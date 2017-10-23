
-- This is a fast OpenComputers event processing library written as an alternative
-- for its' OpenOS analogue which has become too slow and inefficient in the latest updates

--------------------------------------------------------------------------------------------------------

local computer = require("computer")

local event = {
	push = computer.pushSignal,
	handlers = {},
	interruptingEnabled = true,
	interruptingDelay = 1,
	interruptingKeyCodes = {
		[29] = true,
		[46] = true,
		[56] = true
	},
	onError = function(errorMessage)
		-- require("GUI").error("CYKA: " .. tostring(errorMessage))
	end
}

local lastInterrupt, interruptingKeysDown = 0, {}

--------------------------------------------------------------------------------------------------------

function event.register(callback, signalType, times, interval)
	checkArg(1, callback, "function")
	checkArg(2, signalType, "string", "nil")
	checkArg(3, times, "number", "nil")
	checkArg(4, nextTriggerTime, "number", "nil")

	local newID
	while not newID do
		newID = math.random(1, 0x7FFFFFFF)
		for ID, handler in pairs(event.handlers) do
			if ID == newID then
				newID = nil
				break
			end
		end
	end

	event.handlers[newID] = {
		alive = true,
		signalType = signalType,
		callback = callback,
		times = times or math.huge,
		interval = interval,
		nextTriggerTime = interval and (computer.uptime() + interval) or nil
	}

	return newID
end

--------------------------------------------------------------------------------------------------------

function event.listen(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for ID, handler in pairs(event.handlers) do
		if handler.callback == callback then
			return false, "Callback method " .. tostring(callback) .. " is already registered"
		end
	end

	event.register(callback, signalType)
	return true
end

function event.ignore(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for ID, handler in pairs(event.handlers) do
		if handler.signalType == signalType and handler.callback == callback then
			handler.alive = false
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

	return event.register(callback, nil, times, interval)
end

function event.cancel(ID)
	checkArg(1, ID, "number")

	if event.handlers[ID] then
		event.handlers[ID].alive = false
		return true
	else
		return false, "No registered handlers found for ID \"" .. ID .. "\""
	end
end

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

local function getNearestHandlerTriggerTime()
	local nearestTriggerTime
	for ID, handler in pairs(event.handlers) do
		if handler.nextTriggerTime then
			nearestTriggerTime = math.min(nearestTriggerTime or math.huge, handler.nextTriggerTime)
		end
	end

	return nearestTriggerTime
end

function event.skip(signalType)
	event.skipSignalType = signalType
end

function event.pull(...)
	local args = {...}

	local args1Type, timeout, signalType = type(args[1])
	if args1Type == "string" then
		timeout, signalType = math.huge, args[1]
	elseif args1Type == "number" then
		timeout, signalType = args[1], type(args[2]) == "string" and args[2] or nil
	end
	
	local uptime, eventData = computer.uptime()
	local deadline = uptime + (timeout or math.huge)
	while uptime <= deadline do
		uptime = computer.uptime()
		eventData = {computer.pullSignal((getNearestHandlerTriggerTime() or deadline) - computer.uptime())}
		
		-- Handlers processing
		for ID, handler in pairs(event.handlers) do
			if handler.times > 0 and handler.alive then
				if
					(not handler.signalType or handler.signalType == eventData[1]) and
					(not handler.nextTriggerTime or handler.nextTriggerTime <= uptime)
				then
					executeHandlerCallback(handler.callback, table.unpack(eventData))
					uptime = computer.uptime()

					handler.times = handler.times - 1

					if handler.nextTriggerTime then
						handler.nextTriggerTime = uptime + handler.interval
					end
				end
			else
				event.handlers[ID] = nil
			end
		end

		-- Interruption support
		if event.interruptingEnabled then
			-- Analysing for which interrupting key is pressed - we don't need keyboard API for this
			if eventData[1] == "key_down" then
				if event.interruptingKeyCodes[eventData[4]] then
					interruptingKeysDown[eventData[4]] = true
				end
			elseif eventData[1] == "key_up" then
				if event.interruptingKeyCodes[eventData[4]] then
					interruptingKeysDown[eventData[4]] = nil
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
		if eventData[1] and (not signalType or signalType == eventData[1]) then
			if eventData[1] == event.skipSignalType then
				event.skipSignalType = nil
			else
				return table.unpack(eventData)
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
