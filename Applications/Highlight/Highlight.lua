local syntax = require("syntax")
ecs.prepareToExit()
local data = ecs.universalWindow("auto", "auto", 30, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Highlight.app/Resources/TestFile.txt"}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Path to file"}, {"EmptyLine"}, {"Button", 0x33db80, 0xffffff, "GO!"})
local path = data[1]
syntax.highlightFileForDebug(path, midnight)
