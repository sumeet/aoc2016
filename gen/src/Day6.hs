{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

module Day6 where

import Assembly (InitData, stringLiteral)
import Text.RawString.QQ (r)

input :: InitData
input =
  stringLiteral
    [r|eedadn
drvtee
eandsr
raavrd
atevrs
tsrnev
sdttsa
rasrtv
nssdts
ntnada
svetve
tesnvt
vntsnd
vrdear
dvrsen
enarar|]

program = codeBlock [
    123
]