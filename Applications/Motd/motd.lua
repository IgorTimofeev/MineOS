#!/bin/lua

local component = require("component")
local computer = require("computer")
local text = require("text")
local unicode = require("unicode")

if not component.isAvailable("gpu") then
	return
end

ecs.prepareToExit()

local gpu = component.gpu

local lines = { "OpenOS (customized by ECS), " .. math.floor(computer.totalMemory() / 1024) .. "KB RAM"}
local maxWidth = unicode.len(lines[1])
local f = io.open("/usr/misc/greetings/" .. _G.OSSettings.language .. ".txt")
if f then
	local greetings = {}
	pcall(function()
		for line in f:lines() do table.insert(greetings, line) end
	end)
	f:close()
	local greeting = greetings[math.random(1, #greetings)]
	if greeting then
		local width = math.max(10, component.gpu.getResolution())
		for line in text.wrappedLines(greeting, width - 4, width - 4) do
			table.insert(lines, line)
			maxWidth = math.max(maxWidth, unicode.len(line))
		end
	end
end
local borders = {{unicode.char(0x2552), unicode.char(0x2550), unicode.char(0x2555)},
								 {unicode.char(0x2502), nil, unicode.char(0x2502)},
								 {unicode.char(0x2514), unicode.char(0x2500), unicode.char(0x2518)}}

local xSize, ySize = gpu.getResolution()
local oldBackground = gpu.getBackground()
local oldForeground = gpu.getForeground()

gpu.setBackground(0xcccccc)
gpu.fill(1, 1, xSize, #lines + 2, " ")

io.write(" \n")
io.write("")
gpu.setForeground(0x000000)
io.write("  " .. text.padRight(lines[1], maxWidth) .. "  \n")
table.remove(lines, 1)
gpu.setForeground(0x555555)
for _, line in ipairs(lines) do
	io.write("  " .. text.padRight(line, maxWidth) .. "  \n")
end
io.write(" \n\n")

gpu.setBackground(oldBackground)
gpu.setForeground(oldForeground)
