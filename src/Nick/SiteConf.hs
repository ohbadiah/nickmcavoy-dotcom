module Nick.SiteConf where

import Metaplasm.Config
import qualified Data.Map as Map

data SiteConfiguration = SiteConfiguration
  { siteRoot :: String
  , subBlogs       :: Map.Map String String
  , defaultSubblog :: String
  }

siteConf :: SiteConfiguration
siteConf = SiteConfiguration
  { siteRoot = "http://www.nickmcavoy.com"
  , subBlogs = Map.fromList [("tech", "Computing"), ("food", "Food"), ("nick", "Nick"), ("muse", "Music and Culture"), ("yhwh", "Jesus"), ("muse", "Music and Culture")]
  , defaultSubblog = "tech"
  }
