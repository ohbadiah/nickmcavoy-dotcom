module Nick.Subblogs where

import Hakyll
import Nick.SiteConf
import Control.Monad (filterM)
import Data.List (intercalate)
import Data.List.Split (split, onSublist)
import Data.Maybe (fromJust)
import qualified Data.Map as Map

subblogNames :: [String]
subblogNames = (Map.keys $ subBlogs siteConf)

lookupSubblogs :: Metadata -> [String]
lookupSubblogs = words . Map.findWithDefault (defaultSubblog siteConf) "subblog"

-- | Look in Metadata of items to remove those not part of the given subblog.
onlyItemsForSubblog :: (Functor m, MonadMetadata m) => String -> [Item a] -> m [Item a]
onlyItemsForSubblog = filterItemsByMetadata . isSubblog  where
  filterItemsByMetadata :: (MonadMetadata m, Functor m) => (Metadata -> Bool) -> [Item a] -> m [Item a]
  filterItemsByMetadata p  = filterM ((fmap p) . getMetadata .itemIdentifier)

-- | Is the given subblog found in this Metadata?
isSubblog :: String -> Metadata -> Bool
isSubblog s = elem s . lookupSubblogs

-- | Put in context links to each versions of the post in which it is published.
subblogLinksField :: String -> Context a
subblogLinksField key = field key $ \item ->
  let identifier = itemIdentifier item in do
  subblogs <- getSubblogs identifier
  filePath <- fmap (toUrl . fromJust) $ getRoute identifier
  let urls = map (\sb -> subSubblogInUrl sb filePath) subblogs
  let links = map (\(u,sb) -> "<a href=\"" ++ u ++ "\">" ++ sb ++ "</a>") (zip urls subblogs)
  return $ intercalate " | " links where

    subSubblogInUrl :: String -> String -> String
    subSubblogInUrl subblog = concat . (map toThisSubblog) . (split (onSublist "/")) where
      toThisSubblog :: String -> String
      toThisSubblog s = if elem s subblogNames then subblog else s

-- | Get the subblogs an identifier is published in.
getSubblogs :: MonadMetadata m => Identifier -> m [String]
getSubblogs identifier = do
    metadata <- getMetadata identifier
    return $ lookupSubblogs metadata
