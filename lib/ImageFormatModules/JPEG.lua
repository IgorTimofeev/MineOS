local cmp = require("component")
local com = require("computer")
local gpu = cmp.gpu
local trm = require("term")
local shl = require("shell")
local args = shl.parse(...)

HEX = "0123456789ABCDEF"
--[[             MARKER                 ]]

function R(ind)
  return STR:byte(ind) % 16
end

function L(ind)
  return math.floor( STR:byte(ind) / 16 )
end

function getB(ind) local right, left = R(ind) + 1, L(ind) + 1
  return HEX:sub(left, left)..HEX:sub(right, right)
end

function Common()
  i = len
end

function DB() local IDI, x, y = R(i) + 1, 1, 1
  i = i + 1
  while i < len do
    while y > 1 and x < 8 do
      masDB[IDI][y][x] = STR:byte(i) i = i + 1
      y, x = y - 1, x + 1
    end
    if y <= 8 and x <= 8 then
      masDB[IDI][y][x] = STR:byte(i) i = i + 1
    end
    if x == 8 then y = y + 1
    else x = x + 1 end
    while y < 8 and x > 1 do
      masDB[IDI][y][x] = STR:byte(i) i = i + 1
      y, x = y + 1, x - 1
    end
    if y <= 8 and x <= 8 then
      masDB[IDI][y][x] = STR:byte(i) i = i + 1
    end
    if y == 8 then x = x + 1
    else y = y + 1  end
  end
end

function DA() local YCbCr, BYTECODE, BYTEpos, comp = {}, "", 1, STR:byte(i)
  local function DrawFrame(coordX, coordY) local Y, Cb_avr, Cr_avr, value
    local function getTable(INDEX) local DC_ind, AC_ind, x, y, TABLE = YCbCr[INDEX][1], YCbCr[INDEX][2], 1, 1, {{}, {}, {}, {}, {}, {}, {}, {}}
      local CODE
      local function getKEY(ACDC_TABLE) local key = ""
        while ACDC_TABLE[key] == nil do
          key = key..BYTECODE:sub(BYTEpos, BYTEpos)
          BYTEpos = BYTEpos + 1
        end
        return ACDC_TABLE[key]
      end

      local function getCOEF(VALUE) local COEF = 0
    
        CODE = BYTECODE:sub(BYTEpos, BYTEpos + VALUE - 1)
        BYTEpos = BYTEpos + VALUE
        for j=1, #CODE do
          COEF = COEF * 2 + tonumber(CODE:sub(j, j))
        end
        if #CODE ~= 0 and CODE:sub(1, 1) == "0" then
          COEF = COEF - 2 ^ #CODE + 1
        end
        return COEF
      end

      local function step(n)
    TABLE[y][x] = n * masDB[QUAT[INDEX] + 1][y][x]
        if (x + y) % 2 == 1 then
          if y == 8 then x = x + 1
          elseif x == 1 then y = y + 1
          else x, y = x - 1, y + 1
          end
        else
          if x == 8 then y = y + 1
          elseif y == 1 then x = x + 1
          else x, y = x + 1, y - 1
          end
        end
      end
      --[[          DC Coeficient        ]]
      value = getKEY(AC_DC[0][DC_ind])
      step(getCOEF(value) + YCbCr[INDEX][3])
    YCbCr[INDEX][3] = TABLE[1][1] / masDB[QUAT[INDEX] + 1][1][1]
     --[[          AC Coeficient         ]]
      if AC_DC[1][AC_ind] ~= nil then
        while TABLE[8][8] == nil do
          value = getKEY(AC_DC[1][AC_ind])
          if value == 0 then break
          end
          for j=1, math.floor(value / 16) do
            step(0)      
          end
          step(getCOEF(value % 16) or 0)
        end
      end
      while TABLE[8][8] == nil do
        step(0)
      end
      return TABLE
    end
    
    local function getPIXEL(l, j)
      local function RGB(Yval, Cbval, Crval)
        local function SSS(val)
          local ost
          val, ost = math.modf(val)
          if ost > 0.5 then 
            val = val + 1
          end
          return math.max(0, math.min(255, val))
        end
        return SSS(Yval + 1.402 * Crval + 128) * 2 ^ 16 + SSS(Yval - 0.34414 * Cbval - 0.71414 * Crval + 128) * 2 ^ 8 + SSS(Yval + 1.772 * Cbval + 128)
      end
      return RGB(Y[DCT[1][1] * math.floor((l - 1) / 8) + math.ceil(j / 8)][(l - 1) % 8 + 1][(j - 1) % 8 + 1], Cb_avr[math.ceil(l / DCT[1][2])][math.ceil(j / DCT[1][1])], Cr_avr[math.ceil(l / DCT[1][2])][math.ceil(j / DCT[1][1])])
    end

    local function ODCP(arr) local arr1 = {{}, {}, {}, {}, {}, {}, {}, {}}
    local function getC(var)
        if var == 0 then return 1 / math.sqrt(2) end
        return 1
      end
      local function getSyx(x, y) local Syx = 0
        for u = 0, 7 do
          local COSU = getC(u) * math.cos(((2 * x + 1) * u * math.pi) / 16)
          for v = 0, 7 do
            Syx = Syx + COSU * getC(v) * math.cos(((2 * y + 1) * v * math.pi) / 16) * arr[u+1][v+1]
          end
        end
        return Syx / 4
      end
  
      for l=1, 8 do
        for j=1, 8 do
          arr1[l][j] = getSyx(l - 1, j - 1)
        end
      end
      return arr1
    end
    
    Y = {}
  for l=1, DCT[1][1] * DCT[1][2] do
      Y[l] = ODCP(getTable(1))
    end
    Cb_avr = ODCP(getTable(2))
    Cr_avr = ODCP(getTable(3))
    for l=1, 4 * DCT[1][2] do
      for j=1, 8 * DCT[1][1] do
        gpu.setBackground(getPIXEL(l*2-1, j))
        gpu.setForeground(getPIXEL(l*2, j))
        gpu.set(j + coordX - 1,l + coordY - 1,"▄")
      end
    end
  end
  
  local function getBITCODE(value) local tmp = ""
    for j=1, 8 do
      tmp = tostring(value % 2)..tmp
      value = math.floor(value / 2)    
    end
    return tmp
  end

  i = i + 1
  if comp ~= 3 then 
    print("ERROR in FF DA") os.exit() 
  end
  YCbCr = {{L(i + 1), R(i + 1), 0}, {L(i + 3), R(i + 3), 0}, {L(i + 5), R(i + 5), 0}}
  i = len
  local j = i
  while j < #STR - 1 do
    if STR:byte(j) == 255 then BYTECODE, j = BYTECODE.."11111111", j + 1
    else BYTECODE = BYTECODE..getBITCODE(STR:byte(j))
    end
    j = j + 1
  end
  for I = 1, math.ceil(HEIGHT / (8 * DCT[1][2])) do
    for J = 1, math.ceil(WIDTH / (8 * DCT[1][1])) do
      DrawFrame((J - 1) * 8 * DCT[1][1] + 1, (I - 1) * 4 * DCT[1][2] + 1)
    end
  end
end

function C0()
  QUAT, i = {}, i + 1
  HEIGHT = STR:byte(i) * 256 + STR:byte(i + 1) i = i + 2
  WIDTH = STR:byte(i) * 256 + STR:byte(i + 1) i = i + 3
  -- gpu.setResolution(WIDTH, math.floor(HEIGHT / 2))
  DCT = {}
  for j=1, STR:byte(i-1) do
    i = i + 3
    DCT[j] = {L(i - 2), R(i - 2)}
    QUAT[j] = STR:byte(i-1)
  end
  i = len
end

function C4() local TREE, TREEpos, TREElevel, TREEpath, class, index, HAFF = {[0] = -1}, 0, 0, "", L(i), R(i), {}
  i, AC_DC[class][index] = i + 1, {}
  local function AddTree(VAL)
    local function ADD(VALUE)
      if TREElevel ~= VAL - 1 then
        TREEpath = TREEpath..tostring(VALUE)
        TREElevel = TREElevel + 1
        TREEpos = TREEpos * 2 + 1 + VALUE
        TREE[TREEpos] = -1
        return AddTree(VAL)
      else
        TREE[TREEpos * 2 + 1 + VALUE] = 0
        AC_DC[class][index][TREEpath..tostring(VALUE)] = STR:byte(i)
        i = i + 1
      end
    end
    if TREE[TREEpos * 2 + 1] == nil then ADD(0)
    elseif TREE[TREEpos * 2 + 2] == nil then ADD(1)
    else
      TREElevel = TREElevel - 1
      TREEpath = TREEpath:sub(1, -2)
      TREEpos = math.floor((TREEpos - 1) / 2)
      return AddTree(VAL)
    end
  end
  
  for j=1, 16 do
    HAFF[j], i = STR:byte(i), i + 1    
  end
  for j=1, 16 do
    for k=1, HAFF[j] do 
      AddTree(j)
    end
  end
  i = len
end


AC_DC = {[0] = {}, [1] = {}}
MF = {["DB"] = DB, ["C0"] = C0, ["C1"] = C0, ["C2"] = C0, ["C3"] = C0, ["C4"] = C4, ["DA"] = DA, ["FE"] = FE}
masDB = {{{}, {}, {}, {}, {}, {}, {}, {}}, {{}, {}, {}, {}, {}, {}, {}, {}}}
i = 3

file = io.open(args[1], "rb")
STR = file:read("*a")
file:close()
if getB(1) ~= "FF" or getB(2) ~= "D8" then
  print("Error: incorrect contents of the file.")
  os.exit()
end
while i < #STR - 1  do
  idin = getB(i+1)
  i = i + 2
  len = i + STR:byte(i) * 256 + STR:byte(i + 1)
  i = i + 2
  (MF[idin] or Common)()
end