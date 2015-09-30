
-------------------------------------------- OCIF Image Format -----------------------------------------------------------

local copyright = [[
	
	Автор: Pirnogion
		VK: https://vk.com/id88323331
	Соавтор: IT
		VK: https://vk.com/id7799889

]]

--------------------------------------- Подгрузка библиотек --------------------------------------------------------------

local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local gpu = component.gpu

local image = {}

-------------------------------------------- Переменные -------------------------------------------------------------------

--Cигнатура OCIF-файла
local ocif_signature1 = 0x896F6369
local ocif_signature2 = 0x00661A0A --7 bytes: 89 6F 63 69 66 1A 0A
local ocif_signature_expand = { string.char(0x89), string.char(0x6F), string.char(0x63), string.char(0x69), string.char(0x66), string.char(0x1A), string.char(0x0A) }

--Константы программы
local constants = {
	elementCount = 4,
	byteSize = 8,
	nullChar = 0,
	rawImageLoadStep = 19,
	fileOpenError = "Can't open file",
	compressedFileFormat = ".pic",
	rawFileFormat = ".rawpic",
}

---------------------------------------- Локальные функции -------------------------------------------------------------------

--Выделить бит-терминатор в первом байте UTF-8 символа: 1100 0010 --> 0010 0000
local function selectTerminateBit_l()
	local prevByte = nil
	local prevTerminateBit = nil

	return function( byte )
		local x, terminateBit = nil
		if ( prevByte == byte ) then
			return prevTerminateBit
		end

		x = bit32.band( bit32.bnot(byte), 0x000000FF )
		x = bit32.bor( x, bit32.rshift(x, 1) )
		x = bit32.bor( x, bit32.rshift(x, 2) )
		x = bit32.bor( x, bit32.rshift(x, 4) )
		x = bit32.bor( x, bit32.rshift(x, 8) )
		x = bit32.bor( x, bit32.rshift(x, 16) )

		terminateBit = x - bit32.rshift(x, 1)

		prevByte = byte
		prevTerminateBit = terminateBit

		return terminateBit
	end
end
local selectTerminateBit = selectTerminateBit_l()

--Прочитать n байтов из файла, возвращает прочитанные байты как число, если не удалось прочитать, то возвращает 0
local function readBytes(file, bytes)
  local readedByte = 0
  local readedNumber = 0
  for i = bytes, 1, -1 do
    readedByte = string.byte( file:read(1) or constants.nullChar )
    readedNumber = readedNumber + bit32.lshift(readedByte, i * constants.byteSize - constants.byteSize)
  end

  return readedNumber
end

--Преобразует цвет из HEX-записи в RGB-запись
local function HEXtoRGB(color)
  return bit32.rshift( color, 16 ), bit32.rshift( bit32.band(color, 0x00ff00), 8 ), bit32.band(color, 0x0000ff)
end

--Аналогично, но из RGB в HEX
local function RGBtoHEX(rr, gg, bb)
  return bit32.lshift(rr, 16) + bit32.lshift(gg, 8) + bb
end

--Смешивание двух цветов на основе альфа-канала второго
local function alphaBlend(back_color, front_color, alpha_channel)
	local INVERTED_ALPHA_CHANNEL = 255 - alpha_channel

	local back_color_rr, back_color_gg, back_color_bb    = HEXtoRGB(back_color)
	local front_color_rr, front_color_gg, front_color_bb = HEXtoRGB(front_color)

	local blended_rr = front_color_rr * INVERTED_ALPHA_CHANNEL / 255 + back_color_rr * alpha_channel / 255
	local blended_gg = front_color_gg * INVERTED_ALPHA_CHANNEL / 255 + back_color_gg * alpha_channel / 255
	local blended_bb = front_color_bb * INVERTED_ALPHA_CHANNEL / 255 + back_color_bb * alpha_channel / 255

	return RGBtoHEX( blended_rr, blended_gg, blended_bb )
end

--Подготавливает цвета и символ для записи в файл сжатого формата
local function encodePixel(background, foreground, alpha, char)
	--Расхерачиваем жирные цвета в компактные цвета
	local ascii_background1, ascii_background2, ascii_background3 = HEXtoRGB(background)
	local ascii_foreground1, ascii_foreground2, ascii_foreground3 = HEXtoRGB(foreground)
	--Расхерачиваем жирный код юникод-символа в несколько миленьких ascii-кодов
	local ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6 = string.byte( char, 1, 6 )
	ascii_char1 = ascii_char1 or constants.nullChar
	--Возвращаем все расхераченное
	return ascii_background1, ascii_background2, ascii_background3, ascii_foreground1, ascii_foreground2, ascii_foreground3, alpha, ascii_char1, ascii_char2, ascii_char3, ascii_char4, ascii_char5, ascii_char6
end

--Декодирование UTF-8 символа
local function decodeChar(file)
	local first_byte = readBytes(file, 1)
	local charcode_array = {first_byte}
	local len = 1

	local middle = selectTerminateBit(first_byte)
	if ( middle == 32 ) then
		len = 2
	elseif ( middle == 16 ) then 
		len = 3
	elseif ( middle == 8 ) then
		len = 4
	elseif ( middle == 4 ) then
		len = 5
	elseif ( middle == 2 ) then
		len = 6
	end

	for i = 1, len-1 do
		table.insert( charcode_array, readBytes(file, 1) )
	end

	return string.char( table.unpack( charcode_array ) )
end

--Правильное конвертирование HEX-переменной в строковую
local function HEXtoSTRING(color, bitCount, withNull)
	local stro4ka = string.format("%X",color)
	local sStro4ka = unicode.len(stro4ka)

	if sStro4ka < bitCount then
		stro4ka = string.rep("0", bitCount - sStro4ka) .. stro4ka
	end

	sStro4ka = nil

	if withNull then return "0x"..stro4ka else return stro4ka end
end

--Получение формата файла
local function getFileFormat(path)
	local name = fs.name(path)
	local starting, ending = string.find(name, "(.)%.[%d%w]*$")
	if starting == nil then
		return nil
	else
		return unicode.sub(name,starting + 1, -1)
	end
	name, starting, ending = nil, nil, nil
end

------------------------------ Все, что касается сжатого формата ------------------------------------------------------------

-- Запись в файл сжатого OCIF-формата изображения
function image.saveCompressed(path, picture)
	local encodedPixel
	local file = assert( io.open(path, "w"), constants.fileOpenError )

	file:write( table.unpack( ocif_signature_expand ) )
	file:write( string.char( picture.width  ) )
	file:write( string.char( picture.height ) )
	
	for i = 1, picture.width * picture.height * constants.elementCount, constants.elementCount do
		encodedPixel =
		{
			encodePixel(picture[i], picture[i + 1], picture[i + 2], picture[i + 3])
		}
		for j = 1, #encodedPixel do
			file:write( string.char( encodedPixel[j] ) )
		end
	end

	file:close()
end

--Чтение из файла сжатого OCIF-формата изображения, возвращает массив типа 2 (подробнее о типах см. конец файла)
function image.loadCompressed(path)
	local picture = {}
	local file = assert( io.open(path, "rb"), constants.fileOpenError )

	--Проверка файла на соответствие сигнатуры
	local signature1, signature2 = readBytes(file, 4), readBytes(file, 3)
	if ( signature1 ~= ocif_signature1 or signature2 ~= ocif_signature2 ) then
		file:close()
		return nil
	end

	--Читаем ширину и высоту файла
	picture.width = readBytes(file, 1)
	picture.height = readBytes(file, 1)

	for i = 1, picture.width * picture.height do
		--Читаем бекграунд
		table.insert(picture, readBytes(file, 3))
		--Читаем форграунд
		table.insert(picture, readBytes(file, 3))
		--Читаем альфу
		table.insert(picture, readBytes(file, 1))
		--Читаем символ
		table.insert(picture, decodeChar( file ))
	end

	file:close()

	return picture
end

------------------------------ Все, что касается сырого формата ------------------------------------------------------------

--Сохранение в файл сырого формата изображения типа 2 (подробнее о типах см. конец файла)
function image.saveRaw(path, picture)
	local file = assert( io.open(path, "w"), constants.fileOpenError )

	local xPos, yPos = 1, 1
	for i = 1, picture.width * picture.height * constants.elementCount, constants.elementCount do
		file:write( HEXtoSTRING(picture[i], 6), " ", HEXtoSTRING(picture[i + 1], 6), " ", HEXtoSTRING(picture[i + 2], 2), " ", picture[i + 3], " ")

		xPos = xPos + 1
		if xPos > picture.width then
			xPos = 1
			yPos = yPos + 1
			file:write("\n")
		end
	end

	file:close()
end

--Загрузка из файла сырого формата изображения типа 2 (подробнее о типах см. конец файла)
function image.loadRaw(path)
	local file = assert( io.open(path, "r"), constants.fileOpenError )
	local picture = {}

	local background, foreground, alpha, symbol, sLine
	local lineCounter = 0
	for line in file:lines() do
		sLine = unicode.len(line)
		for i = 1, sLine, constants.rawImageLoadStep do
			background = "0x" .. unicode.sub(line, i, i + 5)
			foreground = "0x" .. unicode.sub(line, i + 7, i + 12)
			alpha = "0x" .. unicode.sub(line, i + 14, i + 15)
			symbol = unicode.sub(line, i + 17, i + 17)

			table.insert(picture, tonumber(background))
			table.insert(picture, tonumber(foreground))
			table.insert(picture, tonumber(alpha))
			table.insert(picture, symbol)
		end
		lineCounter = lineCounter + 1
	end

	picture.width = sLine / constants.rawImageLoadStep
	picture.height = lineCounter

	file:close()

	return picture
end

----------------------------------- Вспомогательные функции программы ------------------------------------------------------------

--Оптимизировать и сгруппировать по цветам картинку типа 2 (подробнее о типах см. конец файла)
function image.convertToGroupedImage(picture)
	--Создаем массив оптимизированной картинки
	local optimizedPicture = {}
	--Задаем константы
	local xPos, yPos, background, foreground, alpha, symbol = 1, 1, nil, nil, nil, nil
	--Перебираем все элементы массива
	for i = 1, picture.width * picture.height * constants.elementCount, constants.elementCount do
		--Получаем символ из неоптимизированного массива
		background, foreground, alpha, symbol = picture[i], picture[i + 1], picture[i + 2], picture[i + 3]
		--Группируем картинку по цветам
		optimizedPicture[background] = optimizedPicture[background] or {}
		optimizedPicture[background][foreground] = optimizedPicture[background][foreground] or {}
		table.insert(optimizedPicture[background][foreground], xPos)
		table.insert(optimizedPicture[background][foreground], yPos)
		table.insert(optimizedPicture[background][foreground], alpha)
		table.insert(optimizedPicture[background][foreground], symbol)
		--Если xPos достигает width изображения, то сбросить на 1, иначе xPos++
		xPos = (xPos == picture.width) and 1 or xPos + 1
		--Если xPos равняется 1, то yPos++, а если нет, то похуй
		yPos = (xPos == 1) and yPos + 1 or yPos
	end
	--Возвращаем оптимизированный массив
	return optimizedPicture
end

--Нарисовать по указанным координатам картинку указанной ширины и высоты для теста
function image.drawRandomImage(x, y, width, height)
	local picture = {}
	local symbolArray = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "Й", "К", "Л", "И", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"}
	picture.width = width
	picture.height = height
	local background, foreground, symbol
	for j = 1, height do
		for i = 1, width do
			background = math.random(0x000000, 0xffffff)
			foreground = math.random(0x000000, 0xffffff)
			symbol = symbolArray[math.random(1, #symbolArray)]

			table.insert(picture, background)
			table.insert(picture, foreground)
			table.insert(picture, 0x00)
			table.insert(picture, symbol)
		end
	end
	image.draw(x, y, picture)
	return picture
end

----------------------------------------- Основные функции программы -------------------------------------------------------------------

--Сохранить изображение любого поддерживаемого формата
function image.save(path, picture)
	--Создать папку под файл, если ее нет
	fs.makeDirectory(fs.path(path))
	--Получаем формат указанного файла
	local fileFormat = getFileFormat(path)
	--Проверяем соответствие формата файла
	if fileFormat == constants.compressedFileFormat then
		image.saveCompressed(path, picture)
	elseif fileFormat == constants.rawFileFormat then
		image.saveRaw(path, picture)
	else
		error("Unsupported file format.\n")
	end
end

--Загрузить изображение любого поддерживаемого формата
function image.load(path)
	--Кинуть ошибку, если такого файла не существует
	if not fs.exists(path) then error("File \""..path.."\" does not exists.\n") end
	--Получаем формат указанного файла
	local fileFormat = getFileFormat(path)
	--Проверяем соответствие формата файла
	if fileFormat == constants.compressedFileFormat then
		return image.loadCompressed(path)
	elseif fileFormat == constants.rawFileFormat then
		return image.loadRaw(path)
	else
		error("Unsupported file format.\n")
	end
end

--Отрисовка изображения типа 3 (подробнее о типах см. конец файла)
function image.draw(x, y, rawPicture)
	--Конвертируем в групповое изображение
	local picture = image.convertToGroupedImage(rawPicture)
	--Все как обычно
	x, y = x - 1, y - 1
	--Переменные, чтобы в цикле эту парашу не создавать
	local currentBackground, xPos, yPos, alpha, symbol
	local _, _
	--Перебираем все цвета фона
	for background in pairs(picture) do
		--Заранее ставим корректный цвет фона
		gpu.setBackground(background)
		--Перебираем все цвета текста
		for foreground in pairs(picture[background]) do
			--Ставим сразу и корректный цвет текста
			gpu.setForeground(foreground)
			--Перебираем все пиксели
			for i = 1, #picture[background][foreground], 4 do
				--Получаем временную репрезентацию
				xPos, yPos, alpha, symbol = picture[background][foreground][i], picture[background][foreground][i + 1], picture[background][foreground][i + 2], picture[background][foreground][i + 3]
				--Если альфа имеется, но она не совсем прозрачна
				if alpha > 0x00 and alpha < 0xFF then
					_, _, currentBackground = gpu.get(x + xPos, y + yPos)
					currentBackground = alphaBlend(currentBackground, background, alpha)
					gpu.setBackground(currentBackground)
					--Рисуем символ на экране
					gpu.set(x + xPos, y + yPos, symbol)
				--Если альфа отсутствует
				elseif alpha == 0x00 then
					if currentBackground ~= background then
						currentBackground = background
						gpu.setBackground(currentBackground)
					end
					--Рисуем символ на экране
					gpu.set(x + xPos, y + yPos, symbol)
				end	
				
				--Выгружаем сгруппированное изображение из памяти
				picture[background][foreground][i], picture[background][foreground][i + 1], picture[background][foreground][i + 2], picture[background][foreground][i + 3] = nil, nil, nil, nil
			end
			--Выгружаем данные о текущем цвете текста из памяти
			picture[background][foreground] = nil
		end
		--Выгружаем данные о текущем фоне из памяти
		picture[background] = nil
	end
end

local function loadOldPng(path)
	local massiv = {}
	local file = io.open(path, "r")
	local lineCounter = 0
	local sLine = 0
	for line in file:lines() do
		sLine = unicode.len(line)

		for i = 1, sLine, 16 do
			table.insert(massiv, tonumber("0x" .. unicode.sub(line, i, i + 5)))
			table.insert(massiv, tonumber("0x" .. unicode.sub(line, i + 7, i + 12)))
			table.insert(massiv, 0x00)
			table.insert(massiv, tonumber("0x" .. unicode.sub(line, i + 14, i + 14)))
		end

		lineCounter = lineCounter + 1
	end

	massiv.width = sLine / 16
	massiv.height = lineCounter

	return massiv
end

local function convertAllPngToPic()
	local counter = 0
	local function doConvert(path)
		local fileList = ecs.getFileList(path)
		for file = 1, #fileList do
			if fs.isDirectory(path..file) then
				doConvert(path..file)
			else
				local fileFormat = ecs.getFileFormat(path..file)
				if fileFormat == ".png" then
					print("Найден .png в "..path..file)
					print("Загружаю старый формат...")
					local picture = loadOldPng()
					print("Сохраняю в новом формате...")
					image.saveCompressed(path..ecs.hideFileFormat(file)..".pic", picture)
					picture = nil
					print("Успешно!")
					print(" ")
					counter = counter + 1
				end
			end
		end
	end

	print(" ")
	doConvert("/")
	print("Всего сконвертировано "..counter.." файлов.")
	print(" ")
end

convertAllPngToPic()

------------------------------------------ Примеры работы с библиотекой ------------------------------------------------

-- ecs.prepareToExit()
-- ecs.error("Создаю и рисую картинку!")
-- local generatedPic = image.drawRandomImage(1, 1, 160, 50)
-- ecs.error("Сохраняю созданную картинку в формате .pic!")
-- ecs.prepareToExit()
-- image.save("1.pic", generatedPic)
-- ecs.error("Сохраняю созданную картинку в формате .rawpic!")
-- ecs.prepareToExit()
-- image.save("1.rawpic", generatedPic)
-- ecs.error("Загружаю сохраненную картинку в формате .pic!")
-- ecs.prepareToExit()
-- local loadedPic = image.load("1.pic")
-- image.draw(1, 1, loadedPic)
-- ecs.error("Загружаю сохраненную картинку в формате .rawpic!")
-- ecs.prepareToExit()
-- local loadedPic = image.load("1.rawpic")
-- image.draw(1, 1, loadedPic)

------------------------------------------ Типы массивов изображений ---------------------------------------------------


--[[

	Тип 1:

		Основной формат изображения, линейная запись данных о пикселях,
		сжатие двух цветов и альфа-канала в одно число. Минимальный расход
		оперативной памяти, однако для изменения цвета требует декомпрессию.

			Структура:

				local picture = {
					width = ширина изображения,
					height = высота изображения,
					Сжатые цвета и альфа-канал,
					Символ,
					Сжатые цвета и альфа-канал,
					Символ,
					...
				}

			Пример:

				local picture = {
					width = 2,
					height = 2,
					0xff00aa,
					"Q",
					0x88aacc,
					"W",
					0xff00aa,
					"E",
					0x88aacc,
					"R"
				}

		Тип 2 конвертируется только в тип 3 и только для отрисовки на экране:
		Изображение типа 3 = image.convertToGroupedImage( Сюда кидаем массив изображения типа 2 )

	Тип 2 (сгруппированный по цветам формат, ипользуется только для отрисовки изображения):
	
			Структура:
			local picture = {
				Цвет фона 1 = {
					Цвет текста 1 = {
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						...
					},
					Цвет текста 2 = {
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						...
					},
					...
				},
				Цвет фона 2 = {
					Цвет текста 1 = {
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						...
					},
					Цвет текста 2 = {
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						Координата по X,
						Координата по Y,
						Альфа-канал,
						Символ,
						...
					},
					...
				},
			}

			Пример:
			local picture = {
				0xffffff = {
					0xaabbcc = {
						1,
						1,
						0x00,
						"Q",
						12,
						12,
						0xaa,
						"W"
					},
					0x88aa44 = {
						5,
						5,
						0xcc,
						"E",
						12,
						12,
						0x00,
						"R"
					}
				},
				0x444444 = {
					0x112233 = {
						40,
						20,
						0x00,
						"T",
						12,
						12,
						0xaa,
						"Y"
					},
					0x88aa44 = {
						5,
						5,
						0xcc,
						"U",
						12,
						12,
						0x00,
						"I"
					}
				}
			}

]]

------------------------------------------------------------------------------------------------------------------------

return image









