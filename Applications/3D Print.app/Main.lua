

local number = require("Number")
local GUI = require("GUI")
local screen = require("Screen")
local color = require("Color")
local system = require("System")
local paths = require("Paths")
local text = require("Text")
local bigLetters = require("BigLetters")
local filesystem = require("Filesystem")

--------------------------------------------------------------------------------

local args, options = system.parseArguments(...)

local proxies = {}

local function updateProxy(name)
	proxies[name] = component.list(name)()
	if proxies[name] then
		proxies[name] = component.proxy(proxies[name])

		return proxies[name]
	end
end

local function print(model)
	local proxy = proxies.printer3d

	proxy.reset()

	if model.label then
		proxy.setLabel(model.label)
	end

	if model.tooltip then
		proxy.setTooltip(model.tooltip)
	end

	if model.collidable then
		proxy.setCollidable(model.collidable[1], model.collidable[2])
	end

	if model.lightLevel then
		proxy.setLightLevel(model.lightLevel)
	end

	if model.emitRedstone then
		proxy.setRedstoneEmitter(model.emitRedstone)
	end

	if model.buttonMode then
		proxy.setButtonMode(model.buttonMode)
	end
	
	for i = 1, #model.shapes do
		local shape = model.shapes[i]

		proxy.addShape(shape[1], shape[2], shape[3], shape[4], shape[5], shape[6], shape.texture or "empty", shape.state, shape.tint)
	end

	local success, reason = proxy.commit(1)

	if not success then
		GUI.alert(localization.failedToPrint .. ": " .. reason)
	end
end

-- Just printing without UI
if options.p then
	updateProxy("printer3d")
	print(filesystem.readTable(args[1]))

	return
end

--------------------------------------------------------------------------------

local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/")
local currentLayer = 0
local viewPixelWidth, viewPixelHeight = 4, 2

local model
local savePath
local shapeLimit

local workspace, window, menu = system.addWindow(GUI.filledWindow(1, 1, 100, screen.getHeight() - 1, 0x1E1E1E))

--------------------------------------------------------------------------------

local toolPanel = window:addChild(GUI.panel(1, 1, 28, 1, 0x2D2D2D))

window.backgroundPanel.localX = toolPanel.width + 1

local toolLayout = window:addChild(GUI.layout(1, 1, toolPanel.width, 1, 1, 1))
toolLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
toolLayout:setMargin(1, 1, 0, 1)

local function addSeparator(text)
	toolLayout:addChild(GUI.object(1, 1, toolLayout.width, 1)).draw = function(object)
		screen.drawRectangle(object.x, object.y, object.width, 1, 0x0F0F0F, 0xE1E1E1, " ")
		screen.drawText(object.x + 1, object.y, 0xE1E1E1, text)
	end
end

local function newButton(width, height, ...)
	local button = GUI.button(1, 1, width, height, 0x3C3C3C, 0xA5A5A5, 0xE1E1E1, 0x3C3C3C, ...)
	button.colors.disabled.background = 0x3C3C3C
	button.colors.disabled.text = 0x5A5A5A

	return button
end

local function addObjectsTo(layout, objects)
	layout:setGridSize(#objects * 2 - 1, 1)

	for i = 1, #objects do
		layout:setColumnWidth(i * 2 - 1, GUI.SIZE_POLICY_RELATIVE, 1 / #objects)

		if i < #objects then
			layout:setColumnWidth(i * 2, GUI.SIZE_POLICY_ABSOLUTE, 1)
		end

		layout:setPosition(i * 2 - 1, 1, layout:addChild(objects[i]))
		layout:setFitting(i * 2 - 1, 1, true, false)
	end
end

local function addObjectsWithLayout(objects)
	addObjectsTo(toolLayout:addChild(GUI.layout(1, 1, toolLayout.width - 2, 1, 1, 1)), objects)
end

local function addButtons(...)
	local texts, buttons = {...}, {}
	for i = 1, #texts do
		buttons[i] = newButton(toolLayout.width - 2, 1, texts[i])
	end

	addObjectsWithLayout(buttons)

	return table.unpack(buttons)
end

local function addSwitch(...)
	return toolLayout:addChild(GUI.switchAndLabel(1, 1, toolLayout.width - 2, 6, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x787878, ...)).switch
end

local function addInput(...)
	return toolLayout:addChild(GUI.input(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x5A5A5A, 0x1E1E1E, 0xE1E1E1, ...))
end

local function addSlider(...)
	return toolLayout:addChild(GUI.slider(1, 1, toolLayout.width - 2, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x787878, ...))
end

local function addComboBox(...)
	return toolLayout:addChild(GUI.comboBox(1, 1, toolLayout.width - 2, 1, 0x1E1E1E, 0xA5A5A5, 0x3C3C3C, 0x696969))
end

local bigContainer = toolLayout:addChild(GUI.container(1, 1, toolLayout.width, 5))

bigContainer:addChild(GUI.object(1, 1, bigContainer.width, bigContainer.height)).draw = function(object)
	local text = tostring(math.floor(currentLayer))
	local width = bigLetters.getTextSize(text)
	bigLetters.drawText(math.floor(object.x + object.width / 2 - width / 2), object.y, 0xE1E1E1, text)
end

window.actionButtons:remove()
bigContainer:addChild(window.actionButtons)
window.actionButtons.localY = 1

local fileItem = menu:addContextMenuItem(localization.file)

local newItem = fileItem:addItem(localization.new, false, "^N")
local openItem = fileItem:addItem(localization.open, false, "^O")
fileItem:addSeparator()
local saveItem = fileItem:addItem(localization.save, true, "^S")
local saveAsItem = fileItem:addItem(localization.saveAs, false, "^⇧S")

menu:addItem(localization.help).onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.help)

	local textBox = container.layout:addChild(GUI.textBox(1, 1, 68, 1, nil, 0xB4B4B4, localization.helpInfo, 1, 0, 0, true, true))
	textBox.eventHandler = container.panel.eventHandler

	textBox:update()
	workspace:draw()
end

local function updateSavePath(path)
	savePath = path
	saveItem.disabled = not savePath
end

addSeparator(localization.elementSettings)

local printButton = window:addChild(newButton(toolLayout.width, 3, localization.print))

local modelList = toolLayout:addChild(GUI.list(1, 1, toolLayout.width, 3, math.floor(toolLayout.width / 2), 0, 0x1E1E1E, 0x5A5A5A, 0x1E1E1E, 0x5A5A5A, 0x2D2D2D, 0xA5A5A5))
modelList:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
modelList:setDirection(GUI.DIRECTION_HORIZONTAL)
local disabledListItem = modelList:addItem(localization.disabled)
local enabledListItem = modelList:addItem(localization.enabled)

local shapesComboBox = addComboBox()

local textureInput = addInput("", localization.texture, true)
local tintColorSelector = toolLayout:addChild(GUI.colorSelector(1, 1, toolLayout.width - 2, 1, 0x330040, localization.tintColor))
local tintSwitch = addSwitch(localization.tintEnabled .. ":", false)

local function checkShapeState(shape)
	return modelList.selectedItem == 1 and not shape.state or modelList.selectedItem == 2 and shape.state
end

local addShapeButton, removeShapeButton = addButtons(localization.add, localization.remove)

addSeparator(localization.blockSettings)

local labelInput = addInput("", localization.label, true)
local tooltipInput = addInput("", localization.tooltip, true)
local buttonModeSwitch = addSwitch(localization.buttonMode .. ":", false)
local collisionSwitch = addSwitch(localization.collidable .. ":", true)
local redstoneSwitch = addSwitch(localization.emitRedstone .. ":", true)

local lightLevelSlider = addSlider(0, 15, 0, false, localization.lightLevel .. ": ", "")
lightLevelSlider.height = 2
lightLevelSlider.roundValues = true

local axisComboBox = addComboBox()
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

local rotateButton, flipButton = addButtons(localization.rotate, localization.flip)

addSeparator(localization.projectorSettings)

local projectorSwitch = addSwitch(localization.projectorEnabled .. ": ", true)

local projectorScaleSlider = addSlider(0.33, 3, proxies.hologram and proxies.hologram.getScale() or 1, false, localization.scale .. ": ", "")
projectorScaleSlider.onValueChanged = function()
	if proxies.hologram then
		proxies.hologram.setScale(projectorScaleSlider.value)
	end
end

local projectorOffsetSlider = addSlider(0, 1, proxies.hologram and select(2, proxies.hologram.getTranslation()) or 0, false, localization.offset .. ": ", "")
projectorOffsetSlider.height = 2
projectorOffsetSlider.onValueChanged = function()
	if proxies.hologram then
		proxies.hologram.setTranslation(0, projectorOffsetSlider.value, 0)
	end
end

local hologramWidgetsLayout = toolLayout:addChild(GUI.layout(1, 1, toolLayout.width - 2, 1, 1, 1))

local function updateHologramWidgets()
	local objects = {}

	for i = 1, (proxies.hologram and proxies.hologram.maxDepth() == 1 and 1 or 3) or 3 do
		objects[i] = GUI.colorSelector(1, 1, 1, 1, proxies.hologram and proxies.hologram.getPaletteColor(i) or 0x0, localization.color .. i)
		objects[i].onColorSelected = function()
			if proxies.hologram then
				proxies.hologram.setPaletteColor(i, objects[i].color)
				workspace:draw()
			end
		end
	end

	hologramWidgetsLayout:removeChildren()
	addObjectsTo(hologramWidgetsLayout, objects)
end

local function updateAddRemoveButtonsState()
	addShapeButton.disabled = #model.shapes >= shapeLimit
	removeShapeButton.disabled = #model.shapes < 1 or shapesComboBox:count() < 1
end

local function updateComboBoxFromModel()
	shapesComboBox:clear()
	
	for i = 1, #model.shapes do
		if checkShapeState(model.shapes[i]) then
			local item = shapesComboBox:addItem(tostring(i))

			item.shapeIndex = i
			item.color = colors[i]
		end
	end
end

local function updateProxies()
	updateProxy("hologram")
	updateHologramWidgets()

	local printerProxy = updateProxy("printer3d")
	
	--Update shape limit if we have a printer connected.
	--Probably halfway laggy because it's updating colors now too though,
	--but necessary if we want things to work right with no unintended consequences.
	--I would have this update in the component add remove part, but updateProxy is
	--awesome and tells us if a component is present or not.
	local newLimit = printerProxy and printerProxy.getMaxShapeCount() or 24

	--No need to update anything if new limit is the same as old.
	if newLimit ~= shapeLimit then
		--Otherwise, we need to update both limit and all the colors that use the limit.
		shapeLimit = newLimit
		
		colors, hue, hueStep = {}, 0, 360 / shapeLimit
		
		for i = 1, shapeLimit do
			colors[i] = color.HSBToInteger(hue, 1, 1)
			hue = hue + hueStep
		end

		-- Truncating existing model if it's too fat chick
		if model and #model.shapes > newLimit then
			while #model.shapes > newLimit do
				table.remove(model.shapes, #model.shapes)
			end

			updateComboBoxFromModel()
		end
	end

	printButton.disabled = not printerProxy
end

updateProxies()

local function getSelectedShapeIndex()
	local item = shapesComboBox:getItem(shapesComboBox.selectedItem)
	return item and item.shapeIndex
end

local function updateHologram()
	if proxies.hologram and projectorSwitch.state then
		local initialX = 17
		local initialY = 2
		local initialZ = 33
		local projectorPaletteIndex = proxies.hologram.maxDepth() > 1 and 3 or 1

		proxies.hologram.clear()

		local shapeIndex = getSelectedShapeIndex()
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

local function updateWidgetsFromModel()
	labelInput.text = model.label or ""
	tooltipInput.text = model.tooltip or ""
	buttonModeSwitch:setState(model.buttonMode)
	collisionSwitch:setState(model.collidable)
	redstoneSwitch.state = model.emitRedstone or false
	lightLevelSlider.value = model.lightLevel or 0

	local shapeIndex = getSelectedShapeIndex()
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

	local shapeIndex = getSelectedShapeIndex()

	if shapeIndex then
		model.shapes[shapeIndex].texture = #textureInput.text > 0 and textureInput.text or nil
		model.shapes[shapeIndex].tint = tintSwitch.state and tintColorSelector.color or nil
	end
end

local function load(path)
	model = filesystem.readTable(path)
	updateSavePath(path)

	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()
end

local function save(path)
	filesystem.writeTable(path, model, true)
	updateSavePath(path)
end

saveItem.onTouch = function()
	save(savePath)
end

saveAsItem.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Save", "Cancel", "File name", "/")

	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".3dm")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog.filesystemTree.selectedItem = paths.user.desktop

	filesystemDialog.onSubmit = function(path)
		save(path)
	end

	filesystemDialog:show()
end

openItem.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Open", "Cancel", "File name", "/")

	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".3dm")
	filesystemDialog:expandPath(paths.user.desktop)

	filesystemDialog.onSubmit = function(path)
		load(path)

		workspace:draw()
		updateHologram()
	end
	filesystemDialog:show()
end

local viewLayout = window:addChild(GUI.layout(window.backgroundPanel.localX, 1, 1, 1, 1, 1))
viewLayout:setSpacing(1, 1, 2)

local view = viewLayout:addChild(GUI.object(1, 1, 16 * viewPixelWidth, 16 * viewPixelHeight))

local function getShapeDrawingData(shape)
	local width, height =
		(shape[4] - shape[1]) * viewPixelWidth,
		(shape[5] - shape[2]) * viewPixelHeight

	return
		width > 0 and height > 0 and currentLayer >= shape[3] and currentLayer <= shape[6] - 1 and checkShapeState(shape),
		view.x + shape[1] * viewPixelWidth,
		view.y + view.height - shape[2] * viewPixelHeight - height,
		width,
		height
end

view.draw = function()
	local x, y, step = view.x, view.y, true
	for j = 1, 16 do
		for i = 1, 16 do
			screen.drawRectangle(x, y, viewPixelWidth, viewPixelHeight, 0xF0F0F0, 0xE1E1E1, step and " " or "█")
			x, step = x + viewPixelWidth, not step
		end

		x, y, step = view.x, y + viewPixelHeight, not step
	end

	GUI.drawShadow(view.x, view.y, view.width, view.height, nil, true)

	local selectedShape, shape = getSelectedShapeIndex()

	if selectedShape then
		for i = 1, #model.shapes do
			shape = model.shapes[i]

			local focused, x, y, width, height = getShapeDrawingData(shape)

			if focused then
				screen.drawRectangle(x, y, width, height, i == selectedShape and colors[i] or color.blend(colors[i], 0xFFFFFF, 0.4), 0x0, " ")

				if currentLayer == shape[3] then
					screen.drawRectangle(x, y, viewPixelWidth, viewPixelHeight, 0x0, 0x0, " ", i == selectedShape and 0.2 or 0.6)
				end

				if currentLayer == shape[6] - 1 then
					screen.drawRectangle(x + width - viewPixelWidth, y + height - viewPixelHeight, viewPixelWidth, viewPixelHeight, 0x0, 0x0, " ", i == shapeIndex and 0.4 or 0.8)
				end
			end
		end
	end
end

toolLayout.eventHandler = function(workspace, toolLayout, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local h, v = toolLayout:getMargin(1, 1)

		if e5 > 0 then
			if v < 1 then
				v = v + 1
				toolLayout:setMargin(1, 1, h, v)
				workspace:draw()
			end
		else
			local child = toolLayout.children[#toolLayout.children]

			if child.localY + child.height - 1 >= toolLayout.localY + toolLayout.height - 1 then
				v = v - 1
				toolLayout:setMargin(1, 1, h, v)
				workspace:draw()
			end
		end
	end
end

local shapeX, shapeY, shapeZ
view.eventHandler = function(workspace, view, e1, e2, e3, e4, e5)
	if e1 == "touch" or e1 == "drag" then
		if e5 == 0 then
			local selectedShape = getSelectedShapeIndex()
			if selectedShape then
				local shape = model.shapes[selectedShape]
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

				workspace:draw()
			end
		else
			-- Selecting shape
			local shape
			for i = #model.shapes, 1, -1 do
				shape = model.shapes[i]

				local focused, x, y, width, height = getShapeDrawingData(shape)
				if focused and e3 >= x and e3 <= x + width - 1 and e4 >= y and e4 <= y + height - 1 then
					for j = 1, shapesComboBox:count() do
						if shapesComboBox:getItem(j).shapeIndex == i then
							shapesComboBox.selectedItem = j
							workspace:draw()

							break
						end
					end

					break
				end
			end
		end
	elseif e1 == "drop" then
		shapeX, shapeY, shapeZ = nil, nil, nil

		updateHologram()
	elseif e1 == "scroll" then
		local function fix()
			local shapeIndex = getSelectedShapeIndex()

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

				workspace:draw()
				updateHologram()
			end
		else
			if currentLayer > 0 then
				currentLayer = currentLayer - 1
				fix()

				workspace:draw()
				updateHologram()
			end
		end
	elseif (e1 == "component_added" or e1 == "component_removed") and (e3 == "printer3d" or e3 == "hologram") then
		updateProxies()
		updateAddRemoveButtonsState()

		workspace:draw()
		updateHologram()
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

	workspace:draw()
	updateHologram()
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

	workspace:draw()
	updateHologram()
end

disabledListItem.onTouch = function()
	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()

	workspace:draw()
	updateHologram()
end

enabledListItem.onTouch = disabledListItem.onTouch

local function addShape()
	table.insert(model.shapes, {6, 6, 0, 10, 10, 1, state = modelList.selectedItem == 2 or nil, texture = #textureInput.text > 0 and textureInput.text or nil})
	
	updateComboBoxFromModel()
	shapesComboBox.selectedItem = shapesComboBox:count()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()
end

local function new()
	model = {shapes = {}}
	modelList.selectedItem = 1
	addShape()
	updateSavePath()
end

newItem.onTouch = function()
	new()

	workspace:draw()
	updateHologram()
end

addShapeButton.onTouch = function()
	addShape()

	workspace:draw()
	updateHologram()
end

removeShapeButton.onTouch = function()
	table.remove(model.shapes, getSelectedShapeIndex())

	updateComboBoxFromModel()
	updateWidgetsFromModel()
	updateAddRemoveButtonsState()

	workspace:draw()
	updateHologram()
end

printButton.onTouch = function()
	print(model)
end

shapesComboBox.onItemSelected = function()
	updateWidgetsFromModel()

	workspace:draw()
	updateHologram()
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

-- Overriding window removing for clearing hologram
local overrideWindowRemove = window.remove
window.remove = function(...)
	overrideWindowRemove(...)

	if proxies.hologram then
		proxies.hologram.clear()
	end
end

window.onResize = function(width, height)
	window.backgroundPanel.width = width - toolPanel.width
	window.backgroundPanel.height = height

	viewLayout.width = window.backgroundPanel.width
	viewLayout.height = window.backgroundPanel.height

	toolPanel.height = height - 3
	
	toolLayout.height = toolPanel.height

	printButton.localY = height - 2
end

--------------------------------------------------------------------------------

load(args[1] or (currentScriptDirectory .. "Sample.3dm"))

window:resize(window.width, window.height)
workspace:draw()
