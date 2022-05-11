
local
	stringsMineOSEFI,
	stringsChangeLabel,
	stringsKeyDown,
	stringsComponentAdded,
	stringsFilesystem,
	stringsURLBoot,
	
	componentProxy,
	componentList,
	pullSignal,
	uptime,
	tableInsert,
	mathMax,
	mathMin,
	mathHuge,
	mathFloor,

	colorsTitle,
	colorsBackground,
	colorsText,
	colorsSelectionBackground,
	colorsSelectionText =

	"MineOS EFI",
	"Change label",
	"key_down",
	"component_added",
	"filesystem",
	"URL boot",

	component.proxy,
	component.list,
	computer.pullSignal,
	computer.uptime,
	table.insert,
	math.max,
	math.min,
	math.huge,
	math.floor,

	0x2D2D2D,
	0xE1E1E1,
	0x878787,
	0x878787,
	0xE1E1E1

local
	eeprom,
	gpu,
	internetAddress =

	componentProxy(componentList("eeprom")()),
	componentProxy(componentList("gpu")()),
	componentList("internet")()

local
	gpuSet,
	gpuSetBackground,
	gpuSetForeground,
	gpuFill,
	eepromSetData,
	eepromGetData,
	screenWidth, 
	screenHeight =

	gpu.set,
	gpu.setBackground,
	gpu.setForeground,
	gpu.fill,
	eeprom.setData,
	eeprom.getData,
	gpu.getResolution()

local
	OSList,
	bindGPUToScreen,
	rectangle,
	centrizedText,
	menuElement,
	runLoop =

	{
		{
			"/OS.lua"
		},
		{
			"/init.lua",
			function()
				computer.getBootAddress, computer.setBootAddress = eepromGetData, eepromSetData
			end
		}
	},

	function()
		local screenAddress = componentList("screen")()
		
		if screenAddress then
			gpu.bind(screenAddress, true)
		end
	end,

	function(x, y, width, height, color)
		gpuSetBackground(color)
		gpuFill(x, y, width, height, " ")
	end,

	function(y, foreground, text)
		gpuSetForeground(foreground)
		gpuSet(mathFloor(screenWidth / 2 - #text / 2), y, text)
	end,

	function(text, callback, breakLoop)
		return {
			s = text,
			c = callback,
			b = breakLoop
		}
	end,

	function(func, ...)
		while func({ pullSignal(...) }) == nil do

		end
	end

local function drawTitle(y, title)
	y = mathFloor(screenHeight / 2 - y / 2)
	rectangle(1, 1, screenWidth, screenHeight, colorsBackground)
	centrizedText(y, colorsTitle, title)

	return y + 2
end

local function status(statusText, needWait)
	local lines = {}

	for line in statusText:gmatch("[^\r\n]+") do
		lines[#lines + 1] = line:gsub("\t", "  ")
	end
	
	local y = drawTitle(#lines, stringsMineOSEFI)
	
	for i = 1, #lines do
		centrizedText(y, colorsText, lines[i])
		y = y + 1
	end

	if needWait then
		while pullSignal() ~= stringsKeyDown do

		end
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

	status(reason, 1)
end

local
	boot,
	menuBack,
	menu,
	input,
	internetExecute =

	function(proxy)
		local OS

		for i = 1, #OSList do
			OS = OSList[i]

			if proxy.exists(OS[1]) then
				status("Booting from " .. (proxy.getLabel() or proxy.address))

				-- Updating current EEPROM boot address if it's differs from given proxy address
				if eepromGetData() ~= proxy.address then
					eepromSetData(proxy.address)
				end

				-- Running OS pre-boot function
				if OS[2] then
					OS[2]()
				end

				-- Reading boot file
				local handle, data, chunk, success, reason = proxy.open(OS[1], "rb"), ""

				repeat
					chunk = proxy.read(handle, mathHuge)
					data = data .. (chunk or "")
				until not chunk

				proxy.close(handle)

				-- Running boot file
				executeString(data, "=" .. OS[1])

				return 1
			end
		end
	end,

	function(f)
		return menuElement("Back", f, 1)
	end,
	
	function(title, elements)
		local selectedElement, maxLength = 1, 0

		for i = 1, #elements do
			maxLength = math.max(maxLength, #elements[i].s)
		end

		runLoop(function(e)
			local y, x = drawTitle(#elements + 2, title)
			
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

			if e[1] == stringsKeyDown then
				if e[4] == 200 and selectedElement > 1 then
					selectedElement = selectedElement - 1
				
				elseif e[4] == 208 and selectedElement < #elements then
					selectedElement = selectedElement + 1
				
				elseif e[4] == 28 then
					if elements[selectedElement].c then
						elements[selectedElement].c()
					end

					if elements[selectedElement].b then
						return 1
					end
				end

			elseif e[1] == stringsComponentAdded and e[3] == "screen" then
				bindGPUToScreen()
			end
		end)
	end,

	function(title, prefix)
		local
			y,
			text,
			state,
			eblo,
			char =

			drawTitle(2, title),
			"",
			true

		local function draw()
			eblo = prefix .. text

			gpuFill(1, y, screenWidth, 1, " ")
			gpuSetForeground(colorsText)
			gpuSet(mathFloor(screenWidth / 2 - #eblo / 2), y, eblo .. (state and "█" or ""))
		end

		draw()

		runLoop(
			function(e)
				if e[1] == stringsKeyDown then
					if e[4] == 28 then
						return 1

					elseif e[4] == 14 then
						text = text:sub(1, -2)
					
					else
						char = unicode.char(e[3])

						if char:match("^[%w%d%p%s]+") then
							text = text .. char
						end
					end

					state = true
				
				elseif e[1] == "clipboard" then
					text = text .. e[3]
				
				elseif not e[1] then
					state = not state
				end

				draw()
			end,
			0.5
		)
	end,

	function(url)
		local
			connection,
			data,
			result,
			reason =

			componentProxy(internetAddress).request(url),
			""

		if connection then
			status("Downloading script")

			while 1 do
				result, reason = connection.read(mathHuge)	
				
				if result then
					data = data .. result
				else
					connection.close()
					
					if reason then
						status(reason, 1)
					else
						executeString(data, "=url")
					end

					break
				end
			end
		else
			status("Invalid URL", 1)
		end
	end


bindGPUToScreen()
status("Hold Alt to show boot options")

-- Waiting 1 sec for user to press Alt key
local deadline, e = uptime() + 1

while uptime() < deadline do
	e = { pullSignal(deadline - uptime()) }

	if e[1] == stringsKeyDown and e[4] == 56 then
		local utilities = {
			menuElement("Disk utility", function()
				local restrict, filesystems, filesystemOptions =
					function(text, limit)
						return (#text < limit and text .. string.rep(" ", limit - #text) or text:sub(1, limit)) .. "   "
					end,
					{ menuBack() }

				local function updateFilesystems()
					for i = 2, #filesystems do
						table.remove(filesystems, 1)
					end

					for address in componentList(stringsFilesystem) do
						local proxy = componentProxy(address)

						local
							label,
							isReadOnly,
							filesystemOptions =

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
								proxy.setLabel(input(stringsChangeLabel, "New value: "))
								updateFilesystems()
							end, 1))

							tableInsert(filesystemOptions, menuElement("Erase", function()
								status("Erasing " .. address)
								proxy.remove("")
								updateFilesystems()
							end, 1))
						end

						tableInsert(filesystemOptions, menuBack())

						tableInsert(filesystems, 1,
							menuElement(
								(address == eepromGetData() and "> " or "  ") ..
								restrict(label, 10) ..
								restrict(proxy.spaceTotal() > 1048575 and "HDD" or proxy.spaceTotal() > 65535 and "FDD" or "SYS", 3) ..
								restrict(isReadOnly and "R  " or "R/W", 3) ..
								restrict(math.ceil(proxy.spaceUsed() / proxy.spaceTotal() * 100) .. "%", 4) ..
								address:sub(1, 8) .. "…",
								
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

			menuBack()
		}

		if internetAddress then	
			tableInsert(utilities, 2, menuElement("System recovery", function()
				internetExecute("https://tinyurl.com/29urhz7z")
			end))
			
			tableInsert(utilities, 3, menuElement(stringsURLBoot, function()
				internetExecute(input(stringsURLBoot, "Address: "))
			end))
		end

		menu(stringsMineOSEFI, utilities)
	end
end

-- Trying to boot from previously selected fs or from any available
local bootProxy = componentProxy(eepromGetData())

if not (bootProxy and boot(bootProxy)) then
	local function tryBootFromAny()
		for address in componentList(stringsFilesystem) do
			bootProxy = componentProxy(address)

			if boot(bootProxy) then
				computer.shutdown()
			else
				bootProxy = nil
			end
		end

		if not bootProxy then
			status("Not boot sources found")
		end
	end

	tryBootFromAny()

	runLoop(function(e)
		if e[1] == stringsComponentAdded then
			tryBootFromAny()
		end
	end)
end
