
local filesystem = require("Filesystem")
local json = require("JSON")
local internet = require("Internet")
local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local system = require("System")

------------------------------------------------------------------------------------------------------------------

local resourcesPath = filesystem.path(system.getCurrentScript())
local configPath = paths.user.applicationData .. "Translate/Config.cfg"
local config = {
	APIKey = "trnsl.1.1.20170831T153247Z.6ecf9d7198504994.8ce5a3aa9f9a2ecbe7b2377af37ffe5ad379f4ca",
	fromLanguage = "Русский",
	toLanguage = "Английский",
	languages = {},
}

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

if filesystem.exists(configPath) then
	config = filesystem.readTable(configPath)
end

------------------------------------------------------------------------------------------------------------------

local workspace = GUI.workspace()
workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x1E1E1E))
local actionButtons = workspace:addChild(GUI.actionButtons(3, 2, true))
local layout = workspace:addChild(GUI.layout(1, 1, workspace.width, workspace.height, 1, 1))

local logo = layout:addChild(GUI.image(1, 1, image.load(resourcesPath .. "Logo.pic")))
local elementWidth = image.getWidth(logo.image)
layout:addChild(GUI.object(1, 1, 1, 1))

local fromLanguageContainer = layout:addChild(GUI.container(1, 1, elementWidth, 1))
local fromLanguageAutoDetectButton = fromLanguageContainer:addChild(GUI.adaptiveButton(1, 1, 2, 0, 0x2D2D2D, 0xBBBBBB, 0x666666, 0xBBBBBB, "Detect language"))
fromLanguageAutoDetectButton.localX = fromLanguageContainer.width - fromLanguageAutoDetectButton.width + 1
local fromComboBox = fromLanguageContainer:addChild(GUI.comboBox(1, 1, fromLanguageAutoDetectButton.localX - 3, 1, 0x2D2D2D, 0xAAAAAA, 0x444444, 0x888888))
local fromInputField = layout:addChild(GUI.input(1, 1, elementWidth, 5, 0x2D2D2D, 0x666666, 0x444444, 0x3C3C3C, 0xBBBBBB, nil, "Введите текст", true))

local switchButton = layout:addChild(GUI.adaptiveRoundedButton(1, 1, 3, 1, 0x2D2D2D, 0xBBBBBB, 0x666666, 0xBBBBBB, "←→"))

local toComboBox = layout:addChild(GUI.comboBox(1, 1, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x444444, 0x888888))
local toInputField = layout:addChild(GUI.input(1, 1, elementWidth, 5, 0x2D2D2D, 0x666666, 0x444444, 0x3C3C3C, 0xBBBBBB, nil, nil))

layout:addChild(GUI.label(1, 1, elementWidth, 1, 0xAAAAAA, "API Key:"):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))
local APIKeyInputField = layout:addChild(GUI.input(1, 1, elementWidth, 1, 0x1E1E1E, 0x666666, 0x444444, 0x1E1E1E, 0xBBBBBB, config.APIKey, "Введите API Key", true))

local infoLabel = layout:addChild(GUI.label(1, 1, elementWidth, 1, 0xFF6D40, " "):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP))

------------------------------------------------------------------------------------------------------------------

local function status(text)
	infoLabel.text = text
	workspace:draw()
end

local function getLanguageIndex(text, short)
	local type = short and 1 or 2
	for i = 1, #config.languages do
		if config.languages[i][type] == text then
			return i
		end
	end
end

local function fillLanguages()
	for i = 1, #config.languages do
		fromComboBox:addItem(config.languages[i][2])
		toComboBox:addItem(config.languages[i][2])
	end
end

local function checkLanguages()
	if #config.languages == 0 then
		local result, reason = internet.request("https://translate.yandex.net/api/v1.5/tr.json/getLangs?key=" .. config.APIKey .. "&ui=ru")
		if result then
			fromComboBox:clear()
			toComboBox:clear()

			local yandexArray = json.decode(result)
			for key, value in pairs(yandexArray.langs) do
				table.insert(config.languages, {key, value})
			end
			table.sort(config.languages, function(a, b) return a[2] < b[2] end)
			fillLanguages()
			saveConfig()
		else
			error("Ошибка получения списка языков")
		end
	else
		fillLanguages()
	end
end

local function translate()
	if unicode.len(fromInputField.text or "") > 0 then
		status("Отправка запроса на перевод...")

		local result, reason = internet.request(
			"https://translate.yandex.net/api/v1.5/tr.json/translate?key=" .. config.APIKey ..
			"&text=" .. internet.encode(fromInputField.text) ..
			"&lang=" .. config.languages[getLanguageIndex(fromComboBox:getItem(fromComboBox.selectedItem).text, false)][1] .. "-" ..
			config.languages[getLanguageIndex(toComboBox:getItem(toComboBox.selectedItem).text, false)][1]
		)

		if result then
			toInputField.text = json.decode(result).text[1]
			status(" ")

			config.fromLanguage = fromComboBox:getItem(fromComboBox.selectedItem).text
			config.toLanguage = toComboBox:getItem(toComboBox.selectedItem).text
			saveConfig()
		else
			status("Ошибка во время запроса на перевод")
		end
	end
end

fromLanguageAutoDetectButton.onTouch = function()
	if unicode.len(fromInputField.text or "") > 0 then
		status("Отправка запроса на определение языка...")
		
		local result, reason = internet.request(
			"https://translate.yandex.net/api/v1.5/tr.json/detect?key=" .. config.APIKey ..
			"&text=" .. internet.encode(fromInputField.text)
		)

		if result then
			result = json.decode(result)
			if result.lang then
				fromComboBox.selectedItem = getLanguageIndex(result.lang, true)
				translate()
			else
				status("Невозможно определить язык")
			end
		else
			status("Ошибка во время запроса на определение языка")
		end
	end
end

actionButtons.close.onTouch = function()
	workspace:stop()
end

switchButton.onTouch = function()
	fromComboBox.selectedItem, toComboBox.selectedItem = toComboBox.selectedItem, fromComboBox.selectedItem
	fromInputField.text, toInputField.text = toInputField.text, fromInputField.text
	translate()
end

fromInputField.onInputFinished = function()
	translate()
end

fromComboBox.onItemSelected = function()
	translate()
end

toComboBox.onItemSelected = function()
	translate()
end

APIKeyInputField.onInputFinished = function()
	if APIKeyInputField.text then
		config.APIKey = APIKeyInputField.text
		translate()
		saveConfig()
	end
end

toInputField.eventHandler = nil

------------------------------------------------------------------------------------------------------------------

checkLanguages()
fromComboBox.selectedItem = getLanguageIndex(config.fromLanguage, false)
toComboBox.selectedItem = getLanguageIndex(config.toLanguage, false)

workspace:draw()
workspace:start()
