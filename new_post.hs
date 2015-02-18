import Data.Char (toLower)
import Data.Time
import Data.Time.Clock (getCurrentTime, UTCTime)
import Data.Set (Set, member, union, difference, fromList, toList)
import Control.Monad (liftM)

-- | Prompt the user for input.
prompt :: String -> IO String
prompt query = putStr query' >> getLine where
   query' = query ++ " "

-- Read the system date into a string.
timeAsString :: IO String
timeAsString = liftM show getCurrentTime

dateAsString :: IO String
dateAsString = liftM untilFirstSpace timeAsString where
  untilFirstSpace = takeWhile (/= ' ')

-- What are you allowed to put in the filename of a blog post? What about the post title itself?
lettersNumbers :: Set Char
lettersNumbers = fromList $ ['A' .. 'Z'] ++ ['a' .. 'z'] ++ ['0' .. '9']

specialChars :: Set Char
specialChars  = Data.Set.fromList $ '"' : "\\'., !?_-"

allowedInTitle :: Set Char
allowedInTitle = union lettersNumbers specialChars

allowedInFilename :: Set Char
allowedInFilename = union lettersNumbers $ fromList " _-"

memberOf :: Ord a => Set a -> a -> Bool
memberOf set el = member el set

-- | Take the date and a user-supplied post title and turn it into a filename.
dateAndPostNameToFileName :: String -> String -> String
dateAndPostNameToFileName date = prefixWithDate . (++ ".markdown") . removeBadChars . lowerCaseNoSpaces where
  prefixWithDate = (date ++) . ('-' :)
  lowerCaseNoSpaces =  map $ spaceToDash . toLower
  removeBadChars = filter $ memberOf allowedInFilename
  spaceToDash c = case c of
    ' ' -> '-'
    other -> other

-- | Ask user for name for post.
getPostNameFromUser :: IO String
getPostNameFromUser = do
  ipt <- prompt "What would you like to call the post?"
  if (validPostName ipt) then return ipt else do
    putStrLn $ "Sorry, these characters are not allowed: " ++ disallowed ipt allowedInTitle
    getPostNameFromUser  where
  validPostName = all $ memberOf allowedInTitle
  disallowed s set = toList $ difference (fromList s) set

-- | Ask user for which subblog post is for.
subblogs :: [String]
subblogs = ["muse", "yhwh", "nick", "tech", "food"]

getSubblogFromUser :: IO String
getSubblogFromUser = do
  ipt <- prompt "Which subblog is this post for?"
  if (all (\w -> elem w subblogs) (words ipt)) then return ipt else do
  if (elem ipt subblogs) then return ipt else do
    putStrLn $ "Sorry, please give me one of: " ++ (unwords subblogs)
    getSubblogFromUser

data InfoForPost = InfoForPost {title :: String, subblog :: String} deriving (Show, Eq)

postBody :: InfoForPost -> String
postBody (InfoForPost title subblog) = "---\ntitle: " ++ title ++ "\nsubblog: " ++ subblog ++ "\ntags: \n---\n"

main :: IO ()
main = do
  dateStr  <- dateAsString
  postName <- getPostNameFromUser
  subblog  <- getSubblogFromUser
  let filename = dateAndPostNameToFileName dateStr postName
  let path = "content/posts/" ++ filename
  let info = InfoForPost postName subblog
  writeFile path (postBody info)
  putStrLn "Happy writing."
