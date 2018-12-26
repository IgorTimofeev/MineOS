
local fs = require("filesystem")
local image = require("image")
local buffer = require("doubleBuffering")
local GUI = require("GUI")
local component = require("component")
local unicode = require("unicode")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSInterface = require("MineOSInterface")
if not component.isAvailable("stargate") then
	GUI.alert("This program requires stargate from mod \"SGCraft\"")
	return
end
local stargate = component.stargate

---------------------------------------------------------------------------------------------

local resources = MineOSCore.getCurrentScriptDirectory()
local pathToContacts = MineOSPaths.applicationData .. "Stargate/Contacts.cfg"
local contacts = {}
local Ch1Image = image.load(resources .. "Ch1.pic")
local Ch2Image = image.load(resources .. "Ch2.pic")

local application = GUI.application()

---------------------------------------------------------------------------------------------

local function loadContacts()
	if fs.exists(pathToContacts) then
		contacts = table.fromFile(pathToContacts)
	end
end

local function saveContacts()
	table.toFile(pathToContacts, contacts)
end

local function chevronDraw(object)
	local inactiveColor, activeColor, fadeColor = 0x332400, 0xFFDB00, 0xCC6D00
	-- buffer.drawRectangle(object.x, object.y, object.width, object.height, object.isActivated and fadeColor or inactiveColor)
	-- buffer.drawRectangle(object.x + 1, object.y, 3, object.height, object.isActivated and activeColor or inactiveColor)
	-- buffer.drawText(object.x + 2, object.y + 1, object.isActivated and 0x0 or 0xFFFFFF, object.text)
	buffer.drawImage(object.x, object.y, object.isActivated and Ch1Image or Ch2Image)
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
	table.insert(application.chevrons, application.chevronsContainer:addChild(newChevronObject(x, y)))
end

local function updateChevrons(state)
	for i = 1, #application.chevrons do
		application.chevrons[i].isActivated = state
		if not state then application.chevrons[i].text = " " end
	end
end

local function updateButtons()
	application.removeContactButton.disabled = #contacts == 0
	application.connectContactButton.disabled = #contacts == 0
end

local function update()
	local stargateState, irisState, imagePath = stargate.stargateState(), stargate.irisState()
	application.irisButton.text = irisState == "Closed" and "Open Iris" or "Close Iris"
	application.connectionButton.text = stargateState == "Connected" and "Disconnect" or "Connect"
	application.connectedToLabel.text = stargateState == "Connected" and "(Connected to " .. stargate.remoteAddress() .. ")" or "(Not connected)"
	
	if stargateState == "Connected" then
		application.connectContactButton.disabled = true
		application.messageContactButton.disabled = false

		if irisState == "Closed" then
			imagePath = "OnOn.pic"
		else
			imagePath = "OnOff.pic"
		end
	else
		application.connectContactButton.disabled = false
		application.messageContactButton.disabled = true

		if irisState == "Closed" then
			imagePath = "OffOn.pic"
		else
			imagePath = "OffOff.pic"
		end
	end

	updateButtons()
	application.SGImage.image = image.load(resources .. imagePath)
end

local function updateContacts()
	application.contactsComboBox:clear()
	if #contacts == 0 then
		application.contactsComboBox:addItem("No contacts found")
	else
		for i = 1, #contacts do
			application.contactsComboBox:addItem(contacts[i].name)
		end
	end
end

local function newThing(x, y, width, height)
	local object = GUI.object(x, y, width, height)
	
	object.draw = function(object)
		local x, y = object.x + object.width - 1, math.floor(object.y + object.height / 2)
		for i = object.y, object.y + object.height - 1 do
			buffer.drawText(x, i, 0xEEEEEE, "│")
		end
		for i = object.x, object.x + width - 1 do
			buffer.drawText(i, y, 0xEEEEEE, "─")
		end
		buffer.drawText(x, y, 0xEEEEEE, "┤")
	end

	return object
end

local function dial(address)
	local success, reason = stargate.dial(address)
	if success then
		application.fuelProgressBar.value = math.ceil(stargate.energyToDial(address) / stargate.energyAvailable() * 100)
		application:draw()
	else
		GUI.alert("Failed to dial: " .. tostring(reason))
	end
end

---------------------------------------------------------------------------------------------

local width, height = 32, 37
local x, y = application.width - width - 3, math.floor(application.height / 2 - height / 2)

application:addChild(GUI.panel(1, 1, application.width, application.height, 0x1E1E1E))

application.SGImage = application:addChild(GUI.image(1, 1, image.load(resources .. "OffOff.pic")))
application.SGImage.localX, application.SGImage.localY = math.floor((x - 2) / 2 - image.getWidth(application.SGImage.image) / 2), application.height - image.getHeight(application.SGImage.image) + 1

application.chevronsContainer = application:addChild(GUI.container(application.SGImage.localX, application.SGImage.localY, application.SGImage.width, application.SGImage.height))
application.chevrons = {}
addChevron(13, 30)
addChevron(8, 17)
addChevron(21, 6)
addChevron(45, 1)
addChevron(72, 6)
addChevron(83, 17)
addChevron(79, 30)

application:addChild(newThing(application.SGImage.localX + application.SGImage.width, y, application.width - application.SGImage.localX - application.SGImage.width - width - 7,  height))

application:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Stargate " .. stargate.localAddress())):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 1
application.connectedToLabel = application:addChild(GUI.label(x, y, width, 1, 0x555555, "(Not connected)")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
application.connectionButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Connect")); y = y + 3
-- application.connectionButton.animated = false
application.connectionButton.onTouch = function()
	if stargate.stargateState() == "Idle" then
		local container = MineOSInterface.addBackgroundContainer(application, "Connect")
		local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, contacts.last, "Type address here"))
		input.onInputFinished = function()
			if input.text then
				dial(input.text)
				contacts.last = input.text
				saveContacts()
				container:remove()

				application:draw()
			end
		end

		container.panel.eventHandler = function(application, object, e1)
			if e1 == "touch" then
				input.onInputFinished()
			end
		end

		application:draw()
	else
		stargate.disconnect()
	end
end

application.irisButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Open Iris")); y = y + 3
application.irisButton.onTouch = function()
	if stargate.irisState() == "Open" then
		stargate.closeIris()
	else
		stargate.openIris()
	end
end

application.messageContactButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Message")); y = y + 4
application.messageContactButton.onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, "Message")
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, "Type message text here"))
	input.onInputFinished = function()
		if input.text then
			container:remove()
			stargate.sendMessage(input.text)

			application:draw()
		end
	end

	container.panel.eventHandler = function(application, object, e1)
		if e1 == "touch" then
			input.onInputFinished()
		end
	end

	application:draw()
end

application:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Contacts")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
application.contactsComboBox = application:addChild(GUI.comboBox(x, y, width, 3, 0x3C3C3C, 0xBBBBBB, 0x555555, 0x888888)); y = y + 4

application.connectContactButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Connect")); y = y + 3
application.connectContactButton.onTouch = function()
	dial(contacts[application.contactsComboBox.selectedItem].address)
end

application.addContactButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Add contact")); y = y + 3
application.addContactButton.onTouch = function()
	local container = MineOSInterface.addBackgroundContainer(application, "Add contact")
	local input1 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, nil, "Name"))
	local input2 = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xEEEEEE, 0x666666, 0x666666, 0xEEEEEE, 0x262626, contacts.last, "Address"))

	container.panel.eventHandler = function(application, object, e1)
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
				application:draw()
			end
		end
	end

	application:draw()
end

application.removeContactButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Remove contact")); y = y + 4
application.removeContactButton.onTouch = function()
	if #contacts > 0 then
		table.remove(contacts, application.contactsComboBox.selectedItem)
		updateContacts()
		saveContacts()
		updateButtons()

		application:draw()
	end
end

application:addChild(GUI.label(x, y, width, 1, 0xEEEEEE, "Energy to dial")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP); y = y + 2
application.fuelProgressBar = application:addChild(GUI.progressBar(x, y, width, 0xBBBBBB, 0x0, 0xEEEEEE, 100, true, true, "", "%")); y = y + 3
application.exitButton = application:addChild(GUI.framedButton(x, y, width, 3, 0xEEEEEE, 0xEEEEEE, 0xBBBBBB, 0xBBBBBB, "Exit")); y = y + 4
application.exitButton.onTouch = function()
	application:stop()
end

application.eventHandler = function(application, object, e1, e2, e3, e4)
	if e1 == "sgIrisStateChange" then
		update()
		application:draw()
	elseif e1 == "sgStargateStateChange" then
		if e3 == "Idle" or e3 == "Connected" then
			update()
			updateChevrons(e3 == "Connected")
			application:draw()
		end
	elseif e1 == "sgChevronEngaged" then
		if application.chevrons[e3] then
			application.chevrons[e3].isActivated = true
			application.chevrons[e3].text = e4
			application:draw()
		end
	elseif e1 == "sgMessageReceived" then
		GUI.alert(e3)
	end
end

loadContacts()
updateContacts()
update()
updateChevrons(stargate.stargateState() == "Connected")

application:draw()
application:start()