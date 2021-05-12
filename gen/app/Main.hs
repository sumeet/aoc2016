{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Main where

import Assembly
  ( CFuncCall (..),
    CFunction (..),
    Code (..),
    InitData (..),
    Label (..),
    Operand (..),
    Program (..),
    TextSection (..),
    stringLiteral,
  )
import qualified Codec.Archive.Tar as Tar
import qualified Codec.Archive.Tar.Entry as Tar
import qualified Data.ByteString as BS
import Data.ByteString.Lazy (fromStrict, toStrict)
import Data.ByteString.Lazy.Char8 (pack)
import Data.Either (fromRight)
import Data.List (nub)
import Data.List.NonEmpty (fromList)
import Data.UUID (nil)
import Output (toNasm)
import Text.Printf (printf)
import Text.RawString.QQ (r)

cPrintf :: CFunction
cPrintf = CFunction {numArgs = 2, funcName = "printf", cLib = "c"}

formatString :: InitData
formatString = stringLiteral "%s\n"

message :: InitData
message = stringLiteral "Sup, Bitches!"

myProgram :: Program
myProgram =
  Program
    { dataSection = [formatString, message],
      textSection =
        TextSection
          { cFunctions = [cPrintf],
            mainCode = [CallCFunc $ CFuncCall cPrintf [LabelAddr (label formatString), LabelAddr (label message)]]
          }
    }

toMakefile :: Program -> Tar.Entry
toMakefile p@Program {textSection = TextSection {cFunctions}} =
  Tar.fileEntry
    (filePath "Makefile")
    $ pack $
      printf
        [r|
.RECIPEPREFIX += >
progname = %s

${progname}: ${progname}.o
> gcc -no-pie -m64 -o ${progname} ${progname}.o %s

${progname}.o: ${progname}.asm
> nasm -g -felf64 ${progname}.asm -l ${progname}.lst

clean:
> rm -f ${progname} ${progname}.o ${progname}.lst
|]
        name
        cLibs
  where
    cLibs = unwords $ map ("-l" ++) $ nub $ map cLib cFunctions

toNasmFile :: Program -> Tar.Entry
toNasmFile prog = Tar.fileEntry (filePath $ name ++ ".asm") $ pack $ toNasm prog

filePath :: String -> Tar.TarPath
filePath fileName = fromRight undefined (Tar.toTarPath False $ name ++ "/" ++ fileName)

-- TODO: probably temp
name :: String
name = "testBin"

toTarFile :: Program -> BS.ByteString
toTarFile prog = toStrict $ Tar.write [toMakefile prog, toNasmFile prog]

main :: IO ()
main = BS.putStr $ toTarFile myProgram
