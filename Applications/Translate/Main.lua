
require("advancedLua")
local fs = require("filesystem")
local json = require("json")
local web = require("web")
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local unicode = require("unicode")

------------------------------------------------------------------------------------------------------------------

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x1E1E1E))
local layout = mainContainer:addChild(GUI.layout(1, 1, mainContainer.width, mainContainer.height, 1, 1))

local logo = layout:addChild(GUI.image(1, 1, image.load(fs.path(getCurrentScript()) .. "/Resources/Logo.pic")))
local elementWidth = image.getWidth(logo.image)
layout:addChild(GUI.object(1, 1, 1, 1))

local fromComboBox = layout:addChild(GUI.comboBox(1, 1, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x444444, 0x888888))
local fromInputField = layout:addChild(GUI.inputField(1, 1, elementWidth, 5, 0x2D2D2D, 0x666666, 0x444444, 0x3C3C3C, 0xBBBBBB, nil, "Введите текст"))
local switchButton = layout:addChild(GUI.adaptiveRoundedButton(1, 1, 2, 1, 0x2D2D2D, 0xBBBBBB, 0x666666, 0xBBBBBB, "<>"))
local toComboBox = layout:addChild(GUI.comboBox(1, 1, elementWidth, 1, 0x2D2D2D, 0xAAAAAA, 0x444444, 0x888888))
local toInputField = layout:addChild(GUI.inputField(1, 1, elementWidth, 5, 0x2D2D2D, 0x666666, 0x444444, 0x3C3C3C, 0xBBBBBB, nil, "Введите текст"))
local infoLabel = layout:addChild(GUI.label(1, 1, layout.width, 1, 0xFF6D40, " "):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top))

------------------------------------------------------------------------------------------------------------------

local languages
local function updateLanguages()
	local result, reason = web.request("https://translate.yandex.net/api/v1.5/tr.json/getLangs?key=trnsl.1.1.20170831T153247Z.6ecf9d7198504994.8ce5a3aa9f9a2ecbe7b2377af37ffe5ad379f4ca&ui=ru")
	if result then
		fromComboBox:clear()
		toComboBox:clear()
		languages = {}

		local yandexArray = json:decode(result)
		for key, value in pairs(yandexArray.langs) do
			table.insert(languages, {short = key, full = value})
		end
		table.sort(languages, function(a, b) return a.full < b.full end)
		for i = 1, #languages do
			fromComboBox:addItem(languages[i].full)
			toComboBox:addItem(languages[i].full)
		end
	else
		infoLabel.text = "Ошибка получения списка языков: " .. tostring(reason)
		mainContainer:draw()
		buffer.draw()
	end
end

local function getLanguageIndex(text)
	for i = 1, #languages do
		if languages[i].full == text then
			return i
		end
	end
	error("CYKA BLYAD LANG NOT FOUND")
end

local function translate()
	if fromInputField.text and unicode.len(fromInputField.text) > 0 then
		infoLabel.text = "Отправка запроса на перевод..."
		mainContainer:draw()
		buffer.draw()

		local result, reason = web.request("https://translate.yandex.net/api/v1.5/tr.json/translate?key=trnsl.1.1.20170831T153247Z.6ecf9d7198504994.8ce5a3aa9f9a2ecbe7b2377af37ffe5ad379f4ca&text=" .. string.optimizeForURLRequests(fromInputField.text) .. "&lang=" .. languages[getLanguageIndex(fromComboBox:getItem(fromComboBox.selectedItem).text)].short .. "-" .. languages[getLanguageIndex(toComboBox:getItem(toComboBox.selectedItem).text)].short)
		if result then
			toInputField.text = json:decode(result).text[1]
			infoLabel.text = " "
		else
			infoLabel.text = "Ошибка запроса на перевод: " .. tostring(reason)
		end

		mainContainer:draw()
		buffer.draw()
	end
end

switchButton.onTouch = function()
	fromComboBox.selectedItem, toComboBox.selectedItem = toComboBox.selectedItem, fromComboBox.selectedItem
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

toInputField.eventHandler = nil

------------------------------------------------------------------------------------------------------------------

updateLanguages()
fromComboBox.selectedItem = getLanguageIndex("Русский")
toComboBox.selectedItem = getLanguageIndex("Английский")
mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling()


