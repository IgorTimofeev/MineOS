local component = require("component")
local term = require("term")
component.gpu.setBackground(_G.OSSettings.shellBackground or 0x1B1B1B)
component.gpu.setForeground(_G.OSSettings.shellBackground or 0xEEEEEE)

local width, height = component.gpu.getResolution()
component.gpu.fill(1, 1, width, height, " ")
term.setCursor(1, 1)