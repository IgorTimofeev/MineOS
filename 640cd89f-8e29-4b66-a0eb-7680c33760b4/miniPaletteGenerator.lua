
local libraries = {
	advancedLua = "advancedLua",
	colorlib = "colorlib",
	image = "image",
	buffer = "doubleBuffering",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end; libraries = nil


local function createPalette(width, height, hue)
	local picture = image.create(width, height)
	local saturation, brightness = 0, 100
	local saturationStep, brightnessStep = 100 / width, 100 / (height * 2)
	for j = 1, height do
		for i = 1, width do
			local background = colorlib.HSBtoHEX(hue, saturation, brightness)
			local foreground = colorlib.HSBtoHEX(hue, saturation, brightness - brightnessStep)
			image.set(picture, i, j, background, foreground, 0x0, "▄")
			saturation = saturation + saturationStep
		end
		saturation = 0
		brightness = brightness - brightnessStep - brightnessStep
	end
	return picture
end

buffer.clear(0xFFFFFF)
buffer.draw(true)

local hues = {0, }
local x, y = 2, 2
local paletteWidth, paletteHeight = 8, 4
for hue = 0, 360, 3.5 do
	local picture = createPalette(paletteWidth, paletteHeight, hue)
	buffer.image(x, y, picture)
	x = x + picture.width + 2
	if x >= buffer.screen.width - paletteWidth then 
		x = 2
		y = y + paletteHeight + 1
	end
end

buffer.draw()

-- local saveID = 5
-- image.save("palette" .. saveID .. ".pic", createPalette(paletteWidth, paletteHeight, hues[saveID]), 1)




