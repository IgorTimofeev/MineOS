
-- This is a fast OpenComputers event processing library written as an alternative
-- for its' OpenOS analogue which has become too slow and inefficient in the latest updates

--------------------------------------------------------------------------------------------------------

local computer = require("computer")

local event, handlers, interruptingKeysDown, lastInterrupt = {
	interruptingEnabled = true,
	interruptingDelay = 1,
	interruptingKeyCodes = {
		[29] = true,
		[46] = true,
		[56] = true
	},
	push = computer.pushSignal
}, {}, {}, 0

local computerPullSignal, computerUptime, mathHuge, mathMin, skipSignalType = computer.pullSignal, computer.uptime, math.huge, math.min

--------------------------------------------------------------------------------------------------------

function event.addHandler(callback, signalType, times, interval)
	checkArg(1, callback, "function")
	checkArg(2, signalType, "string", "nil")
	checkArg(3, times, "number", "nil")
	checkArg(4, nextTriggerTime, "number", "nil")

	local ID
	repeat
		ID = math.random(0x7FFFFFFF)
	until not handlers[ID]

	handlers[ID] = {
		signalType = signalType,
		callback = callback,
		times = times or mathHuge,
		interval = interval,
		nextTriggerTime = interval and computerUptime() + interval or 0
	}

	return ID
end

function event.removeHandler(ID)
	checkArg(1, ID, "number")

	if handlers[ID] then
		handlers[ID] = nil

		return true
	else
		return false, "No registered handlers found for ID " .. ID
	end
end

function event.getHandler(ID)
	checkArg(1, ID, "number")

	if handlers[ID] then
		return handlers[ID]
	else
		return false, "No registered handlers found for ID " .. ID
	end
end

--------------------------------------------------------------------------------------------------------

function event.listen(signalType, callback)
	checkArg(1, signalType, "string")
	checkArg(2, callback, "function")

	for ID, handler in pairs(handlers) do
		if handler.callback == callback and handler.signalType == signalType then
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

	return false, "No registered listeners found for signal \"" .. signalType .. "\" and callback method " .. tostring(callback)
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

function event.skip(signalType)
	skipSignalType = signalType
end

function event.pull(arg1, arg2)
	local arg1Type, uptime, timeout, preferredTimeout, signalType, signalData = type(arg1), computerUptime()
	if arg1Type == "string" then
		preferredTimeout, signalType = mathHuge, arg1
	elseif arg1Type == "number" then
		preferredTimeout, signalType = arg1, type(arg2) == "string" and arg2 or nil
	end
	
	local deadline = uptime + (preferredTimeout or mathHuge)
	repeat
		-- Determining pullSignal timeout
		timeout = deadline
		for ID, handler in pairs(handlers) do
			if handler.nextTriggerTime > 0 then
				timeout = mathMin(timeout, handler.nextTriggerTime)
			end
		end

		-- Pulling signal data
		signalData = { computerPullSignal(timeout - computerUptime()) }
				
		-- Handlers processing
		for ID, handler in pairs(handlers) do
			if handler.times > 0 then
				uptime = computerUptime()

				if
					(not handler.signalType or handler.signalType == signalData[1]) and
					handler.nextTriggerTime <= uptime
				then
					handler.times = handler.times - 1
					if handler.nextTriggerTime > 0 then
						handler.nextTriggerTime = uptime + handler.interval
					end

					-- Callback running
					pcall(handler.callback, table.unpack(signalData))
				end
			else
				handlers[ID] = nil
			end
		end

		-- Program interruption support. It's faster to do it here instead of registering handlers
		if signalData[1] == "key_down" or signalData[1] == "key_up" and event.interruptingEnabled then
			-- Analysing for which interrupting key is pressed - we don't need keyboard API for this
			if event.interruptingKeyCodes[signalData[4]] then
				interruptingKeysDown[signalData[4]] = signalData[1] == "key_down" and true or nil
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
			if signalData[1] == skipSignalType then
				skipSignalType = nil
			else
				return table.unpack(signalData)
			end
		end
	until uptime >= deadline
end

--------------------------------------------------------------------------------------------------------

return event
