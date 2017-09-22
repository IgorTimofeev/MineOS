
local component = require("component")
local MineOSCore = require("MineOSCore")
local computer = require("computer")
local event = require("event")
local filesystemComponent = require("component").proxy(computer.getBootAddress())
local filesystemLibrary = require("filesystem")

-- Ебучие херолизы, с каких залупнинских хуев я должен учитывать их говнокод и синтаксические ошибки?
-- GGWP
if not filesystemLibrary.unmount and filesystemLibrary.umount then
	filesystemLibrary.unmount = filesystemLibrary.umount
end

----------------------------------------------------------------------------------------------------------------

local MineOSNetwork = {}

MineOSNetwork.modemPort = 1488
MineOSNetwork.modemProxy = nil
MineOSNetwork.modemPacketReserve = 128
MineOSNetwork.timeout = 2
MineOSNetwork.filesystemHandles = {}
MineOSNetwork.mountPath = "/ftp/"

----------------------------------------------------------------------------------------------------------------

function MineOSNetwork.getProxyName(proxy)
	return proxy.name and proxy.name .. " (" .. proxy.address .. ")" or proxy.address
end

function MineOSNetwork.getProxy(address)
	for proxy, path in filesystemLibrary.mounts() do
		if proxy.network and proxy.address == address then
			return proxy
		end
	end
end

function MineOSNetwork.getProxyCount()
	local count = 0
	for proxy, path in filesystemLibrary.mounts() do
		if proxy.network then
			count = count + 1
		end
	end

	return count
end

function MineOSNetwork.unmountAll()
	for proxy in filesystemLibrary.mounts() do
		if proxy.network then
			filesystemLibrary.unmount(proxy)
		end
	end
end

----------------------------------------------------------------------------------------------------------------

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

function MineOSNetwork.updateModemState()
	if component.isAvailable("modem") then
		MineOSNetwork.modemProxy = component.proxy(component.list("modem")())
		MineOSNetwork.modemProxy.open(MineOSNetwork.modemPort)
		
		return true
	else
		MineOSNetwork.modemProxy = nil
		MineOSNetwork.unmountAll()

		return false, "Modem component is not available"
	end
end

function MineOSNetwork.broadcastComputerState(state)
	return MineOSNetwork.broadcastMessage("MineOSNetwork", state and "computerAvailable" or "computerNotAvailable", MineOSCore.OSSettings.network.name)
end

----------------------------------------------------------------------------------------------------------------

local function newFilesystemProxy(address)
	local function request(method, returnOnFailure, ...)
		MineOSNetwork.sendMessage(address, "MineOSNetwork", "request", method, ...)
		
		while true do
			local eventData = { event.pull(MineOSNetwork.timeout, "modem_message") }
			
			if eventData[3] == address and eventData[6] == "MineOSNetwork" then
				if eventData[7] == "response" and eventData[8] == method then
					return table.unpack(eventData, 9)
				elseif eventData[7] == "accessDenied" then
					computer.pushSignal("MineOSNetwork", "accessDenied", address)
					return returnOnFailure, "Access denied"
				end
			elseif not eventData[1] then
				local proxy = MineOSNetwork.getProxy(address)
				if proxy then
					filesystemLibrary.unmount(proxy)
				end

				computer.pushSignal("MineOSNetwork", "timeout")

				return returnOnFailure, "Network filesystem timeout"
			end
		end
	end

	return {
		type = "filesystem",
		address = address,
		slot = 0,
		network = true,
		
		getLabel = function()
			return request("getLabel", "N/A")
		end,

		isReadOnly = function()
			return request("isReadOnly", "N/A")
		end,

		spaceUsed = function()
			return request("spaceUsed", "N/A")
		end,

		spaceTotal = function()
			return request("spaceTotal", "N/A")
		end,

		exists = function(path)
			return request("exists", false, path)
		end,

		isDirectory = function(path)
			return request("isDirectory", false, path)
		end,

		makeDirectory = function(path)
			return request("makeDirectory", false, path)
		end,

		setLabel = function(name)
			return request("setLabel", false, name)
		end,

		remove = function(path)
			return request("remove", false, path)
		end,

		lastModified = function(path)
			return request("lastModified", 0, path)
		end,

		size = function(path)
			return request("size", 0, path)
		end,

		list = function(path)
			return table.fromString(request("list", "{}", path))
		end,

		seek = function(handle, whence, offset)
			return request("seek", 0, handle, whence, offset)
		end,

		open = function(path, mode)
			return request("open", false, path, mode)
		end,

		close = function(handle)
			return request("close", false, handle)
		end,

		read = function(handle, count)
			return request("read", "", handle, count)
		end,

		write = function(handle, data)
			local maxPacketSize = MineOSNetwork.modemProxy.maxPacketSize() - MineOSNetwork.modemPacketReserve
			repeat
				if not request("write", false, handle, data:sub(1, maxPacketSize)) then
					return false
				end
				data = data:sub(maxPacketSize + 1)
			until #data == 0

			return true
		end,

		rename = function(from, to)
			local proxyFrom = filesystemLibrary.get(from)
			local proxyTo = filesystemLibrary.get(to)

			if proxyFrom.network or proxyTo.network then
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
		end,
	}
end

local exceptionMethods = {
	getLabel = function()
		return MineOSCore.OSSettings.network.name or MineOSNetwork.modemProxy.address
	end,

	list = function(path)
		return table.toString(filesystemComponent.list(path))
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

		MineOSNetwork.filesystemHandles[ID] = filesystemComponent.open(path, mode)
		
		return ID
	end,

	close = function(ID)
		local data, reason = filesystemComponent.close(MineOSNetwork.filesystemHandles[ID])
		MineOSNetwork.filesystemHandles[ID] = nil
		return data, reason
	end,

	read = function(ID, ...)
		return filesystemComponent.read(MineOSNetwork.filesystemHandles[ID], ...)
	end,

	write = function(ID, ...)
		return filesystemComponent.write(MineOSNetwork.filesystemHandles[ID], ...)
	end,

	seek = function(ID, ...)
		return filesystemComponent.seek(MineOSNetwork.filesystemHandles[ID], ...)
	end,
}

local function handleRequest(eventData)
	-- print("REQ", table.unpack(eventData, 6))
	
	if MineOSCore.OSSettings.network.users[eventData[3]].allowReadAndWrite then
		local result = { pcall(exceptionMethods[eventData[8]] or filesystemComponent[eventData[8]], table.unpack(eventData, 9)) }
		if result[1] then
			MineOSNetwork.sendMessage(eventData[3], "MineOSNetwork", "response", eventData[8], table.unpack(result, 2))
		else
			MineOSNetwork.sendMessage(eventData[3], "MineOSNetwork", "response", eventData[8], result[1], result[2])
		end
	else
		MineOSNetwork.sendMessage(eventData[3], "MineOSNetwork", "accessDenied")
	end
end

----------------------------------------------------------------------------------------------------------------

function MineOSNetwork.disable()
	if MineOSNetwork.eventHandler then
		event.cancel(MineOSNetwork.eventHandler.ID)
	end
	MineOSNetwork.unmountAll()
end

function MineOSNetwork.enable()
	MineOSNetwork.disable()

	MineOSNetwork.eventHandler = event.register(function(...)
		local eventData = {...}
		if eventData[1] == "component_added" or eventData[1] == "component_removed" then
			MineOSNetwork.updateModemState()
		elseif eventData[1] == "modem_message" and MineOSCore.OSSettings.network.enabled and eventData[6] == "MineOSNetwork" then
			if eventData[7] == "request" then
				handleRequest(eventData)
			elseif eventData[7] == "computerAvailable" or eventData[7] == "computerAvailableRedirect" then
				for proxy in filesystemLibrary.mounts() do
					if proxy.network and proxy.address == eventData[3] then
						filesystemLibrary.unmount(proxy)
					end
				end

				proxy = newFilesystemProxy(eventData[3])
				proxy.name = eventData[8]
				filesystemLibrary.mount(proxy, MineOSNetwork.mountPath .. eventData[3]:sub(1, 3) .. "/")

				if eventData[7] == "computerAvailable" then
					MineOSNetwork.sendMessage(eventData[3], "MineOSNetwork", "computerAvailableRedirect", MineOSCore.OSSettings.network.name)
				end

				if not MineOSCore.OSSettings.network.users[eventData[3]] then
					MineOSCore.OSSettings.network.users[eventData[3]] = {}
					MineOSCore.saveOSSettings()
				end

				computer.pushSignal("MineOSNetwork", "updateProxyList")
			elseif eventData[7] == "computerNotAvailable" then
				local proxy = MineOSNetwork.getProxy(eventData[3])
				if proxy then
					filesystemLibrary.unmount(proxy)
				end

				computer.pushSignal("MineOSNetwork", "updateProxyList")
			elseif eventData[7] == "message" and MineOSCore.OSSettings.network.users[eventData[3]].allowMessages then
				computer.pushSignal("MineOSNetwork", "message", eventData[3], eventData[8])
			end
		end
	end)
end

----------------------------------------------------------------------------------------------------------------

if not MineOSCore.OSSettings.network then
	MineOSCore.OSSettings.network = {
		users = {},
		enabled = true,
		signalStrength = 512,
	}
	MineOSCore.saveOSSettings()
end

MineOSNetwork.updateModemState()

----------------------------------------------------------------------------------------------------------------

return MineOSNetwork





