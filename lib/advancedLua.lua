
--[[
	
	Advanced Lua Library v1.1 by ECS

	This library extends a lot of default Lua methods
	and adds some really cool features that haven't been
	implemented yet, such as fastest table serialization,
	table binary searching, string wrapping, numbers rounding, etc.

]]

_G.filesystem = _G.filesystem or require("filesystem")
_G.unicode = _G.unicode or require("unicode")
_G.bit32 = _G.bit32 or require("bit32")

-------------------------------------------------- System extensions --------------------------------------------------

function _G.getCurrentScript()
	local runLevel, info = 0
	while true do
		info = debug.getinfo(runLevel)
		if info then
			if info.what == "main" and fs.exists(info.short_src) then return info.short_src end
		else
			error("Failed to get running script: current runLevel is " .. runLevel)
		end

		runLevel = runLevel + 1
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

function bit32.numberToByteArray(number)
	local byteArray = {}
	while number > 0 do
		table.insert(byteArray, 1, bit32.band(number, 0xFF))
		number = bit32.rshift(number, 8)
	end
	return byteArray
end

function bit32.byteArrayToNumber(byteArray)
	local number = byteArray[1]
	for i = 2, #byteArray do
		number = bit32.bor(byteArray[i], bit32.lshift(number, 8))
	end
	return number
end

function bit32.bitArrayToByte(bitArray)
	local number = 0
	for i = 1, #bitArray do
		number = bit32.bor(bitArray[i], bit32.lshift(number, 1))
	end
	return number
end

bit32.byteArrayFromNumber = bit32.numberToByteArray
bit32.numberFromByteArray = bit32.byteArrayToNumber

-------------------------------------------------- Math extensions --------------------------------------------------

function math.round(num) 
	if num >= 0 then return math.floor(num + 0.5) else return math.ceil(num - 0.5) end
end

function math.roundToDecimalPlaces(num, decimalPlaces)
	local mult = 10 ^ (decimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function math.getDigitCount(num)
	local count = 0
	while number > 0 do
		number = math.floor(number / 10)
		count = count + 1
	end
	return count
end

function math.doubleToString(num, digitCount)
	return string.format("%." .. (digitCount or 1) .. "f", num)
end

-------------------------------------------------- Table extensions --------------------------------------------------

local function doSerialize(array, text, prettyLook, indentationSymbol, oldIndentationSymbol, equalsSymbol, currentRecusrionStack, recursionStackLimit)
	text = {"{"}
	table.insert(text, (prettyLook and "\n" or nil))
	
	for key, value in pairs(array) do
		local keyType, valueType, stringValue = type(key), type(value), tostring(value)

		if keyType == "number" or keyType == "string" then
			table.insert(text, (prettyLook and indentationSymbol or nil))
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
					table.insert(text, table.concat(doSerialize(value, text, prettyLook, table.concat({indentationSymbol, indentationSymbol}), table.concat({oldIndentationSymbol, indentationSymbol}), equalsSymbol, currentRecusrionStack + 1, recursionStackLimit)))
				else
					table.insert(text, "...")
				end
			else
				-- error("Unsupported table value type: " .. valueType)
			end
			
			table.insert(text, ",")
			table.insert(text, (prettyLook and "\n" or nil))
		else
			-- error("Unsupported table key type: " .. keyType)
		end
	end

	table.remove(text, (prettyLook and #text - 1 or #text))
	table.insert(text, (prettyLook and oldIndentationSymbol or nil))
	table.insert(text, "}")
	return text
end

function table.serialize(array, prettyLook, indentationWidth, indentUsingTabs, recursionStackLimit)
	checkArg(1, array, "table")
	indentationWidth = indentationWidth or 2
	local indentationSymbol = indentUsingTabs and "	" or " "
	indentationSymbol, indentationSymbolHalf = string.rep(indentationSymbol, indentationWidth)
	return table.concat(doSerialize(array, {}, prettyLook, indentationSymbol, "", prettyLook and " = " or "=", 1, recursionStackLimit or math.huge))
end

function table.unserialize(serializedString)
	checkArg(1, serializedString, "string")
	local success, result = pcall(load("return " .. serializedString))
	if success then return result else return nil, result end
end

function table.toString(...)
	return table.serialize(...)
end

function table.fromString(...)
	return table.unserialize(...)
end

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
	local size = #t
	if size == 0 then for key in pairs(t) do size = size + 1 end end
	return size
end

-------------------------------------------------- String extensions --------------------------------------------------

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

function string.limit(text, size, fromLeft, noDots)
	local length = unicode.len(text)
	if length <= size then return text end

	if fromLeft then
		if noDots then
			return unicode.sub(text, length - size + 1, -1)
		else
			return "…" .. unicode.sub(text, length - size + 2, -1)
		end
	else
		if noDots then
			return unicode.sub(text, 1, size)
		else
			return unicode.sub(text, 1, size - 1) .. "…"
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

-- local function safeCall(method, ...)
-- 	local arguments = {...}
-- 	return xpcall(function() return method(table.unpack(arguments)) end, debug.traceback)
-- end

-- local function safeCallString(str)
-- 	return safeCall(load(str))
-- end

-- print(safeCallString("return 123"))

------------------------------------------------------------------------------------------------------------------

return {loaded = true}


