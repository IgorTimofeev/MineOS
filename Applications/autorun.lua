local ecs = require("ECSAPI")
local shell = require("shell")

ecs.clearScreen()
ecs.setScale(1)
ecs = nil
shell.run("OS.lua")
