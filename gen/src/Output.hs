{-# LANGUAGE NamedFieldPuns #-}

module Output where

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
    "l" ++ show label ++ ": db " ++ intercalate ", " (map show (toList val))

instance OutputNasm TextSection where
  toNasm TextSection {cFunctions, mainCode} =
    intercalate "\n" $
      ["section .text"]
        ++ map (\CFunction {funcName} -> "extern " ++ toNasm funcName) cFunctions
        ++ ["\n"]
        ++ map toNasm mainCode

instance OutputNasm Code where
  toNasm c = intercalate "\n" $ map toNasm $ toInstructions c

instance OutputNasm Instruction where
  toNasm (Mov dest src) = "mov " ++ toNasm dest ++ ", " ++ toNasm src
  toNasm (Cmp lhs rhs) = "cmp " ++ toNasm lhs ++ ", " ++ toNasm rhs
  toNasm (Call callable) = toNasm callable
  toNasm Ret = "ret"

instance OutputNasm Callable where
  toNasm (CallCLabel label) = toNasm label
  toNasm (CallLabel label) = toNasm label

instance OutputNasm CFuncLabel where
  toNasm (CFuncLabel s) = s

instance OutputNasm Label where
  toNasm (Label uuid) = filter (/= '-') $ toString uuid

instance OutputNasm Operand where
  -- TODO: need a way to specify size somewhere, until then registers are 8-bit
  toNasm (Reg RDI) = "dil"
  toNasm (Reg RSI) = "sil"
  toNasm (Reg RAX) = "al"
  toNasm (Loc label) = "byte [" ++ toNasm label ++ "]"
