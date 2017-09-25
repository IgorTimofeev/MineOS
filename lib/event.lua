
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
		-- require("ECSAPI").error("CYKA: " .. tostring(errorMessage))
	end
}

local lastInterrupt, interruptingKeysDown = 0, {}

--------------------------------------------------------------------------------------------------------

function event.register(callback, signalType, times, interval)
	checkArg(1, callback, "function")
	checkArg(2, signalType, "string", "nil")
	checkArg(3, times, "number", "nil")
	checkArg(4, nextTriggerTime, "number", "nil")

	local ID
	while not ID do
		ID = math.random(1, 0x7FFFFFFF)
		for handlerIndex = 1, #event.handlers do
			if event.handlers[handlerIndex].ID == ID then
				ID = nil
				break
			end
		end
	end

	local handler = {
		alive = true,
		ID = ID,
		signalType = signalType,
		callback = callback,
		times = times or math.huge,
		interval = interval,
		nextTriggerTime = interval and (computer.uptime() + interval) or nil
	}
	
	table.insert(event.handlers, handler)

	return handler
end

function event.cancel(ID)
	checkArg(1, ID, "number")

	for handlerIndex = 1, #event.handlers do
		if event.handlers[handlerIndex].ID == ID then
			event.handlers[handlerIndex].alive = false
			return true
		end
	end

	return false, "No registered handlers found for ID \"" .. ID .. "\""
end

--------------------------------------------------------------------------------------------------------

function event.listen(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for handlerIndex = 1, #event.handlers do
		if event.handlers[handlerIndex].callback == callback then
			return false, "Callback method " .. tostring(callback) .. " is already registered"
		end
	end

	event.register(callback, signalType)
end

function event.ignore(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for handlerIndex = 1, #event.handlers do
		if event.handlers[handlerIndex].signalType == signalType and event.handlers[handlerIndex].callback == callback then
			event.handlers[handlerIndex].alive = false
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

	return event.register(callback, nil, times, interval).ID
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

local function eventTick(timeout)
	local eventData, handlerIndex, uptime = {computer.pullSignal(timeout)}, 1, computer.uptime()
	
	while handlerIndex <= #event.handlers do
		if event.handlers[handlerIndex].times > 0 and event.handlers[handlerIndex].alive then
			if
				(not event.handlers[handlerIndex].signalType or event.handlers[handlerIndex].signalType == eventData[1]) and
				(not event.handlers[handlerIndex].nextTriggerTime or event.handlers[handlerIndex].nextTriggerTime <= uptime)
			then
				executeHandlerCallback(event.handlers[handlerIndex].callback, table.unpack(eventData))
				uptime = computer.uptime()

				event.handlers[handlerIndex].times = event.handlers[handlerIndex].times - 1

				if event.handlers[handlerIndex].nextTriggerTime then
					event.handlers[handlerIndex].nextTriggerTime = uptime + event.handlers[handlerIndex].interval
				end
			end

			handlerIndex = handlerIndex + 1
		else
			table.remove(event.handlers, handlerIndex)
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

	return eventData
end

local function getNearestHandlerTriggerTime()
	local nearestTriggerTime
	for handlerIndex = 1, #event.handlers do
		if event.handlers[handlerIndex].nextTriggerTime then
			nearestTriggerTime = math.min(nearestTriggerTime or math.huge, event.handlers[handlerIndex].nextTriggerTime)
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
	
	local deadline = computer.uptime() + (timeout or math.huge)
	while computer.uptime() <= deadline do
		local eventData = eventTick((getNearestHandlerTriggerTime() or deadline) - computer.uptime())
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
