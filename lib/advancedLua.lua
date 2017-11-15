
--[[
	
	Advanced Lua Library v1.1 by ECS

	This library extends a lot of default Lua methods
	and adds some really cool features that haven't been
	implemented yet, such as fastest table serialization,
	table binary searching, string wrapping, numbers rounding, etc.

]]

local filesystem = require("filesystem")
local unicode = require("unicode")
local bit32 = require("bit32")

-------------------------------------------------- System extensions --------------------------------------------------

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

function enum(...)
	local args, enums = {...}, {}
	for i = 1, #args do
		if type(args[i]) ~= "string" then error("Function argument " .. i .. " have non-string type: " .. type(args[i])) end
		enums[args[i]] = i
	end
	return enums
end

function swap(a, b)
	return b, a
end

-------------------------------------------------- Bit32 extensions --------------------------------------------------

-- Merge two numbers into one (0xAABB, 0xCCDD -> 0xAABBCCDD)
function bit32.merge(number2, number1)
	local cutter = math.ceil(math.log(number1 + 1, 256)) * 8
	while number2 > 0 do
		number1, number2, cutter = bit32.bor(bit32.lshift(bit32.band(number2, 0xFF), cutter), number1), bit32.rshift(number2, 8), cutter + 8
	end

	return number1
end

-- Split number to it's own bytes (0xAABBCC -> {0xAA, 0xBB, 0xCC})
function bit32.numberToByteArray(number)
	local byteArray = {}

	repeat
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	until number <= 0

	return byteArray
end

-- Split nubmer to it's own bytes with specified count of bytes (0xAABB, 5 -> {0x00, 0x00, 0x00, 0xAA, 0xBB})
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

-- Create number from it's own bytes ({0xAA, 0xBB, 0xCC} -> 0xAABBCC)
function bit32.byteArrayToNumber(byteArray)
	local result = byteArray[1]
	for i = 2, #byteArray do
		result = bit32.bor(bit32.lshift(result, 8), byteArray[i])
	end

	return result
end

-- Create byte from it's bits ({1, 0, 1, 0, 1, 0, 1, 1} -> 0xAB)
function bit32.bitArrayToByte(bitArray)
	local number = 0
	for i = 1, #bitArray do
		number = bit32.bor(bitArray[i], bit32.lshift(number, 1))
	end
	return number
end

-------------------------------------------------- Math extensions --------------------------------------------------

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

function math.shortenNumber(number, digitCount)
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

---------------------------------------------- Filesystem extensions ------------------------------------------------------------------------

function filesystem.path(path)
	return path:match("^(.+%/).") or ""
end

function filesystem.name(path)
	return path:match("%/?([^%/]+)%/?$")
end

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

-------------------------------------------------- Table extensions --------------------------------------------------

local function doSerialize(array, prettyLook, indentationSymbol, indentationSymbolAdder, equalsSymbol, currentRecusrionStack, recursionStackLimit)
	local text, indentationSymbolNext, keyType, valueType, stringValue = {"{"}, table.concat({indentationSymbol, indentationSymbolAdder})
	if prettyLook then
		table.insert(text, "\n")
	end
	
	for key, value in pairs(array) do
		keyType, valueType, stringValue = type(key), type(value), tostring(value)

		if prettyLook then
			table.insert(text, indentationSymbolNext)
		end
		
		if keyType == "number" then
			table.insert(text, "[")
			table.insert(text, key)
			table.insert(text, "]")
		elseif keyType == "string" then	
			if prettyLook and key:match("^%a") and key:match("^%w%_+$") then
				table.insert(text, key)
			else
				table.insert(text, "[\"")
				table.insert(text, key)
				table.insert(text, "\"]")
			end
		end

		table.insert(text, equalsSymbol)
		
		if valueType == "number" or valueType == "boolean" or valueType == "nil" then
			table.insert(text, stringValue)
		elseif valueType == "string" or valueType == "function" then
			table.insert(text, "\"")
			table.insert(text, stringValue)
			table.insert(text, "\"")
		elseif valueType == "table" then
			if currentRecusrionStack < recursionStackLimit then
				table.insert(
					text,
					table.concat(
						doSerialize(
							value,
							prettyLook,
							indentationSymbolNext,
							indentationSymbolAdder,
							equalsSymbol,
							currentRecusrionStack + 1,
							recursionStackLimit
						)
					)
				)
			else
				table.insert(text, "\"…\"")
			end
		end
		
		table.insert(text, ",")
		if prettyLook then
			table.insert(text, "\n")
		end
	end

	-- Удаляем запятую
	if prettyLook then
		if #text > 2 then
			table.remove(text, #text - 1)
		end
		-- Вставляем заодно уж символ индентации, благо чек на притти лук идет
		table.insert(text, indentationSymbol)
	else
		if #text > 1 then
			table.remove(text, #text)
		end
	end

	table.insert(text, "}")

	return text
end

function table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit)
	checkArg(1, array, "table")
	
	return table.concat(
		doSerialize(
			array,
			prettyLook,
			"",
			string.rep(indentUsingTabs and "	" or " ", indentationWidth or 2),
			prettyLook and " = " or "=",
			1,
			recursionStackLimit or math.huge
		)
	)
end

function table.unserialize(serializedString)
	checkArg(1, serializedString, "string")
	
	local success, result = pcall(load("return " .. serializedString))
	if success then
		return result
	else
		return nil, result
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

local function doTableCopy(source, destination)
	for key, value in pairs(source) do
		if type(value) == "table" then
			destination[key] = {}
			doTableCopy(source[key], destination[key])
		else
			destination[key] = value
		end
	end
end

function table.copy(tableToCopy)
	local tableThatCopied = {}
	doTableCopy(tableToCopy, tableThatCopied)

	return tableThatCopied
end

function table.binarySearch(t, requestedValue)
	local function recursiveSearch(startIndex, endIndex)
		local difference = endIndex - startIndex
		local centerIndex = math.floor(difference / 2 + startIndex)

		if difference > 1 then
			if requestedValue >= t[centerIndex] then
				return recursiveSearch(centerIndex, endIndex)
			else
				return recursiveSearch(startIndex, centerIndex)
			end
		else
			if math.abs(requestedValue - t[startIndex]) > math.abs(t[endIndex] - requestedValue) then
				return t[endIndex]
			else
				return t[startIndex]
			end
		end
	end

	return recursiveSearch(1, #t)
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

-------------------------------------------------- String extensions --------------------------------------------------

function string.brailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128*h + 64*g + 32*f + 16*d + 8*b + 4*e + 2*c + a)
end

function string.readUnicodeChar(file)
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
			init = -#unicode.sub(str,init)
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

	local wrappedLines, result, preResult, preResultLength = {}
	for i = 1, #data do
		for subLine in data[i]:gmatch("[^\n]+") do
			result = ""
			
			for word in subLine:gmatch("[^%s]+") do
				preResult = result .. word
				preResultLength = unicode.len(preResult)

				if preResultLength > limit then
					if unicode.len(word) > limit then
						table.insert(wrappedLines, unicode.sub(preResult, 1, limit))
						for i = limit + 1, preResultLength, limit do
							table.insert(wrappedLines, unicode.sub(preResult, i, i + limit - 1))
						end
						
						result = wrappedLines[#wrappedLines] .. " "
						wrappedLines[#wrappedLines] = nil
					else
						result = result:gsub("%s+$", "")
						table.insert(wrappedLines, result)
						
						result = word .. " "
					end
				else
					result = preResult .. " "
				end
			end

			result = result:gsub("%s+$", "")
			table.insert(wrappedLines, result)
		end
	end

	return wrappedLines
end

-------------------------------------------------- Playground --------------------------------------------------

-- print(table.toString(require("MineOSCore").OSSettings, true, 2, true, 2))

-- local t =  {
-- 	abc = 123,
-- 	def = {
-- 		cyka = "pidor",
-- 		vagina = {
-- 			chlen = 555,
-- 			devil = 666,
-- 			god = 777,
-- 			serost = {
-- 				tripleTable = "aefaef",
-- 				aaa = "bbb",
-- 				ccc = 123,
-- 			}
-- 		}
-- 	},
-- 	ghi = "HEHE",
-- 	emptyTable = {},
-- }

-- print(table.toString(t, true))

------------------------------------------------------------------------------------------------------------------

return {loaded = true}


