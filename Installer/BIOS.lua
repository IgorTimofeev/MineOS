local debugMode = true
local
	stringsLunaEFI,
	stringsLunaInfo,
	stringsChangeLabel,
	stringsKeyDown,
	stringsComponentAdded,
	stringsFilesystem,
	stringsURLBoot,
	stringsInstallOS,
	
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
	colorsSelectionText,

	OSList,
	bindGPUToScreen,
	drawRectangle,
	drawText,
	newMenuElement,
	drawCentrizedText,
	drawTitle,
	status,
	executeString,
	boot,
	newMenuBackElement,
	menu,
	input,
	internetExecute =

	"LunaEFI",
	"https://github.com/AFellowSpeedrunner/LunaEFI",
	"Change filesystem name",
	"key_down",
	"component_added",
	"filesystem",
	"Netboot from URL",
	"Install an OS",

	component.proxy,
	component.list,
	computer.pullSignal,
	computer.uptime,
	table.insert,
	math.max,
	math.min,
	math.huge,
	math.floor,

  -- Colours/colors for text, selector and background

  	0xFFB6C1, -- This is the title text
	0x1E1E1E, -- This is the background
	0x878787, -- This is the the text for menus and boot options key
	0x878787, -- This is the selector bar
	0xE1E1E1  -- This is highlighted text

local text = load("\rlocal text = {}\r\r--------------------------------------------------------------------------------\r\rfunction text.serialize(t, prettyLook, indentator, recursionStackLimit)\r\tcheckArg(1, t, \"table\")\r\r\trecursionStackLimit = recursionStackLimit or math.huge\r\tindentator = indentator or \"  \"\r\t\r\tlocal equalsSymbol = prettyLook and \" = \" or \"=\"\r\r\tlocal function serialize(t, currentIndentationSymbol, currentRecusrionStack)\r\t\tlocal result, nextIndentationSymbol, keyType, valueType, stringValue = {\"{\"}, currentIndentationSymbol .. indentator\r\t\t\r\t\tif prettyLook then\r\t\t\ttable.insert(result, \"\\n\")\r\t\tend\r\t\t\r\t\tfor key, value in pairs(t) do\r\t\t\tkeyType, valueType, stringValue = type(key), type(value), tostring(value)\r\r\t\t\tif prettyLook then\r\t\t\t\ttable.insert(result, nextIndentationSymbol)\r\t\t\tend\r\t\t\t\r\t\t\tif keyType == \"number\" then\r\t\t\t\ttable.insert(result, \"[\")\r\t\t\t\ttable.insert(result, key)\r\t\t\t\ttable.insert(result, \"]\")\r\t\t\t\ttable.insert(result, equalsSymbol)\r\t\t\telseif keyType == \"string\" then\r\t\t\t\tif prettyLook and key:match(\"^%a\") and key:match(\"^[%w%_]+$\") then\r\t\t\t\t\ttable.insert(result, key)\r\t\t\t\telse\r\t\t\t\t\ttable.insert(result, \"[\\\"\")\r\t\t\t\t\ttable.insert(result, key)\r\t\t\t\t\ttable.insert(result, \"\\\"]\")\r\t\t\t\tend\r\r\t\t\t\ttable.insert(result, equalsSymbol)\r\t\t\tend\r\r\t\t\tif valueType == \"number\" or valueType == \"boolean\" or valueType == \"nil\" then\r\t\t\t\ttable.insert(result, stringValue)\r\t\t\telseif valueType == \"string\" or valueType == \"function\" then\r\t\t\t\ttable.insert(result, \"\\\"\")\r\t\t\t\ttable.insert(result, stringValue)\r\t\t\t\ttable.insert(result, \"\\\"\")\r\t\t\telseif valueType == \"table\" then\r\t\t\t\tif currentRecusrionStack < recursionStackLimit then\r\t\t\t\t\ttable.insert(\r\t\t\t\t\t\tresult,\r\t\t\t\t\t\ttable.concat(\r\t\t\t\t\t\t\tserialize(\r\t\t\t\t\t\t\t\tvalue,\r\t\t\t\t\t\t\t\tnextIndentationSymbol,\r\t\t\t\t\t\t\t\tcurrentRecusrionStack + 1\r\t\t\t\t\t\t\t)\r\t\t\t\t\t\t)\r\t\t\t\t\t)\r\t\t\t\telse\r\t\t\t\t\ttable.insert(result, \"\\\"…\\\"\")\r\t\t\t\tend\r\t\t\tend\r\t\t\t\r\t\t\ttable.insert(result, \",\")\r\r\t\t\tif prettyLook then\r\t\t\t\ttable.insert(result, \"\\n\")\r\t\t\tend\r\t\tend\r\r\t\tif prettyLook then\r\t\t\tif #result > 2 then\r\t\t\t\ttable.remove(result, #result - 1)\r\t\t\tend\r\r\t\t\ttable.insert(result, currentIndentationSymbol)\r\t\telse\r\t\t\tif #result > 1 then\r\t\t\t\ttable.remove(result, #result)\r\t\t\tend\r\t\tend\r\r\t\ttable.insert(result, \"}\")\r\r\t\treturn result\r\tend\r\t\r\treturn table.concat(serialize(t, \"\", 1))\rend\r\rfunction text.deserialize(s)\r\tcheckArg(1, s, \"string\")\r\t\r\tlocal result, reason = load(\"return \" .. s)\r\tif result then\r\t\tresult, reason = pcall(result)\r\t\t\r\t\tif result then\r\t\t\treturn reason\r\t\telse\r\t\t\treturn nil, reason\r\t\tend\r\telse\r\t\treturn nil, reason\r\tend\rend\r\rfunction text.split(s, delimiter)\r\tlocal parts, index = {}, 1\r\tfor part in s:gmatch(delimiter) do\r\t\tparts[index] = part\r\t\tindex = index + 1\r\tend\r\r\treturn parts\rend\r\rfunction text.brailleChar(a, b, c, d, e, f, g, h)\r\treturn unicode.char(10240 + 128 * h + 64 * g + 32 * f + 16 * d + 8 * b + 4 * e + 2 * c + a)\rend\r\rfunction text.unicodeFind(s, pattern, init, plain)\r\tif init then\r\t\tif init < 0 then\r\t\t\tinit = -#unicode.sub(s, init)\r\t\telseif init > 0 then\r\t\t\tinit = #unicode.sub(s, 1, init - 1) + 1\r\t\tend\r\tend\r\t\r\ta, b = s:find(pattern, init, plain)\r\t\r\tif a then\r\t\tlocal ap, bp = s:sub(1, a - 1), s:sub(a,b)\r\t\ta = unicode.len(ap) + 1\r\t\tb = a + unicode.len(bp) - 1\r\r\t\treturn a, b\r\telse\r\t\treturn a\r\tend\rend\r\rfunction text.limit(s, limit, mode, noDots)\r\tlocal length = unicode.len(s)\r\t\r\tif length <= limit then\r\t\treturn s\r\telseif mode == \"left\" then\r\t\tif noDots then\r\t\t\treturn unicode.sub(s, length - limit + 1, -1)\r\t\telse\r\t\t\treturn \"…\" .. unicode.sub(s, length - limit + 2, -1)\r\t\tend\r\telseif mode == \"center\" then\r\t\tlocal integer, fractional = math.modf(limit / 2)\r\t\tif fractional == 0 then\r\t\t\treturn unicode.sub(s, 1, integer) .. \"…\" .. unicode.sub(s, -integer + 1, -1)\r\t\telse\r\t\t\treturn unicode.sub(s, 1, integer) .. \"…\" .. unicode.sub(s, -integer, -1)\r\t\tend\r\telse\r\t\tif noDots then\r\t\t\treturn unicode.sub(s, 1, limit)\r\t\telse\r\t\t\treturn unicode.sub(s, 1, limit - 1) .. \"…\"\r\t\tend\r\tend\rend\r\rfunction text.wrap(data, limit)\r\tif type(data) == \"string\" then\r\t\tdata = { data }\r\tend\r\r\tlocal wrappedLines, result, preResult, position = {}\r\r\tfor i = 1, #data do\r\t\twrappedLines[i] = data[i]\r\tend\r\r\tlocal i = 1\r\twhile i <= #wrappedLines do\r\t\tlocal position = wrappedLines[i]:find(\"\\n\")\r\t\tif position then\r\t\t\ttable.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], position + 1, -1))\r\t\t\twrappedLines[i] = unicode.sub(wrappedLines[i], 1, position - 1)\r\t\tend\r\r\t\ti = i + 1\r\tend\r\r\tlocal i = 1\r\twhile i <= #wrappedLines do\r\t\tresult = \"\"\r\r\t\tfor word in wrappedLines[i]:gmatch(\"[^%s]+\") do\r\t\t\tpreResult = result .. word\r\r\t\t\tif unicode.len(preResult) > limit then\r\t\t\t\tif unicode.len(word) > limit then\r\t\t\t\t\ttable.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], limit + 1, -1))\r\t\t\t\t\tresult = unicode.sub(wrappedLines[i], 1, limit)\r\t\t\t\telse\r\t\t\t\t\ttable.insert(wrappedLines, i + 1, unicode.sub(wrappedLines[i], unicode.len(result) + 1, -1))\t\r\t\t\t\tend\r\r\t\t\t\tbreak\t\r\t\t\telse\r\t\t\t\tresult = preResult .. \" \"\r\t\t\tend\r\t\tend\r\r\t\twrappedLines[i] = result:gsub(\"%s+$\", \"\"):gsub(\"^%s+\", \"\")\r\r\t\ti = i + 1\r\tend\r\r\treturn wrappedLines\rend\r\rreturn text")()

local
	eeprom,
	gpu,
	internetAddress =

	componentProxy(componentList("eeprom")()),
	componentProxy(componentList("gpu")()),
	componentList("internet")()

local locale = {
	LunaEFIName = stringsLunaEFI,
	LunaInfo = stringsLunaInfo,
	changeLabel = stringsChangeLabel,
	keyDown = stringsKeyDown,
	componentAdded = stringsComponentAdded,
	filesystem = stringsFilesystem,
	URLBoot = stringsURLBoot,
	installOS = "Install an Operating System",
	pressAltForOptions = "Press ALT key for EFI options within 3 seconds",
	internetRequired = "Internet access is required for this feature",
	questionInstallOS = "Install <osname>?",
}

locale["common"] = {
	back = "Back",
	yes = "Yes",
	no = "No",
	cancel = "Cancel",
	next = "Next",
	prev = "Previous",
	nextPG = "Next page",
	prevPG = "Previous page",
	close = "Close",
	ok = "OK",
	install = "Install",
}


local
	gpuSet,
	gpuSetBackground,
	gpuFill,
	eepromSetData,
	eepromGetData,
	screenWidth, 
	screenHeight =

	gpu.set,
	gpu.setBackground,
	gpu.fill,
	eeprom.setData,
	eeprom.getData

local
	checkValidData,
	setMainBootAddress,
	getMainBootAddress,
	getSettings,
	saveSettings
	-- saveSettings,
	-- loadData
	= function()
		local currentData = text.deserialize(eepromGetData())
		if not pcall(text.deserialize(eepromGetData())) then
			eepromSetData("{[\"bootAddress\"]=\"\",[\"settings\"]={},[\"data\"]={},}")
			currentData = text.deserialize(eepromGetData())
		end
	end,
	function(proxyAddress)
		local currentData = text.deserialize(eepromGetData())
		currentData.bootAddress = proxyAddress
		eepromSetData(text.serialize(currentData))
	end,
	function()
		local currentData = text.deserialize(eepromGetData())
		--status(text.serialize(currentData), true)
		local address = currentData.bootAddress
		return address
	end,
	function()
		local currentData = text.deserialize(eepromGetData())
		--status(text.serialize(currentData), true)
		local settings = currentData.settings
		return settings
	end,
	function(tbl)
		if not type(tbl) == "table" then error("bad argument #1, expected table (got " .. type(tbl) .. ")", 2) end
		local currentData = text.deserialize(eepromGetData())
		--status(text.serialize(currentData), true)
		currentData.settings = tbl
		eepromSetData(text.serialize(currentData))
	end

OSList,
bindGPUToScreen,
drawRectangle,
drawText,
newMenuElement,
drawCentrizedText,
drawTitle,
status,
executeString,
boot,
newMenuBackElement,
menu,
input,
internetExecute,
installFromWebScript =

{	
	{
		"/sys/boot/init.lua"
	},
	{
		"/OS.lua"
	},
	{
		"/boot/kernel/pipes", -- add support for Plan9k OS
		function()
			status("Booting into Plan9k OS")
			computer.getBootAddress, computer.setBootAddress = getMainBootAddress, setMainBootAddress
		end
	},
	{
		"/init.lua",
		function()
			computer.getBootAddress, computer.setBootAddress = getMainBootAddress, setMainBootAddress
		end
	}
},

function()
	local screenAddress = componentList("screen")()
	
	if screenAddress then
		gpu.bind(screenAddress, true)
		screenWidth, screenHeight = gpu.getResolution()
	else
		error("Attach a screen to boot properly. The EFI won't boot without it.", 0)
	end
end,

function(x, y, width, height, color)
	gpuSetBackground(color)
	gpuFill(x, y, width, height, " ")
end,

function(x, y, foreground, text)
	gpu.setForeground(foreground)
	gpuSet(x, y, text)
end,

function(text, callback, breakLoop)
	return {
		s = text,
		c = callback,
		b = breakLoop
	}
end,

function(y, foreground, text)
	drawText(mathFloor(screenWidth / 2 - #text / 2), y, foreground, text)
end,

function(y, title)
	y = mathFloor(screenHeight / 2 - y / 2)
	drawRectangle(1, 1, screenWidth, screenHeight, colorsBackground)
	drawCentrizedText(y, colorsTitle, title)

	return y + 2
end,

function(statusText, needWait)
	local lines = {}

	for line in statusText:gmatch("[^\r\n]+") do
		lines[#lines + 1] = line:gsub("\t", "  ")
	end
	
	local y = drawTitle(#lines, stringsLunaEFI)

	-- Drawing the GitHub link at the bottom left
	drawText(1, screenHeight, colorsText, stringsLunaInfo)
	
	for i = 1, #lines do
		drawCentrizedText(y, colorsText, lines[i])
		y = y + 1
	end

	if needWait then
		while pullSignal() ~= stringsKeyDown do

		end
	end
end,

function(...)
	local result, reason = load(...)

	if result then
		result, reason = xpcall(result, debug.traceback)

		if result then
			return
		end
	end

	if reason:lower():find("too long without yielding") then
		status("The computer held too long and wasn't responding and was halted to prevent\nfuture problems. Reboot the machine by pressing any key\nto recover.", 1)
		status("The computer is restarting now, please wait...")
		computer.shutdown(true)
	else
		status(reason, 1)
	end

end,

function(proxy)
	local OS

	for i = 1, #OSList do
		OS = OSList[i]

		if proxy.exists(OS[1]) then
			-- Display
			status("Booting from " .. (proxy.getLabel() or proxy.address))

			-- Sound
			computer.beep(700, 0.01)
			
			-- Updating current EEPROM boot address if it's differs from given proxy address
			if getMainBootAddress() ~= proxy.address then
				setMainBootAddress(proxy.address)
			end


			computer.getBootAddress, computer.setBootAddress = getMainBootAddress, setMainBootAddress

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
	return newMenuElement(locale.common.back, f, 1)
end,

function(title, items)
	local selectedIndex = 1

	while 1 do
		local y, x, text, e = drawTitle(#items + 2, title)
		
		for i = 1, #items do
			text = "  " .. items[i].s .. "  "
			x = mathFloor(screenWidth / 2 - #text / 2)
			
			if i == selectedIndex then
				gpuSetBackground(colorsSelectionBackground)
				drawText(x, y, colorsSelectionText, text)
				gpuSetBackground(colorsBackground)
			else
				drawText(x, y, colorsText, text)
				drawText(1, screenHeight, colorsText, stringsLunaInfo)
			end
			
			y = y + 1
		end

		e = { pullSignal() }

		if e[1] == stringsKeyDown then
			if e[4] == 200 then -- up
				if selectedIndex > 1 then
					selectedIndex = selectedIndex - 1
					computer.beep(600, 0.01)
				else
					computer.beep(55, 0.005)
				end
			elseif e[4] == 208 then -- down
				if selectedIndex < #items then
					selectedIndex = selectedIndex + 1
					computer.beep(600, 0.01)
				else
					computer.beep(55, 0.005)
				end
			elseif e[4] == 28 then -- enter
				if items[selectedIndex].s:lower() == "back" or items[selectedIndex].s:lower() == "cancel" or items[selectedIndex].s:lower() == "no" then
					computer.beep(500, 0.01)
				else
					computer.beep(700, 0.01)
				end

				if items[selectedIndex].c then
					items[selectedIndex].c()
				end
				
				if items[selectedIndex].b then
					break
				end
			end
		elseif e[1] == stringsComponentAdded and e[3] == "screen" then
			bindGPUToScreen()
		end
	end
end,

function(title, prefix)
	local
		y,
		text,
		state,
		prefixedText,
		char,
		e =

		drawTitle(2, title),
		"",
		1

	while 1 do
		prefixedText = prefix .. text

		gpuFill(1, y, screenWidth, 1, " ")
		drawCentrizedText(y, colorsText, prefixedText .. (state and "_" or ""))

		e = { pullSignal(0.5) }

		if e[1] == stringsKeyDown then
			if e[4] == 28 then
				computer.beep(700, 0.01)
				return text

			elseif e[4] == 14 then
				text = text:sub(1, -2)
				computer.beep(500, 0.01)
			
			else
				char = unicode.char(e[3])

				if char:match("^[%w%d%p%s]+") then
					text = text .. char
					computer.beep(600, 0.01)
				end
			end

			state = 1
		
		elseif e[1] == "clipboard" then
			text = text .. e[3]
			computer.beep(600, 0.01)
		
		elseif not e[1] then
			state = not state
		end
	end
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
		status("Netbooting from file...")

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
		status("Boot failed. Invalid URL.", 1)
	end
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
		status("Grabbing the file to install...")

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
		status("Installation failed: Invalid URL.", 1)
	end
end

bindGPUToScreen()
checkValidData()
computer.beep(450, 0.1)
status("Starting installation...")

startupfunc = function()
	local result, reason = ""

	do
		local handle, chunk = component.proxy(component.list("internet")() or error("Required internet component is missing")).request("https://raw.githubusercontent.com/IgorTimofeev/MineOS/master/Installer/Main.lua")

		while true do
			chunk = handle.read(math.huge)
			
			if chunk then
				result = result .. chunk
			else
				break
			end
		end

		handle.close()
	end

	result, reason = load(result, "=installer")

	if result then
		result, reason = xpcall(result, debug.traceback)

		if not result then
			error(reason)
		end
	else
		error(reason)	
	end
end

succ, err = pcall(startupfunc)
if not succ then
	
	local result, reason = load(...)

	if result then
		result, reason = xpcall(result, debug.traceback)

		if result then
			return
		end
	end

	if reason:lower():find("too long without yielding") then
		status("The computer held too long and wasn't responding and was halted to prevent\nfuture problems. Reboot the machine by pressing any key\nto recover.", 1)
		status("The computer is restarting now, please wait...")
		computer.shutdown(true)
	else
		status(reason, 1)
		computer.shutdown()
	end
end

