


local buffer = {}
local countOfGPUOperations = 0
local debug = true

------------------------------------------------------------------------------------------------------

local function printDebug(line, text)
	if debug then 
		ecs.colorTextWithBack(1, line, 0xFFFFFF, 0x262626, text)
	end
end

function buffer.createArray()
	buffer.screen.current = {}
	buffer.screen.new = {}

	for y = 1, buffer.screen.height do
		for x = 1, buffer.screen.width do
			buffer.screen.current[y] = buffer.screen.current[y] or {}
			table.insert(buffer.screen.current[y], -1)
			table.insert(buffer.screen.current[y], -1)
			table.insert(buffer.screen.current[y], -1)

			buffer.screen.new[y] = buffer.screen.new[y] or {}
			table.insert(buffer.screen.new[y], -1)
			table.insert(buffer.screen.new[y], -1)
			table.insert(buffer.screen.new[y], -1)
		end
	end
end

function buffer.start()
	buffer.screen = {
		current = {},
		new = {},
	}

	buffer.screen.width, buffer.screen.height = gpu.getResolution()

	local old = ecs.getInfoAboutRAM()
	buffer.createArray()
	local new = ecs.getInfoAboutRAM()
	printDebug(49, "Схавалось " .. old - new .. " КБ оперативки")
end

function buffer.get(x, y)
	local xPos = x * 3
	if buffer.screen.new[y] and buffer.screen.new[y][xPos] then
		return buffer.screen.current[y][xPos - 2], buffer.screen.current[y][xPos - 2], buffer.screen.current[y][xPos]
	else
		error("Невозможно получить указанные значения, так как указанные координаты лежат за пределами экрана.\n")
	end
end

function buffer.set(x, y, background, foreground, symbol)
	local xPos = x * 3
	if buffer.screen.new[y] and buffer.screen.new[y][xPos] then
		buffer.screen.new[y][xPos - 2] = background
		buffer.screen.new[y][xPos - 1] = foreground
		buffer.screen.new[y][xPos] = symbol
	end
end

function buffer.fill(x, y, width, height, background, foreground, symbol)
	local xPos
	for j = y, (y + height - 1) do
		for i = x, (x + width - 1) do
			xPos = i * 3
			if buffer.screen.new[y] and buffer.screen.new[y][xPos] then
				buffer.screen.new[j][xPos] = symbol; xPos = xPos - 1
				buffer.screen.new[j][xPos] = foreground; xPos = xPos - 1
				buffer.screen.new[j][xPos] = background
			end
		end
	end
end

function buffer.calculateDifference(x, y)
	local xPos = x * 3 - 2
	local backgroundIsChanged, foregroundIsChanged, symbolIsChanged = false, false, false
	
	--Если цвет фона на новом экране отличается от цвета фона на текущем, то
	if buffer.screen.new[y][xPos] ~= buffer.screen.current[y][xPos] then
		--Присваиваем цвету фона на текущем экране значение цвета фона на новом экране
		buffer.screen.current[y][xPos] = buffer.screen.new[y][xPos]
		
		--Говорим системе, что что фон изменился
		backgroundIsChanged = true
	end
	xPos = xPos + 1
	
	--Аналогично для цвета текста
	if buffer.screen.new[y][xPos] ~= buffer.screen.current[y][xPos] then
		buffer.screen.current[y][xPos] = buffer.screen.new[y][xPos]
		foregroundIsChanged = true
	end
	xPos = xPos + 1

	--И для символа
	if buffer.screen.new[y][xPos] ~= buffer.screen.current[y][xPos] then
		buffer.screen.current[y][xPos] = buffer.screen.new[y][xPos]
		symbolIsChanged = true
	end

	return backgroundIsChanged, foregroundIsChanged, symbolIsChanged
end

function buffer.draw()
	local currentBackground, currentForeground = -math.huge, -math.huge
	local xPos
	
	for y = 1, buffer.screen.height do
		local x = 1
		while x <= buffer.screen.width do

			xPos = x * 3 - 2

			local backgroundIsChanged, foregroundIsChanged, symbolIsChanged = buffer.calculateDifference(x, y)

			if backgroundIsChanged and currentBackground ~= buffer.screen.current[y][xPos] then
				gpu.setBackground(buffer.screen.current[y][xPos])
				currentBackground = buffer.screen.current[y][xPos]
				countOfGPUOperations = countOfGPUOperations + 1
			end

			xPos = xPos + 1

			if foregroundIsChanged and currentForeground ~= buffer.screen.current[y][xPos] then
				gpu.setForeground(buffer.screen.current[y][xPos])
				currentForeground = buffer.screen.current[y][xPos]
				countOfGPUOperations = countOfGPUOperations + 1
			end

			xPos = xPos - 1

			--Если были найдены какие-то отличия нового экрана от старого, то корректируем эти отличия через gpu.set()
			if backgroundIsChanged or foregroundIsChanged or symbolIsChanged then
				local countOfSameSymbols = 1

				local iPos
				for i = (x + 1), buffer.screen.width do
					iPos = i * 3 - 2
					if buffer.screen.current[y][xPos] == buffer.screen.new[y][iPos] and buffer.screen.current[y][xPos + 1] == buffer.screen.new[y][iPos + 1] and buffer.screen.current[y][xPos + 2] == buffer.screen.new[y][iPos + 2] then
					 	countOfSameSymbols = countOfSameSymbols + 1
					 	buffer.calculateDifference(i, y)
					else
						break
					end
				end

				--ecs.error(countOfSameSymbols)

				gpu.set(x, y, string.rep(buffer.screen.current[y][xPos + 2], countOfSameSymbols))
				
				x = x + countOfSameSymbols - 1

				countOfGPUOperations = countOfGPUOperations + 1
			end

			x = x + 1
		end
	end

	printDebug(50, "Количество GPU-операций: " .. countOfGPUOperations)
end

------------------------------------------------------------------------------------------------------

-- ecs.prepareToExit()

-- buffer.start()
-- buffer.fill(1, 1, 20, 10, 0xCCCCCC, 0x262626, "A")
-- buffer.set(4, 4, 0x00FF00, 0xFFFFFF, "B")
-- buffer.set(10, 10, 0xFFFF00, 0x000000, "C")
-- buffer.draw()

-- ecs.wait()

------------------------------------------------------------------------------------------------------


return buffer















