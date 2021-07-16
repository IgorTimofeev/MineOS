
local image = require("Image")
local GUI = require("GUI")

------------------------------------------------------

local workspace, window, menu = select(1, ...), select(2, ...), select(3, ...)
local tool = {}
local locale = select(4, ...)

tool.shortcut = "Txt"
tool.keyCode = 20
tool.about = locale.tool7

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		local input = workspace:addChild(GUI.input(
			e3 - 1,
			e4,
			window.image.x + window.image.width - e3 + 2,
			1,
			nil,
			window.primaryColorSelector.color,
			window.primaryColorSelector.color,
			nil,
			window.primaryColorSelector.color,
			""
		))
		
		input.onInputFinished = function()
			if #input.text > 0 then
				local x, y = e3 - window.image.x + 1, e4 - window.image.y + 1
				for i = 1, unicode.len(input.text) do
					if x <= window.image.width then
						local background, foreground, alpha = image.get(window.image.data, x, y)
						image.set(window.image.data, x, y, background, window.primaryColorSelector.color, alpha, unicode.sub(input.text, i, i))
						x = x + 1
					else
						break
					end
				end
			end

			input:remove()
			workspace:draw()
		end

		input:startInput()
	end
end

------------------------------------------------------

return tool
