
local GUI = require("GUI")
local paths = require("Paths")
local system = require("System")
local network = require("Network")
local filesystem = require("Filesystem")

local module = {}

local workspace, window, localization = table.unpack({...})
local userSettings = system.getUserSettings()

--------------------------------------------------------------------------------

module.name = localization.network
module.margin = 0
module.onTouch = function()
	local emptyObject = window.contentLayout:addChild(GUI.object(1, 1, 0, 0))
	local insertModemText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkNoModem))
	local ebloText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkThis))
	local networkNameInput = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, userSettings.networkName or "", localization.networkName))
	local stateSwitchAndLabel = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.networkEnabled .. ":", userSettings.networkEnabled))
	local remoteComputersText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkRemote))	
	local remoteComputersComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	local allowReadAndWriteSwitchAndLabel = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.networkFileAccess .. ":", false))

	local signalStrengthSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 512, userSettings.networkSignalStrength, false, localization.networkRadius ..": ", ""))
	signalStrengthSlider.roundValues = true

	local function check()
		insertModemText.hidden = network.modemProxy

		for i = 3, #window.contentLayout.children do
			window.contentLayout.children[i].hidden = not network.modemProxy
		end

		if network.modemProxy then
			for i = 6, #window.contentLayout.children do
				window.contentLayout.children[i].hidden = not stateSwitchAndLabel.switch.state
			end

			if stateSwitchAndLabel.switch.state then
				signalStrengthSlider.hidden = not network.modemProxy.isWireless()

				remoteComputersComboBox:clear()
				for proxy, path in filesystem.mounts() do
					if proxy.networkModem then
						local item = remoteComputersComboBox:addItem(network.getModemProxyName(proxy))
						item.proxyAddress = proxy.address
						item.onTouch = function()
							allowReadAndWriteSwitchAndLabel.switch:setState(userSettings.networkUsers[item.proxyAddress].allowReadAndWrite)
						end
					end
				end
				
				remoteComputersText.hidden = remoteComputersComboBox:count() < 1
				remoteComputersComboBox.hidden = remoteComputersText.hidden
				allowReadAndWriteSwitchAndLabel.hidden = remoteComputersText.hidden

				if not remoteComputersText.hidden then
					remoteComputersComboBox:getItem(remoteComputersComboBox.selectedItem).onTouch()
				end
			end
		end

		workspace:draw()
	end

	networkNameInput.onInputFinished = function()
		userSettings.networkName = #networkNameInput.text > 0 and networkNameInput.text or nil
		system.saveUserSettings()
		network.broadcastComputerState(userSettings.networkEnabled)
	end

	signalStrengthSlider.onValueChanged = function()
		userSettings.networkSignalStrength = math.floor(signalStrengthSlider.value)
		system.saveUserSettings()
	end

	stateSwitchAndLabel.switch.onStateChanged = function()
		if stateSwitchAndLabel.switch.state then
			network.enable()
		else
			network.disable()
		end

		check()
	end

	allowReadAndWriteSwitchAndLabel.switch.onStateChanged = function()
		userSettings.networkUsers[remoteComputersComboBox:getItem(remoteComputersComboBox.selectedItem).proxyAddress].allowReadAndWrite = allowReadAndWriteSwitchAndLabel.switch.state
		system.saveUserSettings()
	end

	-- Empty object-listener
	emptyObject.eventHandler = function(workspace, object, e1, e2, e3, ...)
		if (e1 == "component_added" or e1 == "component_removed") and e3 == "modem" then
			check()
		elseif e1 == "network" and e2 == "updateProxyList" then
			check()
		end
	end

	check()
end

--------------------------------------------------------------------------------

return module

