
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.disks
module.margin = 6
module.onTouch = function()
	local currentAddress = component.proxy(component.list("eeprom")()).getData()

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksControl))

	local comboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))

	local input = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, "", localization.disksRename))

	local button = window.contentLayout:addChild(GUI.button(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x696969, 0xE1E1E1, localization.disksFormat))

	window.contentLayout:addChild(GUI.textBox(1, 1, 36, 1, nil, 0xA5A5A5, {localization.disksInfo}, 1, 0, 0, true, true))

	window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.disksStatistics))

	local progressBar = window.contentLayout:addChild(GUI.progressBar(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xA5A5A5, 100, true, true, "", "%"))
	progressBar.height = 2

	local layout = window.contentLayout:addChild(GUI.layout(1, 1, 36, 1, 1, 1))
	layout:setAlignment(1, 1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_TOP)

	local permissionsKV = layout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0xA5A5A5, localization.disksPermissions, ""))
	local spaceTotalKV = layout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0xA5A5A5, localization.disksSpaceTotal, ""))
	local spaceUsedKV = layout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0xA5A5A5, localization.disksSpaceUsed, ""))
	local spaceFreeKV = layout:addChild(GUI.keyAndValue(1, 1, 0x696969, 0xA5A5A5, localization.disksSpaceFree, ""))

	layout.height = (#layout.children * 2) - 1

	local function getProxy()
		return comboBox:getItem(comboBox.selectedItem).proxy
	end

	local function update()
		local proxy = getProxy()
		local used, total = proxy.spaceUsed(), proxy.spaceTotal()
		local free = total - used

		progressBar.value = math.ceil(used / total * 100)
		permissionsKV.value = ": " .. (proxy.isReadOnly() and localization.disksReadOnly or localization.disksReadAndWrite)
		spaceTotalKV.value = ": " .. string.format("%.2f", total / 1024 / 1024) .. " MB"
		spaceUsedKV.value = ": " .. string.format("%.2f", used / 1024 / 1024) .. " MB"
		spaceFreeKV.value = ": " .. string.format("%.2f", free / 1024 / 1024) .. " MB"
	end

	local function fill()
		comboBox:clear()

		for address in component.list("filesystem") do
			local proxy = component.proxy(address)
			local label = proxy.getLabel()
			local item = comboBox:addItem(label and label .. " (" .. address .. ")" or address)
			item.proxy = proxy

			if address == currentAddress then
				comboBox.selectedItem = comboBox:count()
			end
		end

		update()
	end

	comboBox.onItemSelected = function()
		currentAddress = getProxy().address
		update()
		workspace:draw()
	end

	input.onInputFinished = function()
		local success, reason = pcall(getProxy().setLabel, input.text)
		input.text = ""
		
		if success then
			fill()
		else
			GUI.alert(reason)
		end

		workspace:draw()
	end

	button.onTouch = function()
		local proxy = getProxy()
		local list = proxy.list("/")
		for i = 1, #list do
			proxy.remove("/" .. list[i])
		end

		fill()
		workspace:draw()
	end
		
	fill()
end

--------------------------------------------------------------------------------

return module

