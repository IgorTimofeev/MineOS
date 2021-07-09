
local args = {...}
local workspace, window, localization = args[1], args[2], args[3]

local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local number = require("Number")

----------------------------------------------------------------------------------------------------------------

local module = {}
module.name = localization.moduleDisk

local HDDImage = image.load(paths.system.icons .. "HDD.pic")
local floppyImage = image.load(paths.system.icons .. "Floppy.pic")

----------------------------------------------------------------------------------------------------------------

module.onTouch = function()
	window.contentContainer:removeChildren()
	local container = window.contentContainer:addChild(GUI.container(1, 1, window.contentContainer.width, window.contentContainer.height))
		
	local eeprom = component.proxy(component.list("eeprom")())

	local y = 2
	for address in component.list("filesystem") do
		local proxy = component.proxy(address)
		local isBoot = eeprom.getData() == proxy.address
		local isReadOnly = proxy.isReadOnly()

		local diskContainer = container:addChild(GUI.container(1, y, container.width, 4))
		
		local button = diskContainer:addChild(GUI.adaptiveRoundedButton(1, 3, 2, 0, 0x2D2D2D, 0xE1E1E1, 0x0, 0xE1E1E1, localization.options))
		button.onTouch = function()
			local container = system.addBackgroundContainer(workspace, localization.options)
			local inputField = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x666666, 0x666666, 0xE1E1E1, 0x2D2D2D, proxy.getLabel() or "", localization.diskLabel))
			inputField.onInputFinished = function()
				if inputField.text and inputField.text:len() > 0 then
					proxy.setLabel(inputField.text)

					container:remove()
					module.onTouch()
				end
			end
			
			local formatButton = container.layout:addChild(GUI.button(1, 1, 36, 3, 0xC3C3C3, 0x2D2D2D, 0x666666, 0xE1E1E1, localization.format))
			formatButton.onTouch = function()
				local list = proxy.list("/")
				for i = 1, #list do
					proxy.remove(list[i])
				end

				container:remove()
				module.onTouch()
			end
			formatButton.disabled = isReadOnly

			local switch = container.layout:addChild(GUI.switchAndLabel(1, 1, 36, 8, 0x66DB80, 0x1E1E1E, 0xE1E1E1, 0xBBBBBB, localization.bootable .. ":", isBoot)).switch
			switch.onStateChanged = function()
				if switch.state then
					eeprom.setData(proxy.address)

					container:remove()
					module.onTouch()
				end
			end

			workspace:draw()
		end
		button.localX = diskContainer.width - button.width - 1

		local width = diskContainer.width - button.width - 17
		local x = 13
		local spaceTotal = proxy.spaceTotal()
		local spaceUsed = proxy.spaceUsed()

		diskContainer:addChild(GUI.image(3, 1, isReadOnly and floppyImage or HDDImage))
		diskContainer:addChild(GUI.label(x, 1, width, 1, 0x2D2D2D, (proxy.getLabel() or "Unknown") .. " (" .. (isBoot and (localization.bootable .. ", ") or "") .. proxy.address .. ")"))
		diskContainer:addChild(GUI.progressBar(x, 3, width, 0x66DB80, 0xD2D2D2, 0xD2D2D2, spaceUsed / spaceTotal * 100, true))
		diskContainer:addChild(GUI.label(x, 4, width, 1, 0xBBBBBB, localization.free .. " " .. number.roundToDecimalPlaces((spaceTotal - spaceUsed) / 1024 / 1024, 2) .. " MB " .. localization.of .. " " .. number.roundToDecimalPlaces(spaceTotal / 1024 / 1024, 2) .. " MB")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)

		y = y + diskContainer.height + 1
	end

	container.eventHandler = function(workspace, object, e1, e2, e3, e4, e5)
		if e1 == "scroll" then
			if e5 < 0 or container.children[1].localY < 2 then
				for i = 1, #container.children do
					container.children[i].localY = container.children[i].localY + e5
				end

				workspace:draw()
			end
		elseif e1 == "component_added" or e1 == "component_removed" and e3 == "filesystem" then
			module.onTouch()
		end
	end
end

----------------------------------------------------------------------------------------------------------------

return module