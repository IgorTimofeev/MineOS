
local gpu = require("component").gpu
gpu.setBackground(0x1B1B1B)
gpu.setForeground(0xEEEEEE)

local width, height = gpu.getResolution()
gpu.fill(1, 1, width, height, " ")
require("term").setCursor(1, 1)