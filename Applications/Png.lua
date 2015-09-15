--[[
	PNGView
	by TehSomeLuigi, 2014
	
	Intended for use with OpenComputers.
	
	Feel free to use however you wish.
	This header must however be preserved should this be redistributed, even
	if in a modified form.
	
	This software comes with no warranties whatsoever.
]]--

local args = {...}

--package.loaded.libPNGimage = nil
--package.loaded.deflatelua = nil

local term = require("term")
local fs = require("filesystem")
local shell = require("shell")
local component = require("component")
local bit = require("bit32")
local PNGImage = require("libPNGimage")


local out = io.stdout
local err = io.stderr

if not args[1] then
	print("Enter filename of PNG Image:")
	io.stdout:write(": ")
	args[1] = io.read()
elseif args[1] == "-h" or args[1] == "--help" or args[1] == "-?" then
	print(" * PNGView Help *")
	print("Usage: pngview")
	print(" (asks for filename)")
	print("Usage: pngview <filename>")
	print("Use Ctrl+C to exit once started.")
end

args[1] = shell.resolve(args[1])

if not fs.exists(args[1]) then
	io.stderr:write(" * PNGView Error *\n")
	io.stderr:write("The file '" .. tostring(args[1]) .. "' does not exist on the filesystem.\n")
	return
end

if not component.isAvailable("gpu") then
	io.stderr:write(" * PNGView Error *\n")
	io.stderr:write("Component API says there is no primary GPU.\n")
	return
end

local gpu = component.getPrimary("gpu")

-- now attempt to load the PNG image
-- run in protected call to handle potential errors

local success, pngiOrError = pcall(PNGImage.newFromFile, args[1])

if not success then
	io.stderr:write(" * PNGView: PNG Loading Error *\n")
	io.stderr:write("While attempting to load '" .. tostring(args[1]) .. "' as PNG, libPNGImage erred:\n")
	io.stderr:write(pngiOrError)
	return
end

local pngi = pngiOrError

local imgW, imgH = pngi:getSize()
local maxresW, maxresH = gpu.maxResolution()

if imgW > maxresW then
	-- in future, we will attempt some scaling or scrolling
	io.stderr:write(" * PNGView: PNG Display Error *\n")
	io.stderr:write("Resolution not satisfactory: A width resolution of at least " .. imgW .. " is required, only " .. maxresW .. " available:\n")
	io.stderr:write(pngiOrError)
	return
end

if imgH > maxresH then
	-- in future, we will attempt some scaling or scrolling
	io.stderr:write(" * PNGView: PNG Display Error *\n")
	io.stderr:write("Resolution not satisfactory: A height resolution of at least " .. imgH .. " is required, only " .. maxresH .. " available:\n")
	io.stderr:write(pngiOrError)
	return
end

local oldResW, oldResH = gpu.getResolution() -- store for later
local oldBackN, oldBackB = gpu.getBackground()
local oldForeN, oldForeB = gpu.getForeground()


local block = string.char(226, 150, 136)
local trans = string.char(226, 150, 145)


gpu.setResolution(maxresW, maxresH)
gpu.setBackground(0x000000, false)

local function drawPngImage(x, y)
	for j = 0, imgW-1 do
		for i = 0, imgH-1 do
			local r, g, b, a = pngi:getPixel(i, j)
			
			if a > 0 then
				gpu.setForeground(bit.bor(bit.lshift(r, 16), bit.bor(bit.lshift(g, 8), b)), false)
				--gpu.set(x+1, y+1, block)
				gpu.fill(x + i * 2, y + j, 2, 1, block)
				--print(x, y, r, g, b, a, bit.bor(bit.lshift(r, 16), bit.bor(bit.lshift(g, 8), b)))
			--[[else
				gpu.setForeground(0x888888, false)
				gpu.set(x+1, y+1, trans)
				--print(x, y, r, g, b, a, 'tr')
			]]
			end
			--print(x, y, r, g, b, a)
		end
	end
end

ecs.prepareToExit()

drawPngImage(2, 2)

ecs.waitForTouchOrClick()

gpu.setResolution(oldResW, oldResH)
gpu.setForeground(oldForeN, oldForeB)
gpu.setBackground(oldBackN, oldBackB)
