
require("advancedLua")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local color = require("color")
local image = require("image")
local GUI = require("GUI")

------------------------------------------------------------------------------------------

local spinnersPath = fs.path(getCurrentScript()) .. "/Resources/"
local spinners = {}
local currentSpinner = 1
local spinnerLimit = 8
local spinnerHue = math.random(0, 360)
local spinnerHueStep = 20

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))
local spinnerImage = mainContainer:addChild(GUI.image(1, 1, {1, 1}))

------------------------------------------------------------------------------------------

local function changeColor(hue, saturation)
	for i = 1, #spinners do
		for y = 1, image.getHeight(spinners[i]) do
			for x = 1, image.getWidth(spinners[i]) do
				local background, foreground, alpha, symbol = image.get(spinners[i], x, y)
				local hBackground, sBackground, bBackground = color.HEXToHSB(background)
				local hForeground, sForeground, bForeground = color.HEXToHSB(foreground)
				image.set(
					spinners[i],
					x,
					y,
					color.HSBToHEX(hue, saturation, bBackground),
					color.HSBToHEX(hue, saturation, bForeground),
					alpha,
					symbol
				)
			end
		end
	end
	spinnerImage.image = spinners[currentSpinner]
end

mainContainer.eventHandler = function(mainContainer, object, eventData)
	if eventData[1] == "key_down" then
		mainContainer:stopEventHandling()
	elseif eventData[1] == "touch" then
		spinnerHue = spinnerHue + spinnerHueStep * (eventData[5] == 1 and -1 or 1)
		if spinnerHue > 360 then
			spinnerHue = 0
		elseif spinnerHue < 0 then
			spinnerHue = 360
		end
		changeColor(spinnerHue, 100)
	end
	
	currentSpinner = currentSpinner + 1
	if currentSpinner > #spinners then
		currentSpinner = 1
	end
	spinnerImage.image = spinners[currentSpinner]
	
	mainContainer:draw()
	buffer.draw()
end

------------------------------------------------------------------------------------------

for i = 1, spinnerLimit do
	spinners[i] = image.load(spinnersPath .. i .. ".pic")
end
spinnerImage.width = image.getWidth(spinners[currentSpinner])
spinnerImage.height = image.getHeight(spinners[currentSpinner]) 
spinnerImage.localX = math.floor(mainContainer.width / 2 - spinnerImage.width / 2)
spinnerImage.localY = math.floor(mainContainer.height / 2 - spinnerImage.height/ 2)

changeColor(spinnerHue, 100)
buffer.flush()
mainContainer:draw()
buffer.draw(true)

mainContainer:startEventHandling(0)









