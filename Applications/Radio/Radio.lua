
package.loaded.bigLetters = nil
local buffer = require("doubleBuffering")
local bigLetters = require("bigLetters")
local unicode = require("unicode")
local component = require("component")
local fs = require("filesystem")
local context = require("context")
local serialization = require("serialization")
local radio

if not component.isAvailable("openfm_radio") then
	ecs.error("Этой программе требуется радио из мода OpenFM. Причем не на всех версиях еще работает, автор мода - пидор! Проверял на ноябрьской, полет нормальный.")
	return
else
	radio = component.openfm_radio
end

local pathToSaveStations = "MineOS/System/Radio/Stations.cfg"
local stationNameLimit = 8
local spaceBetweenStations = 8
local countOfStationsLimit = 9
local lineHeight

local config = {
	colors = {
		background = 0x1b1b1b,
		line = 0xFFFFFF,
		lineShadow = 0x000000,
		activeStation = 0xFFA800,
		otherStation = 0xBBBBBB,
		bottomToolBarDefaultColor = 0xaaaaaa,
		bottomToolBarCurrentColor = 0xFFA800,
	},
}

local radioStations = {
	currentStation = 3,
	{
		name = "Galnet Soft",
		url = "http://galnet.ru:8000/soft"
	},
	{
		name = "Европа Плюс",
		url = "http://ep256.streamr.ru"
	},
	{
		name = "L-Radio",
		url = "http://server2.lradio.ru:8000/lradio64.aac.m3u"
	},
	{
		name = "Radio Record",
		url = "http://online.radiorecord.ru:8101/rr_128.m3u"
	},
	{
		name = "Moscow FM",
		url = "http://livestream.rfn.ru:8080/moscowfmen128.m3u"
	},
}

--Объекты для тача
local obj = {}

local function drawStation(x, y, name, color)
	bigLetters.drawText(x, y, color, name)
end

local function drawLine()
	local x = math.floor(buffer.screen.width / 2)
	for i = 1, lineHeight do
		buffer.text(x + 1, i, config.colors.lineShadow, "▎")
		buffer.text(x, i, config.colors.line, "▍")
	end
end

local function drawLeftArrow(x, y, color)
	local bg, fg = config.colors.background, color
	local arrow = {
		{ {bg, fg, " "}, {bg, fg, " "}, {bg, fg, "*"} },
		{ {bg, fg, " "}, {bg, fg, "*"}, {bg, fg, " "} },
		{ {bg, fg, "*"}, {bg, fg, " "}, {bg, fg, " "} },
		{ {bg, fg, " "}, {bg, fg, "*"}, {bg, fg, " "} },
		{ {bg, fg, " "}, {bg, fg, " "}, {bg, fg, "*"} },
	}
	buffer.customImage(x, y, arrow)
end

local function drawRightArrow(x, y, color)
	local bg, fg = config.colors.background, color
	local arrow = {
		{ {bg, fg, "*"}, {bg, fg, " "}, {bg, fg, " "} },
		{ {bg, fg, " "}, {bg, fg, "*"}, {bg, fg, " "} },
		{ {bg, fg, " "}, {bg, fg, " "}, {bg, fg, "*"} },
		{ {bg, fg, " "}, {bg, fg, "*"}, {bg, fg, " "} },
		{ {bg, fg, "*"}, {bg, fg, " "}, {bg, fg, " "} },
	}
	buffer.customImage(x, y, arrow)
end

local function drawMenu()
	local width = 36 + (3 * 2 + 2) * #radioStations
	local x, y = math.floor(buffer.screen.width / 2 - width / 2), lineHeight + math.floor((buffer.screen.height - lineHeight) / 2 - 1)

	obj.gromkostPlus = {x, y, x + 4, y + 3}
	x = bigLetters.drawText(x, y, config.colors.bottomToolBarDefaultColor, "+", "*") + 1
	x = x + 1

	obj.strelkaVlevo = {x, y, x + 4, y + 3}
	drawLeftArrow(x, y, config.colors.bottomToolBarDefaultColor); x = x + 5
	x = x + 3
	
	local color
	for i = 1, #radioStations  do
		if i == radioStations.currentStation then color = config.colors.bottomToolBarCurrentColor else color = config.colors.bottomToolBarDefaultColor end
		x = bigLetters.drawText(x, y, color, tostring(i), "*") + 1
	end
	
	x = x + 2
	obj.strelkaVpravo = {x, y, x + 4, y + 3}
	drawRightArrow(x, y, config.colors.bottomToolBarDefaultColor)

	x = x + 8
	obj.gromkostMinus = {x, y, x + 4, y + 3}
	x = bigLetters.drawText(x, y, config.colors.bottomToolBarDefaultColor, "-", "*") + 1
end

local function drawStations()
	local prevWidth, currentWidth, nextWidth, name

	-- Текущая станция
	name = ecs.stringLimit("end", unicode.lower(radioStations[radioStations.currentStation].name), stationNameLimit, true)
	currentWidth = bigLetters.getTextSize(name)
	local x, y = math.floor(buffer.screen.width / 2 - currentWidth / 2), math.floor(buffer.screen.height / 2 - 3)
	drawStation(x, y, name, config.colors.activeStation)

	-- Предедущая
	if radioStations[radioStations.currentStation - 1] then
		name = ecs.stringLimit("start", unicode.lower(radioStations[radioStations.currentStation - 1].name), stationNameLimit)
		prevWidth = bigLetters.getTextSize(name)
		drawStation(x - prevWidth - spaceBetweenStations, y, name, config.colors.otherStation)
	end
	
	-- Следующая
	if radioStations[radioStations.currentStation + 1] then
		name = ecs.stringLimit("end", unicode.lower(radioStations[radioStations.currentStation + 1].name), stationNameLimit)
		nextWidth = bigLetters.getTextSize(name)
		drawStation(x + currentWidth + spaceBetweenStations + 1, y, name, config.colors.otherStation)
	end
	-- ecs.error(x, x - prevWidth - spaceBetweenStations, prevWidth, currentWidth, nextWidth)
end

local function drawAll()
	-- Коррекция от кривых ручонок юзверей
	if radioStations.currentStation < 1 then
		radioStations.currentStation = 1
	elseif radioStations.currentStation > #radioStations then
		radioStations.currentStation = #radioStations
	end

	buffer.square(1, 1, buffer.screen.width, buffer.screen.height, config.colors.background, 0xFFFFFF, " ")

	drawStations()
	drawLine()
	drawMenu()

	buffer.draw()
end

local function saveStations()
	fs.makeDirectory(fs.path(pathToSaveStations))
	local file = io.open(pathToSaveStations, "w")
	file:write(serialization.serialize(radioStations))
	file:close()
end

local function loadStations()
	if fs.exists(pathToSaveStations) then
		local file = io.open(pathToSaveStations, "r")
		radioStations = serialization.unserialize(file:read("*a"))
		file:close()
	else
		saveStations()
	end
end

local function switchStation(i)
	if i == 1 then
		if radioStations.currentStation < #radioStations then
			radioStations.currentStation = radioStations.currentStation + 1
			saveStations()
			radio.stop()
			radio.setURL(radioStations[radioStations.currentStation].url)
			radio.start()
		end
	else
		if radioStations.currentStation > 1 then
			radioStations.currentStation = radioStations.currentStation - 1
			saveStations()
			radio.stop()
			radio.setURL(radioStations[radioStations.currentStation].url)
			radio.start()
		end
	end
end

local function volume(i)
	if i == 1 then
		radio.volUp()
	else
		radio.volDown()
	end
end


buffer.start()
lineHeight = math.floor(buffer.screen.height * 0.7)
loadStations()
radio.stop()
radio.setURL(radioStations[radioStations.currentStation].url)
radio.start()
drawAll()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		if e[5] == 0 then
			if ecs.clickedAtArea(e[3], e[4], obj.strelkaVlevo[1], obj.strelkaVlevo[2], obj.strelkaVlevo[3], obj.strelkaVlevo[4]) then
				drawLeftArrow(obj.strelkaVlevo[1], obj.strelkaVlevo[2], config.colors.bottomToolBarCurrentColor)
				buffer.draw()
				os.sleep(0.2)
				switchStation(-1)
				drawAll()
			elseif ecs.clickedAtArea(e[3], e[4], obj.strelkaVpravo[1], obj.strelkaVpravo[2], obj.strelkaVpravo[3], obj.strelkaVpravo[4]) then
				drawRightArrow(obj.strelkaVpravo[1], obj.strelkaVpravo[2], config.colors.bottomToolBarCurrentColor)
				buffer.draw()
				os.sleep(0.2)
				switchStation(1)
				drawAll()
			elseif ecs.clickedAtArea(e[3], e[4], obj.gromkostPlus[1], obj.gromkostPlus[2], obj.gromkostPlus[3], obj.gromkostPlus[4]) then
				bigLetters.drawText(obj.gromkostPlus[1], obj.gromkostPlus[2], config.colors.bottomToolBarCurrentColor, "+", "*" )
				buffer.draw()
				volume(1)
				os.sleep(0.2)
				drawAll()
			elseif ecs.clickedAtArea(e[3], e[4], obj.gromkostMinus[1], obj.gromkostMinus[2], obj.gromkostMinus[3], obj.gromkostMinus[4]) then
				bigLetters.drawText(obj.gromkostMinus[1], obj.gromkostMinus[2], config.colors.bottomToolBarCurrentColor, "-", "*" )
				buffer.draw()
				volume(-1)
				os.sleep(0.2)
				drawAll()
			end
		else
			local action = context.menu(e[3], e[4], {"Добавить станцию", #radioStations >= countOfStationsLimit}, {"Удалить станцию", #radioStations < 2}, "-", {"О программе"}, "-", {"Выход"})
			if action == "Добавить станцию" then
				local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
					{"EmptyLine"},
					{"CenterText", ecs.colors.orange, "Добавить станцию"},
					{"EmptyLine"},
					{"Input", 0xFFFFFF, ecs.colors.orange, "Название станции"},
					{"Input", 0xFFFFFF, ecs.colors.orange, "URL-ссылка на стрим"},
					{"EmptyLine"},
					{"Button", {ecs.colors.orange, 0x262626, "OK"}, {0x999999, 0xffffff, "Отмена"}}
				)
				if data[3] == "OK" then
					table.insert(radioStations, {name = data[1], url = data[2]})
					saveStations()
					drawAll()
				end
			elseif action == "Удалить станцию" then
				table.remove(radioStations, radioStations.currentStation)
				saveStations()
				drawAll()

			elseif action == "О программе" then
				ecs.universalWindow("auto", "auto", 36, 0x262626, true, 
					{"EmptyLine"},
					{"CenterText", ecs.colors.orange, "Radio v1.0"}, 
					{"EmptyLine"},
					{"CenterText", 0xFFFFFF, "Автор:"},
					{"CenterText", 0xBBBBBB, "Тимофеев Игорь"},
					{"CenterText", 0xBBBBBB, "vk.com/id7799889"},
					{"EmptyLine"},
					{"CenterText", 0xFFFFFF, "Тестер:"},
					{"CenterText", 0xBBBBBB, "Олег Гречкин"}, 
					{"CenterText", 0xBBBBBB, "http://vk.com/id250552893"},
					{"EmptyLine"},
					{"CenterText", 0xFFFFFF, "Автор идеи:"},
					{"CenterText", 0xBBBBBB, "MrHerobrine с Dreamfinity"}, 
					{"EmptyLine"},
					{"Button", {ecs.colors.orange, 0xffffff, "OK"}}
				)
			elseif action == "Выход" then
				buffer.square(1, 1, buffer.screen.width, buffer.screen.height, config.colors.background, 0xFFFFFF, " ")
				buffer.draw()
				ecs.prepareToExit()
				radio.stop()
				return
			end
		end

	elseif e[1] == "scroll" then
		switchStation(e[5])
		drawAll()
	end
end







