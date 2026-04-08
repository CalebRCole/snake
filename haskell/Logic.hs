import Types

isOpposite :: Direction -> Direction -> Bool

isOpposite

updateDirection :: Char -> Direction -> Direction
updateDirection input oldDir =
  case input of
    'w' -> setDir Types.Up
    's' -> setDir Types.Down
    'a' -> setDir Types.Left
    'd' -> setDir Types.Right
    _ -> oldDir
  where
    setDir newDir =
      if isOpposite newDir oldDir
        then oldDir
        else newDir
