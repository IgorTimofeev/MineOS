
local filesystem = require("filesystem")
local unicode = require("unicode")
local bit32 = require("bit32")

----------------------------------------------------------------------------------------------------

function _G.getCurrentScript()
	local info
	for runLevel = 0, math.huge do
		info = debug.getinfo(runLevel)
		if info then
			if info.what == "main" then
				return info.source:sub(2, -1)
			end
		else
			error("Failed to get debug info for runlevel " .. runLevel)
		end
	end
end

function _G.enum(...)
	local enums = {...}
	for i = 1, #enums do
		enums[enums[i]] = i
		enums[i] = nil
	end

	return enums
end

----------------------------------------------------------------------------------------------------

function bit32.merge(number2, number1)
	local cutter = math.ceil(math.log(number1 + 1, 256)) * 8
	while number2 > 0 do
		number1, number2, cutter = bit32.bor(bit32.lshift(bit32.band(number2, 0xFF), cutter), number1), bit32.rshift(number2, 8), cutter + 8
	end

	return number1
end

function bit32.numberToByteArray(number)
	local byteArray = {}

	repeat
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	until number <= 0

	return byteArray
end

function bit32.numberToFixedSizeByteArray(number, size)
	local byteArray, counter = {}, 0
	
	repeat
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
		counter = counter + 1
	until number <= 0

	for i = 1, size - counter do
		table.insert(byteArray, 1, 0x0)
	end

	return byteArray
end

function bit32.byteArrayToNumber(byteArray)
	local result = byteArray[1]
	for i = 2, #byteArray do
		result = bit32.bor(bit32.lshift(result, 8), byteArray[i])
	end

	return result
end

function bit32.bitArrayToByte(bitArray)
	local result = 0
	for i = 1, #bitArray do
		result = bit32.bor(bitArray[i], bit32.lshift(result, 1))
	end

	return result
end

----------------------------------------------------------------------------------------------------

function math.round(num) 
	if num >= 0 then
		return math.floor(num + 0.5)
	else
		return math.ceil(num - 0.5)
	end
end

function math.roundToDecimalPlaces(num, decimalPlaces)
	local mult = 10 ^ (decimalPlaces or 0)
	return math.round(num * mult) / mult
end

function math.getDigitCount(num)
	return num == 0 and 1 or math.ceil(math.log(num + 1, 10))
end

function math.doubleToString(num, digitCount)
	return string.format("%." .. (digitCount or 1) .. "f", num)
end

function math.shorten(number, digitCount)
	local shortcuts = {
		"K",
		"M",
		"B",
		"T"
	}

	local index = math.floor(math.log(number, 1000))
	if number < 1000 then
		return number
	elseif index > #shortcuts then
		index = #shortcuts
	end

	return math.roundToDecimalPlaces(number / 1000 ^ index, digitCount) .. shortcuts[index]
end

----------------------------------------------------------------------------------------------------

-- function filesystem.path(path)
-- 	return path:match("^(.+%/).") or ""
-- end

-- function filesystem.name(path)
-- 	return path:match("%/?([^%/]+)%/?$")
-- end

function filesystem.extension(path, lower)
	local extension = path:match("[^%/]+(%.[^%/]+)%/?$")
	return (lower and extension) and (unicode.lower(extension)) or extension
end

function filesystem.hideExtension(path)
	return path:match("(.+)%..+") or path
end

function filesystem.isFileHidden(path)
	if path:match("^%..+$") then
		return true
	end

	return false
end

function filesystem.sortedList(path, sortingMethod, showHiddenFiles, filenameMatcher, filenameMatcherCaseSensitive)
	if not filesystem.exists(path) then
		error("Failed to get file list: directory \"" .. tostring(path) .. "\" doesn't exists")
	end

	if not filesystem.isDirectory(path) then
		error("Failed to get file list: path \"" .. tostring(path) .. "\" is not a directory")
	end

	local fileList, sortedFileList = {}, {}
	for file in filesystem.list(path) do
		if not filenameMatcher or string.unicodeFind(filenameMatcherCaseSensitive and file or unicode.lower(file), filenameMatcherCaseSensitive and filenameMatcher or unicode.lower(filenameMatcher)) then
			table.insert(fileList, file)
		end
	end

	if #fileList > 0 then
		if sortingMethod == "type" then
			local extension
			for i = 1, #fileList do
				extension = filesystem.extension(fileList[i]) or "Script"
				if filesystem.isDirectory(path .. fileList[i]) and extension ~= ".app" then
					extension = ".01_Folder"
				end
				fileList[i] = {fileList[i], extension}
			end

			table.sort(fileList, function(a, b) return unicode.lower(a[2]) < unicode.lower(b[2]) end)

			local currentExtensionList, currentExtension = {}, fileList[1][2]
			for i = 1, #fileList do
				if currentExtension == fileList[i][2] then
					table.insert(currentExtensionList, fileList[i][1])
				else
					table.sort(currentExtensionList, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
					for j = 1, #currentExtensionList do
						table.insert(sortedFileList, currentExtensionList[j])
					end
					currentExtensionList, currentExtension = {fileList[i][1]}, fileList[i][2]
				end
			end
			
			table.sort(currentExtensionList, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
			
			for j = 1, #currentExtensionList do
				table.insert(sortedFileList, currentExtensionList[j])
			end
		elseif sortingMethod == "name" then
			sortedFileList = fileList
			table.sort(sortedFileList, function(a, b) return unicode.lower(a) < unicode.lower(b) end)
		elseif sortingMethod == "date" then
			for i = 1, #fileList do
				fileList[i] = {fileList[i], filesystem.lastModified(path .. fileList[i])}
			end

			table.sort(fileList, function(a, b) return unicode.lower(a[2]) > unicode.lower(b[2]) end)

			for i = 1, #fileList do
				table.insert(sortedFileList, fileList[i][1])
			end
		else
			error("Unknown sorting method: " .. tostring(sortingMethod))
		end

		local i = 1
		while i <= #sortedFileList do
			if not showHiddenFiles and filesystem.isFileHidden(sortedFileList[i]) then
				table.remove(sortedFileList, i)
			else
				i = i + 1
			end
		end
	end

	return sortedFileList
end

function filesystem.directorySize(path)
	local size = 0
	for file in filesystem.list(path) do
		if filesystem.isDirectory(path .. file) then
			size = size + filesystem.directorySize(path .. file)
		else
			size = size + filesystem.size(path .. file)
		end
	end
	
	return size
end

function filesystem.readUnicodeChar(file)
	local byteArray = {string.byte(file:read(1))}

	local nullBitPosition = 0
	for i = 1, 7 do
		if bit32.band(bit32.rshift(byteArray[1], 8 - i), 0x1) == 0x0 then
			nullBitPosition = i
			break
		end
	end

	for i = 1, nullBitPosition - 2 do
		table.insert(byteArray, string.byte(file:read(1)))
	end

	return string.char(table.unpack(byteArray))
end

----------------------------------------------------------------------------------------------------

function table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit)
	checkArg(1, array, "table")

	recursionStackLimit = recursionStackLimit or math.huge
	local indentationSymbolAdder = string.rep(indentUsingTabs and "	" or " ", indentationWidth or 2)
	local equalsSymbol = prettyLook and " = " or "="

	local function serializeRecursively(array, currentIndentationSymbol, currentRecusrionStack)
		local result, nextIndentationSymbol, keyType, valueType, stringValue = {"{"}, currentIndentationSymbol .. indentationSymbolAdder
		
		if prettyLook then
			table.insert(result, "\n")
		end
		
		for key, value in pairs(array) do
			keyType, valueType, stringValue = type(key), type(value), tostring(value)

			if prettyLook then
				table.insert(result, nextIndentationSymbol)
			end
			
			if keyType == "number" then
				table.insert(result, "[")
				table.insert(result, key)
				table.insert(result, "]")
				table.insert(result, equalsSymbol)
			elseif keyType == "string" then
				-- Короч, если типа начинается с буковки, а также если это алфавитно-нумерическая поеботня
				if prettyLook and key:match("^%a") and key:match("^[%w%_]+$") then
					table.insert(result, key)
				else
					table.insert(result, "[\"")
					table.insert(result, key)
					table.insert(result, "\"]")
				end

				table.insert(result, equalsSymbol)
			end

			if valueType == "number" or valueType == "boolean" or valueType == "nil" then
				table.insert(result, stringValue)
			elseif valueType == "string" or valueType == "function" then
				table.insert(result, "\"")
				table.insert(result, stringValue)
				table.insert(result, "\"")
			elseif valueType == "table" then
				if currentRecusrionStack < recursionStackLimit then
					table.insert(
						result,
						table.concat(
							serializeRecursively(
								value,
								nextIndentationSymbol,
								currentRecusrionStack + 1
							)
						)
					)
				else
					table.insert(result, "\"…\"")
				end
			end
			
			table.insert(result, ",")

			if prettyLook then
				table.insert(result, "\n")
			end
		end

		-- Удаляем запятую
		if prettyLook then
			if #result > 2 then
				table.remove(result, #result - 1)
			end

			table.insert(result, currentIndentationSymbol)
		else
			if #result > 1 then
				table.remove(result, #result)
			end
		end

		table.insert(result, "}")

		return result
	end
	
	return table.concat(serializeRecursively(array, "", 1))
end

function table.unserialize(serializedString)
	checkArg(1, serializedString, "string")
	
	local result, reason = load("return " .. serializedString)
	if result then
		result, reason = pcall(result)
		if result then
			return reason
		else
			return nil, reason
		end
	else
		return nil, reason
	end
end

table.toString = table.serialize
table.fromString = table.unserialize

function table.toFile(path, array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit, appendToFile)
	checkArg(1, path, "string")
	checkArg(2, array, "table")
	
	filesystem.makeDirectory(filesystem.path(path) or "")
	
	local file, reason = io.open(path, appendToFile and "a" or "w")
	if file then
		file:write(table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit))
		file:close()
	else
		error("Failed to open file for writing: " .. tostring(reason))
	end
end

function table.fromFile(path)
	checkArg(1, path, "string")
	
	if filesystem.exists(path) then
		if filesystem.isDirectory(path) then
			error("\"" .. path .. "\" is a directory")
		else
			local file = io.open(path, "r")
			local data = table.unserialize(file:read("*a"))
			file:close()
			return data
		end
	else
		error("\"" .. path .. "\" doesn't exists")
	end
end

function table.copy(tableToCopy)
	local function copyTableRecursively(source, destination)
		for key, value in pairs(source) do
			if type(value) == "table" then
				destination[key] = {}
				doTableCopy(source[key], destination[key])
			else
				destination[key] = value
			end
		end
	end

	local result = {}
	copyTableRecursively(tableToCopy, result)

	return result
end

function table.size(t)
	local size = 0
	for key in pairs(t) do size = size + 1 end
	return size
end

function table.contains(t, object)
	for _, value in pairs(t) do
		if value == object then
			return true
		end
	end
	return false
end

function table.indexOf(t, object)
	for i = 1, #t do
		if t[i] == object then 
			return i
		end
	end
end

function table.sortAlphabetically(t)
	table.sort(t, function(a, b) return a < b end)
end

----------------------------------------------------------------------------------------------------

function string.brailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128*h + 64*g + 32*f + 16*d + 8*b + 4*e + 2*c + a)
end

function string.canonicalPath(str)
	return string.gsub("/" .. str, "%/+", "/")
end

function string.optimize(str, indentationWidth)
	str = string.gsub(str, "\r\n", "\n")
	str = string.gsub(str, "	", string.rep(" ", indentationWidth or 2))
	return str
end

function string.optimizeForURLRequests(code)
	if code then
		code = string.gsub(code, "([^%w ])", function (c)
			return string.format("%%%02X", string.byte(c))
		end)
		code = string.gsub(code, " ", "+")
	end
	return code 
end

function string.unicodeFind(str, pattern, init, plain)
	if init then
		if init < 0 then
			init = -#unicode.sub(str, init)
		elseif init > 0 then
			init = #unicode.sub(str, 1, init - 1) + 1
		end
	end
	
	a, b = string.find(str, pattern, init, plain)
	
	if a then
		local ap, bp = str:sub(1, a - 1), str:sub(a,b)
		a = unicode.len(ap) + 1
		b = a + unicode.len(bp) - 1
		return a, b
	else
		return a
	end
end

function string.limit(s, limit, mode, noDots)
	local length = unicode.len(s)
	if length <= limit then return s end

	if mode == "left" then
		if noDots then
			return unicode.sub(s, length - limit + 1, -1)
		else
			return "…" .. unicode.sub(s, length - limit + 2, -1)
		end
	elseif mode == "center" then
		local integer, fractional = math.modf(limit / 2)
		if fractional == 0 then
			return unicode.sub(s, 1, integer) .. "…" .. unicode.sub(s, -integer + 1, -1)
		else
			return unicode.sub(s, 1, integer) .. "…" .. unicode.sub(s, -integer, -1)
		end
	else
		if noDots then
			return unicode.sub(s, 1, limit)
		else
			return unicode.sub(s, 1, limit - 1) .. "…"
		end
	end
end

function string.wrap(data, limit)
	if type(data) == "string" then data = {data} end

	local wrappedLines, result, preResult, position = {}

	-- Дублируем таблицу строк, шоб не перекосоебить ченить переносами
	for i = 1, #data do
		wrappedLines[i] = data[i]
	end

	-- Отсечение возврата каретки-ебуретки
	local i = 1
	while i <= #wrappedLines do
		local position = string.unicodeFind(wrappedLines[i], "\n")
		if position then
			table.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], position + 1, -1))
			wrappedLines[i] = unicode.sub(wrappedLines[i], 1, position - 1)
		end

		i = i + 1
	end

	-- Сам перенос
	local i = 1
	while i <= #wrappedLines do
		result = ""

		for word in wrappedLines[i]:gmatch("[^%s]+") do
			preResult = result .. word

			if unicode.len(preResult) > limit then
				if unicode.len(word) > limit then
					table.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], limit + 1, -1))
					result = unicode.sub(wrappedLines[i], 1, limit)
				else
					table.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], unicode.len(result) + 1, -1))	
				end

				break	
			else
				result = preResult .. " "
			end
		end

		wrappedLines[i] = result:gsub("%s+$", ""):gsub("^%s+", "")

		i = i + 1
	end

	return wrappedLines
end

----------------------------------------------------------------------------------------------------

return {loaded = true}


