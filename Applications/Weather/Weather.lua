
---------------------------------------------------- Библиотеки ----------------------------------------------------------------

local json = require("json")
local serialization = require("serialization")
local event = require("event")
local ecs = require("ECSAPI")
local fs = require("filesystem")
local bigLetters = require("bigLetters")
local buffer = require("doubleBuffering")
local image = require("image")
local unicode = require("unicode")
local files = require("files")
local component = require("component")
local GUI = require("GUI")

---------------------------------------------------- Константы ----------------------------------------------------------------

local weather = {}
local changeCityButton = {}
local exitButton = {}

local pathToWeatherFile = "MineOS/System/Weather/Forecast.cfg"
local pathToWallpaper = "MineOS/System/OS/Wallpaper.lnk"

local pathsToWeatherTypes = {
	sunny = "MineOS/Applications/Weather.app/Resources/Sunny.pic",
	sunnyWithClouds = "MineOS/Applications/Weather.app/Resources/SunnyWithClouds.pic",
	snowy = "MineOS/Applications/Weather.app/Resources/Snowy.pic",
	rainy = "MineOS/Applications/Weather.app/Resources/Rainy.pic",
	cloudy = "MineOS/Applications/Weather.app/Resources/Cloudy.pic",
	stormy = "MineOS/Applications/Weather.app/Resources/Stormy.pic",
}

local weatherIcons = {
	[0] = pathsToWeatherTypes.stormy,
	[1] = pathsToWeatherTypes.stormy,
	[2] = pathsToWeatherTypes.stormy,
	[3] = pathsToWeatherTypes.stormy,
	[4] = pathsToWeatherTypes.stormy,
	[5] = pathsToWeatherTypes.rainy,
	[6] = pathsToWeatherTypes.rainy,
	[7] = pathsToWeatherTypes.rainy,
	[8] = pathsToWeatherTypes.rainy,
	[9] = pathsToWeatherTypes.rainy,
	[10] = pathsToWeatherTypes.rainy,
	[11] = pathsToWeatherTypes.rainy,
	[12] = pathsToWeatherTypes.rainy,
	[13] = pathsToWeatherTypes.snowy,
	[14] = pathsToWeatherTypes.snowy,
	[15] = pathsToWeatherTypes.snowy,
	[16] = pathsToWeatherTypes.snowy,
	[17] = pathsToWeatherTypes.snowy,
	[18] = pathsToWeatherTypes.rainy,
	[19] = pathsToWeatherTypes.cloudy,
	[20] = pathsToWeatherTypes.cloudy,
	[21] = pathsToWeatherTypes.cloudy,
	[22] = pathsToWeatherTypes.cloudy,
	[23] = pathsToWeatherTypes.cloudy,
	[24] = pathsToWeatherTypes.cloudy,
	[25] = pathsToWeatherTypes.cloudy,
	[26] = pathsToWeatherTypes.cloudy,
	[27] = pathsToWeatherTypes.cloudy,
	[28] = pathsToWeatherTypes.cloudy,
	[29] = pathsToWeatherTypes.sunnyWithClouds,
	[30] = pathsToWeatherTypes.sunnyWithClouds,
	[31] = pathsToWeatherTypes.sunny,
	[32] = pathsToWeatherTypes.sunny,
	[33] = pathsToWeatherTypes.sunny,
	[34] = pathsToWeatherTypes.sunny,
	[35] = pathsToWeatherTypes.rainy,
	[36] = pathsToWeatherTypes.sunny,
	[37] = pathsToWeatherTypes.stormy,
	[38] = pathsToWeatherTypes.stormy,
	[39] = pathsToWeatherTypes.stormy,
	[40] = pathsToWeatherTypes.rainy,
	[41] = pathsToWeatherTypes.snowy,
	[42] = pathsToWeatherTypes.snowy,
	[43] = pathsToWeatherTypes.snowy,
	[44] = pathsToWeatherTypes.sunnyWithClouds,
	[45] = pathsToWeatherTypes.stormy,
	[46] = pathsToWeatherTypes.snowy,
	[47] = pathsToWeatherTypes.stormy,
}

local function request(url)
	local success, reason = pcall(component.internet.request, url)
	if success then
		local response = ""
		while true do
			local data, dataReason = reason.read()	
			if data then
				response = response .. data
			else
				if dataReason then
					return false, dataReason
				else
					return true, response
				end
			end
		end
	else
		return false, reason
	end
end

--Запрос на получение погоды
local function weatherRequest(city)
	local url = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22" .. city .. "%2C%20ak%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
	local success, response = request(url)

	if success then
		response = json:decode(response)
		if response.query and response.query.results and response.query.results.channel and response.query.results.channel.item and response.query.results.channel.item.condition and response.query.results.channel.item.condition.temp then
			return true, response
		else
			return false, "Ответ от Yahoo.com содержит неполную информацию, измените город или подождите некоторое время"
		end
	else
		return false, "Запрос погоды к Yahoo.com не удался. Повторите попытку."
	end
end

--Конвертим ПЕНДОССКИЕ мили в километры
local function convertMilesToKilometers(miles)
	return miles / 1.609344
end

--Конвертируем МИЛИ В ЧАС, блядь, в МЕТРЫ В СЕКУНДУ
local function convertMPHtoMS(mph)
	local kmph = convertMilesToKilometers(mph)
	local metersPerHour = 1000 * kmph
	local metersPerSecond = metersPerHour / 3600
	return metersPerSecond
end

--Конвертируем давление в паскалях в царские ММ РТ СТОЛБА,Е ПТА
local function converPascalsToMMHG(pascals)
	return pascals * 0.75006375541921
end

--Ну, а тут фаренгейт точеный в цельсий дроченый
local function convertFtoC(tempF)
	return ecs.adaptiveRound((tempF - 32) / 1.8)
end

--А тут ебашим пиздатую иконку состояния погоды для прогноза (не охуевшую)
local function drawCorrectWeatherIcon(x, y, weatherCode)
	buffer.image(x, y, image.load(weatherIcons[weatherCode] or pathsToWeatherTypes.sunny))
end

--Конвертирует направление ветра в градусах от 0 до 360 в словесную интерпретацию ХУЙНИ
local function getWindDirection(windAngle)
	local directions = {
		"северный",
		"северо-восточный",
		"восточный",
		"юго-восточный",
		"южный",
		"юго-западный",
		"западный",
		"северо-западный",
	}

	local step = 360 / #directions * 2
	local currentDirection = 1

	local windDirection = "N/A"

	for i = 0, 360, step do
		if windAngle >= i and windAngle <= (i + step) then
			windDirection = directions[currentDirection]
			break
		end
		currentDirection = currentDirection + 1
	end

	return windDirection
end

--Делаем массив погоды пиздатым, а не ебливо-пиндосским
--Ну, там фаренгейты в цельсий, залупу в пизду и т.п.
local function prepareJsonWeatherResponseFromDrawing(jsonWeatherResponse)
	weather.temperature = convertFtoC(jsonWeatherResponse.query.results.channel.item.condition.temp) .. "°"
	weather.pressure = "Давление: " .. ecs.adaptiveRound(converPascalsToMMHG(jsonWeatherResponse.query.results.channel.atmosphere.pressure)) .. " мм"
	weather.city = jsonWeatherResponse.query.results.channel.location.city .. ", " .. jsonWeatherResponse.query.results.channel.location.country
	weather.wind = "Ветер: " .. getWindDirection(tonumber(jsonWeatherResponse.query.results.channel.wind.direction)) .. ", " .. ecs.adaptiveRound(convertMPHtoMS(tonumber(jsonWeatherResponse.query.results.channel.wind.speed))) .. " м/с"
	weather.humidity = "Влажность: " .. jsonWeatherResponse.query.results.channel.atmosphere.humidity .. "%"

	weather.forecast = {}
	for i = 1, #jsonWeatherResponse.query.results.channel.item.forecast do
		weather.forecast[i] = {}
		weather.forecast[i].day = jsonWeatherResponse.query.results.channel.item.forecast[i].day
		weather.forecast[i].code = tonumber(jsonWeatherResponse.query.results.channel.item.forecast[i].code)
		weather.forecast[i].temperature = convertFtoC(tonumber(jsonWeatherResponse.query.results.channel.item.forecast[i].high)) .. " / " .. convertFtoC(tonumber(jsonWeatherResponse.query.results.channel.item.forecast[i].low)).. "°"
	end
end

local function drawWeather()
	--Рисуем обоинку или просто говнофон ССАНЫЙ
	if fs.exists(pathToWallpaper) then
		buffer.image(1, 1, image.load(ecs.readShortcut(pathToWallpaper)))
		buffer.square(1, 1, buffer.screen.width, buffer.screen.height, 0x0, 0x0, " ", 60)
	else
		buffer.clear(0x262626)
	end

	--Рисуем текущую температуру
	local x, y = 10, buffer.screen.height - 25
	bigLetters.drawText(x, y, 0xFFFFFF, weather.temperature, drawWithSymbol)
	y = y + 6
	--Рисуем название города
	buffer.text(x, y, 0xFFFFFF, weather.city)
	--Рисуем ветер
	y = y + 2
	buffer.text(x, y, 0xFFFFFF, weather.wind)
	y = y + 1
	buffer.text(x, y, 0xFFFFFF, weather.pressure)
	y = y + 1
	buffer.text(x, y, 0xFFFFFF, weather.humidity)
	--Рисуем КНОПАЧКИ
	y = y + 2
	changeCityButton = {buffer.button(x, y, 22, 1, 0xEEEEEE, 0x262626, "Другой город")}
	exitButton = {buffer.button(buffer.screen.width - 4, 2, 3, 1, 0xEEEEEE, 0x262626, "X")}

	--Рисуем долгосрочный прогноз
	y = y + 3
	for i = 1, #weather.forecast do
		--Рисуем дату
		buffer.text(x + 2, y, 0xFFFFFF, weather.forecast[i].day)
		--Рисуем КОРТИНАЧКУ
		drawCorrectWeatherIcon(x, y + 2, weather.forecast[i].code)
		--Рисуем температуру
		buffer.text(x, y + 7, 0xFFFFFF, weather.forecast[i].temperature)
		x = x + 11
	end
end

local function loadWeatherData()
	if fs.exists(pathToWeatherFile) then
		weather = files.loadTableFromFile(pathToWeatherFile)
	else
		weather = {
			myCity = "saint-petersburg",
			temperature = "0°",
			pressure = " ",
			city = "Получение информации о погоде...",
			wind = " ",
			humidity = " ",
			forecast = {},
		}
	end
end

local function saveWeatherData()
	files.saveTableToFile(pathToWeatherFile, weather)
end

local function tryToGetAndDrawWeather()
	local success, jsonWeatherResponse = weatherRequest(weather.myCity)
	if success then
		--Подготавливаем данные под РУССКОЕ отображение ГОВНА
		prepareJsonWeatherResponseFromDrawing(jsonWeatherResponse)
		--РЕСУЕМ ПАГОДУ
		drawWeather()
		buffer.draw()
		--Сейвим погодку
		saveWeatherData()
	else
		GUI.error(jsonWeatherResponse, {title = {color = 0xFF8888, text = "Ошибка"}})
	end
end

local function clicked(x, y, object)
	if x >= object[1] and y >= object[2] and x <= object[3] and y <= object[4] then return true end
	return false
end

--------------------------------------------------------------------------------------------------------------------

loadWeatherData()
drawWeather()
buffer.draw(true)

tryToGetAndDrawWeather()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		if clicked(e[3], e[4], changeCityButton) then
			local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
				{"EmptyLine"},
				{"CenterText", ecs.colors.orange, "Изменить город"},
				{"CenterText", ecs.colors.white, "(допускаются только названия по-английски)"},
				{"EmptyLine"},
				{"Input", 0xFFFFFF, ecs.colors.orange, weather.myCity},
				{"EmptyLine"},
				{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
			)

			if data[2] == "OK" then
				weather.myCity = data[1]
				tryToGetAndDrawWeather()
			end
		elseif clicked(e[3], e[4], exitButton) then
			-- buffer.clear(0x262626)
			-- ecs.prepareToExit()
			return
		end
	end
end










