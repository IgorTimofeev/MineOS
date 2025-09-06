local GUI = require("GUI")
local FTP = require("FTP")
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
network.internetTimeout = 1

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

function network.connectToFTP(address, port, user, password)
	if not network.internetProxy then
		return false, "Internet component is not available"
	end

	local client, reason = FTP.connect(address, port)
	if not client then
		return false, reason
	end

	local result, reason = client:login(user, password)
	if not result then
		return false, reason
	end

	local result, reason = client:setMode("I")
	if not result then
		return false, reason
	end

	local result, reason = client:changeWorkingDirectory("/")
	if not result then
		return false, reason
	end	

	local function getFileField(path, field)
		local result, reason = client:getFileInfo(path, true)
		if not result then
			error(reason)
		end

		return result[field]
	end

	local label = network.getFTPProxyName(address, port, user)

	local proxy, fileHandles = {}, {}
	proxy.type = "filesystem"
	proxy.slot = 0
	proxy.address = label
	proxy.networkFTP = true
	
	-- Send command every 30 seconds so server wont suddenly drop connection
	local timerHandler = event.addHandler(
		function()
			client:keepAlive()
		end,
		30
	)

	function proxy.getLabel()
		return label
	end

	function proxy.spaceUsed()
		return network.proxySpaceUsed
	end

	function proxy.spaceTotal()
		return network.proxySpaceTotal
	end

	function proxy.setLabel(text) 
		label = text
		return true
	end

	function proxy.isReadOnly()
		return false
	end

	function proxy.closeSocketHandle()
		filesystem.unmount(proxy)
		event.removeHandler(timerHandler)

		return client:close()
	end

	function proxy.list(path)
		local result, reason = client:listDirectory(path)

		if not result then
			error(reason)
		end

		local list = {}
		for _, entry in pairs(result) do
			table.insert(list, entry.isdir and (entry.name .. "/") or entry.name)
		end

		return list
	end

	function proxy.isDirectory(path)
		return getFileField(path, "isdir")
	end
		
	function proxy.lastModified(path)
		return getFileField(path, "modify")
	end

	function proxy.size(path)
		return getFileField(path, "size")
	end

	function proxy.exists(path)
		return client:fileExists(path, true)
	end

	function proxy.open(path, mode)
		local tmp = system.getTemporaryPath()

		if mode == "r" or mode == "rb" or mode == "a" or mode == "ab" then
			local success, reason = client:readFileToFilesystem(path, tmp)
			if not success then
				error(reason)
			end
		end

		local handle, reason = filesystemProxy.open(tmp, mode)
		if not handle then
			return nil, reason
		end

		fileHandles[handle] = {
			temporaryPath = tmp,
			path = path,
			needUpload = mode ~= "r" and mode ~= "rb"
		}

		return handle
	end

	function proxy.close(handle)
		if not fileHandles[handle] then
			return
		end

		filesystemProxy.close(handle)

		if fileHandles[handle].needUpload then
			client:writeFileFromFilesystem(fileHandles[handle].path, fileHandles[handle].temporaryPath)
		end
	end

	function proxy.write(...)
		return filesystemProxy.write(...)
	end

	function proxy.read(...)
		return filesystemProxy.read(...)
	end

	function proxy.seek(...)
		return filesystemProxy.seek(...)
	end

	function proxy.remove(path)
		return client:removeFile(path)
	end

	function proxy.makeDirectory(path)
		return client:makeDirectory(path)
	end

	function proxy.rename(from, to)
		return client:renameFile(from, to)
	end
	
	return proxy
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





