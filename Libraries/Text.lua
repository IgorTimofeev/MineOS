
local text = {}

--------------------------------------------------------------------------------

function text.serialize(t, prettyLook, indentator, recursionStackLimit)
	checkArg(1, t, "table")

	recursionStackLimit = recursionStackLimit or math.huge
	indentator = indentator or "  "
	
	local equalsSymbol = prettyLook and " = " or "="

	local function serialize(t, currentIndentationSymbol, currentRecusrionStack)
		local result, nextIndentationSymbol, keyType, valueType, stringValue = {"{"}, currentIndentationSymbol .. indentator
		
		if prettyLook then
			table.insert(result, "\n")
		end
		
		for key, value in pairs(t) do
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
							serialize(
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
	
	return table.concat(serialize(t, "", 1))
end

function text.deserialize(s)
	checkArg(1, s, "string")
	
	local result, reason = load("return " .. s)
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

function text.split(s, delimiter)
	local parts, index = {}, 1
	for part in s:gmatch(delimiter) do
		parts[index] = part
		index = index + 1
	end

	return parts
end

function text.brailleChar(a, b, c, d, e, f, g, h)
	return unicode.char(10240 + 128 * h + 64 * g + 32 * f + 16 * d + 8 * b + 4 * e + 2 * c + a)
end

function text.unicodeFind(s, pattern, init, plain)
	if init then
		if init < 0 then
			init = -#unicode.sub(s, init)
		elseif init > 0 then
			init = #unicode.sub(s, 1, init - 1) + 1
		end
	end
	
	a, b = s:find(pattern, init, plain)
	
	if a then
		local ap, bp = s:sub(1, a - 1), s:sub(a,b)
		a = unicode.len(ap) + 1
		b = a + unicode.len(bp) - 1

		return a, b
	else
		return a
	end
end

function text.limit(s, limit, mode, noDots)
	local length = unicode.len(s)
	
	if length <= limit then
		return s
	elseif mode == "left" then
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

function text.wrap(data, limit)
	if type(data) == "string" then
		data = { data }
	end

	local wrappedLines, result, preResult, position = {}

	-- Дублируем таблицу строк, шоб не перекосоебить ченить переносами
	for i = 1, #data do
		wrappedLines[i] = data[i]
	end

	-- Отсечение возврата каретки-ебуретки
	local i = 1
	while i <= #wrappedLines do
		local position = wrappedLines[i]:find("\n")
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

--------------------------------------------------------------------------------

return text