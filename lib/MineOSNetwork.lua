
local component = require("component")
local computer = require("computer")
local MineOSCore = require("MineOSCore")
local MineOSPaths = require("MineOSPaths")
local GUI = require("GUI")
local event = require("event")
local fs = require("filesystem")
local MineOSNetwork = {}

----------------------------------------------------------------------------------------------------------------

local filesystemProxy = component.proxy(computer.getBootAddress())

MineOSNetwork.filesystemHandles = {}

local modemMaxPacketSize = 8192
local modemPacketReserve = 128
MineOSNetwork.modemProxy = nil
MineOSNetwork.modemPort = 1488
MineOSNetwork.modemTimeout = 2

MineOSNetwork.internetProxy = nil
MineOSNetwork.internetDelay = 0.05
MineOSNetwork.internetTimeout = 0.25

MineOSNetwork.proxySpaceUsed = 0
MineOSNetwork.proxySpaceTotal = 1073741824

MineOSNetwork.mountPaths = {
	modem = MineOSPaths.network .. "Modem/",
	FTP = MineOSPaths.network .. "FTP/"
}

----------------------------------------------------------------------------------------------------------------

local function umountProxy(type)
	for proxy in fs.mounts() do
		if proxy[type] then
			fs.umount(proxy)
		end
	end
end

function MineOSNetwork.updateComponents()
	local modemAddress, internetAddress = component.list("modem")(), component.list("internet")()
	if modemAddress then
		MineOSNetwork.modemProxy = component.proxy(modemAddress)
		MineOSNetwork.modemProxy.open(MineOSNetwork.modemPort)
	else
		MineOSNetwork.modemProxy = nil
		MineOSNetwork.umountModems()
	end

	if internetAddress then
		MineOSNetwork.internetProxy = component.proxy(internetAddress)
	else
		MineOSNetwork.internetProxy = nil
		MineOSNetwork.umountFTPs()
	end
end

----------------------------------------------------------------------------------------------------------------

function MineOSNetwork.umountFTPs()
	umountProxy("MineOSNetworkFTP")
end

function MineOSNetwork.getFTPProxyName(address, port, user)
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
	os.sleep(MineOSNetwork.internetDelay)

	local deadline, data, success, result = computer.uptime() + MineOSNetwork.internetTimeout, ""
	while computer.uptime() < deadline do
		success, result = pcall(socketHandle.read, math.huge)
		if success then
			if not result or #result == 0 then
				if #data > 0 then
					return true, data
				end
			else
				data, deadline = data .. result, computer.uptime() + MineOSNetwork.internetTimeout
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
		if result:match("TYPE okay") then
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

			local dataSocketHandle = MineOSNetwork.internetProxy.connect(address, port)
			if dataToWrite then
				os.sleep(MineOSNetwork.internetDelay)
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
		GUI.error(table.unpack(result, 2))
	end
	return table.unpack(result)
end

function MineOSNetwork.connectToFTP(address, port, user, password)
	if MineOSNetwork.internetProxy then
		local socketHandle, reason = MineOSNetwork.internetProxy.connect(address, port)
		if socketHandle then
			FTPSocketRead(socketHandle)

			local result, reason = FTPLogin(socketHandle, user, password)
			if result then

				local proxy, fileHandles, label = {}, {}, MineOSNetwork.getFTPProxyName(address, port, user)

				proxy.type = "filesystem"
				proxy.slot = 0
				proxy.address = label
				proxy.MineOSNetworkFTP = true

				proxy.getLabel = function()
					return label
				end

				proxy.spaceUsed = function()
					return MineOSNetwork.proxySpaceUsed
				end

				proxy.spaceTotal = function()
					return MineOSNetwork.proxySpaceTotal
				end

				proxy.setLabel = function(text)
					label = text
					return true
				end

				proxy.isReadOnly = function()
					return false
				end

				proxy.closeSocketHandle = function()
					fs.umount(proxy)
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
					local temporaryPath = MineOSCore.getTemporaryPath()
					
					if mode == "r" or mode == "rb" or mode == "a" or mode == "ab" then
						local success, result = FTPEnterPassiveModeAndRunCommand(socketHandle, "RETR " .. path)		
						local fileHandle = io.open(temporaryPath, "wb")
						fileHandle:write(success and result or "")
						fileHandle:close()
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
						local file = io.open(fileHandles[fileHandle].temporaryPath, "rb")
						local data = file:read("*a")
						file:close()

						check(FTPEnterPassiveModeAndRunCommand(socketHandle, "STOR " .. fileHandles[fileHandle].path, data))
					end

					fs.remove(fileHandles[fileHandle].temporaryPath)
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

function MineOSNetwork.umountModems()
	umountProxy("MineOSNetworkModem")
end

function MineOSNetwork.getModemProxyName(proxy)
	return proxy.name and proxy.name .. " (" .. proxy.address .. ")" or proxy.address
end

function MineOSNetwork.getMountedModemProxy(address)
	for proxy, path in fs.mounts() do
		if proxy.MineOSNetworkModem and proxy.address == address then
			return proxy
		end
	end
end

function MineOSNetwork.sendMessage(address, ...)
	if MineOSNetwork.modemProxy then
		return MineOSNetwork.modemProxy.send(address, MineOSNetwork.modemPort, ...)
	else
		MineOSNetwork.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function MineOSNetwork.broadcastMessage(...)
	if MineOSNetwork.modemProxy then
		return MineOSNetwork.modemProxy.broadcast(MineOSNetwork.modemPort, ...)
	else
		MineOSNetwork.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function MineOSNetwork.setSignalStrength(strength)
	if MineOSNetwork.modemProxy then
		if MineOSNetwork.modemProxy.isWireless() then
			return MineOSNetwork.modemProxy.setStrength(strength)
		else
			return false, "Modem component is not wireless"
		end
	else
		MineOSNetwork.modemProxy = nil
		return false, "Modem component is not available"
	end
end

function MineOSNetwork.broadcastComputerState(state)
	return MineOSNetwork.broadcastMessage("MineOSNetwork", state and "computerAvailable" or "computerNotAvailable", MineOSCore.properties.network.name)
end

local function newModemProxy(address)
	local function request(method, returnOnFailure, ...)
		MineOSNetwork.sendMessage(address, "MineOSNetwork", "request", method, ...)
		
		while true do
			local eventData = { event.pull(MineOSNetwork.modemTimeout, "modem_message") }
			
			if eventData[3] == address and eventData[6] == "MineOSNetwork" then
				if eventData[7] == "response" and eventData[8] == method then
					return table.unpack(eventData, 9)
				elseif eventData[7] == "accessDenied" then
					computer.pushSignal("MineOSNetwork", "accessDenied", address)
					return returnOnFailure, "Access denied"
				end
			elseif not eventData[1] then
				local proxy = MineOSNetwork.getMountedModemProxy(address)
				if proxy then
					fs.umount(proxy)
				end

				computer.pushSignal("MineOSNetwork", "timeout")

				return returnOnFailure, "Network filesystem timeout"
			end
		end
	end

	local proxy = {}

	proxy.type = "filesystem"
	proxy.address = address
	proxy.slot = 0
	proxy.MineOSNetworkModem = true
	
	proxy.getLabel = function()
		return request("getLabel", "N/A")
	end

	proxy.isReadOnly = function()
		return request("isReadOnly", 0)
	end

	proxy.spaceUsed = function()
		return request("spaceUsed", MineOSNetwork.proxySpaceUsed)
	end

	proxy.spaceTotal = function()
		return request("spaceTotal", MineOSNetwork.proxySpaceTotal)
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
		return table.fromString(request("list", "{}", path))
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
		local maxPacketSize = (MineOSNetwork.modemProxy.maxPacketSize and MineOSNetwork.modemProxy.maxPacketSize() or modemMaxPacketSize) - modemPacketReserve
		repeat
			if not request("write", false, handle, data:sub(1, maxPacketSize)) then
				return false
			end
			data = data:sub(maxPacketSize + 1)
		until #data == 0

		return true
	end

	proxy.rename = function(from, to)
		local proxyFrom = fs.get(from)
		local proxyTo = fs.get(to)

		if proxyFrom.MineOSNetworkModem or proxyTo.MineOSNetworkModem then
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
		return MineOSCore.properties.network.name or MineOSNetwork.modemProxy.address
	end,

	list = function(path)
		return table.toString(filesystemProxy.list(path))
	end,

	open = function(path, mode)
		local ID
		while not ID do
			ID = math.random(1, 0x7FFFFFFF)
			for handleID in pairs(MineOSNetwork.filesystemHandles) do
				if handleID == ID then
					ID = nil
				end
			end
		end

		MineOSNetwork.filesystemHandles[ID] = filesystemProxy.open(path, mode)
		
		return ID
	end,

	close = function(ID)
		local data, reason = filesystemProxy.close(MineOSNetwork.filesystemHandles[ID])
		MineOSNetwork.filesystemHandles[ID] = nil
		return data, reason
	end,

	read = function(ID, ...)
		return filesystemProxy.read(MineOSNetwork.filesystemHandles[ID], ...)
	end,

	write = function(ID, ...)
		return filesystemProxy.write(MineOSNetwork.filesystemHandles[ID], ...)
	end,

	seek = function(ID, ...)
		return filesystemProxy.seek(MineOSNetwork.filesystemHandles[ID], ...)
	end,
}

local function handleRequest(e1, e2, e3, e4, e5, e6, e7, e8, ...)	
	if MineOSCore.properties.network.users[e3].allowReadAndWrite then
		local result = { pcall(exceptionMethods[e8] or filesystemProxy[e8], ...) }
		MineOSNetwork.sendMessage(e3, "MineOSNetwork", "response", e8, table.unpack(result, result[1] and 2 or 1))
	else
		MineOSNetwork.sendMessage(e3, "MineOSNetwork", "accessDenied")
	end
end

----------------------------------------------------------------------------------------------------------------

function MineOSNetwork.update()
	MineOSNetwork.umountModems()
	MineOSNetwork.umountFTPs()
	MineOSNetwork.updateComponents()
	MineOSNetwork.setSignalStrength(MineOSCore.properties.network.signalStrength)
	MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)

	-- if MineOSNetwork.eventHandlerID then
	-- 	event.removeHandler(MineOSNetwork.eventHandlerID)
	-- end

	-- if MineOSCore.properties.network.enabled then
		
	-- end
end

function MineOSNetwork.disable()
	MineOSCore.properties.network.enabled = false
	MineOSCore.saveProperties()
	MineOSNetwork.update()
end

function MineOSNetwork.enable()
	MineOSCore.properties.network.enabled = true
	MineOSCore.saveProperties()
	MineOSNetwork.update()
end

----------------------------------------------------------------------------------------------------------------

event.register(
	nil,
	function(e1, e2, e3, e4, e5, e6, e7, e8, ...)
		if (e1 == "component_added" or e1 == "component_removed") and (e3 == "modem" or e3 == "internet") then
			MineOSNetwork.updateComponents()
			MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)
		elseif MineOSCore.properties.network.enabled and e1 == "modem_message" and e6 == "MineOSNetwork" then
			if e7 == "request" then
				handleRequest(e1, e2, e3, e4, e5, e6, e7, e8, ...)
			elseif e7 == "computerAvailable" or e7 == "computerAvailableRedirect" then
				for proxy in fs.mounts() do
					if proxy.MineOSNetworkModem and proxy.address == e3 then
						fs.umount(proxy)
					end
				end

				proxy = newModemProxy(e3)
				proxy.name = e8
				fs.mount(proxy, MineOSNetwork.mountPaths.modem .. e3 .. "/")

				if e7 == "computerAvailable" then
					MineOSNetwork.sendMessage(e3, "MineOSNetwork", "computerAvailableRedirect", MineOSCore.properties.network.name)
				end

				if not MineOSCore.properties.network.users[e3] then
					MineOSCore.properties.network.users[e3] = {}
					MineOSCore.saveProperties()
				end

				computer.pushSignal("MineOSNetwork", "updateProxyList")
			elseif e7 == "computerNotAvailable" then
				local proxy = MineOSNetwork.getMountedModemProxy(e3)
				if proxy then
					fs.umount(proxy)
				end

				computer.pushSignal("MineOSNetwork", "updateProxyList")
			end
		end
	end,
	math.huge,
	math.huge
)

----------------------------------------------------------------------------------------------------------------

return MineOSNetwork
