
local text = require("Text")
local filesystem = require("Filesystem")
local GUI = require("GUI")
local screen = require("Screen")
local system = require("System")
local paths = require("Paths")

------------------------------------------------------------------------------------------------------------------

local configPath = paths.user.applicationData .. "HEX Editor/Config.cfg"
local config = filesystem.exists(configPath) and filesystem.readTable(configPath) or {
	recentPath = "/OS.lua"
}

local colors = {
	background = 0xF0F0F0,
	backgroundText = 0x555555,
	panel = 0x2D2D2D,
	panelText = 0x999999,
	panelSeleciton = 0x444444,
	panelSelecitonText = 0xE1E1E1,
	selectionFrom = 0x990000,
	selectionTo = 0x990000,
	selectionText = 0xFFFFFF,
	selectionBetween = 0xD2D2D2,
	selectionBetweenText = 0x000000,
	separator = 0xCCCCCC,
	titleBackground = 0x990000,
	titleText = 0xFFFFFF,
	titleText2 = 0xE1E1E1,
}

local bytes = {}
local offset = 0
local selection = {
	from = 1,
	to = 1,
}

local scrollBar, titleTextBox

------------------------------------------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 98, 25, colors.background))

window.maxWidth = window.width
window.showDesktopOnMaximize = true

window.backgroundPanel.localX, window.backgroundPanel.localY = 11, 5
window.backgroundPanel.width = window.width - 10

window.actionButtons.localY = 2

local function byteArrayToNumber(b)
	local n = 0
	for i = 1, #b do
		n = bit32.bor(bit32.lshift(n, 8), b[i])
	end

	return n
end

local function status()
	titleTextBox.lines[1] = "Selected byte" .. (selection.from == selection.to and "" or "s") .. ": " .. selection.from .. "-" .. selection.to
	titleTextBox.lines[2].text = "UTF-8: \"" .. string.char(table.unpack(bytes, selection.from, selection.to)) .. "\""
	titleTextBox.lines[3].text = "INT: " .. byteArrayToNumber({table.unpack(bytes, selection.from, selection.to)})
end

local function byteFieldDraw(object)
	local x, y, index = object.x, object.y, 1 + offset
	local xCount, yCount = math.ceil(object.width / object.elementWidth), math.ceil(object.height / object.elementHeight)
	
	for j = 1, yCount do
		for i = 1, xCount do
			if bytes[index] then
				local textColor = colors.backgroundText
				if index == selection.from or index == selection.to then
					screen.drawRectangle(x - object.offset, y, object.elementWidth, 1, index == selection.from and colors.selectionFrom or colors.selectionTo, colors.selectionText, " ")
					textColor = colors.selectionText
				elseif index > selection.from and index < selection.to then
					screen.drawRectangle(x - object.offset, y, object.elementWidth, 1, colors.selectionBetween, colors.selectionText, " ")
					textColor = colors.selectionBetweenText
				end

				screen.drawText(x, y, textColor, object.asChar and string.char(bytes[index]) or string.format("%02X", bytes[index]))
			else
				return object
			end

			x, index = x + object.elementWidth, index + 1
		end

		local lastLineIndex = index - 1
		if lastLineIndex >= selection.from and lastLineIndex < selection.to then
			screen.drawRectangle(object.x - object.offset, y + 1, object.width, 1, colors.selectionBetween, colors.selectionText, " ")
		end

		x, y = object.x, y + object.elementHeight
	end

	return object
end

local function byteFieldEventHandler(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "touch" or e1 == "drag" then
		if e5 == 1 then
			local menu = GUI.addContextMenu(workspace, e3, e4)
			
			menu:addItem("Select all").onTouch = function()
				selection.from = 1
				selection.to = #bytes
				
				workspace:draw()
			end
			
			menu:addSeparator()
			
			menu:addItem("Edit").onTouch = function()
				local container = system.addBackgroundContainer(workspace, "Fill byte range [" .. selection.from .. "; " .. selection.to .. "]")

				local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x666666, 0x666666, 0xE1E1E1, 0x2D2D2D, string.format("%02X" , bytes[selection.from]), "Type byte value"))
				input.onInputFinished = function(text)
					local number = tonumber("0x" .. input.text)
					if number and number >= 0 and number <= 255 then
						for i = selection.from, selection.to do
							bytes[i] = number
						end

						container:remove()
						workspace:draw()
					end
				end
				
				workspace:draw()
			end
			
			menu:addItem("Insert").onTouch = function()
				local container = system.addBackgroundContainer(workspace, "Insert bytes at position " .. selection.from .. "")

				local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x666666, 0x666666, 0xE1E1E1, 0x2D2D2D, "", "Type byte values separated by space", true))
				local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xBBBBBB, "Select inserted bytes:", true)).switch

				input.onInputFinished = function()
					if input.text:match("[a-fA-F%d%s]+") then
						local insertionPosition, count = selection.from, 0
						for word in input.text:gmatch("[^%s]+") do
							local number = tonumber("0x" .. word)
							if number > 255 then number = 255 end
							table.insert(bytes, insertionPosition + count, number)
							selection.from, selection.to, count = selection.from + 1, selection.to + 1, count + 1
						end

						if switch.state then
							selection.from, selection.to = insertionPosition, insertionPosition + count - 1
						end

						container:remove()
						workspace:draw()
					end
				end
				
				workspace:draw()
			end
			
			menu:addSeparator()
			
			menu:addItem("Delete").onTouch = function()
				for i = selection.from, selection.to do
					table.remove(bytes, selection.from)
				end
				if #bytes == 0 then
					selection.from, selection.to = 1, 1
				else
					selection.to = selection.from
				end
			end

			workspace:draw()
		else
			local index = (math.ceil((e4 - object.y + 1) / 2) - 1) * 16 + math.ceil((e3 - object.x + 1 + object.offset) / object.elementWidth) + offset
			
			if bytes[index] then
				if e1 == "touch" then
					selection.to = index
					selection.from = index
					selection.touchIndex = index
				else
					if not selection.touchIndex then selection.touchIndex = index end
					
					if index < selection.touchIndex then
						selection.from = index
						selection.to = selection.touchIndex
					elseif index > selection.touchIndex then
						selection.to = index
						selection.from = selection.touchIndex
					end
				end

				status()
				workspace:draw()
			end
		end
	elseif e1 == "scroll" then
		offset = offset - 16 * e5
		if offset < 0 then
			offset = 0
		elseif offset > math.floor(#bytes / 16) * 16 then
			offset = math.floor(#bytes / 16) * 16
		end
		scrollBar.value = offset

		workspace:draw()
	end
end

local function newByteField(x, y, width, elementWidth, elementHeight, asChar)
	local object = GUI.object(x, y, width, 1)
	
	object.elementWidth = elementWidth
	object.elementHeight = elementHeight
	object.offset = asChar and 0 or 1
	object.asChar = asChar
	object.draw = byteFieldDraw
	object.eventHandler = byteFieldEventHandler

	return object
end

------------------------------------------------------------------------------------------------------------------

window:addChild(GUI.panel(1, 1, window.width, 3, 0x3C3C3C)):moveToBack()

local byteField = window:addChild(newByteField(13, 6, 64, 4, 2, false))
local charField = window:addChild(newByteField(byteField.localX + byteField.width + 3, 6, 16, 1, 2, true))
local separator = window:addChild(GUI.object(byteField.localX + byteField.width, 5, 1, 1))
separator.draw = function(object)
	for i = object.y, object.y + object.height - 1 do
		screen.drawText(object.x, i, colors.separator, "│")
	end
end

window:addChild(GUI.panel(11, 4, window.width - 10, 1, colors.panel))

-- Vertical
local verticalCounter = window:addChild(GUI.object(1, 4, 10, 1))
verticalCounter.draw = function(object)
	screen.drawRectangle(object.x, object.y, object.width, object.height, colors.panel, colors.panelText, " ")

	local index = offset
	for y = 2, object.height - 1, 2 do
		local textColor = colors.panelText

		if index > selection.from and index < selection.to then
			screen.drawRectangle(object.x, object.y + y - 1, object.width, 2, colors.panelSeleciton, colors.panelSelecitonText, " ")
			textColor = colors.panelSelecitonText
		end

		if selection.from >= index and selection.from <= index + 15 or selection.to >= index and selection.to <= index + 15 then
			screen.drawRectangle(object.x, object.y + y, object.width, 1, colors.selectionFrom, colors.selectionText, " ")
			textColor = colors.selectionText
		end

		screen.drawText(object.x + 1, object.y + y, textColor, string.format("%08X", index))

		index = index + 16
	end
end

-- Horizontal
window:addChild(GUI.object(13, 4, 62, 1)).draw = function(object)
	local counter = 0
	local restFrom, restTo = selection.from % 16, selection.to % 16
	for x = 1, object.width, 4 do
		local textColor = colors.panelText
		if counter + 1 > restFrom and counter + 1 < restTo then
			screen.drawRectangle(object.x + x - 2, object.y, 4, 1, colors.panelSeleciton, colors.selectionText, " ")
			textColor = colors.panelSelecitonText
		elseif restFrom == counter + 1 or restTo == counter + 1 then
			screen.drawRectangle(object.x + x - 2, object.y, 4, 1, colors.selectionFrom, colors.selectionText, " ")
			textColor = colors.selectionText
		end

		screen.drawText(object.x + x - 1, object.y, textColor, string.format("%02X", counter))
		counter = counter + 1
	end
end

scrollBar = window:addChild(GUI.scrollBar(window.width, 5, 1, 1, 0xC3C3C3, 0x393939, 0, 1, 1, 160, 1, true))
scrollBar.eventHandler = nil

titleTextBox = window:addChild(
	GUI.textBox(1, 1, math.floor(window.width * 0.35), 3,
		colors.titleBackground,
		colors.titleText,
		{
			"",
			{text = "", color = colors.titleText2},
			{text = "", color = colors.titleText2}
		},
		1, 1, 0
	)
)

titleTextBox.localX = math.floor(window.width / 2 - titleTextBox.width / 2)
titleTextBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
titleTextBox.eventHandler = nil

local saveFileButton = window:addChild(GUI.adaptiveRoundedButton(titleTextBox.localX - 11, 2, 2, 0, colors.panel, colors.panelSelecitonText, colors.panelSelecitonText, colors.panel, "Save"))
local openFileButton = window:addChild(GUI.adaptiveRoundedButton(saveFileButton.localX - 11, 2, 2, 0, colors.panel, colors.panelSelecitonText, colors.panelSelecitonText, colors.panel, "Open"))

------------------------------------------------------------------------------------------------------------------

local function load(path)
	local file, reason = filesystem.open(path, "rb")
	
	if file then
		bytes = {}
		
		local byte
		while true do
			byte = file:readBytes(1)
			if byte then
				table.insert(bytes, byte)
			else
				break
			end
		end

		file:close()
		
		offset = 0
		selection.from, selection.to = 1, 1
		scrollBar.value, scrollBar.maximumValue = 0, #bytes
		
		status()
	else
		GUI.alert("Failed to open file for reading: " .. tostring(reason))
	end
end

openFileButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(workspace.height * 0.8), "Open", "Cancel", "File name", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:show()
	
	filesystemDialog.onSubmit = function(path)
		load(path)

		config.recentPath = path
		filesystem.writeTable(configPath, config)

		workspace:draw()
	end
end

saveFileButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(workspace.height * 0.8), "Save", "Cancel", "File name", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)
	filesystemDialog:show()
	
	filesystemDialog.onSubmit = function(path)
		local file = filesystem.open(path, "wb")
		if file then
			for i = 1, #bytes do
				file:write(string.char(bytes[i]))
			end
			file:close()
		else
			GUI.alert("Failed to open file for writing: " .. tostring(reason))
		end
	end
end

window.onResize = function(width, height)
	byteField.height = height - 6
	charField.height = byteField.height
	scrollBar.height = byteField.height
	window.backgroundPanel.height = height - 4
	verticalCounter.height = window.backgroundPanel.height + 1
	separator.height = byteField.height + 2
end

------------------------------------------------------------------------------------------------------------------

window.onResize(window.width, window.height)

local args, options = system.parseArguments(...)

load(((options.o or options.open) and args[1] and filesystem.exists(args[1])) and args[1] or config.recentPath)

workspace:draw()
