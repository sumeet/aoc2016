{-# LANGUAGE NamedFieldPuns #-}

module Assembly
  ( stringLiteral,
    Program (..),
    TextSection (..),
    CFunction (..),
    CFuncLabel (..),
    InitData (..),
    CFuncCall (..),
    Operand (..),
    Label (..),
    Code (..),
    Instruction (..),
    Callable (..),
    Register (..),
    toInstructions,
  )
where

import Data.List.NonEmpty (NonEmpty, fromList, toList)
import Data.String (IsString (..))
import Data.UUID (UUID)
import Data.UUID.V5 (generateNamed, namespaceOID)
import Data.Word (Word8)
import Numeric.Natural (Natural)

data Program = Program
  { dataSection :: [InitData],
    textSection :: TextSection
  }
  deriving (Show)

newtype Label = Label UUID deriving (Show)

data InitData = InitData
  { label :: Label,
    val :: NonEmpty Word8
  }
  deriving (Show)

toWord8s :: String -> [Word8]
toWord8s = map $ toEnum . fromEnum

stringLiteral :: String -> InitData
stringLiteral s =
  InitData
    { label = Label $ generateNamed namespaceOID words,
      val = fromList words
    }
  where
    words = toWord8s s

-- TODO: set rax to 0 before calling anything
-- https://stackoverflow.com/questions/6212665/

data TextSection = TextSection
  { cFunctions :: [CFunction],
    -- main is for when we're running under libc
    mainCode :: [Code]
  }
  deriving (Show)

newtype CFuncLabel = CFuncLabel String deriving (Show)

instance IsString CFuncLabel where
  fromString = CFuncLabel

data CFunction = CFunction
  { numArgs :: Natural,
    funcName :: CFuncLabel,
    cLib :: String
  }
  deriving (Show)

data Register = RDI | RSI | RAX deriving (Show)

-- TODO: need to put the size somewhere...
data Operand = Reg Register | Loc Label deriving (Show)

data Callable = CallCLabel CFuncLabel | CallLabel Label deriving (Show)

data Instruction = Mov Operand Operand | Cmp Operand Operand | Ret | Call Callable deriving (Show)

data CFuncCall = CFuncCall
  { cFunc :: CFunction,
    args :: [Operand]
  }
  deriving (Show)

callingConventionOperands :: [Operand]
callingConventionOperands = [Reg RDI, Reg RSI]

toInstructions :: Code -> [Instruction]
toInstructions (ExecInst i) = [i]
toInstructions (CallCFunc CFuncCall {args, cFunc = CFunction {funcName}}) =
  argsSetup ++ [Call $ CallCLabel funcName]
  where
    argsSetup = zipWith Mov args callingConventionOperands

data Code = ExecInst Instruction | CallCFunc CFuncCall deriving (Show)