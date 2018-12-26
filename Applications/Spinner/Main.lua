
require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local color = require("color")
local image = require("image")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local spinnersPath = fs.path(getCurrentScript())
local spinners = {}
local currentSpinner = 1
local spinnerLimit = 8
local spinnerHue = math.random(0, 360)
local spinnerHueStep = 20

local application = GUI.application()
application:addChild(GUI.panel(1, 1, application.width, application.height, 0x0))
local spinnerImage = application:addChild(GUI.image(1, 1, {1, 1}))

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

application.eventHandler = function(application, object, e1, e2, e3, e4, e5)
	if e1 == "key_down" then
		application:stop()
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
	
	application:draw()
end

------------------------------------------------------------------------------------------

for i = 1, spinnerLimit do
	spinners[i] = image.load(spinnersPath .. i .. ".pic")
end
spinnerImage.width = image.getWidth(spinners[currentSpinner])
spinnerImage.height = image.getHeight(spinners[currentSpinner]) 
spinnerImage.localX = math.floor(application.width / 2 - spinnerImage.width / 2)
spinnerImage.localY = math.floor(application.height / 2 - spinnerImage.height/ 2)

changeColor(spinnerHue, 1)
buffer.flush()
application:draw()

application:start(0)









