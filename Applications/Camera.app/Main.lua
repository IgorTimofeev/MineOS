
local GUI = require("GUI")
local system = require("System")
local screen = require("Screen")
local image = require("Image")
local filesystem = require("Filesystem")

if not component.isAvailable("camera") then
	GUI.alert("This program reqiures camera from computronix mod")
	return
end

local cameraProxy = component.get("camera")

local grayscale = {
	0xF0F0F0,
	0xE1E1E1,
	0xD2D2D2,
	0xC3C3C3,
	0xB4B4B4,
	0xA5A5A5,
	0x969696,
	0x878787,
	0x787878,
	0x696969,
	0x5A5A5A,
	0x4B4B4B,
	0x3C3C3C,
	0x2D2D2D,
	0x1E1E1E,
	0x0F0F0F,
}

local thermal = {
	0xFF0000,
	0xFF2400,
	0xFF4900,
	0xFF6D00,
	0xFF9200,
	0xFFB600,
	0xFFDB00,
	0xCCFF00,
	0x99FF00,
	0x33DB00,
	0x00B600,
	0x009200,
	0x006D00,
	0x004900,
	0x002400,
	0x0024BF,
	0x0000BF,
	0x002480,
	0x000080,
	0x000040,
	0x000000,
}
local palette = grayscale

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 100, 25, 0x2D2D2D))

window.backgroundPanel.width = 22
window.backgroundPanel.height = window.height
window.backgroundPanel.colors.transparency = nil

local layout = window:addChild(GUI.layout(1, 4, window.backgroundPanel.width, window.backgroundPanel.height - 3, 1, 1))
layout:setFitting(1, 1, true, false, 2, 0)
layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

layout:addChild(GUI.label(1, 1, 1, 1, 0xC3C3C3, "Select camera"):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
local comboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xF0F0F0, 0x2D2D2D, 0x444444, 0x999999))
local paletteSwitch = layout:addChild(GUI.switchAndLabel(1, 1, 16, 6, 0x66DB80, 0x0, 0xF0F0F0, 0xC3C3C3, "Thermal:", false)).switch
local semiPixelSwitch = layout:addChild(GUI.switchAndLabel(1, 1, 16, 6, 0x66DB80, 0x0, 0xF0F0F0, 0xC3C3C3, "Semipixels:", true)).switch

local autoupdateSwitch = layout:addChild(GUI.switchAndLabel(1, 1, 16, 6, 0x66DB80, 0x0, 0xF0F0F0, 0xC3C3C3, "Autoupdate:", false)).switch
local autoupdateSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x666666, 0, 10000, 1000, false, "Delay: ", " ms"))
autoupdateSlider.hidden = true

local FOVSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x666666, 10, 90, 90, false, "FOV: ", ""))
local rangeSlider = layout:addChild(GUI.slider(1, 1, 12, 0x66DB80, 0x0, 0xFFFFFF, 0x666666, 0, 60, 32, false, "Range: ", ""))

local cameraView = window:addChild(GUI.object(window.backgroundPanel.width + 1, 1, 1, 1))
cameraView.pixels = {}

local function takePicture()
	cameraView.pixels = {}

	local FOV = FOVSlider.value / FOVSlider.maximumValue
	local doubleFOV = FOV * 2

	local x, y = 1, 1
	for yRotation = FOV, -FOV, -(doubleFOV / (cameraView.height * (semiPixelSwitch.state and 2 or 1))) do
		cameraView.pixels[y] = {}
		for xRotation = FOV, -FOV, -(doubleFOV / cameraView.width) do
			cameraView.pixels[y][x] = cameraProxy.distance(xRotation, yRotation)
			
			x = x + 1
		end
		
		x, y = 1, y + 1
	end

	workspace:draw()
end

local buttonImage = image.load(filesystem.path(system.getCurrentScript()) .. "Icon.pic")
local buttonImagePressed = image.blend(buttonImage, 0x0, 0.6)
local shootButton = window:addChild(GUI.object(1, 1, 8, 4))
shootButton.draw = function()
	screen.drawImage(shootButton.x, shootButton.y, shootButton.pressed and buttonImagePressed or buttonImage)
end

shootButton.eventHandler = function(workspace, object, e1)
	if e1 == "touch" then
		shootButton.pressed = true
		workspace:draw()
		
		takePicture()

		shootButton.pressed = false
		workspace:draw()
	end
end

cameraView.draw = function(cameraView)
	screen.drawRectangle(cameraView.x, cameraView.y, cameraView.width, cameraView.height, 0xF0F0F0, 0x878787, " ")
	local x, y = 0, 0
	for y = 1, #cameraView.pixels do
		for x = 1, #cameraView.pixels[y] do
			local color = palette[math.ceil(cameraView.pixels[y][x] / rangeSlider.value * #palette)] or 0x0
			if semiPixelSwitch.state then
				screen.semiPixelSet(cameraView.x + x - 1, cameraView.y * 2 + y - 2, color)
			else
				screen.set(cameraView.x + x - 1, cameraView.y + y - 2, color, 0x0, " ")
			end
		end
	end
end

local lastUptime = computer.uptime()
layout.eventHandler = function()
	if autoupdateSwitch.state then
		local uptime = computer.uptime()
		if uptime - lastUptime >= autoupdateSlider.value / 1000 then
			takePicture()
			lastUptime = uptime
		end
	end
end

window.actionButtons:moveToFront()

semiPixelSwitch.onStateChanged = takePicture
FOVSlider.onValueChanged = takePicture

paletteSwitch.onStateChanged = function()
	palette = paletteSwitch.state and thermal or grayscale
	workspace:draw()
end

autoupdateSwitch.onStateChanged = function()
	autoupdateSlider.hidden = not autoupdateSwitch.state
	workspace:draw()
end

for address in component.list("camera") do
	comboBox:addItem(address).onTouch = function()
		cameraProxy = component.proxy(address)
		takePicture()
	end
end

window.onResize = function(width, height)
	layout.height = window.height
	window.backgroundPanel.height = window.height
	cameraView.height = window.height
	cameraView.width = window.width - window.backgroundPanel.width

	shootButton.localX = math.floor(1 + window.backgroundPanel.width / 2 - shootButton.width / 2)
	shootButton.localY = window.height - shootButton.height

	workspace:draw()
	takePicture()
end

window:resize(window.width, window.height)
