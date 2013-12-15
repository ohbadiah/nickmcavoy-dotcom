{-# LANGUAGE OverloadedStrings #-}
import Control.Applicative (Alternative (..), (<$>))
import Control.Monad (filterM)
import Data.List (intersperse, isSuffixOf)
import Data.List.Split (splitOn)
import qualified Data.Map as Map
import Data.Maybe (fromMaybe)
import Data.Monoid (mappend)
import Hakyll
import Metaplasm.Config
import Metaplasm.Tags
import System.FilePath (combine, splitExtension, takeFileName)
import Text.Pandoc.Options (writerHtml5)

hakyllConf :: Configuration
hakyllConf = defaultConfiguration
  { deployCommand = "git push heroku master"
  }

siteConf :: SiteConfiguration
siteConf = SiteConfiguration
  { siteRoot = "http://www.nickmcavoy.com"
  , subBlogs = ["personal", "tech"]
  , defaultSubblog = "tech"
  }



feedConf :: String -> FeedConfiguration
feedConf title = FeedConfiguration
  { feedTitle = "Nick on Computing: " ++ title
  , feedDescription = "Nick on Computing"
  , feedAuthorName = "Nicholas McAvoy"
  , feedAuthorEmail = "nicholas.mcavoy@gmail.com"
  , feedRoot = "http://nickmcavoy.com/blog"
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

  match "content/posts/*" $ do
    route $ directorizeDate `composeRoutes` stripContent `composeRoutes` setExtension "html" `composeRoutes` prefixWithSubblog
    compile $ do
      compiled <- pandocHtml5Compiler
      full <- loadAndApplyTemplate "templates/post.html" postTagsCtx compiled
      teaser <- loadAndApplyTemplate "templates/post-teaser.html" postTagsCtx $ dropMore compiled
      _ <- saveSnapshot "content" full
      _ <- saveSnapshot "teaser" teaser
      loadAndApplyTemplate "templates/default.html" (postCtx tags) full
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

  match "content/index.html" $ do
    route $ stripContent `composeRoutes` prefixWithSubblog
    compile $ do
      tpl <- loadBody "templates/post-item-full.html"
      body <- readTemplate . itemBody <$> getResourceBody
      loadAllSnapshots "content/posts/*" "teaser"
        >>= fmap (take 100) . recentFirst
        >>= applyTemplateList tpl (postCtx tags)
        >>= makeItem
        >>= applyTemplate body (siteCtx `mappend` bodyField "posts")
        >>= loadAndApplyTemplate "templates/default.html" siteCtx
        >>= relativizeUrls
        >>= deIndexUrls

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

-- | Prefix the filename with the given string, ignoring the path on disk.
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

strTransformToRoutes :: (String -> String) -> Routes
strTransformToRoutes strTransform = customRoute $ strTransform . toFilePath

prefixWithSubblog :: Routes
prefixWithSubblog = metadataRoute $ prefixWithStr . getSubblog where
  prefixWithStr :: String -> Routes
  prefixWithStr s = strTransformToRoutes (combine s)

itemsMetadata :: (MonadMetadata m) => Item a -> m Metadata
itemsMetadata  = getMetadata . itemIdentifier

getSubblog :: Metadata -> String
getSubblog = (fromMaybe (defaultSubblog siteConf)) . (Map.lookup "subblog")

filterItemsByMetadata :: (MonadMetadata m, Functor m) => (Metadata -> Bool) -> [Item a] -> m [Item a]
filterItemsByMetadata pred  = filterM ((fmap pred) . itemsMetadata)

isSubblogPred :: String -> Metadata -> Bool
isSubblogPred s = (s ==) . getSubblog

onlyTechItems :: (Functor m, MonadMetadata m) => [Item a] -> m [Item a]
onlyTechItems = filterItemsByMetadata (isSubblogPred "tech")
