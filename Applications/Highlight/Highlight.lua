local syntax = require("syntax")
ecs.prepareToExit()
local data = ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Enter path to file"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "MineOS/Applications/Highlight.app/Resources/TestFile.txt"}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "GO!"}})
local path = data[1]

local strings = syntax.convertFileToStrings(path)
local xSize, ySize = gpu.getResolution()
buffer.square(1, 1, xSize, ySize, ecs.colors.green, 0xFFFFFF, " ")
buffer.draw(true)
syntax.viewCode(2, 2, 70, 20, strings, 1, 1, true, {from = {x = 6, y = 2}, to = {x = 3, y = 8}})

ecs.waitForTouchOrClick()
