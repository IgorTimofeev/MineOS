
------------------------------------------ Библиотеки -----------------------------------------------------------------


local component = require("component")
local colorlib = require("colorlib")
local event = require("event")
local gpu = component.gpu
local printer = component.printer3d
local hologram = component.hologram

------------------------------------------ Переменные -----------------------------------------------------------------

local pixels = {}

local model = {
	label = "Sosi hui",
	tooltip = "mamu ebal",
	buttonMode = true,
	redstoneEmitter = true,
	active = {
		{x = 1, y = 1, z = 1, x2 = 1, y2 = 1, z2 = 12},
		
		{x = 1, y = 8, z = 1, x2 = 8, y2 = 8, z2 = 16},

		{x = 16, y = 16, z = 16, x2 = 16, y2 = 16, z2 = 16},
	},
	passive = {}
}

local colors = {
	objects = 0x3349FF,
	points = 0xFFFFFF,
	border = 0xFFFF00,
	background = 0x262626,
	rightBar = 0x383838,
	lines = 0x222222,

}
local countOfShapes = printer.getMaxShapeCount()
local adder = 360 / countOfShapes
local hue = 0
colors.shapes = {}
for i = 1, countOfShapes do
	table.insert(colors.shapes, colorlib.HSBtoHEX(hue, 100, 100))
	hue = hue + adder
end

local sizes = {}
sizes.oldResolutionWidth, sizes.oldResolutionHeight = gpu.getResolution()
sizes.xSize, sizes.ySize = gpu.maxResolution()
--
sizes.widthOfRightBar, sizes.heightOfRightBar = 36, sizes.ySize
sizes.xStartOfRightBar, sizes.yStartOfRightBar = sizes.xSize - sizes.widthOfRightBar + 1, 1
--
sizes.widthOfHorizontal = sizes.xSize - sizes.widthOfRightBar
sizes.xStartOfVertical, sizes.yStartOfVertical = math.floor(sizes.widthOfHorizontal / 2), 1
sizes.xStartOfHorizontal, sizes.yStartOfHorizontal = 1, math.floor(sizes.ySize / 2)
--
sizes.widthOfPixel, sizes.heightOfPixel = 2, 1
sizes.image = {}

sizes.image[1] = {x = math.floor(sizes.xStartOfVertical / 2 - (sizes.widthOfPixel * 16) / 2), y = math.floor(sizes.yStartOfHorizontal / 2 - (sizes.heightOfPixel * 16) / 2)}
sizes.image[2] = {x = sizes.xStartOfVertical + sizes.image[1].x + 1, y = sizes.image[1].y}
sizes.image[3] = {x = sizes.image[1].x, y = sizes.yStartOfHorizontal + sizes.image[1].y + 1}
sizes.image[4] = {x = sizes.image[2].x, y = sizes.image[3].y}

local holoOutlineX, holoOutlineY, holoOutlineZ = 16, 24, 16
local currentShape = 1
local currentLayer = 1

------------------------------------------ Функции -----------------------------------------------------------------

local function drawTransparentBackground(x, y, color1, color2)
	local xPos, yPos = x, y
	local color
	for j = 1, 16 do
		for i = 1, 16 do
			if i % 2 == 0 then
				if j % 2 == 0 then
					color = color1
				else
					color = color2
				end
			else
				if j % 2 == 0 then
					color = color2
				else
					color = color1
				end
			end
			ecs.square(xPos, yPos, sizes.widthOfPixel, sizes.heightOfPixel, color)
			xPos = xPos + sizes.widthOfPixel
		end
		xPos = x
		yPos = yPos + sizes.heightOfPixel
	end
end

local function changePalette()
	hologram.setPaletteColor(1, colors.objects)
	hologram.setPaletteColor(2, colors.points)
	hologram.setPaletteColor(3, colors.border)
end

local function drawShapesList(x, y)
	local xPos, yPos = x, y
	local color
	for i = 1, countOfShapes do
		color = 0x000000
		if i == currentShape then color = colors.shapes[i] end
		ecs.drawButton(xPos, yPos, 4, 1, tostring(i), color, 0xFFFFFF )
		xPos = xPos + 5
		if i % 6 == 0 then xPos = x; yPos = yPos + 2 end
	end
end

local function drawInfo(y, info)
	ecs.square(sizes.xStartOfRightBar, y, sizes.widthOfRightBar, 1, 0x000000)
	ecs.colorText(sizes.xStartOfRightBar + 2, y, 0xFFFFFF, info)
end

local function drawRightBar()
	local xPos, yPos = sizes.xStartOfRightBar, sizes.yStartOfRightBar
	ecs.square(xPos, yPos, sizes.widthOfRightBar, sizes.heightOfRightBar, colors.rightBar)
	
	drawInfo(yPos, "Работа с моделью"); yPos = yPos + 2

	yPos = yPos + 5

	drawInfo(yPos, "Работа с объектом"); yPos = yPos + 2

	yPos = yPos + 5

	drawInfo(yPos, "Выбор объекта"); yPos = yPos + 3
	drawShapesList(xPos + 2, yPos); yPos = yPos + (countOfShapes / 6 * 2) + 1

	drawInfo(yPos, "Управление голограммой"); yPos = yPos + 2

	yPos = yPos + 5


	drawInfo(yPos, "Управление принтером"); yPos = yPos + 2

	yPos = yPos + 5


end

local function drawLines()
	ecs.square(sizes.xStartOfVertical, sizes.yStartOfVertical, 2, sizes.ySize,colors.lines)
	ecs.square(sizes.xStartOfHorizontal, sizes.yStartOfHorizontal, sizes.widthOfHorizontal , 1, colors.lines)
end

local function drawViewArray(x, y, massiv)
	local xPos, yPos = x, y
	for i = 1, #massiv do
		for j = 1, #massiv[i] do
			if massiv[i][j] ~= "#" then
				ecs.square(xPos, yPos, sizes.widthOfPixel, sizes.heightOfPixel, massiv[i][j])
			end
			xPos = xPos + sizes.widthOfPixel
		end
		xPos = x
		yPos = yPos + sizes.heightOfPixel
	end
end

--Нарисовать вид спереди
local function drawFrontView()
	local massiv = {}
	for i = 1, 16 do
		massiv[i] = {}
		for j = 1, 16 do
			massiv[i][j] = "#"
		end
	end
	for x = 1, #pixels do
		for y = 1, #pixels[x] do
			for z = 1, #pixels[x][y] do
				if pixels[x][y][z] ~= "#" then
					massiv[y][x] = pixels[x][y][z]
				end
			end
		end
	end
	drawViewArray(sizes.image[1].x, sizes.image[1].y, massiv)
end

--Нарисовать вид сверху
local function drawTopView()
	local massiv = {}
	for i = 1, 16 do
		massiv[i] = {}
		for j = 1, 16 do
			massiv[i][j] = "#"
		end
	end
	for x = 1, #pixels do
		for y = 1, #pixels[x] do
			for z = 1, #pixels[x][y] do
				if pixels[x][y][z] ~= "#" then
					massiv[z][x] = pixels[x][y][z]
				end
			end
		end
	end
	drawViewArray(sizes.image[3].x, sizes.image[3].y, massiv)
end

--Нарисовать вид сбоку
local function drawSideView()
	local massiv = {}
	for i = 1, 16 do
		massiv[i] = {}
		for j = 1, 16 do
			massiv[i][j] = "#"
		end
	end
	for x = 1, #pixels do
		for y = 1, #pixels[x] do
			for z = 1, #pixels[x][y] do
				if pixels[x][y][z] ~= "#" then
					massiv[y][z] = pixels[x][y][z]
				end
			end
		end
	end
	drawViewArray(sizes.image[2].x, sizes.image[2].y, massiv)
end

--Сконвертировать массив объектов в трехмерный массив 3D-изображения
local function render()
	pixels = {}

	for x = 1, 16 do
		pixels[x] = {}
		for y = 1, 16 do
			pixels[x][y] = {}
			for z = 1, 16 do
				pixels[x][y][z] = "#"
			end
		end
	end

	for x = 1, 16 do
		for y = 1, 16 do
			for z = 1, 16 do
				for i = 1, #model.active do
					if (x >= model.active[i].x and x <= model.active[i].x2) and (y >= model.active[i].y and y <= model.active[i].y2) and (z >= model.active[i].z and z <= model.active[i].z2) then
						pixels[x][y][z] = colors.shapes[i]
						--hologram.set(x, y, z, 1)
					end				
				end
			end
		end
	end
end

local function drawBorder()
	for i = 0, 17 do
		hologram.set(i + holoOutlineX, holoOutlineY - currentLayer, holoOutlineZ, 3)
		hologram.set(i + holoOutlineX, holoOutlineY - currentLayer, 17 + holoOutlineZ, 3)
		hologram.set(holoOutlineX, holoOutlineY - currentLayer, i + holoOutlineZ, 3)
		hologram.set(17 + holoOutlineX, holoOutlineY - currentLayer, i + holoOutlineZ, 3)
	end
end

local function drawFrame()
	--Верхний левый
	for i = 1, 2 do hologram.set(i + holoOutlineX - 1, holoOutlineY - 1, holoOutlineZ, 2) end
	hologram.set(holoOutlineX, holoOutlineY - 1, holoOutlineZ + 1, 2)
	hologram.set(holoOutlineX, holoOutlineY - 2, holoOutlineZ, 2)
	--Верхний левый
	for i = 1, 2 do hologram.set(i + holoOutlineX - 1, holoOutlineY - 16, holoOutlineZ, 2) end
	hologram.set(holoOutlineX, holoOutlineY - 16, holoOutlineZ + 1, 2)
	hologram.set(holoOutlineX, holoOutlineY - 15, holoOutlineZ, 2)
end

local function drawModelOnHolo()
	hologram.clear()
	for x = 1, #pixels do
		for y = 1, #pixels[x] do
			for z = 1, #pixels[x][y] do
				if pixels[x][y][z] ~= "#" then
					hologram.set(x + holoOutlineX, holoOutlineY - y, z + holoOutlineZ, 1)
				end
			end
		end
	end

	drawBorder()
	--drawFrame()
end

local function drawAllViews()
	render()
	drawModelOnHolo()
	drawFrontView()
	drawTopView()
	drawSideView()

	drawTransparentBackground(sizes.image[4].x, sizes.image[4].y, 0xFFFFFF, 0xDDDDDD)
end

local function drawAll()
	drawLines()
	drawAllViews()
	drawRightBar()
end

------------------------------------------ Программа -----------------------------------------------------------------

if sizes.xSize < 150 then ecs.error("Этой программе требуется монитор и видеокарта 3 уровня."); return end

gpu.setResolution(sizes.xSize, sizes.ySize)

ecs.prepareToExit()
changePalette()
drawAll()

while true do
	local e = {event.pull()}
	if e[1] == "scroll" then
		if e[5] == 1 then
			if currentLayer > 1 then currentLayer = currentLayer - 1;drawModelOnHolo() end
		else
			if currentLayer < 16 then currentLayer = currentLayer + 1;drawModelOnHolo() end
		end
	end
end

------------------------------------------ Выход из программы -----------------------------------------------------------------

gpu.setResolution(sizes.oldResolutionWidth, sizes.oldResolutionHeight)









