{-# LANGUAGE NamedFieldPuns #-}

module Output (OutputNasm (..)) where

import Assembly
  ( CFuncCall (CFuncCall),
    CFuncLabel (..),
    CFunction (..),
    Callable (..),
    Code (..),
    InitData (..),
    Instruction (..),
    Label (..),
    Operand (..),
    Program (..),
    Register (..),
    TextSection (..),
    exitZeroLibc,
    toInstructions,
  )
import Data.List (intercalate)
import Data.List.NonEmpty (toList)
import Data.UUID (toString)

class OutputNasm a where
  toNasm :: a -> String

instance OutputNasm Program where
  toNasm Program {dataSection, textSection} =
    intercalate
      "\n"
      $ ["section .data"]
        ++ map toNasm dataSection
        ++ ["\n"]
        ++ [toNasm textSection]

instance OutputNasm InitData where
  toNasm InitData {label, val} =
    toNasm label ++ ": db " ++ intercalate ", " (map show (toList val))

instance OutputNasm TextSection where
  toNasm TextSection {cFunctions, mainCode} =
    intercalate "\n" $
      ["section .text"]
        -- TODO: need to formalize main section and export...
        ++ ["global main"]
        ++ map (\CFunction {funcName} -> "extern " ++ toNasm funcName) cFunctions
        ++ ["\n"]
        ++ ["main:"]
        ++ map toNasm mainCode
        ++ map toNasm exitZeroLibc
        ++ ["\n"]

instance OutputNasm Code where
  toNasm c = intercalate "\n" $ map toNasm $ toInstructions c

instance OutputNasm Instruction where
  toNasm (Mov dest src) = "mov " ++ toNasm dest ++ ", " ++ toNasm src
  toNasm (Cmp lhs rhs) = "cmp " ++ toNasm lhs ++ ", " ++ toNasm rhs
  toNasm (Call callable) = toNasm callable
  toNasm Ret = "ret"

instance OutputNasm Callable where
  toNasm (CallCLabel label) = "call " ++ toNasm label
  toNasm (CallLabel label) = "call " ++ toNasm label

instance OutputNasm CFuncLabel where
  toNasm (CFuncLabel s) = s

instance OutputNasm Label where
  toNasm (Label uuid) = "l" ++ filter (/= '-') (toString uuid)

instance OutputNasm Operand where
  toNasm (Reg RDI) = "rdi"
  toNasm (Reg RSI) = "rsi"
  toNasm (Reg RAX) = "rax"
  toNasm (LabelAddr label) = toNasm label
  toNasm (Lit n) = show n
