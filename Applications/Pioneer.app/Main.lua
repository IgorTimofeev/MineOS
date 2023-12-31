
local GUI = require("GUI")
local screen = require("Screen")
local filesystem = require("Filesystem")
local color = require("Color")
local image = require("Image")
local paths = require("Paths")
local system = require("System")
local text = require("Text")
local internet = require("Internet")
local event = require("Event")

-------------------------------- Config ------------------------------------------------

local configPath = paths.user.applicationData .. "Pioneer/Config.cfg"
local saveConfigUptime

local config = {
	tapes = {

	},
	timeMode = 0,
	navigationSensivity = 0,
	jogResistance = 0,
	gain = 1,
	tempo = 0.5,
 	tempoIndex = 0,
}

-- Loading config if it exists
if filesystem.exists(configPath) then
	local loadedConfig = filesystem.readTable(configPath)

	-- Older versions support
	for key, value in pairs(config) do
		if not loadedConfig[key] then
			loadedConfig[key] = value
		end
	end

	config = loadedConfig
end

local function delaySaveConfig()
	saveConfigUptime = computer.uptime() + 1
end

-------------------------------- Core ------------------------------------------------

local sampleRate = 1500 * 4
local IOBufferSize = 8192

local blinkState = false
local blinkUptime = 0
local blinkInterval = 0.5

local loopInButton
local loopOutButton

local tapes
local tapeIndex
local tape
local tapeConfig
local tapePosition = 0

local currentScriptDirectory = filesystem.path(system.getCurrentScript())

local function invoke(...)
	return component.invoke(tape.address, ...)
end

local function setPosition(value)
	invoke("seek", value - invoke("getPosition"))
end

local function updateTapePosition()
	tapePosition = invoke("getPosition")
end

local function navigate(direction)
	-- Min seek is 100 ms & max is 10 s
	invoke("seek", math.floor((0.1 + (10 * config.navigationSensivity)) * sampleRate * direction))
	updateTapePosition()
end

local function getTapeTempo()
	local tempo = 2 * config.tempo - 1

	if config.tempoIndex == 0 then
		tempo = tempo * 0.25
	
	elseif config.tempoIndex == 1 then
		tempo = tempo * 0.5
	
	elseif config.tempoIndex == 2 then
		tempo = tempo * 0.75
	end

	return tempo
end

local function updateTempo(address)
	component.invoke(address, "setSpeed", 1 + getTapeTempo() * 0.75)
end

local function updateGain(address)
	component.invoke(address, "setVolume", config.gain)
end

local function updateTempoForAll()
	for i = 1, #tapes do
		updateTempo(tapes[i].address)
	end
end

local function updateGainForAll()
	for i = 1, #tapes do
		updateGain(tapes[i].address)
	end
end

local function updateLoop()
	loopInButton.blinking = tapeConfig.loopIn and tapeConfig.loopOn
	loopOutButton.blinking = tapeConfig.loopOut and tapeConfig.loopOn
end

local function updateTape()
	tape = tapes[tapeIndex]
	tapeConfig = config.tapes[tape.address]
	config.lastTape = tape.address

	updateLoop()
end

local function updateTapes()
 	tapes = {}
 	tapeIndex = 1
 	tape = nil
 	tapeConfig = nil

 	local counter = 1

 	for address in component.list("tape_drive") do
 		table.insert(tapes, {
 			address = address,
 			size = component.invoke(address, "getSize")
 		})

 		if not config.tapes[address] then
 			config.tapes[address] = {
 				cue = 0,
 				cues = {},
 				cueIndex = 1,
 				hotCues = {}
 			}
 		end

 		if config.lastTape == address then
 			tapeIndex = counter
 		end

 		updateTempo(address)
 		updateGain(address)

 		counter = counter + 1
 	end

 	if #tapes > 0 then
 		updateTape()
 	end
end

local function loadImage(name)
	local result, reason = image.load(currentScriptDirectory .. "Images/" .. name .. ".pic")

	if not result then
		GUI.alert(reason)
	end

	return result
end

-------------------------------- Window ------------------------------------------------

local workspace, window, menu = system.addWindow(GUI.window(1, 1, 78, 49))

window.drawShadow = false

local backgroundImage = loadImage("Background")
local powerButton

-------------------------------- Overlay ------------------------------------------------

local overlay = window:addChild(GUI.object(1, 1, window.width, window.height))

local displayWidth, displayHeight = 33, 10

local jogImages = {}

for i = 1, 12 do
	jogImages[i] = loadImage("Jog" .. i)
end

local knobImages = {}

for i = 1, 8 do
	knobImages[i] = loadImage("Knob" .. i)
end

local jogIndex = 1
local jogIncrementTempoMin = 0.05
local jogIncrementTempoMax = 2
local jogIncrementUptime = 0

local function incrementJogIndex(value)
	jogIndex = jogIndex + value

	if jogIndex > #jogImages then
		jogIndex = 1

	elseif jogIndex < 1 then
		jogIndex = #jogImages
	end
end

local function invalidateJogIncrementUptime(uptime)
	jogIncrementUptime = uptime + (1 - config.tempo) * (jogIncrementTempoMax - jogIncrementTempoMin)
end

local function displayDrawProgressBar(x, y, width, progress)
	local progressActiveWidth = math.floor(progress * width)

	screen.drawText(x, y, 0xE1E1E1, string.rep("━", progressActiveWidth))
	screen.drawText(x + progressActiveWidth, y, 0x4B4B4B, string.rep("━", width - progressActiveWidth))
end

overlay.draw = function(overlay)
	screen.drawImage(overlay.x, overlay.y, backgroundImage)
	
	-- Power indicator
	screen.drawText(overlay.x + 73, overlay.y + 3, powerButton.pressed and 0xFF0000 or 0x330000, "⠒")

	-- SD-card indicator
	screen.drawText(overlay.x + 5, overlay.y + 10, powerButton.pressed and 0xFFB640 or 0x332400, "⠒")

	-- Ignoring if power is off
	if not powerButton.pressed then
		return
	end

	-- Tempo slider indicator
	screen.drawText(overlay.x + 68, overlay.y + 39, 0xFFDB40, "⠆")

	-- Jog
	screen.drawImage(overlay.x + 33, overlay.y + 29, jogImages[jogIndex])

	-- Display
	local displayX, displayY = overlay.x + 22, overlay.y + 3

	-- Label
	local label = tape and invoke("getLabel") or "No tape"

	if not label or #label == 0 then
		label = "Untitled tape"
	end

	screen.drawRectangle(displayX, displayY, displayWidth, 1, 0x004980, 0xE1E1E1, " ")
	screen.drawText(displayX + 1, displayY, 0xE1E1E1, text.limit("♪ " .. label, displayWidth - 3))

	if tape then
		-- Stats
		local statsX = displayX + 2
		local statsY = displayY + displayHeight - 5

		-- Track index
		screen.drawText(statsX, statsY, 0xE1E1E1, "Track")
		screen.drawText(statsX, statsY + 1, 0xE1E1E1, string.format("%02d", tapeIndex))

		-- Time
		local timeSecondsTotal = (config.timeMode == 0 and tapePosition or (config.timeMode == 1 and tape.size - tapePosition or tape.size)) / sampleRate
		local timeMinutes = math.floor(timeSecondsTotal / 60)
		local timeSeconds, timeMilliseconds = math.modf(timeSecondsTotal - timeMinutes * 60)
		local timeString = string.format("%02d", timeMinutes) .. "m:" .. string.format("%02d", timeSeconds) .. "s".. string.format("%02d", math.floor(timeMilliseconds * 100))
		screen.drawText(statsX + 10, statsY + 1, 0xE1E1E1, config.timeMode == 1 and "-" .. timeString or timeString)

		-- Tempo
		screen.drawText(statsX + 24, statsY, 0xE1E1E1, "Tempo")
		screen.drawText(statsX + 26, statsY + 1, 0xE1E1E1, string.format("%02d", math.floor(getTapeTempo() * 100)) .. "%")

		-- Tempo index

		-- Track
		local trackWidth = displayWidth - 4
		local trackHeight = 3
		statsY = statsY + 2

		screen.drawRectangle(
			statsX,
			statsY + 1,
			trackWidth,
			trackHeight - 2,
			0x2D2D2D,
			0xE1E1E1,
			" "
		)

		-- Loop
		if tapeConfig.loopIn or tapeConfig.loopOut then
			local loopX = tapeConfig.loopIn and math.floor(tapeConfig.loopIn / tape.size * trackWidth) or 0

			screen.drawRectangle(
				statsX + loopX,
				statsY + 1,
				1 + (tapeConfig.loopOut and math.floor(tapeConfig.loopOut / tape.size * trackWidth) or trackWidth) - loopX,
				1,
				tapeConfig.loopOn and 0x5A5A5A or 0x3C3C3C,
				0xE1E1E1,
				" "
			)
		end

		-- Position
		screen.drawText(
			math.floor(statsX + (tape.size == 0 and 0 or tapePosition / tape.size) * trackWidth),
			statsY + 1,
			0xE1E1E1,
			"│"
		)

		-- Memory cues
		local cueY = statsY

		for i = 1, #tapeConfig.cues do
			screen.drawText(
				statsX + math.floor(tapeConfig.cues[i] / tape.size * trackWidth),
				cueY,
				i == tapeConfig.cueIndex and 0xE1E1E1 or 0xCC0000,
				"•"
			)
		end

		-- Hot cues
		for name, position in pairs(tapeConfig.hotCues) do
			screen.drawText(
				statsX + math.floor(position / tape.size * trackWidth),
				cueY,
				0x66FF40,
				"•" .. name
			)
		end

		-- Current cue
		cueY = statsY + trackHeight - 1

		screen.drawText(
			statsX + math.floor(tapeConfig.cue / tape.size * trackWidth),
			cueY,
			0xFFB640,
			"•"
		)
	end
end

-------------------------------- Power button ------------------------------------------------

powerButton = window:addChild(GUI.object(75, 2, 4, 2))
powerButton.pressed = false

powerButton.draw = function()
	screen.drawText(powerButton.x, powerButton.y, 0x1E1E1E, powerButton.pressed and "⣠⣤⣄" or "⣸⣿⣇")
end

powerButton.eventHandler = function(workspace, powerButton, e1)
	if e1 == "touch" then
		powerButton.pressed = not powerButton.pressed

		if powerButton.pressed then
			jogIndex = 1
		end

		workspace:draw()

		computer.beep(20, 0.01)

		-- Stopping playback
		if not powerButton.pressed then
			for i = 1, #tapes do
				component.invoke(tapes[i].address, "stop")
			end
		end
	end
end

-------------------------------- Round mini button ------------------------------------------------

local function roundMiniButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, (powerButton.pressed or button.ignoresPower) and button.animationCurrentText or 0x0

	-- Background
	screen.drawRectangle(button.x + 1, button.y + 1, button.width - 2, button.height - 2, bg, fg, " ")

	-- Upper
	screen.drawText(button.x + 1, button.y, bg, string.rep("⣀", button.width - 2))

	-- Left
	screen.drawText(button.x, button.y + 1, bg, "⢸")

	-- Middle
	screen.drawText(math.floor(button.x + button.width / 2 - #button.text / 2), button.y + 1, fg, button.text)

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, bg, "⡇")

	-- Lower
	screen.drawText(button.x + 1, button.y + button.height - 1, bg, string.rep("⠉", button.width - 2))
end


local function roundMiniButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button:press()
	end
end

local function newRoundMiniButton(x, y, ...)
	local button = GUI.button(x, y, 4, 3, ...)

	button.draw = roundMiniButtonDraw
	button.eventHandler = roundMiniButtonEventHandler

	return button
end


local function roundTinyButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, (powerButton.pressed or button.ignoresPower) and button.animationCurrentText or 0x0

	-- Left
	screen.drawText(button.x, button.y, bg, "⢰")

	-- Middle
	screen.drawRectangle(button.x + 1, button.y, 2, 1, bg, fg, " ")
	screen.drawText(button.x + 1, button.y, fg, button.text)

	-- Right
	screen.drawText(button.x + 3, button.y, bg, "⡆")

	-- Lower
	screen.drawText(button.x, button.y + 1, bg, "⠈⠛⠛⠁")
end

local function newRoundTinyButton(x, y, ...)
	local button = GUI.button(x, y, 4, 2, ...)

	button.draw = roundTinyButtonDraw
	button.eventHandler = roundMiniButtonEventHandler

	return button
end

-------------------------------- ImageButton ------------------------------------------------

local function imageButtonDraw(button)
	screen.drawImage(button.x, button.y, (powerButton.pressed and (not button.blinking or blinkState)) and button.imageOn or button.imageOff)
end

local function newImageButton(x, y, width, height, name)
	local button = GUI.object(x, y, width, height)

	button.imageOn = loadImage(name .. "On")
	button.imageOff = loadImage(name .. "Off")

	button.draw = imageButtonDraw

	return button
end

-------------------------------- Tempo slider ------------------------------------------------

local tempoSlider = window:addChild(GUI.object(71, 33, 5, 15))
local tempoSliderImage = loadImage("TempoSlider")

tempoSlider.value = config.tempo

tempoSlider.draw = function(tempoSlider)
	screen.drawImage(
		tempoSlider.x,
		tempoSlider.y + math.floor(tempoSlider.value * tempoSlider.height) - math.floor(tempoSlider.value * 3),
		tempoSliderImage
	)
end

tempoSlider.eventHandler = function(workspace, tempoSlider, e1, e2, e3, e4)
	if (e1 == "touch" or e1 == "drag") then
		if e4 == tempoSlider.y + tempoSlider.height - 1 then
			tempoSlider.value = 1
		elseif e4 == math.floor(tempoSlider.y + tempoSlider.height / 2) then
			tempoSlider.value = 0.5
		else
			tempoSlider.value = (e4 - tempoSlider.y) / tempoSlider.height
		end

		config.tempo = tempoSlider.value
		workspace:draw()

		updateTempoForAll()
		delaySaveConfig()
	end
end

-------------------------------- Display buttons ------------------------------------------------

local function displayButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, (powerButton.pressed or button.ignoresPower) and button.animationCurrentText or 0x4B4B4B

	-- Background
	screen.drawRectangle(button.x + 1, button.y + 1, button.width - 2, button.height - 2, bg, fg, " ")

	-- Upper
	screen.drawText(button.x, button.y, fg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, fg, "⢸")

	-- Middle
	screen.drawText(math.floor(button.x + button.width / 2 - unicode.len(button.text) / 2), button.y + 1, fg, button.text)

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, fg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, fg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")

end

local function newDisplayButton(x, y, width, ...)
	local button = GUI.button(x, y, width, 3, ...)

	button.pressed = false
	button.draw = displayButtonDraw

	return button
end

local helpButton = window:addChild(newDisplayButton(14, 1, 7, 0x0F0F0F, 0xF0F0F0, 0x0, 0xA5A5A5, "Help"))
helpButton.onTouch = function()
	if not powerButton.pressed then
		return
	end

	local container = GUI.addBackgroundContainer(workspace, true, true, "Help")
	container.layout:removeChildren()
	
	local lines = {
		"Pioneer CDJ-2000 nexus",
		" ",
		"Pro-grade digital DJ deck for Computronics",
		"tape drives and DFPWM audio codec.",
		"To convert your favorite tracks, use",
		"https://music.madefor.cc",
		" ",
		"Designed by Pioneer Corporation in Japan",
		" ",
		"Developed and adapted for MineOS by",
		"Igor Timofeev, vk.com/id7799889",
		"Maxim Afonin, @140bpmdubstep"
	}

	local textBox = container.layout:addChild(GUI.textBox(1, 1, container.layout.width, #lines, nil, 0xB4B4B4, lines, 1, 0, 0))
	textBox:setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_TOP)
	textBox.eventHandler = container.panel.eventHandler

	workspace:draw()
end

local closeButton = window:addChild(newDisplayButton(14, 4, 7, 0x0F0F0F, 0x4B4B4B, 0x0, 0x3349FF, "Close"))
closeButton.onTouch = function()
	window:remove()
end

local function checkForFreeSpace(requiredSize)
	if requiredSize > tape.size - invoke("getPosition") then
		GUI.alert("Not enough space on tape")
		return false
	end

	return true
end

local wipeButton = window:addChild(newDisplayButton(14, 7, 7, 0x0F0F0F, 0x4B4B4B, 0x0, 0xFFDB40, "Wipe"))

local fileButton = window:addChild(newDisplayButton(23, 1, 10, 0x0F0F0F, 0x4B4B4B, 0x0, 0xFFDB40, "File"))
fileButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Confirm", "Cancel", "File name", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".dfpwm")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		local fileSize = filesystem.size(path)

		if not checkForFreeSpace(fileSize) then
			return
		end

		local container = GUI.addBackgroundContainer(workspace, true, true, "Writing track via file")
		local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 36, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))

		local oldPosition = invoke("getPosition")
		invoke("stop")

		workspace:draw()

		local file, reason = filesystem.open(path, "rb")
		
		if file then
			local bytesWritten, chunk = 0
			
			while true do
				chunk = file:read(IOBufferSize)

				if not chunk then
					break
				end

				if not invoke("isReady") then
					GUI.alert("Tape was removed during writing")
					break
				end

				invoke("write", chunk)

				bytesWritten = bytesWritten + #chunk
				progressBar.value = math.floor(bytesWritten / fileSize * 100)

				workspace:draw()
			end

			file:close()
		else
			GUI.alert(reason or "Unable to open file for writing")
		end

		setPosition(oldPosition)

		container:remove()
		workspace:draw()
	end
end

local urlButton = window:addChild(newDisplayButton(34, 1, 10, 0x0F0F0F, 0x4B4B4B, 0x0, 0xFFDB40, "Url"))
urlButton.onTouch = function()
	if not tape or not powerButton.pressed or not component.isAvailable("internet") then
		return
	end

	local container = GUI.addBackgroundContainer(workspace, true, true, "Downloading track via URL")
	
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, "", "https://example.com/track.dfpwm", false))

	container.panel.eventHandler = function(workspace, panel, e1)
		if e1 == "touch" then
			if #input.text > 0 then
				input:remove()

				container.label.text = "Downloading track"
				local progressBar = container.layout:addChild(GUI.progressBar(1, 1, 36, 0x66DB80, 0x0, 0xE1E1E1, 0, true, true, "", "%"))

				workspace:draw()

				invoke("stop")

				local handle, reason = component.get("internet").request(
					input.text,
					nil,
					{
						["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.119 Safari/537.36",
						["Content-Type"] = "application/x-www-form-urlencoded"
					},
					"GET"
				)
				
				if handle then
					local deadline, code, message, headers = computer.uptime() + 5
					
					repeat
						code, message, headers = handle:response()
					until headers or computer.uptime() >= deadline

					if headers then
						if headers["Content-Length"] then
							local fileSize = tonumber(headers["Content-Length"][1])
							local oldPosition = invoke("getPosition")

							if checkForFreeSpace(fileSize) then
								local bytesWritten, chunk, reason = 0

								while true do
									chunk, reason = handle.read(IOBufferSize)

									if not chunk then
										if reason then
											GUI.alert(reason)
										end

										break
									end

									if not invoke("isReady") then
										GUI.alert("Tape was removed during writing")
										break
									end

									invoke("write", chunk)

									bytesWritten = bytesWritten + #chunk
									progressBar.value = math.floor(bytesWritten / fileSize * 100)

									workspace:draw()
								end

								setPosition(oldPosition)
							end
						else
							GUI.alert("Web-server didn't respont with Content-Length header")
						end
					else
						GUI.alert("Too long without response")
					end

					handle:close()
				else
					GUI.alert(reason or "Invalid URL-address")
				end
			end

			container:remove()
			workspace:draw()
		end
	end
end

local labelButton = window:addChild(newDisplayButton(45, 1, 10, 0x0F0F0F, 0x4B4B4B, 0x0, 0xFFDB40, "Label"))
labelButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	local container = GUI.addBackgroundContainer(workspace, true, true, "Change tape label")
	
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, invoke("getLabel") or "", "The Algortithm - Superscalar", false))

	input.onInputFinished = function()
		invoke("setLabel", input.text)
		workspace:draw()
	end

	container.panel.onTouch = function()
		container:remove()
		workspace:draw()
	end

	workspace:draw()
end

-------------------------------- Quantize/time buttons ------------------------------------------------

local _ = window:addChild(newRoundTinyButton(14, 12, 0x0F0F0F, 0xFF0000, 0x0, 0x440000, "⢠⡄"))

local timeModeButton = window:addChild(newRoundTinyButton(18, 12, 0x0F0F0F, 0x1E1E1E, 0x0, 0x0F0F0F, "⢠⡄"))
timeModeButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	config.timeMode = config.timeMode + 1

	if config.timeMode > 2 then
		config.timeMode = 0
	end

	workspace:draw()
	delaySaveConfig()
end

-------------------------------- Needle search ------------------------------------------------

local needleSearch = window:addChild(GUI.object(25, 15, 29, 2))

needleSearch.draw = function()
	screen.drawText(needleSearch.x, needleSearch.y, powerButton.pressed and 0xE1E1E1 or 0x0, "▲ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ╷ ▲")
end

needleSearch.eventHandler = function(workspace, needleSearch, e1, e2, e3, e4)
	if (e1 == "touch" or e1 == "drag") and powerButton.pressed and tape then
		setPosition(math.floor((e3 - needleSearch.x) / (needleSearch.width - 1) * tape.size))

		workspace:draw()
	end
end

-------------------------------- Jog ------------------------------------------------

local jog = window:addChild(GUI.object(15, 20, 52, 26))
local jogAngleOld

jog.eventHandler = function(workspace, jog, e1, e2, e3, e4, e5, ...)
	if not tape or not powerButton.pressed then
		return
	end

	local function jogNavigate(direction)
		incrementJogIndex(direction)
		invalidateJogIncrementUptime(computer.uptime())
		navigate(direction)

		workspace:draw()
	end

	if e1 == "drag" then
		local angleNew = math.atan2(
			e3 - jog.x - jog.width / 2,
			e4 - jog.y - jog.height / 2
		)

		if jogAngleOld then
			jogNavigate(jogAngleOld - angleNew >= 0 and 1 or -1)
		end

		jogAngleOld = angleNew

	elseif e1 == "drop" then
		jogAngleOld = nil

	elseif e1 == "scroll" then
		jogNavigate(e5 >= 0 and 1 or -1)
	end
end

-------------------------------- Knobs ------------------------------------------------

local function knobDraw(knob)
	screen.drawImage(knob.x, knob.y, knobImages[1 + math.floor(knob.value * (#knobImages - 1))])
end

local function knobEventHandler(workspace, knob, e1, e2, e3, e4, e5, ...)
	local function increment(upper)
		local tempo = 0.1
		local newValue = math.max(0, math.min(1, knob.value + (upper and tempo or -tempo)))

		if newValue == knob.value then
			return
		end

		knob.value = newValue

		workspace:draw()

		if knob.onValueChanged then
			knob.onValueChanged(knob)
		end
	end

	if e1 == "touch" then
		knob.touchX, knob.touchY = e3, e4

	elseif e1 == "drag" and knob.touchX then
		local dx, dy = e3 - knob.touchX, e4 - knob.touchY
		knob.touchX, knob.touchY = e3, e4

		increment((math.abs(dx) > math.abs(dy) and dx or dy) >= 0)

	elseif e1 == "drop" then
		knob.touchX, knob.touchY = nil, nil

	elseif e1 == "scroll" then
		increment(e5 >= 0)
	end
end

local function newKnob(x, y, value)
	local knob = GUI.object(x, y, 5, 3)

	knob.value = value
	knob.draw = knobDraw
	knob.eventHandler = knobEventHandler

	return knob
end

-- Jog resistance
local jogResistanceKnob = window:addChild(newKnob(61, 21, config.jogResistance))

jogResistanceKnob.onValueChanged = function()
	config.jogResistance = jogResistanceKnob.value
	delaySaveConfig()
end

-- Gain
gainKnob = window:addChild(newKnob(72, 12, config.gain))

gainKnob.onValueChanged = function()
	config.gain = gainKnob.value

	updateGainForAll()
	delaySaveConfig()
end

-- Navigation sensivity
local navigationSensivityKnob = window:addChild(newKnob(72, 16, config.navigationSensivity))

navigationSensivityKnob.onValueChanged = function()
	config.navigationSensivity = navigationSensivityKnob.value
	delaySaveConfig()
end

-------------------------------- Pref/next tape button ------------------------------------------------

local tapePrevButton = window:addChild(newRoundMiniButton(2, 30, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, "<<"))
local tapeNextButton = window:addChild(newRoundMiniButton(7, 30, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, ">>"))

local function incrementTape(next)
	if not tape or not powerButton.pressed then
		return
	end

	tapeIndex = tapeIndex + (next and 1 or -1)

	if tapeIndex > #tapes then
		tapeIndex = 1
	elseif tapeIndex < 1 then
		tapeIndex = #tapes
	end

	updateTape()
	workspace:draw()

	delaySaveConfig()
end

tapePrevButton.onTouch = function()
	incrementTape(false)
end

tapeNextButton.onTouch = function()
	incrementTape(true)
end

-------------------------------- Pref/next search button ------------------------------------------------

local searchPrevButton = window:addChild(newRoundMiniButton(2, 34, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, "<<"))
local searchNextButton = window:addChild(newRoundMiniButton(7, 34, 0x2D2D2D, 0xFFB600, 0x0F0F0F, 0xCC9200, ">>"))

local function incrementFromSearchButton(direction)
	if not tape or not powerButton.pressed then
		return
	end

	navigate(direction)

	workspace:draw()
end

searchPrevButton.onTouch = function()
	incrementFromSearchButton(-1)
end

searchNextButton.onTouch = function()
	incrementFromSearchButton(1)
end

-------------------------------- Hot cue buttons ------------------------------------------------

local hotCueRecCallButton

local function hotCueButtonDraw(button)
	local bg = button.animationCurrentBackground
	local fg = (powerButton.pressed and tape and (hotCueRecCallButton.rec or tapeConfig.hotCues[button.text])) and button.animationCurrentText or 0x2D2D2D

	-- Upper
	screen.drawText(button.x, button.y, bg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, bg, "⢸")

	-- Middle
	screen.set(button.x + 1, button.y + 1, 0x2D2D2D, 0x5A5A5A, "⣤")
	screen.set(button.x + 2, button.y + 1, bg, 0x787878, "⠤")

	screen.set(button.x + 3, button.y + 1, bg, fg, button.text)

	screen.set(button.x + 4, button.y + 1, bg, 0x787878, "⠒")
	screen.set(button.x + 5, button.y + 1, 0x2D2D2D, 0x5A5A5A, "⠛")

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, bg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, bg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")

end

local hotCueButtons = {}

local function newHotCueButton(x, y, index, text)
	local button = GUI.button(x, y, 7, 3, 0x1E1E1E, 0x66FF40, 0x0, 0x336D00, text)

	button.draw = hotCueButtonDraw

	button.onTouch = function()
		if not tape or not powerButton.pressed then
			return
		end

		local hotCuePosition = tapeConfig.hotCues[button.text]

		if hotCueRecCallButton.rec then
			local position = invoke("getPosition")
			tapeConfig.hotCues[button.text] = (not hotCuePosition or hotCuePosition ~= position) and position or nil

			workspace:draw()
			delaySaveConfig()

		elseif hotCuePosition then
			setPosition(hotCuePosition)

			workspace:draw()
		end
	end

	table.insert(hotCueButtons, button)

	return button
end

-- local hotCueButtonA = window:addChild(newHotCueButton(3, 13, 0x66FF40, 0x336D00, "A"))
-- local hotCueButtonB = window:addChild(newHotCueButton(3, 16, 0xFFB600, 0x664900, "B"))
-- local hotCueButtonB = window:addChild(newHotCueButton(3, 19, 0xFF2440, 0x660000, "C"))

local hotCueButtonA = window:addChild(newHotCueButton(3, 13, 1, "A"))
local hotCueButtonB = window:addChild(newHotCueButton(3, 16, 2, "B"))
local hotCueButtonB = window:addChild(newHotCueButton(3, 19, 3, "C"))

hotCueRecCallButton = window:addChild(GUI.button(3, 23, 7, 3, 0x1E1E1E, 0x1E1E1E, 0x0, 0x0, "⠶"))
hotCueRecCallButton.rec = false
hotCueRecCallButton.draw = hotCueButtonDraw
hotCueRecCallButton.onTouch = function()
	hotCueRecCallButton.rec = not hotCueRecCallButton.rec

	-- Updating buttons color scheme
	local button

	for i = 1, #hotCueButtons do
		button = hotCueButtons[i]

		button.colors.default.text = hotCueRecCallButton.rec and 0xFF2440 or 0x66FF40
		button.colors.pressed.text = hotCueRecCallButton.rec and 0x660000 or 0x336D00
		button.animationCurrentText = button.colors.default.text
	end

	workspace:draw()
end

-------------------------------- Loop buttons ------------------------------------------------

local function loopButtonDraw(button)
	local border, color1, color2, color3, color4

	if powerButton.pressed and (not button.blinking or blinkState) then
		if button.pressed then
			border, color1, color2, color3, color4 = 0x332400, 0x996D00, 0x996D00, 0x996D00, 0x996D00
		else
			border, color1, color2, color3, color4 = 0x332400, 0xFFDB80, 0xFFDB40, 0xFFB680, 0xFFB640
		end
	else
		border, color1, color2, color3, color4 = 0x0F0F0F, 0x332400, 0x332400, 0x332400, 0x332400
	end

	-- 1
	screen.drawText(button.x, button.y, border, "⢰")
	screen.set(button.x + 1, button.y, color1, border, "⠉")
	screen.set(button.x + 2, button.y, color2, border, "⠉")
	screen.set(button.x + 3, button.y, color3, border, "⠉")
	screen.drawText(button.x + 4, button.y, border, "⡆")

	-- 2
	screen.drawText(button.x, button.y + 1, border, "⠸")
	screen.set(button.x + 1, button.y + 1, color4, border, "⣀")
	screen.set(button.x + 2, button.y + 1, color4, border, "⣀")
	screen.set(button.x + 3, button.y + 1, color3, border, "⣀")
	screen.drawText(button.x + 4, button.y + 1, border, "⠇")
end

local function loopButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button.pressed = true
		workspace:draw()
		
		event.sleep(0.2)

		button.pressed = false
		workspace:draw()

		if button.onTouch then
			button.onTouch()
		end
	end
end

local function newLoopButton(x, y)
	local button = GUI.object(x, y, 5, 2)

	button.pressed = false
	button.draw = loopButtonDraw
	button.eventHandler = loopButtonEventHandler

	return button
end

loopInButton = window:addChild(newLoopButton(13, 18))
loopOutButton = window:addChild(newLoopButton(19, 18))
local reloopButton = window:addChild(newRoundTinyButton(26, 18, 0x2D2D2D, 0xFFB640, 0x1E1E1E, 0x996D00, "⢠⡄"))

loopInButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	local position = invoke("getPosition")

	tapeConfig.loopIn = position ~= tapeConfig.loopIn and position or nil

	if tapeConfig.loopIn then
		tapeConfig.loopOn = true

		if tapeConfig.loopOut and tapeConfig.loopIn >= tapeConfig.loopOut then
			tapeConfig.loopOut = nil
		end
	else
		tapeConfig.loopOn = tapeConfig.loopOut ~= nil
	end

	updateLoop()

	workspace:draw()
	delaySaveConfig()
end

loopOutButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	local position = invoke("getPosition")

	tapeConfig.loopOut = position ~= tapeConfig.loopOut and position or nil

	if tapeConfig.loopOut then
		tapeConfig.loopOn = true

		if tapeConfig.loopIn and tapeConfig.loopIn >= tapeConfig.loopOut then
			tapeConfig.loopIn = nil
		end
	else
		tapeConfig.loopOn = tapeConfig.loopIn ~= nil
	end

	updateLoop()

	workspace:draw()
	delaySaveConfig()
end

reloopButton.onTouch = function()
	if not tape or not powerButton.pressed or (not tapeConfig.loopIn and not tapeConfig.loopOut) then
		return
	end

	tapeConfig.loopOn = not tapeConfig.loopOn
	updateLoop()

	workspace:draw()
	delaySaveConfig()
end

-------------------------------- Cue memory buttons ------------------------------------------------

local function incrementCueIndex(value)
	if not tape or not powerButton.pressed then
		return
	end

	if #tapeConfig.cues == 0 then
		tapeConfig.cueIndex = 1
		return
	end

	tapeConfig.cueIndex = tapeConfig.cueIndex + value

	if tapeConfig.cueIndex < 1 then
		tapeConfig.cueIndex = #tapeConfig.cues
	elseif tapeConfig.cueIndex > #tapeConfig.cues then
		tapeConfig.cueIndex = 1
	end

	tapeConfig.cue = tapeConfig.cues[tapeConfig.cueIndex]

	setPosition(tapeConfig.cue)

	workspace:draw()
	delaySaveConfig()
end

local cuePrevButton = window:addChild(newRoundTinyButton(50, 18, 0x0F0F0F, 0xFFB640, 0x0, 0x996D00, "⢔ "))
cuePrevButton.onTouch = function()
	incrementCueIndex(-1)
end

local cueNextButton = window:addChild(newRoundTinyButton(54, 18, 0x0F0F0F, 0xFFB640, 0x0, 0x996D00, " ⡢"))
cueNextButton.onTouch = function()
	incrementCueIndex(1)
end

local cueDelButton = window:addChild(newRoundTinyButton(59, 18, 0x0F0F0F, 0x4B4B4B, 0x0, 0x2D2D2D, " "))
cueDelButton.onTouch = function()
	if not tape or not powerButton.pressed or #tapeConfig.cues == 0 then
		return
	end

	table.remove(tapeConfig.cues, tapeConfig.cueIndex)

	if tapeConfig.cueIndex > #tapeConfig.cues then
		tapeConfig.cueIndex = math.max(tapeConfig.cueIndex - 1, 1)
	end	

	delaySaveConfig()
end

local cueMemButton = window:addChild(newRoundTinyButton(63, 18, 0x0F0F0F, 0x4B4B4B, 0x0, 0x2D2D2D, " "))
cueMemButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	local cue

	for i = 1, #tapeConfig.cues do
		cue = tapeConfig.cues[i]

		if cue == tapeConfig.cue then
			return
		end
	end

	table.insert(tapeConfig.cues, tapeConfig.cue)
	table.sort(tapeConfig.cues)

	delaySaveConfig()
end

-------------------------------- Cue / play buttons ------------------------------------------------

local cueButton = window:addChild(newImageButton(2, window.height - 11, 9, 5, "Cue"))

local playButton = window:addChild(newImageButton(2, window.height - 5, 9, 5, "Play"))
playButton.blinking = true

cueButton.eventHandler = function(workspace, cueButton, e1)
	if not tape or not powerButton.pressed then
		return
	end

	if e1 == "touch" then
		cueButton.touchUptime = computer.uptime() + 10

		if playButton.blinking then
			tapeConfig.cue = invoke("getPosition")
			cueButton.blinking = false

			workspace:draw()
			delaySaveConfig()
		else
			setPosition(tapeConfig.cue)

			workspace:draw()
		end
	end
end

playButton.eventHandler = function(workspace, playButton, e1)
	if e1 == "touch" and tape and powerButton.pressed then
		playButton.blinking = not playButton.blinking

		if not playButton.blinking then
			cueButton.blinking = false
		end
		
		invoke(playButton.blinking and "stop" or "play")

		workspace:draw()
	end
end

-------------------------------- Jog mode ------------------------------------------------

local jogModeDisplay = window:addChild(GUI.object(71, 20, 3, 2))
jogModeDisplay.draw = function(jogModeDisplay)
	local vinyl = (powerButton.pressed and not config.jogModeCdj) and 0x00B6FF or 0x002440
	local cdj = (powerButton.pressed and config.jogModeCdj) and 0xFFFF40 or 0x332400

	screen.drawText(jogModeDisplay.x, jogModeDisplay.y, vinyl, "⢀⣀⡀")
	screen.drawRectangle(jogModeDisplay.x, jogModeDisplay.y + 1, 3, 1, vinyl, cdj, "⣤")
	screen.drawText(jogModeDisplay.x, jogModeDisplay.y + 2, cdj, "⠈⠉⠁")
end

local jogModeButton = window:addChild(newRoundMiniButton(74, 20, 0x2D2D2D, 0x696969, 0x1E1E1E, 0x3C3C3C, "JM"))
jogModeButton.ignoresPower = true
jogModeButton.onTouch = function()
	if not tape or not powerButton.pressed then
		return
	end

	config.jogModeCdj = not config.jogModeCdj
	workspace:draw()
	delaySaveConfig()
end

-------------------------------- Right beat buttons ------------------------------------------------

local beatSyncButton = window:addChild(newRoundMiniButton(70, 24, 0xB4B4B4, 0x0F0F0F, 0x787878, 0x0F0F0F, "Sy"))
beatSyncButton.ignoresPower = true

local beatSyncMasterButton = window:addChild(newRoundMiniButton(74, 24, 0xB4B4B4, 0x0F0F0F, 0x787878, 0x0F0F0F, "Ms"))
beatSyncMasterButton.ignoresPower = true

-------------------------------- Right tempo buttons ------------------------------------------------

local tempoButton = window:addChild(newRoundTinyButton(72, 28, 0x0F0F0F, 0x2D2D2D, 0x0, 0xFF2440, " "))

local masterTempoButton = window:addChild(newRoundTinyButton(72, 31, 0x0F0F0F, 0x2D2D2D, 0x0F0F0F, 0xFF0000, "⢠⡄"))
masterTempoButton.switchMode = true
masterTempoButton:press()

tempoButton.onTouch = function()
	config.tempoIndex = config.tempoIndex + 1

	if config.tempoIndex > 3 then
		config.tempoIndex = 1
	end

	workspace:draw()
	updateTempoForAll()
	delaySaveConfig()
end

-------------------------------- Cyka ------------------------------------------------

local overrideWindowEventHandler = window.eventHandler

window.eventHandler = function(workspace, window, e1, e2, e3, ...)
	if (e1 == "component_added" or e1 == "component_removed") and e3 == "tape_drive" then
		updateTapes()
	else
		overrideWindowEventHandler(workspace, window, e1, e2, e3, ...)

		if e1 then
			return
		end

		local uptime = computer.uptime()

		if tape and powerButton.pressed then
			updateTapePosition()
			
			local shouldDraw = false
			local isPlaying = invoke("getState") == "PLAYING"

			-- Cheching if play button state was changed
			if isPlaying == playButton.blinking then
				playButton.blinking = not playButton.blinking
				invalidateJogIncrementUptime(uptime)
				shouldDraw = true
			end

			-- Cue button
			local cueButtonBlinking = playButton.blinking and tapeConfig.cue ~= tapePosition

			if cueButtonBlinking ~= cueButton.blinking then
				cueButton.blinking = cueButtonBlinking
				shouldDraw = true
			end

			-- Jog
			if isPlaying and uptime > jogIncrementUptime then
				incrementJogIndex(1)
				invalidateJogIncrementUptime(uptime)
				shouldDraw = true
			end

			-- Blink state
			if uptime > blinkUptime then
				blinkUptime = uptime + blinkInterval
				blinkState = not blinkState
				shouldDraw = true
			end

			-- Loop
			if isPlaying and tapeConfig.loopOn then
				if tapePosition >= (tapeConfig.loopOut or tape.size) then
					setPosition(tapeConfig.loopIn or 0)
					shouldDraw = true
				end
			end

			if shouldDraw then
				workspace:draw()
			end
		end

		-- If THE TIME HAS COME - saving config file
		if saveConfigUptime and uptime >= saveConfigUptime then
			saveConfigUptime = nil
			filesystem.writeTable(configPath, config)
		end
	end
end

updateTapes()

workspace:draw()