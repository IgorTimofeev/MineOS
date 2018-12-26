
local GUI = require("GUI")
local MineOSInterface = require("MineOSInterface")
local MineOSPaths = require("MineOSPaths")
local MineOSCore = require("MineOSCore")
local MineOSNetwork = require("MineOSNetwork")
local filesystem = require("filesystem")

local module = {}

local application, window, localization = table.unpack({...})

--------------------------------------------------------------------------------

module.name = localization.network
module.margin = 0
module.onTouch = function()
	local emptyObject = window.contentLayout:addChild(GUI.object(1, 1, 0, 0))
	local insertModemText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkNoModem))
	local ebloText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkThis))
	local networkNameInput = window.contentLayout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xA5A5A5, 0xE1E1E1, 0x2D2D2D, MineOSCore.properties.network.name or "", localization.networkName))
	local stateSwitchAndLabel = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.networkEnabled .. ":", MineOSCore.properties.network.enabled))
	local remoteComputersText = window.contentLayout:addChild(GUI.text(1, 1, 0x2D2D2D, localization.networkRemote))	
	local remoteComputersComboBox = window.contentLayout:addChild(GUI.comboBox(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0xD2D2D2, 0xA5A5A5))
	local allowReadAndWriteSwitchAndLabel = window.contentLayout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, localization.networkFileAccess .. ":", false))

	local signalStrengthSlider = window.contentLayout:addChild(GUI.slider(1, 1, 36, 0x66DB80, 0xE1E1E1, 0xFFFFFF, 0xA5A5A5, 0, 512, MineOSCore.properties.network.signalStrength, false, localization.networkRadius ..": ", ""))
	signalStrengthSlider.roundValues = true

	local function check()
		insertModemText.hidden = MineOSNetwork.modemProxy

		for i = 3, #window.contentLayout.children do
			window.contentLayout.children[i].hidden = not MineOSNetwork.modemProxy
		end

		if MineOSNetwork.modemProxy then
			for i = 6, #window.contentLayout.children do
				window.contentLayout.children[i].hidden = not stateSwitchAndLabel.switch.state
			end

			if stateSwitchAndLabel.switch.state then
				signalStrengthSlider.hidden = not MineOSNetwork.modemProxy.isWireless()

				remoteComputersComboBox:clear()
				for proxy, path in filesystem.mounts() do
					if proxy.MineOSNetworkModem then
						local item = remoteComputersComboBox:addItem(MineOSNetwork.getModemProxyName(proxy))
						item.proxyAddress = proxy.address
						item.onTouch = function()
							allowReadAndWriteSwitchAndLabel.switch:setState(MineOSCore.properties.network.users[item.proxyAddress].allowReadAndWrite)
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

		application:draw()
	end

	networkNameInput.onInputFinished = function()
		MineOSCore.properties.network.name = #networkNameInput.text > 0 and networkNameInput.text or nil
		MineOSCore.saveProperties()
		MineOSNetwork.broadcastComputerState(MineOSCore.properties.network.enabled)
	end

	signalStrengthSlider.onValueChanged = function()
		MineOSCore.properties.network.signalStrength = math.floor(signalStrengthSlider.value)
		MineOSCore.saveProperties()
	end

	stateSwitchAndLabel.switch.onStateChanged = function()
		if stateSwitchAndLabel.switch.state then
			MineOSNetwork.enable()
		else
			MineOSNetwork.disable()
		end

		check()
	end

	allowReadAndWriteSwitchAndLabel.switch.onStateChanged = function()
		MineOSCore.properties.network.users[remoteComputersComboBox:getItem(remoteComputersComboBox.selectedItem).proxyAddress].allowReadAndWrite = allowReadAndWriteSwitchAndLabel.switch.state
		MineOSCore.saveProperties()
	end

	-- Empty object-listener
	emptyObject.eventHandler = function(application, object, e1, e2, e3, ...)
		if (e1 == "component_added" or e1 == "component_removed") and e3 == "modem" then
			check()
		elseif e1 == "MineOSNetwork" and e2 == "updateProxyList" then
			check()
		end
	end

	check()
end

--------------------------------------------------------------------------------

return module

