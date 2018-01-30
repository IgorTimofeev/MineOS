
-- package.loaded.doubleBuffering = nil
-- package.loaded.image = nil

local args = {...}
local image = require("image")
local buffer = require("doubleBuffering")
local gpu = require("component").gpu

gpu.setBackground(0x0)
gpu.fill(1, 1, 160, 50, " ")

-- image.draw(1, 1, image.load(args[1]))


buffer.clear(0xFF8888)
buffer.image(1, 1, image.load(args[1]))
buffer.draw(true)