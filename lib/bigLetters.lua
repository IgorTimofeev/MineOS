
local unicode = require("unicode")
local buffer = require("doubleBuffering")
local bigLetters = {}

local pixelHeight = 5
local lettersInterval = 2

local letters = {
  ["0"] = {
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 0, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
  },
  ["1"] = {
    { 0, 0, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
  },
  ["2"] = {
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 1, 1, 1 },
    { 1, 0, 0 },
    { 1, 1, 1 },
  },
  ["3"] = {
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 1, 1, 1 },
  },
  ["4"] = {
    { 1, 0, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
  },
  ["5"] = {
    { 1, 1, 1 },
    { 1, 0, 0 },
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 1, 1, 1 },
  },
  ["6"] = {
    { 1, 1, 1 },
    { 1, 0, 0 },
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
  },
  ["7"] = {
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
    { 0, 0, 1 },
  },
  ["8"] = {
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
  },
  ["9"] = {
    { 1, 1, 1 },
    { 1, 0, 1 },
    { 1, 1, 1 },
    { 0, 0, 1 },
    { 1, 1, 1 },
  },
  -- ["A"] = {
  --   { 0, 1, 1, 1, 0 },
  --   { 1, 0, 0, 0, 1 },
  --   { 1, 0, 0, 0, 1 },
  --   { 1, 1, 1, 1, 1 },
  --   { 1, 0, 0, 0, 1 },
  --   { 1, 0, 0, 0, 1 },
  --   { 1, 0, 0, 0, 1 },
  -- },
  -- ["a"] = {
  --   { 0, 1, 1, 1, 0 },
  --   { 0, 0, 0, 0, 1 },
  --   { 0, 1, 1, 1, 1 },
  --   { 1, 0, 0, 0, 1 },
  --   { 0, 1, 1, 1, 1 },
  -- },
  -- ["SAMPLELITTLE"] = {
  --   { 0, 0, 0, 0, 0 },
  --   { 0, 0, 0, 0, 0 },
  --   { 0, 0, 0, 0, 0 },
  --   { 0, 0, 0, 0, 0 },
  --   { 0, 0, 0, 0, 0 },
  -- },
}

function bigLetters.draw(x, y, color, symbol)
  if not letters[symbol] then
    error("Symbol \"" .. symbol .. "\" is not supported yet.")
  end

  for j = 1, #letters[symbol] do
    for i = 1, #letters[symbol][j] do
      if letters[symbol][j][i] == 1 then
        buffer.square(x + i * 2 - 2, y + (pixelHeight - #letters[symbol]) + j - 1, 2, 1, color, 0xFFFFFF, " ")
      end
    end
  end

  return #letters[symbol][1]
end

function bigLetters.drawText(x, y, color, stroka)
  checkArg(4, stroka, "string")
  for i = 1, unicode.len(stroka) do
    x = x + bigLetters.draw(x, y, color, unicode.sub(stroka, i, i)) * 2 + lettersInterval
  end
end


-- ecs.prepareToExit()
-- bigLetters.drawString(1, 1, 0x00FF00, "0123456789Aa")

return bigLetters











