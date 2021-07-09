
local filesystem = require("Filesystem")
local screen = require("Screen")
local color = require("Color")
local image = require("Image")
local GUI = require("GUI")
local system = require("System")

------------------------------------------------------------------------------------------

local spinnersPath = filesystem.path(system.getCurrentScript())
local spinners = {}
local currentSpinner = 1
local spinnerLimit = 8
local spinnerHue = math.random(0, 360)
local spinnerHueStep = 20

local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x0))
local spinnerImage = workspace:addChild(GUI.image(1, 1, {1, 1}))

------------------------------------------------------------------------------------------

local function changeColor(hue, saturation)
	for i = 1, #spinners do
		for y = 1, image.getHeight(spinners[i]) do
			for x = 1, image.getWidth(spinners[i]) do
				local background, foreground, alpha, symbol = image.get(spinners[i], x, y)
				local hBackground, sBackground, bBackground = color.integerToHSB(background)
				local hForeground, sForeground, bForeground = color.integerToHSB(foreground)
				image.set(
					spinners[i],
					x,
					y,
					color.HSBToInteger(hue, saturation, bBackground),
					color.HSBToInteger(hue, saturation, bForeground),
					alpha,
					symbol
				)
			end
		end
	end
	spinnerImage.image = spinners[currentSpinner]
end

workspace.eventHandler = function(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "key_down" then
		workspace:stop()
	elseif e1 == "touch" then
		spinnerHue = spinnerHue + spinnerHueStep * (e5 == 1 and -1 or 1)
		if spinnerHue > 360 then
			spinnerHue = 0
		elseif spinnerHue < 0 then
			spinnerHue = 360
		end
		changeColor(spinnerHue, 1)
	end
	
	currentSpinner = currentSpinner + 1
	if currentSpinner > #spinners then
		currentSpinner = 1
	end
	spinnerImage.image = spinners[currentSpinner]
	
	workspace:draw()
end

------------------------------------------------------------------------------------------

for i = 1, spinnerLimit do
	spinners[i] = image.load(spinnersPath .. i .. ".pic")
end
spinnerImage.width = image.getWidth(spinners[currentSpinner])
spinnerImage.height = image.getHeight(spinners[currentSpinner]) 
spinnerImage.localX = math.floor(workspace.width / 2 - spinnerImage.width / 2)
spinnerImage.localY = math.floor(workspace.height / 2 - spinnerImage.height/ 2)

changeColor(spinnerHue, 1)
screen.flush()
workspace:draw()

workspace:start(0)









