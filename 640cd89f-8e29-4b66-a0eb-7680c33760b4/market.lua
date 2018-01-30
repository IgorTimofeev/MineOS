
---------------------------------------------------- Libraries ----------------------------------------------------

package.loaded.windows = nil
package.loaded.GUI = nil

require("advancedLua")
local sides = require("sides")
local computer = require("computer")
local component = require("component")
local fs = require("filesystem")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local windows = require("windows")
local MineOSCore = require("MineOSCore")
local event = require("event")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local image = require("image")
local bigLetters = require("bigLetters")
local internet = component.internet
local transposer = component.transposer

---------------------------------------------------- Constants ----------------------------------------------------

local scriptAddress = "http://94.242.34.251:8888/MinecraftMarket/market.php?"
local colors = {
	background = 0x1B1B1B,
	tradeWidget = {
		background = 0xDDDDDD,
		text = 0x262626
	}
}
local currentUser
local mainWindow

local function databaseRequest(url)
	url = scriptAddress .. url
	url = url:gsub(" ", "%%20")
	local success, response = ecs.internetRequest(url)
	if success then
		-- ecs.error("return " .. response)
		response = load("return " .. response)()
	else
		GUI.error(response, {title = {color = 0xFFDB40, text = "URL request failed"}})
	end
	return success, response
end

------------------------------------------------ Trades tab ------------------------------------------------

local function getTrades(offset, count, search)
	return databaseRequest("getTrades&offset=" .. offset .. "&count=" .. count .. (search and "&search=" .. search or ""))
end

local function getMyTrades()
	return databaseRequest("getTrades&user=" .. currentUser.name)
end

local function newTradeWidget(y, trades, i, isMyTrade)
	local object = GUI.container(1, y,mainWindow.contentContainer.width, 3)

	object:addPanel(1, 1, object.width, object.height, colors.tradeWidget.background)
	object.itemIDLabel = object:addLabel(2, 2, 30, 1, colors.tradeWidget.text, trades[i].itemLabel)
	if isMyTrade then
		object:addButton(object.width - 13, 1, 14, object.height, 0xFF5555, 0xFFFFFF, 0xAA2222, 0xFFFFFF, "Убрать").onTouch = function()
				
		end
	else
		object:addButton(object.width - 13, 1, 14, object.height, 0x66B680, 0xFFFFFF, 0x004900, 0xFFFFFF, "Купить").onTouch = function()
			
		end
	end

	return object
end

local function updateTrades(offset, count, search)
	mainWindow.contentContainer:deleteChildren(2)
	local myTradesSuccess, myTradesResponse = getMyTrades()
	local allTradesSuccesss, allTradesResponse = getTrades(offset, count, search)
	
	if myTradesSuccess and allTradesSuccesss then
		local y = 1
		-- if #myTradesResponse.trades > 0 then
		-- 	for i = 1, #myTradesResponse.trades do
		-- 		mainWindow.contentContainer:addChild(newTradeWidget(y, myTradesResponse.trades, i, true))
		-- 		y = y + 4
		-- 	end
		-- end

		-- mainWindow.contentContainer.searchTextBox.localPosition.y = y
		y = y + 2
		for i = 1, #allTradesResponse.trades do
			mainWindow.contentContainer:addChild(newTradeWidget(y, allTradesResponse.trades, i))
			y = y + 4
		end
	end
end

local function showTrades(offset, count)
	mainWindow.contentContainer.searchTextBox = mainWindow.contentContainer:addInputTextBox(math.floor(mainWindow.width / 2 - 20), 1, 40, 1, 0x262626, 0x777777, 0x262626, 0xDDDDDD, nil, "Давай найдем че-нить", true)
	mainWindow.contentContainer.searchTextBox.onInputFinished = function()
		updateTrades(offset, count, mainWindow.contentContainer.searchTextBox.text)
	end
	updateTrades(offset, count)
end

------------------------------------------------ Inventory tab ------------------------------------------------

local function getUser(nickname)
	return databaseRequest("getUser=" .. nickname)
end

local function updateCurrentUser(nickname)
	local success, response = getUser(nickname)
	if success then
		currentUser = response
	end
end

local function newInventoryItemWidget(x, y, width, height, inventory, inventoryID, background, foreground1, foreground2)
	local object = GUI.container(x, y, width, height)
	object.inventoryID = inventoryID
	object:addPanel(1, 1, object.width, object.height, background)
	object:addLabel(2, 3, object.width - 2, 1, foreground1, inventory[inventoryID].label):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	if unicode.len(inventory[inventoryID].label) > object.width - 2 then
		object:addLabel(2, 4, object.width - 2, 1, foreground1, unicode.sub(inventory[inventoryID].label, object.width - 1, -1)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	end
	object:addLabel(2, 6, object.width - 2, 1, foreground2, math.shortenNumber(tonumber(inventory[inventoryID].count), 2)):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	return object
end

local function digitize(side, nickname)
	local items = ""
	for slot = 1, transposer.getInventorySize(side) do
		local stack = transposer.getStackInSlot(side, slot)
		if stack then
			items = items .. "&items[" .. (slot - 1) .. "][id]=" .. stack.name
			items = items .. "&items[" .. (slot - 1) .. "][data]=" .. stack.damage
			items = items .. "&items[" .. (slot - 1) .. "][label]=" .. stack.label
			items = items .. "&items[" .. (slot - 1) .. "][count]=" .. stack.size
		end
	end
	local file = io.open("PIDORAS.lua", "w")
	file:write(scriptAddress .. "addItemsToInventory=" .. nickname .. items)
	file:close()
	local success, response = databaseRequest("addItemsToInventory=" .. nickname .. items)
	if success and response.success then
		ecs.error("Оцифровочка завершена")
	end
end

local function updateInventory()
	mainWindow.contentContainer:deleteChildren(3)

	local width, height = 16, 8
	local xCountOfItems = math.floor((mainWindow.contentContainer.width - mainWindow.contentContainer.itemDetailContainer.width - 2) / width)
	local yCountOfItems = math.floor((mainWindow.contentContainer.height - 4) / height)
	local totalCountOfItems = xCountOfItems * yCountOfItems
	local fromItem = (mainWindow.contentContainer.currentPage - 1) * totalCountOfItems + 1
	mainWindow.contentContainer.countOfPages = math.ceil(#currentUser.inventory / totalCountOfItems)

	local x, y, chessStep, background, foreground1, foreground2 = 1, 1, true
	for j = 1, yCountOfItems do
		for i = 1, xCountOfItems do
			if currentUser.inventory[fromItem] then
				if fromItem == mainWindow.contentContainer.currentItem then
					background, foreground1, foreground2 = 0x66B680, 0xFFFFFF, 0x0
				else
					foreground1, foreground2 = 0x262626, 0x777777
					if chessStep then background = 0xEEEEEE else background = 0xDDDDDD end
				end

				local object = mainWindow.contentContainer:addChild(newInventoryItemWidget(x, y, width, height, currentUser.inventory, fromItem, background, foreground1, foreground2))
				for i = 1, #object.children do
					object.children[i].onTouch = function()
						mainWindow.contentContainer.currentItem = object.inventoryID
						updateInventory()
					end
				end
			else
				break
			end

			x, fromItem, chessStep = x + width, fromItem + 1, not chessStep
		end
		x, y = 1, y + height
	end

	if currentUser.inventory[mainWindow.contentContainer.currentItem] then
		mainWindow.contentContainer.itemTextBox.lines = {
			"ID: " .. currentUser.inventory[mainWindow.contentContainer.currentItem].id,
			"Data: " .. currentUser.inventory[mainWindow.contentContainer.currentItem].data,
			"Label: " .. currentUser.inventory[mainWindow.contentContainer.currentItem].label,
			"Count: " .. currentUser.inventory[mainWindow.contentContainer.currentItem].count,
		}
	end

	mainWindow.contentContainer.pagesContainer.pageLabel.text = mainWindow.contentContainer.currentPage .. " из " .. mainWindow.contentContainer.countOfPages
end

local function showInventory()
	mainWindow.contentContainer.currentPage = 1
	mainWindow.contentContainer.currentItem = 1
	mainWindow.contentContainer.countOfPages = 1

	local width = 32
	mainWindow.contentContainer.itemDetailContainer = mainWindow.contentContainer:addContainer(mainWindow.contentContainer.width - width + 1, 1, width, mainWindow.contentContainer.height)
	mainWindow.contentContainer.itemDetailContainer:addPanel(1, 1, mainWindow.contentContainer.itemDetailContainer.width, mainWindow.contentContainer.itemDetailContainer.height, 0xEEEEEE)
	
	mainWindow.contentContainer.itemTextBox = mainWindow.contentContainer.itemDetailContainer:addTextBox(2, 2, mainWindow.contentContainer.itemDetailContainer.width - 2, 5, nil, 0x262626, {}, 1, 0, 0)
	
	mainWindow.contentContainer.itemDetailContainer:addButton(1, mainWindow.contentContainer.itemDetailContainer.height - 8, mainWindow.contentContainer.itemDetailContainer.width, 3, 0x669280, 0xFFFFFF, 0x339240, 0xFFFFFF, "Оцифровать").onTouch = function(eventData)
		digitize(sides.up, eventData[6])
		updateCurrentUser(eventData[6])
		updateInventory()
	end
	mainWindow.contentContainer.itemDetailContainer:addButton(1, mainWindow.contentContainer.itemDetailContainer.height - 5, mainWindow.contentContainer.itemDetailContainer.width, 3, 0x66B680, 0xFFFFFF, 0x339240, 0xFFFFFF, "Материализовать")
	mainWindow.contentContainer.itemDetailContainer:addButton(1, mainWindow.contentContainer.itemDetailContainer.height - 2, mainWindow.contentContainer.itemDetailContainer.width, 3, 0x66DB80, 0xFFFFFF, 0x339240, 0xFFFFFF, "Продать")

	width = 25
	mainWindow.contentContainer.pagesContainer = mainWindow.contentContainer:addContainer(mainWindow.contentContainer.width - mainWindow.contentContainer.itemDetailContainer.width - width - 1, mainWindow.contentContainer.height - 2, width, 3)
	mainWindow.contentContainer.pagesContainer:addPanel(1, 1, mainWindow.contentContainer.pagesContainer.width, mainWindow.contentContainer.pagesContainer.height, 0xEEEEEE)
	mainWindow.contentContainer.pagesContainer.pageLabel = mainWindow.contentContainer.pagesContainer:addLabel(6, 2, mainWindow.contentContainer.pagesContainer.width - 10, 1, 0x262626, ""):setAlignment(GUI.alignment.horizontal.center, GUI.alignment.vertical.top)
	mainWindow.contentContainer.pagesContainer:addButton(1, 1, 5, mainWindow.contentContainer.pagesContainer.height, 0x66B680, 0xFFFFFF, 0x004900, 0xFFFFFF, "<").onTouch = function()
		if mainWindow.contentContainer.currentPage > 1 then
			mainWindow.contentContainer.currentPage = mainWindow.contentContainer.currentPage - 1
			updateInventory()
		end
	end
	mainWindow.contentContainer.pagesContainer:addButton(mainWindow.contentContainer.pagesContainer.width - 4, 1, 5, mainWindow.contentContainer.pagesContainer.height, 0x66B680, 0xFFFFFF, 0x004900, 0xFFFFFF, ">").onTouch = function()
		if mainWindow.contentContainer.currentPage < mainWindow.contentContainer.countOfPages then
			mainWindow.contentContainer.currentPage = mainWindow.contentContainer.currentPage + 1
			updateInventory()
		end
	end

	updateInventory()
end

------------------------------------------------ Mainwindow ------------------------------------------------

local function createWindow()
	mainWindow = windows.fullScreen()
	mainWindow.backgroundPanel = mainWindow:addPanel(1, 1, mainWindow.width, mainWindow.height, colors.background)
	mainWindow.tabBar = mainWindow:addTabBar(1, 1, mainWindow.width, 3, 1, 0xDDDDDD, 0x262626, 0xC4C4C4, 0x262626, "Купить", "Инвентарь", "Лотерея")
	mainWindow.tabBar.onTabSwitched = function(newTab, eventData)
		mainWindow.contentContainer:deleteChildren()
		if newTab == 1 then
			updateCurrentUser(eventData[6])
			showTrades(0, 50)
		elseif newTab == 2 then
			updateCurrentUser(eventData[6])
			showInventory(1, 1)
		end
	end
	mainWindow.contentContainer = mainWindow:addContainer(3, 5, mainWindow.width - 4, mainWindow.height - 5)
	
	mainWindow.onAnyEvent = function(eventData)
		if eventData[1] == "scroll" then
			if mainWindow.tabBar.selectedTab == 1 then
				for i = 1, #mainWindow.contentContainer.children do
					mainWindow.contentContainer.children[i].localPosition.y = mainWindow.contentContainer.children[i].localPosition.y + (eventData[5] == 1 and 2 or -2)
				end
			end
		end
		mainWindow:draw()
		buffer.draw()
	end
end

---------------------------------------------------- Meow-meow ----------------------------------------------------

buffer.start()
createWindow()

mainWindow:draw()
buffer.draw()
mainWindow:handleEvents(1)












