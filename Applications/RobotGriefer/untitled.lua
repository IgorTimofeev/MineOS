
local component = require("component")
local event = require("event")
local ecs = require("ECSAPI")
local hologram = component.hologram
local printer = component.printer3d
local gpu = component.gpu

------------------------------------------------------------------------------------------------------------------------

local colors = {
	drawingZoneBackground = 0x262626,
	toolbarBackground = 0x444444,
}

local xSize, ySize = gpu.getResolution()
local widthOfToolbar = 2
local xToolbar = xSize - widthOfToolbar
local widthOfDrawingZone = xSize - widthOfToolbar

------------------------------------------------------------------------------------------------------------------------

local function drawDrawingZone()
	ecs.square(1, 1, xSize, ySize, colors.drawingZoneBackground)
end

local function drawToolbar()
	ecs.square(xToolbar, 1, widthOfToolbar, ySize, colors.toolbarBackground)
end

local function drawAll()
	drawDrawingZone()
	drawToolbar()
end

------------------------------------------------------------------------------------------------------------------------

drawAll()




