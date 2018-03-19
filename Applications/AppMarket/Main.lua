local args = {...}

require("advancedLua")
local component = require("component")
local computer = require("computer")
local web = require("web")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local MineOSCore = require("MineOSCore")
local MineOSPaths = require("MineOSPaths")
local MineOSInterface = require("MineOSInterface")
local image = require("image")
local fs = require("filesystem")
local color = require("color")
local unicode = require("unicode")

--------------------------------------------------------------------------------

local host = "http://eliteclubsessions.ru/MineOSAPI/2.03/"
local iconCheckReponseTime = 1

local overviewIconsCount = 10
local overviewAnimationDelay = 0.05
local overviewForceDecay = 0.15
local overviewForceLimit = 0.5
local overviewMaximumTouchAcceleration = 5

local appMarketPath = MineOSPaths.applicationData .. "App Market/"
local configPath = appMarketPath .. "Config.cfg"
local userPath = appMarketPath .. "User.cfg"
local iconCachePath = appMarketPath .. "Cache/"

local resourcesPath = MineOSCore.getCurrentScriptDirectory() 
local localization = MineOSCore.getLocalization(resourcesPath .. "Localizations/") 

local categories = {
	localization.categoryApplications,
	localization.categoryLibraries,
	localization.categoryScripts,
}

local orderDirections = {
	"desc",
	"asc",
}

local downloadPaths = {
	"/MineOS/Applications/",
	"/lib/",
	"/bin/",
}

local licenses = {
	"MIT",
	"GNU GPLv3",
	"GNU AGPLv3",
	"GNU LGPLv3",
	"Apache Licence 2.0",
	"Mozilla Public License 2.0",
	"The Unlicense",
}

local orderBys = {
	"popularity",
	"rating",
	"name",
	"date",
}

local languages = {
	[18] = "English",
	[71] = "Russian",
}

--------------------------------------------------------------------------------

fs.makeDirectory(iconCachePath)

local luaIcon = image.load(MineOSPaths.icons .. "Lua.pic")
local fileNotExistsIcon = image.load(MineOSPaths.icons .. "FileNotExists.pic")
local scriptIcon = image.load(MineOSPaths.icons .. "Script.pic")

local search = ""
local appWidth, appHeight, appHSpacing, appVSpacing, currentPage, appsPerPage, appsPerWidth, appsPerHeight  = 34, 6, 2, 1, 0
local updateFileList, editPublication
local config, fileVersions, user

--------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(MineOSInterface.tabbedWindow(1, 1, 110, 29))

local contentContainer = window:addChild(GUI.container(1, 4, 1, 1))

local activityWidget = window:addChild(GUI.object(1, 1, 4, 3))
activityWidget.hidden = true
activityWidget.position = 0
activityWidget.color1 = 0x99FF80
activityWidget.color2 = 0x00B640
activityWidget.draw = function(activityWidget)
	buffer.text(activityWidget.x + 1, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⢀")
	buffer.text(activityWidget.x + 2, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⡀")

	buffer.text(activityWidget.x + 3, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⠆")
	buffer.text(activityWidget.x + 2, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⢈")

	buffer.text(activityWidget.x + 1, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠈")
	buffer.text(activityWidget.x + 2, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠁")

	buffer.text(activityWidget.x, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⠰")
	buffer.text(activityWidget.x + 1, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⡁")
end

local overrideWindowDraw = window.draw
window.draw = function(...)
	if not activityWidget.hidden then
		activityWidget.position = activityWidget.position + 1
		if activityWidget.position > 4 then
			activityWidget.position = 1
		end
	end

	return overrideWindowDraw(...)
end

local function activity(state)
	activityWidget.hidden = not state
	MineOSInterface.OSDraw()
end

--------------------------------------------------------------------------------

local function saveConfig()
	table.toFile(configPath, config)
end

local function saveFileVersions()
	table.toFile(MineOSPaths.fileVersions, fileVersions)
end

local function saveUser()
	table.toFile(userPath, user)
end

local function loadConfig()
	if fs.exists(MineOSPaths.fileVersions) then
		fileVersions = table.fromFile(MineOSPaths.fileVersions)
	else
		fileVersions = {}
	end

	if fs.exists(userPath) then
		user = table.fromFile(userPath)
	else
		user = {}
	end

	if fs.exists(configPath) then
		config = table.fromFile(configPath)
	else
		config = {
			language_id = 18,
			orderBy = 1,
			orderDirection = 1,
			singleSession = false,
		}
	end
end

--------------------------------------------------------------------------------

local function RawAPIRequest(script, data, notUnserialize)
	local requestResult, requestReason = web.request(
		host .. script .. ".php",
		data and web.serialize(data) or nil,
		{ 
			["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.119 Safari/537.36"
		}
	)

	if requestResult then
		if not notUnserialize then
			local unserializeResult, unserializeReason = table.fromString(requestResult)
			if unserializeResult then
				if unserializeResult.success then
					return unserializeResult
				else
					return false, "API request not succeded: " .. tostring(unserializeResult.reason)
				end
			else
				return false, "Failed to unserialize response data: " .. tostring(unserializeReason)
			end
		else
			return result
		end
	else
		return false, "Web request failed: " .. tostring(requestReason)
	end
end

local function fieldAPIRequest(fieldToReturn, script, data)
	local success, reason = RawAPIRequest(script, data)
	if success then
		if success[fieldToReturn] then
			return success[fieldToReturn]
		else
			GUI.error("Request was successful, but field " .. tostring(fieldToReturn) .. " doesn't exists")
		end
	else
		GUI.error(reason)
	end
end

local function checkContentLength(url)
	local handle = component.internet.request(url)
	if handle then
		local uptime, _, _, responseData = computer.uptime()
		repeat
			_, _, responseData = handle:response()
		until responseData or computer.uptime() - uptime > iconCheckReponseTime

		if responseData and responseData["Content-Length"] then
			if tonumber(responseData["Content-Length"][1]) <= 10240 then
				return handle
			else
				handle:close()
				return false, "Specified image size is too big"
			end
		else
			return false, "Too long without response"
		end
	else
		return false, "Invalid URL"
	end
end

local function checkImage(url, mneTolkoSprosit)
	local handle, reason = checkContentLength(url)
	if handle then
		local needCheck, data, chunk, reason = true, ""
		while true do
			chunk, reason = handle.read(math.huge)
			if chunk then
				data = data .. chunk
				if needCheck and #data > 8 then
					if data:sub(1, 4) == "OCIF" then
						if string.byte(data:sub(5, 5)) == 6 then
							if string.byte(data:sub(6, 6)) == 8 and string.byte(data:sub(7, 7)) == 4 then
								if mneTolkoSprosit then
									handle:close()
									return true								
								end
								needCheck = false
							else
								handle:close()
								return false, "Image size is larger than 8x4"
							end
						else
							handle:close()
							return false, "Image encoding method is not supported"
						end
					else
						handle:close()
						return false, "Wrong image file signature"
					end		
				end
			else
				handle:close()

				if reason then
					return false, reason
				else
					return data
				end
			end
		end	
	else
		return false, reason
	end
end

local function tryToDownload(...)
	local success, reason = web.download(...)
	if not success then
		GUI.error(reason)
	end

	return success
end

--------------------------------------------------------------------------------

local lastMethod, lastArguments
local function callLastMethod()
	lastMethod(table.unpack(lastArguments))
end

local function showLabelAsContent(text)
	contentContainer:deleteChildren()
	contentContainer:addChild(GUI.label(1, 1, contentContainer.width, contentContainer.height, 0x2D2D2D, text)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)
end

local function newButtonsLayout(x, y, width, spacing)
	local buttonsLayout = GUI.layout(x, y, width, 1, 1, 1)
	buttonsLayout:setCellDirection(1, 1, GUI.directions.horizontal)
	buttonsLayout:setCellSpacing(1, 1, spacing)

	return buttonsLayout
end

local function getUpdateState(file_id, version)
	if fileVersions[file_id] then
		if fs.exists(fileVersions[file_id].path) then
			if fileVersions[file_id].version >= version then
				return 4
			else
				return 3
			end
		else
			return 2
		end
	else
		return 1
	end
end

local function ratingWidgetDraw(object)
	local x = 0
	for i = 1, 5 do
		buffer.text(object.x + x, object.y, object.rating >= i and object.colors.first or object.colors.second, "*")
		x = x + object.spacing
	end

	return object
end

local function newRatingWidget(x, y, rating, firstColor, secondColor)
	local object = GUI.object(x, y, 9, 1)
	
	object.colors = {
		first = firstColor or 0xFFB600,
		second = secondColor or 0xC3C3C3
	}
	object.spacing = 2
	object.draw = ratingWidgetDraw
	object.rating = rating

	return object
end

local function deletePublication(publication)
	local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, localization.areYouSure)
	local buttonsLayout = container.layout:addChild(newButtonsLayout(1, 1, container.layout.width, 2))
	
	buttonsLayout:addChild(GUI.adaptiveButton(1, 1, 2, 0, 0xA5A5A5, 0x2D2D2D, 0x0, 0xE1E1E1, localization.no)).onTouch = function()
		container:delete()
		MineOSInterface.OSDraw()
	end

	buttonsLayout:addChild(GUI.adaptiveButton(1, 1, 2, 0, 0xE1E1E1, 0x2D2D2D, 0x0, 0xE1E1E1, localization.yes)).onTouch = function()
		local success, reason = RawAPIRequest("delete", {
			token = user.token,
			file_id = publication.file_id,
		})

		if success then		
			container:delete()			
			updateFileList(publication.category_id)
		else
			GUI.error(reason)
		end
	end
end

--------------------------------------------------------------------------------

local function getApplicationPathFromVersions(versionsPath)
	return versionsPath:gsub("%.app/Main%.lua", ".app")
end

local function getDependencyPath(mainFilePath, dependency)
	local path
	-- Если зависимость - эт публикация
	if dependency.publication_name then
		path = downloadPaths[dependency.category_id] .. dependency.path
	-- Если зависимость - эт ресурс
	else
		-- Ресурсы по абсолютному пути
		if dependency.path:sub(1, 1) == "/" then
			path = dependency.path
		-- Ресурсы по релятивному пути
		else
			path = getApplicationPathFromVersions(mainFilePath) .. "/" .. dependency.path
		end
	end

	return path:gsub("/+", "/")
end

local function download(publication)
	activity(true)

	if not publication.translated_description then
		publication = fieldAPIRequest("result", "publication", {
			file_id = publication.file_id,
			language_id = config.language_id,
		})
	end

	if publication then
		local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, localization.choosePath)
		container.layout:setCellFitting(2, 1, false, false)

		local filesystemChooserPath = fileVersions[publication.file_id] and getApplicationPathFromVersions(fileVersions[publication.file_id].path)
		if not filesystemChooserPath then
			if publication.category_id == 1 then
				filesystemChooserPath = downloadPaths[publication.category_id] .. publication.publication_name .. ".app"
			else
				filesystemChooserPath = downloadPaths[publication.category_id] .. publication.path
			end
		end

		local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 44, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696, filesystemChooserPath, localization.save, localization.cancel, localization.fileName, "/"))
		filesystemChooser:setMode(GUI.filesystemModes.save, GUI.filesystemModes.file)

		container.layout:addChild(GUI.text(1, 1, 0xE1E1E1, localization.tree))
		local tree = container.layout:addChild(GUI.tree(1, 1, 44, 10, 0xE1E1E1, 0xA5A5A5, 0x3C3C3C, 0xA5A5A5, 0x3C3C3C, 0xE1E1E1, 0xB4B4B4, 0xA5A5A5, 0xC3C3C3, 0x444444))

		local mainFilePath
		local function updateTree()
			tree.items = {}
			tree.fromItem = 1

			mainFilePath = filesystemChooser.path .. (publication.category_id == 1 and "/Main.lua" or "")

			-- Вот тута будет йоба-древо
			local dependencyTree = {}
			local treeData = {
				{
					path = mainFilePath,
					source_url = publication.source_url,
				}
			}

			if publication.dependencies then
				for i = 1, #publication.all_dependencies do
					table.insert(treeData, publication.dependencies_data[publication.all_dependencies[i]])
				end
			end

			for i = 1, #treeData do
				local idiNahooy = dependencyTree
				local dependencyPath = getDependencyPath(mainFilePath, treeData[i])
				
				for blyad in fs.path(dependencyPath):gmatch("[^/]+") do
					if not idiNahooy[blyad] then
						idiNahooy[blyad] = {}
					end
					idiNahooy = idiNahooy[blyad]
				end
				
				table.insert(idiNahooy, {
					path = dependencyPath,
					source_url = treeData[i].source_url,
				})
			end
			
			-- Пизда для формирования той ебалы, как ее там
			local function pizda(t, offset, initPath)
				for chlen, devka in pairs(t) do
					if devka.path then
						tree:addItem(fs.name(devka.path), devka.path, offset, false)
					else
						tree:addItem(chlen, chlen, offset, true)
						tree.expandedItems[chlen] = true

						pizda(devka, offset + 2, initPath .. chlen .. "/")
					end
				end
			end

			pizda(dependencyTree, 1, "/")
		end

		local shortcutSwitchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 44, 8, 0x66DB80, 0x0, 0xE1E1E1, 0x878787, localization.createShortcut .. ":", true))
		shortcutSwitchAndLabel.hidden = publication.category_id == 2

		container.layout:addChild(GUI.button(1, 1, 44, 3, 0x696969, 0xFFFFFF, 0x0, 0xFFFFFF, localization.download)).onTouch = function()
			container.layout:deleteChildren(2)
			local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 40, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))
				
			local countOfShit = 1 + (publication.all_dependencies and #publication.all_dependencies or 0)
			
			local function govnoed(pizda, i)
				container.label.text = localization.downloading .. " " .. fs.name(pizda.path)
				progressBar.value = math.round(i / countOfShit * 100)
				MineOSInterface.OSDraw()
			end

			-- SAVED
			fileVersions[publication.file_id] = {
				path = mainFilePath,
				version = publication.version,
			}

			govnoed(publication, 1)
			tryToDownload(publication.source_url, mainFilePath)

			if publication.dependencies then
				for i = 1, #publication.all_dependencies do
					local dependency = publication.dependencies_data[publication.all_dependencies[i]]
					local dependencyPath = getDependencyPath(mainFilePath, dependency)

					govnoed(dependency, i + 1)

					if getUpdateState(publication.all_dependencies[i], dependency.version) < 4 then
						fileVersions[publication.all_dependencies[i]] = {
							path = dependencyPath,
							version = dependency.version,
						}
						tryToDownload(dependency.source_url, dependencyPath)
					else
						os.sleep(0.05)
					end
				end
			end

			container:delete()
			callLastMethod()

			if not shortcutSwitchAndLabel.hidden and shortcutSwitchAndLabel.switch.state then
				MineOSCore.createShortcut(MineOSPaths.desktop .. fs.hideExtension(fs.name(filesystemChooser.path)) .. ".lnk", filesystemChooser.path .. "/")
			end
			
			computer.pushSignal("MineOSCore", "updateFileList")
			saveFileVersions()
		end

		filesystemChooser.onSubmit = updateTree
		updateTree()
	end

	activity()
end

local function addPanel(container, color)
	container.panel = container:addChild(GUI.panel(1, 1, container.width, container.height, color or 0xFFFFFF))
end

local function loadImage(path)
	local picture, reason = image.load(path)
	if picture then
		return picture
	else
		return fileNotExistsIcon
	end
end

local function getPublicationIcon(publication)
	if publication.icon_url then
		local path = iconCachePath .. publication.file_id .. "@" .. publication.version .. ".pic"

		if fs.exists(path) then
			return loadImage(path)
		else
			local data, reason = checkImage(publication.icon_url)
			if data then
				local file = io.open(path, "w")
				file:write(data)
				file:close()

				return loadImage(path)
			else
				return fileNotExistsIcon
			end
		end
	elseif publication.category_id == 2 then
		return luaIcon
	else
		return scriptIcon
	end
end

local function addApplicationInfo(container, publication, limit)
	addPanel(container)
	container.image = container:addChild(GUI.image(3, 2, getPublicationIcon(publication)))
	container.nameLabel = container:addChild(GUI.text(13, 2, 0x0, string.limit(publication.publication_name, limit, "right")))
	container.developerLabel = container:addChild(GUI.text(13, 3, 0x878787, string.limit("©" .. publication.user_name, limit, "right")))
	container.rating = container:addChild(newRatingWidget(13, 4, publication.average_rating and math.round(publication.average_rating) or 0))

	local updateState = getUpdateState(publication.file_id, publication.version)
	container.downloadButton = container:addChild(GUI.adaptiveRoundedButton(13, 5, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x969696, 0xFFFFFF, updateState == 4 and localization.installed or updateState == 3 and localization.update or localization.install))
	container.downloadButton.onTouch = function()
		download(publication)
	end
	container.downloadButton.colors.disabled.background = 0xE1E1E1
	container.downloadButton.colors.disabled.text = 0xFFFFFF
	container.downloadButton.disabled = updateState == 4

	if updateState > 2 then
		container.downloadButton.width = container.downloadButton.width + 1
		container:addChild(GUI.adaptiveRoundedButton(container.downloadButton.localX + container.downloadButton.width, container.downloadButton.localY, 1, 0, 0xF0F0F0, 0x969696, 0x969696, 0xFFFFFF, "x")).onTouch = function()
			fs.remove(getApplicationPathFromVersions(fileVersions[publication.file_id].path))
			fs.remove(MineOSPaths.desktop .. publication.publication_name .. ".lnk")
			fileVersions[publication.file_id] = nil
			
			callLastMethod()
			computer.pushSignal("MineOSCore", "updateFileList")
			saveFileVersions()
		end
	end
end

local function keyValueWidgetDraw(object)
	buffer.text(object.x, object.y, object.colors.key, object.key)
	buffer.text(object.x + unicode.len(object.key), object.y, object.colors.value, object.value)
end

local function newKeyValueWidget(x, y, width, keyColor, valueColor, key, value)
	local object = GUI.object(x, y, width, 1)
	
	object.colors = {
		key = keyColor,
		value = valueColor
	}
	object.key = key
	object.value = value

	object.draw = keyValueWidgetDraw

	return object
end

local function containerScrollEventHandler(mainContainer, object, eventData)
	if eventData[1] == "scroll" then
		local first, last = object.children[1], object.children[#object.children]
		
		if eventData[5] == 1 then
			if first.localY < 2 then
				for i = 1, #object.children do
					object.children[i].localY = object.children[i].localY + 1
				end
				MineOSInterface.OSDraw()
			end
		else
			if last.localY + last.height - 1 >= object.height then
				for i = 1, #object.children do
					object.children[i].localY = object.children[i].localY - 1
				end
				MineOSInterface.OSDraw()
			end
		end
	end
end

local function newPublicationInfo(file_id)
	lastMethod, lastArguments = newPublicationInfo, {file_id}
	activity(true)

	local publication = fieldAPIRequest("result", "publication", {
		file_id = file_id,
		language_id = config.language_id,
	})

	if publication then
		MineOSInterface.OSDraw()

		local reviews = fieldAPIRequest("result", "reviews", {
			file_id = file_id,
			offset = 0,
			count = 10,
		})

		if reviews then
			contentContainer:deleteChildren()
			
			local infoContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))
			infoContainer.eventHandler = containerScrollEventHandler

			-- Жирный йоба-лейаут для отображения ВАЩЕ всего - и инфы, и отзыввов
			local layout = infoContainer:addChild(GUI.layout(3, 2, infoContainer.width - 4, infoContainer.height, 1, 1))
			layout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

			-- А вот эт уже контейнер чисто инфы крч
			local detailsContainer = layout:addChild(GUI.container(3, 2, layout.width, 6))
					
			-- Тут будут находиться ваще пизда подробности о публикации
			local ratingsContainer = detailsContainer:addChild(GUI.container(1, 1, 28, 6))
			ratingsContainer.localX = detailsContainer.width - ratingsContainer.width + 1
			addPanel(ratingsContainer, 0xE1E1E1)
			
			-- Всякая текстовая пизда
			local y = 2
			-- Фигачим кнопочки на изменение хуйни
			if publication.user_name == user.name then
				local buttonsLayout = ratingsContainer:addChild(newButtonsLayout(2, y, ratingsContainer.width - 2, 3))
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(2, 1, 1, 0, 0x969696, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.edit)).onTouch = function()
					editPublication(publication)
				end
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(2, 1, 1, 0, 0x969696, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.remove)).onTouch = function()
					deletePublication(publication)
				end
				y = y + 2
			end

			ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.developer, ": " .. publication.user_name)); y = y + 1
			ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.license, ": " .. licenses[publication.license_id])); y = y + 1
			ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.category, ": " .. categories[publication.category_id])); y = y + 1
			ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.version, ": " .. publication.version)); y = y + 1
			ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.updated, ": " .. os.date("%d.%m.%Y", publication.timestamp))); y = y + 1
			
			-- Добавляем инфу с общими рейтингами
			if #reviews > 0 then
				local ratings = {0, 0, 0, 0, 0}
				for i = 1, #reviews do
					ratings[reviews[i].rating] = ratings[reviews[i].rating] + 1
				end

				y = y + 1
				ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.reviews, ": " .. #reviews)); y = y + 1
				ratingsContainer:addChild(newKeyValueWidget(2, y, ratingsContainer.width - 2, 0x2D2D2D, 0x878787, localization.averageRating, ": " .. string.format("%.1f", publication.average_rating or 0))); y = y + 1

				for i = #ratings, 1, -1 do
					local text = tostring(ratings[i])
					local textLength = #text
					ratingsContainer:addChild(newRatingWidget(2, y, i, nil, 0xC3C3C3))
					ratingsContainer:addChild(GUI.progressBar(12, y, ratingsContainer.width - textLength - 13, 0x2D2D2D, 0xC3C3C3, 0xC3C3C3, ratings[i] / #reviews * 100, true))
					ratingsContainer:addChild(GUI.text(ratingsContainer.width - textLength, y, 0x2D2D2D, text))
					y = y + 1
				end
			end
			
			-- Добавляем контейнер под описание и прочую пизду
			local textDetailsContainer = detailsContainer:addChild(GUI.container(1, 1, detailsContainer.width - ratingsContainer.width, detailsContainer.height))
			-- Ебурим саму пизду
			addApplicationInfo(textDetailsContainer, publication, math.huge)
			-- Ебурим описание
			local x, y = 3, 7
			local lines = string.wrap(publication.translated_description, textDetailsContainer.width - 4)
			local textBox = textDetailsContainer:addChild(GUI.textBox(3, y, textDetailsContainer.width - 4, #lines, nil, 0x969696, lines, 1, 0, 0))
			textBox.eventHandler = nil
			y = y + textBox.height + 1

			-- Зависимости
			if publication.dependencies then
				local publicationDependencyExists = false
				for i = 1, #publication.all_dependencies do
					if publication.dependencies_data[publication.all_dependencies[i]].publication_name then
						publicationDependencyExists = true
						break
					end
				end

				if publicationDependencyExists then
					textDetailsContainer:addChild(GUI.label(1, y, textDetailsContainer.width, 1, 0x696969, localization.dependencies)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
					y = y + 2

					for i = 1, #publication.all_dependencies do
						local dependency = publication.dependencies_data[publication.all_dependencies[i]]
						if dependency.publication_name then
							local textLength = unicode.len(dependency.publication_name) 
							if x + textLength + 4 > textDetailsContainer.width - 4 then
								x, y = 3, y + 2
							end
							local button = textDetailsContainer:addChild(GUI.roundedButton(x, y, textLength + 2, 1, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, dependency.publication_name))
							button.onTouch = function()
								newPublicationInfo(publication.all_dependencies[i])
							end
							x = x + button.width + 2
						end
					end

					y = y + 2
				end
			end

			-- Подсчитываем результирующие размеры
			textDetailsContainer.height = math.max(
				textDetailsContainer.children[#textDetailsContainer.children].localY + textDetailsContainer.children[#textDetailsContainer.children].height,
				ratingsContainer.children[#ratingsContainer.children].localY + ratingsContainer.children[#ratingsContainer.children].height
			)
			textDetailsContainer.panel.height = textDetailsContainer.height
			ratingsContainer.height = textDetailsContainer.height
			ratingsContainer.panel.height = textDetailsContainer.height
			detailsContainer.height = textDetailsContainer.height

			if user.token and user.name ~= publication.user_name then
				local existingReviewText
				if #reviews > 0 then
					for i = 1, #reviews do
						if reviews[i].user_name == user.name then
							existingReviewText = reviews[i].comment
							break
						end
					end
				end

				layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, existingReviewText and localization.changeReview or localization.writeReview)).onTouch = function()
					local container = MineOSInterface.addUniversalContainer(window, existingReviewText and localization.changeReview or localization.writeReview)
					container.layout:setCellFitting(2, 1, false, false)

					local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, existingReviewText or "", localization.writeReviewHere))
					
					local pizda = container.layout:addChild(GUI.container(1, 1, 1, 1))
					local eblo = pizda:addChild(GUI.text(1, 1, 0xE1E1E1, localization.yourRating .. ": "))
					pizda.width = eblo.width + 9
					
					local cyka = pizda:addChild(newRatingWidget(eblo.width + 1, 1, 4))
					cyka.eventHandler = function(mainContainer, object, eventData)
						if eventData[1] == "touch" then
							cyka.rating = math.round((eventData[3] - object.x + 1) / object.width * 5)
							MineOSInterface.OSDraw()
						end
					end
					
					local govno = container.layout:addChild(GUI.button(1, 1, 36, 3, 0x696969, 0xFFFFFF, 0x3C3C3C, 0xFFFFFF, "OK"))
					govno.disabled = true
					govno.colors.disabled.background = 0xA5A5A5
					govno.colors.disabled.text = 0xC3C3C3
					govno.onTouch = function()
						activity(true)

						local success, reason = RawAPIRequest("review", {
							token = user.token,
							file_id = publication.file_id,
							rating = cyka.rating,
							comment = input.text,
						})

						container:delete()
						MineOSInterface.OSDraw()

						if success then
							newPublicationInfo(publication.file_id)
						else
							GUI.error(reason)
						end

						activity()
					end

					input.onInputFinished = function()
						local textLength, from, to = unicode.len(input.text), 2, 1000
						if textLength >= from and textLength <= to then
							govno.disabled = false
						else
							govno.disabled = true
							if textLength > to then
								GUI.error("Too big review length (" .. textLength .. "). Maximum is " .. to)
							end
						end
						
						MineOSInterface.OSDraw()
					end

					input.onInputFinished()
				end
			end

			if #reviews > 0 then
				-- Отображаем все оценки
				layout:addChild(GUI.text(1, 1, 0x696969, localization.reviewsOfUsers))

				-- Перечисляем все отзывы
				for i = 1, #reviews do
					local reviewContainer = layout:addChild(GUI.container(1, 1, layout.width, 4))
					addPanel(reviewContainer)

					local y = 2
					local nameLabel = reviewContainer:addChild(GUI.text(3, y, 0x2D2D2D, reviews[i].user_name))
					reviewContainer:addChild(GUI.text(nameLabel.localX + nameLabel.width + 1, y, 0xC3C3C3, "(" .. os.date("%d.%m.%Y", reviews[i].timestamp) .. ")"))
					y = y + 1

					reviewContainer:addChild(newRatingWidget(3, y, reviews[i].rating))
					y = y + 1

					local lines = string.wrap(reviews[i].comment, reviewContainer.width - 4)
					local textBox = reviewContainer:addChild(GUI.textBox(3, y, reviewContainer.width - 4, #lines, nil, 0x878787, lines, 1, 0, 0))
					textBox.eventHandler = nil
					y = y + #lines

					if reviews[i].votes or user.token and user.name ~= reviews[i].user_name then
						y = y + 1
					end

					if reviews[i].votes then
						reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, reviews[i].votes.positive .. " из " .. reviews[i].votes.total .. " пользователей считают этот отзыв полезным"))
						y = y + 1
					end

					if user.token and user.name ~= reviews[i].user_name then
						local wasHelpText = reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, localization.wasReviewHelpful))
						local yesButton = reviewContainer:addChild(GUI.adaptiveButton(wasHelpText.localX + wasHelpText.width + 1, y, 0, 0, nil, 0x696969, nil, 0x2D2D2D, localization.yes))
						local stripLabel = reviewContainer:addChild(GUI.text(yesButton.localX + yesButton.width + 1, y, 0xC3C3C3, "|"))
						local noButton = reviewContainer:addChild(GUI.adaptiveButton(stripLabel.localX + stripLabel.width + 1, y, 0, 0, nil, 0x696969, nil, 0x2D2D2D, localization.no))
						
						local function go(rating)
							activity(true)
							
							local success = fieldAPIRequest("result", "review_vote", {
								token = user.token,
								review_id = reviews[i].id,
								rating = rating
							})

							if success then
								wasHelpText.text = localization.thanksForVote
								wasHelpText.color = 0x696969
								yesButton:delete()
								stripLabel:delete()
								noButton:delete()
							end

							activity()
						end

						yesButton.onTouch = function()
							go(1)
						end

						noButton.onTouch = function()
							go(0)
						end

						y = y + 1
					end

					reviewContainer.height = y
					reviewContainer.panel.height = reviewContainer.height
				end
			end

			layout:update()
			layout.height = layout.children[#layout.children].localY + layout.children[#layout.children].height - 1
		end
	end

	activity()
end

--------------------------------------------------------------------------------

local function applicationWidgetEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.parent.panel.colors.background = 0xE1E1E1
		MineOSInterface.OSDraw()
		newPublicationInfo(object.parent.file_id)
	end
end

local function newApplicationPreview(x, y, publication)
	local container = GUI.container(x, y, appWidth, appHeight)

	container.file_id = publication.file_id
	addApplicationInfo(container, publication, appWidth - 14)

	container.panel.eventHandler,
	container.image.eventHandler,
	container.nameLabel.eventHandler,
	container.developerLabel.eventHandler,
	container.rating.eventHandler =
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler

	return container
end

--------------------------------------------------------------------------------

local function newPlusMinusCyka(width, disableLimit)
	local layout = GUI.layout(1, 1, width, 1, 2, 1)
	layout:setColumnWidth(1, GUI.sizePolicies.percentage, 1.0)
	layout:setColumnWidth(2, GUI.sizePolicies.absolute, 8)
	layout:setCellFitting(1, 1, true, false)
	layout:setCellMargin(2, 1, 1, 0)
	layout:setCellAlignment(1, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	layout:setCellAlignment(2, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	layout:setCellDirection(1, 1, GUI.directions.horizontal)
	layout:setCellDirection(2, 1, GUI.directions.horizontal)

	layout.comboBox = layout:addChild(GUI.comboBox(1, 1, width - 7, 1, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
	layout.defaultColumn = 2
	layout.addButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "+"))
	layout.removeButton = layout:addChild(GUI.button(1, 1, 3, 1, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "-"))

	local overrideRemoveButtonDraw = layout.removeButton.draw
	layout.removeButton.draw = function(...)
		layout.removeButton.disabled = layout.comboBox:count() <= disableLimit
		overrideRemoveButtonDraw(...)
	end

	layout.removeButton.onTouch = function()
		layout.comboBox:removeItem(layout.comboBox.selectedItem)
		MineOSInterface.OSDraw()
	end

	return layout
end

editPublication = function(initialPublication, initialCategoryID)
	lastMethod, lastArguments = editPublication, {initialPublication}
	contentContainer:deleteChildren()

	local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 3, 1))
	layout:setColumnWidth(1, GUI.sizePolicies.percentage, 0.5)
	layout:setColumnWidth(2, GUI.sizePolicies.absolute, 36)
	layout:setColumnWidth(3, GUI.sizePolicies.percentage, 0.5)
	layout:setCellAlignment(1, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.center)
	layout:setCellAlignment(2, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.center)
	layout:setCellFitting(2, 1, true, false)
	layout:setCellMargin(1, 1, 1, 0)

	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.category .. ":"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.license .. ":"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.publicationName .. ":"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.mainFileURL .. ":"))
	local iconHint = layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.iconURL .. ":"))
	local pathHint = layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.mainFileName .. ":"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.description .. ":"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.dependenciesAndResources .. ":"))

	layout.defaultColumn = 2

	layout:addChild(GUI.label(1, 1, 36, 1, 0x0, initialPublication and localization.editPublication or localization.publish)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	local categoryComboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
	for i = 1, #categories do
		categoryComboBox:addItem(categories[i])
	end
	if initialPublication then
		categoryComboBox.selectedItem = initialPublication.category_id
	elseif initialCategoryID then
		categoryComboBox.selectedItem = initialCategoryID
	end

	local licenseComboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
	for i = 1, #licenses do
		licenseComboBox:addItem(licenses[i])
	end
	if initialPublication then licenseComboBox.selectedItem = initialPublication.license_id end

	local nameInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, initialPublication and initialPublication.publication_name or "", "My Script"))
	local mainUrlInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, initialPublication and initialPublication.source_url or "", "http://example.com/Main.lua"))
	local iconUrlInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, initialPublication and initialPublication.icon_url or "", "http://example.com/Icon.pic"))
	local mainPathInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, initialPublication and initialPublication.path or "", "MyScript.lua"))
	local descriptionInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, initialPublication and initialPublication.initial_description or "", "This is my cool script"))
	local dependenciesLayout = layout:addChild(newPlusMinusCyka(36, 0))

	local function addDependency(dependency)
		local text
		if dependency.publication_name then
			text = "#" .. dependency.publication_name
		else
			if dependency.path:sub(1, 1) == "/" then
				text = dependency.path
			else
				text = "../" .. dependency.path
			end
		end
		dependenciesLayout.comboBox:addItem(text).dependency = dependency
		dependenciesLayout.comboBox.selectedItem = dependenciesLayout.comboBox:count()
	end

	if initialPublication and initialPublication.dependencies then
		for i = 1, #initialPublication.dependencies do
			local dependency = initialPublication.dependencies_data[initialPublication.dependencies[i]]
			if dependency.publication_name then
				addDependency({publication_name = dependency.publication_name})
			elseif dependency.path ~= "Icon.pic" then
				addDependency({source_url = dependency.source_url, path = dependency.path})
			end
		end
	end

	local lastDependencyType = 1

	dependenciesLayout.addButton.onTouch = function()
		local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, localization.addDependency)
		
		container.layout:setCellFitting(2, 1, false, false)

		local dependencyTypeComboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
		dependencyTypeComboBox:addItem(localization.fileByURL)
		dependencyTypeComboBox:addItem(localization.existingPublication)
		dependencyTypeComboBox.selectedItem = lastDependencyType

		local publicationNameInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", "Double Buffering"))
		local urlInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", "http://example.com/English.lang"))
		local pathInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", ""))
		local pathType = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x0, 0xE1E1E1, 0x878787, localization.relativePath .. ":", true))

		local button = container.layout:addChild(GUI.button(1, 1, 36, 3, 0x696969, 0xFFFFFF, 0x0, 0xFFFFFF, localization.add))
		button.onTouch = function()
			addDependency({
				publication_name = lastDependencyType > 1 and publicationNameInput.text or nil,
				path = lastDependencyType == 1 and (not pathType.hidden and pathType.switch.state and pathInput.text:gsub("^/+", "") or "/" .. pathInput.text:gsub("/+", "/")) or nil,
				source_url = lastDependencyType == 1 and urlInput.text or nil,
			})

			container:delete()
			MineOSInterface.OSDraw()
		end

		publicationNameInput.onInputFinished = function()
			if lastDependencyType == 1 then
				button.disabled = #pathInput.text == 0 or #urlInput.text == 0
			else
				button.disabled = #publicationNameInput.text == 0
			end
		end
		pathInput.onInputFinished, urlInput.onInputFinished = publicationNameInput.onInputFinished, publicationNameInput.onInputFinished
		
		local function onDependencyTypeComboBoxItemSelected()
			lastDependencyType = dependencyTypeComboBox.selectedItem
			publicationNameInput.hidden = lastDependencyType == 1
			pathInput.hidden = not publicationNameInput.hidden
			urlInput.hidden = pathInput.hidden
			pathType.hidden = categoryComboBox.selectedItem > 1 or pathInput.hidden
		end

		dependencyTypeComboBox.onItemSelected = function()
			onDependencyTypeComboBoxItemSelected()
			MineOSInterface.OSDraw()
		end

		pathType.switch.onStateChanged = function()
			pathInput.placeholderText = pathType.switch.state and "Localizations/English.lang" or "/MineOS/Localizations/English.lang"
		end

		publicationNameInput.onInputFinished()
		onDependencyTypeComboBoxItemSelected()
		pathType.switch.onStateChanged()
		MineOSInterface.OSDraw()
	end

	local publishButton = layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.save))

	local function checkFields()
		publishButton.disabled = not (#nameInput.text > 0 and #mainUrlInput.text > 0 and #descriptionInput.text > 0 and (iconUrlInput.hidden and true or #iconUrlInput.text > 0) and (mainPathInput.hidden and true or #mainPathInput.text > 0))
	end

	iconUrlInput.onInputFinished, nameInput.onInputFinished, mainUrlInput.onInputFinished, mainPathInput.onInputFinished, descriptionInput.onInputFinished = checkFields, checkFields, checkFields, checkFields, checkFields

	categoryComboBox.onItemSelected = function()
		iconHint.hidden = categoryComboBox.selectedItem > 1
		iconUrlInput.hidden = iconHint.hidden

		pathHint.hidden = not iconHint.hidden
		mainPathInput.hidden = pathHint.hidden

		nameInput.onInputFinished()
		MineOSInterface.OSDraw()
	end

	categoryComboBox.onItemSelected()

	publishButton.onTouch = function()
		local dependencies = {}
		for i = 1, dependenciesLayout.comboBox:count() do
			table.insert(dependencies, dependenciesLayout.comboBox:getItem(i).dependency)
		end

		if categoryComboBox.selectedItem == 1 then
			table.insert(dependencies, {
				source_url = iconUrlInput.text,
				path = "Icon.pic"
			})
		end

		activity(true)
		
		local success, reason = RawAPIRequest(initialPublication and "update" or "upload", {
			-- Вот эта хня чисто для апдейта
			file_id = initialPublication and initialPublication.file_id or nil,
			-- А вот эта хня универсальная
			token = user.token,
			name = nameInput.text,
			source_url = mainUrlInput.text,
			path = categoryComboBox.selectedItem == 1 and "Main.lua" or mainPathInput.text,
			description = descriptionInput.text,
			license_id = licenseComboBox.selectedItem,
			dependencies = dependencies,
			category_id = categoryComboBox.selectedItem,
		})

		if success then
			window.tabBar.selectedItem = categoryComboBox.selectedItem + 1
			
			if initialPublication then
				newPublicationInfo(initialPublication.file_id)
			else
				config.orderBy = 3
				saveConfig()
				updateFileList(categoryComboBox.selectedItem)
			end
		else
			GUI.error(reason)
		end

		activity()
	end

	activity()
end

--------------------------------------------------------------------------------

updateFileList = function(category_id, updates)
	lastMethod, lastArguments = updateFileList, {category_id, updates}
	activity(true)

	local file_ids
	if updates then
		file_ids = {}
		for id in pairs(fileVersions) do
			table.insert(file_ids, id)
		end
	end

	local result = fieldAPIRequest("result", "publications", {
		category_id = category_id,
		order_by = updates and "date" or orderBys[config.orderBy],
		order_direction = updates and "desc" or orderDirections[config.orderDirection],
		offset = currentPage * appsPerPage,
		count = updates and 100 or appsPerPage + 1,
		search = search,
		file_ids = file_ids,
	})

	if result then
		contentContainer:deleteChildren()
		
		if updates then
			local i = 1
			while i <= #result do
				if getUpdateState(result[i].file_id, result[i].version) ~= 3 then
					table.remove(result, i)
				else
					i = i + 1
				end
			end
		end

		local y = 2
		local layout = contentContainer:addChild(GUI.layout(1, y, contentContainer.width, 1, 1, 1))
		layout:setCellDirection(1, 1, GUI.directions.horizontal)
		layout:setCellSpacing(1, 1, 2)

		if not updates or updates and #result > 0 then
			if updates then
				if #result > 0 then
					layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.updateAll)).onTouch = function()
						local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, "")
						container.layout:setCellFitting(2, 1, false, false)

						local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 40, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))

						for i = 1, #result do
							container.label.text = localization.downloading .. " " .. result[i].publication_name
							progressBar.value = math.round(i / #result * 100)
							MineOSInterface.OSDraw()

							local publication = fieldAPIRequest("result", "publication", {
								file_id = result[i].file_id,
								language_id = config.language_id,
							})
							
							fileVersions[publication.file_id].version = publication.version
							tryToDownload(publication.source_url, fileVersions[publication.file_id].path)

							if publication then
								if publication.dependencies then
									for j = 1, #publication.all_dependencies do
										local dependency = publication.dependencies_data[publication.all_dependencies[j]]
										if not dependency.publication_name then
											container.label.text = localization.downloading .. " " .. dependency.path
											MineOSInterface.OSDraw()
											
											if getUpdateState(publication.all_dependencies[j], dependency.version) < 4 then
												local dependencyPath = getDependencyPath(fileVersions[publication.file_id].path, dependency)
												
												fileVersions[publication.all_dependencies[j]] = {
													path = dependencyPath,
													version = dependency.version,
												}

												tryToDownload(dependency.source_url, dependencyPath)
											else
												os.sleep(0.05)
											end
										end
									end
								end
							end
						end

						container:delete()
						saveFileVersions()
						computer.shutdown(true)
					end
				end
			else
				local input = layout:addChild(GUI.input(1, 1, 20, layout.height, 0xFFFFFF, 0x2D2D2D, 0x696969, 0xFFFFFF, 0x2D2D2D, search or "", localization.search, true))
				input.onInputFinished = function()
					if #input.text == 0 then
						search = nil
					else
						search = input.text
					end

					currentPage = 0
					updateFileList(category_id, updates)
				end

				local orderByComboBox = layout:addChild(GUI.comboBox(1, 1, 20, layout.height, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
				orderByComboBox:addItem(localization.byPopularity)
				orderByComboBox:addItem(localization.byRating)
				orderByComboBox:addItem(localization.byName)
				orderByComboBox:addItem(localization.byDate)
				
				orderByComboBox.selectedItem = config.orderBy

				local orderDirectionComboBox = layout:addChild(GUI.comboBox(1, 1, 18, layout.height, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
				orderDirectionComboBox:addItem(localization.desc)
				orderDirectionComboBox:addItem(localization.asc)
				orderDirectionComboBox.selectedItem = config.orderDirection

				orderByComboBox.onItemSelected = function()
					config.orderBy = orderByComboBox.selectedItem
					config.orderDirection = orderDirectionComboBox.selectedItem
					updateFileList(category_id, updates)
					saveConfig()
				end
				orderDirectionComboBox.onItemSelected = orderByComboBox.onItemSelected

				if user.token then
					layout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.publish)).onTouch = function()
						editPublication(nil, category_id)
					end
				end
			end

			y = y + layout.height + 1

			local navigationLayout = contentContainer:addChild(GUI.layout(1, contentContainer.height - 1, contentContainer.width, 1, 1, 1))
			navigationLayout:setCellDirection(1, 1, GUI.directions.horizontal)
			navigationLayout:setCellSpacing(1, 1, 2)

			local function switchPage(forward)
				currentPage = currentPage + (forward and 1 or -1)
				updateFileList(category_id, updates)
			end

			local backButton = navigationLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xFFFFFF, 0x696969, 0xA5A5A5, 0xFFFFFF, "<"))
			backButton.colors.disabled.background = 0xE1E1E1
			backButton.colors.disabled.text = 0xC3C3C3
			backButton.disabled = currentPage == 0
			backButton.onTouch = function()
				switchPage(false)
			end

			navigationLayout:addChild(GUI.text(1, 1, 0x696969, localization.page .. " " .. (currentPage + 1)))
			local nextButton = navigationLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xFFFFFF, 0x696969, 0xA5A5A5, 0xFFFFFF, ">"))
			nextButton.colors.disabled = backButton.colors.disabled
			nextButton.disabled = #result <= appsPerPage
			nextButton.onTouch = function()
				switchPage(true)
			end

			local xStart = math.floor(1 + contentContainer.width / 2 - (appsPerWidth * (appWidth + appHSpacing) - appHSpacing) / 2)
			local x, counter = xStart, 1
			for i = 1, #result do
				contentContainer:addChild(newApplicationPreview(x, y, result[i]))
				
				if counter >= appsPerPage then
					break
				elseif counter % appsPerWidth == 0 then
					x, y = xStart, y + appHeight + appVSpacing
				else
					x = x + appWidth + appHSpacing
				end
				counter = counter + 1

				MineOSInterface.OSDraw()
			end
		else
			showLabelAsContent(localization.noUpdates)
		end
	end

	activity()
end

--------------------------------------------------------------------------------

local function account()
	lastMethod, lastArguments = account, {}

	local function logout()
		user = {}
		saveUser()
		account()
	end

	local function addAccountShit(login, register, recover)
		contentContainer:deleteChildren()
		local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))
		
		layout:addChild(GUI.label(1, 1, 36, 1, 0x0, login and localization.login or register and localization.createAccount or recover and localization.changePassword)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
		local nameInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", localization.nickname))
		local emailInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", login and localization.nicknameOrEmail or "E-mail"))
		local currentPasswordInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", localization.currentPassword, false, "*"))
		local passwordInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", recover and localization.newPassword or localization.password, false, "*"))

		local singleSessionSwitchAndLabel = layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xC3C3C3, 0xFFFFFF, 0xA5A5A5, localization.singleSession .. ":", config.singleSession))

		layout:addChild(GUI.button(1, 1, 36, 3, 0xA5A5A5, 0xFFFFFF, 0x696969, 0xFFFFFF, "OK")).onTouch = function()
			activity(true)

			if login then
				local result = fieldAPIRequest("result", "login", {
					[(string.find(emailInput.text, "@") and "email" or "name")] = emailInput.text,
					password = passwordInput.text
				})

				if result then
					user = {
						token = result.token,
						name = result.name,
						id = result.id,
						email = result.email,
						timestamp = result.timestamp,
					}

					account()

					config.singleSession = singleSessionSwitchAndLabel.switch.state
					if not config.singleSession then
						saveUser()
					end
					saveConfig()
				end
			elseif register then
				local result = fieldAPIRequest("result", "register", {
					name = nameInput.text,
					email = emailInput.text,
					password = passwordInput.text,
				})

				if result then
					showLabelAsContent(localization.registrationSuccessfull)
				end
			else
				local success, reason = RawAPIRequest("change_password", {
					email = user.email,
					current_password = currentPasswordInput.text,
					new_password = passwordInput.text,
				})

				if success then
					logout()
				else
					GUI.error(reason)
				end
			end

			activity()
		end

		if login then
			local registerLayout = layout:addChild(GUI.layout(1, 1, layout.width, 1, 1, 1))
			registerLayout:setCellDirection(1, 1, GUI.directions.horizontal)
			registerLayout:addChild(GUI.text(1, 1, 0xA5A5A5, localization.notRegistered))
			registerLayout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x696969, nil, 0x0, localization.createAccount)).onTouch = function()
				addAccountShit(false, true, false)
			end
		end

		currentPasswordInput.hidden = not recover
		emailInput.hidden = recover
		nameInput.hidden = login or recover
		singleSessionSwitchAndLabel.hidden = not login
	end

	if user.token then
		activity(true)

		local result = fieldAPIRequest("result", "publications", {
			user_name = user.name,
			order_by = "name",
			order_direction = "asc",
		})

		if result then
			contentContainer:deleteChildren()
			local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))

			layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.profile))

			layout:addChild(newKeyValueWidget(1, 1, 36, 0x4B4B4B, 0x878787, localization.nickname, ": " .. user.name))
			layout:addChild(newKeyValueWidget(1, 1, 36, 0x4B4B4B, 0x878787, "E-Mail", ": " .. user.email))
			layout:addChild(newKeyValueWidget(1, 1, 36, 0x4B4B4B, 0x878787, localization.registrationDate, ": " .. os.date("%d.%m.%Y", user.timestamp)))

			local buttonsLayout = layout:addChild(newButtonsLayout(1, 1, layout.width, 2))
			
			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.changePassword)).onTouch = function()
				addAccountShit(false, false, true)
			end

			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.clearCache)).onTouch = function()
				for file in fs.list(iconCachePath) do
					fs.remove(iconCachePath .. file)
				end
			end

			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.exit)).onTouch = function()
				logout()
			end

			layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.language))

			local languageComboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
			for key, value in pairs(languages) do
				languageComboBox:addItem(value).onTouch = function()
					config.language_id = key
					saveConfig()
				end

				if key == config.language_id then
					languageComboBox.selectedItem = languageComboBox:count()
				end
			end

			if #result > 0 then
				layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.publications))

				local comboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x696969, 0x969696, 0xE1E1E1))
				for i = 1, #result do
					comboBox:addItem(result[i].publication_name)
				end

				local buttonsLayout = layout:addChild(newButtonsLayout(1, 1, layout.width, 2))
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.open)).onTouch = function()
					newPublicationInfo(result[comboBox.selectedItem].file_id)
				end

				local function editOrDelete(edit)
					activity(true)

					local result = fieldAPIRequest("result", "publication", {
						file_id = result[comboBox.selectedItem].file_id,
						language_id = config.language_id,
					})

					if result then
						if edit then
							editPublication(result)
						else
							deletePublication(result)
						end
					end

					activity()
				end

				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.edit)).onTouch = function()
					editOrDelete(true)
				end
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.remove)).onTouch = function()
					editOrDelete(false)
				end
			end
		end

		activity()
	else
		addAccountShit(true, false, false)
	end
end

local function loadCategory(category_id, updates)
	currentPage, search = 0, nil
	updateFileList(category_id, updates)
end

--------------------------------------------------------------------------------

local function statistics()
	lastMethod, lastArguments = statistics, {}

	activity(true)

	local statistics = fieldAPIRequest("result", "statistics")
	if statistics then
		MineOSInterface.OSDraw()

		local publications = fieldAPIRequest("result", "publications", {
			order_by = "popularity",
			order_direction = "desc",
			offset = 0,
			count = overviewIconsCount + 1,
			category_id = 1,
		})

		if publications then
			contentContainer:deleteChildren()

			local iconsContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))

			local width = 40
			local container = contentContainer:addChild(GUI.container(math.floor(contentContainer.width / 2 - width / 2), 1, width, contentContainer.height))
			container:addChild(GUI.panel(1, 1, container.width, container.height, 0xFFFFFF))
			local statisticsLayout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))

			statisticsLayout:addChild(GUI.image(1, 1, image.load(resourcesPath .. "Icon.pic"))).height = 5
			statisticsLayout:addChild(newKeyValueWidget(1, 1, container.width - 8, 0x4B4B4B, 0xA5A5A5, localization.statisticsUsersCount, ": " .. statistics.users_count))
			statisticsLayout:addChild(newKeyValueWidget(1, 1, container.width - 8, 0x4B4B4B, 0xA5A5A5, localization.statisticsNewUser, ": " .. statistics.last_registered_user))
			statisticsLayout:addChild(newKeyValueWidget(1, 1, container.width - 8, 0x4B4B4B, 0xA5A5A5, localization.statisticsMostPopularUser, ": " .. statistics.most_popular_user))
			statisticsLayout:addChild(newKeyValueWidget(1, 1, container.width - 8, 0x4B4B4B, 0xA5A5A5, localization.statisticsPublicationsCount, ": " .. statistics.publications_count))
			statisticsLayout:addChild(newKeyValueWidget(1, 1, container.width - 8, 0x4B4B4B, 0xA5A5A5, localization.statisticsReviewsCount, ": " .. statistics.reviews_count))
			
			local applicationPreview = statisticsLayout:addChild(newApplicationPreview(1, 1, publications[1]))
			applicationPreview.panel.colors.background = 0xF0F0F0
			statisticsLayout:addChild(GUI.label(1, 1, statisticsLayout.width, 1, 0xA5A5A5, localization.statisticsPopularPublication)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.center)

			MineOSInterface.OSDraw()

			local uptime, newUptime = computer.uptime()
			local function tick()
				newUptime = computer.uptime()
				if newUptime - uptime > overviewAnimationDelay then
					uptime = newUptime

					local child
					for i = 1, #iconsContainer.children do
						child = iconsContainer.children[i]
						
						child.moveX, child.moveY = child.moveX + child.forceX, child.moveY + child.forceY
							
						if child.forceX > 0 then
							if child.forceX > overviewForceLimit then
								child.forceX = child.forceX - overviewForceDecay
							else
								child.forceX = overviewForceLimit
							end
						else
							if child.forceX < -overviewForceLimit then
								child.forceX = child.forceX + overviewForceDecay
							else
								child.forceX = -overviewForceLimit
							end
						end

						if child.forceY > 0 then
							if child.forceY > overviewForceLimit then
								child.forceY = child.forceY - overviewForceDecay
							else
								child.forceY = overviewForceLimit
							end
						else
							if child.forceY < -overviewForceLimit then
								child.forceY = child.forceY + overviewForceDecay
							else
								child.forceY = -overviewForceLimit
							end
						end

						if child.moveX <= 1 then
							child.forceX, child.moveX = -child.forceX, 1
						elseif child.moveX + child.width - 1 >= iconsContainer.width then
							child.forceX, child.moveX = -child.forceX, iconsContainer.width - child.width + 1
						end

						if child.moveY <= 1 then
							child.forceY, child.moveY = -child.forceY, 1
						elseif child.moveY + child.height - 1 >= iconsContainer.height then
							child.forceY, child.moveY = -child.forceY, iconsContainer.height - child.height + 1
						end

						child.localX, child.localY = math.floor(child.moveX), math.floor(child.moveY)
					end

					MineOSInterface.OSDraw()

					return true
				end
			end

			iconsContainer.eventHandler = function(mainContainer, object, eventData)
				if eventData[1] == "touch" or eventData[1] == "drag" then
					local child, deltaX, deltaY, vectorLength
					for i = 1, #iconsContainer.children do
						child = iconsContainer.children[i]
						
						deltaX, deltaY = eventData[3] - child.x, eventData[4] - child.y
						vectorLength = math.sqrt(deltaX ^ 2 + deltaY ^ 2)
						if vectorLength > 0 then
							child.forceX = deltaX / vectorLength * math.random(overviewMaximumTouchAcceleration)
							child.forceY = deltaY / vectorLength * math.random(overviewMaximumTouchAcceleration)
						end
					end
				end

				tick()
			end

			local function makeBlyad(object)
				object.localX = math.random(1, iconsContainer.width - object.width + 1)
				object.localY = math.random(1, iconsContainer.height - object.width + 1)
				object.moveX = object.localX
				object.moveY = object.localY
				object.forceX = math.random(-100, 100) / 100 * overviewForceLimit
				object.forceY = math.random(-100, 100) / 100 * overviewForceLimit
				
				if not tick() then
					MineOSInterface.OSDraw()
				end
			end

			for i = 2, #publications do
				makeBlyad(iconsContainer:addChild(GUI.image(1, 1, getPublicationIcon(publications[i])), 1))
			end
		end
	end

	activity()
end

--------------------------------------------------------------------------------

window.tabBar:addItem(localization.categoryOverview).onTouch = function()
	statistics()
end

for i = 1, #categories do
	window.tabBar:addItem(categories[i]).onTouch = function()
		loadCategory(i)
	end
end

window.tabBar:addItem(localization.categoryUpdates).onTouch = function()
	loadCategory(nil, true)
end

window.tabBar:addItem(localization.categoryAccount).onTouch = function()
	account()
end

window.onResize = function(width, height)
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height - 3
	contentContainer.width = width
	contentContainer.height = window.backgroundPanel.height
	window.tabBar.width = width

	activityWidget.localX = window.width - activityWidget.width

	appsPerWidth = math.floor((contentContainer.width + appHSpacing) / (appWidth + appHSpacing))
	appsPerHeight = math.floor((contentContainer.height - 6 + appVSpacing) / (appHeight + appVSpacing))
	appsPerPage = appsPerWidth * appsPerHeight
	currentPage = 0

	contentContainer:deleteChildren()
	callLastMethod()
end

--------------------------------------------------------------------------------

loadConfig()

if args[1] == "updates" then
	lastMethod, lastArguments = updateFileList, {nil, true}
	window.tabBar.selectedItem = #categories + 2
else
	lastMethod, lastArguments = statistics, {}
end

window:resize(window.width, window.height)