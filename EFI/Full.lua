

-- local component, computer, unicode = require("component"), require("computer"), require("unicode")

local stringsMain, stringsBootFromURL, stringsChangeLabel, stringKeyDown, stringsInit, stringsFilesystem, componentProxy, componentList, pullSignal, uptime, tableInsert, mathMax, mathMin, mathHuge = "MineOS EFI", "Internet boot", "Change label", "key_down", "/init.lua", "filesystem", component.proxy, component.list, computer.pullSignal, computer.uptime, table.insert, math.max, math.min, math.huge
local colorsTitle, colorsBackground, colorsText, colorsSelectionBackground, colorsSelectionText, eeprom, gpu, internetAddress = 1, 0, 1, 1, 0, componentProxy(componentList("eeprom")()), componentProxy(componentList("gpu")()), componentList("internet")()

gpu.bind(componentList("screen")(), true)

local shutdown, gpuSet, gpuFill, eepromSetData, eepromGetData, depth, screenWidth, screenHeight, curentBackground, currentForeground, NIL = computer.shutdown, gpu.set, gpu.fill, eeprom.setData, eeprom.getData, gpu.getDepth(), gpu.getResolution()
computer.getBootAddress, computer.setBootAddress = eepromGetData, eepromSetData

if depth == 4 then
	colorsTitle, colorsBackground, colorsText, colorsSelectionBackground, colorsSelectionText = 0x333333, 0xFFFFFF, 0x333333, 0x333333, 0xFFFFFF
elseif depth == 8 then
	colorsTitle, colorsBackground, colorsText, colorsSelectionBackground, colorsSelectionText = 0x2D2D2D, 0xE1E1E1, 0x878787, 0x878787, 0xE1E1E1
end

local setBackground, setForeground, round, restrict = 
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
	function(n)
		return math.floor(n + 0.5)
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
		local x = round(screenWidth / 2 - #text / 2)
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

local function status(y, titleText, statusText, needWait)
	y = y or round(screenHeight / 2 - 1)

	rectangle(1, 1, screenWidth, screenHeight, colorsBackground)
	centrizedText(y, colorsTitle, titleText)
	centrizedText(y + 2, colorsText, statusText or "")
	if needWait then
		repeat
			local event = pullSignal()
		until event == stringKeyDown or event == "touch"
	end

	return y
end

local loadInit, menuBack, menu, input, netboot =
	function(proxy)
		status(NIL, stringsMain, "Booting from " .. proxy.address)

		local data, chunk, handle, success, reason = "", "", proxy.open(stringsInit, "r")
		while chunk do
			data, chunk = data .. chunk, proxy.read(handle, mathHuge)
		end
		proxy.close(handle)

		success, reason = load(data)
		if success then
			success, reason = pcall(success)
			if success then
				return
			end
		end

		status(NIL, stringsMain, "Failed to run init file: " .. reason, 1)
	end,
	function()
		return menuElement("Back", NIL, 1)
	end,
	function(titleText, elements)
		local spacing, selectedElement, maxLength = 2, 1, 0
		for i = 1, #elements do
			maxLength = math.max(maxLength, #elements[i].s)
		end

		while 1 do
			local y, x, eventData = status(round(screenHeight / 2 - (#elements + 2) / 2), titleText) + 2
			
			for i = 1, #elements do
				x = round(screenWidth / 2 - #elements[i].s / 2)
				
				if i == selectedElement then
					rectangle(round(screenWidth / 2 - maxLength / 2) - 2, y, maxLength + 4, 1, colorsSelectionBackground)
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
			gpuSet(round(screenWidth / 2 - #eblo / 2), y, eblo .. (state and "█" or ""))

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
	end,
	function(url)	
		local runReason, data, handle, result, reason =
			function(text)
				status(NIL, stringsBootFromURL, "Internet boot failed: " .. text, 1)
			end,
			"",
			componentProxy(internetAddress).request(url)
		
		if handle then
			status(NIL, stringsBootFromURL, "Downloading script...")	
			while 1 do
				result, reason = handle.read(mathHuge)	
				if result then
					data = data .. result
				else
					handle:close()
					
					if reason then
						runReason(reason)
					else
						result, reason = load(data)
						if result then
							eepromSetData("#" .. url)
							result, reason = pcall(result)
							if result then
								return
							else
								runReason(reason)
							end
						else
							runReason(reason)
						end
					end

					break
				end
			end
		else
			runReason("invalid URL-address")
		end
	end

status(NIL, stringsMain, "Hold Alt to show boot options menu")

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
										proxy.setLabel(input(status(NIL, stringsChangeLabel) + 2, "Enter new name: "))
									end, 1))

									tableInsert(filesystemOptions, 2, menuElement("Format", function()
										status(NIL, stringsMain, "Formatting filesystem " .. address)
										for _, file in ipairs(proxy.list("/")) do
											proxy.remove(file)
										end
										status(NIL, stringsMain, "Formatting finished", 1)
									end, 1))
								end

								if proxy.exists(stringsInit) then
									tableInsert(filesystemOptions, 1, menuElement("Set as startup", function()
										eepromSetData(address)
									end, 1))
								end

								menu(label .. " (" .. address .. ")", filesystemOptions)
							end
						, 1)
					)
				end

				menu("Select filesystem to show options", filesystems)
			end),
			
			menuElement("Shutdown", function()
				shutdown()
			end),

			menuBack()
		}

		if internetAddress then	
			tableInsert(utilities, 2, menuElement(stringsBootFromURL, function()
				netboot(input(status(NIL, stringsBootFromURL) + 2, "Enter URL: "))
			end))
		end

		menu(stringsMain, utilities)
	end
end

local data, proxy = eepromGetData()
if data:sub(1, 1) == "#" then
	netboot(data:sub(2, -1))
else
	proxy = componentProxy(data)
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
			status(NIL, stringsMain, "No bootable mediums found", 1)
		end
	end
end

shutdown()



















