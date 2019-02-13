
local stringsMain, stringsChangeLabel, stringKeyDown, stringsFilesystem, colorsTitle, colorsBackground, colorsText, colorsSelectionBackground, colorsSelectionText, componentProxy, componentList, pullSignal, uptime, tableInsert, mathMax, mathMin, mathHuge, mathFloor = "MineOS EFI", "Change label", "key_down", "filesystem", 0x2D2D2D, 0xE1E1E1, 0x878787, 0x878787, 0xE1E1E1, component.proxy, component.list, computer.pullSignal, computer.uptime, table.insert, math.max, math.min, math.huge, math.floor

local eeprom, gpu, internetAddress = componentProxy(componentList("eeprom")()), componentProxy(componentList("gpu")()), componentList("internet")()

gpu.bind(componentList("screen")(), true)

local shutdown, gpuSet, gpuSetBackground, gpuSetForeground, gpuFill, eepromSetData, eepromGetData, screenWidth, screenHeight = computer.shutdown, gpu.set, gpu.setBackground, gpu.setForeground, gpu.fill, eeprom.setData, eeprom.getData, gpu.getResolution()

local OSList, rectangle, centrizedText, menuElement =
	{
		{
			"/OS.lua",
			function()
			end
		},
		{
			"/init.lua",
			function()
				computer.getBootAddress, computer.setBootAddress = eepromGetData, eepromSetData
			end
		}
	},
	function(x, y, width, height, color)
		gpuSetBackground(color)
		gpuFill(x, y, width, height, " ")
	end,
	function(y, foreground, text)
		local x = mathFloor(screenWidth / 2 - #text / 2)
		gpuSetForeground(foreground)
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

	status(stringsMain, reason, 1)
end

local boot, menuBack, menu, input =
	function(proxy)
		for i = 1, #OSList do
			if proxy.exists(OSList[i][1]) then
				status(stringsMain, "Booting from " .. (proxy.getLabel() or proxy.address))

				-- Updating current EEPROM boot address if it's differs from given proxy address
				if eepromGetData() ~= proxy.address then
					eepromSetData(proxy.address)
				end

				-- Running OS pre-boot function
				OSList[i][2]()

				-- Reading boot file
				local handle, data, chunk, success, reason = proxy.open(OSList[i][1], "rb"), ""
				repeat
					chunk = proxy.read(handle, mathHuge)
					data = data .. (chunk or "")
				until not chunk

				proxy.close(handle)

				-- Running boot file
				executeString(data, "=" .. OSList[i][1])

				return 1
			end
		end
	end,
	function(f)
		return menuElement("Back", f, 1)
	end,
	function(titleText, elements)
		local selectedElement, maxLength = 1, 0
		for i = 1, #elements do
			maxLength = math.max(maxLength, #elements[i].s)
		end

		while 1 do
			local y, x, eventData = title(#elements + 2, titleText)
			
			for i = 1, #elements do
				x = mathFloor(screenWidth / 2 - #elements[i].s / 2)
				
				if i == selectedElement then
					rectangle(mathFloor(screenWidth / 2 - maxLength / 2) - 2, y, maxLength + 4, 1, colorsSelectionBackground)
					gpuSetForeground(colorsSelectionText)
					gpuSet(x, y, elements[i].s)
					gpuSetBackground(colorsBackground)
				else
					gpuSetForeground(colorsText)
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
			gpuSetForeground(colorsText)
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

status(stringsMain, "Hold Alt to show boot options")

local deadline, eventData = uptime() + 1
while uptime() < deadline do
	eventData = {pullSignal(deadline - uptime())}
	if eventData[1] == stringKeyDown and eventData[4] == 56 then
		local utilities = {
			menuElement("Disk management", function()
				local restrict, filesystems, filesystemOptions =
					function(text, limit)
						if #text < limit then
							text = text .. string.rep(" ", limit - #text)
						else
							text = text:sub(1, limit)
						end

						return text .. "  "
					end,
					{menuBack()}

				local function updateFilesystems()
					for i = 2, #filesystems do
						table.remove(filesystems, 1)
					end

					for address in componentList(stringsFilesystem) do
						local proxy = componentProxy(address)
						local label, isReadOnly, filesystemOptions =
							proxy.getLabel() or "Unnamed",
							proxy.isReadOnly(),
							{
								menuElement("Set as bootable", function()
									eepromSetData(address)
									updateFilesystems()
								end, 1)
							}

						if not isReadOnly then
							tableInsert(filesystemOptions, menuElement(stringsChangeLabel, function()
								proxy.setLabel(input(title(2, stringsChangeLabel), "Enter new name: "))
								updateFilesystems()
							end, 1))

							tableInsert(filesystemOptions, menuElement("Format", function()
								status(stringsMain, "Formatting filesystem " .. address)
								
								for _, file in ipairs(proxy.list("/")) do
									proxy.remove(file)
								end

								updateFilesystems()
							end, 1))
						end

						tableInsert(filesystemOptions, menuBack())

						tableInsert(filesystems, 1,
							menuElement(
								(address == eepromGetData() and "> " or "  ") ..
								restrict(label, 12) ..
								restrict(proxy.spaceTotal() > 1048576 and "HDD" or proxy.spaceTotal() > 65536 and "FDD" or "SYS", 3) ..
								restrict(isReadOnly and "R" or "R/W", 3) ..
								restrict(string.format("%.1f", proxy.spaceUsed() / proxy.spaceTotal() * 100) .. "%", 6) ..
								address:sub(1, 7) .. "…",
								function()
									menu(label .. " (" .. address .. ")", filesystemOptions)
								end
							)
						)
					end
				end

				updateFilesystems()
				menu("Select filesystem", filesystems)
			end),
			
			menuElement("Shutdown", function()
				shutdown()
			end),

			menuBack()
		}

		if internetAddress then	
			tableInsert(utilities, 2, menuElement("Internet recovery", function()
				local handle, data, result, reason = componentProxy(internetAddress).request("https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/Main.lua"), ""

				if handle then
					status(stringsMain, "Downloading recovery script")

					while 1 do
						result, reason = handle.read(mathHuge)	
						
						if result then
							data = data .. result
						else
							handle.close()
							
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
if not (proxy and boot(proxy)) then
	for address in componentList(stringsFilesystem) do
		proxy = componentProxy(address)

		if boot(proxy) then
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
