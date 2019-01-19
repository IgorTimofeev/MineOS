local gpu, r, xr, ti = require("Screen").getGPUProxy(), math.random, bit32.bxor, table.insert
local event = require("Event")

local tbl, tbl1, S, gsF, gsB, w, h, n, c, Fc, Bc, C, D, i, j, m, k, q, p, a, b = {}, {x = {}, y = {}}, "▄", gpu.setForeground, gpu.setBackground, gpu.getResolution()

local t = (w-h*2)/2

local function pix(x, y, color)

  n = y%2

  y = (y+n)/2

  c, Fc, Bc = gpu.get(x+t, y)

  if c ~= S then

    Fc = Bc

  end

  if n == 0 then

    Fc = color

  else

    Bc = color

  end

  gsF(Fc)

  gsB(Bc)

  gpu.set(x+t, y, S)

end



gsB(0)

gpu.fill(1, 1, w, h, " ")

for i = 1, h do

  tbl[i] = {}

  for j = 1, h do

    ti(tbl1.x, i)

    ti(tbl1.y, j)

  end

end

for n = 1, #tbl1.x do

  k = r(n)

  tbl1.x[n], tbl1.x[k], tbl1.y[n], tbl1.y[k] =

  tbl1.x[k], tbl1.x[n], tbl1.y[k], tbl1.y[n]

end

while true do

  for i = 1, h do

    for j = 1, h do

      tbl[i][j] = 0

    end

  end

  for i = 1, h do

    m = r(0, 1)

    tbl[i][1], tbl[1][i] = m, m

  end

  C, D, i, j = r(0, 255), t

  for y = 2, #tbl do

    for x = y, #tbl[y] do

      q = xr(tbl[x-1][y], tbl[x][y-1])

      tbl[x][y], tbl[y][x] = q, q

    end

  end

  for o = 1, #tbl1.x do

    i, j = tbl1.x[o], tbl1.y[o]

    p, a, b = i*j*C, -j+h*2, -i+h*2

    if tbl[i][j] == 1 then

      pix(j, i, p)

      pix(a, b, p)

      pix(a, i, p)

      pix(j, b, p)

    else

      pix(j, i, 0)

      pix(a, b, 0)

      pix(a, i, 0)

      pix(j, b, 0)

    end

    pix(r(-D+1, 0), r(1, h*2), C)

    pix(r(h*2, w-D), r(1, h*2), C)

  end

  gsF(65280)
  gsB(0)

  local e = {event.pull(1)}
  if e[1] == "key_down" or e[1] == "touch" then
    gpu.setBackground(0x0)
    gpu.fill(1, 1, w, h, " ")
    break
  end
end