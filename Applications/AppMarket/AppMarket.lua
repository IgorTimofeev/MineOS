
-- package.loaded.GUI = nil
-- _G.GUI = nil

local libraries = {
	buffer = "doubleBuffering",
	MineOSCore = "MineOSCore",
	image = "image",
	GUI = "GUI",
	fs = "filesystem",
	component = "component",
	unicode = "unicode",
	files = "files",
	ecs = "ECSAPI",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil

------------------------------------------------------------------------------------------------------------------

local obj = {}
local sizes = {}
local colors = {
	main = 0xFFFFFF,
	topBar = 0xDDDDDD,
	topBarText = 0x555555,
	topBarElement = 0xCCCCCC,
	topBarElementText = 0x555555,
	statusBar = 0xDDDDDD,
	statusBarText = 0x888888,
	appName = 0x262626,
	version = 0x555555,
	description = 0x888888,
	downloadButton = 0xAAAAAA,
	downloadButtonText = 0xFFFFFF,
	downloading = 0x009240,
	downloadingText = 0xFFFFFF,
	downloaded = 0xCCCCCC,
	downloadedText = 0xFFFFFF,
}

local typeFilters = {
	"Application",
	"Library",
	"Wallpaper",
	"Script",
}

local localization = files.loadTableFromFile("MineOS/Applications/AppMarket.app/Resources/Localization/" .. _G.OSSettings.language .. ".lang")
local appMarketConfigPath = "MineOS/System/AppMarket/"
local pathToApplications = "MineOS/System/OS/Applications.txt"
local updateImage = image.load(MineOSCore.paths.icons .. "Update.pic")
local topBarElements = {localization.applications, localization.libraries, localization.wallpapers, localization.other, localization.updates}
local oldApplications, newApplications, currentApps, changes = {}, {}, {}, {}

local currentTopBarElement = 1
local from, limit, fromY = 1, 8

------------------------------------------------------------------------------------------------------------------

local function correctDouble(number)
	return string.format("%.2f", number)
end

local function status(text)
	text = unicode.sub(text, 1, sizes.width - 2)
	local y = sizes.y + sizes.height - 1
	buffer.square(sizes.x, y, sizes.width, 1, colors.statusBar, colors.statusBarText, " ")
	buffer.text(sizes.x + 1, y, colors.statusBarText, text)
	buffer.draw()
end

local function calculateSizes()
	sizes.width, sizes.height = math.floor(buffer.screen.width * 0.6), math.floor(buffer.screen.height * 0.7)
	sizes.x, sizes.y = math.floor(buffer.screen.width / 2 - sizes.width / 2), math.floor(buffer.screen.height / 2 - sizes.height / 2)
	sizes.topBarHeight = 3
	obj.main = GUI.object(sizes.x, sizes.y + sizes.topBarHeight, sizes.width, sizes.height - sizes.topBarHeight)
	sizes.downloadButtonWidth = 17
	sizes.descriptionTruncateSize = sizes.width - 6 - MineOSCore.iconWidth - sizes.downloadButtonWidth
	sizes.searchFieldWidth = math.floor(sizes.width * 0.3)
	obj.searchTextField = GUI.textField(math.floor(sizes.x + sizes.width / 2 - sizes.searchFieldWidth / 2), 1, sizes.searchFieldWidth, 1, 0xEEEEEE, 0x777777, 0xEEEEEE, 0x555555, nil, localization.search, false, true)
end

local function drawTopBar()
	obj.topBarButtons = GUI.toolbar(sizes.x, sizes.y, sizes.width, sizes.topBarHeight, 2, currentTopBarElement, colors.topBar, colors.topBarText, colors.topBarElement, colors.topBarElementText, table.unpack(topBarElements))
	obj.windowActionButtons = GUI.windowActionButtons(sizes.x + 1, sizes.y)
end

local function getIcon(url)
	local success, response = ecs.internetRequest(url)
	local path = appMarketConfigPath .. "TempIcon.pic"
	if success then
		local file = io.open(path, "w")
		file:write(response)
		file:close()
	else
		GUI.error(tostring(response), {title = {color = 0xFFDB40, text = localization.errorWhileLoadingIcon}})
	end
	return image.load(path)
end

local function getDescription(url)
	local success, response = ecs.internetRequest(url)
	if success then
		return response
	else
		GUI.error(tostring(response), {title = {color = 0xFFDB40, text = localization.errorWhileLoadingDescription}})
	end
end

local function getApplication(i)
	currentApps[i] = {}
	currentApps[i].name = fs.name(newApplications[i].name)

	if newApplications[i].icon then
		currentApps[i].icon = getIcon(newApplications.GitHubUserURL .. newApplications[i].icon)
	else
		if newApplications[i].type == "Application" then
			currentApps[i].icon = failureIcon
		elseif newApplications[i].type == "Wallpaper" then
			currentApps[i].icon = MineOSCore.icons.image
		elseif newApplications[i].type == "Library" then
			currentApps[i].icon = MineOSCore.icons.lua
		else
			currentApps[i].icon = MineOSCore.icons.script
		end
	end

	if newApplications[i].about then
		currentApps[i].description = getDescription(newApplications.GitHubUserURL .. newApplications[i].about .. _G.OSSettings.language .. ".txt")
		currentApps[i].description = ecs.stringWrap({currentApps[i].description}, sizes.descriptionTruncateSize )
	else
		currentApps[i].description = {localization.descriptionNotAvailable}
	end

	if newApplications[i].version then
		currentApps[i].version = localization.version .. correctDouble(newApplications[i].version)
	else
		currentApps[i].version = localization.versionNotAvailable
	end
end

local function checkAppExists(name, type)
	if type == "Application" then
		name = name .. ".app"
	end
	return fs.exists(name)
end

local function drawApplication(x, y, i, doNotDrawButton)
	buffer.image(x, y, currentApps[i].icon)
	buffer.text(x + 10, y, colors.appName, currentApps[i].name)
	buffer.text(x + 10, y + 1, colors.version, currentApps[i].version)
	local appExists = checkAppExists(newApplications[i].name, newApplications[i].type)
	local text = appExists and localization.update or localization.download
	
	if not doNotDrawButton then
		local xButton, yButton = sizes.x + sizes.width - sizes.downloadButtonWidth - 2, y + 1
		if currentApps[i].buttonObject then
			currentApps[i].buttonObject.x, currentApps[i].buttonObject.y = xButton, yButton
			currentApps[i].buttonObject:draw()
		else
			currentApps[i].buttonObject = GUI.button(xButton, yButton, sizes.downloadButtonWidth, 1, colors.downloadButton, colors.downloadButtonText, 0x555555, 0xFFFFFF, text)
		end
	end

	for j = 1, #currentApps[i].description do
		buffer.text(x + 10, y + j + 1, colors.description, currentApps[i].description[j])
	end
	y = y + (#currentApps[i].description > 2 and #currentApps[i].description - 2 or 0)
	y = y + 5

	return x, y
end

local function drawPageSwitchButtons(y)
	local text = localization.applicationsFrom .. from .. localization.applicationsTo .. from + limit - 1
	local textLength = unicode.len(text)
	local buttonWidth = 5
	local width = buttonWidth * 2 + textLength + 2
	local x = math.floor(sizes.x + sizes.width / 2 - width / 2)
	obj.prevPageButton = GUI.button(x, y, buttonWidth, 1, colors.downloadButton, colors.downloadButtonText, 0x262626, 0xFFFFFF, "<")
	x = x + obj.prevPageButton.width + 1
	buffer.text(x, y, colors.version, text)
	x = x + textLength + 1
	obj.nextPageButton = GUI.button(x, y, buttonWidth, 1, colors.downloadButton, colors.downloadButtonText, 0x262626, 0xFFFFFF, ">")
end

local function clearMainZone()
	buffer.square(sizes.x, obj.main.y, sizes.width, obj.main.height, 0xFFFFFF)
end

local function drawMain(refreshData)
	clearMainZone()
	local x, y = sizes.x + 2, fromY

	buffer.setDrawLimit(sizes.x, obj.main.y, sizes.width, obj.main.height)

	obj.searchTextField.y, obj.searchTextField.invisible = y, false
	obj.searchTextField:draw()
	y = y + 2

	local matchCount = 1
	for i = 1, #newApplications do
		if newApplications[i].type == typeFilters[currentTopBarElement] then
			if not obj.searchTextField.text or (string.find(unicode.lower(fs.name(newApplications[i].name)), unicode.lower(obj.searchTextField.text))) then
				if matchCount >= from and matchCount <= from + limit - 1 then
					if refreshData and not currentApps[i] then
						status(localization.downloadingInfoAboutApplication .. " \"" .. newApplications[i].name .. "\"")
						getApplication(i)
					end
					x, y = drawApplication(x, y, i)
				end
				matchCount = matchCount + 1
			end
		end
	end

	if matchCount > limit then
		drawPageSwitchButtons(y)
	end

	buffer.resetDrawLimit()
end

local function getNewApplications()
	local pathToNewApplications = appMarketConfigPath .. "NewApplications.txt"
	ecs.getFileFromUrl(oldApplications.GitHubApplicationListURL, pathToNewApplications)
	newApplications = files.loadTableFromFile(pathToNewApplications)
end

local function getChanges()
	changes = {}
	for j = 1, #newApplications do
		local matchFound = false
		for i = 1, #oldApplications do	
			if oldApplications[i].name == newApplications[j].name then
				if oldApplications[i].version < newApplications[j].version then table.insert(changes, j) end
				matchFound = true
				break
			end
		end
		if not matchFound then table.insert(changes, j) end
	end
end

local function updates()
	clearMainZone()

	obj.searchTextField.invisible = true

	if #changes > 0 then
		buffer.setDrawLimit(sizes.x, obj.main.y, sizes.width, obj.main.height)
		local x, y = sizes.x + 2, fromY
		obj.updateAllButton = GUI.button(math.floor(sizes.x + sizes.width / 2 - sizes.downloadButtonWidth / 2), y, 20, 1, colors.downloadButton, colors.downloadButtonText, 0x555555, 0xFFFFFF, "Обновить все")
		y = y + 2

		for i = from, (from + limit) do
			if not changes[i] then break end
			if not currentApps[changes[i]] then
				status(localization.downloadingInfoAboutApplication .. " \"" .. fs.name(newApplications[changes[i]].name) .. "\"")
				getApplication(changes[i])
			end
			x, y = drawApplication(x, y, changes[i], true)
		end

		if #changes > limit then
			drawPageSwitchButtons(y)
		end
		buffer.resetDrawLimit()
	else
		local text = localization.youHaveNewestApps
		buffer.text(math.floor(sizes.x + sizes.width / 2 - unicode.len(text) / 2), math.floor(obj.main.y + obj.main.height / 2 - 1), colors.description, text)
	end
end

local function flush()
	fromY = obj.main.y + 1
	from = 1
	currentApps = {}
end

local function loadOldApplications()
	oldApplications = files.loadTableFromFile(pathToApplications)
end

local function saveOldApplications()
	files.saveTableToFile(pathToApplications, oldApplications)
end

local function drawAll(refreshIcons, force)
	drawTopBar()
	if currentTopBarElement == 5 then
		updates()
	else
		drawMain(refreshIcons)
	end
	buffer.draw(force)
end

local function updateImageWindow()
	clearMainZone()
	local x, y = math.floor(sizes.x + sizes.width / 2 - updateImage.width / 2), math.floor(obj.main.y + obj.main.height / 2 - updateImage.height / 2 - 2)
	buffer.image(x, y, updateImage)
	return y + updateImage.height
end

local function updateImageWindowWithText(text)
	local y = updateImageWindow() + 2
	local x = math.floor(sizes.x + sizes.width / 2 - unicode.len(text) / 2)
	buffer.text(x, y, colors.description, text)
end

local function updateAll()
	local y = updateImageWindow()
	local barWidth = math.floor(sizes.width * 0.6)
	local xBar = math.floor(sizes.x + sizes.width / 2 - barWidth / 2)
	y = y + 2
	for i = 1, #changes do
		local text = localization.updating .. " " .. fs.name(newApplications[changes[i]].name)
		local xText = math.floor(sizes.x + sizes.width / 2 - unicode.len(text) / 2)
		buffer.square(sizes.x, y + 1, sizes.width, 1, 0xFFFFFF)
		buffer.text(xText, y + 1, colors.description, text)
		GUI.progressBar(xBar, y, barWidth, 1, 0xCCCCCC, 0x0092FF, i, #changes, true)
		buffer.draw()
		ecs.getOSApplication(newApplications[changes[i]], true)
	end
	changes = {}
	oldApplications = newApplications
	saveOldApplications()
end

------------------------------------------------------------------------------------------------------------------

-- buffer.start()
-- buffer.clear(0xFF8888)

local args = {...}
if args[1] == "updateCheck" then
	currentTopBarElement = 5
end

fs.makeDirectory(appMarketConfigPath)
calculateSizes()
flush()
loadOldApplications()
drawTopBar()
GUI.windowShadow(sizes.x, sizes.y, sizes.width, sizes.height, 50)
updateImageWindowWithText(localization.downloadingApplicationsList)
buffer.draw()
getNewApplications()
getChanges()
drawAll(true, false)

while true do
	local e = {event.pull()}
	if e[1] == "touch" then

		if obj.main:isClicked(e[3], e[4]) then
			if obj.searchTextField:isClicked(e[3], e[4]) then
				obj.searchTextField:input()
				flush()
				drawAll(true, false)
			end

			if currentTopBarElement < 5 then
				for appIndex, app in pairs(currentApps) do
					if app.buttonObject:isClicked(e[3], e[4]) then
						app.buttonObject:press(0.3)
						if app.buttonObject.text == localization.update or app.buttonObject.text == localization.download then
							app.buttonObject.text = localization.downloading
							app.buttonObject.disabled = true
							app.buttonObject.colors.disabled.button, app.buttonObject.colors.disabled.text = colors.downloading, colors.downloadingText
							app.buttonObject:draw()
							buffer.draw()
							ecs.getOSApplication(newApplications[appIndex], true)
							app.buttonObject.text = localization.downloaded
							app.buttonObject.colors.disabled.button, app.buttonObject.colors.disabled.text = colors.downloaded, colors.downloadedText
							app.buttonObject:draw()
							buffer.draw()
						end
						break
					end	
				end
			else
				if obj.updateAllButton and obj.updateAllButton:isClicked(e[3], e[4]) then
					obj.updateAllButton:press()
					updateAll()
					flush()
					drawAll()
				end
			end

			if obj.nextPageButton then
				if obj.nextPageButton:isClicked(e[3], e[4]) then
					obj.nextPageButton:press()
					fromY = obj.main.y + 1
					from = from + limit
					currentApps = {}
					drawAll(true, false)
				elseif obj.prevPageButton:isClicked(e[3], e[4]) then
					if from > limit then
						fromY = obj.main.y + 1
						from = from - limit
						currentApps = {}
						drawAll(true, false)
					end
				end
			end
		end


		if obj.windowActionButtons.close:isClicked(e[3], e[4]) then
			obj.windowActionButtons.close:press()
			return
		end

		for key, button in pairs(obj.topBarButtons) do
			if button:isClicked(e[3], e[4]) then
				currentTopBarElement = key
				flush()
				drawAll(true, false)
				break
			end
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if (fromY < obj.main.y) then
				fromY = fromY + 2
				drawAll(false, false)
			end
		else
			fromY = fromY - 2
			drawAll(false, false)
		end
	end
end








