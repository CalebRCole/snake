module Types where

type Position = (Int, Int)

data Direction = Left | Down | Up | Right
  deriving (Eq, Show)
