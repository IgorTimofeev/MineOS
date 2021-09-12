
local internet = require("Internet")
local GUI = require("GUI")
local screen = require("Screen")
local system = require("System")
local paths = require("Paths")
local image = require("Image")
local filesystem = require("Filesystem")
local color = require("Color")
local number = require("Number")
local text = require("Text")
local event = require("Event")

--------------------------------------------------------------------------------

local host = "http://mineos.modder.pw/MineOSAPI/2.04/"
local iconCheckReponseTime = 2

local overviewIconsCount = 14
local overviewAnimationDelay = 0.05
local overviewForceDecay = 0.15
local overviewForceLimit = 0.5
local overviewMaximumTouchAcceleration = 5

local appMarketPath = paths.user.applicationData .. "App Market/"
local configPath = appMarketPath .. "Config.cfg"
local userPath = appMarketPath .. "User.cfg"
local iconCachePath = appMarketPath .. "Cache/"

local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/") 

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
	paths.system.applications,
	paths.system.libraries,
	"/",
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

filesystem.makeDirectory(iconCachePath)

local luaIcon = image.load(currentScriptDirectory .. "Icons/Lua.pic")
local fileNotExistsIcon = image.load(currentScriptDirectory .. "Icons/FileNotExists.pic")
local scriptIcon = image.load(currentScriptDirectory .. "Icons/Script.pic")

local search = ""
local appWidth, appHeight, appHSpacing, appVSpacing, currentPage, appsPerPage, appsPerWidth, appsPerHeight = 32, 6, 2, 1, 0
local config, userVersions, systemVersions, user
local updateFileList, editPublication, messagesItem

--------------------------------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 127, 33, 0xF0F0F0))

local leftListPanel = system.addBlurredOrDefaultPanel(window, 1, 1, 23, 1)

local leftList = window:addChild(GUI.list(1, 4, leftListPanel.width, 1, 3, 0, nil, 0x787878, nil, 0x787878, 0xF0F0F0, 0x2D2D2D, false))

local contentContainer = window:addChild(GUI.container(1, 1, 1, 1))

local sponsoredLabel = window:addChild(GUI.text(2, 1, 0x3C3C3C, "Sponsored by McModder"))

local progressIndicator = window:addChild(GUI.progressIndicator(math.floor(leftListPanel.width / 2 - 1), 1, 0x3C3C3C, 0x00B640, 0x99FF80))

window.actionButtons.localX = 3
window.actionButtons:moveToFront()

--------------------------------------------------------------------------------

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

local function saveVersions()
	filesystem.writeTable(paths.system.versions, systemVersions, true)
	filesystem.writeTable(paths.user.versions, userVersions, true)
end

local function saveUser()
	filesystem.writeTable(userPath, user)
end

local function loadConfig()
	local function loadVersions(path)
		if filesystem.exists(path) then
			return filesystem.readTable(path)
		else
			return {}
		end
	end

	userVersions = loadVersions(paths.user.versions)
	systemVersions = loadVersions(paths.system.versions)

	if filesystem.exists(userPath) then
		user = filesystem.readTable(userPath)
	else
		user = {}
	end

	if filesystem.exists(configPath) then
		config = filesystem.readTable(configPath)
	else
		config = {
			language_id = 18,
			orderBy = 4,
			orderDirection = 1,
			singleSession = false,
		}
	end

	messagesItem.hidden = not user.token
end

--------------------------------------------------------------------------------

local function RawAPIRequest(script, postData, notUnserialize)
	progressIndicator.active = true
	workspace:draw()

	local data = ""
	local success, reason = internet.rawRequest(
		host .. script .. ".php",
		postData and internet.serialize(postData) or nil,
		{["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.119 Safari/537.36"},
		function(chunk)
			data = data .. chunk
			
			progressIndicator:roll()
			workspace:draw()
		end,
		math.huge
	)

	progressIndicator.active = false
	workspace:draw()


	if success then
		if not notUnserialize then
			local unserializeResult, unserializeReason = text.deserialize(data)
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
		return false, "Web request failed: " .. tostring(reason)
	end
end

local function fieldAPIRequest(fieldToReturn, script, data)
	local success, reason = RawAPIRequest(script, data)
	if success then
		if success[fieldToReturn] then
			return success[fieldToReturn]
		else
			GUI.alert("Request was successful, but field " .. tostring(fieldToReturn) .. " doesn't exists")
		end
	else
		GUI.alert(reason)
	end
end

local function checkContentLength(url)
	local handle = component.get("internet").request(url)
	if handle then
		local deadline, _, _, responseData = computer.uptime() + iconCheckReponseTime
		repeat
			_, _, responseData = handle:response()
		until responseData or computer.uptime() >= deadline

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
				progressIndicator:roll()
				workspace:draw()

				if needCheck and #data > 8 then
					if data:sub(1, 4) == "OCIF" then
						local encodingMethod = string.byte(data:sub(5, 5))

						if encodingMethod >= 6 or encodingMethod <= 8 then
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
	local success, reason = internet.download(...)
	if not success then
		GUI.alert(reason)
	end

	return success
end

--------------------------------------------------------------------------------

local lastMethod, lastArguments
local function callLastMethod()
	lastMethod(table.unpack(lastArguments))
end

local function showLabelAsContent(container, text)
	container:removeChildren()
	container:addChild(GUI.label(1, 1, container.width, container.height, 0x2D2D2D, text)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
end

local function newButtonsLayout(x, y, width, spacing)
	local buttonsLayout = GUI.layout(x, y, width, 1, 1, 1)
	buttonsLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	buttonsLayout:setSpacing(1, 1, spacing)

	return buttonsLayout
end

local function getVersionsTable(file_id)
	if systemVersions[file_id] then
		return systemVersions
	else
		return userVersions
	end
end

local function getUpdateState(file_id, version)
	local versionsTable = getVersionsTable(file_id)
	if versionsTable[file_id] then
		if filesystem.exists(versionsTable[file_id].path) then
			if versionsTable[file_id].version >= version then
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
		screen.drawText(object.x + x, object.y, object.rating >= i and object.colors.first or object.colors.second, "*")
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
	local container = GUI.addBackgroundContainer(workspace, true, true, localization.areYouSure)
	local buttonsLayout = container.layout:addChild(newButtonsLayout(1, 1, container.layout.width, 3))
	
	buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xE1E1E1, 0x2D2D2D, 0x0, 0xE1E1E1, localization.yes)).onTouch = function()
		local success, reason = RawAPIRequest("delete", {
			token = user.token,
			file_id = publication.file_id,
		})

		if success then		
			container:remove()			
			updateFileList(publication.category_id)
		else
			GUI.alert(reason)
		end
	end

	buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xA5A5A5, 0x2D2D2D, 0x0, 0xE1E1E1, localization.no)).onTouch = function()
		container:remove()
		workspace:draw()
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

	return filesystem.removeSlashes(path)
end

local function download(publication)
	if not publication.translated_description then
		publication = fieldAPIRequest("result", "publication", {
			file_id = publication.file_id,
			language_id = config.language_id,
		})
	end

	if publication then
		local container = GUI.addBackgroundContainer(workspace, true, true, localization.choosePath)

		local versionsTable = getVersionsTable(publication.file_id)
		local filesystemChooserPath = versionsTable[publication.file_id] and getApplicationPathFromVersions(versionsTable[publication.file_id].path)
		if not filesystemChooserPath then
			if publication.category_id == 1 then
				filesystemChooserPath = downloadPaths[publication.category_id] .. publication.publication_name .. ".app"
			else
				filesystemChooserPath = downloadPaths[publication.category_id] .. publication.path
			end
		end

		local filesystemChooser = container.layout:addChild(GUI.filesystemChooser(1, 1, 44, 3, 0xE1E1E1, 0x2D2D2D, 0x4B4B4B, 0x969696, filesystemChooserPath, localization.save, localization.cancel, localization.fileName, "/"))
		filesystemChooser:setMode(GUI.IO_MODE_SAVE, GUI.IO_MODE_FILE)

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
				
				for blyad in filesystem.path(dependencyPath):gmatch("[^/]+") do
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
						tree:addItem(filesystem.name(devka.path), devka.path, offset, false)
					else
						tree:addItem(chlen, chlen, offset, true)
						tree.expandedItems[chlen] = true

						pizda(devka, offset + 2, initPath .. chlen .. "/")
					end
				end
			end

			pizda(dependencyTree, 1, "")
		end

		local shortcutSwitchAndLabel = container.layout:addChild(GUI.switchAndLabel(1, 1, 44, 6, 0x66DB80, 0x0, 0xE1E1E1, 0x878787, localization.createShortcut .. ":", true))
		shortcutSwitchAndLabel.hidden = publication.category_id == 2

		container.layout:addChild(GUI.button(1, 1, 44, 3, 0x696969, 0xFFFFFF, 0x0, 0xFFFFFF, localization.download)).onTouch = function()
			container.layout:removeChildren(2)
			local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 40, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))
				
			local countOfShit = 1 + (publication.all_dependencies and #publication.all_dependencies or 0)
			
			local function govnoed(pizda, i)
				container.label.text = localization.downloading .. " " .. filesystem.name(pizda.path)
				progressBar.value = math.floor(i / countOfShit * 100)
				workspace:draw()
			end

			-- SAVED
			versionsTable[publication.file_id] = {
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
						versionsTable[publication.all_dependencies[i]] = {
							path = dependencyPath,
							version = dependency.version,
						}
						tryToDownload(dependency.source_url, dependencyPath)
					else
						event.sleep(0.05)
					end
				end
			end

			container:remove()
			callLastMethod()

			if not shortcutSwitchAndLabel.hidden and shortcutSwitchAndLabel.switch.state then
				system.createShortcut(paths.user.desktop .. filesystem.hideExtension(filesystem.name(filesystemChooser.path)), filesystemChooser.path .. "/")
			end
			
			computer.pushSignal("system", "updateFileList")
			saveVersions()
		end

		filesystemChooser.onSubmit = updateTree
		updateTree()
	end
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

		if filesystem.exists(path) then
			return loadImage(path)
		else
			progressIndicator.active = true
			workspace:draw()

			local data, reason = checkImage(publication.icon_url)

			progressIndicator.active = false
			workspace:draw()

			if data then
				filesystem.write(path, data)

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
	container.nameLabel = container:addChild(GUI.text(13, 2, 0x0, text.limit(publication.publication_name, limit, "right")))
	container.developerLabel = container:addChild(GUI.text(13, 3, 0x878787, text.limit("©" .. publication.user_name, limit, "right")))
	container.rating = container:addChild(newRatingWidget(13, 4, publication.average_rating and number.round(publication.average_rating) or 0))

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
			local versionsTable = getVersionsTable(publication.file_id)
			filesystem.remove(getApplicationPathFromVersions(versionsTable[publication.file_id].path))
			filesystem.remove(paths.user.desktop .. publication.publication_name .. ".lnk")
			versionsTable[publication.file_id] = nil
			
			callLastMethod()
			computer.pushSignal("system", "updateFileList")
			saveVersions()
		end
	end
end

local function containerScrollEventHandler(workspace, object, e1, e2, e3, e4, e5)
	if e1 == "scroll" then
		local first, last = object.children[1], object.children[#object.children]
		
		if e5 == 1 then
			if first.localY < 2 then
				for i = 1, #object.children do
					object.children[i].localY = object.children[i].localY + 1
				end
				workspace:draw()
			end
		else
			if last.localY + last.height - 1 >= object.height then
				for i = 1, #object.children do
					object.children[i].localY = object.children[i].localY - 1
				end
				workspace:draw()
			end
		end
	end
end

local newApplicationPreview, newPublicationInfo

local function applicationWidgetEventHandler(workspace, object, e1)
	if e1 == "touch" then
		object.parent.panel.colors.background = 0xE1E1E1
		workspace:draw()
		newPublicationInfo(object.parent.file_id)
	end
end

newApplicationPreview = function(x, y, publication)
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

local function overview()
	leftList.selectedItem = 1
	lastMethod, lastArguments = overview, {}

	local statistics = fieldAPIRequest("result", "statistics")
	if statistics then
		local publications = fieldAPIRequest("result", "publications", {
			order_by = "popularity",
			order_direction = "desc",
			offset = 0,
			count = overviewIconsCount + 1,
			category_id = 1,
		})

		if publications then
			contentContainer:removeChildren()

			local iconsContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))

			local width = appWidth + 4
			local container = contentContainer:addChild(GUI.container(math.floor(contentContainer.width / 2 - width / 2), 1, width, contentContainer.height))
			container:addChild(GUI.panel(1, 1, container.width, container.height, 0xFFFFFF))
			
			local statisticsLayout = container:addChild(GUI.layout(1, 1, container.width, container.height, 1, 1))

			statisticsLayout:addChild(GUI.image(1, 1, image.load(currentScriptDirectory .. "Icon.pic"))).height = 5
			
			local textLayout = statisticsLayout:addChild(GUI.layout(1, 1, container.width - 4, 1, 1, 1))
			textLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

			local function add(key, value)
				textLayout:addChild(GUI.keyAndValue(1, 1, 0x4B4B4B, 0xA5A5A5, key, ": " .. value))
			end

			add(localization.statisticsUsersCount, statistics.users_count)
			add(localization.statisticsNewUser, statistics.last_registered_user)
			add(localization.statisticsMostPopularUser, statistics.most_popular_user)
			add(localization.statisticsPublicationsCount, statistics.publications_count)
			add(localization.statisticsReviewsCount, statistics.reviews_count)
			add(localization.statisticsMessagesCount, statistics.messages_count)
			
			textLayout.height = #textLayout.children * 2

			local applicationPreview = statisticsLayout:addChild(newApplicationPreview(1, 1, publications[1]))
			applicationPreview.panel.colors.background = 0xF0F0F0
			statisticsLayout:addChild(GUI.label(1, 1, statisticsLayout.width, 1, 0xA5A5A5, localization.statisticsPopularPublication)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)

			workspace:draw()

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

					workspace:draw()

					return true
				end
			end

			iconsContainer.eventHandler = function(workspace, object, e1, e2, e3, e4)
				if e1 == "touch" or e1 == "drag" then
					local child, deltaX, deltaY, vectorLength
					for i = 1, #iconsContainer.children do
						child = iconsContainer.children[i]
						
						deltaX, deltaY = e3 - child.x, e4 - child.y
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
					workspace:draw()
				end
			end

			for i = 2, #publications do
				makeBlyad(iconsContainer:addChild(GUI.image(1, 1, getPublicationIcon(publications[i])), 1))
			end
		end
	end
end

local function settings()
	local function logout()
		user = {}
		saveUser()
		settings()
	end

	local function addAccountShit(login, register, recover)
		contentContainer:removeChildren()
		
		local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))
		
		layout:addChild(GUI.label(1, 1, 36, 1, 0x0, login and localization.login or register and localization.createAccount or recover and localization.changePassword)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
		local nameInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", localization.nickname))
		local emailInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", login and localization.nicknameOrEmail or "E-mail"))
		local currentPasswordInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", localization.currentPassword, false, "*"))
		local passwordInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", recover and localization.newPassword or localization.password, false, "*"))

		local singleSessionSwitchAndLabel = layout:addChild(GUI.switchAndLabel(1, 1, 36, 6, 0x66DB80, 0xC3C3C3, 0xFFFFFF, 0xA5A5A5, localization.singleSession .. ":", config.singleSession))

		layout:addChild(GUI.button(1, 1, 36, 3, 0xA5A5A5, 0xFFFFFF, 0x696969, 0xFFFFFF, "OK")).onTouch = function()
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

					settings()

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
					showLabelAsContent(contentContainer, localization.registrationSuccessfull)
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
					GUI.alert(reason)
				end
			end
		end

		if login then
			local registerLayout = layout:addChild(GUI.layout(1, 1, layout.width, 1, 1, 1))
			registerLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
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

	messagesItem.hidden = not user.token

	if user.token then
		local result = fieldAPIRequest("result", "publications", {
			user_name = user.name,
			order_by = "name",
			order_direction = "asc",
		})

		if result then
			contentContainer:removeChildren()
			local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))

			layout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.profile))

			local textLayout = layout:addChild(GUI.layout(1, 1, 36, 5, 1, 1))
			textLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
			
			textLayout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0x969696, localization.nickname, ": " .. user.name))
			textLayout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0x969696, "E-Mail", ": " .. user.email))
			textLayout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0x969696, localization.registrationDate, ": " .. os.date("%d.%m.%Y", user.timestamp)))
			textLayout.height = #textLayout.children * 2 - 1

			local buttonsLayout = layout:addChild(newButtonsLayout(1, 1, layout.width, 2))
			
			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.changePassword)).onTouch = function()
				addAccountShit(false, false, true)
			end

			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.exit)).onTouch = function()
				logout()
			end

			buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.clearCache)).onTouch = function()
				local list = filesystem.list(iconCachePath)
				for i = 1, #list do
					filesystem.remove(iconCachePath .. list[i])
				end
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

				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.edit)).onTouch = function()
					local result = fieldAPIRequest("result", "publication", {
						file_id = result[comboBox.selectedItem].file_id,
						language_id = config.language_id,
					})

					if result then
						editPublication(result)
					end
				end
			end
		end
	else
		addAccountShit(true, false, false)
		workspace:draw()
	end
end

local function dialogGUI(to_user_name)
	local messages
	if to_user_name then
		local result = fieldAPIRequest("result", "messages", {
			token = user.token,
			user_name = to_user_name
		})

		if result then
			messages = result
		end
	end
	messages = messages or {}

	contentContainer:removeChildren()

	local button = contentContainer:addChild(GUI.adaptiveButton(1, contentContainer.height - 2, 2, 1, 0x4B4B4B, 0xE1E1E1, 0x2D2D2D, 0xE1E1E1, localization.send))
	button.localX = contentContainer.width - button.width + 1
	button.colors.disabled.background = 0xB4B4B4
	button.colors.disabled.text = 0xFFFFFF
	button.disabled = true

	local input = contentContainer:addChild(GUI.input(1, button.localY, contentContainer.width - button.width, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", localization.typeMessageText))

	local function check()
		button.disabled = not (to_user_name and #input.text > 0)
	end

	input.onInputFinished = check

	button.onTouch = function()
		local success, reason = RawAPIRequest("message", {
			token = user.token,
			user_name = to_user_name,
			text = input.text
		})

		if success then
			dialogGUI(to_user_name)
		else
			GUI.alert(reason)
		end
	end

	local messagesContainer = contentContainer:addChild(GUI.container(1, 4, contentContainer.width, contentContainer.height - 6))
	messagesContainer.eventHandler = containerScrollEventHandler

	local panel = contentContainer:addChild(GUI.panel(1, 1, contentContainer.width, 3, 0xFFFFFF))
	if not to_user_name then
		panel.colors.transparency = nil
		local text = contentContainer:addChild(GUI.text(3, 2, 0x0, localization.toWho))
		local input = contentContainer:addChild(GUI.input(text.localX + text.width, 1, contentContainer.width - text.width - 4, 3, 0xFFFFFF, 0x878787, 0xC3C3C3, 0xFFFFFF, 0x878787, to_user_name or "", localization.typeUserName))
		input.onInputFinished = function()
			to_user_name = input.text
			check()
		end
	else
		local keyAndValue = contentContainer:addChild(GUI.keyAndValue(1, 2, 0x878787, 0x0, localization.dialogWith, to_user_name))
		keyAndValue.localX = math.floor(contentContainer.width / 2 - (keyAndValue.keyLength + keyAndValue.valueLength) / 2)
		-- contentContainer:addChild(GUI.label(1, 2, contentContainer.width, 1, 0x2D2D2D, to_user_name)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
	end

	local function cloudDraw(object)
		local backgroundColor, textColor = object.me and 0x6692FF or 0xFFFFFF, object.me and 0xFFFFFF or 0x4B4B4B
		
		screen.drawRectangle(object.x, object.y, object.width, object.height, backgroundColor, textColor, " ")
		screen.drawText(object.x, object.y - 1, backgroundColor, "⢀" .. string.rep("⣀", object.width - 2) .. "⡀")
		screen.drawText(object.x, object.y + object.height, backgroundColor, "⠈" .. string.rep("⠉", object.width - 2) .. "⠁")

		local date = os.date("%d.%m.%Y, %H:%M", object.timestamp)
		if object.me then
			screen.drawText(object.x - #date - 1, object.y, 0xC3C3C3, date)
			screen.drawText(object.x + object.width, object.y + object.height - 1, backgroundColor, "◤")
		else
			screen.drawText(object.x + object.width + 1, object.y, 0xC3C3C3, date)
			screen.drawText(object.x - 1, object.y + object.height - 1, backgroundColor, "◥")
		end

		for i = 1, #object.lines do
			screen.drawText(object.x + 1, object.y + i - 1, textColor, object.lines[i])
		end
	end

	local function newCloud(y, width, cloudText, me, timestamp)
		local lines = text.wrap(cloudText, width - 2)
		local object = GUI.object(me and messagesContainer.width - width - 1 or 3, y - #lines + 1, width, 1)
		
		object.lines = lines
		object.height = #lines
		object.me = me
		object.text = cloudText
		object.draw = cloudDraw
		object.timestamp = timestamp

		return object
	end

	local y = messagesContainer.height - 1
	for j = 1, #messages do
		local cloud = messagesContainer:addChild(newCloud(y, math.floor(messagesContainer.width * 0.6), tostring(messages[j].text), messages[j].user_name == user.name, messages[j].timestamp), 1)
		y = y - cloud.height - 2
	end

	-- Пустой объект для прокрутки ниже этой прозрачной пизды
	messagesContainer:addChild(GUI.object(1, y, 1, 2), 1)
end

local function dialogs()
	local dialogs = fieldAPIRequest("result", "dialogs", {
		token = user.token,
	})

	if dialogs then
		contentContainer:removeChildren()

		local dialogsContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))
		dialogsContainer.eventHandler = containerScrollEventHandler

		local sendMessageButton = dialogsContainer:addChild(GUI.adaptiveRoundedButton(1, #dialogs > 0 and 2 or math.floor(dialogsContainer.height / 2 + 1), 2, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.newMessage))
		sendMessageButton.localX = math.floor(dialogsContainer.width / 2 - sendMessageButton.width / 2)
		sendMessageButton.onTouch = function()
			dialogGUI()
		end

		if #dialogs > 0 then
			local y = sendMessageButton.localY + 2

			for i = 1, #dialogs do
				local backgroundColor, nicknameColor, timestampColor, textColor = 0xFFFFFF, 0x0, 0xD2D2D2, 0x969696
				if dialogs[i].last_message_is_read == 0 and dialogs[i].last_message_user_name ~= user.name then
					backgroundColor, nicknameColor, timestampColor, textColor = 0xCCDBFF, 0x0, 0xB4B4B4, 0x878787
				end

				local dialogContainer = dialogsContainer:addChild(GUI.container(3, y, dialogsContainer.width - 4, 4))
				addPanel(dialogContainer,backgroundColor)
				
				dialogContainer:addChild(GUI.keyAndValue(3, 2, nicknameColor, timestampColor, dialogs[i].dialog_user_name, os.date(" (%d.%m.%Y, %H:%M)", dialogs[i].timestamp)))
				dialogContainer:addChild(GUI.text(3, 3, textColor, text.limit((dialogs[i].last_message_user_name == user.name and localization.yourText .. " " or "") .. dialogs[i].text, dialogContainer.width - 4, "right")))

				dialogContainer.eventHandler = function(workspace, object, e1)
					if e1 == "touch" then
						dialogContainer.panel.colors.background = 0xE1E1E1
						dialogGUI(dialogs[i].dialog_user_name)
					end
				end

				y = y + dialogContainer.height + 1
			end
		else
			dialogsContainer:addChild(GUI.label(1, sendMessageButton.localY - 2, dialogsContainer.width, 1, 0xA5A5A5, localization.hereBeYourDialogs)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_CENTER)
		end
	end
end

newPublicationInfo = function(file_id)
	lastMethod, lastArguments = newPublicationInfo, {file_id}

	local publication = fieldAPIRequest("result", "publication", {
		file_id = file_id,
		language_id = config.language_id,
	})

	if publication then
		workspace:draw()

		local reviews = fieldAPIRequest("result", "reviews", {
			file_id = file_id,
			offset = 0,
			count = 10,
		})

		if reviews then
			contentContainer:removeChildren()
			
			local infoContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))
			infoContainer.eventHandler = containerScrollEventHandler

			-- Жирный йоба-лейаут для отображения ВАЩЕ всего - и инфы, и отзыввов
			local layout = infoContainer:addChild(GUI.layout(3, 2, infoContainer.width - 4, infoContainer.height, 1, 1))
			layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

			-- А вот эт уже контейнер чисто инфы крч
			local detailsContainer = layout:addChild(GUI.container(3, 2, layout.width, 6))
					
			-- Тут будут находиться ваще пизда подробности о публикации
			local ratingsContainer = detailsContainer:addChild(GUI.container(1, 1, 28, 6))
			ratingsContainer.localX = detailsContainer.width - ratingsContainer.width + 1
			addPanel(ratingsContainer, 0xE1E1E1)
			
			local y = 2

			ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.developer, ": " .. publication.user_name)); y = y + 1
			ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.license, ": " .. licenses[publication.license_id])); y = y + 1
			ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.category, ": " .. categories[publication.category_id])); y = y + 1
			ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.version, ": " .. publication.version)); y = y + 1
			ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.updated, ": " .. os.date("%d.%m.%Y", publication.timestamp))); y = y + 1
			
			-- Добавляем инфу с общими рейтингами
			if #reviews > 0 then
				local ratings = {0, 0, 0, 0, 0}
				for i = 1, #reviews do
					ratings[reviews[i].rating] = ratings[reviews[i].rating] + 1
				end

				y = y + 1
				ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.reviews, ": " .. #reviews)); y = y + 1
				ratingsContainer:addChild(GUI.keyAndValue(2, y, 0x2D2D2D, 0x878787, localization.averageRating, ": " .. string.format("%.1f", publication.average_rating or 0))); y = y + 1

				for i = #ratings, 1, -1 do
					local text = tostring(ratings[i])
					local textLength = #text
					ratingsContainer:addChild(newRatingWidget(2, y, i, nil, 0xC3C3C3))
					ratingsContainer:addChild(GUI.progressBar(12, y, ratingsContainer.width - textLength - 13, 0x2D2D2D, 0xC3C3C3, 0xC3C3C3, ratings[i] / #reviews * 100, true))
					ratingsContainer:addChild(GUI.text(ratingsContainer.width - textLength, y, 0x2D2D2D, text))
					y = y + 1
				end
			end

			-- Фигачим кнопочки на изменение хуйни
			if user.token then
				y = y + 1

				local buttonsLayout = ratingsContainer:addChild(GUI.layout(1, y, ratingsContainer.width, 3, 1, 1))

				if publication.user_name == user.name then
					buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.edit)).onTouch = function()
						editPublication(publication)
					end

					buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.remove)).onTouch = function()
						deletePublication(publication)
					end
				else
					buttonsLayout:addChild(GUI.adaptiveRoundedButton(2, 1, 1, 0, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.newMessageToDeveloper)).onTouch = function()
						dialogGUI(publication.user_name)
					end

					local existingReviewText
					if #reviews > 0 then
						for i = 1, #reviews do
							if reviews[i].user_name == user.name then
								existingReviewText = reviews[i].comment
								break
							end
						end
					end

					buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, existingReviewText and localization.changeReview or localization.writeReview)).onTouch = function()
						local container = GUI.addBackgroundContainer(workspace, true, true, existingReviewText and localization.changeReview or localization.writeReview)

						local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, existingReviewText or "", localization.writeReviewHere))
						
						local pizda = container.layout:addChild(GUI.container(1, 1, 1, 1))
						local eblo = pizda:addChild(GUI.text(1, 1, 0xE1E1E1, localization.yourRating .. ": "))
						pizda.width = eblo.width + 9
						
						local cyka = pizda:addChild(newRatingWidget(eblo.width + 1, 1, 4))
						cyka.eventHandler = function(workspace, object, e1, e2, e3)
							if e1 == "touch" then
								cyka.rating = number.round((e3 - object.x + 1) / object.width * 5)
								workspace:draw()
							end
						end
						
						local govno = container.layout:addChild(GUI.button(1, 1, 36, 3, 0x696969, 0xFFFFFF, 0x3C3C3C, 0xFFFFFF, "OK"))
						govno.disabled = true
						govno.colors.disabled.background = 0xA5A5A5
						govno.colors.disabled.text = 0xC3C3C3
						govno.onTouch = function()
							local success, reason = RawAPIRequest("review", {
								token = user.token,
								file_id = publication.file_id,
								rating = cyka.rating,
								comment = input.text,
							})

							container:remove()
							workspace:draw()

							if success then
								newPublicationInfo(publication.file_id)
							else
								GUI.alert(reason)
							end
						end

						input.onInputFinished = function()
							local textLength, from, to = unicode.len(input.text), 2, 1000
							if textLength >= from and textLength <= to then
								govno.disabled = false
							else
								govno.disabled = true
								if textLength > to then
									GUI.alert("Too big review length (" .. textLength .. "). Maximum is " .. to)
								end
							end
							
							workspace:draw()
						end

						input.onInputFinished()
					end
				end
			end
			
			-- Добавляем контейнер под описание и прочую пизду
			local textDetailsContainer = detailsContainer:addChild(GUI.container(1, 1, detailsContainer.width - ratingsContainer.width, detailsContainer.height))
			-- Ебурим саму пизду
			addApplicationInfo(textDetailsContainer, publication, math.huge)
			-- Ебурим описание
			local x, y = 3, 7

			local function addLabel(text)
				textDetailsContainer:addChild(GUI.label(1, y, textDetailsContainer.width, 1, 0x696969, text)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
				y = y + 2
			end
			
			local function addTextBox(t)
				local lines = text.wrap(t, textDetailsContainer.width - 4)
				local textBox = textDetailsContainer:addChild(GUI.textBox(3, y, textDetailsContainer.width - 4, #lines, nil, 0x969696, lines, 1, 0, 0))
				textBox.eventHandler = nil
				y = y + textBox.height + 1
			end

			addTextBox(publication.translated_description)

			-- Инфа о чем-то новом
			if publication.whats_new then
				addLabel(localization.whatsNewInVersion .. " " .. publication.whats_new_version .. ":")
				addTextBox(publication.whats_new)
			end

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
					addLabel(localization.dependencies .. ":")

					for i = 1, #publication.all_dependencies do
						local dependency = publication.dependencies_data[publication.all_dependencies[i]]
						if dependency.publication_name then
							local textLength = unicode.len(dependency.publication_name) 
							if x + textLength + 4 > textDetailsContainer.width - 4 then
								x, y = 3, y + 2
							end
							
							local button = textDetailsContainer:addChild(GUI.tagButton(x, y, textLength + 2, 1, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, dependency.publication_name))
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

					local lines = text.wrap(tostring(reviews[i].comment), reviewContainer.width - 4)
					local textBox = reviewContainer:addChild(GUI.textBox(3, y, reviewContainer.width - 4, #lines, nil, 0x878787, lines, 1, 0, 0))
					textBox.eventHandler = nil
					y = y + #lines

					if reviews[i].votes or user.token and user.name ~= reviews[i].user_name then
						y = y + 1
					end

					if reviews[i].votes then
						reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, reviews[i].votes.positive .. " " .. localization.of .. " " .. reviews[i].votes.total .. " " .. localization.usersLoveReview))
						y = y + 1
					end

					if user.token and user.name ~= reviews[i].user_name then
						local wasHelpText = reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, localization.wasReviewHelpful))
						
						local layout = reviewContainer:addChild(GUI.layout(wasHelpText.localX + wasHelpText.width + 1, y, reviewContainer.width - wasHelpText.localX - wasHelpText.width - 1, 1, 1, 1))
						layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
						layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

						local function go(rating)
							local success = fieldAPIRequest("result", "review_vote", {
								token = user.token,
								review_id = reviews[i].id,
								rating = rating
							})

							if success then
								wasHelpText.text = localization.thanksForVote
								wasHelpText.color = 0x696969
								layout:remove()
							end
						end

						layout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x696969, nil, 0x2D2D2D, localization.yes)).onTouch = function()
							go(1)
						end
						layout:addChild(GUI.text(1, 1, 0xC3C3C3, "|"))
						layout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x696969, nil, 0x2D2D2D, localization.no)).onTouch = function()
							go(0)
						end
						layout:addChild(GUI.text(1, 1, 0xC3C3C3, "|"))
						layout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x696969, nil, 0x2D2D2D, localization.newMessagePersonal)).onTouch = function()
							dialogGUI(reviews[i].user_name.user_name)
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
end

--------------------------------------------------------------------------------

local function newPlusMinusCyka(width, disableLimit)
	local layout = GUI.layout(1, 1, width, 1, 2, 1)
	layout:setColumnWidth(1, GUI.SIZE_POLICY_RELATIVE, 1.0)
	layout:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, 8)
	layout:setFitting(1, 1, true, false)
	layout:setMargin(2, 1, 1, 0)
	layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	layout:setAlignment(2, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
	layout:setDirection(2, 1, GUI.DIRECTION_HORIZONTAL)

	layout.comboBox = layout:addChild(GUI.comboBox(1, 1, width - 7, 1, 0xFFFFFF, 0x878787, 0x969696, 0xE1E1E1))
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
		workspace:draw()
	end

	return layout
end

editPublication = function(initialPublication, initialCategoryID)
	lastMethod, lastArguments = editPublication, {initialPublication}
	contentContainer:removeChildren()

	local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 3, 1))
	layout:setColumnWidth(1, GUI.SIZE_POLICY_RELATIVE, 0.5)
	layout:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, 36)
	layout:setColumnWidth(3, GUI.SIZE_POLICY_RELATIVE, 0.5)
	layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_RIGHT, GUI.ALIGNMENT_VERTICAL_CENTER)
	layout:setAlignment(2, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
	layout:setFitting(2, 1, true, false)
	layout:setMargin(1, 1, 1, 0)

	local function addText(text)
		return layout:addChild(GUI.text(1, 1, 0x4B4B4B, text))
	end

	local function addInput(...)
		return layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x878787, 0xC3C3C3, 0xFFFFFF, 0x2D2D2D, ...))
	end

	local function addComboBox()
		return layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x878787, 0x969696, 0xE1E1E1))
	end

	addText(localization.category .. ":")
	addText(localization.license .. ":")
	addText(localization.publicationName .. ":")
	addText(localization.mainFileURL .. ":")
	local iconHint = addText(localization.iconURL .. ":")
	local pathHint = addText(localization.mainFileName .. ":")
	addText(localization.description .. ":")
	local whatsNewHint = addText(localization.whatsNew .. ":")
	addText(localization.dependenciesAndResources .. ":")

	layout.defaultColumn = 2

	layout:addChild(GUI.label(1, 1, 36, 1, 0x0, initialPublication and localization.edit or localization.publish)):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

	local categoryComboBox = addComboBox()
	for i = 1, #categories do
		categoryComboBox:addItem(categories[i])
	end

	local licenseComboBox = addComboBox()
	for i = 1, #licenses do
		licenseComboBox:addItem(licenses[i])
	end
	
	local nameInput = addInput(initialPublication and initialPublication.publication_name or "", "My publication")
	local mainUrlInput = addInput(initialPublication and initialPublication.source_url or "", "http://example.com/Main.lua")
	local iconUrlInput = addInput(initialPublication and initialPublication.icon_url or "", "http://example.com/Icon.pic")
	local mainPathInput = addInput(initialPublication and initialPublication.path or "", "MyScript.lua")
	local descriptionInput = addInput(initialPublication and initialPublication.initial_description or "", "This's my favourite script", true)
	local whatsNewInput = addInput("", "Added some cool features...")
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

	if initialPublication then
		categoryComboBox.selectedItem = initialPublication.category_id
		licenseComboBox.selectedItem = initialPublication.license_id
	elseif initialCategoryID then
		categoryComboBox.selectedItem = initialCategoryID
	end
	whatsNewHint.hidden, whatsNewInput.hidden = not initialPublication, not initialPublication

	local lastDependencyType = 1
	dependenciesLayout.addButton.onTouch = function()
		local container = GUI.addBackgroundContainer(workspace, true, true, localization.addDependency)
		
		local dependencyTypeComboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xFFFFFF, 0x4B4B4B, 0x969696, 0xE1E1E1))
		dependencyTypeComboBox:addItem(localization.fileByURL)
		dependencyTypeComboBox:addItem(localization.localizationDependency)
		dependencyTypeComboBox:addItem(localization.existingPublication)
		dependencyTypeComboBox.selectedItem = lastDependencyType

		local publicationNameInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", "MineOS"))
		local urlInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", ""))
		local pathInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x696969, 0xB4B4B4, 0xFFFFFF, 0x2D2D2D, "", ""))
		local pathType = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 6, 0x66DB80, 0x0, 0xE1E1E1, 0x878787, localization.relativePath .. ":", true))

		local button = container.layout:addChild(GUI.button(1, 1, 36, 3, 0x696969, 0xFFFFFF, 0x0, 0xFFFFFF, localization.add))
		button.onTouch = function()
			addDependency({
				publication_name = lastDependencyType == 3 and publicationNameInput.text or nil,
				path =
					lastDependencyType == 1 and
					(
						not pathType.hidden and pathType.switch.state and pathInput.text:gsub("^/+", "") or filesystem.removeSlashes("/" .. pathInput.text)
					) or
					lastDependencyType == 2 and
					(
						"Localizations/" .. filesystem.name(urlInput.text)
					) or
					nil,
				source_url = lastDependencyType ~= 3 and urlInput.text or nil,
			})

			container:remove()
			workspace:draw()
		end

		publicationNameInput.onInputFinished = function()
			if lastDependencyType == 1 then
				button.disabled = #pathInput.text == 0 or #urlInput.text == 0
			elseif lastDependencyType == 2 then
				button.disabled = #urlInput.text == 0 or filesystem.extension(urlInput.text) ~= ".lang"
			else
				button.disabled = #publicationNameInput.text == 0
			end
		end
		pathInput.onInputFinished, urlInput.onInputFinished = publicationNameInput.onInputFinished, publicationNameInput.onInputFinished
		
		local function updatePlaceholder()
			urlInput.placeholderText = lastDependencyType == 1 and "http://example.com/Main.lua" or "http://example.com/English.lang"
			pathInput.placeholderText = pathType.switch.state and "Resources/Main.lua" or "Users/Scripts/Main.lua"
		end

		local function onDependencyTypeComboBoxItemSelected()
			lastDependencyType = dependencyTypeComboBox.selectedItem
			publicationNameInput.hidden = lastDependencyType ~= 3
			pathInput.hidden = lastDependencyType ~= 1
			urlInput.hidden = lastDependencyType == 3
			pathType.hidden = categoryComboBox.selectedItem == 3 or pathInput.hidden

			updatePlaceholder()
		end

		dependencyTypeComboBox.onItemSelected = function()
			onDependencyTypeComboBoxItemSelected()
			workspace:draw()
		end

		pathType.switch.onStateChanged = updatePlaceholder

		publicationNameInput.onInputFinished()
		onDependencyTypeComboBoxItemSelected()
		pathType.switch.onStateChanged()
		workspace:draw()
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
		workspace:draw()
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
			whats_new = #whatsNewInput.text > 0 and whatsNewInput.text or nil
		})

		if success then
			leftList.selectedItem = categoryComboBox.selectedItem + 1
			
			if initialPublication then
				newPublicationInfo(initialPublication.file_id)
			else
				config.orderBy = 4
				saveConfig()
				updateFileList(categoryComboBox.selectedItem)
			end
		else
			GUI.alert(reason)
		end
	end
end

--------------------------------------------------------------------------------

updateFileList = function(category_id, updates)
	lastMethod, lastArguments = updateFileList, {category_id, updates}

	local file_ids
	if updates then
		file_ids = {}

		local function iterate(t)
			for id in pairs(t) do
				table.insert(file_ids, id)
			end
		end

		iterate(userVersions)
		iterate(systemVersions)
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
		contentContainer:removeChildren()
		
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
		layout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
		layout:setSpacing(1, 1, 2)

		if not updates or updates and #result > 0 then
			if updates then
				if #result > 0 then
					layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x696969, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, localization.updateAll)).onTouch = function()
						local container = GUI.addBackgroundContainer(workspace, true, true, "")

						local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 40, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))

						for i = 1, #result do
							container.label.text = localization.downloading .. " " .. result[i].publication_name
							progressBar.value = number.round(i / #result * 100)
							workspace:draw()

							local publication = fieldAPIRequest("result", "publication", {
								file_id = result[i].file_id,
								language_id = config.language_id,
							})
							
							local versionsTable = getVersionsTable(publication.file_id)
							versionsTable[publication.file_id].version = publication.version
							tryToDownload(publication.source_url, versionsTable[publication.file_id].path)

							if publication then
								if publication.dependencies then
									for j = 1, #publication.all_dependencies do
										local dependency = publication.dependencies_data[publication.all_dependencies[j]]
										if not dependency.publication_name then
											container.label.text = localization.downloading .. " " .. dependency.path
											workspace:draw()
											
											if getUpdateState(publication.all_dependencies[j], dependency.version) < 4 then
												local dependencyPath = getDependencyPath(versionsTable[publication.file_id].path, dependency)
												
												versionsTable[publication.all_dependencies[j]] = {
													path = dependencyPath,
													version = dependency.version,
												}

												tryToDownload(dependency.source_url, dependencyPath)
											else
												event.sleep(0.05)
											end
										end
									end
								end
							end
						end

						container:remove()
						saveVersions()
						computer.shutdown(true)
					end
				end
			else
				local input = layout:addChild(GUI.input(1, 1, 20, layout.height, 0xFFFFFF, 0x2D2D2D, 0xA5A5A5, 0xFFFFFF, 0x2D2D2D, search or "", localization.search, true))
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
			navigationLayout:setDirection(1, 1, GUI.DIRECTION_HORIZONTAL)
			navigationLayout:setSpacing(1, 1, 2)

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

				workspace:draw()
			end
		else
			showLabelAsContent(contentContainer, localization.noUpdates)
		end
	end
end

local function loadCategory(...)
	currentPage, search = 0, nil
	updateFileList(...)
end

--------------------------------------------------------------------------------

leftList:addItem(localization.categoryOverview).onTouch = overview

for i = 1, #categories do
	leftList:addItem(categories[i]).onTouch = function()
		loadCategory(i)
	end
end

leftList:addItem(localization.categoryUpdates).onTouch = function()
	loadCategory(nil, true)
end

messagesItem = leftList:addItem(localization.messages)
messagesItem.onTouch = dialogs

leftList:addItem(localization.settings).onTouch = settings

window.onResize = function(width, height)
	leftListPanel.height = height
	leftList.height = height - 3

	window.backgroundPanel.localX = leftList.width + 1
	window.backgroundPanel.width = width - leftList.width
	window.backgroundPanel.height = height

	contentContainer.localX = window.backgroundPanel.localX
	contentContainer.width = window.backgroundPanel.width
	contentContainer.height = window.backgroundPanel.height

	progressIndicator.localY = height - progressIndicator.height
	sponsoredLabel.localY = height
end

window.onResizeFinished = function()
	appsPerWidth = math.floor((contentContainer.width + appHSpacing) / (appWidth + appHSpacing))
	appsPerHeight = math.floor((contentContainer.height - 6 + appVSpacing) / (appHeight + appVSpacing))
	appsPerPage = appsPerWidth * appsPerHeight
	currentPage = 0
	
	contentContainer:removeChildren()
	callLastMethod()
end

--------------------------------------------------------------------------------

loadConfig()

lastMethod = loadCategory

if select(1, ...) == "updates" then
	lastArguments = {nil, true}
	leftList.selectedItem = #categories + 2
else
	lastArguments = {1}
	leftList.selectedItem = 2
end

window:resize(window.width, window.height)
