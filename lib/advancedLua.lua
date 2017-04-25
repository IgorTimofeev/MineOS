
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

-- function filesystem.path(path)
-- 	return string.match(path, "^(.+%/).") or ""
-- end

-- function filesystem.name(path)
-- 	return string.match(path, "%/?([^%/]+)%/?$")
-- end

local function getNameAndExtension(path)
	local fileName, extension = string.match(path, "^(.+)(%.[^%/]+)%/?$")
	return (fileName or path), extension
end

function filesystem.extension(path)
	local fileName, extension = getNameAndExtension(path)
	return extension
end

function filesystem.hideExtension(path)
	local fileName, extension = getNameAndExtension(path)
	return fileName
end

function filesystem.isFileHidden(path)
	if string.match(path, "^%..+$") then return true end
	return false
end

function filesystem.sortedList(path, sortingMethod, showHiddenFiles)
	if not filesystem.exists(path) then
		error("Failed to get file list: directory \"" .. tostring(path) .. "\" doesn't exists")
	end
	if not filesystem.isDirectory(path) then
		error("Failed to get file list: path \"" .. tostring(path) .. "\" is not a directory")
	end

	local fileList, sortedFileList = {}, {}
	for file in filesystem.list(path) do
		table.insert(fileList, file)
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

			table.sort(fileList, function(a, b) return a[2] < b[2] end)

			local currentExtensionList, currentExtension = {}, fileList[1][2]
			for i = 1, #fileList do
				if currentExtension == fileList[i][2] then
					table.insert(currentExtensionList, fileList[i][1])
				else
					table.sort(currentExtensionList, function(a, b) return a < b end)
					for j = 1, #currentExtensionList do
						table.insert(sortedFileList, currentExtensionList[j])
					end
					currentExtensionList, currentExtension = {fileList[i][1]}, fileList[i][2]
				end
			end
			
			table.sort(currentExtensionList, function(a, b) return a < b end)
			for j = 1, #currentExtensionList do
				table.insert(sortedFileList, currentExtensionList[j])
			end
		elseif sortingMethod == "name" then
			sortedFileList = fileList
			table.sort(sortedFileList, function(a, b) return a < b end)
		elseif sortingMethod == "date" then
			for i = 1, #fileList do
				fileList[i] = {fileList[i], filesystem.lastModified(path .. fileList[i])}
			end

			table.sort(fileList, function(a, b) return a[2] > b[2] end)

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
	for file in filesystmem.list(path) do
		if filesystmem.isDirectory(path .. file) then
			size = size + filesystem.directorySize(path .. file)
		else
			size = size + filesystmem.size(path .. file)
		end
	end
	
	return size
end

-------------------------------------------------- Table extensions --------------------------------------------------

local function doSerialize(array, prettyLook, indentationSymbol, indentationSymbolAdder, equalsSymbol, currentRecusrionStack, recursionStackLimit)
	local text, keyType, valueType, stringValue = {"{"}
	table.insert(text, (prettyLook and "\n" or nil))
	
	for key, value in pairs(array) do
		keyType, valueType, stringValue = type(key), type(value), tostring(value)

		if keyType == "number" or keyType == "string" then
			table.insert(text, (prettyLook and table.concat({indentationSymbol, indentationSymbolAdder}) or nil))
			table.insert(text, "[")
			table.insert(text, (keyType == "string" and table.concat({"\"", key, "\""}) or key))
			table.insert(text, "]")
			table.insert(text, equalsSymbol)
			
			if valueType == "number" or valueType == "boolean" or valueType == "nil" then
				table.insert(text, stringValue)
			elseif valueType == "string" or valueType == "function" then
				table.insert(text, "\"")
				table.insert(text, stringValue)
				table.insert(text, "\"")
			elseif valueType == "table" then
				-- Ограничение стека рекурсии
				if currentRecusrionStack < recursionStackLimit then
					table.insert(text, table.concat(doSerialize(value, prettyLook, table.concat({indentationSymbol, indentationSymbolAdder}), indentationSymbolAdder, equalsSymbol, currentRecusrionStack + 1, recursionStackLimit)))
				else
					table.insert(text, "...")
				end
			end
			
			table.insert(text, ",")
			table.insert(text, (prettyLook and "\n" or nil))
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
	if success then return result else return nil, result end
end

table.toString = table.serialize
table.fromString = table.unserialize

function table.toFile(path, array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit, appendToFile)
	checkArg(1, path, "string")
	checkArg(2, array, "table")
	filesystem.makeDirectory(filesystem.path(path) or "")
	local file = io.open(path, appendToFile and "a" or "w")
	file:write(table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit))
	file:close()
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
	local function recursiveCopy(source, destination)
		for key, value in pairs(source) do
			if type(value) == "table" then
				destination[key] = {}
				recursiveCopy(source[key], destination[key])
			else
				destination[key] = value
			end
		end
	end

	local tableThatCopied = {}
	recursiveCopy(tableToCopy, tableThatCopied)

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

-------------------------------------------------- String extensions --------------------------------------------------

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

function string.limit(text, limit, mode, noDots)
	local length = unicode.len(text)
	if length <= limit then return text end

	if mode == "left" then
		if noDots then
			return unicode.sub(text, length - limit + 1, -1)
		else
			return "…" .. unicode.sub(text, length - limit + 2, -1)
		end
	elseif mode == "center" then
		local partSize = math.ceil(limit / 2)
		return unicode.sub(text, 1, partSize) .. "…" .. unicode.sub(text, -partSize + 1, -1)
	else
		if noDots then
			return unicode.sub(text, 1, limit)
		else
			return unicode.sub(text, 1, limit - 1) .. "…"
		end
	end
end

function string.wrap(strings, limit)
	strings = type(strings) == "string" and {strings} or strings

	local currentString = 1
	while currentString <= #strings do
		local words = {}; for word in string.gmatch(tostring(strings[currentString]), "[^%s]+") do table.insert(words, word) end

		local newStringThatFormedFromWords, oldStringThatFormedFromWords = "", ""
		local word = 1
		local overflow = false
		while word <= #words do
			oldStringThatFormedFromWords = oldStringThatFormedFromWords .. (word > 1 and " " or "") .. words[word]
			if unicode.len(oldStringThatFormedFromWords) > limit then
				if unicode.len(words[word]) > limit then
					local left = unicode.sub(oldStringThatFormedFromWords, 1, limit)
					local right = unicode.sub(strings[currentString], unicode.len(left) + 1, -1)
					overflow = true
					strings[currentString] = left
					if strings[currentString + 1] then
						strings[currentString + 1] = right .. " " .. strings[currentString + 1]
					else
						strings[currentString + 1] = right
					end 
				end
				break
			else
				newStringThatFormedFromWords = oldStringThatFormedFromWords
			end
			word = word + 1
		end

		if word <= #words and not overflow then
			local fuckToAdd = table.concat(words, " ", word, #words)
			if strings[currentString + 1] then
				strings[currentString + 1] = fuckToAdd .. " " .. strings[currentString + 1]
			else
				strings[currentString + 1] = fuckToAdd
			end
			strings[currentString] = newStringThatFormedFromWords
		end

		currentString = currentString + 1
	end

	return strings
end

-------------------------------------------------- Playground --------------------------------------------------

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


