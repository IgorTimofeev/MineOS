local event = require("event")
local computer = require("computer")

----------------------------------------------------------------------------------------------------------------

local buttons = {}
buttons.pressTime = 0.2
buttons.objects = {}

function buttons.setPressTime(time)
	buttons.pressTime = time
end

function buttons.getPressTime()
	return buttons.pressTime
end

local function checkError(class, name)
	if not buttons.objects[class] then error("Несуществующий класс кнопки \"" .. class .. "\"") end
	if not buttons.objects[class][name] then error("Несуществующее имя кнопки \"" .. name .. "\" в классе \"" .. class .. "\"" ) end
end

function buttons.draw(class, name)
	checkError(class, name)
	if buttons.objects[class][name].visible then
		if buttons.objects[class][name].pressed then
			ecs.drawButton(buttons.objects[class][name].x, buttons.objects[class][name].y, buttons.objects[class][name].width, buttons.objects[class][name].height, name, buttons.objects[class][name].backgroundWhenPressed, buttons.objects[class][name].foregroundWhenPressed)
		else
			ecs.drawButton(buttons.objects[class][name].x, buttons.objects[class][name].y, buttons.objects[class][name].width, buttons.objects[class][name].height, name, buttons.objects[class][name].background, buttons.objects[class][name].foreground)
		end
	end
end

function buttons.add(class, name, x, y, width, height, background, foreground, backgroundWhenPressed, foregroundWhenPressed, justAddNoDraw)
	buttons.objects[class] = buttons.objects[class] or {}
	buttons.objects[class][name] = {
		["x"] = x,
		["y"] = y,
		["width"] = width,
		["height"] = height,
		["background"] = background,
		["foreground"] = foreground,
		["backgroundWhenPressed"] = backgroundWhenPressed,
		["foregroundWhenPressed"] = foregroundWhenPressed,
		["visible"] = not justAddNoDraw,
		["pressed"] = false,
	}
	if not justAddNoDraw then
		buttons.draw(class, name)
	end
end

function buttons.remove(class, name)
	checkError(class, name)
	buttons.objects[class][name] = nil
end

function buttons.setVisible(class, name, state)
	checkError(class, name)
	buttons.objects[class][name].visible = state
end

function buttons.press(class, name)
	checkError(class, name)
	buttons.objects[class][name].pressed = true
	buttons.draw(class, name)
	os.sleep(buttons.pressTime)
	buttons.objects[class][name].pressed = false
	buttons.draw(class, name)
end

function buttons.drawAll()
	for class in pairs(buttons.objects) do
		for name in pairs(buttons.objects[class]) do
			buttons.draw(class, name)
		end
	end
end

local function listener(...)
	local e = {...}
	local exit = false
	if e[1] == "touch" then
		for class in pairs(buttons.objects) do
			if exit then break end
			for name in pairs(buttons.objects[class]) do
				if ecs.clickedAtArea(e[3], e[4], buttons.objects[class][name].x, buttons.objects[class][name].y, buttons.objects[class][name].x + buttons.objects[class][name].width - 1, buttons.objects[class][name].y + buttons.objects[class][name].height - 1) then
					if buttons.objects[class][name].visible then
						buttons.press(class, name)
						computer.pushSignal("button_pressed", class, name, buttons.objects[class][name].x, buttons.objects[class][name].y, buttons.objects[class][name].width, buttons.objects[class][name].height)
					end
					exit = true
					break
				end
			end
		end
	end
end

function buttons.start()
	event.listen("touch", listener)
end

function buttons.stop()
	event.ignore("touch", listener)
end

------------------------------------------ Тест программы -------------------------------------------------------------------

-- ecs.prepareToExit()
-- buttons.start()
-- local xPos, yPos, width, height, counter = 2, 6, 6, 3, 1
-- for i = 1, 10 do
-- 	for j = 1, 20 do
-- 		buttons.add("Test", tostring(counter), xPos, yPos, width, height, ecs.colors.green, 0xFFFFFF, ecs.colors.red, 0xFFFFFF)
-- 		xPos = xPos + width + 2; counter = counter + 1
-- 	end
-- 	xPos = 2; yPos = yPos + height + 1
-- end
-- buttons.add("Test", "Выйти отсюдова", 2, 2, 30, 3, ecs.colors.orange, 0xFFFFFF, ecs.colors.red, 0xFFFFFF)

-- while true do
-- 	local e = {event.pull()}
-- 	if e[1] == "button_pressed" then
-- 		if e[2] == "Test" and e[3] == "Выйти отсюдова" then
-- 			buttons.stop()
-- 			ecs.prepareToExit()
-- 			break
-- 		end
-- 	end
-- end






