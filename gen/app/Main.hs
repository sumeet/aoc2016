{-# LANGUAGE OverloadedStrings #-}

module Main where

import Assembly
  ( CFuncCall (..),
    CFunction (..),
    Code (..),
    Label (..),
    Operand (..),
    Program (..),
    TextSection (..),
    InitData (..),
    stringLiteral,
  )
import Data.List.NonEmpty (fromList)
import Data.UUID (nil)

printf :: CFunction
printf = CFunction {numArgs = 2, funcName = "printf", cLib = "c"}

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
          { cFunctions = [printf],
            mainCode = [CallCFunc $ CFuncCall printf [Loc (label formatString), Loc (label message)]]
          }
    }

main :: IO ()
main = print "Hello World"
