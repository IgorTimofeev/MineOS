local keyboard = {
  -- Control
  LEFT_CONTROL = 29,
  RIGHT_CONTROL = 157,
  -- Shift
  LEFT_SHIFT = 42,
  RIGHT_SHIFT = 54,
  -- Alt
  LEFT_ALT = 56,
  RIGHT_ALT = 184,
  -- Command (Mac & Linux) or Windows Key (Windows), I added both in case someone is from windows
  COMMAND_KEY = 219,
  WINDOWS_KEY = 219,
  
  -- Numbers (Not from Num Pad)
  ONE = 2,
  TWO = 3,
  THREE = 4,
  FOUR = 5,
  FIVE = 6,
  SIX = 7,
  SEVEN = 8,
  EIGHT = 9,
  NINE = 10,
  ZERO = 11,
  
  -- Letters
  A = 30,
  B = 48,
  C = 46,
  D = 32,
  E = 18,
  F = 33,
  G = 34,
  H = 35,
  I = 23,
  J = 36,
  K = 37,
  L = 38,
  M = 50,
  N = 49,
  O = 24,
  P = 25,
  Q = 16,
  R = 19,
  S = 31,
  T = 20,
  U = 22,
  V = 47,
  W = 17,
  X = 45,
  Y = 21,
  Z = 44,
  
  -- Misc
  MINUS= 12,
  PLUS = 13,
  BACKSPACE = 14,
  TAB = 15,
  SINGLE_QUOTE = 26,
  EXCLAMATION = 27,
  ENTER = 28,
  OPEN_QUOTE = 40,
  COMMA = 51,
  DOT = 52,
  SPACE = 57,
  
  -- Arrow Keys
  UP = 200,
  DOWN = 208,
  RIGHT = 205,
  LEFT = 203,
}

local pressedCodes = {}

-------------------------------------------------------------------------

function keyboard.isKeyDown(code)
  checkArg(1, code, "number")
  
  return pressedCodes[code]
end

function keyboard.isControl(code)
  return type(code) == "number" and (code < 32 or (code >= 127 and code <= 159))
end

function keyboard.isAltDown()
  return pressedCodes[keyboard.LEFT_ALT] or pressedCodes[keyboard.RIGHT_ALT]
end

function keyboard.isControlDown()
  return pressedCodes[keyboard.LEFT_CONTROL] or pressedCodes[keyboard.RIGHT_CONTROL]
end

function keyboard.isShiftDown()
  return pressedCodes[keyboard.LEFT_SHIFT] or pressedCodes[keyboard.RIGHT_SHIFT]
end

function keyboard.isCommandDown()
  return pressedCodes[keyboard.COMMAND_KEY]
end

-------------------------------------------------------------------------------

require("Event").addHandler(function(e1, _, _, e4)
  if e1 == "key_down" then
    pressedCodes[e4] = true
  elseif e1 == "key_up" then
    pressedCodes[e4] = nil
  end
end)

-------------------------------------------------------------------------------

return keyboard
