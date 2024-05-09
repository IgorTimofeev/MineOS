local screen = require("Screen")
local color = require("Color")
local filesystem = require("Filesystem")
local system = require("System")
local GUI = require("GUI")
local image = require("Image")

--------------------------------------------------------------------------------

local workspace, wallpaper = select(1, ...), select(2, ...)

local configPath = filesystem.path(system.getCurrentScript()) .. "Config.cfg"

local config = {
	backgroundColor = 0x000000,
	speed = 1
}

if filesystem.exists(configPath) then
	for key, value in pairs(filesystem.readTable(configPath)) do
		config[key] = value
	end
end

local function saveConfig()
	filesystem.writeTable(configPath, config)
end

--------------------------------------------------------------------------------

local logo = image.load(filesystem.path(system.getCurrentScript()) .. "Logo.pic")

local logoPosition = {
	x = math.random(1, wallpaper.width  - image.getWidth (logo)),
	y = math.random(1, wallpaper.height - image.getHeight(logo))
}

local logoSpeed = {
	x = (2 * math.random() - 1) * 10,
	y = (2 * math.random() - 1) * 10
}

local lastUpdateTime = computer.uptime()

--------------------------------------------------------------------------------

wallpaper.draw = function(wallpaper)
	local currentTime = computer.uptime()
	local deltaTime = currentTime - lastUpdateTime
	lastUpdateTime = currentTime

	screen.drawRectangle(wallpaper.x, wallpaper.y, wallpaper.width, wallpaper.height, config.backgroundColor, 0, " ")
	screen.drawImage(wallpaper.x + math.floor(logoPosition.x), wallpaper.y + math.floor(logoPosition.y), logo)

	logoPosition.x = logoPosition.x + logoSpeed.x * config.speed * deltaTime
	logoPosition.y = logoPosition.y + logoSpeed.y * config.speed * deltaTime

	if logoPosition.x < 1 or logoPosition.x >= wallpaper.width - image.getWidth(logo) then
		logoSpeed.x = -logoSpeed.x
	end

	if logoPosition.y < 1 or logoPosition.y >= wallpaper.height - image.getHeight(logo) then
		logoSpeed.y = -logoSpeed.y
	end
end

wallpaper.configure = function(layout)
	layout:addChild(GUI.colorSelector(1, 1, 36, 3, config.backgroundColor, "Background color")).onColorSelected = function(_, object)
		config.backgroundColor = object.color
		saveConfig()
	end

	local speedSlider = layout:addChild(
		GUI.slider(
			1, 1, 
			36,
			0x66DB80, 
			0xE1E1E1, 
			0xFFFFFF, 
			0xA5A5A5, 
			0, 50, 
			config.speed, 
			false, 
			"Speed: "
		)
	)

	speedSlider.onValueChanged = function()
		config.speed = math.floor(speedSlider.value)
		saveConfig()
	end	
end

--------------------------------------------------------------------------------