
if not _G.buffer then _G.buffer = require("doubleBuffering") end
if not _G.unicode then _G.unicode = require("unicode") end

local buttons = {}
buttons.IDs = {}
buttons.pressTime = 0.2

--------------------------------------------------------------------------------------------------------------------------------

local function getRandomID()
	local ID
	repeat
   		ID = math.floor(math.random(1, 0xFFFFFF))
  	until not buttons.IDs[ID]
  	return ID
end

local function drawButton(ID)
	local state = buttons.IDs[ID].isPressed and "pressed" or "default"

	if buttons.IDs[ID] then
		buffer.button(buttons.IDs[ID].x, buttons.IDs[ID].y, buttons.IDs[ID].width, buttons.IDs[ID].height, buttons.IDs[ID].style[state].buttonColor, buttons.IDs[ID].style[state].textColor, buttons.IDs[ID].text)
	else
		error("Button ID \"" .. ID .. "\" doesn't exists.\n")
	end
end

local function clickedAtArea(x, y, x1, y1, x2, y2)
	if x >= x1 and x <= x2 and y >= y1 and y <= y2 then
		return true
	end
end

--------------------------------------------------------------------------------------------------------------------------------

function buttons.checkEventData(eventData)
	if eventData[1] == "touch" then
		for ID in pairs(buttons.IDs) do
			if clickedAtArea(eventData[3], eventData[4], buttons.IDs[ID].x, buttons.IDs[ID].y, buttons.IDs[ID].x2, buttons.IDs[ID].y2) then
				buttons.IDs[ID].isPressed = true
				drawButton(ID)
				buffer.draw()
				
				os.sleep(buttons.pressTime or 0.2)
				
				buttons.IDs[ID].isPressed = nil
				drawButton(ID)
				buffer.draw()
				
				if buttons.IDs[ID].callback then
					pcall(buttons.IDs[ID].callback)
				end
			end
		end
	end
end

function buttons.newStyle(buttonColor, textColor, buttonColorWhenPressed, textColorWhenPressed)
	return { 
		default = { 
			buttonColor = buttonColor,
			textColor = textColor,
		},
		pressed = { 
			buttonColor = buttonColorWhenPressed,
			textColor = textColorWhenPressed,
		}, 
	}
end

function buttons.draw(...)
	local IDs = { ... }
	if #IDs > 0 then
		for ID in pairs(IDs) do
			if buttons.IDs[ID] then
				drawButton(ID)
			else
				error("Button ID \"" .. ID .. "\" doesn't exists.\n")
			end
		end
		buffer.draw()
	else
		for ID in pairs(buttons.IDs) do
			drawButton(ID)
		end
		buffer.draw()
	end
end

function buttons.add(x, y, width, height, style, text, callback)
	checkArg(1, x, "number")
	checkArg(2, y, "number")
	checkArg(3, width, "number")
	checkArg(4, height, "number")
	checkArg(5, style, "table")
	checkArg(6, text, "string")
	if callback then checkArg(7, callback, "function") end

	local ID = getRandomID()

	buttons.IDs[ID] = {
		x = x,
		y = y,
		x2 = x + width - 1,
		y2 = y + height - 1,
		width = width,
		height = height,
		style = style,
		text = text,
		callback = callback
	}

	return ID
end

function buttons.remove( ... )
	local IDs = { ... }
	if #IDs > 0 then
		for ID in pairs(IDs) do
			if buttons.IDs[ID] then
				buttons.IDs[ID] = nil
			else
				error("Button ID \"" .. ID .. "\" doesn't exists.\n")
			end
		end
	else
		buttons.IDs = {}
	end
end

function buttons.setPressTime(time)
	buttons.pressTime = time
end

--------------------------------------------------------------------------------------------------------------------------------

return buttons







