
local bit32 = require("bit32")
local base64 = {}

--------------------------------------------------------------------------------

function base64.encode(data)
	local result, bytes, chars, bit32Bor, bit32Rshift, bit32Lshift, stringFormat, stringByte, stringSub = "", {}, {[0] = "A", [1] = "B", [2] = "C", [3] = "D", [4] = "E", [5] = "F", [6] = "G", [7] = "H", [8] = "I", [9] = "J", [10] = "K", [11] = "L", [12] = "M", [13] = "N", [14] = "O", [15] = "P", [16] = "Q", [17] = "R", [18] = "S", [19] = "T", [20] = "U", [21] = "V", [22] = "W", [23] = "X", [24] = "Y", [25] = "Z", [26] = "a", [27] = "b", [28] = "c", [29] = "d", [30] = "e", [31] = "f", [32] = "g", [33] = "h", [34] = "i", [35] = "j", [36] = "k", [37] = "l", [38] = "m", [39] = "n", [40] = "o", [41] = "p", [42] = "q", [43] = "r", [44] = "s", [45] = "t", [46] = "u", [47] = "v", [48] = "w", [49] = "x", [50] = "y", [51] = "z", [52] = "0", [53] = "1", [54] = "2", [55] = "3", [56] = "4", [57] = "5", [58] = "6", [59] = "7", [60] = "8", [61] = "9", [62] = "-", [63] = "_"}, bit32.bor, bit32.rshift, bit32.lshift, string.format, string.byte, string.sub
	
	for i = 0, #data - 1, 3 do
		for j = 1, 3 do
			bytes[j] = stringByte(stringSub(data, i + j)) or 0
		end
		
		result =
			result ..
			chars[bit32Rshift(bytes[1], 2)] ..
			(chars[bit32Bor(bit32Lshift(bytes[1] % 4, 4), bit32Rshift(bytes[2], 4))] or "=") ..
			(#data - i > 1 and chars[bit32Bor(bit32Lshift(bytes[2] % 16, 2), bit32Rshift(bytes[3], 6))] or "=") ..
			(#data - i > 2 and chars[bytes[3] % 64] or "=")
	end

	return result
end

function base64.decode(data)
	local result, chars, bytes, bit32Bor, bit32Rshift, bit32Lshift, stringFormat, stringChar, stringSub = "", {}, {["A"] = 0, ["B"] = 1, ["C"] = 2, ["D"] = 3, ["E"] = 4, ["F"] = 5, ["G"] = 6, ["H"] = 7, ["I"] = 8, ["J"] = 9, ["K"] = 10, ["L"] = 11, ["M"] = 12, ["N"] = 13, ["O"] = 14, ["P"] = 15, ["Q"] = 16, ["R"] = 17, ["S"] = 18, ["T"] = 19, ["U"] = 20, ["V"] = 21, ["W"] = 22, ["X"] = 23, ["Y"] = 24, ["Z"] = 25, ["a"] = 26, ["b"] = 27, ["c"] = 28, ["d"] = 29, ["e"] = 30, ["f"] = 31, ["g"] = 32, ["h"] = 33, ["i"] = 34, ["j"] = 35, ["k"] = 36, ["l"] = 37, ["m"] = 38, ["n"] = 39, ["o"] = 40, ["p"] = 41, ["q"] = 42, ["r"] = 43, ["s"] = 44, ["t"] = 45, ["u"] = 46, ["v"] = 47, ["w"] = 48, ["x"] = 49, ["y"] = 50, ["z"] = 51, ["0"] = 52, ["1"] = 53, ["2"] = 54, ["3"] = 55, ["4"] = 56, ["5"] = 57, ["6"] = 58, ["7"] = 59, ["8"] = 60, ["9"] = 61, ["-"] = 62, ["_"] = 63, ["="] = nil}, bit32.bor, bit32.rshift, bit32.lshift, string.format, string.char, string.sub
			
	for i = 0, #data - 1, 4 do
		for j = 1, 4 do
			chars[j] = bytes[stringSub(data, i + j, i + j) or "="]
		end

		result =
			result ..
			stringChar(bit32Bor(bit32Lshift(chars[1], 2) % 256, bit32Rshift(chars[2], 4))) ..
			(chars[3] and stringChar(bit32Bor(bit32Lshift(chars[2], 4) % 256, bit32Rshift(chars[3], 2))) or "") ..
			(chars[4] and stringChar(bit32Bor(bit32Lshift(chars[3], 6) % 256, chars[4])) or "")
	end

	return result
end

--------------------------------------------------------------------------------

return base64
