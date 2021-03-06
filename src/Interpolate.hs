module Interpolate where
import Text.ParserCombinators.Parsec
import Control.Monad
import qualified Data.Map as M

data InterpolationSection = StringSection String
                          | VarSection String deriving (Show, Eq)

interpolate :: M.Map String String -> String -> String
interpolate pairs s =
  case parse parseInterpolant "" s of
    Left err       -> error $ "could not parse for interpolation: " ++ show err
    Right sections -> concatMap (substitute pairs) sections


substitute :: M.Map String String -> InterpolationSection -> String
substitute _ (StringSection s) = s
substitute pairs (VarSection s) =
  case M.lookup s pairs of
    Just v  -> v
    Nothing -> error $ "could not find variable " ++ s ++ " to interpolate"

parseInterpolant :: Parser [InterpolationSection]
parseInterpolant = many $ parseVarSection <|> parseStringSection

parseVarSection :: Parser InterpolationSection
parseVarSection = do string "#{"
                     name <- many1 letter
                     char '}'
                     return $ VarSection name

parseStringSection :: Parser InterpolationSection
parseStringSection = liftM StringSection parseStringSection'
  where parseStringSection' = do
          c <- noneOf "#"
          result <- if c == '\\'
                       then do escaped <- escapedChar
                               return (c:escaped)
                       else return [c]
          rest <- many parseStringSection'
          return $ (result ++ concat rest)

escapedChar :: Parser String
escapedChar = do c <- optionMaybe anyChar
                 return $ maybe [] (:[]) c
