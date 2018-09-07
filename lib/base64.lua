
local bit32 = require("bit32")
local base64 = {}

--------------------------------------------------------------------------------

function base64.encode(data)
	data = {string.byte(data, 1, #data)}
	local result, dataIndex, resultIndex, chars, bit32Bor, bit32Rshift, bit32Lshift, stringChar, stringSub = {}, 1, 1, {[0] = "A", [1] = "B", [2] = "C", [3] = "D", [4] = "E", [5] = "F", [6] = "G", [7] = "H", [8] = "I", [9] = "J", [10] = "K", [11] = "L", [12] = "M", [13] = "N", [14] = "O", [15] = "P", [16] = "Q", [17] = "R", [18] = "S", [19] = "T", [20] = "U", [21] = "V", [22] = "W", [23] = "X", [24] = "Y", [25] = "Z", [26] = "a", [27] = "b", [28] = "c", [29] = "d", [30] = "e", [31] = "f", [32] = "g", [33] = "h", [34] = "i", [35] = "j", [36] = "k", [37] = "l", [38] = "m", [39] = "n", [40] = "o", [41] = "p", [42] = "q", [43] = "r", [44] = "s", [45] = "t", [46] = "u", [47] = "v", [48] = "w", [49] = "x", [50] = "y", [51] = "z", [52] = "0", [53] = "1", [54] = "2", [55] = "3", [56] = "4", [57] = "5", [58] = "6", [59] = "7", [60] = "8", [61] = "9", [62] = "+", [63] = "/"}, bit32.bor, bit32.rshift, bit32.lshift, string.byte, string.sub
	
	for i = 1, #data, 3 do
		result[resultIndex] = chars[bit32Rshift(data[dataIndex] or 0, 2)] or "="; resultIndex = resultIndex + 1
		result[resultIndex] = chars[bit32Bor(bit32Lshift((data[dataIndex] or 0) % 4, 4), bit32Rshift(data[dataIndex + 1] or 0, 4))] or "="; resultIndex = resultIndex + 1
		result[resultIndex] = #data - i > 0 and chars[bit32Bor(bit32Lshift((data[dataIndex + 1] or 0) % 16, 2), bit32Rshift(data[dataIndex + 2] or 0, 6))] or "="; resultIndex = resultIndex + 1
		result[resultIndex] = #data - i > 1 and chars[(data[dataIndex + 2] or 0) % 64] or "="; resultIndex = resultIndex + 1

		dataIndex = dataIndex + 3
	end

	return table.concat(result)
end

function base64.decode(data)
	local result, resultIndex, bytes, bit32Bor, bit32Rshift, bit32Lshift, stringChar, stringSub, byte1, byte2, byte3, byte4 = {}, 1, {["A"] = 0, ["B"] = 1, ["C"] = 2, ["D"] = 3, ["E"] = 4, ["F"] = 5, ["G"] = 6, ["H"] = 7, ["I"] = 8, ["J"] = 9, ["K"] = 10, ["L"] = 11, ["M"] = 12, ["N"] = 13, ["O"] = 14, ["P"] = 15, ["Q"] = 16, ["R"] = 17, ["S"] = 18, ["T"] = 19, ["U"] = 20, ["V"] = 21, ["W"] = 22, ["X"] = 23, ["Y"] = 24, ["Z"] = 25, ["a"] = 26, ["b"] = 27, ["c"] = 28, ["d"] = 29, ["e"] = 30, ["f"] = 31, ["g"] = 32, ["h"] = 33, ["i"] = 34, ["j"] = 35, ["k"] = 36, ["l"] = 37, ["m"] = 38, ["n"] = 39, ["o"] = 40, ["p"] = 41, ["q"] = 42, ["r"] = 43, ["s"] = 44, ["t"] = 45, ["u"] = 46, ["v"] = 47, ["w"] = 48, ["x"] = 49, ["y"] = 50, ["z"] = 51, ["0"] = 52, ["1"] = 53, ["2"] = 54, ["3"] = 55, ["4"] = 56, ["5"] = 57, ["6"] = 58, ["7"] = 59, ["8"] = 60, ["9"] = 61, ["+"] = 62, ["/"] = 63, ["="] = nil}, bit32.bor, bit32.rshift, bit32.lshift, string.char, string.sub
	
	for i = 1, #data, 4 do
		byte1, byte2, byte3, byte4 = bytes[stringSub(data, i, i)], bytes[stringSub(data, i + 1, i + 1)], bytes[stringSub(data, i + 2, i + 2)], bytes[stringSub(data, i + 3, i + 3)]

		result[resultIndex] = stringChar(bit32Bor(bit32Lshift(byte1, 2) % 256, bit32Rshift(byte2, 4))); resultIndex = resultIndex + 1
		result[resultIndex] = byte3 and stringChar(bit32Bor(bit32Lshift(byte2, 4) % 256, bit32Rshift(byte3, 2))) or ""; resultIndex = resultIndex + 1
		result[resultIndex] = byte4 and stringChar(bit32Bor(bit32Lshift(byte3, 6) % 256, byte4)) or ""; resultIndex = resultIndex + 1
	end

	return table.concat(result)
end

--------------------------------------------------------------------------------

return base64