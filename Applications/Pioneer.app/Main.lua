
local GUI = require("GUI")
local screen = require("Screen")
local filesystem = require("Filesystem")
local color = require("Color")
local image = require("Image")
local paths = require("Paths")
local system = require("System")
local text = require("Text")

--------------------------------------------------------------------------------

local currentScriptDirectory = filesystem.path(system.getCurrentScript())

local function loadImage(name)
	local result, reason = image.load(currentScriptDirectory .. "Images/" .. name .. ".pic")

	if not result then
		GUI.alert(reason)
	end

	return result
end

local speedSlider
local speedMin = 0.25
local speedMax = 1.75

local bpmMin = 40
local bpmMax = 200


--------------------------------------------------------------------------------

local tapes
local tapeIndex
local tape
local tapeWritingProgress

local function updateCurrentTapeSpeed()
	tape.proxy.setSpeed(speedMin + tape.speed * (speedMax - speedMin))
end

local function updateCurrentTape()
	tape = tapes[tapeIndex]
	speedSlider.value = tape.speed

	updateCurrentTapeSpeed()
end

local function incrementTape(next)
	tapeIndex = tapeIndex + (next and 1 or -1)

	if tapeIndex > #tapes then
		tapeIndex = 1
	elseif tapeIndex < 1 then
		tapeIndex = #tapes
	end

	updateCurrentTape()
end

local function updateTapes()
 	tapes = {}
 	tapeIndex = 1

 	for address in component.list("tape_drive") do
 		table.insert(tapes, {
 			proxy = component.proxy(address),
 			speed = 0.5,
 			cues = {}
 		})
 	end

 	updateCurrentTape()
end


-------------------------------- Window ------------------------------------------------

local backgroundImage = loadImage("Background")

local workspace, window, menu = system.addWindow(GUI.window(1, 1, 78, 49))

window.drawShadow = false



-------------------------------- Jog ------------------------------------------------

local jogImages = {}

for i = 1, 12 do
	jogImages[i] = loadImage("Jog" .. i)
end


local function getIsPlaying()
	return tape.proxy.getState() == "PLAYING"
end


-------------------------------- Background ------------------------------------------------


local currentJogIndex = 1

local windowBackground = window:addChild(GUI.object(1, 1, window.width, window.height))

windowBackground.draw = function(windowBackground)
	-- Background
	screen.drawImage(windowBackground.x, windowBackground.y, backgroundImage)

	-- Jog
	screen.drawImage(windowBackground.x + 33, windowBackground.y + 29, jogImages[currentJogIndex])
end


-------------------------------- ImageButton ------------------------------------------------

local imageButtonBlink = false
local imageButtonBlinkUptime = 0
local imageButtonBlinkInterval = 0.5

local function imageButtonDraw(button)
	screen.drawImage(button.x, button.y, (not button.blinking or imageButtonBlink) and button.imageOn or button.imageOff)
end

local function newImageButton(x, y, width, height, name)
	local button = GUI.object(x, y, width, height)

	button.imageOn = loadImage(name .. "On")
	button.imageOff = loadImage(name .. "Off")

	button.draw = imageButtonDraw

	return button
end


-------------------------------- Speed slider ------------------------------------------------

local speedSliderImage = loadImage("SpeedSlider")

speedSlider = window:addChild(GUI.object(71, 33, 5, 14))

speedSlider.draw = function(speedSlider)
	-- screen.drawRectangle(speedSlider.x, speedSlider.y, speedSlider.width, speedSlider.height, 0xFF0000, 0x0, " ")

	local x = speedSlider.x
	local y = speedSlider.y + math.floor((1 - speedSlider.value) * (speedSlider.height - image.getHeight(speedSliderImage) / 2))

	screen.drawImage(x, y, speedSliderImage)
end

speedSlider.eventHandler = function(workspace, speedSlider, e1, e2, e3, e4)
	if e1 == "touch" or e1 == "drag" then
		speedSlider.value = 1 - ((e4 - speedSlider.y) / speedSlider.height)
		tape.speed = speedSlider.value

		updateCurrentTapeSpeed()

		workspace:draw()
	end
end



-------------------------------- UpperButtons ------------------------------------------------

local function upperButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, button.animationCurrentText

	-- Background
	screen.drawRectangle(button.x + 1, button.y + 1, button.width - 2, button.height - 2, bg, fg, " ")

	-- Upper
	screen.drawText(button.x, button.y, fg, "⢀" .. string.rep("⣀", button.width - 2) .. "⡀")

	-- Left
	screen.drawText(button.x, button.y + 1, fg, "⢸")

	-- Middle
	screen.drawText(math.floor(button.x + button.width / 2 - #button.text / 2), button.y + 1, fg, button.text)

	-- Right
	screen.drawText(button.x + button.width - 1, button.y + 1, fg, "⡇")

	-- Lower
	screen.drawText(button.x, button.y + button.height - 1, fg, "⠈" .. string.rep("⠉", button.width - 2) .. "⠁")

end

local function upperButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button:press()
	end
end

local function newUpperButton(x, y, width, text)
	local button = GUI.button(x, y, width, 3, 0x2D2D2D, 0xFFB600, 0x2D2D2D, 0x996D00, text)

	button.pressed = false
	button.draw = upperButtonDraw
	button.eventHandler = upperButtonEventHandler

	return button
end

-------------------------------- Write upper button ------------------------------------------------

local writeUpperButton = window:addChild(newUpperButton(23, 1, 9, "Write"))

writeUpperButton.onTouch = function()
	local filesystemDialog = GUI.addFilesystemDialog(workspace, true, 50, math.floor(window.height * 0.8), "Confirm", "Cancel", "File name", "/")
	
	filesystemDialog:setMode(GUI.IO_MODE_OPEN, GUI.IO_MODE_FILE)
	filesystemDialog:addExtensionFilter(".dfpwm")
	filesystemDialog:expandPath(paths.user.desktop)
	filesystemDialog:show()

	filesystemDialog.onSubmit = function(path)
		local tapeSize = tape.proxy.getSize()
		local tapeSpaceFree = tapeSize - tape.proxy.getPosition()
		local fileSize = filesystem.size(path)

		if fileSize > tapeSpaceFree then
			GUI.alert("Not enough space on tape")
			return
		end
		
		local file = filesystem.open(path, "rb")

		tape.proxy.stop()

		local bytesWritten, chunk = 0
		while true do
			chunk = file:read(8192)

			if not chunk then
				break
			end

			if not tape.proxy.isReady() then
				GUI.alert("Tape was removed during writing")
				break
			end

			tape.proxy.write(chunk)

			bytesWritten = bytesWritten + #chunk
			tapeWritingProgress = bytesWritten / fileSize
			workspace:draw()
		end

		file:close()
		tape.proxy.seek(-tape.proxy.getSize())
		tapeWritingProgress = nil
	end
end

-------------------------------- Write upper button ------------------------------------------------

local writeUpperButton = window:addChild(newUpperButton(33, 1, 9, "Label"))

writeUpperButton.onTouch = function()
	local container = GUI.addBackgroundContainer(workspace, true, true, title)
	
	local input = container.layout:addChild(GUI.input(1, 1, 36, 3, 0xE1E1E1, 0x696969, 0x969696, 0xE1E1E1, 0x2D2D2D, tape.proxy.getLabel() or "", "New label", false))

	input.onInputFinished = function()
		tape.proxy.setLabel(input.text)
		workspace:draw()
	end

	container.panel.onTouch = function()
		container:remove()
		workspace:draw()
	end

	workspace:draw()

	return container
end


-------------------------------- Display ------------------------------------------------

local display = window:addChild(GUI.object(23, 4, 33, 9))

local function displayDrawProgressBar(x, y, width, progress)
	local progressActiveWidth = math.floor(progress * width)

	screen.drawText(x, y, 0xE1E1E1, string.rep("━", progressActiveWidth))
	screen.drawText(x + progressActiveWidth, y, 0x4B4B4B, string.rep("━", width - progressActiveWidth))
end

display.draw = function(display)
	local upperText

	if tapeWritingProgress then
		upperText = "Writing in progress"

		local progressWidth = display.width - 4

		displayDrawProgressBar(
			math.floor(display.x + display.width / 2 - progressWidth / 2),
			math.floor(display.y + display.height / 2),
			progressWidth,
			tapeWritingProgress
		)

	else
		-- UpperText
		upperText = tape.proxy.getLabel()

		if not upperText or #upperText == 0 then
			upperText = "Untitled tape"
		end


		-- BPM
		local bpmText = tostring(math.floor(bpmMin + speedSlider.value * (bpmMax - bpmMin))) .. " bpm"
		local bpmWidth = #bpmText + 4
		
		local bpmX = display.x + display.width - 2 -bpmWidth
		local bpmY = display.y + display.height - 5

		screen.drawFrame(bpmX, bpmY, bpmWidth, 3, 0xE1E1E1)
		screen.drawText(bpmX + 2, bpmY + 1, 0xE1E1E1, bpmText)

		-- Lower track
		local progressWidth = display.width - 4
		local tapeSize = tape.proxy.getSize()

		displayDrawProgressBar(
			math.floor(display.x + display.width / 2 - progressWidth / 2),
			display.y + display.height - 2,
			progressWidth,
			tapeSize == 0 and 0 or tape.proxy.getPosition() / tapeSize
		)
	end

	-- UpperText
	upperText = text.limit(upperText, display.width - 2)
	screen.drawText(math.floor(display.x + display.width / 2 - #upperText / 2), display.y + 1, 0xE1E1E1, upperText)
end


-------------------------------- Needle search ------------------------------------------------

local needleSearch = window:addChild(GUI.object(25, 15, 29, 2))

-- needleSearch.draw = function()
-- 	screen.drawRectangle(needleSearch.x, needleSearch.y, needleSearch.width, needleSearch.height, 0xFF0000, 0x0, " ")
-- end

needleSearch.eventHandler = function(workspace, needleSearch, e1, e2, e3, e4)
	if e1 == "touch" and tape then
		local position = tape.proxy.getPosition()
		local newPosition = math.floor((e3 - needleSearch.x) / needleSearch.width * tape.proxy.getSize())

		tape.proxy.seek(newPosition - position)
	end
end

-------------------------------- Left mini button ------------------------------------------------

local function leftMiniButtonDraw(button)
	local bg, fg = button.animationCurrentBackground, button.animationCurrentText

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

local function leftMiniButtonEventHandler(workspace, button, e1, e2, e3, e4, e5)
	if e1 == "touch" then
		button:press()
	end
end

local function newLeftMiniButton(x, y, text)
	local button = GUI.button(x, y, 4, 3, 0x4B4B4B, 0xFFB600, 0x2D2D2D, 0xCC9200, text)

	button.draw = leftMiniButtonDraw
	button.eventHandler = leftMiniButtonEventHandler

	return button
end


-------------------------------- Pref/next tape button ------------------------------------------------

local previousTapeButton = window:addChild(newLeftMiniButton(2, 30, "<<"))
local nextTapeButton = window:addChild(newLeftMiniButton(7, 30, ">>"))

previousTapeButton.onTouch = function()
	incrementTape(false)
end

nextTapeButton.onTouch = function()
	incrementTape(true)
end

-------------------------------- Pref/next search button ------------------------------------------------

local previousSearchButton = window:addChild(newLeftMiniButton(2, 34, "<<"))
local nextSearchButton = window:addChild(newLeftMiniButton(7, 34, ">>"))

previousSearchButton.onTouch = function()
	
end

nextSearchButton.onTouch = function()
	
end


-------------------------------- Cue button ------------------------------------------------

local cueButton = window:addChild(newImageButton(2, window.height - 11, 9, 5, "Cue"))

cueButton.eventHandler = function(workspace, cueButton, e1)
	if e1 == "touch" then
		workspace:draw()
	end
end

-------------------------------- Play button ------------------------------------------------

local playButton = window:addChild(newImageButton(2, window.height - 5, 9, 5, "Play"))

playButton.blinking = true

playButton.eventHandler = function(workspace, playButton, e1)
	if e1 == "touch" then
		playButton.blinking = not playButton.blinking

		if playButton.blinking then
			tape.proxy.stop()
		else
			tape.proxy.play()
		end

		workspace:draw()
	end
end


-------------------------------- Events ------------------------------------------------

local jogIncrementSpeedMin = 0.05
local jogIncrementSpeedMax = 1
local jogIncrementUptime = 0

local overrideWindowEventHandler = window.eventHandler

window.eventHandler = function(workspace, window, e1, ...)
	overrideWindowEventHandler(workspace, window, e1, ...)

	local shouldDraw = false
	local isPlaying = getIsPlaying()

	local uptime = computer.uptime()

	if isPlaying then
		if uptime > jogIncrementUptime then
			-- Rotating jog
			currentJogIndex = currentJogIndex + 1

			if currentJogIndex > #jogImages then
				currentJogIndex = 1
			end

			jogIncrementUptime = uptime + (1 - speedSlider.value) * (jogIncrementSpeedMax - jogIncrementSpeedMin)
			shouldDraw = true
		end
	else
		jogIncrementUptime = uptime + (1 - speedSlider.value) * (jogIncrementSpeedMax - jogIncrementSpeedMin)
	end

	-- Blink
	if uptime > imageButtonBlinkUptime then
		imageButtonBlinkUptime = uptime + imageButtonBlinkInterval
		imageButtonBlink = not imageButtonBlink
		shouldDraw = true
	end

	if not e1 then
		-- Cheching if play button state was changed
		if isPlaying == playButton.blinking then
			playButton.blinking = not playButton.blinking
			shouldDraw = true
		end
	end

	if shouldDraw then
		workspace:draw()
	end
end


---------------------------------------------------------------------------------

updateTapes()

workspace:draw()
