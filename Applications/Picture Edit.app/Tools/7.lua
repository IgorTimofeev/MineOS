
local image = require("image")
local GUI = require("GUI")
local tool = {}

------------------------------------------------------

tool.shortcut = "Tx"
tool.keyCode = 20
tool.about = "Text tool allows you to type some text data with selected primary color right on your image! It's time to say \"ur mom gay\" to everyone <3"

tool.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "touch" then
		local input = workspace:addChild(GUI.input(
			e3 - 1,
			e4,
			workspace.image.x + workspace.image.width - e3 + 2,
			1,
			nil,
			workspace.primaryColorSelector.color,
			workspace.primaryColorSelector.color,
			nil,
			workspace.primaryColorSelector.color,
			""
		))
		
		input.onInputFinished = function()
			if #input.text > 0 then
				local x, y = e3 - workspace.image.x + 1, e4 - workspace.image.y + 1
				for i = 1, unicode.len(input.text) do
					if x <= workspace.image.width then
						local background, foreground, alpha = image.get(workspace.image.data, x, y)
						image.set(workspace.image.data, x, y, background, workspace.primaryColorSelector.color, alpha, unicode.sub(input.text, i, i))
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