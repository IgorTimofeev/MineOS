
local args, options = require("shell").parse(...)

require("advancedLua")
local component = require("component")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local color = require("color")
local unicode = require("unicode")
local MineOSCore = require("MineOSCore")
local bigLetters = require("bigLetters")

--------------------------------------------------------------------------------

local localization = MineOSCore.getCurrentScriptLocalization()
local currentLayer = 0
local model
local shapeLimit = 24
local proxies = {}
local viewPixelWidth, viewPixelHeight = 4, 2

local colors, hue, hueStep = {}, 0, 360 / shapeLimit
for i = 1, shapeLimit do
	colors[i] = color.HSBToInteger(hue, 1, 1)
	hue = hue + hueStep
end

--------------------------------------------------------------------------------

local application = GUI.application()

local toolPanel = application:addChild(GUI.panel(1, 1, 28, application.height, 0x2D2D2D))
local toolLayout = application:addChild(GUI.layout(1, 1, toolPanel.width, toolPanel.height - 3, 1, 1))
toolLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
toolLayout:setMargin(1, 1, 0, 1)

local function addSeparator(text)
	toolLayout:addChild(GUI.object(1, 1, toolLayout.width, 1)).draw = function(object)
		buffer.drawRectangle(object.x, object.y, object.width, 1, 0x0F0F0F, 0xE1E1E1, " ")
		buffer.drawText(object.x + 1, object.y, 0xE1E1E1, text)
	end
end

local function addButton(...)
	return toolLayout:addChild(GUI.button(1, 1, toolLayout.width - 2, 1, 0x3C3C3C, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, ...))
end

local function addColorSelector(...)
	return toolLayout:addChild(GUI.colorSelector(1, 1, toolLayout.width - 2, 1, ...))
end

local printButton = application:addChild(GUI.button(1, application.height - 2, toolLayout.width, 3, 0x4B4B4B, 0xD2D2D2, 0xE1E1E1, 0x3C3C3C, localization.print))

toolLayout:addChild(GUI.object(1, 1, toolLayout.width, 5)).draw = function(object)
	local text = tostring(math.floor(currentLayer))
	local width = bigLetters.getTextSize(text)
	bigLetters.drawText(math.floor(object.x + object.width / 2 - width / 2), object.y, 0xE1E1E1, text)
end

addSeparator(localization.modelSettings)

local newButton = addButton(localization.new)
local openButton = addButton(localization.open)

addButton(localization.save).onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "Save", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".3dm")
	filesystemDialog.onSubmit = function(path)
		table.toFile(path, model, true)
	end
	filesystemDialog:show()
end

addButton(localization.exit).onTouch = function()
	if hologram then
		hologram.clear()
	end

	application:stop()
end

addSeparator(localization.elementSettings)

local modelList = toolLayout:addChild(GUI.list(1, 1, toolLayout.width, 3, math.floor(toolLayout.width / 2), 0, 0x1E1E1E, 0x5A5A5A, 0x1E1E1E, 0x5A5A5A, 0x2D2D2D, 0xA5A5A5))
modelList:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
modelList:setDirection(GUI.DIRECTION_HORIZONTAL)
local disabledListItem = modelList:addItem(localization.disabled)
local enabledListItem = modelList:addItem(localization.enabled)

local elementComboBox = toolLayout:addChild(GUI.comboBox(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x3C3C3C, 0x696969))

local textureInput = toolLayout:addChild(GUI.input(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x696969, 0x1E1E1E, 0xE1E1E1, "", localization.texture, true))
local tintColorSelector = addColorSelector(0x330040, localization.tintColor)
local tintSwitch = toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, localization.tintEnabled .. ":", false)).switch

local addShapeButton = addButton(localization.add)

local function checkShapeState(shape)
	return modelList.selectedItem == 1 and not shape.state or modelList.selectedItem == 2 and shape.state
end

local removeShapeButton = addButton(localization.remove)

addSeparator(localization.blockSettings)

local labelInput = toolLayout:addChild(GUI.input(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x696969, 0x1E1E1E, 0xE1E1E1, "", localization.label, true))
local tooltipInput = toolLayout:addChild(GUI.input(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x696969, 0x1E1E1E, 0xE1E1E1, "", localization.tooltip, true))
local buttonModeSwitch = toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, localization.buttonMode .. ":", false)).switch
local collisionSwitch = toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, localization.collidable .. ":", true)).switch
local redstoneSwitch = toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, localization.emitRedstone .. ":", true)).switch

local lightLevelSlider = toolLayout:addChild(GUI.slider(1, 1, toolLayout.width - 2, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, 0, 15, 0, false, localization.lightLevel .. ": ", ""))
lightLevelSlider.height = 2
lightLevelSlider.roundValues = true

local axisComboBox = toolLayout:addChild(GUI.comboBox(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x3C3C3C, 0x696969))
axisComboBox:addItem(localization.xAxis)
axisComboBox:addItem(localization.yAxis)
axisComboBox:addItem(localization.zAxis)

local function fixShape(shape)
	for i = 1, 3 do
		if shape[i] > shape[i + 3] then
			shape[i], shape[i + 3] = shape[i + 3], shape[i]
		end
	end
end

local rotateButton = addButton(localization.rotate)
local flipButton = addButton(localization.flip)

addSeparator(localization.projectorSettings)

local function updateProxies()
	local function updateProxy(name)
		proxies[name] = component.list(name)()
		if proxies[name] then
			proxies[name] = component.proxy(proxies[name])
			return true
		end
	end

	updateProxy("hologram")
	printButton.disabled = not updateProxy("printer3d")
end

updateProxies()

local projectorSwitch = toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, localization.projectorEnabled .. ": ", true)).switch

local projectorScaleSlider = toolLayout:addChild(GUI.slider(1, 1, toolLayout.width - 2, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, 0.33, 3, proxies.hologram and proxies.hologram.getScale() or 1, false, localization.scale .. ": ", ""))
projectorScaleSlider.onValueChanged = function()
	if proxies.hologram then
		proxies.hologram.setScale(projectorScaleSlider.value)
	end
end

local projectorOffsetSlider = toolLayout:addChild(GUI.slider(1, 1, toolLayout.width - 2, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xA5A5A5, 0, 1, proxies.hologram and select(2, proxies.hologram.getTranslation()) or 0, false, localization.offset .. ": ", ""))
projectorOffsetSlider.height = 2
projectorOffsetSlider.onValueChanged = function()
	if proxies.hologram then
		proxies.hologram.setTranslation(0, projectorOffsetSlider.value, 0)
	end
end

if proxies.hologram then
	for i = 1, proxies.hologram.maxDepth() == 1 and 1 or 3 do
		local selector = addColorSelector(proxies.hologram and proxies.hologram.getPaletteColor(i) or 0x0, localization.color .. " " .. i)
		selector.onColorSelected = function()
			if proxies.hologram then
				proxies.hologram.setPaletteColor(i, selector.color)
				application:draw()
			end
		end
	end
end

local function getCurrentShapeIndex()
	local item = elementComboBox:getItem(elementComboBox.selectedItem)
	return item and item.shapeIndex
end

local function updateOnHologram()
	if proxies.hologram and projectorSwitch.state then
		local initialX = 17
		local initialY = 2
		local initialZ = 33
		local projectorPaletteIndex = proxies.hologram.maxDepth() > 1 and 3 or 1

		proxies.hologram.clear()

		local shapeIndex = getCurrentShapeIndex()
		for i = 1, #model.shapes do
			local shape = model.shapes[i]
			if checkShapeState(shape) then
				for x = initialX + shape[1], initialX + shape[4] - 1 do
					for z = initialZ - shape[6] + 1, initialZ - shape[3] do
						proxies.hologram.fill(x, z, initialY + shape[2], initialY + shape[5] - 1, projectorPaletteIndex == 3 and (i == shapeIndex and 1 or 2) or 1)
					end
				end
			end
		end

		proxies.hologram.fill(initialX - 1, initialZ - currentLayer, initialY - 1, initialY + 16, projectorPaletteIndex)
		proxies.hologram.fill(initialX + 16, initialZ - currentLayer, initialY - 1, initialY + 16, projectorPaletteIndex)

		for x = initialX - 1, initialX + 16 do
			proxies.hologram.set(x, initialY - 1, initialZ - currentLayer, projectorPaletteIndex)
			proxies.hologram.set(x, initialY + 16, initialZ - currentLayer, projectorPaletteIndex)
		end
	end
end

local function updateComboBoxFromModel()
	elementComboBox:clear()
	
	for i = 1, #model.shapes do
		if checkShapeState(model.shapes[i]) then
			local item = elementComboBox:addItem(tostring(i))
			item.shapeIndex = i
			item.color = colors[i]
		end
	end
end

local function updateAddRemoveButtonsState()
	addShapeButton.disabled = #model.shapes >= shapeLimit
	removeShapeButton.disabled = #model.shapes < 1 or elementComboBox:count() < 1
end

local function updateWidgetsFromModel()
	labelInput.text = model.label or ""
	tooltipInput.text = model.tooltip or ""
	buttonModeSwitch:setState(model.buttonMode)
	collisionSwitch:setState(model.collidable)
	redstoneSwitch.state = model.emitRedstone or false
	lightLevelSlider.value = model.lightLevel or 0

	local shapeIndex = getCurrentShapeIndex()
	if shapeIndex then
		textureInput.text = model.shapes[shapeIndex].texture or ""
		tintSwitch:setState(model.shapes[shapeIndex].tint and true or false)
		tintColorSelector.color = model.shapes[shapeIndex].tint or tintColorSelector.color
	end
end

local function updateModelFromWidgets()
	model.label = #labelInput.text > 0 and labelInput.text or nil
	model.tooltip = #tooltipInput.text > 0 and tooltipInput.text or nil
	model.buttonMode = buttonModeSwitch.state
	model.collidable = collisionSwitch.state and {true, true} or nil
	model.emitRedstone = redstoneSwitch.state
	model.lightLevel = lightLevelSlider.value > 0 and lightLevelSlider.value or nil

	local shapeIndex = getCurrentShapeIndex()
	if shapeIndex then
		model.shapes[shapeIndex].texture = #textureInput.text > 0 and textureInput.text or nil
		model.shapes[shapeIndex].tint = tintSwitch.state and tintColorSelector.color or nil
	end
end

local function load(path)
	model = table.fromFile(path)

	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()
end

openButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(application, true, 50, math.floor(application.height * 0.8), "Open", "Cancel", "File name", "/")
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".3dm")
	filesystemDialog.onSubmit = function(path)
		load(path)

		application:draw()
		updateOnHologram()
	end
	filesystemDialog:show()
end

application:addChild(GUI.panel(toolPanel.width + 1, 1, application.width - toolPanel.width, toolPanel.height, 0x1E1E1E))

local view = application:addChild(GUI.object(1, 1, 16 * viewPixelWidth, 16 * viewPixelHeight))
view.localX = math.floor(toolLayout.width + (application.width - toolLayout.width) / 2 - view.width / 2)
view.localY = math.floor(application.height / 2 - view.height / 2)
view.draw = function()
	local x, y, step = view.x, view.y, true
	for j = 1, 16 do
		for i = 1, 16 do
			buffer.drawRectangle(x, y, viewPixelWidth, viewPixelHeight, 0xF0F0F0, 0xE1E1E1, step and " " or "█")
			x, step = x + viewPixelWidth, not step
		end

		x, y, step = view.x, y + viewPixelHeight, not step
	end

	GUI.drawShadow(view.x, view.y, view.width, view.height, nil, true)

	local shapeIndex, shape = getCurrentShapeIndex()
	if shapeIndex then
		for i = 1, #model.shapes do
			shape = model.shapes[i]

			if checkShapeState(shape) then
				local width = (shape[4] - shape[1]) * viewPixelWidth
				local height = (shape[5] - shape[2]) * viewPixelHeight
				local x = view.x + shape[1] * viewPixelWidth
				local y = view.y + view.height - shape[2] * viewPixelHeight - height

				if width > 0 and height > 0 and currentLayer >= shape[3] and currentLayer <= shape[6] - 1 then
					buffer.drawRectangle(x, y, width, height, i == shapeIndex and colors[i] or color.blend(colors[i], 0xFFFFFF, 0.5), 0x0, " ")

					if currentLayer == shape[3] then
						buffer.drawRectangle(x, y, viewPixelWidth, viewPixelHeight, 0x0, 0x0, " ", i == shapeIndex and 0.2 or 0.6)
					end

					if currentLayer == shape[6] - 1 then
						buffer.drawRectangle(x + width - viewPixelWidth, y + height - viewPixelHeight, viewPixelWidth, viewPixelHeight, 0x0, 0x0, " ", i == shapeIndex and 0.4 or 0.8)
					end
				end
			end
		end
	end
end

toolLayout.eventHandler = function(application, toolLayout, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local cell = toolLayout.cells[1][1]
		if e5 > 0 then
			if cell.verticalMargin < 1 then
				cell.verticalMargin = cell.verticalMargin + 1
				application:draw()
			end
		else
			local child = toolLayout.children[#toolLayout.children]
			if child.localY + child.height - 1 >= toolLayout.localY + toolLayout.height - 1 then
				cell.verticalMargin = cell.verticalMargin - 1
				application:draw()
			end
		end
	end
end

local touchX, touchY, shapeX, shapeY, shapeZ
view.eventHandler = function(application, view, e1, e2, e3, e4, e5)
	if e1 == "touch" or e1 == "drag" then
		if e5 > 0 then
			if e1 == "touch" then
				touchX, touchY = e3, e4
			elseif touchX then
				view.localX, view.localY = view.localX + e3 - touchX, view.localY + e4 - touchY
				touchX, touchY = e3, e4

				application:draw()
			end
		else
			local shapeIndex = getCurrentShapeIndex()
			if shapeIndex then
				local shape = model.shapes[shapeIndex]
				local x = math.floor((e3 - view.x) / view.width * 16)
				local y = 15 - math.floor((e4 - view.y) / view.height * 16)

				if e1 == "touch" then
					shapeX, shapeY, shapeZ = x, y, currentLayer
					shape[1], shape[2], shape[3] = x, y, currentLayer
					shape[4], shape[5], shape[6] = x + 1, y + 1, currentLayer + 1
				elseif shapeX then
					shape[1], shape[2], shape[3] = shapeX, shapeY, shapeZ
					shape[4], shape[5], shape[6] = x, y, currentLayer
					fixShape(shape)
					shape[4], shape[5], shape[6] = shape[4] + 1, shape[5] + 1, shape[6] + 1
				end

				application:draw()
			end
		end
	elseif e1 == "drop" then
		touchX, touchY, shapeX, shapeY, shapeZ = nil, nil, nil, nil, nil
		updateOnHologram()
	elseif e1 == "scroll" then
		local function fix()
			local shapeIndex = getCurrentShapeIndex()
			if shapeX and shapeIndex then
				local shape = model.shapes[shapeIndex]
				shape[3] = shapeZ
				shape[6] = currentLayer
				fixShape(shape)
				shape[6] = shape[6] + 1
			end
		end

		if e5 > 0 then
			if currentLayer < 15 then
				currentLayer = currentLayer + 1
				fix()

				application:draw()
				updateOnHologram()
			end
		else
			if currentLayer > 0 then
				currentLayer = currentLayer - 1
				fix()

				application:draw()
				updateOnHologram()
			end
		end
	elseif e1 == "component_added" or e1 == "component_removed" then
		updateProxies()
		updateOnHologram()
	end
end

rotateButton.onTouch = function()
	for i = 1, #model.shapes do
		local shape = model.shapes[i]
				
		if axisComboBox.selectedItem == 1 then
			shape[1], shape[2], shape[3], shape[4], shape[5], shape[6] = shape[1], -shape[3] + 16, shape[2], shape[4], -shape[6] + 16, shape[5]
		elseif axisComboBox.selectedItem == 2 then
			shape[1], shape[2], shape[3], shape[4], shape[5], shape[6] = -shape[3] + 16, shape[2], shape[1], -shape[6] + 16, shape[5], shape[4]
		else
			shape[1], shape[2], shape[3], shape[4], shape[5], shape[6] = shape[2], -shape[1] + 16, shape[3], shape[5], -shape[4] + 16, shape[6]
		end

		fixShape(shape)
	end

	application:draw()
	updateOnHologram()
end

flipButton.onTouch = function()
	local function fix(shape, index)
		shape[index] = 16 - shape[index]
		shape[index + 3] = 16 - shape[index + 3]
	end

	for i = 1, #model.shapes do
		local shape = model.shapes[i]
		if axisComboBox.selectedItem == 1 then
			fix(shape, 1)
		elseif axisComboBox.selectedItem == 2 then
			fix(shape, 2)
		else
			fix(shape, 3)
		end

		fixShape(shape)
	end

	application:draw()
	updateOnHologram()
end

disabledListItem.onTouch = function()
	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()

	application:draw()
	updateOnHologram()
end

enabledListItem.onTouch = disabledListItem.onTouch

local function addShape()
	table.insert(model.shapes, {6, 6, 0, 10, 10, 1, state = modelList.selectedItem == 2 or nil, texture = #textureInput.text > 0 and textureInput.text or nil})
	
	updateComboBoxFromModel()
	elementComboBox.selectedItem = elementComboBox:count()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()
end

local function new()
	model = {shapes = {}}
	addShape()
end

newButton.onTouch = function()
	new()

	application:draw()
	updateOnHologram()
end

addShapeButton.onTouch = function()
	addShape()

	application:draw()
	updateOnHologram()
end

removeShapeButton.onTouch = function()
	table.remove(model.shapes, getCurrentShapeIndex())

	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()

	application:draw()
	updateOnHologram()
end

printButton.onTouch = function()
	proxies.printer3d.reset()

	if model.label then
		proxies.printer3d.setLabel(model.label)
	end

	if model.tooltip then
		proxies.printer3d.setTooltip(model.tooltip)
	end

	if model.collidable then
		proxies.printer3d.setCollidable(model.collidable[1], model.collidable[2])
	end

	if model.lightLevel then
		proxies.printer3d.setLightLevel(model.lightLevel)
	end

	if model.emitRedstone then
		proxies.printer3d.setRedstoneEmitter(model.emitRedstone)
	end

	if model.buttonMode then
		proxies.printer3d.setButtonMode(model.buttonMode)
	end
	
	for i = 1, #model.shapes do
		local shape = model.shapes[i]
		proxies.printer3d.addShape(shape[1], shape[2], shape[3], shape[4], shape[5], shape[6], shape.texture or "empty", shape.state, shape.tint)
	end

	local success, reason = proxies.printer3d.commit(1)
	if not success then
		GUI.alert(localization.failedToPrint .. ": " .. reason)
	end
end

elementComboBox.onItemSelected = function()
	updateWidgetsFromModel()

	application:draw()
	updateOnHologram()
end

labelInput.onInputFinished = updateModelFromWidgets
tooltipInput.onInputFinished = updateModelFromWidgets
buttonModeSwitch.onStateChanged = updateModelFromWidgets
collisionSwitch.onStateChanged = updateModelFromWidgets
redstoneSwitch.onStateChanged = updateModelFromWidgets
lightLevelSlider.onValueChanged = updateModelFromWidgets
textureInput.onInputFinished = updateModelFromWidgets
tintSwitch.onStateChanged = updateModelFromWidgets
tintColorSelector.onColorSelected = updateModelFromWidgets

--------------------------------------------------------------------------------

if (options.o or options.open) and args[1] then
	load(args[1])
else
	new()
end

application:draw()
updateOnHologram()
application:start()