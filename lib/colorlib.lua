local colorlib = {}

--utils
local function check(tVal, tMaxVal, tMinVal, tType)
  
end

local function isNan(x)
	return x~=x
end

--RGB model
function colorlib.HEXtoRGB(color)
  color = math.ceil(color)

  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)

  return rr, gg, bb
end

function colorlib.RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--HSB model
function colorlib.RGBtoHSB(rr, gg, bb)
  local max = math.max(rr, math.max(gg, bb))
  local min = math.min(rr, math.min(gg, bb))
  local delta = max - min

  local h = 0
  if ( max == rr and gg >= bb) then h = 60*(gg-bb)/delta end
  if ( max == rr and gg <= bb ) then h = 60*(gg-bb)/delta + 360 end
  if ( max == gg ) then h = 60*(bb-rr)/delta + 120 end
  if ( max == bb ) then h = 60*(rr-gg)/delta + 240 end

  local s = 0
  if ( max ~= 0 ) then s = 1-(min/max) end

  local b = max*100/255

  if isNan(h) then h = 0 end

  return h, s*100, b
end

function colorlib.HSBtoRGB(h, s, v)
  if h >359 then h = 0 end
  local rr, gg, bb = 0, 0, 0
  local const = 255

  s = s/100
  v = v/100
  
  local i = math.floor(h/60)
  local f = h/60 - i
  
  local p = v*(1-s)
  local q = v*(1-s*f)
  local t = v*(1-(1-f)*s)

  if ( i == 0 ) then rr, gg, bb = v, t, p end
  if ( i == 1 ) then rr, gg, bb = q, v, p end
  if ( i == 2 ) then rr, gg, bb = p, v, t end
  if ( i == 3 ) then rr, gg, bb = p, q, v end
  if ( i == 4 ) then rr, gg, bb = t, p, v end
  if ( i == 5 ) then rr, gg, bb = v, p, q end

  return rr*const, gg*const, bb*const
end

function colorlib.HEXtoHSB(color)
  local rr, gg, bb = colorlib.HEXtoRGB(color)
  local h, s, b = colorlib.RGBtoHSB( rr, gg, bb )
  
  return h, s, b
end

function colorlib.HSBtoHEX(h, s, b)
  local rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
  local color = colorlib.RGBtoHEX(rr, gg, bb)

  return color
end

return colorlib
