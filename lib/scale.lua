
local component = require("component")
local screenScale = {}

------------------------------------------------------------------------------------------------------

local function calculateAspect(screens)
	if screens == 2 then
		return 28
	elseif screens > 2 then
		return 28 + (screens - 2) * 16
	else
		return 12
	end
end

function screenScale.getResolution(scale, debug)
	if scale > 1 then
		scale = 1
	elseif scale <= 0.01 then
		scale = 0.01
	end

	local xScreens, yScreens = component.proxy(component.gpu.getScreen()).getAspectRatio()
	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)
	local proportion = xPixels / yPixels

	local xMax, yMax = component.gpu.maxResolution()

	local newWidth, newHeight
	if proportion >= 1 then
		newWidth = xMax
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = yMax
		newWidth = math.floor(newHeight * proportion * 2)
	end

	local optimalNewWidth, optimalNewHeight = newWidth, newHeight
	if optimalNewWidth > xMax then
		local difference = newWidth / xMax
		optimalNewWidth = xMax
		optimalNewHeight = math.ceil(newHeight / difference)
	end

	if optimalNewHeight > yMax then
		local difference = newHeight / yMax
		optimalNewHeight = yMax
		optimalNewWidth = math.ceil(newWidth / difference)
	end

	local finalNewWidth, finalNewHeight = math.floor(optimalNewWidth * scale), math.floor(optimalNewHeight * scale)

	if debug then
		print(" ")
		print("Максимальное разрешение: "..xMax.."x"..yMax)
		print("Пропорция монитора: "..xPixels.."x"..yPixels)
		print("Коэффициент пропорции: "..proportion)
		print(" ")
		print("Теоретическое разрешение: "..newWidth.."x"..newHeight)
		print("Оптимизированное разрешение: "..optimalNewWidth.."x"..optimalNewHeight)
		print(" ")
		print("Новое разрешение: "..finalNewWidth.."x"..finalNewHeight)
		print(" ")
	end

	return finalNewWidth, finalNewHeight
end

--Установка масштаба монитора
function screenScale.set(scale, debug)
	--Устанавливаем выбранное разрешение
	component.gpu.setResolution(screenScale.getResolution(scale, debug))
end

------------------------------------------------------------------------------------------------------

-- screenScale.set(0.8)

------------------------------------------------------------------------------------------------------

return screenScale





