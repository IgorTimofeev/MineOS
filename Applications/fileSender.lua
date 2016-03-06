


local event = require("event")
local modemConnection = require("modemConnection")
local component = require("component")
local ecs = require("ECSAPI")

local ECSAPI = {}

function ECSAPI.checkFileExists(path)
	if fs.exists(path) then
		return true
	else
		ecs.error("Файл \"" .. path .. "\" не существует.")
		return false
	end
end

function ECSAPI.sendData()

end

function ECSAPI.sendFile(path, address, port)
	component.modem.open(port)
	
	local fileSize = fs.size(path)
	local maxPacketSize = component.modem.maxPacketSize() - 16
	local countOfPacketsToSend = math.ceil(fileSize / maxPacketSize)

	local file = io.open(path, "rb")
	for i = 1, countOfPacketsToSend do
		local percent = math.floor(i / countOfPacketsToSend * 100)
		ecs.progressWindow("auto", "auto", 40, percent, "Отправка файла: " .. i * maxPacketSize .. "/" .. fileSize .. " байт")
		component.modem.send(address, port, file:read(maxPacketSize))
	end
	file:close()
	
	component.modem.close(port)
end

function ECSAPI.receiveFile(fromAddress, fromPort, pathToSave)
	component.modem.open(fromPort)
	
	fs.makeDirectory(fs.path(pathToSave))
	local file = io.open(pathToSave, "wb")
	while true do
		local eventData = { event.pull("modem_message") }
		if eventData[3] == fromAddress and eventData[4] == fromPort then
			file:write(eventData[6])
		end
	end
	file:close()

	component.modem.close(fromPort)
end

modemConnection.sendPersonalData()
modemConnection.search()

ECSAPI.sendFile("lib/image.lua", modemConnection.remoteAddress, 228)
ECSAPI.receiveFile(modemConnection.remoteAddress, 228, "testFileToReceive.lua")














