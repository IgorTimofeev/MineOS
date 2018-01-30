
-- This is a fast OpenComputers event processing library written as an alternative
-- for its' OpenOS analogue which has become too slow and inefficient in the latest updates

--------------------------------------------------------------------------------------------------------

local computer = require("computer")

local event, handlers, interruptingKeysDown, lastInterrupt = {
	push = computer.pushSignal,
	interruptingEnabled = true,
	interruptingDelay = 1,
	interruptingKeyCodes = {
		[29] = true,
		[46] = true,
		[56] = true
	},
	onError = function(errorMessage)
		-- require("GUI").error("Event handler error: \"" .. tostring(errorMessage) .. "\"")
	end
}, {}, {}, 0

--------------------------------------------------------------------------------------------------------

function event.addHandler(callback, signalType, times, interval)
	checkArg(1, callback, "function")
	checkArg(2, signalType, "string", "nil")
	checkArg(3, times, "number", "nil")
	checkArg(4, nextTriggerTime, "number", "nil")

	local ID = math.random(1, 0x7FFFFFFF)
	while handlers[ID] do
		ID = math.random(1, 0x7FFFFFFF)
	end

	handlers[ID] = {
		signalType = signalType,
		callback = callback,
		times = times or math.huge,
		interval = interval,
		nextTriggerTime = interval and (computer.uptime() + interval) or nil
	}

	return ID
end

function event.removeHandler(ID)
	checkArg(1, ID, "number")

	if handlers[ID] then
		handlers[ID] = nil
		return true
	else
		return false, "No registered handlers found for ID \"" .. ID .. "\""
	end
end

function event.getHandler(ID)
	checkArg(1, ID, "number")

	if handlers[ID] then
		return handlers[ID]
	else
		return false, "No registered handlers found for ID \"" .. ID .. "\""
	end
end

--------------------------------------------------------------------------------------------------------

function event.listen(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for ID, handler in pairs(handlers) do
		if handler.callback == callback then
			return false, "Callback method " .. tostring(callback) .. " is already registered"
		end
	end

	event.addHandler(callback, signalType)
	return true
end

function event.ignore(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for ID, handler in pairs(handlers) do
		if handler.signalType == signalType and handler.callback == callback then
			handlers[ID] = nil
			return true
		end
	end

	return false, "No registered listeners found for signal \"" .. signalType .. "\" and callback method \"" .. tostring(callback)
end

--------------------------------------------------------------------------------------------------------

function event.timer(interval, callback, times)
	checkArg(1, interval, "number")
	checkArg(2, callback, "function")
	checkArg(3, times, "number", "nil")

	return event.addHandler(callback, nil, times or 1, interval)
end

event.cancel = event.removeHandler

--------------------------------------------------------------------------------------------------------

local function executeHandlerCallback(callback, ...)
	local success, result = pcall(callback, ...)
	if success then
		return result
	else
		if type(event.onError) == "function" then
			pcall(event.onError, result)
		end
	end
end

function event.skip(signalType)
	event.skipSignalType = signalType
end

function event.pull(...)
	local args = {...}

	local args1Type, preferredTimeout, signalType = type(args[1])
	if args1Type == "string" then
		preferredTimeout, signalType = math.huge, args[1]
	elseif args1Type == "number" then
		preferredTimeout, signalType = args[1], type(args[2]) == "string" and args[2] or nil
	end
	
	local uptime, signalData, timeout = computer.uptime()
	local deadline = uptime + (preferredTimeout or math.huge)
	
	while uptime <= deadline do
		-- Determining pullSignal timeout
		timeout = deadline
		for ID, handler in pairs(handlers) do
			if handler.nextTriggerTime then
				timeout = math.min(timeout, handler.nextTriggerTime)
			end
		end

		-- Pulling signal data
		signalData = { computer.pullSignal(timeout - computer.uptime()) }
				
		-- Handlers processing
		for ID, handler in pairs(handlers) do
			if handler.times > 0 then
				uptime = computer.uptime()

				if
					(not handler.signalType or handler.signalType == signalData[1]) and
					(not handler.nextTriggerTime or handler.nextTriggerTime <= uptime)
				then
					handler.times = handler.times - 1
					if handler.nextTriggerTime then
						handler.nextTriggerTime = uptime + handler.interval
					end

					executeHandlerCallback(handler.callback, table.unpack(signalData))
				end
			else
				handlers[ID] = nil
			end
		end

		-- Interruption support
		if event.interruptingEnabled then
			-- Analysing for which interrupting key is pressed - we don't need keyboard API for this
			if signalData[1] == "key_down" then
				if event.interruptingKeyCodes[signalData[4]] then
					interruptingKeysDown[signalData[4]] = true
				end
			elseif signalData[1] == "key_up" then
				if event.interruptingKeyCodes[signalData[4]] then
					interruptingKeysDown[signalData[4]] = nil
				end
			end

			local shouldInterrupt = true
			for keyCode in pairs(event.interruptingKeyCodes) do
				if not interruptingKeysDown[keyCode] then
					shouldInterrupt = false
				end
			end
			
			if shouldInterrupt and uptime - lastInterrupt > event.interruptingDelay then
				lastInterrupt = uptime
				error("interrupted", 0)
			end
		end
		
		-- Loop-breaking conditions
		if signalData[1] and (not signalType or signalType == signalData[1]) then
			if signalData[1] == event.skipSignalType then
				event.skipSignalType = nil
			else
				return table.unpack(signalData)
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------

local doubleTouchInterval, lastTouchX, lastTouchY, lastTouchButton, lastTouchUptime, lastTouchScreenAddress = 0.3, 0, 0, 0, 0

event.listen("touch", function(signalType, screenAddress, x, y, button, user)
	local uptime = computer.uptime()
	
	if lastTouchX == x and lastTouchY == y and lastTouchButton == button and lastTouchScreenAddress == screenAddress and uptime - lastTouchUptime <= doubleTouchInterval then
		event.skip("touch")
		computer.pushSignal("double_touch", screenAddress, x, y, button, user)
	end

	lastTouchX, lastTouchY, lastTouchButton, lastTouchUptime, lastTouchScreenAddress = x, y, button, uptime, screenAddress
end)

--------------------------------------------------------------------------------------------------------

return event
