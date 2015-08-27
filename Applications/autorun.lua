
--Загружаем самые нужные апишки
_G.component = require("component")
_G.ecs = require("ECSAPI")
_G.config = require("config")
_G.shell = require("shell")
_G.fs = require("filesystem")

ecs.clearScreen()
ecs.setScale(1)
shell.execute("OS.lua")
