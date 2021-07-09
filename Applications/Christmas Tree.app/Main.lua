
-- Copyright (c) Totoro, ComputerCraft.ru

local system = require("System")
local GUI = require("GUI")
local filesystem = require("Filesystem")
local image = require("Image")

---------------------------------------------------------------------------------------------------------

local hologram

-- создаем модель елки
local tSpruce = {3, 2, 2, 2, 2, 8, 9, 10, 9, 8, 7, 6, 5, 4, 3, 4, 6, 8, 7, 6, 5, 4, 3, 6, 5, 4, 3, 2, 3, 2, 1}
-- создаем таблицу с падающими снежинками
local tSnow = {}

if not component.isAvailable("hologram") then
	GUI.alert("This program requires Tier 2 holographic projector")
	return
else
	hologram = component.get("hologram")
end

-----------------------------------------------------------

local workspace, window = system.addWindow(GUI.filledWindow(1, 1, 36, 18, 0x2D2D2D))

local layout = window:addChild(GUI.layout(1, 1, window.width, window.height, 1, 1))

local picture = layout:addChild(GUI.image(1, 1, image.load(filesystem.path(system.getCurrentScript()) .. "Icon.pic")))
picture.height = picture.height + 1

local function addSlider(min, max, value, ...)
	return layout:addChild(GUI.slider(1, 1, layout.width - 10, 0x66DB80, 0x0, 0xE1E1E1, 0x969696, min, max, value, false, ...))
end

local speedSlider = addSlider(0.1, 1, 0.8, "Speed: ", "")
local rotationSlider = addSlider(0, 100, 0, "Rotation: ", "")
local translationSlider = addSlider(0, 1, select(2, hologram.getTranslation()), "Translation: ", "")
local scaleSlider = addSlider(0.33, 3, hologram.getScale(), "Scale: ", "")
scaleSlider.height = 2

scaleSlider.onValueChanged = function()
	hologram.setScale(scaleSlider.value)
end

rotationSlider.onValueChanged = function()
	hologram.setRotationSpeed(rotationSlider.value, 0, 23, 0)
end

translationSlider.onValueChanged = function()
	hologram.setTranslation(0, translationSlider.value, 0)
end

window.onResize = function(width, height)
	window.backgroundPanel.width = width
	window.backgroundPanel.height = height

	layout.width = width
	layout.height = height
end

-- Главный йоба-цикл
local deadline = 0
layout.eventHandler = function(workspace, panel, e1)
	if computer.uptime() > deadline then
		-- генерируем снежинку
		local x, y, z, pixel = math.random(1, 46), 32, math.random(1, 46)
		table.insert(tSnow, {x = x, y = y, z = z})
		hologram.set(x, y, z, 1)

		-- сдвигаем снежинки вниз
		local i = 1
		while i <= #tSnow do
			if tSnow[i].y > 1 then
				x, y, z = tSnow[i].x + math.random(-1, 1), tSnow[i].y - 1, tSnow[i].z + math.random(-1, 1)
				
				if x < 1 then
					x = 1
				elseif x > 46 then
					x = 46
				end

				if z < 1 then
					z = 1
				elseif z > 46 then
					z = 46
				end
				
				pixel = hologram.get(x, y, z)
				
				if pixel == 0 or pixel == 1 then
					hologram.set(tSnow[i].x, tSnow[i].y, tSnow[i].z, 0)
					hologram.set(x, y, z, 1)
					
					tSnow[i].x, tSnow[i].y, tSnow[i].z = x, y, z
					i = i + 1
				else
					table.remove(tSnow,i)
				end
			else
				table.remove(tSnow,i)
			end
		end

		deadline = computer.uptime() + 1 - speedSlider.value
	end
end

-----------------------------------------------------------

-- Сначала интерфейс
workspace:draw()

-- очищаем прожектор
hologram.clear()
scaleSlider.onValueChanged()
rotationSlider.onValueChanged()

-- создаем палитру цветов
hologram.setPaletteColor(1, 0xFFFFFF) -- снег
hologram.setPaletteColor(2, 0x221100) -- ствол
hologram.setPaletteColor(3, 0x005522) -- хвоя

 -- задействуем алгоритм Брезенхэма для рисования кругов
local function cricle(x0, y, z0, R, i)
	local x = R
	local z = 0
	local err = -R
	while z <= x do
		hologram.set(x + x0, y, z + z0, i)
		hologram.set(z + x0, y, x + z0, i)
		hologram.set(-x + x0, y, z + z0, i)
		hologram.set(-z + x0, y, x + z0, i)
		hologram.set(-x + x0, y, -z + z0, i)
		hologram.set(-z + x0, y, -x + z0, i)
		hologram.set(x + x0, y, -z + z0, i)
		hologram.set(z + x0, y, -x + z0, i)
		z = z + 1
		if err <= 0 then
			err = err + (2 * z + 1)
		else
			x = x - 1
			err = err + (2 * (z - x) + 1)
		end
	end
end

 -- отрисовываем основание ствола
for i = 1, 5 do
	cricle(23, i, 23, tSpruce[i], 2)
	cricle(23, i, 23, tSpruce[i]-1, 2)
end

-- отрисовываем хвою
for j = 5, #tSpruce do
	cricle(23, j, 23, tSpruce[j]-1, 3)
	cricle(23, j, 23, tSpruce[j]-2, 3)
end
