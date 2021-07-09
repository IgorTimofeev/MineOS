local gpu = require("Screen").getGPUProxy()
local event = require("Event")
local w, h, t, q = gpu.getResolution()
local numb, ha, wh, p, s, u, e, gsB, gS, ti, r, slp, tn = {29850,29351,30887,18925,14735,27343,9383,31407,31147,[0]=31599}, h/2-2, {0, 8, nil, 18, 26}, "▀", "  ", h%2, w/2, gpu.setBackground, gpu.set, table.insert, math.random, event.sleep, tonumber

local function drawN(x, y, n)
  local c = 0
  for i = 0, 14 do
    if bit32.extract(numb[n], i) == 1 then
      gsB(60928)
      gS(x, y, s)
    else
      gsB(0)
      gS(x, y, s)
    end
    c, x = c + 1, x + 2
    if c % 3 == 0 then
      y, x = y + 1, x - 6
    end
  end
end

gsB(0)
gpu.fill(1, 1, w, h, " ")
local tbl = {x = {}, y = {}}
for x = 1, w, 2 do
  for y = 1, ha-1-u do
    ti(tbl.x, x)
    ti(tbl.y, y)
  end
end
for n = 1, #tbl.x do
  k = r(n)
  tbl.x[n], tbl.x[k], tbl.y[n], tbl.y[k] =
  tbl.x[k], tbl.x[n], tbl.y[k], tbl.y[n]
end
while true do
  q = 1
  for i = 1, #tbl.x do
    gpu.setForeground(r(tbl.x[i]*tbl.y[i])*512)
    gS(tbl.x[i], tbl.y[i], p)
    gS(-tbl.x[i]+w, -tbl.y[i]+h+1, p)
    q = q + 1
    if q == 55 then
      t = os.date("%T")
      for o = 1, 5 do
        if o ~= 3 then
          drawN(e+wh[o]-15, ha+u, tn(t:sub(o,o)))
        end
      end
      if tn(t:sub(5, 5))%2 == 0 then
        gsB(60928)
      else
        gsB(0)
      end
      gS(e, ha+1+u, s)
      gS(e, ha+3+u, s)
      gsB(0)
      q = 1
      slp(0.05)
    end
    local cykaNahooy = {event.pull(0)}
    if cykaNahooy[1] == "key_down" or cykaNahooy[1] == "touch" then
      gpu.setBackground(0x0)
      gpu.fill(1, 1, w, h, " ")
      return
    end
  end
  slp(0.05)
end