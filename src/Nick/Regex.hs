module Nick.Regex where

import Text.Regex.TDFA
import Data.Maybe (listToMaybe)

-- | Given a pattern with at least one capture group matching a string,
-- return the matched first capture group.
firstMatch :: String -> String -> String
firstMatch pat s = runOn s where
  runOn = (!! 1) . safe . listToMaybe . (=~ pat)

  safe :: Maybe [String] -> [String]
  safe = maybe (error msg) id

  msg =  ("Pattern " ++ pat ++ " was not matched by string " ++ s ++"!")
