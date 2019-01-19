
local filesystem = require("Filesystem")
local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")

if not component.isAvailable("stargate") then
	GUI.alert("This program requires stargate from mod \"SGCraft\"")
	return
end

local stargate = component.get("stargate")

---------------------------------------------------------------------------------------------

local resources = filesystem.path(system.getCurrentScript())
local pathToContacts = paths.user.applicationData .. "Stargate/Contacts.cfg"
local contacts = {}
local Ch1Image = image.load(resources .. "Ch1.pic")
local Ch2Image = image.load(resources .. "Ch2.pic")

local workspace = GUI.workspace()

---------------------------------------------------------------------------------------------

local function loadContacts()
	if filesystem.exists(pathToContacts) then
		contacts = filesystem.readTable(pathToContacts)
	end
end

local function saveContacts()
	filesystem.writeTable(pathToContacts, contacts)
end

local function chevronDraw(object)
	local inactiveColor, activeColor, fadeColor = 0x332400, 0xFFDB00, 0xCC6D00
	-- screen.drawRectangle(object.x, object.y, object.width, object.height, object.isActivated and fadeColor or inactiveColor)
	-- screen.drawRectangle(object.x + 1, object.y, 3, object.height, object.isActivated and activeColor or inactiveColor)
	-- screen.drawText(object.x + 2, object.y + 1, object.isActivated and 0x0 or 0xFFFFFF, object.text)
	screen.drawImage(object.x, object.y, object.isActivated and Ch1Image or Ch2Image)
	return object
end

local function newChevronObject(x, y)
	local object = GUI.object(x, y, 5, 3)

	object.draw = chevronDraw
	object.isActivated = false
	object.text = " "

	return object
end

local function addChevron(x, y)
	table.insert(workspace.chevrons, workspace.chevronsContainer:addChild(newChevronObject(x, y)))
end

local function updateChevrons(state)
	for i = 1, #workspace.chevrons do
		workspace.chevrons[i].isActivated = state
		if not state then workspace.chevrons[i].text = " " end
	end
end

local function updateButtons()
	workspace.removeContactButton.disabled = #contacts == 0
	workspace.connectContactButton.disabled = #contacts == 0
end

local function update()
	local stargateState, irisState, imagePath = stargate.stargateState(), stargate.irisState()
	workspace.irisButton.text = irisState == "Closed" and "Open Iris" or "Close Iris"
	workspace.connectionButton.text = stargateState == "Connected" and "Disconnect" or "Connect"
	workspace.connectedToLabel.text = stargateState == "Connected" and "(Connected to " .. stargate.remoteAddress() .. ")" or "(Not connected)"
	
	if stargateState == "Connected" then
		workspace.connectContactButton.disabled = true
		workspace.messageContactButton.disabled = false

		if irisState == "Closed" then
			imagePath = "OnOn.pic"
		else
			imagePath = "OnOff.pic"
		end
	else
		workspace.connectContactButton.disabled = false
		workspace.messageContactButton.disabled = true

		if irisState == "Closed" then
			imagePath = "OffOn.pic"
		else
			imagePath = "OffOff.pic"
		end
	end

	updateButtons()
	workspace.SGImage.image = image.load(resources .. imagePath)
end

local function updateContacts()
	workspace.contactsComboBox:clear()
	if #contacts == 0 then
		workspace.contactsComboBox:addItem("No contacts found")
	else
		for i = 1, #contacts do
			workspace.contactsComboBox:addItem(contacts[i].name)
		end
	end
end

local function newThing(x, y, width, height)
	local object = GUI.object(x, y, width, height)
	
	object.draw = function(object)
		local x, y = object.x + object.width - 1, math.floor(object.y + object.height / 2)
		for i = object.y, object.y + object.height - 1 do
			screen.drawText(x, i, 0xEEEEEE, "│")
		end
		for i = object.x, object.x + width - 1 do
			screen.drawText(i, y, 0xEEEEEE, "─")
		end
		screen.drawText(x, y, 0xEEEEEE, "┤")
	end

	return object
end

local function dial(address)
	local success, reason = stargate.dial(address)
	if success then
		workspace.fuelProgressBar.value = math.ceil(stargate.energyToDial(address) / stargate.energyAvailable() * 100)
		workspace:draw()
	else
		GUI.alert("Failed to dial: " .. tostring(reason))
	end
end

---------------------------------------------------------------------------------------------

local width, height = 32, 37
local x, y = workspace.width - width - 3, math.floor(workspace.height / 2 - height / 2)

workspace:addChild(GUI.panel(1, 1, workspace.width, workspace.height, 0x1E1E1E))

workspace.SGImage = workspace:addChild(GUI.image(1, 1, image.load(resources .. "OffOff.pic")))
workspace.SGImage.localX, workspace.SGImage.localY = math.floor((x - 2) / 2 - image.getWidth(workspace.SGImage.image) / 2), workspace.height - image.getHeight(workspace.SGImage.image) + 1

workspace.chevronsContainer = workspace:addChild(GUI.container(workspace.SGImage.localX, workspace.SGImage.localY, workspace.SGImage.width, workspace.SGImage.height))
workspace.chevrons = {}
addChevron(13, 30)
addChevron(8, 17)
addChevron(21, 6)
addChevron(45, 1)
addChevron(72, 6)
addChevron(83, 17)
addChevron(79, 30)

workspace:addChild(newThing(workspace.SGImage.localX + workspace.SGImage.width, y, workspace.width - workspace.SGImage.localX - workspace.SGImage.width - width - 7,  height))

workspace:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Stargate " .. stargate.localAddress())):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 1
workspace.connectedToLabel = workspace:addChild(GUI.label(x, y, width, 1, 0x555555, "(Not connected)")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
workspace.connectionButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Connect")); y = y + 3
-- workspace.connectionButton.animated = false
workspace.connectionButton.onTouch = function()
	if stargate.stargateState() == "Idle" then
		local container = GUI.addBackgroundContainer(workspace, true, true, "Connect")
		local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, contacts.last, "Type address here"))
		input.onInputFinished = function()
			if input.text then
				dial(input.text)
				contacts.last = input.text
				saveContacts()
				container:remove()

				workspace:draw()
			end
		end

		container.panel.eventHandler = function(workspace, object, e1)
			if e1 == "touch" then
				input.onInputFinished()
			end
		end

		workspace:draw()
	else
		stargate.disconnect()
	end
end

workspace.irisButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Open Iris")); y = y + 3
workspace.irisButton.onTouch = function()
	if stargate.irisState() == "Open" then
		stargate.closeIris()
	else
		stargate.openIris()
	end
end

workspace.messageContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Message")); y = y + 4
workspace.messageContactButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "Message")
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, "Type message text here"))
	input.onInputFinished = function()
		if input.text then
			container:remove()
			stargate.sendMessage(input.text)

			workspace:draw()
		end
	end

	container.panel.eventHandler = function(workspace, object, e1)
		if e1 == "touch" then
			input.onInputFinished()
		end
	end

	workspace:draw()
end

workspace:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Contacts")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
workspace.contactsComboBox = workspace:addChild(GUI.comboBox(x, y, width, 3, 0x3C3C3C, 0xBBBBBB, 0x555555, 0x888888)); y = y + 4

workspace.connectContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Connect")); y = y + 3
workspace.connectContactButton.onTouch = function()
	dial(contacts[workspace.contactsComboBox.selectedItem].address)
end

workspace.addContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Add contact")); y = y + 3
workspace.addContactButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, "Add contact")
	local input1 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, "Name"))
	local input2 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, contacts.last, "Address"))

	container.panel.eventHandler = function(workspace, object, e1)
		if e1 == "touch" then
			if input1.text and input2.text then
				local exists = false
				for i = 1, #contacts do
					if contacts[i].address == input2.text then
						exists = true
						break
					end
				end
				if not exists then
					table.insert(contacts, {name = input1.text, address = input2.text})
					updateContacts()
					saveContacts()	
					updateButtons()
				end

				container:remove()
				workspace:draw()
			end
		end
	end

	workspace:draw()
end

workspace.removeContactButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Remove contact")); y = y + 4
workspace.removeContactButton.onTouch = function()
	if #contacts > 0 then
		table.remove(contacts, workspace.contactsComboBox.selectedItem)
		updateContacts()
		saveContacts()
		updateButtons()

		workspace:draw()
	end
end

workspace:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Energy to dial")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
workspace.fuelProgressBar = workspace:addChild(GUI.progressBar(x, y, width, 0xBBBBBB, 0x0, 0xEEEEEE, 100, true, true, "", "%")); y = y + 3
workspace.exitButton = workspace:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Exit")); y = y + 4
workspace.exitButton.onTouch = function()
	workspace:stop()
end

workspace.eventHandler = function(workspace, object, e1, e2, e3, e4)
	if e1 == "sgIrisStateChange" then
		update()
		workspace:draw()
	elseif e1 == "sgStargateStateChange" then
		if e3 == "Idle" or e3 == "Connected" then
			update()
			updateChevrons(e3 == "Connected")
			workspace:draw()
		end
	elseif e1 == "sgChevronEngaged" then
		if workspace.chevrons[e3] then
			workspace.chevrons[e3].isActivated = true
			workspace.chevrons[e3].text = e4
			workspace:draw()
		end
	elseif e1 == "sgMessageReceived" then
		GUI.alert(e3)
	end
end

loadContacts()
updateContacts()
update()
updateChevrons(stargate.stargateState() == "Connected")

workspace:draw()
workspace:start()