local fs = require("filesystem")
local unicode = require("unicode")
local gpu = require("component").gpu

local image = {}

local transparentSymbol = "#"

--------------------Все, что касается сжатого формата изображений----------------------------------------------------------------------------------

--OC image format .ocif by Pirnogion
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }

local BYTE = 8
local NULL_CHAR = 0

local imageAPI = {}

local function readBytes(file, bytes)
  local readedByte = 0
  local readedNumber = 0
  for i = bytes, 1, -1 do
    readedByte = string.byte( file:read(1) or NULL_CHAR )
    readedNumber = readedNumber + bit32.lshift(readedByte, i*8-8)
  end

  return readedNumber
end

local function HEXtoRGB(color)
  local rr = bit32.rshift( color, 16 )
  local gg = bit32.rshift( bit32.band(color, 0x00ff00), 8 )
  local bb = bit32.band(color, 0x0000ff)
 
  return rr, gg, bb
end

local function encodePixel(hexcolor_fg, hexcolor_bg, char)
	local rr_fg, gg_fg, bb_fg = HEXtoRGB( hexcolor_fg )
	local rr_bg, gg_bg, bb_bg = HEXtoRGB( hexcolor_bg )
	local ascii_char1, ascii_char2 = string.byte( char, 1, 2 )

	ascii_char1 = ascii_char1 or NULL_CHAR
	ascii_char2 = ascii_char2 or NULL_CHAR

	return rr_fg, gg_fg, bb_fg, rr_bg, gg_bg, bb_bg, ascii_char1, ascii_char2
end

local function decodeChar(char1, char2)
	if ( char1 ~= 0 and char2 ~= 0 ) then
		return string.char( char1, char2 )
	elseif ( char1 ~= 0) then
		return string.char( char1 )
	elseif ( char2 ~= 0 ) then
		return string.char( char2 )
	end
end

--Чтение сжатого формата
local function loadJPG(path)
	local image = {}
	local file = io.open(path, "rb")

	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		return nil
	end

	image.width = readBytes(file, 1)
	image.height = readBytes(file, 1)
	image.depth = readBytes(file, 1)

	for y = 1, image.height, 1 do
		table.insert( image, {} )
		for x = 1, image.width, 1 do
			table.insert( image[y], {} )
			image[y][x].fg = readBytes(file, 3)
			image[y][x].bg = readBytes(file, 3)
			image[y][x].char = decodeChar(readBytes(file, 1), readBytes(file, 1))
		end
	end

	file:close()

	return image
end

--Рисование сжатого формата
local function drawJPG(x, y, image2)
	x = x - 1
	y = y - 1
	for j = 1, image2.height, 1 do
		for i = 1, image2.width, 1 do

			if image2[j][i].char ~= transparentSymbol then
				-- if i > 1 then
				-- 	if image2[j][i - 1].bg ~= image2[j][i].bg then
				-- 		gpu.setBackground(image2[j][i].bg)
				-- 	end
				-- 	if image2[j][i - 1].fg ~= image2[j][i].fg then
				-- 		gpu.setBackground(image2[j][i].bg)
				-- 	end
				-- else
					gpu.setBackground(image2[j][i].bg)
					gpu.setForeground(image2[j][i].fg)
				-- end

				gpu.set(x + i, y + j, image2[j][i].char)
			end
		end
	end
end

--Сохранение ДЖПГ в файл из существующего массива
function image.saveJPG(path, image)

	-- Удаляем файл, если есть
	-- И делаем папку к нему
	fs.remove(path)
	fs.makeDirectory(fs.path(path))

	local file = io.open(path, "w")

	--print("width = ", image.width)

	file:write( table.unpack(ocif_signature_expand) )
	file:write( string.char( image.width ) )
	file:write( string.char( image.height ) )
	file:write( string.char( image.depth ) )

	for y = 1, image.height, 1 do
		for x = 1, image.width, 1 do
			local encodedPixel = { encodePixel( image[y][x].fg, image[y][x].bg, image[y][x].char ) }
			for i = 1, #encodedPixel do
				file:write( string.char( encodedPixel[i] ) )
			end
		end
	end

	file:close()
end

---------------------------Все, что касается несжатого формата-------------------------------------------------------

--Загрузка ПНГ
local function loadPNG(path)
	local file = io.open(path, "r")
	local massiv = {}

	for line in file:lines() do
		local dlinaStroki = unicode.len(line)
		local lineNumber = #massiv + 1

		if dlinaStroki > 14 then
			local pixelCounter = 1
			massiv[lineNumber] = {}
			for i = 1, dlinaStroki, 16 do
				local loadedBackground = unicode.sub(line, i, i + 5)
				local loadedForeground = unicode.sub(line, i + 7, i + 12)
				local loadedSymbol = unicode.sub(line, i + 14, i + 14)

				massiv[lineNumber][pixelCounter] = { tonumber("0x" .. loadedBackground), tonumber("0x" .. loadedForeground), loadedSymbol }

				pixelCounter = pixelCounter + 1
			end
		end
	end

	file:close()
	return massiv
end

--Отрисовка ПНГ
local function drawPNG(x, y, massivSudaPihay)
	x = x - 1
	y = y - 1
	for j = 1, #massivSudaPihay do
		for i = 1, #massivSudaPihay[j] do
			if massivSudaPihay[j][i][1] and massivSudaPihay[j][i][2] and massivSudaPihay[j][i][3] ~= transparentSymbol then
				
				-- if i > 1 then
				-- 	if massivSudaPihay[j][i - 1][1] ~= massivSudaPihay[j][i][1] then
				-- 		gpu.setBackground(massivSudaPihay[j][i][1])
				-- 	end
				-- 	if massivSudaPihay[j][i - 1][2] ~= massivSudaPihay[j][i][2] then
				-- 		gpu.setForeground(massivSudaPihay[j][i][2])
				-- 	end
				-- else
				if massivSudaPihay[j][i][1] ~= gpu.getBackground() then
					gpu.setBackground(massivSudaPihay[j][i][1])
				end
				if massivSudaPihay[j][i][2] ~= gpu.getForeground() then
					gpu.setForeground(massivSudaPihay[j][i][2])	
				end
				-- end

				gpu.set(x + i, y + j, massivSudaPihay[j][i][3])
			end
		end
	end
end

-- Сохранение существующего массива ПНГ в файл
function image.savePNG(path, MasterPixels)
	-- Удаляем файл, если есть
	-- И делаем папку к нему
	fs.remove(path)
	fs.makeDirectory(fs.path(path))
	local f = io.open(path, "w")

	for j=1, #MasterPixels do
		for i=1,#MasterPixels[j] do
			f:write(HEXtoSTRING(MasterPixels[j][i][1])," ",HEXtoSTRING(MasterPixels[j][i][2])," ",MasterPixels[j][i][3]," ")
		end
		f:write("\n")
	end

	f:close()
end

---------------------Глобальные функции отрисовки---------------------------------------------------------

--Конвертер из PNG в JPG
function image.PNGtoJPG(PNGMassiv)
	local JPGMassiv = {}
	local width, height = 0, 0

	--Сохраняем пиксели
	for j = 1, #PNGMassiv do
		JPGMassiv[j] = {}
		width = 0
		for i = 1, #PNGMassiv[j] do
			JPGMassiv[j][i] = {}
			JPGMassiv[j][i]["bg"] = PNGMassiv[j][i][1]
			JPGMassiv[j][i]["fg"] = PNGMassiv[j][i][2]
			JPGMassiv[j][i]["char"] = PNGMassiv[j][i][3]
			width = width + 1
		end
		height = height + 1
	end

	JPGMassiv["width"] = width
	JPGMassiv["height"] = height
	JPGMassiv["depth"] = 8

	return JPGMassiv
end

--Конвертер из JPG в PNG
function image.JPGtoPNG(JPGMassiv)
	local PNGMassiv = {}
	local width, height = 0, 0

	--Сохраняем пиксели
	for j = 1, #JPGMassiv do
		PNGMassiv[j] = {}
		width = 0
		for i = 1, #JPGMassiv[j] do
			PNGMassiv[j][i] = {}
			PNGMassiv[j][i][1] = JPGMassiv[j][i]["bg"]
			PNGMassiv[j][i][2] = JPGMassiv[j][i]["fg"]
			PNGMassiv[j][i][3] = JPGMassiv[j][i]["char"]
			width = width + 1
		end
		height = height + 1
	end

	return PNGMassiv
end

-- Просканировать файловую систему на наличие .PNG
-- И сохранить рядом с ними аналогичную копию в формате .JPG
-- Осторожно, функция для дебага и знающих людей
-- С кривыми ручками сюда не лезь
function image.convertAllPNGtoJPG(path)
	local list = ecs.getFileList(path)
	for key, file in pairs(list) do
		if fs.isDirectory(path.."/"..file) then
			image.convertAllPNGtoJPG(path.."/"..file)
		else
			if ecs.getFileFormat(file) == ".png" or ecs.getFileFormat(file) == ".PNG" then
				print("Найден .PNG в директории \""..path.."/"..file.."\"")
				print("Загружаю этот файл...")
				PNGFile = loadPNG(path.."/"..file)
				print("Загрузка завершена!")
				print("Конвертация в JPG начата...")
				JPGFile = image.PNGtoJPG(PNGFile)
				print("Ковертация завершена!")
				print("Сохраняю .JPG в той же папке...")
				image.saveJPG(path.."/"..ecs.hideFileFormat(file)..".jpg", JPGFile)
				print("Сохранение завершено!")
				print(" ")
			end
		end
	end
end

--Загрузка любого изображения из доступных типов
function image.load(path)

	local kartinka = {}
	local fileFormat = ecs.getFileFormat(path)

	if string.lower(fileFormat) == ".jpg" then
		kartinka["format"] = ".jpg"
		kartinka["image"] = loadJPG(path)
	elseif  string.lower(fileFormat) == ".png" then
		kartinka["format"] = ".png"
		kartinka["image"] = loadPNG(path)
	else
		ecs.error("Wrong file format! (not .png or .jpg)")
	end

	return kartinka
end

--Отрисовка этого изображения
function image.draw(x, y, kartinka)
	if kartinka.format == ".jpg" then
		drawJPG(x, y, kartinka["image"])
	elseif kartinka.format == ".png" then
		drawPNG(x, y, kartinka["image"])
	end
end

---------------------------------------------------------------------------------------------------------------------

--image.convertAllPNGtoJPG("")

-- local test = image.load("System/OS/Icons/Love.jpg")
-- image.draw(2, 2, test)

-- local cyyyyka = image.load("1.png.png")
-- image.draw(2, 2, cyyyyka)




-- function imageAPI.initGlobal()
-- 	local prev = _G.global_images
-- 	_G.global_images = {}

-- 	return _G.global_images, prev
-- end

-- local test = {
-- 	["format"] = ".jpg",
-- 	["image"] ={
-- 		["width"] = 8,
-- 		["height"] = 4,
-- 		["depth"] = 8,
-- 		{ 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '}, 
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '},
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '}
-- 		},
-- 		{ 
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'}, 
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '},
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '}
-- 		},
-- 		{ 
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '},
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='0'}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='1'},
-- 			{["fg"]=0x000000, ["bg"]=0x004980, ["char"]=' '}
-- 		},
-- 		{ 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='P'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='A'}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='S'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='T'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='Ж'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='B'}, 
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='I'},
-- 			{["fg"]=0x000000, ["bg"]=0xFFFFFF, ["char"]='N'}
-- 		},
-- 	}
-- }

-- image.draw(20, 2, test)


return image













