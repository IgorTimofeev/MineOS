
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

local host = "http://buttex.ru/mineos/appmarket/"
local luaIcon = image.load(MineOSPaths.icons .. "Lua.pic")
local scriptIcon = image.load(MineOSPaths.icons .. "Script.pic")
local appMarketPath = MineOSPaths.applicationData .. "AppMarket/"
local configPath = appMarketPath .. "Config.cfg"
local iconCachePath = appMarketPath .. "Cache/"

local config = {
	descriptionLanguage = "en",
	orderBy = 1,
	orderDirection = 1,
	user = {}
}

local categories = {
	"Приложения",
	"Библиотеки",
	"Скрипты",
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
	"average_rating",
	"file_id",
	"publication_name",
}

local search = ""
local appWidth, appHeight, appHSpacing, appVSpacing, currentPage, appsPerPage, appsPerWidth, appsPerHeight  = 34, 6, 2, 1

local updateFileList, editPublication

--------------------------------------------------------------------------------

local function saveConfig()
	table.toFile(configPath, config)
end

local function loadConfig()
	if fs.exists(configPath) then
		config = table.fromFile(configPath)
	else
		saveConfig()
	end
end

--------------------------------------------------------------------------------

local function RawAPIRequest(script, postData, notUnserialize)
	local url = host .. script .. ".php?" .. web.serialize(postData)
	-- table.toFile("/test.txt", {url})
	local requestResult, requestReason = web.request(url)
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
				return false, "Failed to unserialize response data: " .. tostring(unserializeReason) .. ", the data was: " .. tostring(requestResult)
			end
		else
			return result
		end
	else
		return false, "Web request failed: " .. tostring(requestReason)
	end
end

local function fieldAPIRequest(fieldToReturn, ...)
	local success, reason = RawAPIRequest(...)
	if success then
		if success[fieldToReturn] then
			return success[fieldToReturn]
		else
			return false, "Request was successful, but field " .. tostring(fieldToReturn) .. " doesn't exists"
		end
	else
		return false, reason
	end
end

local function checkImage(url)
	local handle = component.internet.request(url)
	if handle then
		local _, _, responseData
		repeat
			_, _, responseData = handle:response()
		until responseData

		local contentLength = tonumber(responseData["Content-Length"][1])
		if contentLength <= 10240 then
			local data, chunk, reason = ""
			while true do
				chunk, reason = handle.read(math.huge)
				if chunk then
					data = data .. chunk
					if #data > 8 then
						if data:sub(1, 4) == "OCIF" then
							if string.byte(data:sub(6, 6)) > 8 or string.byte(data:sub(7, 7)) > 4 then
								handle:close()
								return false, "Image size is larger than 8x4"
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
			handle:close()
			return false, "Specified image size is too big"
		end
	else
		return false, "Invalid URL"
	end
end

--------------------------------------------------------------------------------

local mainContainer, window = MineOSInterface.addWindow(MineOSInterface.tabbedWindow(1, 1, 110, 30))
local overrideWindowDraw = window.draw
window.draw = function(...)
	overrideWindowDraw(...)
	buffer.text(window.x, window.y + window.height, 0xFF0000, "Free RAM: " .. math.floor(computer.freeMemory() / 1024))
end

local contentContainer = window:addChild(GUI.container(1, 4, 1, 1))
local statusWidget = window:addChild(GUI.object(1, 1, 1, 1))
statusWidget.draw = function()
	buffer.square(statusWidget.x, statusWidget.y, statusWidget.width, 1, 0x2D2D2D, 0xF0F0F0, " ")
	buffer.text(statusWidget.x + 1, statusWidget.y, 0xF0F0F0, statusWidget.text)
end

--------------------------------------------------------------------------------

local function status(text)
	statusWidget.text = text
	MineOSInterface.OSDraw()
end

local function getAllDependencies(application)
	if application.dependencies then
		local allDependencies = {}

		local function getAllDependenciesRecursively(file_ids)
			local list, reason = fieldAPIRequest("list", "list", {
				file_ids = file_ids,
				fields = {
					"dependencies",
					"publication_name",
					"path",
					"source_url",
					"category_id",
				}
			})

			if list then
				local newDependenciesList = {}

				for i = 1, #list do
					if not allDependencies[list[i].file_id] and list[i].file_id ~= application.file_id then
						allDependencies[list[i].file_id] = list[i]
					end

					if list[i].dependencies then
						for j = 1, #list[i].dependencies do
							if not allDependencies[list[i].dependencies[j]] and list[i].dependencies[j] ~= application.file_id then
								table.insert(newDependenciesList, list[i].dependencies[j])
							end
						end
					end
				end

				if #newDependenciesList > 0 then
					getAllDependenciesRecursively(newDependenciesList)
				end
			else
				GUI.error(reason)
			end
		end

		getAllDependenciesRecursively(application.dependencies)

		application.expandedDependencies = {}
		for key, value in pairs(allDependencies) do
			table.insert(application.expandedDependencies, value)
			allDependencies[key] = nil
		end

		if #application.expandedDependencies == 0 then
			application.expandedDependencies = nil
		end
	end
end

local function ratingWidgetDraw(object)
	local x = 0
	for i = 1, 5 do
		buffer.text(object.x + x, object.y, math.round(object.rating) >= i and object.colors.first or object.colors.second, "*")
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

--------------------------------------------------------------------------------

local function getApplicationIcon(category_id, dependencies)
	if dependencies then
		for i = 1, #dependencies do
			if dependencies[i].path == "Resources/Icon.pic" then
				local path = iconCachePath .. dependencies[i].file_id .. ".pic"
				
				if fs.exists(path) then
					return image.load(path)
				else
					local data, reason = checkImage(dependencies[i].source_url)
					if data then
						local file = io.open(path, "w")
						file:write(data)
						file:close()

						return image.load(path)
					else
						GUI.error("Failed to download publication icon: " .. reason)
						break
					end
				end
			end
		end
	end

	if category_id == 2 then
		return luaIcon
	else
		return scriptIcon
	end
end

local function addPanel(container, color)
	container.panel = container:addChild(GUI.panel(1, 1, container.width, container.height, color or 0xFFFFFF))
end

local function addApplicationInfo(container, application)
	addPanel(container)
	container.image = container:addChild(GUI.image(3, 2, getApplicationIcon(application.category_id, application.expandedDependencies)))
	container.nameLabel = container:addChild(GUI.text(13, 2, 0x0, application.publication_name))
	container.versionLabel = container:addChild(GUI.text(13, 3, 0x888888, "©" .. application.user_name))
	container.rating = container:addChild(newRatingWidget(13, 4, application.average_rating or 0))
	container.downloadButton = container:addChild(GUI.adaptiveRoundedButton(13, 5, 1, 0, 0xBBBBBB, 0xFFFFFF, 0x888888, 0xFFFFFF, "Загрузить"))
	container.downloadButton.onTouch = function()
		local filesystemDialog = GUI.addFilesystemDialogToContainer(MineOSInterface.mainContainer, 50, math.floor(MineOSInterface.mainContainer.height * 0.8), true, "Загрузить", "Отмена", "Имя приложения", "/")
		
		filesystemDialog.input.text = application.category_id == 1 and application.publication_name or fs.hideExtension(application.path)
		filesystemDialog:addExtensionFilter(application.category_id == 1 and ".app" or ".lua")
		
		filesystemDialog.filesystemTree.selectedItem = downloadPaths[application.category_id]
		filesystemDialog:expandPath(filesystemDialog.filesystemTree.selectedItem)

		filesystemDialog.onSubmit = function(downloadPath)
			local container = MineOSInterface.addUniversalContainer(MineOSInterface.mainContainer, "")
			container.layout:setCellFitting(2, 1, false, false)

			local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 36, 0x66DB80, 0x0, 0xEEEEEE, 0, true, true, "", "%"))
				
			local function updateLabel(pizda)
				container.label.text = "Загрузка " .. (pizda.publication_name or fs.name(pizda.path))
			end
			updateLabel(application)

			MineOSInterface.OSDraw()

			-- SAVED
			getAllDependencies(application)
			local whatToDownload = {application}
			if application.expandedDependencies then
				for i = 1, #application.expandedDependencies do
					table.insert(whatToDownload, application.expandedDependencies[i])
				end
			end
			
			for i = 1, #whatToDownload do
				progressBar.value = math.round(i / #whatToDownload * 100)
				updateLabel(whatToDownload[i])

				-- Если это публикация
				local finalPath
				if whatToDownload[i].category_id then
					finalPath = downloadPaths[whatToDownload[i].category_id]

					if whatToDownload[i].category_id == 1 then
						if i == 1 then
							finalPath = downloadPath .. "/Main.lua"
						else
							finalPath = finalPath .. whatToDownload[i].publication_name .. ".app/Main.lua"
						end
					else
						finalPath = finalPath .. whatToDownload[i].path
					end
				-- Если это ресурс
				else
					finalPath = downloadPath .. "/" .. whatToDownload[i].path
				end

				-- GUI.error(whatToDownload[i].source_url, finalPath)
				-- local success, reason = web.download(whatToDownload[i].source_url, finalPath)
				-- if not success then
				-- 	GUI.error(reason)
				-- end

				MineOSInterface.OSDraw()
			end

			container:delete()
			MineOSInterface.OSDraw()		
		end

		filesystemDialog:setMode(GUI.filesystemModes.save, GUI.filesystemModes.file)
		filesystemDialog:show()
	end
end

local function keyValueWidgetUpdate(object)
	object.width = unicode.len(object.key .. object.value)
end

local function keyValueWidgetDraw(object)
	keyValueWidgetUpdate(object)
	buffer.text(object.x, object.y, object.colors.key, object.key)
	buffer.text(object.x + unicode.len(object.key), object.y, object.colors.value, object.value)
end

local function newKeyValueWidget(x, y, keyColor, valueColor, key, value)
	local object = GUI.object(x, y, 1, 1)
	
	object.colors = {
		key = keyColor,
		value = valueColor
	}
	object.key = key
	object.value = value

	object.draw = keyValueWidgetDraw
	keyValueWidgetUpdate(object)

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

local function newApplicationInfo(file_id)
	status("Получение информации о приложении...")

	local info, reason = fieldAPIRequest("list", "list", {
		file_ids = {file_id},
		fields = {
			"publication_id",
			"publication_name",
			"average_rating",
			"version",
			"reviews",
			"description",
			"category_id",
			"dependencies",
			"user_name",
			"license",
			"timestamp",
			"path",
		},
		description_language = config.descriptionLanguage,
	})

	if info then
		local application = info[1]

		status("Построение древа зависимостей...")
		getAllDependencies(application)

		contentContainer:deleteChildren()
		
		local infoContainer = contentContainer:addChild(GUI.container(1, 1, contentContainer.width, contentContainer.height))
		infoContainer.eventHandler = containerScrollEventHandler

		-- Жирный йоба-лейаут для отображения ВАЩЕ всего - и инфы, и отзыввов
		local layout = infoContainer:addChild(GUI.layout(3, 2, infoContainer.width - 4, infoContainer.height, 1, 1))
		layout:setCellAlignment(1, 1, GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

		-- А вот эт уже контейнер чисто инфы крч
		local detailsContainer = layout:addChild(GUI.container(3, 2, layout.width, 6))
				
		-- Тут будут находиться ваще пизда подробности о публикации
		local ratingsContainer = detailsContainer:addChild(GUI.container(1, 1, 26, 6))
		ratingsContainer.localX = detailsContainer.width - ratingsContainer.width + 1
		addPanel(ratingsContainer, 0xE1E1E1)
		
		-- Всякая текстовая пизда
		local y = 2
		ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Разработчик", ": " .. application.user_name)); y = y + 1
		ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Лицензия", ": " .. application.license)); y = y + 1
		ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Категория", ": " .. categories[application.category_id])); y = y + 1
		ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Версия", ": " .. string.format("%.2f", application.version))); y = y + 1
		ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Обновлено", ": " .. os.date("%d.%m.%Y", application.timestamp))); y = y + 1
		y = y + 1

		-- Добавляем инфу с общими рейтингами
		if application.reviews then
			status("Формирование структуры отзывов...")

			local ratings = {0, 0, 0, 0, 0}
			for i = 1, #application.reviews do
				ratings[application.reviews[i].rating] = ratings[application.reviews[i].rating] + 1
			end

			ratingsContainer:addChild(newKeyValueWidget(2, y, 0x2D2D2D, 0x888888, "Средний рейтинг", ": " .. string.format("%.1f", application.average_rating or 0))); y = y + 1

			for i = #ratings, 1, -1 do
				local text = tostring(ratings[i])
				local textLength = #text
				ratingsContainer:addChild(newRatingWidget(2, y, i, nil, 0xC3C3C3))
				ratingsContainer:addChild(GUI.progressBar(12, y, ratingsContainer.width - textLength - 13, 0x2D2D2D, 0xC3C3C3, 0xC3C3C3, ratings[i] / #application.reviews * 100, true))
				ratingsContainer:addChild(GUI.text(ratingsContainer.width - textLength, y, 0x2D2D2D, text))
				y = y + 1
			end
		end
		
		-- Добавляем описание и прочую пизду
		local textDetailsContainer = detailsContainer:addChild(GUI.container(1, 1, detailsContainer.width - ratingsContainer.width, detailsContainer.height))
		addApplicationInfo(textDetailsContainer, application)

		local lines = string.wrap(info[1].description, textDetailsContainer.width - 4)
		local textBox = textDetailsContainer:addChild(GUI.textBox(3, 7, textDetailsContainer.width - 4, #lines, nil, 0x888888, lines, 1, 0, 0))
		textBox.eventHandler = nil

		if application.expandedDependencies then
			local publicationDependencyExists, resourceDependencyExists = false, false
			for i = 1, #application.expandedDependencies do
				if application.expandedDependencies[i].publication_name then
					publicationDependencyExists = true
				else
					resourceDependencyExists = true
				end
			end

			local x, y = 3, textBox.localY + textBox.height + 1

			if resourceDependencyExists then
				textDetailsContainer:addChild(GUI.label(1, y, textDetailsContainer.width, 1, 0x666666, "Структура приложения")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
				y = y + 2

				local tree = textDetailsContainer:addChild(GUI.tree(2, y, textDetailsContainer.width - 2, 1, 0xF0F0F0, 0x3C3C3C, 0xAAAAAA, 0xAAAAAA, 0x3C3C3C, 0xE1E1E1, 0xBBBBBB, 0xAAAAAA, 0xC3C3C3, 0x444444))
				
				local dependencyTree = {}
				for i = 1, #application.expandedDependencies do
					if not application.expandedDependencies[i].publication_name then
						local idiNahooy = dependencyTree
						for blyad in (application.publication_name .. ".app/" .. fs.path(application.expandedDependencies[i].path)):gmatch("[^/]+") do
							if not idiNahooy[blyad] then
								idiNahooy[blyad] = {}
							end
							idiNahooy = idiNahooy[blyad]
						end
						table.insert(idiNahooy, fs.name(application.expandedDependencies[i].path))
					end
				end
				table.insert(dependencyTree[application.publication_name .. ".app"], "Main.lua")
				-- GUI.error(dependencyTree)

				local function pizda(t, offset)
					for key, value in pairs(t) do
						if type(value) == "table" then
							tree:addItem(key, key, offset, true)
							tree.expandedItems[key] = true

							pizda(value, offset + 2)
						else
							tree:addItem(value, value, offset, false)
						end
					end
				end

				pizda(dependencyTree, 1)

				tree.height = #tree.items
				tree.eventHandler = nil
				y = y + tree.height + 1
			end

			if publicationDependencyExists then
				textDetailsContainer:addChild(GUI.label(1, y, textDetailsContainer.width, 1, 0x666666, "Зависимости")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
				y = y + 2

				for i = 1, #application.expandedDependencies do
					local text = application.expandedDependencies[i].publication_name or fs.name(application.expandedDependencies[i].path)
					if application.expandedDependencies[i].publication_name then
						local textLength = unicode.len(text) 
						if x + textLength + 4 > textDetailsContainer.width - 4 then
							x, y = 3, y + 2
						end
						local button = textDetailsContainer:addChild(GUI.roundedButton(x, y, textLength + 2, 1, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, text))
						button.onTouch = function()
							newApplicationInfo(application.expandedDependencies[i].file_id)
						end
						x = x + button.width + 2
					end
				end

				y = y + 2
			end
		end

		textDetailsContainer.height = math.max(
			textDetailsContainer.children[#textDetailsContainer.children].localY + textDetailsContainer.children[#textDetailsContainer.children].height,
			ratingsContainer.children[#ratingsContainer.children].localY + ratingsContainer.children[#ratingsContainer.children].height
		)
		textDetailsContainer.panel.height = textDetailsContainer.height
		
		ratingsContainer.height = textDetailsContainer.height
		ratingsContainer.panel.height = textDetailsContainer.height

		detailsContainer.height = textDetailsContainer.height

		if config.user.token and config.user.name ~= application.user_name then
			layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x666666, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Написать отзыв")).onTouch = function()
				local container = MineOSInterface.addUniversalContainer(window, "Написать отзыв")
				container.layout:setCellFitting(2, 1, false, false)

				local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "Оставьте свой высер тут"))
				
				local pizda = container.layout:addChild(GUI.container(1, 1, 1, 1))
				local eblo = pizda:addChild(GUI.text(1, 1, 0xE1E1E1, "Оцените приложение: "))
				pizda.width = eblo.width + 9
				
				local cyka = pizda:addChild(newRatingWidget(eblo.width + 1, 1, 4))
				cyka.eventHandler = function(mainContainer, object, eventData)
					if eventData[1] == "touch" then
						cyka.rating = (eventData[3] - object.x + 1) / object.width * 5
						MineOSInterface.OSDraw()
					end
				end
				
				local govno = container.layout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xFFFFFF, 0x2D2D2D, 0x0, 0xFFFFFF, "Отправить высер"))
				govno.disabled = true
				govno.colors.disabled.background = 0xAAAAAA
				govno.colors.disabled.text = 0xC3C3C3
				govno.onTouch = function()
					local success, reason = RawAPIRequest("review", {
						token = config.user.token,
						publication_id = application.publication_id,
						rating = cyka.rating,
						comment = input.text,
					})

					container:delete()

					if success then					
						newApplicationInfo(application.file_id)
					else
						MineOSInterface.OSDraw()
						GUI.error(reason)
					end
				end

				input.onInputFinished = function()
					local textLength, from, to = unicode.len(input.text), 2, 1000
					if textLength >= from and textLength <= to then
						govno.disabled = false
					else
						govno.disabled = true
						GUI.error("Слишком охуевший высер. Его длина величиной " .. textLength .. " выходит за границы допустимого диапазона [" .. from .. "; " .. to .. "]")
					end
					
					MineOSInterface.OSDraw()
				end

				MineOSInterface.OSDraw()
			end
		end

		if application.reviews then
			-- Отображаем все оценки
			layout:addChild(GUI.text(1, 1, 0x666666, "Отзывы пользователей"))

			-- Перечисляем все отзывы
			local counter, limit = 0, 10

			for i = 1, #application.reviews do
				if application.reviews[i].comment then
					local reviewContainer = layout:addChild(GUI.container(1, 1, layout.width, 4))
					addPanel(reviewContainer)

					local y = 2
					local nameLabel = reviewContainer:addChild(GUI.text(3, y, 0x2D2D2D, application.reviews[i].user_name))
					reviewContainer:addChild(GUI.text(nameLabel.localX + nameLabel.width + 1, y, 0xC3C3C3, "(" .. os.date("%d.%m.%Y в %H:%M", application.reviews[i].timestamp) .. ")"))
					y = y + 1

					reviewContainer:addChild(newRatingWidget(3, y, application.reviews[i].rating))
					y = y + 1

					local lines = string.wrap(application.reviews[i].comment, reviewContainer.width - 4)
					local textBox = reviewContainer:addChild(GUI.textBox(3, y, reviewContainer.width - 4, #lines, nil, 0x888888, lines, 1, 0, 0))
					textBox.eventHandler = nil
					y = y + #lines + 1

					if application.reviews[i].votes then
						reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, application.reviews[i].positive_votes .. " из " .. application.reviews[i].votes .. " пользователей считают этот отзыв полезным"))
						y = y + 1
					end

					if config.user.token then
						local wasHelpText = reviewContainer:addChild(GUI.text(3, y, 0xC3C3C3, "Был ли этот отзыв полезен?"))
						local yesButton = reviewContainer:addChild(GUI.adaptiveButton(wasHelpText.localX + wasHelpText.width + 1, y, 0, 0, nil, 0x666666, nil, 0x2D2D2D, "Да"))
						local stripLabel = reviewContainer:addChild(GUI.text(yesButton.localX + yesButton.width + 1, y, 0xC3C3C3, "|"))
						local noButton = reviewContainer:addChild(GUI.adaptiveButton(stripLabel.localX + stripLabel.width + 1, y, 0, 0, nil, 0x666666, nil, 0x2D2D2D, "Нет"))
						
						local function go(rating)
							RawAPIRequest("review_vote", {
								token = config.user.token,
								review_id = application.reviews[i].id,
								rating = rating
							}, true)

							computer.beep(1500, 0.1)
							
							wasHelpText.text = "Спасибо за ответ."
							wasHelpText.color = 0x666666
							yesButton:delete()
							stripLabel:delete()
							noButton:delete()

							MineOSInterface.OSDraw()
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
					
					counter = counter + 1
					if counter > limit then
						break
					end
				end
			end
		end

		layout:update()
		layout.height = layout.children[#layout.children].localY + layout.children[#layout.children].height - 1

		status("Ожидание")
	else
		GUI.error(reason)
	end
end

--------------------------------------------------------------------------------

local function applicationWidgetEventHandler(mainContainer, object, eventData)
	if eventData[1] == "touch" then
		object.parent.panel.colors.background = 0xE1E1E1
		MineOSInterface.OSDraw()
		newApplicationInfo(object.parent.application.file_id)
	end
end

local function newApplicationPreview(x, y, application)
	local container = GUI.container(x, y, appWidth, appHeight)

	container.application = application
	addApplicationInfo(container, application)

	container.panel.eventHandler,
	container.image.eventHandler,
	container.nameLabel.eventHandler,
	container.versionLabel.eventHandler,
	container.rating.eventHandler =
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler,
	applicationWidgetEventHandler

	return container
end

--------------------------------------------------------------------------------

editPublication = function()
	contentContainer:deleteChildren()

	local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 3, 1))
	layout:setCellAlignment(1, 1, GUI.alignment.horizontal.right, GUI.alignment.vertical.center)
	layout:setCellAlignment(2, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.center)
	layout:setCellFitting(2, 1, true, false)
	layout:setCellMargin(1, 1, 1, 0)

	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Категория:"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Лицензия:"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Имя публикации:"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "URL главного файла:"))
	local iconHint = layout:addChild(GUI.text(1, 1, 0x2D2D2D, "URL иконки:"))
	local pathHint = layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Путь главного файла:"))
	layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Описание:"))
	layout:addChild(GUI.object(1, 1, 1, 1))
	layout:addChild(GUI.object(1, 1, 1, 1))

	layout.defaultColumn = 2

	layout:addChild(GUI.label(1, 1, 36, 1, 0x0, "Опубликовать ПО")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	local categoryComboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
	for i = 1, #categories do
		categoryComboBox:addItem(categories[i])
	end

	local licenseComboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
	for i = 1, #licenses do
		licenseComboBox:addItem(licenses[i])
	end

	local nameInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "My Script"))
	local mainUrlInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "http://example.com/Main.lua"))
	local iconUrlInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "http://example.com/Icon.pic"))
	local mainPathInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "MyScript.lua"))
	local descriptionInput = layout:addChild(GUI.input(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "This is my cool script"))
	
	layout:addChild(GUI.label(1, 1, 36, 1, 0x0, "Зависимости и ресурсы")):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)

	local dependenciesLayout = layout:addChild(GUI.layout(1, 1, 36, 1, 2, 1))
	dependenciesLayout:setColumnWidth(1, GUI.sizePolicies.percentage, 1.0)
	dependenciesLayout:setColumnWidth(2, GUI.sizePolicies.absolute, 8)
	dependenciesLayout:setCellFitting(1, 1, true, false)
	dependenciesLayout:setCellMargin(2, 1, 1, 0)
	dependenciesLayout:setCellAlignment(1, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	dependenciesLayout:setCellAlignment(2, 1, GUI.alignment.horizontal.left, GUI.alignment.vertical.top)
	dependenciesLayout:setCellDirection(1, 1, GUI.directions.horizontal)
	dependenciesLayout:setCellDirection(2, 1, GUI.directions.horizontal)
	local dependenciesComboBox = dependenciesLayout:addChild(GUI.comboBox(1, 1, 29, 1, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
	dependenciesLayout.defaultColumn = 2
	
	local addButton = dependenciesLayout:addChild(GUI.button(1, 1, 3, 1, 0x666666, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "+"))
	local removeButton = dependenciesLayout:addChild(GUI.button(1, 1, 3, 1, 0x666666, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "-"))

	local function checkRemoveButton()
		local count = dependenciesComboBox:count()
		removeButton.disabled = count == 0
		dependenciesComboBox.selectedItem = count
	end
	checkRemoveButton()

	addButton.onTouch = function()
		local container = MineOSInterface.addUniversalContainer(window, "Добавить зависимость")
		
		container.layout:setCellFitting(2, 1, false, false)

		local dependencyTypeComboBox = container.layout:addChild(GUI.comboBox(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
		dependencyTypeComboBox:addItem("Существующая публикация")
		dependencyTypeComboBox:addItem("Файл ресурсов", categoryComboBox.selectedItem > 1)

		local publicationNameInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "Double Buffering"))
		local urlInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "http://example.com/English.lang"))
		local pathInput = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "Localization/English.lang"))

		local button = container.layout:addChild(GUI.button(1, 1, 36, 3, 0x666666, 0xFFFFFF, 0x0, 0xFFFFFF, "Добавить"))
		button.onTouch = function()	
			if dependencyTypeComboBox.selectedItem == 1 then
				dependenciesComboBox:addItem(publicationNameInput.text).publication_name = publicationNameInput.text
			else
				local item = dependenciesComboBox:addItem(pathInput.text)
				item.path = pathInput.text
				item.source_url = urlInput.text
			end

			checkRemoveButton()

			container:delete()
			MineOSInterface.OSDraw()
		end

		publicationNameInput.onInputFinished = function()
			if dependencyTypeComboBox.selectedItem == 1 then
				button.disabled = #publicationNameInput.text == 0
			else
				button.disabled = #pathInput.text == 0 or #urlInput.text == 0
			end
		end
		pathInput.onInputFinished, urlInput.onInputFinished = publicationNameInput.onInputFinished, publicationNameInput.onInputFinished
		
		dependencyTypeComboBox.onItemSelected = function()
			pathInput.hidden = dependencyTypeComboBox.selectedItem == 1
			urlInput.hidden = pathInput.hidden
			publicationNameInput.hidden = not pathInput.hidden

			MineOSInterface.OSDraw()
		end

		publicationNameInput.onInputFinished()
		dependencyTypeComboBox.onItemSelected()
	end

	removeButton.onTouch = function()
		dependenciesComboBox:getItem(dependenciesComboBox.selectedItem):delete()
		checkRemoveButton()
		MineOSInterface.OSDraw()
	end

	local publishButton = layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0x666666, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Опубликовать"))

	nameInput.onInputFinished = function()
		publishButton.disabled = not (#nameInput.text > 0 and #mainUrlInput.text > 0 and (iconUrlInput.hidden and true or #iconUrlInput.text > 0) and (mainPathInput.hidden and true or #mainPathInput.text > 0) and #descriptionInput.text > 0)
	end
	mainUrlInput.onInputFinished, mainPathInput.onInputFinished, iconUrlInput.onInputFinished, descriptionInput.onInputFinished = nameInput.onInputFinished, nameInput.onInputFinished, nameInput.onInputFinished, nameInput.onInputFinished

	categoryComboBox.onItemSelected = function()
		iconHint.hidden = categoryComboBox.selectedItem > 1
		iconUrlInput.hidden = iconHint.hidden

		pathHint.hidden = not iconHint.hidden
		mainPathInput.hidden = pathHint.hidden

		nameInput.onInputFinished()
		MineOSInterface.OSDraw()
	end

	publishButton.onTouch = function()
		local dependencies = {}
		for i = 1, dependenciesComboBox:count() do
			local item = dependenciesComboBox:getItem(i)
			if item.publication_name then
				table.insert(dependencies, {
					publication_name = item.publication_name
				})
			else
				table.insert(dependencies, {
					source_url = item.source_url,
					path = "Resources/" .. item.path
				})
			end
		end

		if categoryComboBox.selectedItem == 1 then
			table.insert(dependencies, {
				source_url = iconUrlInput.text,
				path = "Resources/Icon.pic"
			})
		end

		local success, reason = RawAPIRequest("upload", {
			token = config.user.token,
			name = web.encode(nameInput.text),
			source_url = mainUrlInput.text,
			path = web.encode(categoryComboBox.selectedItem == 1 and "Main.lua" or mainPathInput.text),
			description = web.encode(descriptionInput.text),
			license_id = licenseComboBox.selectedItem,
			dependencies = dependencies,
			category_id = categoryComboBox.selectedItem,
		})

		if success then
			window.tabBar.selectedItem = categoryComboBox.selectedItem
			config.orderBy = 2
			updateFileList(window.tabBar.selectedItem)
		else
			GUI.error(reason)
		end
	end

	categoryComboBox.onItemSelected()
end

--------------------------------------------------------------------------------

updateFileList = function(category_id)
	status("Обновление списка приложений...")

	-- Получаем общий список приложений
	local list, reason = fieldAPIRequest("list", "list", {
		publications_only = true,
		category_id = category_id,
		fields = {
			"average_rating",
			"dependencies",
			"publication_name",
			"user_name",
			"path",
			"source_url",
		},
		order_by = orderBys[config.orderBy],
		order_direction = orderDirections[config.orderDirection],
		offset = currentPage * appsPerPage,
		count = appsPerPage + 1,
		search = search
	})

	if list then
		contentContainer:deleteChildren()

		local y = 2

		local layout = contentContainer:addChild(GUI.layout(1, y, contentContainer.width, 1, 1, 1))
		layout:setCellDirection(1, 1, GUI.directions.horizontal)
		layout:setCellSpacing(1, 1, 2)
		
		local input = layout:addChild(GUI.input(1, 1, 20, layout.height, 0xFFFFFF, 0x2D2D2D, 0x666666, 0xFFFFFF, 0x2D2D2D, search or "", "Поиск", true))
		input.onInputFinished = function()
			if #input.text == 0 then
				search = nil
			else
				search = input.text
			end

			updateFileList(category_id)
		end

		local orderByComboBox = layout:addChild(GUI.comboBox(1, 1, 18, layout.height, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
		orderByComboBox:addItem("По рейтингу")
		orderByComboBox:addItem("По дате")
		orderByComboBox:addItem("По имени")
		orderByComboBox.selectedItem = config.orderBy

		local orderDirectionComboBox = layout:addChild(GUI.comboBox(1, 1, 18, layout.height, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
		orderDirectionComboBox:addItem("По убыванию")
		orderDirectionComboBox:addItem("По возрастанию")
		orderDirectionComboBox.selectedItem = config.orderDirection

		orderByComboBox.onItemSelected = function()
			config.orderBy = orderByComboBox.selectedItem
			config.orderDirection = orderDirectionComboBox.selectedItem
			updateFileList(category_id)
			saveConfig()
		end
		orderDirectionComboBox.onItemSelected = orderByComboBox.onItemSelected

		if config.user.token then
			local uploadButton = layout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0x666666, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Опубликовать ПО"))
			uploadButton.onTouch = function()
				editPublication()
			end
		end

		y = y + layout.height + 1

		local navigationLayout = contentContainer:addChild(GUI.layout(1, contentContainer.height - 1, contentContainer.width, 1, 1, 1))
		navigationLayout:setCellDirection(1, 1, GUI.directions.horizontal)
		navigationLayout:setCellSpacing(1, 1, 2)

		local function switchPage(forward)
			currentPage = currentPage + (forward and 1 or -1)
			updateFileList(category_id)
		end

		local backButton = navigationLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xFFFFFF, 0x666666, 0x2D2D2D, 0xFFFFFF, "<"))
		backButton.disabled = currentPage == 0
		backButton.onTouch = function()
			switchPage(false)
		end

		navigationLayout:addChild(GUI.text(1, 1, 0x666666, "Страница " .. (currentPage + 1)))
		local nextButton = navigationLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xFFFFFF, 0x666666, 0x2D2D2D, 0xFFFFFF, ">"))
		nextButton.disabled = #list <= appsPerPage
		nextButton.onTouch = function()
			switchPage(true)
		end

		local xStart = math.floor(1 + contentContainer.width / 2 - (appsPerWidth * (appWidth + appHSpacing) - appHSpacing) / 2)
		local x, counter = xStart, 1
		for i = 1, #list do
			-- Сам ты пидор!
			list[i].category_id = category_id
			-- Если мы чекаем приложухи, и в этой публикации есть какие-то зависимости
			if category_id == 1 and list[i].dependencies then
				-- Получаем лист этих зависимостей по идшникам, выдавая только путь и урлку
				local dependencies, reason = fieldAPIRequest("list", "list", {
					file_ids = list[i].dependencies,
					fields = {
						"path",
						"source_url"
					}
				})

				if dependencies then
					list[i].expandedDependencies = dependencies
				else
					GUI.error(reason)
				end
			end

			contentContainer:addChild(newApplicationPreview(x, y, list[i]))

			x = x + appWidth + appHSpacing
			if counter >= appsPerPage then
				break
			elseif counter % appsPerWidth == 0 then
				x, y = xStart, y + appHeight + appVSpacing
			end
			counter = counter + 1

			-- Если мы тока шо создали приложеньку, от отрисовываем содержимое сразу же
			if category_id == 1 then
				MineOSInterface.OSDraw()
			end
		end
	else
		GUI.error(reason)
	end

	status("Ожидание")
end

window.onResize = function(width, height)
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height - 4
	contentContainer.width = width
	contentContainer.height = window.height - 4
	window.tabBar.width = width
	statusWidget.width = window.width
	statusWidget.localY = window.height

	appsPerWidth = math.floor((contentContainer.width + appHSpacing) / (appWidth + appHSpacing))
	appsPerHeight = math.floor((contentContainer.height - 6 + appVSpacing) / (appHeight + appVSpacing))
	appsPerPage = appsPerWidth * appsPerHeight
end

local function account()
	contentContainer:deleteChildren()
	
	local layout = contentContainer:addChild(GUI.layout(1, 1, contentContainer.width, contentContainer.height, 1, 1))

	if config.user.token then
		local list, reason = fieldAPIRequest("list", "list", {
			file_ids = {file_id},
			fields = {
				"publication_id",
				"publication_name",
				"file_id",
			},
			publications_only = true,
			user_id = config.user.id,
			order_by = "publication_name",
		})

		if list then
			layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Профиль"))
			layout:addChild(GUI.label(1, 1, 36, 1, 0x888888, "Имя: " .. config.user.name))
			layout:addChild(GUI.label(1, 1, 36, 1, 0x888888, "E-Mail: " .. config.user.email))
			layout:addChild(GUI.label(1, 1, 36, 1, 0x888888, "Дата регистрации: " .. os.date("%d.%m.%Y", config.user.timestamp)))

			layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 0, 0xAAAAAA, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Выход")).onTouch = function()
				config.user = {}
				saveConfig()
				account()
			end

			if #list > 0 then
				layout:addChild(GUI.text(1, 1, 0x2D2D2D, "Публикации"))

				local comboBox = layout:addChild(GUI.comboBox(1, 1, 36, 1, 0xFFFFFF, 0x666666, 0x999999, 0xE1E1E1))
				for i = 1, #list do
					comboBox:addItem(list[i].publication_name)
				end

				local buttonsLayout = layout:addChild(GUI.layout(1, 1, layout.width, 1, 1, 1))
				buttonsLayout:setCellDirection(1, 1, GUI.directions.horizontal)
				buttonsLayout:setCellSpacing(1, 1, 3)
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xAAAAAA, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Открыть")).onTouch = function()
					newApplicationInfo(list[comboBox.selectedItem].file_id)
				end
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xAAAAAA, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Изменить"))
				buttonsLayout:addChild(GUI.adaptiveRoundedButton(1, 1, 1, 0, 0xAAAAAA, 0xFFFFFF, 0x2D2D2D, 0xFFFFFF, "Удалить"))
			end

			
		else
			GUI.error(reason)
		end
	else
		local function addShit(register)
			layout:deleteChildren()

			local text = register and "Register" or "Login"
			layout:addChild(GUI.label(1, 1, 36, 1, 0x0, text)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
			
			if register then
				layout.nameInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, "", "Username"))
			end

			layout.emailInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, config.user.email or "", register and "E-mail" or "E-Mail или никнейм"))
			layout.passwordInput = layout:addChild(GUI.input(1, 1, 36, 3, 0xFFFFFF, 0x666666, 0xBBBBBB, 0xFFFFFF, 0x2D2D2D, config.user.password or "", "Password", false, "*"))
			
			if register then
				layout.submit = layout:addChild(GUI.button(1, 1, 36, 3, 0xAAAAAA, 0xFFFFFF, 0x666666, 0xFFFFFF, text))
			end
		end

		addShit(false)

		layout:addChild(GUI.button(1, 1, 36, 3, 0xAAAAAA, 0xFFFFFF, 0x666666, 0xFFFFFF, "Login")).onTouch = function()
			local user, reason = fieldAPIRequest("user", "login", {
				[(string.find(layout.emailInput.text, "@") and "email" or "name")] = layout.emailInput.text,
				password = layout.passwordInput.text
			})

			if user then
				config.user = {
					token = user.token,
					name = user.name,
					id = user.id,
					email = user.email,
					timestamp = user.timestamp,
					password = layout.passwordInput.text,
				}
				saveConfig()
				account()
			else
				GUI.error(reason)
			end
		end

		local registerLayout = layout:addChild(GUI.layout(1, 1, layout.width, 1, 1, 1))
		registerLayout:setCellDirection(1, 1, GUI.directions.horizontal)

		local registerText = registerLayout:addChild(GUI.text(1, 1, 0xAAAAAA, "Еще не зарегистрированы?"))
		registerLayout:addChild(GUI.adaptiveButton(1, 1, 0, 0, nil, 0x666666, nil, 0x0, "Создать аккаунт")).onTouch = function()
			addShit(true)

			layout.submit.onTouch = function()
				local information, reason = fieldAPIRequest("information", "register", {
					name = layout.nameInput.text,
					email = layout.emailInput.text,
					password = layout.passwordInput.text,
				})

				if information then
					GUI.error("Все заебись! Чекни свое мыло (" .. layout.emailInput.text .. ") и папку спама, чтобы подтвердить свой акк")
				else
					GUI.error(reason)
				end
			end
		end
	end
end

local function loadCategory(id)
	currentPage = 0
	updateFileList(id)
end

window.tabBar:addItem(categories[1]).onTouch = function()
	loadCategory(1)
end

window.tabBar:addItem(categories[2]).onTouch = function()
	loadCategory(2)
end

window.tabBar:addItem(categories[3]).onTouch = function()
	loadCategory(3)
end

window.tabBar:addItem("Обновления").onTouch = function()
	
end

window.tabBar:addItem("Аккаунт").onTouch = function()
	account()
end

--------------------------------------------------------------------------------

loadConfig()
window:resize(window.width, window.height)
-- window.tabBar:getItem(2).onTouch()
newApplicationInfo(169)






