module Main where

import Shelly (run, shelly, silently)
import Data.Text (Text, pack, unpack, isInfixOf)
import Data.Text.Encoding (encodeUtf8)
import Data.Aeson (decode, FromJSON, ToJSON)
import Data.ByteString (fromStrict)
import GHC.Generics (Generic)
import Data.Map (Map, elems)
import Control.Exception (Exception, throwIO)
import Text.RE.TDFA.Text
import System.Environment (getArgs)
import Control.Monad (forM, forM_)

data Package = Package
  { pname :: Text
  , version :: Text
  , description :: Text
  } deriving (Generic, FromJSON, ToJSON, Show)

type Packages = Map Text Package

data Error
  = NoPackages
  deriving (Show, Exception)

getPackages :: IO Packages
getPackages = do
  let command = silently $ run "nix" ["search", "nixpkgs", "--json"]
  output <- shelly command
  let result = decode . fromStrict . encodeUtf8 $ output
  case result of
    Just packages -> pure packages
    Nothing -> throwIO NoPackages

prettyPackage :: Package -> String
prettyPackage package =
  unlines
    [ "name: " <> unpack package.pname
    , "version: " <> unpack package.version
    , "description: " <> unpack package.description
    ]

main :: IO ()
main = do
  queries <- getArgs
  regexes <- forM queries \query -> do
    compileRegexWith BlockInsensitive query

  let test package regex = (package.pname =~ regex) || (package.description =~ regex)

  packages <- elems <$> getPackages

  forM_ packages \package -> do
    if all id $ map (test package) regexes
       then putStrLn $ prettyPackage package
       else pure ()

  pure ()
