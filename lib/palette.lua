local component = require("component")
local event = require("event")
local term = require("term")
local unicode = require("unicode")
local ecs = require("ECSAPI")
local colorlib = require("colorlib")

local gpu = component.gpu

local palette = {}

------------------------------------------------------------------------------------

local height = 23
local width = 78
local rainbowWidth, rainbowHeight = 40, 20
local h, s, b, rr, gg, bb, hex = 0, 100, 100, 255, 0, 0, 0xff0000

local yHueSelector, xCrest, yCrest, oldCrest, startColor, xPalette, yPalette, xBigRainbow, yBigRainbow, xMiniRainbow, xColors, oldPixels

------------------------------------------------------------------------------------

local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawBigRainbow()
	local x, y = xBigRainbow - 1, yBigRainbow - 1

	local saturation, brightness = 1, 100
	local xModifyer, yModifyer = 2.53, 5.263157

	for i = 1, rainbowWidth do
		brightness = 100
		for j = 1, rainbowHeight do
			ecs.square(x + i, y + j, 2, 1, colorlib.HSBtoHEX(h, saturation, brightness))
			brightness = brightness - yModifyer
		end
		saturation = saturation + xModifyer
	end
end

local function drawMiniRainbow(x, y)
	y = y - 1

	local hue = 0
	local yModifyer = 18.94736
	for i = 1, rainbowHeight do
		ecs.square(x, y + i, 3, 1, colorlib.HSBtoHEX(hue, 100, 100))
		hue = hue + yModifyer
	end
end


local function drawHueSelector(x, y)
	ecs.colorTextWithBack(x, y, 0x000000, ecs.windowColors.background, ">")
	gpu.set(x + 4, y, "<")
end

local function calculateAllColors(hexColor)
	rr, gg, bb = colorlib.HEXtoRGB(hexColor)
	h, s, b = colorlib.RGBtoHSB(rr, gg, bb)
	hex = hexColor

	--ecs.error("Подсчитано: r = "..rr..", g = "..gg..", b = "..bb..", h = "..h..", s = "..s..", b = "..b..", hex = "..tostring(hex))
end

local function rememberOldCrest()
	oldCrest = ecs.rememberOldPixels(xCrest - 2, yCrest - 1, xCrest + 2, yCrest + 1)
end

--ЭТО КУРСОРЧИК КРЕСТИК
local function drawCrest(pointX, pointY)
	ecs.drawOldPixels(oldCrest)
	rememberOldCrest()

	ecs.invertedText(pointX-2,pointY,"─")
	ecs.invertedText(pointX+2,pointY,"─")
	ecs.invertedText(pointX-1,pointY,"─")
	ecs.invertedText(pointX+1,pointY,"─")
	ecs.invertedText(pointX,pointY-1,"│")
	ecs.invertedText(pointX,pointY+1,"│")
end

local function drawColors()
	ecs.square(xColors, yBigRainbow, 10, 3, hex)
	ecs.square(xColors, yBigRainbow + 3, 10, 3, startColor)
end

local function convertHexToString(hex)
	local stroka = string.format("%x", hex)
	local sStroka = unicode.len(stroka)

	if sStroka < 6 then
		stroka = string.rep("0", 6 - sStroka) .. stroka
	end

	return stroka
end

local function convertStringToHex(stroka)
	return tonumber(stroka)
end

local function drawInfo()

	local x, y = xColors, yBigRainbow + 7

	local massiv = {
		{"R:", math.floor(rr)},
		{"G:", math.floor(gg)},
		{"B:", math.floor(bb)},
		{"H:", math.floor(h)},
		{"S:", math.floor(s)},
		{"L:", math.floor(b)},
		{"0x", convertHexToString(hex)},
	}

	local yPos = y

	for i = 1, #massiv do
		ecs.colorTextWithBack(x, yPos, ecs.windowColors.usualText, ecs.windowColors.background, massiv[i][1])
		ecs.inputText(x + 3, yPos, 7, tostring(massiv[i][2]), 0xffffff, 0x000000, true)

		newObj("Inputs", massiv[i][1], x + 3, yPos, x + 10, yPos)

		yPos = yPos + 2
	end
end

--Просчитать позицию креста, основываясь на цветах
local function calculateCrest()
	xModifyer, yModifyer = rainbowWidth / 100, rainbowHeight / 100
	xCrest, yCrest = xBigRainbow + s * xModifyer, yBigRainbow + rainbowHeight - (b * yModifyer)

	if yCrest == yPalette + height - 1 then yCrest = yCrest - 1 end
end

--То же самое, но на основе текущего Хуя
local function calculateMini()
	yModifyer = rainbowHeight / 360
	yHueSelector = yBigRainbow + math.abs(h * yModifyer - yModifyer)
end

local function drawButtons()
	local xButtons, yButtons = xColors + 12, yBigRainbow
	newObj("Buttons", "  OK  ", ecs.drawAdaptiveButton(xButtons, yButtons, 3, 0, "  OK  ", ecs.colors.lightBlue, 0xffffff))
	newObj("Buttons", "Отмена", ecs.drawAdaptiveButton(xButtons, yButtons + 2, 3, 0, "Отмена", 0xffffff, 0x000000))
end

--Собственно, отрисовка палитры
local function drawPalette()

	--Считаем все цвета от стартового хекса
	calculateAllColors(startColor)

	--Рисуем окошечко и прочее
	xPalette, yPalette = ecs.correctStartCoords(xPalette, yPalette, width, height)
	oldPixels = ecs.emptyWindow(xPalette, yPalette, width, height, "Выберите цвет")

	--Считаем коорды радуки и всякую хуйню
	xBigRainbow, yBigRainbow = xPalette + 2, yPalette + 2
	xMiniRainbow = xPalette + 46
	xColors = xMiniRainbow + 6

	--Рисуем обе радуги
	drawBigRainbow()
	drawMiniRainbow(xMiniRainbow, yBigRainbow)

	--Рисуем крест
	calculateCrest()
	rememberOldCrest()
	drawCrest(xCrest, yCrest)

	--Рисуем черточки у выбора Хуя
	calculateMini()
	drawHueSelector(xMiniRainbow - 1, yHueSelector)

	--Рисуем цвета
	drawColors()

	--Рисуем текстики
	drawInfo()

	--Рисуем кнопочки
	drawButtons()
end

--ТУ ХУЙНЮ НАРИСОВАТЬ
local function drawGOVNO()
	--Две горизонтальные сверху и снизу
	ecs.square(xBigRainbow - 2, yBigRainbow - 1, rainbowWidth + 4, 1, ecs.windowColors.background)
	gpu.fill(xBigRainbow - 2, yBigRainbow + rainbowHeight, rainbowWidth + 4, 1, " ")

	--И две вертикальные
	gpu.fill(xBigRainbow - 2, yBigRainbow, 2, rainbowHeight, " ")
	gpu.fill(xBigRainbow + rainbowWidth + 1, yBigRainbow, 2, rainbowHeight, " ")

	--И еще две мелких хуйни около мелкой радужки
	gpu.fill(xMiniRainbow - 1, yBigRainbow, 1, rainbowHeight, " ")
	gpu.fill(xMiniRainbow + 3, yBigRainbow, 1, rainbowHeight, " ")
end

--Вот эту херь вызывать только в случае глобального изменения Хуя
local function changeColor()
	drawBigRainbow()
	drawGOVNO()
	rememberOldCrest()
	calculateCrest()
	calculateMini()
	drawCrest(xCrest, yCrest)
	drawHueSelector(xMiniRainbow - 1, yHueSelector)
	drawColors()
	drawInfo()
end

------------------------------------------------------------

--Самая жирная и главная пиздофункция!
function palette.draw(xPalette1, yPalette1, startColor1)

	--Всякие стартовые хуевинки
	if not startColor1 then startColor1 = 0xff0000 end

	--Костыли, костыли
	xPalette, yPalette = xPalette1, yPalette1
	startColor = startColor1
	hex = startColor

	--Рисуем саму палитру
	drawPalette()

	--Объектики создаем на всякий
	newObj("Zones", "Big", xBigRainbow, yBigRainbow, xBigRainbow + rainbowWidth, yBigRainbow + rainbowHeight - 1)
	newObj("Zones", "Mini", xMiniRainbow, yBigRainbow, xMiniRainbow + 2, yBigRainbow + rainbowHeight - 1)

	--Смотрим, че как
	while true do
		local e = {event.pull()}
		if e[1] == "touch" or e[1] == "drag" then

			--Клик на жирную радугу
			if ecs.clickedAtArea(e[3], e[4], obj["Zones"]["Big"][1], obj["Zones"]["Big"][2], obj["Zones"]["Big"][3], obj["Zones"]["Big"][4]) then
				--Крест на новое место
				xCrest = e[3]
				yCrest = e[4]
				drawCrest(xCrest, yCrest)

				--Просчет цвета
				local symbol, fore, back = gpu.get(e[3], e[4])
				calculateAllColors(back)
				drawColors()
				drawInfo()
			--А это если на мелкую радугу
			elseif ecs.clickedAtArea(e[3], e[4], obj["Zones"]["Mini"][1], obj["Zones"]["Mini"][2], obj["Zones"]["Mini"][3], obj["Zones"]["Mini"][4]) then
				local symbol, fore, back = gpu.get(e[3], e[4])
				--Считаем цвета
				h = colorlib.HEXtoHSB(back)
				rr, gg, bb = colorlib.HSBtoRGB(h, s, b)

				--перерисовываем
				drawGOVNO()
				drawHueSelector(xMiniRainbow - 1, e[4])
				drawBigRainbow()
				rememberOldCrest()
				drawCrest(xCrest, yCrest)

				symbol, fore, back = gpu.get(xCrest, yCrest)
				hex = back

				drawColors()
				drawInfo()
			end

			--А это кнопочки!
			for key, val in pairs(obj["Buttons"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Buttons"][key][1], obj["Buttons"][key][2], obj["Buttons"][key][3], obj["Buttons"][key][4]) then
					ecs.drawAdaptiveButton(obj["Buttons"][key][1], obj["Buttons"][key][2], 3, 0, key, ecs.colors.blue, 0xffffff)
					os.sleep(0.3)

					if key == "  OK  " then
						ecs.drawOldPixels(oldPixels)
						return hex
					else
						ecs.drawOldPixels(oldPixels)
						return nil
					end
				end
			end


			--А это... уууу, бля! Не лезь сюда вообще. Говнокод, но рабочий!
			for key, val in pairs(obj["Inputs"]) do
				if ecs.clickedAtArea(e[3], e[4], obj["Inputs"][key][1], obj["Inputs"][key][2], obj["Inputs"][key][3], obj["Inputs"][key][4]) then

					local text = ecs.inputText(obj["Inputs"][key][1], obj["Inputs"][key][2], 7, "", 0xffffff, 0x000000, false)	

					if text ~= "" and text ~= " " and text then
						if key == "0x" then
							hex = convertStringToHex("0x"..text)
							calculateAllColors(hex)
						elseif key == "R:" then
							local color = tonumber(text)
							if color >= 255 then color = 255 end
							if color < 1 then color = 1 end
							rr = color

							hex = colorlib.RGBtoHEX(rr, gg, bb)
							h, s, b = colorlib.RGBtoHSB(rr, gg, bb)
						elseif key == "G:" then
							local color = tonumber(text)
							if color >= 255 then color = 255 end
							if color < 1 then color = 1 end
							gg = color

							hex = colorlib.RGBtoHEX(rr, gg, bb)
							h, s, b = colorlib.RGBtoHSB(rr, gg, bb)
						elseif key == "B:" then
							local color = tonumber(text)
							if color >= 255 then color = 255 end
							if color < 1 then color = 1 end
							bb = color

							hex = colorlib.RGBtoHEX(rr, gg, bb)
							h, s, b = colorlib.RGBtoHSB(rr, gg, bb)
						elseif key == "H:" then
							local color = tonumber(text)
							if color >= 360 then color = 0 end
							if color < 0 then color = 0 end
							h = color

							hex = colorlib.HSBtoHEX(h, s, b)
							rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
						elseif key == "S:" then
							local color = tonumber(text)
							if color >= 100 then color = 100 end
							if color < 0 then color = 0 end
							s = color

							hex = colorlib.HSBtoHEX(h, s, b)
							rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
						elseif key == "L:" then
							local color = tonumber(text)
							if color >= 100 then color = 100 end
							if color < 0 then color = 0 end
							b = color

							hex = colorlib.HSBtoHEX(h, s, b)
							rr, gg, bb = colorlib.HSBtoRGB(h, s, b)
						end

						changeColor()

						break
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------------------

--print( convertHexToString( palette.draw(5, 5, 0xff00ff) ))

return palette











