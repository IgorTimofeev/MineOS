local PNGImage = {}

--
-- libPNGimage by TehSomeLuigi
-- Revision:
PNGImage.rev = 1
--
-- A library to load, edit and save PNGs for OpenComputers
--

--[[
	
	Feel free to use however you wish.
	This header must however be preserved should this be redistributed, even
	if in a modified form.
	
	This software comes with no warranties whatsoever.
	
	2014 TehSomeLuigi

]]--


--local DEFLATE = require("libDEFLATE")
local DeflateLua = require("deflatelua")
local CRC32Lua = require("crc32lua")

local bit = require("bit32")

local PNGImagemetatable = {}
PNGImagemetatable.__index = PNGImage




PNGImage.ColourTypes = {
	Greyscale=0,
	Truecolour=2,
	IndexedColour=3,
	GreyscaleAlpha=4,
	TruecolourAlpha=6
}






local band = bit.band
local rshift = bit.rshift



-- Unpack 32-bit unsigned integer (most-significant-byte, MSB, first)
-- from byte string.
local function __unpack_msb_uint32(s)
	local a,b,c,d = s:byte(1,#s)
	local num = (((a*256) + b) * 256 + c) * 256 + d
	return num
end

local function __write_msb_uint32(fh, int)
	-- MSB B2 B1 LSB
	
	local msb = rshift(band(0xFF000000, int), 24)
	local b2 = rshift(band(0x00FF0000, int), 16)
	local b1 = rshift(band(0x0000FF00, int), 8)
	local lsb = band(0x000000FF, int)
	
	fh:write(string.char(msb))
	fh:write(string.char(b2))
	fh:write(string.char(b1))
	fh:write(string.char(lsb))
end

local function __wbuf_msb_uint32(buf, int)
	-- MSB B2 B1 LSB
	
	local msb = rshift(band(0xFF000000, int), 24)
	local b2 = rshift(band(0x00FF0000, int), 16)
	local b1 = rshift(band(0x0000FF00, int), 8)
	local lsb = band(0x000000FF, int)
	
	buf(msb)
	buf(b2)
	buf(b1)
	buf(lsb)
end

local function __sep_msb_uint32(int)
	-- MSB B2 B1 LSB
	
	local msb = rshift(band(0xFF000000, int), 24)
	local b2 = rshift(band(0x00FF0000, int), 16)
	local b1 = rshift(band(0x0000FF00, int), 8)
	local lsb = band(0x000000FF, int)
	
	return msb, b2, b1, lsb
end

local function __pack_msb_uint16(int)
	return string.char(rshift(band(int, 0xFF00), 8), band(int, 0xFF))
end

local function __pack_lsb_uint16(int)
	return string.char(band(int, 0xFF), rshift(band(int, 0xFF00), 8))
end

-- Read 32-bit unsigned integer (most-significant-byte, MSB, first) from file.
local function __read_msb_uint32(fh)
	return __unpack_msb_uint32(fh:read(4))
end

-- Read unsigned byte (integer) from file
local function __read_byte(fh)
	return fh:read(1):byte()
end



local function getBitWidthPerPixel(ihdr)
	if ihdr.color_type == PNGImage.ColourTypes.Greyscale then -- Greyscale
		return ihdr.bit_depth
	end
	if ihdr.color_type == PNGImage.ColourTypes.Truecolour then -- Truecolour
		return ihdr.bit_depth * 3
	end
	if ihdr.color_type == PNGImage.ColourTypes.IndexedColour then -- Indexed-colour
		return ihdr.bit_depth
	end
	if ihdr.color_type == PNGImage.ColourTypes.GreyscaleAlpha then -- Greyscale + Alpha
		return ihdr.bit_depth * 2
	end
	if ihdr.color_type == PNGImage.ColourTypes.TruecolourAlpha then -- Truecolour + Alpha
		return ihdr.bit_depth * 4
	end
end

local function getByteWidthPerScanline(ihdr)
	return math.ceil((ihdr.width * getBitWidthPerPixel(ihdr)) / 8)
end

local outssmt = {}

function outssmt:__call(write)
	self.str = self.str .. string.char(write)
end

function outssmt.OutStringStream()
	local outss = {str=""}
	setmetatable(outss, outssmt)
	return outss
end




local function __parse_IHDR(fh, len)
	if len ~= 13 then
		error("PNG IHDR Corrupt - should be 13 bytes long")
	end
	
	local ihdr = {}
	
	ihdr.width = __read_msb_uint32(fh)
	ihdr.height = __read_msb_uint32(fh)
	ihdr.bit_depth = __read_byte(fh)
	ihdr.color_type = __read_byte(fh)
	ihdr.compression_method = __read_byte(fh)
	ihdr.filter_method = __read_byte(fh)
	ihdr.interlace_method = __read_byte(fh)
	
	--[[
	print("width=", ihdr.width)
	print("height=", ihdr.height)
	print("bit_depth=", ihdr.bit_depth)
	print("color_type=", ihdr.color_type)
	print("compression_method=", ihdr.compression_method)
	print("filter_method=", ihdr.filter_method)
	print("interlace_method=", ihdr.interlace_method)
	]]--
	
	return ihdr
end

--[[
local function __parse_IDAT(fh, len, commeth)
	if commeth ~= 0 then
		error("Only zlib/DEFLATE compression supported")
	end
	
	local d, msg = DEFLATE.inflate(fh, len);
	
	if not d then
		return nil, msg
	end
	
	local oh = io.open('dump.dat', 'wb')
	oh:write(d.dat)
	oh:close()
	
	return true
end
]]--

local function __parse_IDAT(fh, len, commeth, outss)
	if commeth ~= 0 then
		error("Only zlib/DEFLATE compression supported")
	end
	
	
	--local oh = io.open('dump.dat', 'wb')
	--oh:write(d.dat)
	
	--local ph = io.open('pass.dat', 'wb')
	
	local input = fh:read(len)
	
	--ph:write(input)
	--ph:close()
	
	local cfg = {input=input, output=outss, disable_crc=true}
	
	DeflateLua.inflate_zlib(cfg)
	
	--oh:close()
	
--	if not d then
--		return nil, msg
--	end
	
	return true
end



local function getPNGStdByteAtXY(ihdr, oss, x, y)
	local bpsl = getByteWidthPerScanline(ihdr) -- don't include filterType byte -- we don't store that after it has been read
	if (x <= 0) or (y <= 0) then
		return 0 -- this is what the spec says we should return when the coordinate is out of bounds -- in this part of the code, the coordinates are ONE-BASED like in good Lua
	end
	local offset_by_y = (y - 1) * bpsl
	-- now read it!
	local idx = offset_by_y + x
	return oss.str:sub(idx, idx):byte()
end


local function __paeth_predictor(a, b, c)
	local p = a + b - c
	local pa = math.abs(p - a)
	local pb = math.abs(p - b)
	local pc = math.abs(p - c)
	if pa <= pb and pa <= pc then
		return a
	elseif pb <= pc then
		return b
	else
		return c
	end
end



local function __parse_IDAT_effective_bytes(outss, ihdr)
	local bpsl = getByteWidthPerScanline(ihdr)
	local bypsl = math.ceil(getBitWidthPerPixel(ihdr) / 8)
	
	if outss.str:len() == 0 then
		error("Empty string: outss")
	end
	
	local bys = DeflateLua.stringToBytestream(outss.str)
	
	if not bys then
		error("Did not get a bytestream from string", bys, outss)
	end
	
	local out2 = outssmt.OutStringStream() -- __callable table with metatable that stores what you give it
	
	local y = 0
	
	-- x the byte being filtered;
	-- a the byte corresponding to x in the pixel immediately before the pixel containing x (or the byte immediately before x, when the bit depth is less than 8);
	-- b the byte corresponding to x in the previous scanline;
	-- c the byte corresponding to b in the pixel immediately before the pixel containing b (or the byte immediately before b, when the bit depth is less than 8).
	
	while true do
		local filterType = bys:read()
		
		if filterType == nil then
			break
		end
		
		y = y + 1
		
		for x = 1, bpsl do
			--[..c..][..b..]
			--[..a..][..x <--- what is being processed (x)
			local a = getPNGStdByteAtXY(ihdr, out2, x - bypsl, y)
			local b = getPNGStdByteAtXY(ihdr, out2, x, y - 1)
			local c = getPNGStdByteAtXY(ihdr, out2, x - bypsl, y - 1)
			
			local outVal = 0
			
			if filterType == 0 then
				-- Recon(x) = Filt(x)
				outVal = bys:read()
			elseif filterType == 1 then
				-- Recon(x) = Filt(x) + Recon(a)
				outVal = bys:read() + a
			elseif filterType == 2 then
				-- Recon(x) = Filt(x) + Recon(b)
				outVal = bys:read() + b
			elseif filterType == 3 then
				-- Recon(x) = Filt(x) + floor((Recon(a) + Recon(b)) / 2)
				outVal = bys:read() + math.floor((a + b) / 2)
			elseif filterType == 4 then
				-- Recon(x) = Filt(x) + PaethPredictor(Recon(a), Recon(b), Recon(c))
				outVal = bys:read() + __paeth_predictor(a, b, c)
			else
				error("Unsupported Filter Type: " .. tostring(filterType))
			end
			
			outVal = outVal % 256
			
			out2(outVal)
		end
	end
	
	return out2
end



local function __newPNGImage()
	local pngi = {}
	setmetatable(pngi, PNGImagemetatable)
	return pngi
end

function PNGImage.newFromFile(fn)
	local fh = io.open(fn, 'rb')
	if not fh then
		error("Could not open PNG file")
	end
	return PNGImage.newFromFileHandle(fh)
end

function PNGImage.newFromScratch(width, height, bkcol)
	local pngi = __newPNGImage()
	
	local width = tonumber(width)
	local height = tonumber(height)
	
	if (not width) or (width < 1) or (math.floor(width) ~= width) then
		error("Invalid param #1 (width) to PNGImage.newFromScratch - integer (>=0) expected")
	end
	if (not height) or (height < 1) or (math.floor(height) ~= height) then
		error("Invalid param #2 (height) to PNGImage.newFromScratch - integer (>=0) expected")
	end
	
	local bkg = {0, 0, 0, 0} -- Transparency
	
	if type(bkcol) == "table" then
		if #bkcol == 3 then
			bkg = {bkcol[1], bkcol[2], bkcol[3], 255} -- Opaque colour
		elseif #bkcol == 4 then
			bkg = {bkcol[1], bkcol[2], bkcol[3], bkcol[4]} -- Defined
		else
			error("Invalid format for param #3 (bkcol) to PNGImage.newFromScratch: nil or table expected, but the table must be of format {r, g, b} or {r, g, b, a} -- Invalid table")
		end
	elseif bkcol ~= nil then
		error("Invalid format for param #3 (bkcol) to PNGImage.newFromScratch: nil or table expected, but the table must be of format {r, g, b} or {r, g, b, a} -- Parameter is not nil or table")
	end
	
	bkg[1] = tonumber(bkg[1])
	if bkg[1] == nil then
		error("PNGImage.newFromScratch: bkg[R] is not numeric")
	end
	bkg[2] = tonumber(bkg[2])
	if bkg[2] == nil then
		error("PNGImage.newFromScratch: bkg[G] is not numeric")
	end
	bkg[3] = tonumber(bkg[3])
	if bkg[3] == nil then
		error("PNGImage.newFromScratch: bkg[B] is not numeric")
	end
	bkg[4] = tonumber(bkg[4])
	if bkg[4] == nil then
		error("PNGImage.newFromScratch: bkg[A] is not numeric")
	end
	
	pngi.ihdr = {
		width = width,
		height = height,
		bit_depth = 8,
		color_type = 6,
		compression_method = 0,
		filter_method = 0,
		interlace_method = 0
	}
	
	-- do this for every pixel.. i.e string.rep(str, w*h)
	pngi.data = string.byte(bkg[1], bkg[2], bkg[3], bkg[4]):rep(width * height)
	
	return pngi
end

function PNGImage.newFromFileHandle(fh)
	local pngi = __newPNGImage()
	local expecting = "\137\080\078\071\013\010\026\010"
	if fh:read(8) ~= expecting then -- check the 8-byte PNG header exists
		error("Not a PNG file")
	end
	
	local ihdr
	
	local outss = outssmt.OutStringStream()
	
	while true do
		local len = __read_msb_uint32(fh)
		local stype = fh:read(4)
		
		if stype == 'IHDR' then
			ihdr, msg = __parse_IHDR(fh, len)
		elseif stype == 'IDAT' then
			local res, msg = __parse_IDAT(fh, len, ihdr.compression_method, outss)
		else
			fh:read(len) -- dummy read
		end
		
		local crc = __read_msb_uint32(fh)
		
		-- print("chunk:", "type=", stype, "len=", len, "crc=", crc)
		
		if stype == 'IEND' then
			break
		end
	end
	
	fh:close()
	
	
	if ihdr.filter_method ~= 0 then
		error("Unsupported Filter Method: " .. ihdr.filter_method)
	end
	
	if ihdr.interlace_method ~= 0 then
		error("Unsupported Interlace Method (Interlacing is currently unsupported): " .. ihdr.interlace_method)
	end
	
	if ihdr.color_type ~= PNGImage.ColourTypes.TruecolourAlpha and ihdr.color_type ~= PNGImage.ColourTypes.Truecolour then
		error("Currently, only Truecolour and Truecolour+Alpha images are supported.")
	end
	
	if ihdr.bit_depth ~= 8 then
		error("Currently, only images with a bit depth of 8 are supported.")
	end
	
	--[[
	local oh = io.open('before-decode.dat', 'wb')
	oh:write(outss.str)
	oh:close()
	]]--
	
	-- now parse the IDAT chunks
	local out2 = __parse_IDAT_effective_bytes(outss, ihdr)
	
	if ihdr.color_type == PNGImage.ColourTypes.Truecolour then
		-- add an alpha layer so it effectively becomes RGBA, not RGB
		local inp = out2.str
		out2 = outssmt.OutStringStream()
		
		for i=1, ihdr.width*ihdr.height do
			local b = ((i - 1)*3) + 1
			out2(inp:byte(b)) -- R
			out2(inp:byte(b + 1)) -- G
			out2(inp:byte(b + 2)) -- B
			out2(255) -- A
		end
	end
	
	pngi.ihdr = ihdr
	pngi.data = out2.str
	
	--[[
	local oh = io.open('effective.dat', 'wb')
	oh:write(out2.str)
	oh:close()
	]]--
	
	return pngi
end


-- Warning: Co-ordinates are Zero-based but strings are 1-based
function PNGImage:getByteOffsetForPixel(x, y)
	return (((y * self.ihdr.width) + x) * 4) + 1
end

function PNGImage:getPixel(x, y)
	local off = self:getByteOffsetForPixel(x, y)
	return self.data:byte(off, off + 3)
end

function PNGImage:setPixel(x, y, col)
	local off = self:getByteOffsetForPixel(x, y)
	self.data = table.concat({self.data:sub(1, off - 1), string.char(col[1], col[2], col[3], col[4]), self.data:sub(off + 4)})
end

function PNGImage:lineXAB(ax, y, bx, col)
	for x=ax, bx do
		self:setPixel(x, y, col)
	end
end

function PNGImage:lineYAB(x, ay, by, col)
	for y=ay, by do
		self:setPixel(x, y, col)
	end
end

function PNGImage:lineRectangleAB(ax, ay, bx, by, col)
	self:lineXAB(ax, ay, bx, col)
	self:lineXAB(ax, by, bx, col)
	self:lineYAB(ax, ay, by, col)
	self:lineYAB(bx, ay, by, col)
end

function PNGImage:fillRectangleAB(ax, ay, bx, by, col)
	for x=ax, bx do
		for y=ay, by do
			self:setPixel(x, y, col)
		end
	end
end

function PNGImage:saveToFile(fn)
	local fh = io.open(fn, 'wb')
	if not fh then
		error("Could not open for writing: " .. fn)
	end
	self:saveToFileHandle(fh)
	fh:close()
end

function PNGImage:getSize()
	return self.ihdr.width, self.ihdr.height
end

function PNGImage:generateRawIDATData(outbuf)
	for y = 0, self.ihdr.height - 1 do
		outbuf(0) -- filter type is 0 (Filt(x) = Orig(x))
		for x = 0, self.ihdr.width - 1 do
			local r, g, b, a = self:getPixel(x, y)
			outbuf(r)
			outbuf(g)
			outbuf(b)
			outbuf(a)
		end
	end
end

local ZLIB_LITERAL_LIMIT = 65535

local function __raw_to_literalZLIB(inbuf)
	local outstr = string.char(8, 29) -- zlib headers
	
	while inbuf.str:len() > 0 do
		if inbuf.str:len() > ZLIB_LITERAL_LIMIT then
			outstr = outstr .. string.char(0) -- LITERAL[00] FINAL[0]
		else
			outstr = outstr .. string.char(1) -- LITERAL[00] FINAL[1]
		end
		local min = math.min(ZLIB_LITERAL_LIMIT, inbuf.str:len())
		outstr = table.concat({outstr, __pack_msb_uint16(min), __pack_msb_uint16(bit.bnot(min)), inbuf.str:sub(1, min)})
		inbuf.str = inbuf.str:sub(min + 1)
	end
	
	local adler32 = 1
	
	for i = 1, outstr:len() do
		adler32 = DeflateLua.adler32(outstr:byte(i), adler32)
	end
	
	outstr = table.concat({outstr, string.char(__sep_msb_uint32(adler32))})
	
	return outstr
end

function PNGImage:saveToFileHandle(fh)
	-- basic PNG 'encoder'
	-- most likely temporary
	local expecting = "\137\080\078\071\013\010\026\010"
	fh:write(expecting)
	
	local outbuf = outssmt.OutStringStream()
	
	__wbuf_msb_uint32(outbuf, self.ihdr.width)
	__wbuf_msb_uint32(outbuf, self.ihdr.height)
	
	outbuf(8) -- bit depth
	outbuf(6) -- colour type
	outbuf(0) -- compression method
	outbuf(0) -- filter method
	outbuf(0) -- interlace method
	
	__write_msb_uint32(fh, outbuf.str:len()) -- length field
	fh:write("IHDR") -- name of chunk
	fh:write(outbuf.str) -- chunk data
	__write_msb_uint32(fh, CRC32Lua.crc32_string("IHDR" .. outbuf.str)) -- chunk data CRC32
	outbuf.str = "" -- reset buffer
	
	-- now onto the IDAT
	
	self:generateRawIDATData(outbuf)
	
	local zlibstr = __raw_to_literalZLIB(outbuf)
	
	local tmpstr = ""
	while zlibstr:len() > 0 do
		local min = math.min(ZLIB_LITERAL_LIMIT, zlibstr:len())
		tmpstr = zlibstr:sub(1, min)
		zlibstr = zlibstr:sub(min + 1)
		
		__write_msb_uint32(fh, tmpstr:len()) -- length field
		fh:write("IDAT") -- name of chunk
		fh:write(tmpstr) -- chunk data
		__write_msb_uint32(fh, CRC32Lua.crc32_string("IDAT" .. tmpstr)) -- chunk data CRC32
		tmpstr = "" -- reset
	end
	
	__write_msb_uint32(fh, 0) -- length field
	fh:write("IEND") -- name of chunk
	-- fh:write(tmpstr) -- chunk data
	__write_msb_uint32(fh, CRC32Lua.crc32_string("IEND")) -- chunk data CRC32
end



return PNGImage
