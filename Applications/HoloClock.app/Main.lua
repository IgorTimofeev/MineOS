
local text = require("Text")
local number = require("Number")
local filesystem = require("Filesystem")
local event = require("Event")
local screen = require("Screen")
local paths = require("Paths")
local GUI = require("GUI")

--------------------------------------------------------------------------------------------

if not component.isAvailable("hologram") then
  GUI.alert("This program needs a Tier 2 holo-projector to work")
  return
end

local hologram = component.get("hologram")

local date
local path = paths.user.applicationData .. "/HoloClock/Settings.cfg"
local config = {
	dateColor = 0xFFFFFF,
	holoScale = 1
}

--------------------------------------------------------------------------------------------

local symbols = {
	["0"] = {
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	["1"] = {
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
	},
	["2"] = {
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 0, 1, 1, 1, 0 },
	},
	["3"] = {
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	["4"] = {
		{ 0, 0, 0, 0, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
	},
	["5"] = {
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	["6"] = {
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 1, 0, 0, 0, 0 },
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	["7"] = {
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 0 },
	},
	["8"] = {
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	["9"] = {
		{ 0, 1, 1, 1, 0 },
		{ 1, 0, 0, 0, 1 },
		{ 1, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 0, 0, 0, 1 },
		{ 0, 1, 1, 1, 0 },
	},
	[":"] = {
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 1, 0, 0 },
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 1, 0, 0 },
		{ 0, 0, 0, 0, 0 },
		{ 0, 0, 0, 0, 0 },
	},
}

--------------------------------------------------------------------------------------------

local function save()
	filesystem.writeTable(path, config)
end

local function load()
	if filesystem.exists(path) then
		config = filesystem.readTable(path)
	else
		save()
	end
end

--------------------------------------------------------------------------------------------

local function drawSymbolOnScreen(x, y, symbol, color)
	local xPos = x
	for j = 1, #symbols[symbol] do
		for i = 1, #symbols[symbol][j] do
			if symbols[symbol][j][i] == 1 then
				screen.drawRectangle(xPos, y, 2, 1, color, 0x000000, " ")
			end
			xPos = xPos + 2
		end
		xPos = x
		y = y + 1
	end
end


local function drawSymbolOnProjector(x, y, z, symbol)
	local xPos = x
	for j = 1, #symbols[symbol] do
		for i = 1, #symbols[symbol][j] do
			if symbols[symbol][j][i] == 1 then
				hologram.set(xPos, y, z, 1)
			else
				hologram.set(xPos, y, z, 0)
			end
			xPos = xPos + 1
		end
		xPos = x
		y = y - 1
	end
end

local function drawText(x, y, text, color)
	for i = 1, unicode.len(text) do
		local symbol = unicode.sub(text, i, i)
		drawSymbolOnScreen(x, y, symbol, color)
		drawSymbolOnProjector(i * 6 + 4, 16, 24, symbol)
		x = x + 12
	end
end

local function changeHoloColor()
	hologram.setPaletteColor(1, config.dateColor)
end

local function getDate()
	date = string.sub(os.date("%T"), 1, -4)
end

local function flashback()
	screen.clear(0x0, 0.3)
end

local function draw()
	local width, height = 58, 7
	local x, y = math.floor(screen.getWidth() / 2 - width / 2), math.floor(screen.getHeight() / 2 - height / 2)

	drawText(x, y, "88:88", 0x000000)
	drawText(x, y, date, config.dateColor)

	y = y + 9
	GUI.label(1, y, screen.getWidth(), 1, config.dateColor, "Press R to randomize clock color, scroll to change projection scale,"):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP):draw(); y = y + 1
	GUI.label(1, y, screen.getWidth(), 1, config.dateColor, "or press Enter to save and quit"):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP):draw()
	-- GUI.label(1, y, screen.getWidth(), 1, 0xFFFFFF, ""):draw()

	screen.update()
end

--------------------------------------------------------------------------------------------

load()
hologram.clear()
changeHoloColor()
hologram.setScale(config.holoScale)
flashback()

while true do
	getDate()
	draw()

	local e = {event.pull(1)}
	if e[1] == "scroll" then
		if e[5] == 1 then
			if config.holoScale < 4 then config.holoScale = config.holoScale + 0.1; hologram.setScale(config.holoScale); save() end
		else
			if config.holoScale > 0.33 then config.holoScale = config.holoScale - 0.1; hologram.setScale(config.holoScale); save() end
		end
	elseif e[1] == "key_down" then
		if e[4] == 19 then
			config.dateColor = math.random(0x666666, 0xFFFFFF)
			changeHoloColor()
			save()
		elseif e[4] == 28 then
			save()
			hologram.clear()
			return
		end
	end
end




