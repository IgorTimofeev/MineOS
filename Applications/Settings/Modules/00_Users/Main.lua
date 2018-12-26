
local GUI = require("GUI")
local computer = require("computer")

local module = {}

local application, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.users
module.margin = 0
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.usersAdd))

	local input = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.usersTypeNameHere))

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.usersInfo}, 1, 0, 0, true, true))

	local usersListText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.usersList))

	local usersLayout = window.contentLayout:addChild(GUI.layout(1, 1, 36, 1, 1, 1))
	usersLayout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)
	usersLayout:setSpacing(1, 1, 0)

	local function update()
		local users = {computer.users()}
		-- local users = {"ECS", "Xylic", "Computrix", "Yan0t", "Кукарек", "Bird", "Pirnogion"}
		
		usersLayout:removeChildren()
		usersLayout.height = 0

		usersListText.hidden = #users == 0
		usersLayout.hidden = usersListText.hidden

		module.margin = #users * 3

		if #users > 0 then
			local step = false

			for i = 1, #users do
				local userContainer = usersLayout:addChild(GUI.container(1, 1, usersLayout.width, 3))
				userContainer:addChild(GUI.panel(1, 1, userContainer.width - 5, userContainer.height, 0xE1E1E1))
				userContainer:addChild(GUI.text(2, 2, 0x696969, string.limit(users[i], userContainer.width - 5, "right")))
				userContainer:addChild(GUI.button(userContainer.width - 4, 1, 5, 3, step and 0xC3C3C3 or 0xD2D2D2, 0x0, 0x969696, 0xE1E1E1, "x")).onTouch = function()
					computer.removeUser(users[i])

					update()
					application:draw()
				end

				usersLayout.height, step = usersLayout.height + userContainer.height, not step
			end
		end
	end

	input.onInputFinished = function()
		if #input.text > 0 then
			computer.addUser(input.text)
			input.text = ""

			update()
			application:draw()
		end
	end

	update()
end

--------------------------------------------------------------------------------

return module
