
local screen = require("Screen")
local filesystem = require("Filesystem")
local image = require("Image")
local color = require("Color")
local keyboard = require("Keyboard")
local event = require("Event")
local GUI = require("GUI")
local paths = require("Paths")
local text = require("Text")
local number = require("Number")

--------------------------------------------------------------------------------

local system = {}

local iconImageWidth = 8
local iconImageHeight = 4

local bootUptime = computer.uptime()
local dateUptime = bootUptime
local screensaverUptime = bootUptime

local user
local userSettings
local localization
local iconHalfWidth
local iconTextHeight
local iconImageHorizontalOffset
local bootRealTime

local workspace
local desktopWindowsContainer
local dockContainer
local desktopMenu
local desktopMenuLayout
local desktopIconField
local desktopBackground
local desktopBackgroundColor = 0x1E1E1E
local desktopBackgroundWallpaperX
local desktopBackgroundWallpaperY

-- Caching commonly used icons
local iconCache = {
	archive = image.load(paths.system.icons .. "Archive.pic"),
	directory = image.load(paths.system.icons .. "Folder.pic"),
	fileNotExists = image.load(paths.system.icons .. "FileNotExists.pic"),
	application = image.load(paths.system.icons .. "Application.pic"),
	script = image.load(paths.system.icons .. "Script.pic"),
}

--------------------------------------------------------------------------------

-- Returns real timestamp in seconds
function system.getTime()
	return bootRealTime + computer.uptime() + userSettings.timeTimezone
end

-- Returns currently logged in user
function system.getUser()
	return user
end

-- Returns logged in user settings
function system.getUserSettings()
	return userSettings
end

-- Returns current system localization table
function system.getSystemLocalization()
	return localization
end

function system.getDefaultUserSettings()
	return {
		localizationLanguage = "English",

		timeFormat = "%d %b %Y %H:%M:%S",
		timeRealTimestamp = true,
		timeTimezone = 0,

		networkUsers = {},
		networkName = "Computer #" .. string.format("%06X", math.random(0x0, 0xFFFFFF)),
		networkEnabled = true,
		networkSignalStrength = 512,
		networkFTPConnections = {},
		
		interfaceWallpaperEnabled = false,
		interfaceWallpaperPath = paths.system.pictures .. "Space.pic",
		interfaceWallpaperMode = 1,
		interfaceWallpaperBrightness = 0.9,

		interfaceScreensaverEnabled = false,
		interfaceScreensaverPath = paths.system.screensavers .. "Space.lua",
		interfaceScreensaverDelay = 20,
		
		interfaceTransparencyEnabled = true,
		interfaceTransparencyDock = 0.4,
		interfaceTransparencyMenu = 0.2,
		interfaceTransparencyContextMenu = 0.2,
		interfaceBlurEnabled = false,
		interfaceBlurRadius = 3,
		interfaceBlurTransparency = 0.6,

		interfaceColorDesktopBackground = 0x1E1E1E,
		interfaceColorDock = 0xE1E1E1,
		interfaceColorMenu = 0xF0F0F0,
		interfaceColorDropDownMenuSeparator = 0xA5A5A5,
		interfaceColorDropDownMenuDefaultBackground = 0xFFFFFF,
		interfaceColorDropDownMenuDefaultText = 0x2D2D2D,

		filesShowExtension = false,
		filesShowHidden = false,
		filesShowApplicationIcon = true,

		iconWidth = 12,
		iconHeight = 6,
		iconHorizontalSpace = 1,
		iconVerticalSpace = 1,
		
		tasks = {},
		dockShortcuts = {
			filesystem.path(paths.system.applicationAppMarket),
			filesystem.path(paths.system.applicationMineCodeIDE),
			filesystem.path(paths.system.applicationFinder),
			filesystem.path(paths.system.applicationPictureEdit),
			filesystem.path(paths.system.applicationSettings),
		},
		extensions = {
			[".lua"] = filesystem.path(paths.system.applicationMineCodeIDE),
			[".cfg"] = filesystem.path(paths.system.applicationMineCodeIDE),
			[".txt"] = filesystem.path(paths.system.applicationMineCodeIDE),
			[".lang"] = filesystem.path(paths.system.applicationMineCodeIDE),
			[".pic"] = filesystem.path(paths.system.applicationPictureView),
			[".3dm"] = paths.system.applications .. "3D Print.app/"
		},
	}
end

--------------------------------------------------------------------------------

function system.saveUserSettings()
	filesystem.writeTable(paths.user.settings, userSettings, true)
end

function system.getCurrentScript()
	local info

	for runLevel = 0, math.huge do
		info = debug.getinfo(runLevel)

		if info then
			if info.what == "main" then
				return info.source:sub(2, -1)
			end
		else
			error("Failed to get debug info for runlevel " .. runLevel)
		end
	end
end

function system.getLocalization(pathToLocalizationFolder)
	local required, english = pathToLocalizationFolder .. userSettings.localizationLanguage .. ".lang", pathToLocalizationFolder .. "English.lang"
	
	-- First trying to return required localization
	if filesystem.exists(required) then
		return filesystem.readTable(required)
	-- Otherwise maybe english localization exists?
	elseif filesystem.exists(english) then
		return filesystem.readTable(english)
	-- Otherwise returning first available localization
	else
		local list = filesystem.list(pathToLocalizationFolder)

		if #list > 0 then
			return filesystem.readTable(pathToLocalizationFolder .. list[1])
		else
			error("Failed to get localization: directory is empty")
		end
	end
end

function system.getCurrentScriptLocalization()
	return system.getLocalization(filesystem.path(system.getCurrentScript()) .. "Localizations/")
end

function system.getTemporaryPath()
	local temporaryPath
	repeat
		temporaryPath = paths.system.temporary .. string.format("%08X", math.random(0xFFFFFFFF))
	until not filesystem.exists(temporaryPath)

	return temporaryPath
end

function system.createShortcut(where, forWhat)
	filesystem.makeDirectory(filesystem.path(where))
	filesystem.write(where .. ".lnk", forWhat)
end

function system.parseArguments(...)
	local i, arguments, options, dashes, data, key, value = 1, {...}, {}

	while i <= #arguments do
		if type(arguments[i]) == "string" then
			dashes, data = arguments[i]:match("^(%-+)(.+)")
			
			if dashes then
				-- Single dash option
				if #dashes == 1 then
					for i = 1, unicode.len(data) do
						options[unicode.sub(data, i, i)] = true
					end
				-- Multiple dash option
				else
					-- Option with key and value
					key, value = data:match("^([^=]+)=(.+)")
					if key then
						options[key] = value
					else
						options[data] = true
					end
				end

				table.remove(arguments, i)
				i = i - 1
			end
		end

		i = i + 1
	end

	return arguments, options
end

function system.readShortcut(path)
	local data, reason = filesystem.read(path)
	if data then
		return data
	else
		error("Failed to read shortcut \"" .. tostring(path) .. "\": " .. tostring(reason))
	end
end

function system.call(method, ...)
	local args = {...}
	local function launchMethod()
		method(table.unpack(args))
	end

	local function tracebackMethod(xpcallTraceback)
		local traceback, info, firstMatch = tostring(xpcallTraceback) .. "\n" .. debug.traceback()
		for runLevel = 0, math.huge do
			info = debug.getinfo(runLevel)
			if info then
				if (info.what == "main" or info.what == "Lua") and info.source ~= "=machine" then
					if firstMatch then
						return {
							path = info.source:sub(2, -1),
							line = info.currentline,
							traceback = traceback
						}
					else
						firstMatch = true
					end
				end
			else
				error("Failed to get debug info for runlevel " .. runLevel)
			end
		end
	end
	
	local xpcallSuccess, xpcallReason = xpcall(launchMethod, tracebackMethod)
	if type(xpcallReason) == "string" or type(xpcallReason) == "nil" then
		xpcallReason = {
			path = paths.system.libraries .. "System.lua",
			line = 1,
			traceback = "system fatal error: " .. tostring(xpcallReason)
		}
	end

	if not xpcallSuccess and not xpcallReason.traceback:match("^table") and not xpcallReason.traceback:match("interrupted") then
		return false, xpcallReason.path, xpcallReason.line, xpcallReason.traceback
	end

	return true
end

function system.setPackageUnloading(value)
	local metatable = getmetatable(package.loaded)

	if value then
		if metatable then
			metatable.__mode = "v"
		else
			setmetatable(package.loaded, {__mode = "v"})
		end
	else
		if metatable then
			metatable.__mode = nil

			for key in pairs(metatable) do
				return
			end
			
			setmetatable(package.loaded, nil)
		end
	end
end

--------------------------------------------------------------------------------

local function addBackgroundContainerInput(parent, ...)
	return parent:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, ...))
end

local function addBackgroundContainerWithInput(inputText, title, placeholder)
	local container = GUI.addBackgroundContainer(workspace, true, true, title)
	
	container.input = addBackgroundContainerInput(container.layout, inputText, placeholder, false)
	container.label = container.layout:addChild(GUI.label(1, 1, 36, 1, 0xFF4940, localization.file .. " " .. localization.alreadyExists)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	container.label.hidden = true

	return container
end

local function checkFileToExists(container, path)
	if filesystem.exists(path) then
		container.label.hidden = false
		container.parent:draw()
	else
		container:remove()
		return true
	end
end

local function uploadToPastebin(path)
	local container = addBackgroundContainerWithInput("", localization.uploadToPastebin, localization.pasteName)

	local result, reason
	container.panel.eventHandler = function(workspace, panel, e1)
		if e1 == "touch" then
			if result == nil and #container.input.text > 0 then
				container.input:remove()
				local info = container.layout:addChild(GUI.text(1, 1, 0x878787, localization.uploading))

				workspace:draw()

				local internet = require("Internet")
				result, reason = internet.request("https://pastebin.com/api/api_post.php", internet.serialize({
					api_option = "paste",
					api_dev_key = "fd92bd40a84c127eeb6804b146793c97",
					api_paste_expire_date = "N",
					api_paste_format = filesystem.extension(path) == ".lua" and "lua" or "text",
					api_paste_name = container.input.text,
					api_paste_code = filesystem.read(path),
				}))

				info.text =
					result and
					(
						result:match("^http") and
						localization.uploadingSuccess .. result or
						localization.uploadingFailure .. result
					) or
					localization.uploadingFailure .. reason
			else
				container:remove()
			end

			workspace:draw()
		end
	end

	workspace:draw()
end

function system.addUploadToPastebinMenuItem(menu, path)
	menu:addItem(localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
		uploadToPastebin(path)
	end
end

function system.launchWithArguments(path)
	local container = addBackgroundContainerWithInput("", localization.launchWithArguments)

	container.panel.eventHandler = function(workspace, object, e1)
		if e1 == "touch" then
			local args = {}
			if container.input.text then
				for arg in container.input.text:gmatch("[^%s]+") do
					table.insert(args, arg)
				end
			end

			container:remove()
			system.execute(path, table.unpack(args))
			workspace:draw()
		end
	end

	workspace:draw()
end

local iconLaunchers = {
	application = function(icon)
		system.execute(icon.path .. "Main.lua")
	end,

	directory = function(icon)
		icon.parent:setPath(icon.path)
	end,

	shortcut = function(icon)
		local oldPath = icon.path
		icon.path = icon.shortcutPath
		icon:shortcutLaunch()
		icon.path = oldPath
	end,

	corrupted = function(icon)
		GUI.alert("Application is corrupted")
	end,

	extension = function(icon)
		if icon.isShortcut then
			system.execute(userSettings.extensions[icon.shortcutExtension] .. "Main.lua", icon.shortcutPath, "-o")
		else
			system.execute(userSettings.extensions[icon.extension] .. "Main.lua", icon.path, "-o")
		end
	end,

	script = function(icon)
		system.execute(paths.system.applicationMineCodeIDE, icon.path)
	end,

	showPackageContent = function(icon)
		icon.parent:setPath(icon.path)
		icon.parent:updateFileList()
		
		workspace:draw()
	end,

	showContainingFolder = function(icon)
		icon.parent:setPath(filesystem.path(icon.shortcutPath))
		icon.parent:updateFileList()
		
		workspace:draw()
	end,

	archive = function(icon)
		local success, reason = require("Compressor").unpack(icon.path, filesystem.path(icon.path))
		if success then
			computer.pushSignal("system", "updateFileList")
		else
			GUI.alert(reason)
		end
	end
}

function system.calculateIconProperties()
	iconHalfWidth = math.floor(userSettings.iconWidth / 2)
	iconTextHeight = userSettings.iconHeight - iconImageHeight - 1
	iconImageHorizontalOffset = math.floor(iconHalfWidth - iconImageWidth / 2)
end

function system.updateIconProperties()
	desktopIconField:deleteIconConfig()
	computer.pushSignal("system", "updateFileList")
end

local function drawSelection(x, y, width, height, color, transparency)
	screen.drawText(x, y, color, string.rep("▄", width), transparency)
	screen.drawText(x, y + height - 1, color, string.rep("▀", width), transparency)
	screen.drawRectangle(x, y + 1, width, height - 2, color, 0x0, " ", transparency)
end

local function gridIconDraw(icon)
	local selectionTransparency = userSettings.interfaceTransparencyEnabled and icon.colors.selectionTransparency
	local xCenter, yText = icon.x + iconHalfWidth, icon.y + iconImageHeight + 1

	local function gridIconDrawNameLine(y, line)
		local lineLength = unicode.len(line)
		local x = math.floor(xCenter - lineLength / 2)

		local foreground
		if icon.selected then
			foreground = icon.colors.selectionText
			screen.drawRectangle(x, y, lineLength, 1, icon.colors.selectionBackground, foreground or 0xFF00FF, " ", selectionTransparency)
		else
			foreground = icon.colors.defaultText
		end

		screen.drawText(x, y, foreground or 0xFF00FF, line)
	end

	local charIndex = 1
	for lineIndex = 1, iconTextHeight do
		if lineIndex < iconTextHeight then
			gridIconDrawNameLine(yText, unicode.sub(icon.name, charIndex, charIndex + icon.width - 1))
			charIndex, yText = charIndex + icon.width, yText + 1
		else
			gridIconDrawNameLine(yText, text.limit(unicode.sub(icon.name, charIndex, -1), icon.width, "center"))
		end
	end

	local xImage = icon.x + iconImageHorizontalOffset
	if icon.selected then
		drawSelection(xImage - 1, icon.y - 1, iconImageWidth + 2, iconImageHeight + 2, icon.colors.selectionBackground, selectionTransparency)
	end

	if icon.image then
		if icon.cut then
			if not icon.semiTransparentImage then
				icon.semiTransparentImage = image.copy(icon.image)
				for i = 3, #icon.semiTransparentImage, 4 do
					icon.semiTransparentImage[i + 2] = icon.semiTransparentImage[i + 2] + 0.6
					if icon.semiTransparentImage[i + 2] > 1 then
						icon.semiTransparentImage[i + 2] = 1
					end
				end
			end
			
			screen.drawImage(xImage, icon.y, icon.semiTransparentImage, true)
		else
			screen.drawImage(xImage, icon.y, icon.image)
		end
	elseif icon.liveImage then
		icon.liveImage(xImage, icon.y)
	end

	local xShortcut = xImage + iconImageWidth
	if icon.isShortcut then
		screen.set(xShortcut - 1, icon.y + iconImageHeight - 1, 0xFFFFFF, 0x0, "<")
	end

	if icon.windows then
		screen.drawText(xCenter - 1, icon.y + iconImageHeight, 0x66DBFF, "╺╸")
		
		if icon.windowCount > 1 then
			local windowCount = tostring(icon.windowCount)
			local windowCountLength = #windowCount
			local xTip, yTip = xShortcut - windowCountLength, icon.y

			screen.drawRectangle(xTip, yTip, windowCountLength, 1, 0xFF4940, 0xFFFFFF, " ")
			screen.drawText(xTip, yTip, 0xFFFFFF, windowCount)
			screen.drawText(xTip - 1, yTip, 0xFF4940, "⢸")
			screen.drawText(xTip + windowCountLength, yTip, 0xFF4940, "⡇")
			screen.drawText(xTip, yTip - 1, 0xFF4940, string.rep("⣀", windowCountLength))
			screen.drawText(xTip, yTip + 1, 0xFF4940, string.rep("⠉", windowCountLength))
		end
	end
end

local function iconFieldSaveIconPosition(iconField, filename, x, y)
	if iconField.iconConfigEnabled then
		iconField.iconConfig[filename] = { x = x, y = y }
		iconField:saveIconConfig()
	end
end

local function iconDeselectAndSelect(icon)
	if not keyboard.isKeyDown(29) and not keyboard.isKeyDown(219) then
		icon.parent:clearSelection()
	end
	icon.selected = true

	workspace:draw()
end

local function iconOnRightClick(selectedIcons, icon, e1, e2, e3, e4)
	local contextMenu = GUI.addContextMenu(workspace, e3, e4)

	if #selectedIcons > 1 then
		contextMenu:addItem(localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")").onTouch = function()
			local container = addBackgroundContainerWithInput("", localization.newFolderFromChosen .. " (" .. #selectedIcons .. ")", localization.folderName)

			container.input.onInputFinished = function()
				local path = filesystem.path(selectedIcons[1].path) .. container.input.text .. "/"
				if checkFileToExists(container, path) then
					filesystem.makeDirectory(path)
					
					for i = 1, #selectedIcons do
						filesystem.rename(selectedIcons[i].path, path .. selectedIcons[i].name)
					end

					iconFieldSaveIconPosition(icon.parent, container.input.text, e3, e4)
					computer.pushSignal("system", "updateFileList")
				end
			end

			workspace:draw()
		end

		contextMenu:addSeparator()
	else
		if icon.isDirectory then
			if icon.extension == ".app" then
				contextMenu:addItem(localization.edit .. " Main.lua").onTouch = function()
					system.execute(paths.system.applicationMineCodeIDE, icon.path .. "Main.lua")
				end

				contextMenu:addItem(localization.showPackageContent).onTouch = function()
					icon.parent.launchers.showPackageContent(icon)
				end		

				contextMenu:addItem(localization.launchWithArguments).onTouch = function()
					system.launchWithArguments(icon.path .. "Main.lua")
				end

				contextMenu:addSeparator()
			end

			if icon.extension ~= ".app" then
				contextMenu:addItem(localization.addToFavourites).onTouch = function()
					local container = GUI.addBackgroundContainer(workspace, true, true, localization.addToFavourites)

					local input = addBackgroundContainerInput(container.layout, icon.name, localization.name)
					container.panel.eventHandler = function(workspace, object, e1)
						if e1 == "touch" then
							container:remove()

							if e1 == "touch" and #input.text > 0 then
								computer.pushSignal("Finder", "updateFavourites", {name = input.text, path = icon.path})
							else
								workspace:draw()
							end
						end
					end					
			 	end
			end
		else
			if icon.isShortcut then
				contextMenu:addItem(localization.editShortcut).onTouch = function()
					local text = system.readShortcut(icon.path)
					local container = addBackgroundContainerWithInput(text, localization.editShortcut, localization.rename)

					container.input.onInputFinished = function()
						if filesystem.exists(container.input.text) then
							system.createShortcut(icon.path, container.input.text)
							container:remove()
							computer.pushSignal("system", "updateFileList")
						else
							container.label.text = localization.shortcutIsCorrupted
							container.label.hidden = false

							workspace:draw()
						end
					end

					workspace:draw()
				end

				contextMenu:addItem(localization.showContainingFolder).onTouch = function()
					icon.parent.launchers.showContainingFolder(icon)
				end

				contextMenu:addSeparator()
			else
				local function addDefault()
					contextMenu:addItem(localization.uploadToPastebin, not component.isAvailable("internet")).onTouch = function()
						uploadToPastebin(icon.path)
					end
					contextMenu:addSeparator()
				end

				if userSettings.extensions[icon.extension] then
					local result, reason = loadfile(userSettings.extensions[icon.extension] .. "Extensions/" .. icon.extension .. "/Context menu.lua")
					if result then
						result, reason = pcall(result, workspace, icon, contextMenu)

						if result then
							contextMenu:addSeparator()
						else
							GUI.alert("Failed to load extension association: " .. tostring(reason))
						end
					else
						addDefault()
					end
				else
					addDefault()
				end

				-- Open with
				local subMenu = contextMenu:addSubMenuItem(localization.openWith)
				
				local function setAssociation(path)
					userSettings.extensions[icon.extension] = path
					
					iconCache[icon.extension] = nil
					icon:analyseExtension(icon.parent.launchers)
					icon:launch()
					workspace:draw()

					system.saveUserSettings()
				end

				subMenu:addItem(localization.select).onTouch = function()
					local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(workspace.height * 0.8), localization.open, localization.cancel, localization.fileName, "/")
					
					filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_DIRECTORY)
					filesystemDialog:addExtensionFilter(".app")
					filesystemDialog:expandPath(paths.system.applications)
					filesystemDialog.filesystemTree.selectedItem = userSettings.extensions[icon.extension]
					filesystemDialog.onSubmit = function(path)
						setAssociation(path)
					end

					filesystemDialog:show()
				end

				subMenu:addSeparator()

				local list = filesystem.list(paths.system.applications)
				for i = 1, #list do
					local path = paths.system.applications .. list[i]

					if path:sub(-1) == "/" and filesystem.extension(list[i]) == ".app" then
						subMenu:addItem(filesystem.hideExtension(list[i])).onTouch = function()
							setAssociation(path)
						end
					end
				end
			end
		end
	end

	if not icon.isShortcut or #selectedIcons > 1 then
		local subMenu = contextMenu:addSubMenuItem(localization.createShortcut)
		
		subMenu:addItem(localization.inCurrentDirectory).onTouch = function()
			for i = 1, #selectedIcons do
				if not selectedIcons[i].isShortcut then
					system.createShortcut(
						filesystem.path(selectedIcons[i].path) .. filesystem.hideExtension(selectedIcons[i].name),
						selectedIcons[i].path
					)
				end
			end
			
			computer.pushSignal("system", "updateFileList")
		end

		subMenu:addItem(localization.onDesktop).onTouch = function()
			for i = 1, #selectedIcons do
				if not selectedIcons[i].isShortcut then
					system.createShortcut(
						paths.user.desktop ..  filesystem.hideExtension(selectedIcons[i].name),
						selectedIcons[i].path
					)
				end
			end
			
			computer.pushSignal("system", "updateFileList")
		end
	end

	local subMenu = contextMenu:addSubMenuItem(localization.archive .. (#selectedIcons > 1 and " (" .. #selectedIcons .. ")" or ""))
	
	local function archive(where)
		local itemsToArchive = {}
		for i = 1, #selectedIcons do
			table.insert(itemsToArchive, selectedIcons[i].path)
		end

		local success, reason = require("Compressor").pack(where .. "/Archive.pkg", itemsToArchive)
		if not success then
			GUI.alert(reason)
		end
		
		computer.pushSignal("system", "updateFileList")
	end

	subMenu:addItem(localization.inCurrentDirectory).onTouch = function()
		archive(filesystem.path(icon.path))
	end

	subMenu:addItem(localization.onDesktop).onTouch = function()
		archive(paths.user.desktop)
	end

	if #selectedIcons == 1 then
		contextMenu:addItem(localization.addToDock).onTouch = function()
			dockContainer.addIcon(icon.path).keepInDock = true
			dockContainer.saveUserSettings()
		end
	end

	contextMenu:addSeparator()

	local function cutOrCopy(cut)
		for i = 1, #icon.parent.children do
			icon.parent.children[i].cut = nil
		end

		system.clipboard = {cut = cut}
		for i = 1, #selectedIcons do
			selectedIcons[i].cut = cut
			table.insert(system.clipboard, selectedIcons[i].path)
		end
	end

	contextMenu:addItem(localization.cut).onTouch = function()
		cutOrCopy(true)
	end

	contextMenu:addItem(localization.copy).onTouch = function()
		cutOrCopy()
	end

	if #selectedIcons == 1 then
		contextMenu:addItem(localization.rename).onTouch = function()
			local container = addBackgroundContainerWithInput(filesystem.name(icon.path), localization.rename, localization.newName)

			container.input.onInputFinished = function()
				if checkFileToExists(container, filesystem.path(icon.path) .. container.input.text) then
					filesystem.rename(icon.path, filesystem.path(icon.path) .. container.input.text)
					computer.pushSignal("system", "updateFileList")
				end
			end

			workspace:draw()
		end
	end

	contextMenu:addItem(localization.delete).onTouch = function()
		for i = 1, #selectedIcons do
			if filesystem.path(selectedIcons[i].path) == paths.user.trash then
				filesystem.remove(selectedIcons[i].path)
			else
				local newName = paths.user.trash .. selectedIcons[i].name
				local clearName = filesystem.hideExtension(selectedIcons[i].name)
				local repeats = 1
				while filesystem.exists(newName) do
					newName, repeats = paths.user.trash .. clearName .. string.rep("-copy", repeats) .. (selectedIcons[i].extension or ""), repeats + 1
				end
				filesystem.rename(selectedIcons[i].path, newName)
			end
		end

		computer.pushSignal("system", "updateFileList")
	end

	contextMenu:addSeparator()

	contextMenu:addItem(localization.properties).onTouch = function()
		for i = 1, #selectedIcons do
			system.addPropertiesWindow(e3, e4, 46, selectedIcons[i])
		end
	end

	workspace:draw()
end

local function iconOnDoubleClick(icon)
	icon:launch()
	workspace:draw()
end

local function gridIconFieldIconEventHandler(workspace, object, e1, e2, e3, e4, e5, ...)
	if e1 == "touch" and object:isPointInside(e3, e4) then
		object.lastTouchPosition = object.lastTouchPosition or {}
		object.lastTouchPosition.x, object.lastTouchPosition.y = e3, e4
		object:moveToFront()

		if e5 == 0 then
			iconDeselectAndSelect(object)
		else
			local selectedIcons = {}
			for i = 2, #object.parent.children do
				if object.parent.children[i].selected then
					table.insert(selectedIcons, object.parent.children[i])
				end
			end

			-- Right click on multiple selected icons	
			if not object.selected then
				iconDeselectAndSelect(object)
				selectedIcons = {object}
			end

			iconOnRightClick(selectedIcons, object, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "double_touch" and object:isPointInside(e3, e4) and e5 == 0 then
		iconOnDoubleClick(object, e1, e2, e3, e4, e5, ...)
	elseif e1 == "drag" and object.parent.iconConfigEnabled and object.lastTouchPosition then
		-- Ебучие авторы мода, ну на кой хуй было делать drop-ивент без наличия drag? ПИДОРЫ
		object.dragStarted = true
		object.localX = object.localX + e3 - object.lastTouchPosition.x
		object.localY = object.localY + e4 - object.lastTouchPosition.y
		object.lastTouchPosition.x, object.lastTouchPosition.y = e3, e4

		workspace:draw()
	elseif e1 == "drop" and object.dragStarted then
		object.dragStarted = nil
		object.lastTouchPosition = nil

		iconFieldSaveIconPosition(
			object.parent,
			object.name .. (object.isDirectory and "/" or ""),
			object.localX,
			object.localY
		)
	end
end

local function anyIconAnalyseExtension(icon, launchers)
	if icon.isDirectory then
		if icon.extension == ".app" then
			if userSettings.filesShowApplicationIcon then
				icon.image = image.load(icon.path .. "Icon.pic") or iconCache.fileNotExists
			else
				icon.image = iconCache.application
			end

			icon.launch = launchers.application
		else
			icon.image = iconCache.directory
			icon.launch = launchers.directory
		end
	else
		if icon.extension == ".lnk" then
			icon.shortcutPath = system.readShortcut(icon.path)
			icon.shortcutExtension = filesystem.extension(icon.shortcutPath)
			icon.shortcutIsDirectory = icon.shortcutPath:sub(-1) == "/"
			icon.isShortcut = true

			local shortcutIcon = anyIconAnalyseExtension(
				{
					path = icon.shortcutPath,
					extension = icon.shortcutExtension,
					name = icon.name,
					isDirectory = icon.shortcutIsDirectory,
					iconImage = icon.iconImage,
				},
				launchers
			)

			icon.image = shortcutIcon.image
			icon.shortcutLaunch = shortcutIcon.launch
			icon.launch = launchers.shortcut
		elseif icon.extension == ".pkg" then
			icon.image = iconCache.archive
			icon.launch = launchers.archive
		elseif userSettings.extensions[icon.extension] then
			if iconCache[icon.extension] then
				icon.image = iconCache[icon.extension]
			else
				local picture =
					image.load(userSettings.extensions[icon.extension] .. "Extensions/" .. icon.extension .. "/Icon.pic") or
					image.load(userSettings.extensions[icon.extension] .. "Icon.pic")
				
				if picture then
					iconCache[icon.extension] = picture
					icon.image = picture
				else
					icon.image = iconCache.fileNotExists
				end
			end

			icon.launch = launchers.extension
		elseif not filesystem.exists(icon.path) then
			icon.image = iconCache.fileNotExists
			icon.launch = launchers.corrupted
		else
			icon.image = iconCache.script
			icon.launch = launchers.script
		end
	end

	return icon
end

local function gridIconIsPointInside(icon, x, y)
	return
		x >= icon.x + iconImageHorizontalOffset and
		y >= icon.y and
		x <= icon.x + iconImageHorizontalOffset + iconImageWidth - 1 and
		y <= icon.y + iconImageHeight - 1
		or
		x >= icon.x and 
		y >= icon.y + iconImageHeight + 1 and
		x <= icon.x + userSettings.iconWidth - 1 and
		y <= icon.y + userSettings.iconHeight - 1
end

local function anyIconAddInfo(icon, path)
	icon.path = path
	icon.extension = filesystem.extension(path)
	icon.isDirectory = path:sub(-1) == "/"

	local name = icon.isDirectory and filesystem.name(path):sub(1, -2) or filesystem.name(path)
	icon.name = userSettings.filesShowExtension and name or filesystem.hideExtension(name)

	icon.analyseExtension = anyIconAnalyseExtension
end

function system.gridIcon(x, y, path, colors)
	local icon = GUI.object(x, y, userSettings.iconWidth, userSettings.iconHeight)
	
	anyIconAddInfo(icon, path)

	icon.colors = colors
	icon.isPointInside = gridIconIsPointInside
	icon.draw = gridIconDraw

	return icon
end

local function iconFieldLoadIconConfig(iconField)
	local configPath = iconField.path .. ".icons"
	if filesystem.exists(configPath) then
		iconField.iconConfig = filesystem.readTable(configPath)
	else
		iconField.iconConfig = {}
	end
end

local function iconFieldSaveIconConfig(iconField)
	filesystem.writeTable(iconField.path .. ".icons", iconField.iconConfig)
end

local function iconFieldDeleteIconConfig(iconField)
	iconField.iconConfig = {}
	filesystem.remove(iconField.path .. ".icons", iconField.iconConfig)
end

---------------------------------------- Icon field ----------------------------------------

local function gridIconFieldCheckSelection(iconField)
	local selection = iconField.selection
	if selection and selection.x2 then
		local child

		for i = 1, #iconField.children do
			child = iconField.children[i]

			local xCenter, yCenter = child.x + userSettings.iconWidth / 2, child.y + userSettings.iconHeight / 2
			child.selected = 
				xCenter >= selection.x1 and
				xCenter <= selection.x2 and
				yCenter >= selection.y1 and
				yCenter <= selection.y2
		end
	end
end

local function anyIconFieldAddIcon(iconField, icon)
	-- Cheching "cut" state
	if system.clipboard and system.clipboard.cut then
		for i = 1, #system.clipboard do
			if system.clipboard[i] == icon.path then
				icon.cut = true
			end
		end
	end

	icon:analyseExtension(iconField.launchers)
end

local function anyIconFieldUpdateFileList(iconField, func)
	local list, reason = filesystem.list(iconField.path, userSettings.filesSortingMethod)
	if list then
		-- Hidden files and filename matcher
		local i = 1
		while i <= #list do
			if
				(
					not userSettings.filesShowHidden and
					filesystem.isHidden(list[i])
				)
				or
				(
					iconField.filenameMatcher and
					not unicode.lower(list[i]):match(iconField.filenameMatcher)
				)
			then
				table.remove(list, i)
			else
				i = i + 1
			end
		end

		-- 
		func(list)
	else
		GUI.alert("Failed to update file list: " .. tostring(reason))
	end

	return iconField
end

local function gridIconFieldUpdateFileList(iconField)
	anyIconFieldUpdateFileList(iconField, function(list)
		local function addGridIcon(x, y, path)
			local icon = system.gridIcon(
					x,
					y,
					iconField.path .. path,
					iconField.colors
				)

			anyIconFieldAddIcon(iconField, icon)
			icon.eventHandler = gridIconFieldIconEventHandler

			iconField:addChild(icon)
		end

		-- Updating sizes
		iconField.yOffset = iconField.yOffsetInitial

		iconField.backgroundObject.width, iconField.backgroundObject.height = iconField.width, iconField.height

		iconField.iconCount.horizontal = math.floor((iconField.width - iconField.xOffset) / (userSettings.iconWidth + userSettings.iconHorizontalSpace))
		iconField.iconCount.vertical = math.floor((iconField.height - iconField.yOffset) / (userSettings.iconHeight + userSettings.iconVerticalSpace))
		iconField.iconCount.total = iconField.iconCount.horizontal * iconField.iconCount.vertical

		-- Clearing eblo
		iconField:removeChildren(2)

		-- Updating icon config if possible
		if iconField.iconConfigEnabled then
			iconField:loadIconConfig()
		end
		
		--
		local i, configList, notConfigList = 1, {}, {}
		while i <= #list do
			if iconField.iconConfigEnabled and iconField.iconConfig[list[i]] then
				table.insert(configList, list[i])
			else
				table.insert(notConfigList, list[i])
			end

			table.remove(list, i)
		end

		-- Filling icons container
		for i = 1, #configList do
			addGridIcon(iconField.iconConfig[configList[i]].x, iconField.iconConfig[configList[i]].y, configList[i])
		end

		local x, y = iconField.xOffset, iconField.yOffset

		local function nextX()
			x = x + userSettings.iconWidth + userSettings.iconHorizontalSpace
			if x + userSettings.iconWidth + userSettings.iconHorizontalSpace > iconField.width then
				x, y = iconField.xOffset, y + userSettings.iconHeight + userSettings.iconVerticalSpace
			end
		end

		if #configList > 0 then
			for i = 2, #iconField.children do
				y = math.max(y, iconField.children[i].localY)
			end

			for i = 2, #iconField.children do
				if iconField.children[i].localY == y then
					x = math.max(x, iconField.children[i].localX)
				end
			end

			nextX()
		end

		for i = 1, #notConfigList do
			addGridIcon(x, y, notConfigList[i])
			iconField.iconConfig[notConfigList[i]] = {x = x, y = y}

			nextX()
		end

		if iconField.iconConfigEnabled then
			iconField:saveIconConfig()
		end
	end)
end

local function listIconFieldUpdateFileList(iconField)
	anyIconFieldUpdateFileList(iconField, function(list)
		-- Removing old rows
		iconField:clear()

		local function cell1Draw(self)
			local foreground = GUI.tableCellDraw(self)

			screen.drawText(self.x, self.y, self.pizda, " ■ ")
			screen.drawText(self.x + 3, self.y, foreground, self.name)
		end

		local function newCell1(path)
			local icon = GUI.tableCell(iconField.cell1Colors)
			
			anyIconAddInfo(icon, path)
			anyIconFieldAddIcon(iconField, icon)

			icon.draw = cell1Draw

			return icon
		end

		local file
		for i = 1, #list do
			file = list[i] 

			if file then
				file = iconField.path .. file

				local icon = newCell1(file)

				-- Adding a single-pixel representation of icon
				for i = 3, #icon.image, 4 do
					if icon.image[i + 2] == 0 then
						icon.pizda = icon.image[i]
						break
					end
				end
				icon.pizda = icon.pizda or 0x0
				
				iconField:addRow(
					icon,
					GUI.tableTextCell(iconField.cell2Colors, os.date(userSettings.timeFormat, math.floor(filesystem.lastModified(file) / 1000))),
					GUI.tableTextCell(iconField.cell2Colors, icon.isDirectory and "-" or number.roundToDecimalPlaces(filesystem.size(file) / 1024, 2) .. " KB"),
					GUI.tableTextCell(iconField.cell2Colors, icon.isDirectory and localization.folder or (icon.extension and icon.extension:sub(2, 2):upper() .. icon.extension:sub(3, -1) or "-"))
				)
			else
				break
			end
		end
	end)
end

local function iconFieldBackgroundClick(iconField, e1, e2, e3, e4, e5, ...)
	local contextMenu = GUI.addContextMenu(workspace, e3, e4)

	local subMenu = contextMenu:addSubMenuItem(localization.create)

	subMenu:addItem(localization.newFile).onTouch = function()
		local container = addBackgroundContainerWithInput("", localization.newFile, localization.fileName)

		container.input.onInputFinished = function()
			local path = iconField.path .. container.input.text
			if checkFileToExists(container, path) then
				filesystem.write(path, "")

				iconFieldSaveIconPosition(iconField, container.input.text, e3, e4)
				system.execute(paths.system.applicationMineCodeIDE, path)
				computer.pushSignal("system", "updateFileList")
			end
		end

		workspace:draw()
	end
	
	subMenu:addItem(localization.newFolder).onTouch = function()
		local container = addBackgroundContainerWithInput("", localization.newFolder, localization.folderName)

		container.input.onInputFinished = function()
			local path = iconField.path .. container.input.text
			if checkFileToExists(container, path) then
				filesystem.makeDirectory(path)
				iconFieldSaveIconPosition(iconField, container.input.text .. "/", e4, e4)
				computer.pushSignal("system", "updateFileList")
			end
		end

		workspace:draw()
	end

	subMenu:addItem(localization.newImage).onTouch = function()
		local container = addBackgroundContainerWithInput("", localization.newImage, localization.fileName)

		local layout = container.layout:addChild(GUI.layout(1, 1, 36, 3, 1, 1))
		layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
		layout:setSpacing(1, 1, 0)

		local widthInput = addBackgroundContainerInput(layout, "", "width")
		layout:addChild(GUI.text(1, 1, 0x696969, " x "))
		local heightInput = addBackgroundContainerInput(layout, "", "height")
		widthInput.width, heightInput.width = 16, 17

		container.panel.eventHandler = function(workspace, panel, e1)
			if e1 == "touch" then
				if
					#container.input.text > 0 and
					widthInput.text:match("%d+") and
					heightInput.text:match("%d+")
				then
					local imageName = filesystem.hideExtension(container.input.text) .. ".pic"
					local path = iconField.path .. imageName

					if checkFileToExists(container, path) then
						image.save(path, image.create(
							tonumber(widthInput.text),
							tonumber(heightInput.text),
							0x0,
							0xFFFFFF,
							1,
							" "
						))

						iconFieldSaveIconPosition(iconField, imageName, e3, e4)
						computer.pushSignal("system", "updateFileList")
					end
				end

				container:remove()
				workspace:draw()
			end
		end

		workspace:draw()
	end

	subMenu:addItem(localization.newFileFromURL, not component.isAvailable("internet")).onTouch = function()
		local container = addBackgroundContainerWithInput("", localization.newFileFromURL, localization.fileName)

		local inputURL = addBackgroundContainerInput(container.layout, "", "URL", false)
		
		container.panel.eventHandler = function(workspace, panel, e1)
			if e1 == "touch" then
				if #container.input.text > 0 and #inputURL.text > 0 then
					local path = iconField.path .. container.input.text
					
					if filesystem.exists(path) then
						container.label.hidden = false
						workspace:draw()
					else
						container.layout:removeChildren(2)
						container.layout:addChild(GUI.label(1, 1, container.width, 1, 0x878787, localization.downloading .. "...")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
						workspace:draw()

						local success, reason = require("Internet").download(inputURL.text, path)
						
						container:remove()

						if success then
							iconFieldSaveIconPosition(iconField, container.input.text, e3, e4)
							computer.pushSignal("system", "updateFileList")
						else
							GUI.alert(reason)
							workspace:draw()
						end
					end
				else
					container:remove()
					workspace:draw()
				end
			end
		end

		workspace:draw()
	end

	subMenu:addSeparator()

	subMenu:addItem(localization.newApplication).onTouch = function()
		local container = addBackgroundContainerWithInput("", localization.newApplication, localization.applicationName)
		
		container.panel.eventHandler = function(workspace, panel, e1)
			if e1 == "touch" then	
				if #container.input.text > 0 then
					local path = iconField.path .. container.input.text .. ".app/"
					
					if checkFileToExists(container, path) then
						system.copy({ paths.system.applicationSample }, paths.system.temporary)
						filesystem.rename(paths.system.temporary .. filesystem.name(paths.system.applicationSample), path)
						
						container:remove()
						iconFieldSaveIconPosition(iconField, container.input.text .. ".app/", e3, e4)
						computer.pushSignal("system", "updateFileList")
					end
				else
					container:remove()
					workspace:draw()
				end
			end
		end

		workspace:draw()
	end

	contextMenu:addSeparator()
				
	local subMenu = contextMenu:addSubMenuItem(localization.sortBy)
	
	local function sortAutomatically()
		if iconField.iconConfigEnabled then
			iconField:deleteIconConfig()
		end

		computer.pushSignal("system", "updateFileList")
	end

	local function setSortingMethod(sm)
		userSettings.filesSortingMethod = sm
		system.saveUserSettings()

		sortAutomatically()
	end

	subMenu:addItem(localization.sortByName).onTouch = function()
		setSortingMethod(filesystem.SORTING_NAME)
	end

	subMenu:addItem(localization.sortByDate).onTouch = function()
		setSortingMethod(filesystem.SORTING_DATE)
	end

	subMenu:addItem(localization.sortByType).onTouch = function()
		setSortingMethod(filesystem.SORTING_TYPE)
	end

	contextMenu:addItem(localization.sortAutomatically).onTouch = sortAutomatically

	contextMenu:addItem(localization.update).onTouch = function()
		iconField:updateFileList()
	end

	contextMenu:addSeparator()

	contextMenu:addItem(localization.paste, not system.clipboard).onTouch = function()
		local i = 1
		while i <= #system.clipboard do
			if filesystem.exists(system.clipboard[i]) then
				i = i + 1
			else
				table.remove(system.clipboard, i)
			end
		end

		system.copy(system.clipboard, iconField.path)

		if system.clipboard.cut then
			for i = 1, #system.clipboard do
				filesystem.remove(system.clipboard[i])
			end

			system.clipboard = nil
		end

		computer.pushSignal("system", "updateFileList")
	end

	workspace:draw()
end

local function gridIconFieldBackgroundObjectEventHandler(workspace, object, e1, e2, e3, e4, e5, ...)
	local iconField = object.parent

	if e1 == "touch" then
		if e5 == 0 then
			iconField:clearSelection()
			iconField.selection = {
				x1Raw = e3,
				y1Raw = e4
			}
			gridIconFieldCheckSelection(iconField)

			workspace:draw()
		else
			iconFieldBackgroundClick(iconField, e1, e2, e3, e4, e5, ...)
		end
	elseif e1 == "drag" then
		if iconField.selection then
			local selection = iconField.selection
			selection.x2Raw, selection.y2Raw = e3, e4

			-- Creating ordered representation of selection
			selection.x1, selection.y1, selection.x2, selection.y2 =
				selection.x1Raw, selection.y1Raw, selection.x2Raw, selection.y2Raw

			if selection.x2 < selection.x1 then
				selection.x1, selection.x2 = selection.x2, selection.x1
			end

			if selection.y2 < selection.y1 then
				selection.y1, selection.y2 = selection.y2, selection.y1
			end

			gridIconFieldCheckSelection(iconField)
			object:moveToFront()

			workspace:draw()
		end
	elseif e1 == "drop" then
		iconField.selection = nil
		gridIconFieldCheckSelection(iconField)
		object:moveToBack()

		workspace:draw()
	end
end

local function iconFieldBackgroundObjectDraw(object)
	local selection = object.parent.selection
	if selection and object.parent.selection.x2 then
		local y1, y2
		if selection.y1Raw < selection.y2Raw then
			y1, y2 = selection.y1 + object.parent.yOffset - object.parent.yOffsetInitial, selection.y2
		else
			y1, y2 = selection.y1, selection.y2 + object.parent.yOffset - object.parent.yOffsetInitial
		end

		if userSettings.interfaceTransparencyEnabled then	
			screen.drawRectangle(selection.x1, y1, selection.x2 - selection.x1 + 1, y2 - y1 + 1, object.parent.colors.selectionFrame, 0x0, " ", 0.6)
		else
			screen.drawFrame(selection.x1, y1, selection.x2 - selection.x1 + 1, y2 - y1 + 1, object.parent.colors.selectionFrame)
		end
	end
end

local function gridIconFieldClearSelection(self)
	for i = 1, #self.children do
		self.children[i].selected = nil
	end
end

local function iconFieldSetPath(iconField, path)
	iconField.path = path
	iconField.filenameMatcher = nil
	iconField.fromFile = 1

	return iconField
end

local function anyIconFieldAddInfo(iconField, path)
	iconField.path = path
	iconField.filenameMatcher = nil

	iconField.setPath = iconFieldSetPath

	-- Duplicate icon launchers for overriding possibility
	iconField.launchers = {}
	for key, value in pairs(iconLaunchers) do
		iconField.launchers[key] = value
	end
end

function system.gridIconField(x, y, width, height, xOffset, yOffset, path, defaultTextColor, selectionBackgroundColor, selectionTextColor, selectionFrameColor, selectionTransparency)
	local iconField = GUI.container(x, y, width, height)

	iconField.colors = {
		defaultText = defaultTextColor,
		selectionBackground = selectionBackgroundColor,
		selectionText = selectionTextColor,
		selectionFrame = selectionFrameColor,
		selectionTransparency = selectionTransparency,
	}
	iconField.iconConfigEnabled = false
	iconField.xOffset = xOffset
	iconField.yOffsetInitial = yOffset
	iconField.yOffset = yOffset
	iconField.iconCount = {}
	iconField.iconConfig = {}

	iconField.backgroundObject = iconField:addChild(GUI.object(1, 1, width, height))
	iconField.backgroundObject.eventHandler = gridIconFieldBackgroundObjectEventHandler
	iconField.backgroundObject.draw = iconFieldBackgroundObjectDraw

	iconField.clearSelection = gridIconFieldClearSelection
	iconField.loadIconConfig = iconFieldLoadIconConfig
	iconField.saveIconConfig = iconFieldSaveIconConfig
	iconField.deleteIconConfig = iconFieldDeleteIconConfig
	iconField.updateFileList = gridIconFieldUpdateFileList

	anyIconFieldAddInfo(iconField, path)

	return iconField
end

function system.listIconField(x, y, width, height, path, ...)
	local iconField = GUI.table(x, y, width, height, 1, ...)

	-- First cell colors
	iconField.cell1Colors = {
		defaultBackground = nil,
		defaultText = 0x3C3C3C,
		alternativeBackground = 0xE1E1E1,
		alternativeText = 0x3C3C3C,
		selectionBackground = 0xCC2440,
		selectionText = 0xFFFFFF,
	}

	-- Other cells colors
	iconField.cell2Colors = {}
	for key, value in pairs(iconField.cell1Colors) do
		iconField.cell2Colors[key] = value
	end
	iconField.cell2Colors.defaultText, iconField.cell2Colors.alternativeText = 0xA5A5A5, 0xA5A5A5

	iconField:addColumn(localization.name, GUI.SIZE_POLICY_RELATIVE, 0.6)
	iconField:addColumn(localization.date, GUI.SIZE_POLICY_RELATIVE, 0.4)
	iconField:addColumn(localization.size, GUI.SIZE_POLICY_ABSOLUTE, 16)
	iconField:addColumn(localization.type, GUI.SIZE_POLICY_ABSOLUTE, 10)

	iconField.updateFileList = listIconFieldUpdateFileList

	anyIconFieldAddInfo(iconField, path)

	iconField.onCellTouch = function(workspace, cell, e1, e2, e3, e4, e5, ...)
		local index, columnCount = cell:indexOf() - 1, #cell.parent.columnSizes
		local icon = cell.parent.children[index - index % columnCount + 1]

		if e1 == "touch" then
			if e5 == 1 then
				local selectedIcons = {}
				for i = 1, #cell.parent.children - 1, columnCount do
					if cell.parent.children[i].selected then
						table.insert(selectedIcons, cell.parent.children[i])
					end
				end

				iconOnRightClick(selectedIcons, icon, e1, e2, e3, e4, e5, ...)
			end
		elseif e1 == "double_touch" then
			iconOnDoubleClick(icon)
		end
	end

	iconField.onBackgroundTouch = function(workspace, self, e1, e2, e3, e4, e5, ...)
		if e5 == 1 then
			iconFieldBackgroundClick(iconField, e1, e2, e3, e4, e5, ...)
		end
	end

	return iconField
end

--------------------------------------------------------------------------------

local function updateMenu()
	local topmostWindow = desktopWindowsContainer.children[#desktopWindowsContainer.children]
	desktopMenu.children = topmostWindow and topmostWindow.menu.children or system.menuInitialChildren
end

local function setWorkspaceHidden(state)
	local child
	for i = 1, #workspace.children do
		child = workspace.children[i]
		if child ~= desktopWindowsContainer and child ~= desktopMenu and child ~= desktopMenuLayout then
			child.hidden = state
		end
	end
end

local function windowMaximize(window, ...)
	window.movingEnabled = window.maximized
	
	if window.maximized then
		setWorkspaceHidden(false)
	else
		setWorkspaceHidden(not window.showDesktopOnMaximize)
	end

	GUI.windowMaximize(window, ...)
end

local function windowMinimize(...)
	setWorkspaceHidden(false)
	GUI.windowMinimize(...)
end

local function windowRemove(window)
	setWorkspaceHidden(false)

	if window.dockIcon then
		-- Удаляем ссылку на окно из докиконки
		window.dockIcon.windows[window] = nil
		window.dockIcon.windowCount = window.dockIcon.windowCount - 1

		-- Если в докиконке еще остались окна
		if window.dockIcon.windowCount < 1 then
			window.dockIcon.windows = nil
			window.dockIcon.windowCount = nil

			if not window.dockIcon.keepInDock then
				window.dockIcon:remove()
				dockContainer.sort()
			end
		end
	end

	-- Удаляем само окошко
	table.remove(window.parent.children, window:indexOf())
	updateMenu()
end

function system.addWindow(window, dontAddToDock, preserveCoordinates)
	-- Чекаем коорды
	if not preserveCoordinates then
		window.x, window.y =
			math.floor(desktopWindowsContainer.width / 2 - window.width / 2),
			math.floor(desktopWindowsContainer.height / 2 - window.height / 2)

		window.x, window.y = window.x > 0 and window.x or 1, window.y > 0 and window.y or 1
	end
	
	-- Ебурим окно к окнам
	GUI.focusedObject = window
	desktopWindowsContainer:addChild(window)
	
	if not dontAddToDock then
		-- Получаем путь залупы
		local info
		for i = 0, math.huge do
			info = debug.getinfo(i)
			if info then
				if info.source and info.what == "main" and info.source:sub(-13, -1) == ".app/Main.lua" then
					local dockPath = filesystem.removeSlashes(info.source:sub(2, -9))

					-- Чекаем наличие иконки в доке с таким же путем, и еси ее нет, то хуячим новую
					for i = 1, #dockContainer.children do
						if dockContainer.children[i].path == dockPath then
							window.dockIcon = dockContainer.children[i]
							break
						end
					end

					if not window.dockIcon then
						window.dockIcon = dockContainer.addIcon(dockPath)
					end
					
					-- Ебурим ссылку на окна в иконку
					window.dockIcon.windows = window.dockIcon.windows or {}
					window.dockIcon.windows[window] = true
					window.dockIcon.windowCount = (window.dockIcon.windowCount or 0) + 1

					-- Взалупливаем иконке индивидуальную менюху. По дефолту тут всякая хуйня и прочее
					window.menu = GUI.menu(1, 1, 1)
					window.menu.colors = desktopMenu.colors
					local name = filesystem.hideExtension(filesystem.name(dockPath))
					local contextMenu = window.menu:addContextMenuItem(name, 0x0)

					contextMenu:addItem(localization.closeWindow .. " " .. name, false, "^W").onTouch = function()
						window:remove()
					end

					-- Смещаем окно правее и ниже, если уже есть открытые окна этой софтины
					local lastIndex
					for i = #desktopWindowsContainer.children, 1, -1 do
						if desktopWindowsContainer.children[i] ~= window and window.dockIcon.windows[desktopWindowsContainer.children[i]] then
							lastIndex = i
							break
						end
					end

					if lastIndex then
						window.localX, window.localY = desktopWindowsContainer.children[lastIndex].localX + 4, desktopWindowsContainer.children[lastIndex].localY + 2
					end

					-- Когда окно фокусицца, то главная ОСевая менюха заполницца ДЕТИШЕЧКАМИ оконной менюхи
					window.onFocus = updateMenu

					-- Заполняем главную менюху текущим окном
					updateMenu()

					break
				end
			else
				break
			end
		end
	end

	-- "Закрытие" акошычка
	window.remove = windowRemove
	window.maximize = windowMaximize
	window.minimize = windowMinimize

	-- Кнопочкам тоже эту хуйню пихаем
	if window.actionButtons then
		window.actionButtons.close.onTouch = function()
			window:remove()
		end
		
		window.actionButtons.maximize.onTouch = function()
			window:maximize()
		end
		
		window.actionButtons.minimize.onTouch = function()
			window:minimize()
		end
	end

	return workspace, window, window.menu
end

--------------------------------------------------------------------------------

function system.addPropertiesWindow(x, y, width, icon)
	local workspace, window = system.addWindow(GUI.titledWindow(x, y, width, 1, localization.properties), true, true)

	window.backgroundPanel.colors.transparency = 0.2
	window:addChild(GUI.image(2, 3, icon.image))

	local x, y = 11, 3

	local function addKeyAndValue(key, value)
		local object = window:addChild(GUI.keyAndValue(x, y, 0x3C3C3C, 0x5A5A5A, key, ": " .. value))
		y = y + 1

		return object
	end

	addKeyAndValue(localization.type, icon.extension or (icon.isDirectory and localization.folder or localization.unknown))
	local sizeKeyAndValue = addKeyAndValue(localization.size, icon.isDirectory and "-" or string.format("%.2f", filesystem.size(icon.path) / 1024) .. " KB")
	addKeyAndValue(localization.date, os.date("%d.%m.%y, %H:%M", math.floor(filesystem.lastModified(icon.path) / 1000)))
	addKeyAndValue(localization.path, " ")

	local textBox = window:addChild(GUI.textBox(17, y - 1, window.width - 18, 1, nil, 0x555555, {icon.path}, 1, 0, 0, true, true))
	textBox.eventHandler = nil

	window.actionButtons.minimize:remove()
	window.actionButtons.maximize:remove()

	window.height = textBox.y + textBox.height
	window.backgroundPanel.width = window.width
	window.backgroundPanel.height = textBox.y + textBox.height

	workspace:draw()
end

-----------------------------------------------------------------------------------------------------------------------------------

function system.copy(fileList, toPath)
	local applyYes, breakRecursion

	local container = GUI.addBackgroundContainer(workspace, true, true, localization.copying)
	local textBox = container.layout:addChild(GUI.textBox(1, 1, container.width, 1, nil, 0x878787, {}, 1, 0, 0, true, true):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
	local switchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 37, 8, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0x878787, localization.applyToAll .. ":", false))
	container.panel.eventHandler = nil

	local buttonsLayout = container.layout:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	buttonsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	buttonsLayout:setSpacing(1, 1, 2)

	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, localization.yes)).onTouch = function()
		applyYes = true
		workspace:stop()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, localization.no)).onTouch = function()
		workspace:stop()
	end
	buttonsLayout:addChild(GUI.button(1, 1, 11, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, localization.cancel)).onTouch = function()
		breakRecursion = true
		workspace:stop()
	end

	buttonsLayout:fitToChildrenSize(1, 1)

	local function copyOrMove(path, finalPath)
		switchAndLabel.hidden = true
		buttonsLayout.hidden = true

		textBox.lines = {
			localization.copying .. " " .. localization.faylaBlyad .. " " .. filesystem.name(path) .. " " .. localization.toDirectory .. " " .. filesystem.removeSlashes(toPath),
		}
		textBox:update()

		workspace:draw()

		filesystem.remove(finalPath)

		filesystem.copy(path, finalPath)
	end

	local function recursiveCopy(path, toPath)
		local finalPath = toPath .. "/" .. filesystem.name(path)

		if filesystem.isDirectory(path) then
			filesystem.makeDirectory(finalPath)

			local list = filesystem.list(path)
			for i = 1, #list do
				if breakRecursion then
					return
				end
				recursiveCopy(path .. "/" .. list[i], finalPath)
			end
		else
			if filesystem.exists(finalPath) then
				if not switchAndLabel.switch.state then
					switchAndLabel.hidden = false
					buttonsLayout.hidden = false
					applyYes = false

					textBox.lines = {
						localization.file .. " " .. filesystem.name(path) .. " " .. localization.alreadyExists .. " " ..  localization.inDirectory .. " " .. filesystem.removeSlashes(toPath),
						localization.needReplace,
					}
					textBox:update()

					workspace:draw()
					workspace:start()
					workspace:draw()
				end

				if applyYes then
					copyOrMove(path, finalPath)
				end
			else
				copyOrMove(path, finalPath)
			end
		end
	end

	for i = 1, #fileList do
		recursiveCopy(fileList[i], toPath)
	end

	container:remove()
	workspace:draw()
end

local function menuWidgetEventHandler(workspace, object, e1, ...)
	if e1 == "touch" and object.onTouch then
		object.selected = true
		workspace:draw()

		object.onTouch(workspace, object, e1, ...)

		object.selected = false
		workspace:draw()
	end
end

local function menuWidgetDraw(object)
	if object.selected then
		object.textColor = 0xFFFFFF
		screen.drawRectangle(object.x - 1, object.y, object.width + 2, 1, 0x3366CC, object.textColor, " ")
	else
		object.textColor = 0x0
	end

	object.drawContent(object)
end

function system.menuWidget(width)
	local object = GUI.object(1, 1, width, 1)
	
	object.selected = false
	object.eventHandler = menuWidgetEventHandler
	object.draw = menuWidgetDraw

	return object
end

function system.addMenuWidget(object)
	desktopMenuLayout:addChild(object)
	object:moveToBack()

	return object
end

--------------------------------------------------------------------------------

function system.error(path, line, traceback)
	local container = GUI.addBackgroundContainer(workspace, true, false, false)

	local window = container:addChild(GUI.container(1, 1, screen.getWidth(), math.floor(container.height * 0.5)))
	window.localY = math.floor(container.height / 2 - window.height / 2)

	window:addChild(GUI.panel(1, 1, window.width, 3, 0x3C3C3C))
	window:addChild(GUI.label(1, 2, window.width, 1, 0xE1E1E1, localization.errorWhileRunningProgram .. "\"" .. filesystem.name(path) .. "\"")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	local actionButtons = window:addChild(GUI.actionButtons(2, 2, true))
	local sendToDeveloperButton = window:addChild(GUI.adaptiveButton(9, 1, 2, 1, 0x4B4B4B, 0xD2D2D2, 0x2D2D2D, 0xFFFFFF, localization.sendFeedback))
	
	local codeView = window:addChild(GUI.codeView(1, 4, math.floor(window.width * 0.62), window.height - 3, 1, 1, 100, {}, {[line] = 0xFF4444}, GUI.LUA_SYNTAX_PATTERNS, GUI.LUA_SYNTAX_COLOR_SCHEME, true, {}))
	
	-- Obtain from- and to- lines that need to be shown
	codeView.fromLine = line - math.floor((window.height - 3) / 2) + 1
	if codeView.fromLine <= 0 then
		codeView.fromLine = 1
	end
	local toLine, lineCounter = codeView.fromLine + codeView.height - 1, 1

	-- Read part of file to display error line
	for line in filesystem.lines(path) do
		if lineCounter >= codeView.fromLine and lineCounter <= toLine then
			codeView.lines[lineCounter] = line:gsub("\t", "  ")
		elseif lineCounter < codeView.fromLine then
			codeView.lines[lineCounter] = " "
		elseif lineCounter > toLine then
			break
		end
		
		lineCounter = lineCounter + 1
		
		if lineCounter % 200 == 0 then
			computer.pullSignal(0)
		end
	end

	-- Stacktrace parsing
	local lines = text.wrap(traceback:gsub("\r\n", "\n"):gsub("\t", "  "), window.width - codeView.width - 2)
	window:addChild(GUI.textBox(codeView.width + 1, 4, window.width - codeView.width, codeView.height, 0xFFFFFF, 0x0, lines, 1, 1, 0))
	
	actionButtons.close.onTouch = function()
		container:remove()
		workspace:draw()
	end

	window.eventHandler = function(workspace, object, e1, e2, e3, e4)
		if e1 == "key_down" and e4 == 28 then
			actionButtons.close.onTouch()
		end
	end

	sendToDeveloperButton.onTouch = function()
		if component.isAvailable("internet") then
			local internet = require("Internet")
			internet.request("https://api.mcmodder.ru/ECS/report.php?path=" .. internet.encode(path) .. "&errorMessage=" .. internet.encode(traceback))

			sendToDeveloperButton.text = localization.sendedFeedback
			workspace:draw()
			event.sleep(1)
		end

		actionButtons.close.onTouch()
	end

	workspace:draw()

	for i = 1, 3 do
		component.get("computer").beep(1500, 0.08)
	end
end

function system.execute(path, ...)
	path = filesystem.removeSlashes(path)

	local oldScreenWidth, oldScreenHeight, success, errorPath, line, traceback = screen.getResolution()
	
	if filesystem.exists(path) then
		success, reason = loadfile(path)

		if success then
			success, errorPath, line, traceback = system.call(success, ...)
		else
			success, errorPath, line, traceback = false, path, tonumber(reason:match(":(%d+)%:")) or 1, reason
		end
	else
		GUI.alert("File \"" .. tostring(path) .. "\" doesn't exists")
	end

	component.proxy(screen.getGPUProxy().getScreen()).setPrecise(false)
	screen.setResolution(oldScreenWidth, oldScreenHeight)

	if not success then
		system.error(errorPath, line, traceback)
	end

	return success, errorPath, line, traceback
end

local function desktopBackgroundAmbientDraw()
	screen.drawRectangle(1, desktopBackground.y, desktopBackground.width, desktopBackground.height, desktopBackgroundColor, 0, " ")
end

function system.updateWallpaper()
	desktopBackground.draw = desktopBackgroundAmbientDraw

	if userSettings.interfaceWallpaperEnabled and userSettings.interfaceWallpaperPath then
		local extension = filesystem.extension(userSettings.interfaceWallpaperPath)
		if extension == ".pic" then
			local result, reason = image.load(userSettings.interfaceWallpaperPath)
			if result then
				-- Fit to screen size mode
				if userSettings.interfaceWallpaperMode == 1 then
					result = image.transform(result, desktopBackground.width, desktopBackground.height)
					desktopBackgroundWallpaperX, desktopBackgroundWallpaperY = 1, 2
				-- Centerized mode
				else
					desktopBackgroundWallpaperX = math.floor(1 + desktopBackground.width / 2 - image.getWidth(result) / 2)
					desktopBackgroundWallpaperY = math.floor(2 + desktopBackground.height / 2 - image.getHeight(result) / 2)
				end

				-- Brightness adjustment
				local brightness, background, foreground, alpha, symbol, r, g, b = userSettings.interfaceWallpaperBrightness
				for y = 1, image.getHeight(result) do
					for x = 1, image.getWidth(result) do
						background, foreground, alpha, symbol = image.get(result, x, y)
						
						r, g, b = color.integerToRGB(background)
						background = color.RGBToInteger(
							math.floor(r * brightness),
							math.floor(g * brightness),
							math.floor(b * brightness)
						)

						r, g, b = color.integerToRGB(foreground)
						foreground = color.RGBToInteger(
							math.floor(r * brightness),
							math.floor(g * brightness),
							math.floor(b * brightness)
						)

						image.set(result, x, y, background, foreground, alpha, symbol)
					end
				end

				desktopBackground.draw = function(...)
					desktopBackgroundAmbientDraw(...)
					screen.drawImage(desktopBackgroundWallpaperX, desktopBackgroundWallpaperY, result)
				end
			else
				GUI.alert(reason or "image file is corrupted")
			end
		elseif extension == ".lua" then
			local result, reason = loadfile(userSettings.interfaceWallpaperPath)

			if result then
				result, functionOrReason = xpcall(result, debug.traceback)
				if result then
					if type(functionOrReason) == "function" then
						desktopBackground.draw = functionOrReason
					else
						GUI.alert("Wallpaper script didn't return drawing function")
					end
				else
					GUI.alert(functionOrReason)
				end
			else
				GUI.alert(reason)
			end
		end
	end
end

function system.updateResolution()
	if userSettings.interfaceScreenWidth then
		screen.setResolution(userSettings.interfaceScreenWidth, userSettings.interfaceScreenHeight)
	else
		screen.setResolution(screen.getGPUProxy().maxResolution())
	end

	workspace.width, workspace.height = screen.getResolution()

	desktopIconField.width = workspace.width
	desktopIconField.height = workspace.height
	desktopIconField:updateFileList()

	desktopMenu.width = workspace.width
	desktopMenuLayout.width = workspace.width
	desktopBackground.localY, desktopBackground.width, desktopBackground.height = 2, workspace.width, workspace.height - 1

	desktopWindowsContainer.width, desktopWindowsContainer.height = workspace.width, workspace.height - 1

	dockContainer.sort()
	dockContainer.localY = workspace.height - dockContainer.height + 1
end

local function moveDockIcon(index, direction)
	dockContainer.children[index], dockContainer.children[index + direction] = dockContainer.children[index + direction], dockContainer.children[index]
	dockContainer.sort()
	dockContainer.saveUserSettings()
	workspace:draw()
end

local function getPercentageColor(pecent)
	if pecent >= 0.75 then
		return 0x00B640
	elseif pecent >= 0.6 then
		return 0x99DB40
	elseif pecent >= 0.3 then
		return 0xFFB640
	elseif pecent >= 0.2 then
		return 0xFF9240
	else
		return 0xFF4940
	end
end

local function dockIconEventHandler(workspace, icon, e1, e2, e3, e4, e5, e6, ...)
	if e1 == "touch" then
		icon.selected = true
		workspace:draw()

		if e5 == 0 then
			icon.onLeftClick(icon, e1, e2, e3, e4, e5, e6, ...)
		else
			icon.onRightClick(icon, e1, e2, e3, e4, e5, e6, ...)
		end
	end
end

function system.updateDesktop()
	desktopIconField = workspace:addChild(
		system.gridIconField(
			1, 2, 1, 1, 3, 2,
			paths.user.desktop,
			0xFFFFFF,
			0xD2D2D2,
			0xFFFFFF,
			0xD2D2D2,
			0.5
		)
	)
	
	desktopIconField.iconConfigEnabled = true
	
	desktopIconField.launchers.directory = function(icon)
		system.execute(paths.system.applicationFinder, "-o", icon.path)
	end
	
	desktopIconField.launchers.showContainingFolder = function(icon)
		system.execute(paths.system.applicationFinder, "-o", filesystem.path(icon.shortcutPath or icon.path))
	end
	
	desktopIconField.launchers.showPackageContent = function(icon)
		system.execute(paths.system.applicationFinder, "-o", icon.path)
	end

	dockContainer = workspace:addChild(GUI.container(1, 1, workspace.width, 7))

	dockContainer.saveUserSettings = function()
		userSettings.dockShortcuts = {}
		for i = 1, #dockContainer.children do
			if dockContainer.children[i].keepInDock then
				table.insert(userSettings.dockShortcuts, dockContainer.children[i].path)
			end
		end

		system.saveUserSettings()
	end

	dockContainer.sort = function()
		local x = 4
		for i = 1, #dockContainer.children do
			dockContainer.children[i].localX = x
			x = x + userSettings.iconWidth + userSettings.iconHorizontalSpace
		end

		dockContainer.width = #dockContainer.children * (userSettings.iconWidth + userSettings.iconHorizontalSpace) - userSettings.iconHorizontalSpace + 6
		dockContainer.localX = math.floor(workspace.width / 2 - dockContainer.width / 2)
	end

	dockContainer.updateIcons = function()
		for i = 1, #dockContainer.children - 1 do
			dockContainer.children[i]:analyseExtension(iconLaunchers)
		end
	end

	local dockColors = {
		selectionBackground = 0xD2D2D2,
		selectionText = 0x2D2D2D,
		defaultText = 0x2D2D2D,
		selectionTransparency = 0.5
	}

	dockContainer.addIcon = function(path)
		local icon = dockContainer:addChild(system.gridIcon(1, 2, path, dockColors))
		icon:analyseExtension(iconLaunchers)
		icon:moveBackward()

		icon.eventHandler = dockIconEventHandler

		icon.onLeftClick = function(icon, ...)
			if icon.windows then
				local topmostWindow

				-- Unhide all windows
				for w in pairs(icon.windows) do
					topmostWindow = w
					topmostWindow.hidden = false
				end

				topmostWindow:focus()

				updateMenu()
				event.sleep(0.2)
			else
				icon:launch()
			end

			icon.selected = false
			workspace:draw()
		end

		icon.onRightClick = function(icon, e1, e2, e3, e4, ...)
			local indexOf = icon:indexOf()
			local contextMenu = GUI.addContextMenu(workspace, e3, e4)
			
			contextMenu.onMenuClosed = function()
				icon.selected = false
				workspace:draw()
			end

			if icon.windows then
				local eventData = {...}
				
				contextMenu:addItem(localization.newWindow).onTouch = function()
					iconOnDoubleClick(icon, e1, e2, e3, e4, table.unpack(eventData))
				end
				
				contextMenu:addItem(localization.closeAllWindows).onTouch = function()
					for window in pairs(icon.windows) do
						window:remove()
					end

					workspace:draw()
				end
			end
			
			contextMenu:addItem(localization.showContainingFolder).onTouch = function()
				system.execute(paths.system.applicationFinder, "-o", filesystem.path(icon.shortcutPath or icon.path))
			end
			
			contextMenu:addSeparator()
			
			contextMenu:addItem(localization.moveRight, indexOf >= #dockContainer.children - 1).onTouch = function()
				moveDockIcon(indexOf, 1)
			end
			
			contextMenu:addItem(localization.moveLeft, indexOf <= 1).onTouch = function()
				moveDockIcon(indexOf, -1)
			end
			
			contextMenu:addSeparator()
			
			if icon.keepInDock then
				if #dockContainer.children > 1 then
					contextMenu:addItem(localization.removeFromDock).onTouch = function()
						if icon.windows then
							icon.keepInDock = nil
						else
							icon:remove()
							dockContainer.sort()
						end
						
						workspace:draw()
						dockContainer.saveUserSettings()
					end
				end
			else
				if icon.windows then
					contextMenu:addItem(localization.keepInDock).onTouch = function()
						icon.keepInDock = true
						dockContainer.saveUserSettings()
					end
				end
			end

			workspace:draw()
		end

		dockContainer.sort()

		return icon
	end

	-- Trash
	local icon = dockContainer.addIcon(paths.user.trash)
	icon.image = image.load(paths.system.icons .. "Trash.pic")
	icon.launch = function()
		system.execute(paths.system.applicationFinder, "-o", icon.path)
	end

	icon.eventHandler = dockIconEventHandler

	icon.onLeftClick = function(...)
		icon:launch()
		
		icon.selected = false
		workspace:draw()
	end

	icon.onRightClick = function(icon, e1, e2, e3, e4)
		local contextMenu = GUI.addContextMenu(workspace, e3, e4)
		
		contextMenu.onMenuClosed = function()
			icon.selected = false
			workspace:draw()
		end
		
		contextMenu:addItem(localization.emptyTrash).onTouch = function()
			local container = GUI.addBackgroundContainer(workspace, true, true, localization.areYouSure)

			container.layout:addChild(GUI.button(1, 1, 30, 1, 0xE1E1E1, 0x2D2D2D, 0xA5A5A5, 0x2D2D2D, "OK")).onTouch = function()
				local list = filesystem.list(paths.user.trash)
				for i = 1, #list do
					filesystem.remove(paths.user.trash .. list[i])
				end
				container:remove()
				computer.pushSignal("system", "updateFileList")
			end

			container.panel.onTouch = function()
				container:remove()
				workspace:draw()
			end

			workspace:draw()
		end

		workspace:draw()
	end

	for i = 1, #userSettings.dockShortcuts do
		dockContainer.addIcon(userSettings.dockShortcuts[i]).keepInDock = true
	end

	-- Draw dock drawDock dockDraw cyka заебался искать, блядь
	local overrideDockContainerDraw = dockContainer.draw
	dockContainer.draw = function(dockContainer)
		local color, currentDockTransparency, currentDockWidth, xPos = userSettings.interfaceColorDock, userSettings.interfaceTransparencyDock, dockContainer.width - 2, dockContainer.x

		for y = dockContainer.y + dockContainer.height - 1, dockContainer.y + dockContainer.height - 4, -1 do
			screen.drawText(xPos, y, color, "◢", userSettings.interfaceTransparencyEnabled and currentDockTransparency)
			screen.drawRectangle(xPos + 1, y, currentDockWidth, 1, color, 0xFFFFFF, " ", userSettings.interfaceTransparencyEnabled and currentDockTransparency)
			screen.drawText(xPos + currentDockWidth + 1, y, color, "◣", userSettings.interfaceTransparencyEnabled and currentDockTransparency)

			currentDockTransparency, currentDockWidth, xPos = currentDockTransparency + 0.08, currentDockWidth - 2, xPos + 1
			if currentDockTransparency > 1 then
				currentDockTransparency = 1
			end
		end

		overrideDockContainerDraw(dockContainer)
	end

	desktopWindowsContainer = workspace:addChild(GUI.container(1, 2, 1, 1))

	desktopMenu = workspace:addChild(GUI.menu(1, 1, workspace.width, 0x0, 0x696969, 0x3366CC, 0xFFFFFF))
	
	local MineOSContextMenu = desktopMenu:addContextMenuItem("MineOS", 0x000000)
	MineOSContextMenu:addItem(localization.aboutSystem).onTouch = function()
		local container = GUI.addBackgroundContainer(workspace, true, true, localization.aboutSystem)
		container.layout:removeChildren()
		
		local lines = {
			"MineOS",
			"Copyright © 2014-" .. os.date("%Y", system.getTime()),
			" ",
			"Developers:",
			" ",
			"Igor Timofeev, vk.com/id7799889",
			"Gleb Trifonov, vk.com/id88323331",
			"Yakov Verevkin, vk.com/id60991376",
			"Alexey Smirnov, vk.com/id23897419",
			"Timofey Shestakov, vk.com/id113499693",
			" ",
			"UX-advisers:",
			" ",
			"Nikita Yarichev, vk.com/id65873873",
			"Vyacheslav Sazonov, vk.com/id21321257",
			"Michail Prosin, vk.com/id75667079",
			"Dmitrii Tiunov, vk.com/id151541414",
			"Egor Paliev, vk.com/id83795932",
			"Maxim Pakin, vk.com/id100687922",
			"Andrey Kakoito, vk.com/id201043162",
			"Maxim Omelaenko, vk.com/id54662296",
			"Konstantin Mayakovskiy, vk.com/id10069748",
			"Ruslan Isaev, vk.com/id181265169",
			"Eugene8388608, vk.com/id287247631",
			" ",
			"Translators:",
			" ",
			"06Games, github.com/06Games",
			"Xenia Mazneva, vk.com/id5564402",
			"Yana Dmitrieva, vk.com/id155326634",
		}

		local textBox = container.layout:addChild(GUI.textBox(1, 1, container.layout.width, #lines, nil, 0xB4B4B4, lines, 1, 0, 0))
		textBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
		textBox.eventHandler = container.panel.eventHandler

		workspace:draw()
	end

	MineOSContextMenu:addItem(localization.updates).onTouch = function()
		system.execute(paths.system.applicationAppMarket, "updates")
	end

	MineOSContextMenu:addSeparator()

	MineOSContextMenu:addItem(localization.logout).onTouch = function()
		system.authorize()
	end

	MineOSContextMenu:addItem(localization.reboot).onTouch = function()
		require("Network").broadcastComputerState(false)
		computer.shutdown(true)
	end

	MineOSContextMenu:addItem(localization.shutdown).onTouch = function()
		require("Network").broadcastComputerState(false)
		computer.shutdown()
	end
		
	desktopMenuLayout = workspace:addChild(GUI.layout(1, 1, 1, 1, 1, 1))
	desktopMenuLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	desktopMenuLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_TOP)
	desktopMenuLayout:setMargin(1, 1, 1, 0)
	desktopMenuLayout:setSpacing(1, 1, 2)

	local dateWidget, dateWidgetText = system.addMenuWidget(system.menuWidget(1))
	dateWidget.drawContent = function()
		screen.drawText(dateWidget.x, 1, dateWidget.textColor, dateWidgetText)
	end

	local batteryWidget, batteryWidgetPercent, batteryWidgetText = system.addMenuWidget(system.menuWidget(1))
	batteryWidget.drawContent = function()
		screen.drawText(batteryWidget.x, 1, batteryWidget.textColor, batteryWidgetText)

		local pixelPercent = math.floor(batteryWidgetPercent * 4 + 0.5)
		if pixelPercent == 0 then
			pixelPercent = 1
		end
		
		local index = screen.getIndex(batteryWidget.x + #batteryWidgetText, 1)
		for i = 1, 4 do
			screen.rawSet(index, screen.rawGet(index), i <= pixelPercent and getPercentageColor(batteryWidgetPercent) or 0xD2D2D2, i < 4 and "⠶" or "╸")
			index = index + 1
		end
	end

	local RAMWidget, RAMPercent = system.addMenuWidget(system.menuWidget(16))
	RAMWidget.drawContent = function()
		local text = "RAM: " .. math.ceil(RAMPercent * 100) .. "% "
		local barWidth = RAMWidget.width - #text
		local activeWidth = math.ceil(RAMPercent * barWidth)

		screen.drawText(RAMWidget.x, 1, RAMWidget.textColor, text)
		
		local index = screen.getIndex(RAMWidget.x + #text, 1)
		for i = 1, barWidth do
			screen.rawSet(index, screen.rawGet(index), i <= activeWidth and getPercentageColor(1 - RAMPercent) or 0xD2D2D2, "━")
			index = index + 1
		end
	end

	function system.updateMenuWidgets()
		dateWidgetText = os.date(userSettings.timeFormat, userSettings.timeRealTimestamp and system.getTime() or nil)
		dateWidget.width = unicode.len(dateWidgetText)

		batteryWidgetPercent = computer.energy() / computer.maxEnergy()
		if batteryWidgetPercent == math.huge then
			batteryWidgetPercent = 1
		end
		batteryWidgetText = math.ceil(batteryWidgetPercent * 100) .. "% "
		batteryWidget.width = #batteryWidgetText + 4

		local totalMemory = computer.totalMemory()
		RAMPercent = (totalMemory - computer.freeMemory()) / totalMemory
	end

	local lastWindowHandled
	workspace.eventHandler = function(workspace, object, e1, e2, e3, e4)
		if e1 == "key_down" then
			local windowCount = #desktopWindowsContainer.children
			-- Ctrl or CMD
			if windowCount > 0 and not lastWindowHandled and (keyboard.isKeyDown(29) or keyboard.isKeyDown(219)) then
				-- W
				if e4 == 17 then
					desktopWindowsContainer.children[windowCount]:remove()
					lastWindowHandled = true

					workspace:draw()
				end
			end
		elseif lastWindowHandled and e1 == "key_up" and (e4 == 17 or e4 == 35) then
			lastWindowHandled = false
		elseif e1 == "system" then
			if e2 == "updateFileList" then
				desktopIconField:updateFileList()
				dockContainer.sort()
				dockContainer.updateIcons()
				workspace:draw()
			end
		elseif e1 == "network" then
			if e2 == "accessDenied" then
				GUI.alert(localization.networkAccessDenied)
			elseif e2 == "timeout" then
				GUI.alert(localization.networkTimeout)
			end
		end

		if computer.uptime() - dateUptime >= 1 then
			system.updateMenuWidgets()
			workspace:draw()

			dateUptime = computer.uptime()
		end

		if userSettings.interfaceScreensaverEnabled then
			if e1 then
				screensaverUptime = computer.uptime()
			end

			if dateUptime - screensaverUptime >= userSettings.interfaceScreensaverDelay then
				if filesystem.exists(userSettings.interfaceScreensaverPath) then
					system.execute(userSettings.interfaceScreensaverPath)
					workspace:draw(true)
				end

				screensaverUptime = computer.uptime()
			end
		end
	end

	system.menuInitialChildren = desktopMenu.children
	system.consoleWindow = nil

	system.updateColorScheme()
	system.updateResolution()
	system.updateWallpaper()
	system.updateMenuWidgets()
end

function system.updateColorScheme()
	-- Drop down menus
	GUI.CONTEXT_MENU_BACKGROUND_TRANSPARENCY = userSettings.interfaceTransparencyEnabled and 0.18
	GUI.CONTEXT_MENU_SHADOW_TRANSPARENCY = userSettings.interfaceTransparencyEnabled and 0.4
	GUI.CONTEXT_MENU_SEPARATOR_COLOR = userSettings.interfaceColorDropDownMenuSeparator
	GUI.CONTEXT_MENU_DEFAULT_BACKGROUND_COLOR = userSettings.interfaceColorDropDownMenuDefaultBackground
	GUI.CONTEXT_MENU_DEFAULT_TEXT_COLOR = userSettings.interfaceColorDropDownMenuDefaultText

	-- Windows
	GUI.WINDOW_SHADOW_TRANSPARENCY = userSettings.interfaceTransparencyEnabled and 0.6
	-- Background containers
	GUI.BACKGROUND_CONTAINER_PANEL_COLOR = userSettings.interfaceTransparencyEnabled and 0x0 or userSettings.interfaceColorDesktopBackground
	GUI.BACKGROUND_CONTAINER_PANEL_TRANSPARENCY = userSettings.interfaceTransparencyEnabled and 0.3
	-- Top menu
	desktopMenu.colors.default.background = userSettings.interfaceColorMenu
	-- Desktop background
	desktopBackgroundColor = userSettings.interfaceColorDesktopBackground
end

--------------------------------------------------------------------------------

-- Runs tasks before/after OS UI initialization
local function runTasks(mode)
	for i = 1, #userSettings.tasks do
		local task = userSettings.tasks[i]
		if task.mode == mode and task.enabled then
			system.execute(task.path)
		end
	end
end

function system.setUser(u)
	user = u

	-- Updating paths
	paths.updateUser(u)

	-- Updating current desktop iconField path to new one
	if desktopIconField then
		desktopIconField.path = paths.user.desktop
	end
end

local function updateUser(u)
	system.setUser(u)
	-- Loading localization
	localization = system.getLocalization(paths.system.localizations)
	-- Tasks before UI initialization
	runTasks(2)
	-- Recalculating icon internal sizes based on user userSettings
	system.calculateIconProperties()
	-- Creating desktop widgets
	system.updateDesktop()
	-- Meowing
	workspace:draw()
	require("Network").update()
	
	-- Tasks after UI initialization
	runTasks(1)
end

local function userObjectDraw(userObject)
	local center = userObject.x + userObject.width / 2
	local imageWidth = image.getWidth(userObject.icon)
	local imageX = math.floor(center - imageWidth / 2)
	
	if userObject.selected then
		drawSelection(imageX - 1, userObject.y - 1, imageWidth + 2, image.getHeight(userObject.icon) + 2, 0xFFFFFF, 0.5)
	end

	screen.drawImage(imageX, userObject.y, userObject.icon)
	screen.drawText(math.floor(center - unicode.len(userObject.name) / 2), userObject.y + image.getHeight(userObject.icon) + 1, 0xE1E1E1, userObject.name)
end

local function userObjectEventHandler(workspace, userObject, e1)
	if e1 == "touch" then
		userObject.selected = true
		workspace:draw()
		
		event.sleep(0.2)

		userObject.selected = false
		userObject.onTouch()
	end
end

local function newUserObject(name, addEventHandler)
	local userObject = GUI.object(1, 1, math.max(8, unicode.len(name)), 6)

	userObject.name = name

	local iconPath = paths.system.users .. name .. "/Icon.pic"
	userObject.icon = image.load(filesystem.exists(iconPath) and iconPath or paths.system.icons .. "User.pic")

	userObject.draw = userObjectDraw
	userObject.eventHandler = addEventHandler and userObjectEventHandler

	return userObject
end

function system.updateWorkspace()
	-- Clearing workspace
	workspace:removeChildren()

	-- Creating desktop background object
	local oldDraw = desktopBackground and desktopBackground.draw
	desktopBackground = workspace:addChild(GUI.object(1, 1, workspace.width, workspace.height))
	desktopBackground.draw = oldDraw or desktopBackgroundAmbientDraw
end

function system.createUser(name, language, password, wallpaper, screensaver)
	-- Generating default user userSettings
	local defaultSettings = system.getDefaultUserSettings()	
	
	-- Injecting preferred fields
	defaultSettings.localizationLanguage = language
	defaultSettings.securityPassword = password and require("SHA-256").hash(password)
	defaultSettings.interfaceWallpaperEnabled = wallpaper
	defaultSettings.interfaceScreensaverEnabled = screensaver

	-- Generating user home directory tree
	local userPaths = paths.getUser(name)
	paths.create(userPaths)

	-- Creating basic user icon
	filesystem.copy(paths.system.icons .. "User.pic", userPaths.home .. "Icon.pic")
	
	-- Saving user userSettings
	filesystem.writeTable(userPaths.settings, defaultSettings, true)

	return defaultSettings, userPaths
end

function system.setWorkspace(w)
	workspace = w
end

function system.getWorkspace()
	return workspace
end

function system.authorize()
	system.updateWorkspace()

	-- Obtaining user list and removing non-directory files from it
	local userList = filesystem.list(paths.system.users)
	local i = 1
	while i <= #userList do
		if userList[i]:sub(-1) == "/" then
			i = i + 1
		else
			table.remove(userList, i)
		end
	end

	local function loadUserSettingsAndCheckProtection(userName)
		paths.updateUser(userName)

		if filesystem.exists(paths.user.settings) then
			userSettings = filesystem.readTable(paths.user.settings)

			for key, value in pairs(system.getDefaultUserSettings()) do
				if userSettings[key] == nil then
					userSettings[key] = value
				end
			end
		else
			userSettings = system.getDefaultUserSettings()
		end

		return userSettings.securityPassword
	end

	-- Creating login UI only if there's more than one user with protection
	if #userList > 1 or loadUserSettingsAndCheckProtection(userList[1]) then
		local container = workspace:addChild(GUI.container(1, 1, workspace.width, workspace.height))

		-- If we've loaded wallpaper (from user logout or above) then add a panel to make it darker
		if desktopBackground.draw ~= desktopBackgroundAmbientDraw then
			container:addChild(GUI.panel(1, 1, container.width, container.height, 0x0, 0.5))
		end

		local function addLayout(y, height, spacing)
			local layout = container:addChild(GUI.layout(1, y, container.width, height, 1, 1))
			
			layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
			layout:setSpacing(1, 1, spacing)

			return layout
		end

		local buttonsLayout = addLayout(container.height - 2, 1, 4)

		local function addButton(text, onTouch)
			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0x4B4B4B, 0xE1E1E1, 0x787878, 0xE1E1E1, text)).onTouch = onTouch
		end

		addButton("Reboot", function()
			computer.shutdown(true)
		end)

		addButton("Shutdown", function()
			computer.shutdown()
		end)

		local function selectUser()
			local function securityCheck(userName)
				local passwordLayout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))
				
				passwordLayout:addChild(newUserObject(userName))
				
				local passwordContainer = passwordLayout:addChild(GUI.container(1, 1, 36, 3))
				local input = addBackgroundContainerInput(passwordContainer, "", "Password", false, "•")

				-- Adding "select user again" button only if there's more than 1 user
				if #userList > 1 then
					local backButton = passwordContainer:addChild(GUI.button(1, 1, 5, 3, 0x2D2D2D, 0xE1E1E1, 0x4B4B4B, 0xE1E1E1, "<"))
					input.localX = backButton.width + 1
					input.width = input.width - backButton.width

					backButton.onTouch = function()
						passwordLayout:remove()
						selectUser()
					end
				end

				input.onInputFinished = function()
					if #input.text > 0 then
						local hash = require("SHA-256").hash(input.text)
						
						package.loaded["SHA-256"] = nil
						input.text = ""

						if hash == userSettings.securityPassword then
							container:remove()
							updateUser(userName)
						else
							GUI.alert("Incorrect password")
						end
					end
				end

				workspace:draw()
			end

			if #userList > 1 then
				local usersLayout = addLayout(1, container.height, 4)
				
				for i = 1, #userList do
					local userObject = usersLayout:addChild(newUserObject(userList[i]:sub(1, -2), true))
					userObject.onTouch = function()
						usersLayout:remove()

						-- Again, if there's some protection
						if loadUserSettingsAndCheckProtection(userObject.name) then
							securityCheck(userObject.name)
						else
							container:remove()
							updateUser(userObject.name)
						end
					end
				end
			else
				securityCheck(userList[1]:sub(1, -2))
			end
		end

		selectUser()
	else
		updateUser(userList[1]:sub(1, -2))
	end

	workspace:draw()
end

function system.getWindowsContainer()
	return desktopWindowsContainer
end

function system.getDockContainer()
	return dockContainer
end

function system.addBlurredOrDefaultPanel(container, x, y, width, height)
	return container:addChild(userSettings.interfaceBlurEnabled and GUI.blurredPanel(x, y, width, height, userSettings.interfaceBlurRadius, 0x0, userSettings.interfaceBlurTransparency) or GUI.panel(x, y, width, height, 0x2D2D2D))
end

--------------------------------------------------------------------------------

-- Keeping temporary file's last modified timestamp as boot timestamp
do
	local proxy, path = component.proxy(computer.tmpAddress()), "timestamp"
	
	proxy.close(proxy.open(path, "wb"))
	bootRealTime = math.floor(proxy.lastModified(path) / 1000)
	proxy.remove(path)
end

-- Global print() function for debugging
_G.print = function(...)
	if not system.consoleWindow then
		local result, data = loadfile(paths.system.applicationConsole)
			
		if result then
			result, data = xpcall(result, debug.traceback)
			
			if not result then
				GUI.alert(data)
				return
			end
		else
			GUI.alert(data)
			return
		end
	end

	local args, arg = {...}

	for i = 1, #args do
		arg = args[i]

		if type(arg) == "table" then
			arg = text.serialize(arg, true, "  ", 3)
		else
			arg = tostring(arg)
		end

		args[i] = arg
	end

	args = table.concat(args, " ")
	
	system.consoleWindow.addLine(args)
	system.consoleWindow:focus()
end

--------------------------------------------------------------------------------

return system
