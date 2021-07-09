
local paths = require("Paths")
local event = require("Event")

--------------------------------------------------------------------------------

local filesystem = {
	SORTING_NAME = 1,
	SORTING_TYPE = 2,
	SORTING_DATE = 3,
}

local BUFFER_SIZE = 1024
local BOOT_PROXY

local mountedProxies = {}

--------------------------------------- String-related path processing -----------------------------------------

function filesystem.path(path)
	return path:match("^(.+%/).") or ""
end

function filesystem.name(path)
	return path:match("%/?([^%/]+%/?)$")
end

function filesystem.extension(path, lower)
	return path:match("[^%/]+(%.[^%/]+)%/?$")
end

function filesystem.hideExtension(path)
	return path:match("(.+)%..+") or path
end

function filesystem.isHidden(path)
	if path:sub(1, 1) == "." then
		return true
	end

	return false
end

function filesystem.removeSlashes(path)
	return path:gsub("/+", "/")
end

--------------------------------------- Mounted filesystem support -----------------------------------------

function filesystem.mount(cyka, path)	
	if type(cyka) == "table" then
		for i = 1, #mountedProxies do
			if mountedProxies[i].path == path then
				return false, "mount path has been taken by other mounted filesystem"
			elseif mountedProxies[i].proxy == cyka then
				return false, "proxy is already mounted"
			end
		end

		table.insert(mountedProxies, {
			path = path,
			proxy = cyka
		})

		return true
	else
		error("bad argument #1 (filesystem proxy expected, got " .. tostring(cyka) .. ")")
	end
end

function filesystem.unmount(cyka)
	if type(cyka) == "table" then
		for i = 1, #mountedProxies do
			if mountedProxies[i].proxy == cyka then
				table.remove(mountedProxies, i)
				return true
			end
		end

		return false, "specified proxy is not mounted"
	elseif type(cyka) == "string" then
		for i = 1, #mountedProxies do
			if mountedProxies[i].proxy.address == cyka then
				table.remove(mountedProxies, i)
				return true
			end
		end
		
		return false, "specified proxy address is not mounted"
	else
		error("bad argument #1 (filesystem proxy or mounted path expected, got " .. tostring(cyka) .. ")")
	end
end

function filesystem.get(path)
	checkArg(1, path, "string")

	for i = 1, #mountedProxies do
		if path:sub(1, unicode.len(mountedProxies[i].path)) == mountedProxies[i].path then
			return mountedProxies[i].proxy, unicode.sub(path, mountedProxies[i].path:len() + 1, -1)
		end
	end

	return BOOT_PROXY, path
end

function filesystem.mounts()
	local key, value
	return function()
		key, value = next(mountedProxies, key)
		if value then
			return value.proxy, value.path
		end
	end
end

--------------------------------------- I/O methods -----------------------------------------

local function readString(self, count)
	-- If current buffer content is a "part" of "count of data" we need to read
	if count > #self.buffer then
		local data, chunk = self.buffer

		while #data < count do
			chunk = self.proxy.read(self.stream, BUFFER_SIZE)

			if chunk then
				data = data .. chunk
			else
				self.position = self:seek("end", 0)

				-- EOF at start
				if data == "" then
					return nil
				-- EOF after read
				else
					return data
				end
			end
		end

		self.buffer = data:sub(count + 1, -1)
		chunk = data:sub(1, count)
		self.position = self.position + #chunk

		return chunk
	else
		local data = self.buffer:sub(1, count)
		self.buffer = self.buffer:sub(count + 1, -1)
		self.position = self.position + count

		return data
	end
end

local function readLine(self)
	local data = ""
	while true do
		if #self.buffer > 0 then
			local starting, ending = self.buffer:find("\n")
			if starting then
				local chunk = self.buffer:sub(1, starting - 1)
				self.buffer = self.buffer:sub(ending + 1, -1)
				self.position = self.position + #chunk

				return data .. chunk
			else
				data = data .. self.buffer
			end
		end

		local chunk = self.proxy.read(self.stream, BUFFER_SIZE)
		if chunk then
			self.buffer = chunk
			self.position = self.position + #chunk
		-- EOF
		else
			local data = self.buffer
			self.position = self:seek("end", 0)

			return #data > 0 and data or nil
		end
	end
end

local function lines(self)
	return function()
		local line = readLine(self)
		if line then
			return line
		else
			self:close()
		end
	end
end

local function readAll(self)
	local data, chunk = ""
	while true do
		chunk = self.proxy.read(self.stream, 4096)
		if chunk then
			data = data .. chunk
		-- EOF
		else
			self.position = self:seek("end", 0)
			return data
		end
	end
end

local function readBytes(self, count, littleEndian)
	if count == 1 then
		local data = readString(self, 1)
		if data then
			return string.byte(data)
		end

		return nil
	else
		local bytes, result = {string.byte(readString(self, count) or "\x00", 1, 8)}, 0

		if littleEndian then
			for i = #bytes, 1, -1 do
				result = bit32.bor(bit32.lshift(result, 8), bytes[i])
			end
		else
			for i = 1, #bytes do
				result = bit32.bor(bit32.lshift(result, 8), bytes[i])
			end
		end

		return result
	end
end

local function readUnicodeChar(self)
	local byteArray = {string.byte(readString(self, 1))}

	local nullBitPosition = 0
	for i = 1, 7 do
		if bit32.band(bit32.rshift(byteArray[1], 8 - i), 0x1) == 0x0 then
			nullBitPosition = i
			break
		end
	end

	for i = 1, nullBitPosition - 2 do
		table.insert(byteArray, string.byte(readString(self, 1)))
	end

	return string.char(table.unpack(byteArray))
end

local function read(self, format, ...)
	local formatType = type(format)
	if formatType == "number" then	
		return readString(self, format)
	elseif formatType == "string" then
		format = format:gsub("^%*", "")

		if format == "a" then
			return readAll(self)
		elseif format == "l" then
			return readLine(self)
		elseif format == "b" then
			return readBytes(self, 1)
		elseif format == "bs" then
			return readBytes(self, ...)
		elseif format == "u" then
			return readUnicodeChar(self)
		else
			error("bad argument #2 ('a' (whole file), 'l' (line), 'u' (unicode char), 'b' (byte as number) or 'bs' (sequence of n bytes as number) expected, got " .. format .. ")")
		end
	else
		error("bad argument #1 (number or string expected, got " .. formatType ..")")
	end
end

local function seek(self, pizda, cyka)
	if pizda == "set" then
		local result, reason = self.proxy.seek(self.stream, "set", cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	elseif pizda == "cur" then
		local result, reason = self.proxy.seek(self.stream, "set", self.position + cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	elseif pizda == "end" then
		local result, reason = self.proxy.seek(self.stream, "end", cyka)
		if result then
			self.position = result
			self.buffer = ""
		end

		return result, reason
	else
		error("bad argument #2 ('set', 'cur' or 'end' expected, got " .. tostring(pizda) .. ")")
	end
end

local function write(self, ...)
	local data = {...}
	for i = 1, #data do
		data[i] = tostring(data[i])
	end
	data = table.concat(data)

	-- Data is small enough to fit buffer
	if #data < (BUFFER_SIZE - #self.buffer) then
		self.buffer = self.buffer .. data

		return true
	else
		-- Write current buffer content
		local success, reason = self.proxy.write(self.stream, self.buffer)
		if success then
			-- If data will not fit buffer, use iterative writing with data partitioning 
			if #data > BUFFER_SIZE then
				for i = 1, #data, BUFFER_SIZE do
					success, reason = self.proxy.write(self.stream, data:sub(i, i + BUFFER_SIZE - 1))
					
					if not success then
						break
					end
				end

				self.buffer = ""

				return success, reason
			-- Data will perfectly fit in empty buffer
			else
				self.buffer = data

				return true
			end
		else
			return false, reason
		end
	end
end

local function writeBytes(self, ...)
	return write(self, string.char(...))
end

local function close(self)
	if self.write and #self.buffer > 0 then
		self.proxy.write(self.stream, self.buffer)
	end

	return self.proxy.close(self.stream)
end

function filesystem.open(path, mode)
	local proxy, proxyPath = filesystem.get(path)
	local result, reason = proxy.open(proxyPath, mode)
	if result then
		local handle = {
			proxy = proxy,
			stream = result,
			position = 0,
			buffer = "",
			close = close,
			seek = seek,
		}

		if mode == "r" or mode == "rb" then
			handle.readString = readString
			handle.readUnicodeChar = readUnicodeChar
			handle.readBytes = readBytes
			handle.readLine = readLine
			handle.lines = lines
			handle.readAll = readAll
			handle.read = read

			return handle
		elseif mode == "w" or mode == "wb" or mode == "a" or mode == "ab" then
			handle.write = write
			handle.writeBytes = writeBytes

			return handle
		else
			error("bad argument #2 ('r', 'rb', 'w', 'wb' or 'a' expected, got )" .. tostring(mode) .. ")")
		end
	else
		return nil, reason
	end
end

--------------------------------------- Rest proxy methods -----------------------------------------

function filesystem.exists(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.exists(proxyPath)
end

function filesystem.size(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.size(proxyPath)
end

function filesystem.isDirectory(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.isDirectory(proxyPath)
end

function filesystem.makeDirectory(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.makeDirectory(proxyPath)
end

function filesystem.lastModified(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.lastModified(proxyPath)
end

function filesystem.remove(path)
	local proxy, proxyPath = filesystem.get(path)
	return proxy.remove(proxyPath)
end

function filesystem.list(path, sortingMethod)
	local proxy, proxyPath = filesystem.get(path)
	
	local list, reason = proxy.list(proxyPath)	
	if list then
		-- Fullfill list with mounted paths if needed
		for i = 1, #mountedProxies do
			if path == filesystem.path(mountedProxies[i].path) then
				table.insert(list, filesystem.name(mountedProxies[i].path))
			end
		end

		-- Applying sorting methods
		if not sortingMethod or sortingMethod == filesystem.SORTING_NAME then
			table.sort(list, function(a, b)
				return unicode.lower(a) < unicode.lower(b)
			end)

			return list
		elseif sortingMethod == filesystem.SORTING_DATE then
			table.sort(list, function(a, b)
				return filesystem.lastModified(path .. a) > filesystem.lastModified(path .. b)
			end)

			return list
		elseif sortingMethod == filesystem.SORTING_TYPE then
			-- Creating a map with "extension" = {file1, file2, ...} structure
			local map, extension = {}
			for i = 1, #list do
				extension = filesystem.extension(list[i]) or "Z"
				
				-- If it's a directory without extension
				if extension:sub(1, 1) ~= "." and filesystem.isDirectory(path .. list[i]) then
					extension = "."
				end

				map[extension] = map[extension] or {}
				table.insert(map[extension], list[i])
			end

			-- Sorting lists for each extension
			local extensions = {}
			for key, value in pairs(map) do
				table.sort(value, function(a, b)
					return unicode.lower(a) < unicode.lower(b)
				end)

				table.insert(extensions, key)
			end

			-- Sorting extensions
			table.sort(extensions, function(a, b)
				return unicode.lower(a) < unicode.lower(b)
			end)

			-- Fullfilling final list
			list = {}
			for i = 1, #extensions do
				for j = 1, #map[extensions[i]] do
					table.insert(list, map[extensions[i]][j])
				end
			end

			return list
		end
	end

	return list, reason
end

function filesystem.rename(fromPath, toPath)
	local fromProxy, fromProxyPath = filesystem.get(fromPath)
	local toProxy, toProxyPath = filesystem.get(toPath)

	-- If it's the same filesystem component
	if fromProxy.address == toProxy.address then
		return fromProxy.rename(fromProxyPath, toProxyPath)
	else
		-- Copy files to destination
		filesystem.copy(fromPath, toPath)
		-- Remove original files
		filesystem.remove(fromPath)
	end
end

--------------------------------------- Advanced methods -----------------------------------------

function filesystem.copy(fromPath, toPath)
	local function copyRecursively(fromPath, toPath)
		if filesystem.isDirectory(fromPath) then
			filesystem.makeDirectory(toPath)

			local list = filesystem.list(fromPath)
			for i = 1, #list do
				copyRecursively(fromPath .. "/" .. list[i], toPath .. "/" .. list[i])
			end
		else
			local fromHandle = filesystem.open(fromPath, "rb")
			if fromHandle then
				local toHandle = filesystem.open(toPath, "wb")
				if toHandle then
					while true do
						local chunk = readString(fromHandle, BUFFER_SIZE)
						if chunk then
							if not write(toHandle, chunk) then
								break
							end
						else
							toHandle:close()
							fromHandle:close()

							break
						end
					end
				end
			end
		end
	end

	copyRecursively(fromPath, toPath)
end

function filesystem.read(path)
	local handle, reason = filesystem.open(path, "rb")
	if handle then
		local data = readAll(handle)
		handle:close()

		return data
	end

	return false, reason
end

function filesystem.lines(path)
	local handle, reason = filesystem.open(path, "rb")
	if handle then
		return handle:lines()
	else
		error(reason)
	end
end

function filesystem.readLines(path)
	local handle, reason = filesystem.open(path, "rb")
	if handle then
		local lines, index, line = {}, 1

		repeat
			line = readLine(handle)
			lines[index] = line
			index = index + 1
		until not line

		handle:close()

		return lines
	end

	return false, reason
end

local function writeOrAppend(append, path, ...)
	filesystem.makeDirectory(filesystem.path(path))
	
	local handle, reason = filesystem.open(path, append and "ab" or "wb")
	if handle then
		local result, reason = write(handle, ...)
		handle:close()

		return result, reason
	end

	return false, reason
end

function filesystem.write(path, ...)
	return writeOrAppend(false, path,...)
end

function filesystem.append(path, ...)
	return writeOrAppend(true, path, ...)
end

function filesystem.writeTable(path, ...)
	return filesystem.write(path, require("Text").serialize(...))
end

function filesystem.readTable(path)
	local result, reason = filesystem.read(path)
	if result then
		return require("Text").deserialize(result)
	end

	return result, reason
end

function filesystem.setProxy(proxy)
	BOOT_PROXY = proxy
end

function filesystem.getProxy()
	return BOOT_PROXY
end

--------------------------------------- loadfile() and dofile() implementation -----------------------------------------

function loadfile(path)
	local data, reason = filesystem.read(path)
	if data then
		return load(data, "=" .. path)
	end

	return nil, reason
end

function dofile(path, ...)
	local result, reason = loadfile(path)
	if result then
		local data = {xpcall(result, debug.traceback, ...)}
		if data[1] then
			return table.unpack(data, 2)
		else
			error(data[2])
		end
	else
		error(reason)
	end
end

--------------------------------------------------------------------------------

-- Mount all existing filesystem components
for address in component.list("filesystem") do
	filesystem.mount(component.proxy(address), paths.system.mounts .. address .. "/")
end

-- Automatically mount/unmount filesystem components
event.addHandler(function(signal, address, type)
	if signal == "component_added" and type == "filesystem" then
		filesystem.mount(component.proxy(address), paths.system.mounts .. address .. "/")
	elseif signal == "component_removed" and type == "filesystem" then
		filesystem.unmount(address)
	end
end)

--------------------------------------------------------------------------------

return filesystem
