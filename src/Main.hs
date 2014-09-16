{-# LANGUAGE OverloadedStrings #-}
import Control.Applicative (Alternative (..))
import Control.Monad (filterM, (>=>), forM_)
import Data.List (intersperse, isSuffixOf)
import Data.List.Split (splitOn)
import qualified Data.Map as Map
import Data.Maybe (fromJust)
import Data.Monoid (mappend, (<>))
import Hakyll
import Metaplasm.Config
import Metaplasm.Tags
import System.FilePath (combine, splitExtension, takeFileName)
import Text.Pandoc.Options (writerHtml5)
import Nick.Regex (firstMatch)
--import Debug.Trace (trace)

hakyllConf :: Configuration
hakyllConf = defaultConfiguration
  { deployCommand = "git push heroku master"
  }

siteConf :: SiteConfiguration
siteConf = SiteConfiguration
  { siteRoot = "http://www.nickmcavoy.com"
  , subBlogs = Map.fromList [("tech", "Computing"), ("food", "Food"), ("nick", "Nick"), ("muse", "Music and Culture"), ("yhwh", "Jesus"), ("muse", "Music and Culture")]
  , defaultSubblog = "tech"
  }

feedConf :: String -> FeedConfiguration
feedConf title = FeedConfiguration
  { feedTitle = "Nick on Computing: " ++ title
  , feedDescription = "Nick on Computing"
  , feedAuthorName = "Nicholas McAvoy"
  , feedAuthorEmail = "nicholas.mcavoy@gmail.com"
  , feedRoot = "http://nickmcavoy.com"
  }

main :: IO ()
main = hakyllWith hakyllConf $ do
  let engineConf = defaultEngineConfiguration
  let writerOptions = defaultHakyllWriterOptions { writerHtml5 = True }
  let pandocHtml5Compiler =
        pandocCompilerWith defaultHakyllReaderOptions writerOptions

  tags <- buildTags "content/posts/*" (fromCapture "tags/*/index.html")

  let postTagsCtx = postCtx tags

  match "content/tmp/*" $ do
    route stripContent
    compile copyFileCompiler

  match "images/*.png" $ do
    route $ idRoute
    compile copyFileCompiler

  match "content/img/*.jpg" $ do
    route $ stripContent
    compile copyFileCompiler

  match "extra/*" $ do
    route idRoute
    compile copyFileCompiler

  match (fromList $ vendorScriptFiles engineConf) $ do
    route $ prefixRoute "js/vendor"
    compile copyFileCompiler

  match (fromList $ lessFiles engineConf) $ do
    route $ setExtension "css"
    compile $ getResourceString
      >>= withItemBody
        (unixFilter (lessCommand engineConf) $ "-" : (lessOptions engineConf))

  match "content/about/index.md" $ do
    route $ stripContent `composeRoutes` setExtension "html"
    compile $ pandocHtml5Compiler
      >>= loadAndApplyTemplate "templates/about.html"  siteCtx
      >>= loadAndApplyTemplate "templates/default.html" siteCtx
      >>= relativizeUrls
      >>= deIndexUrls

  tagsRules tags $ \tag pattern -> do
    let title = "Posts tagged " ++ tag

    route idRoute
    compile $ do
      list <- postList tags (\t -> recentFirst t >>= filterM (fmap (elem tag) . getTags . itemIdentifier))
      let ctx =
            constField "tag" tag `mappend`
            constField "posts" list `mappend`
            constField "feedTitle" title `mappend`
            constField "title" title `mappend`
            constField "feedUrl" ("/tags/" ++ tag ++ "/index.xml") `mappend`
            siteCtx
      makeItem ""
        >>= loadAndApplyTemplate "templates/tag-posts.html" ctx
        >>= loadAndApplyTemplate "templates/default.html" ctx
        >>= relativizeUrls
        >>= deIndexUrls

    version "rss" $ do
      let feedCtx = postCtx tags `mappend` bodyField "description"
      route $ setExtension "xml"
      compile $ loadAllSnapshots pattern "content"
        >>= fmap (take 10) . recentFirst
        >>= renderAtom (feedConf title) feedCtx

  match "content/posts/*" $ mapM_ (\subblog ->
     do
      route $ directorizeDate `composeRoutes` (prefixWithStr subblog) `composeRoutes` stripContent `composeRoutes` setExtension "html"
      compile $ do
        compiled <- pandocHtml5Compiler
        full <- loadAndApplyTemplate "templates/post.html" postTagsCtx compiled
        teaser <- loadAndApplyTemplate "templates/post-teaser.html" postTagsCtx $ dropMore compiled
        _ <- saveSnapshot "content" full
        _ <- saveSnapshot "teaser" teaser
        loadAndApplyTemplate "templates/default_subblog.html" (metadataField <> (postCtx tags) <> (subblogCtx subblog)) full
          >>= relativizeUrls
          >>= deIndexUrls) ["asdf","fdsa"]

  match "content/index.md" $ do
    route $ stripContent `composeRoutes` setExtension "html"
    compile $ pandocHtml5Compiler
      >>= loadAndApplyTemplate "templates/default.html" siteCtx
      >>= relativizeUrls
      >>= deIndexUrls

  create ["archive.html"] $ do
    route stripContent
    compile $ do
      let archiveCtx =
            field "posts" (\_ -> postList tags recentFirst) `mappend`
            constField "title" "Archives" `mappend` siteCtx

      makeItem ""
        >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
        >>= loadAndApplyTemplate "templates/default.html" archiveCtx
        >>= relativizeUrls

  forM_ (Map.keys $ subBlogs siteConf)
    (\subblog ->
      do
        processSubblogIndex tags subblog
        createSubblogAtomFeed tags subblog
        createSubblogAboutPages subblog)

  create ["atom.xml"] $ do
    route idRoute
    compile $ do
      let feedCtx = postCtx tags `mappend` bodyField "description"
      posts <- mapM deIndexUrls =<< fmap (take 10) . recentFirst =<<
        loadAllSnapshots "content/posts/*" "content"
      renderAtom (feedConf "blog") feedCtx (posts)

  match "templates/*" $ compile templateCompiler
  match "templates/*/*" $ compile templateCompiler

siteCtx :: Context String
siteCtx =
  deIndexedUrlField "url" `mappend`
  constField "root" (siteRoot siteConf) `mappend`
  constField "feedTitle" "Posts" `mappend`
  constField "feedUrl" "/atom.xml" `mappend`
  defaultContext

postCtx :: Tags -> Context String
postCtx tags =
  dateField "date" "%e %B %Y" `mappend`
  dateField "datetime" "%Y-%m-%d" `mappend`
  (tagsFieldWith' getTags) "tags" tags `mappend`
  siteCtx

postList :: Tags -> ([Item String] -> Compiler [Item String]) -> Compiler String
postList tags sortFilter = do
  posts <- sortFilter =<< loadAll "content/posts/*"
  itemTpl <- loadBody "templates/post-item.html"
  list <- applyTemplateList itemTpl (postCtx tags) posts
  return list

stripContent :: Routes
stripContent = gsubRoute "content/" $ const ""

prefixRoute :: String -> Routes
prefixRoute s = customRoute (combine s . takeFileName . toFilePath)

directorizeDate :: Routes
directorizeDate = customRoute (\i -> directorize $ toFilePath i)
  where
    directorize path = dirs ++ "/index" ++ ext
      where
        (dirs, ext) = splitExtension $ concat $
          (intersperse "/" date) ++ ["/"] ++ (intersperse "-" rest)
        (date, rest) = splitAt 3 $ splitOn "-" path

stripIndex :: String -> String
stripIndex url = if "index.html" `isSuffixOf` url && elem (head url) "/."
  then take (length url - 10) url else url

deIndexUrls :: Item String -> Compiler (Item String)
deIndexUrls item = return $ fmap (withUrls stripIndex) item

deIndexedUrlField :: String -> Context a
deIndexedUrlField key = field key
  $ fmap (stripIndex . maybe empty toUrl) . getRoute . itemIdentifier

dropMore :: Item String -> Item String
dropMore = fmap (unlines . takeWhile (/= "<!-- MORE -->") . lines)

prefixWithStr :: String -> Routes
prefixWithStr s = customRoute $ (combine s) . toFilePath

getSubblogs :: Metadata -> [String]
getSubblogs = words . Map.findWithDefault (defaultSubblog siteConf) "subblog"

onlyItemsForSubblog :: (Functor m, MonadMetadata m) => String -> [Item a] -> m [Item a]
onlyItemsForSubblog = filterItemsByMetadata . isSubblog  where
  filterItemsByMetadata :: (MonadMetadata m, Functor m) => (Metadata -> Bool) -> [Item a] -> m [Item a]
  filterItemsByMetadata p  = filterM ((fmap p) . getMetadata . itemIdentifier)

isSubblog :: String -> Metadata -> Bool
isSubblog s = any (s ==) .  getSubblogs

subblogAboutPath :: String -> String
subblogAboutPath = (++ "/about/index.html") . firstMatch "about/([a-zA-Z]+).md"

strTransformToRoutes :: (String -> String) -> Routes
strTransformToRoutes strTransform = customRoute $ strTransform . toFilePath

subblogAboutRoutes :: Routes
subblogAboutRoutes = strTransformToRoutes subblogAboutPath

processSubblogIndex :: Tags -> String -> Rules ()
processSubblogIndex tags subblog =
  let ctx = siteCtx <> (subblogCtx subblog) in
  create [fromFilePath $ subblog ++ "/index.html"] $ do
    route $ idRoute
    compile $ do
      postTpl <- loadBody "templates/post-item-full.html"
      body <- loadBody "templates/subblog-index.html"
      loadAllSnapshots "content/posts/*" "teaser"
        >>= fmap (take 100) . (recentFirst >=> (onlyItemsForSubblog subblog))
        >>= applyTemplateList postTpl (postCtx tags)
        >>= makeItem
        >>= applyTemplate body (siteCtx <> bodyField "posts")
        >>= loadAndApplyTemplate "templates/default_subblog.html" ctx
        >>= relativizeUrls
        >>= deIndexUrls

createSubblogAtomFeed :: Tags -> String -> Rules ()
createSubblogAtomFeed tags subblog =
  create [fromFilePath $ subblog ++ "/atom.xml"] $ do
    route idRoute
    compile $ do
      let feedCtx = postCtx tags <> bodyField "description"
      posts <- mapM deIndexUrls =<< fmap (take 10) . (recentFirst >=> (onlyItemsForSubblog subblog)) =<<
        loadAllSnapshots "content/posts/*" "content"
      renderAtom (feedConf "blog") feedCtx (posts)

createSubblogAboutPages :: String -> Rules ()
createSubblogAboutPages subblog =
  let ctx = siteCtx <> (subblogCtx subblog) in
  let writerOptions = defaultHakyllWriterOptions { writerHtml5 = True } in
  match  (fromGlob $ "content/about/" ++ subblog ++ ".md") $ do
    route $ subblogAboutRoutes
    compile $ (pandocCompilerWith defaultHakyllReaderOptions writerOptions)
      >>= loadAndApplyTemplate "templates/about.html"  ctx
      >>= loadAndApplyTemplate "templates/default_subblog.html" ctx
      >>= relativizeUrls
      >>= deIndexUrls

subblogCtx :: String -> Context String
subblogCtx subblog =
  constField "subblog" subblog <>
  constField "subblogTitle" (titleForSubblog subblog) where

titleForSubblog :: String -> String
titleForSubblog s  = fromJust $ Map.lookup s (subBlogs siteConf)
