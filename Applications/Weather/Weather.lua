
require("advancedLua")
local web = require("web")
local json = require("json")
local fs = require("filesystem")
local bigLetters = require("bigLetters")
local buffer = require("doubleBuffering")
local image = require("image")
local unicode = require("unicode")
local component = require("component")
local GUI = require("GUI")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")

--------------------------------------------------------------------------------------------------------

local application, window = MineOSInterface.addWindow(GUI.filledWindow(1, 1, 130, 30, 0))
window.backgroundPanel.colors.transparency = 0.2

local weatherContainer = window:addChild(GUI.container(1, 1, 1, 23))

local configPath = MineOSPaths.applicationData .. "Weather/Config.cfg"
local resources = MineOSCore.getCurrentScriptDirectory()
local weatherIcons = {
	sunny = image.load(resources .. "Sunny.pic"),
	sunnyAndCloudy = image.load(resources .. "Icon.pic"),
	snowy = image.load(resources .. "Snowy.pic"),
	rainy = image.load(resources .. "Rainy.pic"),
	cloudy = image.load(resources .. "Cloudy.pic"),
	thundery = image.load(resources .. "Stormy.pic"),
	foggy = image.load(resources .. "Foggy.pic"),
}

local config = {
	lastCityName = "Санкт-Петербург"
}

--------------------------------------------------------------------------------------------------------

local function newWeather(x, y, day)
	local object = GUI.object(x, y, 14, 11)

	local type
	if day.weather[1].id == 800 then
		type = "sunny"
	elseif day.weather[1].id == 801 then
		type = "sunnyAndCloudy"
	elseif day.weather[1].id >= 800 then
		type = "cloudy"
	elseif day.weather[1].id >= 700 then
		type = "foggy"
	elseif day.weather[1].id >= 600 then
		type = "snowy"
	elseif day.weather[1].id >= 300 then
		type = "rainy"
	elseif day.weather[1].id >= 200 then
		type = "thundery"
	else
		type = "sunnyAndCloudy"
	end

	local temp = math.round(day.temp.min) .. " / " .. math.round(day.temp.max) .. " °C"
	local pressure = math.round(day.pressure / 1.33322387415) .. " mm Hg"
	local humidity = math.round(day.humidity) .. "%"
	local winds = {
		[0] = "N",
		[1] = "NE",
		[2] = "E",
		[3] = "SE",
		[4] = "S",
		[5] = "SW",
		[6] = "W",
		[7] = "NW",
		[8] = "N",
	}
	local wind = day.speed .. " m/s, " .. (winds[math.round(day.deg / 45)] or "N/A")

	local function centerText(y, color, text)
		buffer.drawText(math.floor(object.x + object.width / 2 - unicode.len(text) / 2), y, color, text)
	end

	object.draw = function()
		centerText(object.y, 0xFFFFFF, os.date("%a", day.dt))
		buffer.drawImage(object.x + 3, object.y + 2, weatherIcons[type])
		centerText(object.y + 7, 0xFFFFFF, temp)
		centerText(object.y + 8, 0xDDDDDD, wind)
		centerText(object.y + 9, 0xBBBBBB, pressure)
		centerText(object.y + 10, 0x999999, humidity)
	end

	return object
end

local function updateForecast()
	local result, reason = web.request("http://api.openweathermap.org/data/2.5/forecast/daily?&appid=98ba4333281c6d0711ca78d2d0481c3d&units=metric&cnt=17&q=" .. web.encode(config.lastCityName))
	if result then
		result = json.decode(result)
		
		if result.list then
			weatherContainer:removeChildren()

			local x, y = 1, 1
			local currentDay = result.list[1]
			local object = weatherContainer:addChild(GUI.object(x + 2, y, 40, 8))
			object.draw = function()
				bigLetters.drawText(object.x, object.y, 0xFFFFFF, math.round((currentDay.temp.max + currentDay.temp.min) / 2) .. "°")
				buffer.drawText(object.x, object.y + 6, 0xFFFFFF, result.city.name .. ", " .. result.city.country)
				buffer.drawText(object.x, object.y + 7, 0xFFFFFF, "Population: " .. math.shorten(result.city.population, 2))
			end

			y = y + object.height + 1

			local input = weatherContainer:addChild(GUI.input(x + 2, y, 25, 1, 0xE1E1E1, 0x696969, 0x878787, 0xE1E1E1, 0x2D2D2D, "", "Type city name here"))
			input.onInputFinished = function()
				config.lastCityName = input.text
				updateForecast()
			end

			y = y + input.height + 2

			for i = 1, #result.list do
				local object = weatherContainer:addChild(newWeather(x, y, result.list[i]))
				x = x + object.width + 2
			end

			MineOSInterface.application:draw()
			table.toFile(configPath, config)
		else
			GUI.alert(result.message)
		end
	else
		GUI.alert("Wrong result. Check city name and try again.")
	end
end


--------------------------------------------------------------------------------------------------------

window.onResize = function(width, height)
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height
	weatherContainer.width = width
	weatherContainer.localY = height - weatherContainer.height - 1
	weatherContainer.localX = 3
end

window:resize(window.width, window.height)
MineOSInterface.application:draw()

if fs.exists(configPath) then
	config = table.fromFile(configPath)
end

updateForecast()











