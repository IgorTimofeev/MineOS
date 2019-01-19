
local stringsMain, stringsInit, stringsChangeLabel, stringKeyDown, stringsFilesystem, colorsTitle, colorsBackground, colorsText, colorsSelectionBackground, colorsSelectionText, componentProxy, componentList, pullSignal, uptime, tableInsert, mathMax, mathMin, mathHuge, mathFloor = "MineOS EFI", "/OS.lua", "Change label", "key_down", "filesystem", 0x2D2D2D, 0xE1E1E1, 0x878787, 0x878787, 0xE1E1E1, component.proxy, component.list, computer.pullSignal, computer.uptime, table.insert, math.max, math.min, math.huge, math.floor

local eeprom, gpu, internetAddress = componentProxy(componentList("eeprom")()), componentProxy(componentList("gpu")()), componentList("internet")()

local shutdown, gpuSet, gpuFill, eepromSetData, eepromGetData, screenWidth, screenHeight, curentBackground, currentForeground = computer.shutdown, gpu.set, gpu.fill, eeprom.setData, eeprom.getData, gpu.getResolution()

local resetColors, setBackground, setForeground, restrict = 
	function()
		curentBackground, currentForeground = nil, nil
	end,
	function(color)
		if color ~= curentBackground then
			gpu.setBackground(color)
			curentBackground = color
		end
	end,
	function(color)
		if color ~= currentForeground then
			gpu.setForeground(color)
			currentForeground = color
		end
	end,
	function(text, limit, skip)
		if #text < limit then
			text = text .. string.rep(" ", limit - #text)
		else
			text = text:sub(1, limit)
		end

		return text .. (skip and "" or "  ")
	end

local rectangle, centrizedText, menuElement =
	function(x, y, width, height, color)
		setBackground(color)
		gpuFill(x, y, width, height, " ")
	end,
	function(y, foreground, text)
		local x = mathFloor(screenWidth / 2 - #text / 2)
		setForeground(foreground)
		gpuSet(x, y, text)
	end,
	function(text, callback, breakLoop)
		return {
			s = text,
			c = callback,
			b = breakLoop
		}
	end

local function title(y, titleText)
	y = mathFloor(screenHeight / 2 - y / 2)
	rectangle(1, 1, screenWidth, screenHeight, colorsBackground)
	centrizedText(y, colorsTitle, titleText)

	return y + 2
end

local function status(titleText, statusText, needWait)
	local lines = {}
	for line in statusText:gmatch("[^\r\n]+") do
		lines[#lines + 1] = line:gsub("\t", "  ")
	end
	
	local y = title(#lines, titleText)
	
	for i = 1, #lines do
		centrizedText(y, colorsText, lines[i])
		y = y + 1
	end

	if needWait then
		repeat
			needWait = pullSignal()
		until needWait == stringKeyDown or needWait == "touch"
	end
end

local function executeString(...)
	local result, reason = load(...)
	if result then
		result, reason = xpcall(result, debug.traceback)
		if result then
			return
		end
	end

	resetColors()
	status(stringsMain, reason, 1)
end

local loadInit, menuBack, menu, input =
	function(proxy)
		status(stringsMain, "Booting from " .. proxy.address)

		local handle, data, chunk, success, reason = proxy.open(stringsInit, "rb"), "", ""
		repeat
			chunk = proxy.read(handle, mathHuge)
			data = data .. (chunk or "")
		until not chunk

		proxy.close(handle)

		executeString(data, "=" .. stringsInit)
	end,
	function()
		return menuElement("Back", nil, 1)
	end,
	function(titleText, elements)
		local spacing, selectedElement, maxLength = 2, 1, 0
		for i = 1, #elements do
			maxLength = math.max(maxLength, #elements[i].s)
		end

		while 1 do
			local y, x, eventData = title(#elements + 2, titleText)
			
			for i = 1, #elements do
				x = mathFloor(screenWidth / 2 - #elements[i].s / 2)
				
				if i == selectedElement then
					rectangle(mathFloor(screenWidth / 2 - maxLength / 2) - 2, y, maxLength + 4, 1, colorsSelectionBackground)
					setForeground(colorsSelectionText)
					gpuSet(x, y, elements[i].s)
				else
					setBackground(colorsBackground)
					setForeground(colorsText)
					gpuSet(x, y, elements[i].s)
				end
				
				y = y + 1
			end

			eventData = {pullSignal()}
			if eventData[1] == stringKeyDown then
				if eventData[4] == 200 and selectedElement > 1 then
					selectedElement = selectedElement - 1
				elseif eventData[4] == 208 and selectedElement < #elements then
					selectedElement = selectedElement + 1
				elseif eventData[4] == 28 then
					if elements[selectedElement].c then
						elements[selectedElement].c()
					end

					if elements[selectedElement].b then
						return
					end
				end
			end
		end
	end,
	function(y, prefix)
		local text, state, eblo, eventData, char = "", true
		while 1 do
			eblo = prefix .. text
			gpuFill(1, y, screenWidth, 1, " ")
			setForeground(colorsText)
			gpuSet(mathFloor(screenWidth / 2 - #eblo / 2), y, eblo .. (state and "█" or ""))

			eventData = {pullSignal(0.5)}
			if eventData[1] == stringKeyDown then
				if eventData[4] == 28 then
					return text
				elseif eventData[4] == 14 then
					text = text:sub(1, -2)
				else
					char = unicode.char(eventData[3])
					if char:match("^[%w%d%p%s]+") then
						text = text .. char
					end
				end

				state = true
			elseif eventData[1] == "clipboard" then
				text = text .. eventData[3]
			elseif not eventData[1] then
				state = not state
			end
		end
	end

gpu.bind(componentList("screen")(), true)
status(stringsMain, "Hold Alt to show boot options menu")

local deadline, eventData = uptime() + 1
while uptime() < deadline do
	eventData = {pullSignal(deadline - uptime())}
	if eventData[1] == stringKeyDown and eventData[4] == 56 then
		local utilities = {
			menuElement("Disk management", function()
				local filesystems, bootAddress = {menuBack()}, eepromGetData()
				
				for address in componentList(stringsFilesystem) do
					local proxy = componentProxy(address)
					local label, isReadOnly = proxy.getLabel() or "Unnamed", proxy.isReadOnly()
					
					tableInsert(filesystems, 1,
						menuElement(
							(address == bootAddress and "> " or "  ") ..
							restrict(label, 10) ..
							restrict(proxy.spaceTotal() > 1048576 and "HDD" or proxy.spaceTotal() > 65536 and "FDD" or "SYS", 3) ..
							restrict(isReadOnly and "R" or "R/W", 3) ..
							address:sub(1, 8) .. "  " ..
							restrict(string.format("%.2f", proxy.spaceUsed() / proxy.spaceTotal() * 100) .. "%", 6, 1),

							function()
								local filesystemOptions = {menuBack()}

								if not isReadOnly then
									tableInsert(filesystemOptions, 1, menuElement(stringsChangeLabel, function()
										proxy.setLabel(input(title(2, stringsChangeLabel), "Enter new name: "))
									end, 1))

									tableInsert(filesystemOptions, 2, menuElement("Format", function()
										status(stringsMain, "Formatting filesystem " .. address)
										for _, file in ipairs(proxy.list("/")) do
											proxy.remove(file)
										end
										status(stringsMain, "Formatting finished", 1)
									end, 1))
								end

								tableInsert(filesystemOptions, 1, menuElement("Set as startup", function()
									eepromSetData(address)
								end, 1))

								menu(label .. " (" .. address .. ")", filesystemOptions)
							end
						, 1)
					)
				end

				menu("Select filesystem", filesystems)
			end),
			
			menuElement("Shutdown", function()
				shutdown()
			end),

			menuBack()
		}

		if internetAddress then	
			tableInsert(utilities, 2, menuElement("Internet recovery", function()
				local handle, data, result, reason = componentProxy(internetAddress).request("https://raw.githubusercontent.com/IgorTimofeev/MineOSStandalone/master/Installer/Main.lua"), ""

				if handle then
					status(stringsMain, "Downloading recovery script")

					while 1 do
						result, reason = handle.read(mathHuge)	
						
						if result then
							data = data .. result
						else
							handle:close()
							
							if reason then
								status(stringsMain, reason, 1)
							else
								executeString(data, "=string")
							end

							break
						end
					end
				else
					status(stringsMain, "invalid URL-address", 1)
				end
			end))
		end

		menu(stringsMain, utilities)
	end
end

local proxy = componentProxy(eepromGetData())
if proxy and proxy.exists(stringsInit) then
	loadInit(proxy)
else
	for address in componentList(stringsFilesystem) do
		proxy = componentProxy(address)
		if proxy.exists(stringsInit) then
			eepromSetData(address)
			loadInit(proxy)
			break
		else
			proxy = nil
		end
	end

	if not proxy then
		status(stringsMain, "No bootable mediums found", 1)
	end
end

shutdown()
