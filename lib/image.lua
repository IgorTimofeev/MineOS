
---------------------------------------- OpenComputers Image Format (OCIF) -----------------------------------------------------------

--[[
	
	Автор: Pornogion
		VK: https://vk.com/id88323331
	Соавтор: IT
		VK: https://vk.com/id7799889

	Основные функции:

		image.load(string путь): table изображение
			Загружает существующую картинку в формате .pic и возвращает ее
			в качестве массива (таблицы).

		image.draw(int x, int y, table изображение)
			Рисует на экране загруженную ранее картинку по указанным координатам.

		image.save(string путь, table изображение [, int метод кодирования])
			Сохраняет указанную картинку по указанному пути в формате .pic,
			по умолчанию используя метод кодирования 3. Рекомендуется
			использовать именно его.

	Функции для работы с изображением:

		image.expand(table картинка, string направление, int количество пикселей[, int цвет фона, int цвет текста, int прозрачность, char символ]): table картинка
			Расширяет указанную картинку в указанном направлении (fromRight, fromLeft, fromTop, fromBottom),
			создавая при этом пустые белые пиксели. Если указаны опциональные аргументы, то вместо пустых
			пикселей могут быть вполне конкретные значения.

		image.crop(table картинка, string направление, int количество пикселей): table картинка
			Обрезает указанную картинку в указанном направлении (fromRight, fromLeft, fromTop, fromBottom),
			удаляя лишние пиксели.

		image.rotate(table картинка, int угол): table картинка
			Поворачивает указанную картинку на указанный угол. Угол может иметь
			значение 90, 180 и 270 градусов.

		image.flipVertical(table картинка): table картинка
			Отражает указанную картинку по вертикали.

		image.flipHorizontal(table картинка): table картинка
			Отражает указанную картинку по горизонтали.

	Функции для работы с цветом:

		image.hueSaturationBrightness(table картинка, int тон, int насыщенность, int яркость): table картинка
			Корректирует цветовой тон, насыщенность и яркость указанной картинки.
			Значения аргументов могут быть отрицательными для уменьшения параметра
			и положительными для его увеличения. Если значение, к примеру, насыщенности
			менять не требуется, просто указывайте 0.
			
			Для удобства вы можете использовать следующие сокращения:
				image.hue(table картинка, int тон): table картинка
				image.saturation(table картинка, int насыщенность): table картинка
				image.brightness(table картинка, int яркость): table картинка
				image.blackAndWhite(table картинка): table картинка

		image.colorBalance(table картинка, int красный, int зеленый, int синий): table картинка
			Корректирует цветовые каналы изображения указанной картинки. Аргументы цветовых
			каналов могут принимать как отрицательные значения для уменьшения интенсивности канала,
			так и положительные для увеличения.

		image.invert(table картинка): table картинка
			Инвертирует цвета в указанной картинке.

		image.photoFilter(table картинка, int цвет, int прозрачность): table картинка
			Накладывает на указанное изображение фотофильтр с указанной прозрачностью.
			Прозрачность может быть от 0 до 255.

		image.replaceColor(table картинка, int заменяемыйЦвет, int цветДляЗамены): table картинка
			Заменяет в указанном изображении один конкретный цвет на другой.
]]

--------------------------------------- Подгрузка библиотек --------------------------------------------------------------

-- Адаптивная загрузка необходимых библиотек и компонентов
local libraries = {
	["component"] = "component",
	["unicode"] = "unicode",
	["fs"] = "filesystem",
	["colorlib"] = "colorlib",
	["bit"] = "bit32",
}

local components = {
	["gpu"] = "gpu",
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

local image = {}

-------------------------------------------- Переменные -------------------------------------------------------------------

--Константы программы
local constants = {
	OCIFSignature = "OCIF",
	encodingMethods = {
		raw = 0,
		OCIF1 = 1,
		OCIF2 = 2,
		OCIF3 = 3,
	},
	OCIF2Elements = {
		alphaStart = "A",
		symbolStart = "S",
		backgroundStart = "B",
		foregroundStart = "F",
	},
	elementCount = 4,
	byteSize = 8,
	nullChar = 0,
	rawImageLoadStep = 19,
	compressedFileFormat = ".pic",
	rawFileFormat = ".rawpic",
	pngFileFormat = ".png",
}

---------------------------------------- Локальные функции -------------------------------------------------------------------

--Формула конвертации индекса массива изображения в абсолютные координаты пикселя изображения
local function convertIndexToCoords(index, width)
	--Приводим индекс к корректному виду (1 = 1, 4 = 2, 7 = 3, 10 = 4, 13 = 5, ...)
	index = (index + constants.elementCount - 1) / constants.elementCount
	--Получаем остаток от деления индекса на ширину изображения
	local ostatok = index % width
	--Если остаток равен 0, то х равен ширине изображения, а если нет, то х равен остатку
	local x = (ostatok == 0) and width or ostatok
	--А теперь как два пальца получаем координату по Y
	local y = math.ceil(index / width)
	--Очищаем остаток из оперативки
	ostatok = nil
	--Возвращаем координаты
	return x, y
end

--Формула конвертации абсолютных координат пикселя изображения в индекс для массива изображения
local function convertCoordsToIndex(x, y, width)
	return (width * (y - 1) + x) * constants.elementCount - constants.elementCount + 1
end

--Костыльное получение размера массива, ибо автор луа не позволяет
--подсчитывать ненумерические индексы через #massiv
--мда, мда
--...
--мда
local function getArraySize(array)
	local size = 0
	for key in pairs(array) do
		size = size + 1
	end
	return size
end

--Получить количество байт, которое можно извлечь из указанного числа
local function getCountOfBytes(number)
	if number == 0 or number == 1 then return 1 end
	return math.ceil(math.log(number, 256))
end

--Распидорасить число на составляющие байты
local function extractBytesFromNumber(number, countOfBytesToExtract)
	local bytes = {}
	local byteCutter = 0xff
	for i = 1, countOfBytesToExtract do
		table.insert(bytes, 1, bit32.rshift(bit32.band(number, byteCutter), (i-1)*8))
		byteCutter = bit32.lshift(byteCutter, 8)
	end
	return table.unpack(bytes)
end

--Склеить байты и создать из них число
local function mergeBytesToNumber(...)
	local bytes = {...}
	local finalNumber = bytes[1]
	for i = 2, #bytes do
		finalNumber = bit32.bor(bit32.lshift(finalNumber, 8), bytes[i])
	end
	return finalNumber
end

-- Сконвертировать все переданные байты в строку
local function convertBytesToString(...)
	local bytes = {...}
	for i = 1, #bytes do
		bytes[i] = string.char(bytes[i])
	end
	return table.concat(bytes)
end

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
local function readBytes(file, count)
  local readedBytes = file:read(count)
  return mergeBytesToNumber(string.byte(readedBytes, 1, count))
end

--Подготавливает цвета и символ для записи в файл сжатого формата
local function encodePixel(background, foreground, alpha, char)
	--Расхерачиваем жирные цвета в компактные цвета
	local ascii_background1, ascii_background2, ascii_background3 = colorlib.HEXtoRGB(background)
	local ascii_foreground1, ascii_foreground2, ascii_foreground3 = colorlib.HEXtoRGB(foreground)
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
		return unicode.sub(name, starting + 1, -1)
	end
	name, starting, ending = nil, nil, nil
end

--Прочесть сигнатуру файла и сравнить ее с константой
local function readSignature(file)
	local readedSignature = file:read(4)
	if readedSignature ~= constants.OCIFSignature then
		file:close()
		error("Can't load file: wrong OCIF format signature (\""..readedSignature .. "\" ~= \"" ..constants.OCIFSignature .. "\")")
	end
end

--Записать сигнатуру в файл
local function writeSignature(file)
	file:write(constants.OCIFSignature)
end

--Сжать все цвета в изображении в 8-битную палитру
local function compressImageColorsTo8Bit(picture)
	for i = 1, #picture, 4 do
		picture[i] = colorlib.convert24BitTo8Bit(picture[i])
		picture[i + 1] = colorlib.convert24BitTo8Bit(picture[i + 1])
		if i % 505 == 0 then os.sleep(0) end
	end
	return picture
end

------------------------------ Все, что касается формата OCIF1 ------------------------------------------------------------

-- Запись в файл сжатого OCIF-формата изображения
local function saveOCIF1(file, picture)
	local encodedPixel
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
local function loadOCIF1(file)
	local picture = {}

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

------------------------------------------ Все, что касается формата OCIF2 ------------------------------------------------

local function saveOCIF2(file, picture, compressColors)
	--Записываем ширину изображения
	file:write(string.char(picture.width))
	file:write(string.char(picture.height))

	--Группируем картинку
	local grouppedPucture = image.convertToGroupedImage(picture)

	--Перебираем все альфы
	for alpha in pairs(grouppedPucture) do
		--Получаем размер массива, содержащего символы
		local arraySize = getArraySize(grouppedPucture[alpha])
		local countOfBytesForArraySize = getCountOfBytes(arraySize)
		--Записываем в файл символ АльфаСтарта, размер массива альфы и само значение альфы
		file:write(
			constants.OCIF2Elements.alphaStart,
			string.char(countOfBytesForArraySize),
			convertBytesToString(extractBytesFromNumber(arraySize, countOfBytesForArraySize)),
			string.char(alpha)
		)
		
		for symbol in pairs(grouppedPucture[alpha]) do
			--Записываем заголовок
			file:write(constants.OCIF2Elements.symbolStart)
			--Записываем количество всех цветов текста и символ
			if compressColors then
				file:write(
					string.char(getArraySize(grouppedPucture[alpha][symbol])),
					convertBytesToString(string.byte(symbol, 1, 6))
				)
			else
				file:write(	
					convertBytesToString(extractBytesFromNumber(getArraySize(grouppedPucture[alpha][symbol]), 3)),
					convertBytesToString(string.byte(symbol, 1, 6))
				)
			end
		
			for foreground in pairs(grouppedPucture[alpha][symbol]) do
				--Записываем заголовок
				file:write(constants.OCIF2Elements.foregroundStart)
				--Записываем количество цветов фона и цвет текста
				if compressColors then
					file:write(
						string.char(getArraySize(grouppedPucture[alpha][symbol][foreground])),
						string.char(foreground)
					)
				else
					file:write(
						convertBytesToString(extractBytesFromNumber(getArraySize(grouppedPucture[alpha][symbol][foreground]), 3)),
						convertBytesToString(extractBytesFromNumber(foreground, 3))
					)
				end
		
				for background in pairs(grouppedPucture[alpha][symbol][foreground]) do
					--Записываем заголовок и размер массива координат
					file:write(
							constants.OCIF2Elements.backgroundStart,
							convertBytesToString(extractBytesFromNumber(getArraySize(grouppedPucture[alpha][symbol][foreground][background]), 2))
					)
					--Записываем цвет фона
					if compressColors then
						file:write(string.char(background))
					else
						file:write(convertBytesToString(extractBytesFromNumber(background, 3)))
					end
		
					--Записываем координаты
					for i = 1, #grouppedPucture[alpha][symbol][foreground][background], 2 do
						file:write(
							string.char(grouppedPucture[alpha][symbol][foreground][background][i]),
							string.char(grouppedPucture[alpha][symbol][foreground][background][i + 1])
						)
					end
				end
			end
		end
	end

	file:close()
end

local function loadOCIF2(file, decompressColors)
	local picture = {}

	--Читаем размер изображения
	local readedWidth = string.byte(file:read(1))
	local readedHeight = string.byte(file:read(1))
	picture.width = readedWidth
	picture.height = readedHeight

	local header, alpha, symbol, foreground, background, alphaSize, symbolSize, foregroundSize, backgroundSize = ""
	while true do
		header = file:read(1)
		if not header then break end
		-- print("----------------------")
		-- print("Заголовок: " .. header)

		if header == "A" then
			local countOfBytesForArraySize = string.byte(file:read(1))
			alphaSize = string.byte(file:read(countOfBytesForArraySize))
			alpha = string.byte(file:read(1))
			-- print("Количество байт под размер массива символов: " .. countOfBytesForArraySize)
			-- print("Размер массива символов: " .. alphaSize)
			-- print("Альфа: " .. alpha)

		elseif header == "S" then
			if decompressColors then
				symbolSize = string.byte(file:read(1))
			else
				symbolSize = mergeBytesToNumber(string.byte(file:read(3), 1, 3))
			end
			symbol = decodeChar(file)
			-- print("Размер массива цвета текста: " .. symbolSize)
			-- print("Символ: \"" .. symbol .. "\"")

		elseif header == "F" then
			if decompressColors then
				foregroundSize = string.byte(file:read(1))
				foreground = colorlib.convert8BitTo24Bit(string.byte(file:read(1)))
			else
				foregroundSize = mergeBytesToNumber(string.byte(file:read(3), 1, 3))
				foreground = mergeBytesToNumber(string.byte(file:read(3), 1, 3))
			end
			-- print("Размер массива цвета фона: " .. foregroundSize)
			-- print("Цвет текста: " .. foreground)

		elseif header == "B" then
			backgroundSize = mergeBytesToNumber(string.byte(file:read(2), 1, 2))
			if decompressColors then
				background = colorlib.convert8BitTo24Bit(string.byte(file:read(1)))
			else
				background = mergeBytesToNumber(string.byte(file:read(3), 1, 3))
			end
			-- print("Размер массива координат: " .. backgroundSize)
			-- print("Цвет фона: " .. background)

			--Читаем координаты
			for i = 1, backgroundSize, 2 do
				local x = string.byte(file:read(1))
				local y = string.byte(file:read(1))
				local index = convertCoordsToIndex(x, y, readedWidth)
				-- print("Координата: " .. x .. "x" .. y .. ", индекс: "..index)

				picture[index] = background
				picture[index + 1] = foreground
				picture[index + 2] = alpha
				picture[index + 3] = symbol
			end			
		else
			error("Ошибка чтения формата OCIF: неизвестный тип заголовка (" .. header .. ")")
		end

	end

	file:close()

	return picture
end

------------------------------ Все, что касается формата RAW ------------------------------------------------------------

--Сохранение в файл сырого формата изображения типа 2 (подробнее о типах см. конец файла)
local function saveRaw(file, picture)

	file:write("\n")

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
local function loadRaw(file)
	--Читаем один байт "прост так"
	file:read(1)

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

----------------------------------- Все, что касается реального PNG-формата ------------------------------------------------------------

function image.loadPng(path)
	if not _G.libPNGImage then _G.libPNGImage = require("libPNGImage") end

	local success, pngImageOrErrorMessage = pcall(libPNGImage.newFromFile, path)

	if not success then
		io.stderr:write(" * PNGView: PNG Loading Error *\n")
		io.stderr:write("While attempting to load '" .. path .. "' as PNG, libPNGImage erred:\n")
		io.stderr:write(pngImageOrErrorMessage)
		return
	end

	local picture = {}
	picture.width, picture.height = pngImageOrErrorMessage:getSize()

	local r, g, b, a, hex
	for j = 0, picture.height - 1 do
		for i = 0, picture.width - 1 do
			r, g, b, a = pngImageOrErrorMessage:getPixel(i, j)

			if r and g and b and a and a > 0 then
				hex = colorlib.RGBtoHEX(r, g, b)
				table.insert(picture, hex)
				table.insert(picture, 0x000000)
				table.insert(picture, 0x00)
				table.insert(picture, " ")
			end

		end
	end

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
		optimizedPicture[alpha] = optimizedPicture[alpha] or {}
		optimizedPicture[alpha][symbol] = optimizedPicture[alpha][symbol] or {}
		optimizedPicture[alpha][symbol][foreground] = optimizedPicture[alpha][symbol][foreground] or {}
		optimizedPicture[alpha][symbol][foreground][background] = optimizedPicture[alpha][symbol][foreground][background] or {}

		table.insert(optimizedPicture[alpha][symbol][foreground][background], xPos)
		table.insert(optimizedPicture[alpha][symbol][foreground][background], yPos)
		--Если xPos достигает width изображения, то сбросить на 1, иначе xPos++
		xPos = (xPos == picture.width) and 1 or xPos + 1
		--Если xPos равняется 1, то yPos++, а если нет, то похуй
		yPos = (xPos == 1) and yPos + 1 or yPos
	end
	--Возвращаем оптимизированный массив
	return optimizedPicture
end

--Нарисовать по указанным координатам картинку указанной ширины и высоты для теста
function image.createImage(width, height, random)
	local picture = {}
	local symbolArray = {"A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "А", "Б", "В", "Г", "Д", "Е", "Ж", "З", "И", "Й", "К", "Л", "И", "Н", "О", "П", "Р", "С", "Т", "У", "Ф", "Х", "Ц", "Ч", "Ш", "Щ", "Ъ", "Ы", "Ь", "Э", "Ю", "Я"}
	picture.width = width
	picture.height = height
	local background, foreground, symbol
	for j = 1, height do
		for i = 1, width do
			if random then
				background = math.random(0x000000, 0xffffff)
				foreground = math.random(0x000000, 0xffffff)
				symbol = symbolArray[math.random(1, #symbolArray)]
			else
				background = 0x880000
				foreground = 0xffffff
				symbol = "Q"
			end

			table.insert(picture, background)
			table.insert(picture, foreground)
			table.insert(picture, 0x00)
			table.insert(picture, symbol)
		end
	end
	-- image.draw(x, y, picture)
	return picture
end

-- Функция оптимизации цвета текста у картинки, уменьшает число GPU-операций при отрисовке
-- Вызывается только при сохранении файла, так что на быстродействии не сказывается,
-- а в целом штука очень и очень полезная. Фиксит криворукость художников.
function image.optimize(picture, showOptimizationProcess)
	local currentForeground = 0x000000
	local optimizationCounter = 0
	for i = 1, #picture, constants.elementCount do
		if picture[i + 3] == " " and picture[i + 1] ~= currentForeground then		
			picture[i + 1] = currentForeground
			if showOptimizationProcess then picture[i + 3] = "#" end
			optimizationCounter = optimizationCounter + 1
		else
			currentForeground = picture[i + 1]
		end
	end
	if showOptimizationProcess then ecs.error("Count of optimized pixels: " .. optimizationCounter) end
	return picture
end

------------------------------------------ Функция снятия скриншота с экрана ------------------------------------------------

--Сделать скриншот экрана и сохранить его по указанному пути
function image.screenshot(path)
	local picture = {}
	local foreground, background, symbol
	picture.width, picture.height = gpu.getResolution()
	
	for j = 1, picture.height do
		for i = 1, picture.width do
			symbol, foreground, background = gpu.get(i, j)
			table.insert(picture, background)
			table.insert(picture, foreground)
			table.insert(picture, 0x00)
			table.insert(picture, symbol)
		end
	end

	image.save(path, picture)
end

------------------------------------------ Функции обработки изображения ------------------------------------------------

function image.expand(picture, mode, countOfPixels, background, foreground, alpha, symbol)
	background = background or 0xffffff
	foreground = foreground or 0x000000
	alpha = alpha or 0x00
	symbol = symbol or " "
	if mode == "fromRight" then
		for j = 1, countOfPixels do
			for i = 1, picture.height do		
				local index = convertCoordsToIndex(picture.width + j, i, picture.width + j)
				table.insert(picture, index, symbol); table.insert(picture, index, alpha); table.insert(picture, index, foreground); table.insert(picture, index, background)
			end
		end
		picture.width = picture.width + countOfPixels
	elseif mode == "fromLeft" then
		for j = 1, countOfPixels do
			for i = 1, picture.height do		
				local index = convertCoordsToIndex(1, i, picture.width + j)
				table.insert(picture, index, symbol); table.insert(picture, index, alpha); table.insert(picture, index, foreground); table.insert(picture, index, background)
			end
		end
		picture.width = picture.width + countOfPixels
	elseif mode == "fromTop" then
		for i = 1, (countOfPixels * picture.width) do
			table.insert(picture, 1, symbol); table.insert(picture, 1, alpha); table.insert(picture, 1, foreground); table.insert(picture, 1, background)
		end
		picture.height = picture.height + countOfPixels
	elseif mode == "fromBottom" then
		for i = 1, (countOfPixels * picture.width) do
			table.insert(picture, background); table.insert(picture, foreground); table.insert(picture, alpha); table.insert(picture, symbol)
		end
		picture.height = picture.height + countOfPixels
	else
		error("Wrong image expanding mode: only 'fromRight', 'fromLeft', 'fromTop' and 'fromBottom' are supported.")
	end
	return picture
end

function image.crop(picture, mode, countOfPixels)
	if mode == "fromRight" then
		for j = 1, countOfPixels do
			for i = 1, picture.height do
				local index = convertCoordsToIndex(picture.width + 1 - j, i, picture.width - j)
				for a = 1, constants.elementCount do table.remove(picture, index) end
			end
		end
		picture.width = picture.width - countOfPixels
	elseif mode == "fromLeft" then
		for j = 1, countOfPixels do
			for i = 1, picture.height do
				local index = convertCoordsToIndex(1, i, picture.width - j)
				for a = 1, constants.elementCount do table.remove(picture, index) end
			end
		end
		picture.width = picture.width - countOfPixels
	elseif mode == "fromTop" then
		for i = 1, (countOfPixels * constants.elementCount * picture.width) do table.remove(picture, 1) end
		picture.height = picture.height - countOfPixels
	elseif mode == "fromBottom" then
		for i = 1, (countOfPixels * constants.elementCount * picture.width) do table.remove(picture, #picture) end
		picture.height = picture.height - countOfPixels
	else
		error("Wrong image cropping mode: only 'fromRight', 'fromLeft', 'fromTop' and 'fromBottom' are supported.")
	end
	return picture
end

function image.flipVertical(picture)
	local newPicture = {}; newPicture.width = picture.width; newPicture.height = picture.height
	for j = picture.height, 1, -1 do
		for i = 1, picture.width do
			local index = convertCoordsToIndex(i, j, picture.width)
			table.insert(newPicture, picture[index]); table.insert(newPicture, picture[index + 1]); table.insert(newPicture, picture[index + 2]); table.insert(newPicture, picture[index + 3])
			picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = nil, nil, nil, nil
		end
	end
	return newPicture
end

function image.flipHorizontal(picture)
	local newPicture = {}; newPicture.width = picture.width; newPicture.height = picture.height
	for j = 1, picture.height do
		for i = picture.width, 1, -1 do
			local index = convertCoordsToIndex(i, j, picture.width)
			table.insert(newPicture, picture[index]); table.insert(newPicture, picture[index + 1]); table.insert(newPicture, picture[index + 2]); table.insert(newPicture, picture[index + 3])
			picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = nil, nil, nil, nil
		end
	end
	return newPicture
end

function image.rotate(picture, angle)
	local function rotateBy90(picture)
		local newPicture = {}; newPicture.width = picture.height; newPicture.height = picture.width
		for i = 1, picture.width do
			for j = picture.height, 1, -1 do
				local index = convertCoordsToIndex(i, j, picture.width)
				table.insert(newPicture, picture[index]); table.insert(newPicture, picture[index + 1]); table.insert(newPicture, picture[index + 2]); table.insert(newPicture, picture[index + 3])
				picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = nil, nil, nil, nil
			end
		end
		return newPicture
	end

	local function rotateBy180(picture)
		local newPicture = {}; newPicture.width = picture.width; newPicture.height = picture.height
		for j = picture.height, 1, -1 do
				for i = picture.width, 1, -1 do
				local index = convertCoordsToIndex(i, j, picture.width)
				table.insert(newPicture, picture[index]); table.insert(newPicture, picture[index + 1]); table.insert(newPicture, picture[index + 2]); table.insert(newPicture, picture[index + 3])
				picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = nil, nil, nil, nil
			end
		end
		return newPicture
	end

	local function rotateBy270(picture)
		local newPicture = {}; newPicture.width = picture.height; newPicture.height = picture.width
		for i = picture.width, 1, -1 do
			for j = 1, picture.height do
				local index = convertCoordsToIndex(i, j, picture.width)
				table.insert(newPicture, picture[index]); table.insert(newPicture, picture[index + 1]); table.insert(newPicture, picture[index + 2]); table.insert(newPicture, picture[index + 3])
				picture[index], picture[index + 1], picture[index + 2], picture[index + 3] = nil, nil, nil, nil
			end
		end
		return newPicture
	end

	if angle == 90 then
		return rotateBy90(picture)
	elseif angle == 180 then
		return rotateBy180(picture)
	elseif angle == 270 then
		return rotateBy270(picture)
	else
		error("Can't rotate image: angle must be 90, 180 or 270 degrees.")
	end
end

------------------------------------------ Функции для работы с цветом -----------------------------------------------

function image.hueSaturationBrightness(picture, hue, saturation, brightness)
	local function calculateBrightnessChanges(color)
		local h, s, b = colorlib.HEXtoHSB(color)
		b = b + brightness; if b < 0 then b = 0 elseif b > 100 then b = 100 end
		s = s + saturation; if s < 0 then s = 0 elseif s > 100 then s = 100 end
		h = h + hue; if h < 0 then h = 0 elseif h > 360 then h = 360 end
		return colorlib.HSBtoHEX(h, s, b)
	end

	for i = 1, #picture, 4 do
		picture[i] = calculateBrightnessChanges(picture[i])
		picture[i + 1] = calculateBrightnessChanges(picture[i + 1])
	end

	return picture
end

function image.hue(picture, hue)
	return image.hueSaturationBrightness(picture, hue, 0, 0)
end

function image.saturation(picture, saturation)
	return image.hueSaturationBrightness(picture, 0, saturation, 0)
end

function image.brightness(picture, brightness)
	return image.hueSaturationBrightness(picture, 0, 0, brightness)
end

function image.blackAndWhite(picture)
	return image.hueSaturationBrightness(picture, 0, -100, 0)
end

function image.colorBalance(picture, r, g, b)
	local function calculateRGBChanges(color)
		local rr, gg, bb = colorlib.HEXtoRGB(color)
		rr = rr + r; gg = gg + g; bb = bb + b
		if rr < 0 then rr = 0 elseif rr > 255 then rr = 255 end
		if gg < 0 then gg = 0 elseif gg > 255 then gg = 255 end
		if bb < 0 then bb = 0 elseif bb > 255 then bb = 255 end
		return colorlib.RGBtoHEX(rr, gg, bb)
	end

	for i = 1, #picture, 4 do
		picture[i] = calculateRGBChanges(picture[i])
		picture[i + 1] = calculateRGBChanges(picture[i + 1])
	end

	return picture
end

function image.invert(picture)
	for i = 1, #picture, 4 do
		picture[i] = 0xffffff - picture[i]
		picture[i + 1] = 0xffffff - picture[i + 1]
	end
	return picture 
end

function image.photoFilter(picture, color, transparency)
	if transparency < 0 then transparency = 0 elseif transparency > 255 then transparency = 255 end
	for i = 1, #picture, 4 do
		picture[i] = colorlib.alphaBlend(picture[i], color, transparency)
		picture[i + 1] = colorlib.alphaBlend(picture[i + 1], color, transparency)
	end
	return picture
end

function image.replaceColor(picture, fromColor, toColor)
	for i = 1, #picture, 4 do
		if picture[i] == fromColor then picture[i] = toColor end
	end
	return picture
end

----------------------------------------- Основные функции программы -------------------------------------------------------------------

--Сохранить изображение любого поддерживаемого формата
function image.save(path, picture, encodingMethod)
	encodingMethod = encodingMethod or 3
	--Создать папку под файл, если ее нет
	fs.makeDirectory(fs.path(path))
	--Получаем формат указанного файла
	local fileFormat = getFileFormat(path)
	--Оптимизируем картинку
	picture = image.optimize(picture)
	--Открываем файл
	local file = io.open(path, "w")
	--Записываем сигнатуру
	writeSignature(file)
	--Проверяем соответствие формата файла
	if fileFormat == constants.compressedFileFormat then
		if encodingMethod == 0 or string.lower(encodingMethod) == "raw" then
			file:write(string.char(encodingMethod))
			saveRaw(file, picture)
		elseif encodingMethod == 1 or string.lower(encodingMethod) == "ocif1" then
			file:write(string.char(encodingMethod))
			saveOCIF1(file, picture)
		elseif encodingMethod == 2 or string.lower(encodingMethod) == "ocif2" then
			file:write(string.char(encodingMethod))
			saveOCIF2(file, picture)
		elseif encodingMethod == 3 or string.lower(encodingMethod) == "ocif3" then
			file:write(string.char(encodingMethod))
			picture = compressImageColorsTo8Bit(picture)
			saveOCIF2(file, picture, true)
		else
			file:close()
			error("Unsupported encoding method.\n")
		end
	else
		file:close()
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
		local file = io.open(path, "rb")
		--Читаем сигнатуру файла
		readSignature(file)
		--Читаем метод обработки изображения
		local encodingMethod = string.byte(file:read(1))
		--Читаем файлы в зависимости от метода
		--print("Загружаю файл типа " .. encodingMethod)
		if encodingMethod == 0 then
			return loadRaw(file)
		elseif encodingMethod == 1 then
			return loadOCIF1(file)
		elseif encodingMethod == 2 then
			return loadOCIF2(file)
		elseif encodingMethod == 3 then
			return loadOCIF2(file, true)
		else
			file:close()
			error("Unsupported encoding method.\n")
		end
	else
		file:close()
		error("Unsupported file format.\n")
	end
end

--Отрисовка изображения типа 3 (подробнее о типах см. конец файла)
function image.draw(x, y, picture)
	--Конвертируем в групповое изображение
	picture = image.convertToGroupedImage(picture)
	--Все как обычно
	x, y = x - 1, y - 1

	local xPos, yPos, currentBackground
	for alpha in pairs(picture) do
		for symbol in pairs(picture[alpha]) do
			for foreground in pairs(picture[alpha][symbol]) do
				if gpu.getForeground ~= foreground then gpu.setForeground(foreground) end
				for background in pairs(picture[alpha][symbol][foreground]) do
					if gpu.getBackground ~= background then gpu.setBackground(background) end
					currentBackground = background
					for i = 1, #picture[alpha][symbol][foreground][background], 2 do	
						xPos, yPos = x + picture[alpha][symbol][foreground][background][i], y + picture[alpha][symbol][foreground][background][i + 1]
						
						--Если альфа имеется, но она не совсем прозрачна
						if (alpha > 0x00 and alpha < 0xFF) or (alpha == 0xFF and symbol ~= " ")then
							_, _, currentBackground = gpu.get(xPos, yPos)
							currentBackground = colorlib.alphaBlend(currentBackground, background, alpha)
							gpu.setBackground(currentBackground)

							gpu.set(xPos, yPos, symbol)

						elseif alpha == 0x00 then
							if currentBackground ~= background then
								currentBackground = background
								gpu.setBackground(currentBackground)
							end

							gpu.set(xPos, yPos, symbol)
						end
						--ecs.wait()
					end
				end
			end
		end
	end
end

local function createSaveAndLoadFiles()
	ecs.prepareToExit()
	ecs.error("Создаю/загружаю изображение")
	local cyka = image.load("MineOS/System/OS/Icons/Love.pic")
	--local cyka = image.createImage(4, 4)
	ecs.error("Рисую загруженное изображение")
	image.draw(2, 2, cyka)
	ecs.error("Сохраняю его в 4 форматах")
	image.save("0.pic", cyka, 0)
	image.save("1.pic", cyka, 1)
	image.save("2.pic", cyka, 2)
	image.save("3.pic", cyka, 3)
	ecs.prepareToExit()
	ecs.error("Загружаю все 4 формата и рисую их")
	local cyka0 = image.load("0.pic")
	image.draw(2, 2, cyka0)
	local cyka1 = image.load("1.pic")
	image.draw(10, 2, cyka1)
	local cyka2 = image.load("2.pic")
	image.draw(18, 2, cyka2)
	local cyka3 = image.load("3.pic")
	image.draw(26, 2, cyka3)
	ecs.error("Рисую все 3 формата")
end

------------------------------------------ Место для баловства ------------------------------------------------

-- ecs.prepareToExit()

-- local cyka = image.load("MineOS/Applications/Piano.app/Resources/Icon.pic")
-- image.draw(2, 2, cyka)
-- ecs.error(HEXtoSTRING(cyka[1], 6, true))
-- image.draw(8, 2, cyka)
-- createSaveAndLoadFiles()

------------------------------------------------------------------------------------------------------------------------

return image











