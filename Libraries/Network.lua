
local GUI = require("GUI")
local event = require("Event")
local filesystem = require("Filesystem")
local system = require("System")
local paths = require("Paths")
local text = require("Text")

local network = {}

----------------------------------------------------------------------------------------------------------------

local userSettings
local filesystemProxy = filesystem.getProxy()

network.filesystemHandles = {}

network.modemProxy = nil
network.modemPort = 1488
network.modemPacketReserve = 128
network.modemTimeout = 2

network.internetProxy = nil
network.internetDelay = 0.05
network.internetTimeout = 0.25

network.proxySpaceUsed = 0
network.proxySpaceTotal = 1073741824

----------------------------------------------------------------------------------------------------------------

local function unmountProxy(type)
	for proxy in filesystem.mounts() do
		if proxy[type] then
			filesystem.unmount(proxy)
		end
	end
end

function network.updateComponents()
	local modem, internet = component.get("modem"), component.get("internet")
	if modem then
		network.modemProxy = modem
		network.modemProxy.open(network.modemPort)
	else
		network.modemProxy = nil
		network.unmountModems()
	end

	if internet then
		network.internetProxy = internet
	else
		network.internetProxy = nil
		network.unmountFTPs()
	end
end

----------------------------------------------------------------------------------------------------------------

function network.unmountFTPs()
	unmountProxy("networkFTP")
end

function network.getFTPProxyName(address, port, user)
	return user .. "@" .. address .. ":" .. port
end

local function FTPSocketWrite(socketHandle, data)
	local success, result = pcall(socketHandle.write, data .. "\r\n")
	if success then
		return true, result
	else
		return false, result
	end
end

local function FTPSocketRead(socketHandle)
	event.sleep(network.internetDelay)

	local deadline, data, success, result = computer.uptime() + network.internetTimeout, ""
	while computer.uptime() < deadline do
		success, result = pcall(socketHandle.read, math.huge)
		if success then
			if not result or #result == 0 then
				if #data > 0 then
					return true, data
				end
			else
				data, deadline = data .. result, computer.uptime() + network.internetTimeout
			end
		else
			return false, result
		end
	end

	return false, "Socket read time out"
end

local function FTPParseLines(data)
	local lines = {}

	for line in data:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	return lines
end

local function FTPLogin(socketHandle, user, password)
	FTPSocketWrite(socketHandle, "USER " .. user)
	FTPSocketWrite(socketHandle, "PASS " .. password)
	FTPSocketWrite(socketHandle, "TYPE I")
	
	local success, result = FTPSocketRead(socketHandle)
	if success then
		if result:match("TYPE okay") or result:match("200") then
			return true
		else
			return false, "Authentication failed"
		end
	else
		return false, result
	end
end

local function FTPEnterPassiveModeAndRunCommand(commandSocketHandle, command, dataToWrite)
	FTPSocketWrite(commandSocketHandle, "PASV")

	local success, result = FTPSocketRead(commandSocketHandle)
	if success then
		local digits = {result:match("Entering Passive Mode %((%d+),(%d+),(%d+),(%d+),(%d+),(%d+)%)")}
		if #digits == 6 then
			local address, port =  table.concat(digits, ".", 1, 4), tonumber(digits[5]) * 256 + tonumber(digits[6])

			FTPSocketWrite(commandSocketHandle, command)

			local dataSocketHandle = network.internetProxy.connect(address, port)
			if dataToWrite then
				event.sleep(network.internetDelay)
				dataSocketHandle.read(1)
				dataSocketHandle.write(dataToWrite)
				dataSocketHandle.close()

				return true
			else
				local success, result = FTPSocketRead(dataSocketHandle)
				dataSocketHandle.close()

				if success then
					return true, result
				else
					return false, result
				end
			end
		else
			return false, "Entering passive mode failed: wrong address byte array. Socket response message was: " .. tostring(result)
		end
	else
		return false, result
	end
end

local function FTPParseFileInfo(result)
	local size, year, month, day, hour, minute, sec, type, name = result:match("Size=(%d+);Modify=(%d%d%d%d)(%d%d)(%d%d)(%d%d)(%d%d)(%d%d)[^;]*;Type=([^;]+);%s([^\r\n]+)")
	if size then
		return
			true,
			name,
			type == "dir",
			tonumber(size),
			os.time({
				year = year,
				day = day,
				month = month,
				hour = hour,
				minute = minute,
				sec = sec
			})
	else
		return false, "File not exists"
	end
end

local function FTPFileInfo(socketHandle, path, field)
	FTPSocketWrite(socketHandle, "MLST " .. path)
	
	local success, result = FTPSocketRead(socketHandle)
	if success then
		local success, name, isDirectory, size, lastModified = FTPParseFileInfo(result)
		if success then
			if field == "isDirectory" then
				return true, isDirectory
			elseif field == "lastModified" then
				return true, lastModified
			else
				return true, size
			end
		else
			return true, false
		end
	else
		return false, result
	end
end

local function check(...)
	local result = {...}
	if not result[1] then
		GUI.alert(table.unpack(result, 2))
	end
	return table.unpack(result)
end

function network.connectToFTP(address, port, user, password)
	if network.internetProxy then
		local socketHandle, reason = network.internetProxy.connect(address, port)
		if socketHandle then
			FTPSocketRead(socketHandle)

			local result, reason = FTPLogin(socketHandle, user, password)
			if result then

				local proxy, fileHandles, label = {}, {}, network.getFTPProxyName(address, port, user)

				proxy.type = "filesystem"
				proxy.slot = 0
				proxy.address = label
				proxy.networkFTP = true

				proxy.getLabel = function()
					return label
				end

				proxy.spaceUsed = function()
					return network.proxySpaceUsed
				end

				proxy.spaceTotal = function()
					return network.proxySpaceTotal
				end

				proxy.setLabel = function(text)
					label = text
					return true
				end

				proxy.isReadOnly = function()
					return false
				end

				proxy.closeSocketHandle = function()
					filesystem.unmount(proxy)
					return socketHandle.close()
				end

				proxy.list = function(path)
					local success, result = FTPEnterPassiveModeAndRunCommand(socketHandle, "MLSD -a " .. path)
					if success then
						local list = FTPParseLines(result)
						for i = 1, #list do
							local success, name, isDirectory = FTPParseFileInfo(list[i])
							if success then
								list[i] = name .. (isDirectory and "/" or "")
							end
						end

						return list
					else
						return {}
					end
				end

				proxy.isDirectory = function(path)
					local success, result = check(FTPFileInfo(socketHandle, path, "isDirectory"))
					if success then
						return result
					else
						return false
					end
				end

				proxy.lastModified = function(path)
					local success, result = check(FTPFileInfo(socketHandle, path, "lastModified"))
					if success then
						return result
					else
						return 0
					end
				end

				proxy.size = function(path)
					local success, result = check(FTPFileInfo(socketHandle, path, "size"))
					if success then
						return result
					else
						return 0
					end
				end

				proxy.exists = function(path)
					local success, result = check(FTPFileInfo(socketHandle, path))
					if success then
						return result
					else
						return false
					end
				end

				proxy.open = function(path, mode)
					local temporaryPath = system.getTemporaryPath()
					
					if mode == "r" or mode == "rb" or mode == "a" or mode == "ab" then
						local success, result = FTPEnterPassiveModeAndRunCommand(socketHandle, "RETR " .. path)		
						
						filesystem.write(temporaryPath, success and result or "")
					end
					
					local fileHandle, reason = filesystemProxy.open(temporaryPath, mode)
					if fileHandle then
						fileHandles[fileHandle] = {
							temporaryPath = temporaryPath,
							path = path,
							needUpload = mode ~= "r" and mode ~= "rb",
						}
					end

					return fileHandle, reason
				end

				proxy.close = function(fileHandle)
					filesystemProxy.close(fileHandle)

					if fileHandles[fileHandle].needUpload then
						local data = filesystem.read(fileHandles[fileHandle].temporaryPath)

						check(FTPEnterPassiveModeAndRunCommand(socketHandle, "STOR " .. fileHandles[fileHandle].path, data))
					end

					filesystem.remove(fileHandles[fileHandle].temporaryPath)
					fileHandles[fileHandle] = nil
				end

				proxy.write = function(...)
					return filesystemProxy.write(...)
				end

				proxy.read = function(...)
					return filesystemProxy.read(...)
				end

				proxy.seek = function(...)
					return filesystemProxy.seek(...)
				end

				proxy.remove = function(path)
					if proxy.isDirectory(path) then		
						local list = proxy.list(path)
						for i = 1, #list do
							proxy.remove((path .. "/" .. list[i]):gsub("/+", "/"))
						end

						FTPSocketWrite(socketHandle, "RMD " .. path)
					else
						FTPSocketWrite(socketHandle, "DELE " .. path)
					end
				end

				proxy.makeDirectory = function(path)
					FTPSocketWrite(socketHandle, "MKD " .. path)
					return true
				end

				proxy.rename = function(oldPath, newPath)
					FTPSocketWrite(socketHandle, "RNFR " .. oldPath)
					FTPSocketWrite(socketHandle, "RNTO " .. newPath)

					return true
				end

				return proxy
			else
				return false, reason
			end
		else
			return false, reason
		end
	else
		return false, "Internet component is not available"
	end
end

----------------------------------------------------------------------------------------------------------------

function network.unmountModems()
	unmountProxy("networkModem")
end

function network.getModemProxyName(proxy)
	return proxy.name and proxy.name .. " (" .. proxy.address .. ")" or proxy.address
end

function network.getMountedModemProxy(address)
	for proxy, path in filesystem.mounts() do
		if proxy.networkModem and proxy.address == address then
			return proxy
		end
	end
end

function network.sendMessage(address, ...)
	if network.modemProxy then
		return network.modemProxy.send(address, network.modemPort, ...)
	else
		network.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function network.broadcastMessage(...)
	if network.modemProxy then
		return network.modemProxy.broadcast(network.modemPort, ...)
	else
		network.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function network.setSignalStrength(strength)
	if network.modemProxy then
		if network.modemProxy.isWireless() then
			return network.modemProxy.setStrength(strength)
		else
			return false, "Modem component is not wireless"
		end
	else
		network.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function network.broadcastComputerState(state)
	return network.broadcastMessage("network", state and "computerAvailable" or "computerNotAvailable", userSettings.networkName)
end

local function newModemProxy(address)
	local function request(method, returnOnFailure, ...)
		network.sendMessage(address, "network", "request", method, ...)
		
		while true do
			local eventData = { event.pull(network.modemTimeout) }
			if eventData[1] == "modem_message" then
				if eventData[3] == address and eventData[6] == "network" then
					if eventData[7] == "response" and eventData[8] == method then
						return table.unpack(eventData, 9)
					elseif eventData[7] == "accessDenied" then
						computer.pushSignal("network", "accessDenied", address)
						return returnOnFailure, "Access denied"
					end
				elseif not eventData[1] then
					local proxy = network.getMountedModemProxy(address)
					if proxy then
						filesystem.unmount(proxy)
					end

					computer.pushSignal("network", "timeout")

					return returnOnFailure, "Network filesystem timeout"
				end
			end
		end
	end

	local proxy = {}

	proxy.type = "filesystem"
	proxy.address = address
	proxy.slot = 0
	proxy.networkModem = true
	
	proxy.getLabel = function()
		return request("getLabel", "N/A")
	end

	proxy.isReadOnly = function()
		return request("isReadOnly", 0)
	end

	proxy.spaceUsed = function()
		return request("spaceUsed", network.proxySpaceUsed)
	end

	proxy.spaceTotal = function()
		return request("spaceTotal", network.proxySpaceTotal)
	end

	proxy.exists = function(path)
		return request("exists", false, path)
	end

	proxy.isDirectory = function(path)
		return request("isDirectory", false, path)
	end

	proxy.makeDirectory = function(path)
		return request("makeDirectory", false, path)
	end

	proxy.setLabel = function(name)
		return request("setLabel", false, name)
	end

	proxy.remove = function(path)
		return request("remove", false, path)
	end

	proxy.lastModified = function(path)
		return request("lastModified", 0, path)
	end

	proxy.size = function(path)
		return request("size", 0, path)
	end

	proxy.list = function(path)
		return text.deserialize(request("list", "{}", path))
	end

	proxy.open = function(path, mode)
		return request("open", false, path, mode)
	end

	proxy.close = function(handle)
		return request("close", false, handle)
	end

	proxy.seek = function(...)
		return request("seek", 0, ...)
	end

	proxy.read = function(...)
		return request("read", "", ...)
	end

	proxy.write = function(handle, data)
		local maxPacketSize                                       -- В OC версий 1.11+ выпилили modem.maxPacketSize(), так-что чекаем, есть ли этот метод
		if network.modemProxy.maxPacketSize then
			maxPacketSize = network.modemProxy.maxPacketSize() - network.modemPacketReserve
		else
			local modemInfo = computer.getDeviceInfo()[network.modemProxy.address] -- Получаем инфу о компоненте модема
			maxPacketSize =  modemInfo.capacity - network.modemPacketReserve       -- поле capacity - макс. размер пакета
		end
		repeat
			if not request("write", false, handle, data:sub(1, maxPacketSize)) then
				return false
			end
			data = data:sub(maxPacketSize + 1)
		until #data == 0

		return true
	end

	proxy.rename = function(from, to)
		local proxyFrom = filesystem.get(from)
		local proxyTo = filesystem.get(to)

		if proxyFrom.networkModem or proxyTo.networkModem then
			local success, handleFrom, handleTo, data, reason = true
			
			handleFrom, reason = proxyFrom.open(from, "rb")
			if handleFrom then
				handleTo, reason = proxyTo.open(to, "wb")
				if handleTo then
					while true do
						data, readReason = proxyFrom.read(handleFrom, 1024)
						if data then
							success, reason = proxyTo.write(handleTo, data)
							if not success then
								break
							end
						else
							success = false
							break
						end
					end

					proxyFrom.close(handleTo)
				else
					success = false
				end

				proxyFrom.close(handleFrom)
			else
				success = false
			end

			if success then
				success, reason = proxyFrom.remove(from)
			end

			return success, reason
		else
			return request("rename", false, from, to)
		end
	end

	return proxy
end

local exceptionMethods = {
	getLabel = function()
		return userSettings.networkName or network.modemProxy.address
	end,

	list = function(path)
		return text.serialize(filesystemProxy.list(path))
	end,

	open = function(path, mode)
		local ID
		while not ID do
			ID = math.random(1, 0x7FFFFFFF)
			for handleID in pairs(network.filesystemHandles) do
				if handleID == ID then
					ID = nil
				end
			end
		end

		network.filesystemHandles[ID] = filesystemProxy.open(path, mode)
		
		return ID
	end,

	close = function(ID)
		local data, reason = filesystemProxy.close(network.filesystemHandles[ID])
		network.filesystemHandles[ID] = nil
		return data, reason
	end,

	read = function(ID, ...)
		return filesystemProxy.read(network.filesystemHandles[ID], ...)
	end,

	write = function(ID, ...)
		return filesystemProxy.write(network.filesystemHandles[ID], ...)
	end,

	seek = function(ID, ...)
		return filesystemProxy.seek(network.filesystemHandles[ID], ...)
	end,
}

local function handleRequest(eventData)	
	if userSettings.networkUsers[eventData[3]].allowReadAndWrite then
		local result = { pcall(exceptionMethods[eventData[8]] or filesystemProxy[eventData[8]], table.unpack(eventData, 9)) }
		network.sendMessage(eventData[3], "network", "response", eventData[8], table.unpack(result, result[1] and 2 or 1))
	else
		network.sendMessage(eventData[3], "network", "accessDenied")
	end
end

----------------------------------------------------------------------------------------------------------------

function network.update()
	userSettings = system.getUserSettings()
	
	network.unmountModems()
	network.unmountFTPs()
	network.updateComponents()
	network.setSignalStrength(userSettings.networkSignalStrength)
	network.broadcastComputerState(userSettings.networkEnabled)

	if network.eventHandlerID then
		event.removeHandler(network.eventHandlerID)
	end

	if userSettings.networkEnabled then
		network.eventHandlerID = event.addHandler(function(...)
			local eventData = {...}
			
			if (eventData[1] == "component_added" or eventData[1] == "component_removed") and (eventData[3] == "modem" or eventData[3] == "internet") then
				network.updateComponents()
			elseif eventData[1] == "modem_message" and userSettings.networkEnabled and eventData[6] == "network" then
				if eventData[7] == "request" then
					handleRequest(eventData)
				elseif eventData[7] == "computerAvailable" or eventData[7] == "computerAvailableRedirect" then
					for proxy in filesystem.mounts() do
						if proxy.networkModem and proxy.address == eventData[3] then
							filesystem.unmount(proxy)
						end
					end

					local proxy = newModemProxy(eventData[3])
					proxy.name = eventData[8]
					filesystem.mount(proxy, paths.system.mounts .. eventData[3] .. "/")

					if eventData[7] == "computerAvailable" then
						network.sendMessage(eventData[3], "network", "computerAvailableRedirect", userSettings.networkName)
					end

					if not userSettings.networkUsers[eventData[3]] then
						userSettings.networkUsers[eventData[3]] = {}
						system.saveUserSettings()
					end

					computer.pushSignal("network", "updateProxyList")
				elseif eventData[7] == "computerNotAvailable" then
					local proxy = network.getMountedModemProxy(eventData[3])
					if proxy then
						filesystem.unmount(proxy)
					end

					computer.pushSignal("network", "updateProxyList")
				end
			end
		end)
	end
end

function network.disable()
	userSettings.networkEnabled = false
	system.saveUserSettings()
	network.update()
end

function network.enable()
	userSettings.networkEnabled = true
	system.saveUserSettings()
	network.update()
end

----------------------------------------------------------------------------------------------------------------

-- network.updateComponents()

-- local proxy, reason = network.FTPProxy("localhost", 8888, "root", "1234")
-- print(proxy, reason)

----------------------------------------------------------------------------------------------------------------

return network





