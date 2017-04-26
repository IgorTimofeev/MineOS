
local args = {...}
local filesystem = require("filesystem")
local image = require("image")
local buffer = require("doubleBuffering")

if args[1] then
	if filesystem.exists(args[1]) then
		-- Очищаем экранный буфер черным цветом
		buffer.clear(0x000000)
		-- Загружаем и рисуем изображение в буфер
		buffer.image(1, 1, image.load(args[1]))
		-- Отрисовываем содержимое буфера в принудительном режиме
		buffer.draw(true)
	else
		print("Файл \"" .. tostring(args[1]) .. "\" не существует")
	end
else
	print("Использование: draw <путь к изображению>")
end
