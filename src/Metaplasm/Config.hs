{-# LANGUAGE OverloadedStrings #-}
module Metaplasm.Config where

import Hakyll

data EngineConfiguration = EngineConfiguration
  { lessCommand :: String
  , lessFiles :: [Identifier]
  , lessOptions :: [String]
  , vendorScriptFiles :: [Identifier]
  }

defaultEngineConfiguration :: EngineConfiguration
defaultEngineConfiguration = EngineConfiguration
  { lessCommand = "lessc"
  , lessFiles =
    [ "css/bootstrap.less"
    , "css/responsive.less"
    , "css/main.less"
    ]
  , lessOptions = ["--compress"]
  , vendorScriptFiles = map (fromFilePath . (modulePath ++))
    [ "jquerymin/jquery-1.9.1.min.js"
    , "boot-scripts/bootstrap.min.js"
    , "modernizrrespond/modernizr-2.6.2-respond-1.1.0.min.js"
    ]
  }
  where
    modulePath = "lib/initializr/war/builder/modules/"

data SiteConfiguration = SiteConfiguration
  { siteRoot ::  String
  }
