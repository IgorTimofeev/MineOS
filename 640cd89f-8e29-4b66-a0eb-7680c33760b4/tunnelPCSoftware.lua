
local component = require("component")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local modem = component.modem
local port = 512
modem.open(port)

--------------------------------------------------------------------------------------------------

local masterControllerAddress

--------------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()

mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x262626))
local textBox = mainContainer:addChild(GUI.textBox(1, 1,  mainContainer.width, mainContainer.height, nil, 0x555555, {}, 1, 0, 0, false, false))
local function info(text)
	table.insert(textBox.lines, text)
	if #textBox.lines > textBox.height then
		table.remove(textBox.lines, 1)
	end
	mainContainer:draw()
	buffer.draw()
end
local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))
layout:setCellSpacing(1, 1, 0)

local function sendFile(command, path)
	local file = io.open(path, "r")
	local data = file:read("*a")
	file:close()
	modem.broadcast(port, command, data)
end

layout:addChild(GUI.roundedButton(1, 1, 30, 3, 0xEEEEEE, 0x262626, 0x888888, 0x262626, "Прошить биос")).onTouch = function()
	sendFile("flash", "/tunnelBIOS.lua")
	masterControllerAddress = nil
end

layout:addChild(GUI.roundedButton(1, 1, 30, 3, 0xEEEEEE, 0x262626, 0x888888, 0x262626, "Оффнуть все")).onTouch = function()
	modem.broadcast(port, "tunnelState", "stop")
end

layout:addChild(GUI.roundedButton(1, 1, 30, 3, 0xEEEEEE, 0x262626, 0x888888, 0x262626, "Врубить все")).onTouch = function()
	modem.broadcast(port, "tunnelState", "start")
end

mainContainer.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "modem_message" then
		info("Message: " .. table.concat({table.unpack(eventData, 6)}, " "))
		if eventData[6] == "tunnelHandle" then
			modem.broadcast(port, "tunnelResend", table.unpack(eventData, 7))
		elseif eventData[6] == "tunnelUpdate" then
			if not masterControllerAddress then
				info("Назначаю контроллером йобу: " .. eventData[7])
				masterControllerAddress = eventData[7]
			end

			modem.send(eventData[3], port, "tunnelMasterControllerUpdate", masterControllerAddress)
		end
	end
end

--------------------------------------------------------------------------------------------------

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()


