
local number = {}

--------------------------------------------------------------------------------

function number.round(num) 
	if num >= 0 then
		return math.floor(num + 0.5)
	else
		return math.ceil(num - 0.5)
	end
end

function number.roundToDecimalPlaces(num, decimalPlaces)
	local mult = 10 ^ (decimalPlaces or 0)
	return number.round(num * mult) / mult
end

function number.getDigitCount(num)
	return num == 0 and 1 or math.ceil(math.log(num + 1, 10))
end

function number.shorten(num, digitCount)
	if num < 1000 then
		return num
	else
		local shortcuts = { "K", "M", "G", "T", "P", "E", "Z", "Y" }
		local index = math.floor(math.log(num, 1000))

		return number.roundToDecimalPlaces(num / 1000 ^ index, digitCount) .. shortcuts[index]
	end
end

--------------------------------------------------------------------------------

return number
