
local GUI = require("GUI")
local text = require("Text")
local filesystem = require("Filesystem")
local paths = require("Paths")
local system = require("System")
local image = require("Image")
local SHA = require("SHA-256")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.users
module.margin = 7
module.onTouch = function()
	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.usersList))

	local function addButton(parent, x, width, ...)
		local button = parent:addChild(GUI.button(x, 1, width, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, ...))
		button.colors.disabled = {
			background = 0xE1E1E1,
			text = 0xB4B4B4
		}

		return button
	end

	local function addInput(parent, ...)
		return parent:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, ...))
	end

	local function addComboBox(parent, width)
		return parent:addChild(GUI.comboBox(1, 1, width, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	end

	local usersContainer = window.contentLayout:addChild(GUI.container(1, 1, 36, 3))
	local removeUserButton = addButton(usersContainer, usersContainer.width - 4, 5, "─")
	local addUserButton = addButton(usersContainer, removeUserButton.localX - 6, 5, "+")
	local usersComboBox = addComboBox(usersContainer, addUserButton.localX - 2)

	local iconButton = addButton(window.contentLayout, 1, 36, localization.usersEditIcon)
	
	local renameButton = addButton(window.contentLayout, 1, 36, localization.usersChangeName)
	local renameInput = addInput(window.contentLayout, "", localization.usersChangeNamePlaceholder)
	
	local passwordButton = addButton(window.contentLayout, 1, 36, "")
	local passwordInput = addInput(window.contentLayout, "", localization.usersAddPasswordPlaceholder1, false, "•")
	local submitPasswordInput = addInput(window.contentLayout, "", localization.usersAddPasswordPlaceholder2, false, "•")
	local passwordText = window.contentLayout:addChild(GUI.text(1, 1, 0xCC4940, localization.usersPasswordsArentEqual))

	local function updatePasswordText()
		passwordButton.text = userSettings.securityPassword and localization.usersRemovePassword or localization.usersAddPassword
	end

	local function updateRename(state)
		renameButton.hidden = state
		renameInput.hidden = not state
	end

	local function getSelected()
		return usersComboBox:getItem(usersComboBox.selectedItem).text
	end

	local function updateRemoveAndPasswordButtons(state)
		if system.getUser() == getSelected() then
			removeUserButton.disabled = true
			passwordButton.hidden = state
			passwordInput.hidden = not state
			submitPasswordInput.hidden = not state
		else
			removeUserButton.disabled = false
			passwordButton.hidden = true
			passwordInput.hidden = true
			submitPasswordInput.hidden = true
			passwordText.hidden = true
		end
	end

	local function updateUserList()
		usersComboBox:clear()
		
		local list = filesystem.list(paths.system.users)
		for i = 1, #list do
			if filesystem.isDirectory(paths.system.users .. list[i]) then
				local name = list[i]:sub(1, -2)
				usersComboBox:addItem(name)

				if name == system.getUser() then
					usersComboBox.selectedItem = usersComboBox:count()
				end
			end
		end

		updateRemoveAndPasswordButtons()
	end

	usersComboBox.onItemSelected = function()
		updateRemoveAndPasswordButtons()
	end

	updatePasswordText()
	updateUserList()

	renameInput.hidden = true
	passwordInput.hidden = true
	submitPasswordInput.hidden = true
	passwordText.hidden = true

	addUserButton.onTouch = function()
		local name = "User #" .. math.random(0xFFFFFF)

		system.createUser(name, userSettings.localizationLanguage, nil, userSettings.interfaceWallpaperEnabled, userSettings.interfaceScreensaverEnabled)
		
		usersComboBox:addItem(name)
		usersComboBox.selectedItem = usersComboBox:count()
	end

	removeUserButton.onTouch = function()
		filesystem.remove(paths.system.users .. getSelected() .. "/")
		updateUserList()
	end

	iconButton.onTouch = function()
		system.execute(paths.system.applicationPictureEdit, "-on", paths.system.users .. getSelected() .. "/Icon.pic", 8, 4)
	end

	renameButton.onTouch = function()
		updateRename(true)
	end

	passwordButton.onTouch = function()
		if userSettings.securityPassword then
			userSettings.securityPassword = nil
			updatePasswordText()

			workspace:draw()
			system.saveUserSettings()
		else
			updateRemoveAndPasswordButtons(true)
		end
	end

	renameInput.onInputFinished = function()
		if #renameInput.text > 0 then
			filesystem.rename(paths.system.users .. getSelected() .. "/", paths.system.users .. renameInput.text .. "/")
			
			if getSelected() == system.getUser() then
				system.setUser(renameInput.text)
				computer.pushSignal("system", "updateFileList")
			end

			updateUserList()
			renameInput.text = ""
			updateRename(false)

			workspace:draw()
		end
	end

	passwordInput.onInputFinished = function()
		if #passwordInput.text > 0 and #submitPasswordInput.text > 0 then
			if passwordInput.text == submitPasswordInput.text then
				userSettings.securityPassword = SHA.hash(passwordInput.text)
				system.saveUserSettings()

				passwordInput.text = ""
				submitPasswordInput.text = ""
				updatePasswordText()
				updateRemoveAndPasswordButtons()

				passwordText.hidden = true
			else
				passwordText.hidden = false
			end

			workspace:draw()
		end
	end
	submitPasswordInput.onInputFinished = passwordInput.onInputFinished

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.usersClaim))

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.usersClaimInfo}, 1, 0, 0, true, true))

	local claimContainer = window.contentLayout:addChild(GUI.container(1, 1, 36, 3))
	local claimRemoveButton = addButton(claimContainer, claimContainer.width - 4, 5, "─")
	local claimComboBox = addComboBox(claimContainer, claimRemoveButton.localX - 2)

	local claimInput = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.usersClaimPlaceholder))


	local function update()
		local users = {computer.users()}
		-- local users = {"ECS", "Xylic", "Computrix", "Yan0t", "Кукарек", "Bird", "Pirnogion"}
		
		claimContainer.hidden = #users == 0
		claimComboBox:clear()

		for i = 1, #users do
			claimComboBox:addItem(users[i])
		end
	end

	claimRemoveButton.onTouch = function()
		computer.removeUser(claimComboBox:getItem(claimComboBox.selectedItem).text)
		
		update()
		workspace:draw()
	end

	claimInput.onInputFinished = function()
		if #claimInput.text > 0 then
			computer.addUser(claimInput.text)
			claimInput.text = ""

			update()
			workspace:draw()
		end
	end

	update()
end

--------------------------------------------------------------------------------

return module
