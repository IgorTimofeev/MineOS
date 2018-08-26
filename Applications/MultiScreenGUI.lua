
local component = require("component")
local color = require("color")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local event = require("event")
local scale = require("scale")
local unicode = require("unicode")

--------------------------------------------------------------------------------

local elementWidth = 32
local GPUProxy = buffer.getGPUProxy()
local mainScreenAddress = GPUProxy.getScreen()

--------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))

local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))

local function addButton(text)
	return layout:addChild(GUI.button(1, 1, elementWidth, 3, 0x3C3C3C, 0x969696, 0x969696, 0x3C3C3C, text))
end


local mainMenu

local function calibrationMenu()
	layout:removeChildren()	

	local hSlider = layout:addChild(GUI.slider(1, 1, elementWidth, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 1, 10, 5, false, "Screens by horizontal: ", ""))
	hSlider.roundValues = true
	hSlider.height = 2

	local vSlider = layout:addChild(GUI.slider(1, 1, elementWidth, 0x66DB80, 0x0, 0xFFFFFF, 0xAAAAAA, 1, 10, 4, false, "Screens by vertical: ", ""))
	vSlider.roundValues = true
	vSlider.height = 2

	addButton("Next").onTouch = function()
		local connectedCount = -1
		for address in component.list("screen") do
			connectedCount = connectedCount + 1
		end
		
		hSlider.value, vSlider.value = math.floor(hSlider.value), math.floor(vSlider.value)
		local specifiedCount = hSlider.value * vSlider.value

		if specifiedCount <= connectedCount then
			layout:removeChildren()

			local SSX, SSY = 1, 1
			local function screenObjectDraw(object)
				buffer.drawRectangle(object.x, object.y, object.width, object.height, (SSX == object.SX and SSY == object.SY) and 0x22FF22 or 0xE1E1E1, 0x0, " ")
			end

			local function newScreen(SX, SY)
				local object = GUI.object(1, 1, 8, 3)
				object.draw = screenObjectDraw
				object.SX = SX
				object.SY = SY

				return object
			end

			local function newScreenLine(SY)
				local lineLayout = GUI.layout(1, 1, layout.width, 3, 1, 1)
				lineLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
				lineLayout:setSpacing(1, 1, 2)

				for SX = 1, hSlider.value do
					lineLayout:addChild(newScreen(SX, SY))
				end

				return lineLayout
			end

			for SY = 1, vSlider.value do
				layout:addChild(newScreenLine(SY))
			end

			mainContainer:drawOnScreen()

			local map = {}
			local hue, hueStep = 0, 360 / specifiedCount
			while true do
				local e1, e2 = event.pull("touch")
				if e2 ~= mainScreenAddress then
					GPUProxy.bind(e2, false)
					local RW, RH = scale.getResolution(1)

					GPUProxy.setResolution(RW, RH)
					GPUProxy.setBackground(color.HSBToInteger(hue, 1, 1))
					GPUProxy.setForeground(0x0)
					GPUProxy.fill(1, 1, RW, RH, " ")

					local text = "Screen " .. SSX .. "x" .. SSY .. " has been calibrated"
					GPUProxy.set(math.floor(RW / 2 - unicode.len(text) / 2), math.floor(RH / 2), text)
					
					GPUProxy.bind(mainScreenAddress, false)

					SSX, hue = SSX + 1, hue + hueStep
					if SSX > hSlider.value then
						SSX, SSY = 1, SSY + 1
						if SSY > vSlider.value then
							table.toFile("/MultiScreen.cfg", map, true)
							break
						end
					end

					map[SSY] = map[SSY] or {}
					map[SSY][SSX] = {
						address = e2,
						resolution = {
							width = RW,
							height = RH
						}
					}

					mainContainer:drawOnScreen()
				end
			end

			GUI.alert("All screens has been successfully calibrated")
			mainMenu()
		else
			GUI.alert("Invalid count of connected screens. You're specified " .. specifiedCount .. " of screens, but there's " .. connectedCount .. " connected screens")
		end
	end

	mainContainer:drawOnScreen()
end

mainMenu = function(force)
	layout:removeChildren()

	local actionComboBox = layout:addChild(GUI.comboBox(1, 1, elementWidth, 3, 0xEEEEEE, 0x2D2D2D, 0xCCCCCC, 0x888888))
	actionComboBox:addItem("Draw image")
	actionComboBox:addItem("Clear screens")
	actionComboBox:addItem("Calibrate")

	addButton("Next").onTouch = function()
		if actionComboBox.selectedItem == 1 then
			
		elseif actionComboBox.selectedItem == 2 then

		else
			calibrationMenu()
		end
	end

	mainContainer:drawOnScreen(force)
end

--------------------------------------------------------------------------------

mainMenu(true)
mainContainer:startEventHandling()