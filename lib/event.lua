local computer = require("computer")
local keyboard = require("keyboard")
local component = require("component")

local event, listeners, timers = {}, {}, {}
local lastInterrupt = -math.huge

local function call(callback, ...)
  local result, message = pcall(callback, ...)
  if not result and type(event.onError) == "function" then
    pcall(event.onError, message)
    return
  end
  return message
end

local function dispatch(signal, ...)
  if listeners[signal] then
    local function callbacks()
      local list = {}
      for index, listener in ipairs(listeners[signal]) do
        list[index] = listener
      end
      return list
    end
    for _, callback in ipairs(callbacks()) do
      if call(callback, signal, ...) == false then
        event.ignore(signal, callback) -- alternative method of removing a listener
      end
    end
  end
end

local function tick()
  local function elapsed()
    local list = {}
    for id, timer in pairs(timers) do
      if timer.after <= computer.uptime() then
        table.insert(list, timer.callback)
        timer.times = timer.times - 1
        if timer.times <= 0 then
          timers[id] = nil
        else
          timer.after = computer.uptime() + timer.interval
        end
      end
    end
    return list
  end
  for _, callback in ipairs(elapsed()) do
    call(callback)
  end
end

local function createPlainFilter(name, ...)
  local filter = table.pack(...)
  if name == nil and filter.n == 0 then
    return nil
  end

  return function(...)
    local signal = table.pack(...)
    if name and not (type(signal[1]) == "string" and signal[1]:match(name)) then
      return false
    end
    for i = 1, filter.n do
      if filter[i] ~= nil and filter[i] ~= signal[i + 1] then
        return false
      end
    end
    return true
  end
end

local function createMultipleFilter(...)
  local filter = table.pack(...)
  if filter.n == 0 then
    return nil
  end

  return function(...)
    local signal = table.pack(...)
    if type(signal[1]) ~= "string" then
      return false
    end
    for i = 1, filter.n do
      if filter[i] ~= nil and signal[1]:match(filter[i]) then
        return true
      end
    end
    return false
  end
end
-------------------------------------------------------------------------------

function event.cancel(timerId)
  checkArg(1, timerId, "number")
  if timers[timerId] then
    timers[timerId] = nil
    return true
  end
  return false
end

function event.ignore(name, callback)
  checkArg(1, name, "string")
  checkArg(2, callback, "function")
  if listeners[name] then
    for i = 1, #listeners[name] do
      if listeners[name][i] == callback then
        table.remove(listeners[name], i)
        if #listeners[name] == 0 then
          listeners[name] = nil
        end
        return true
      end
    end
  end
  return false
end

function event.listen(name, callback)
  checkArg(1, name, "string")
  checkArg(2, callback, "function")
  if listeners[name] then
    for i = 1, #listeners[name] do
      if listeners[name][i] == callback then
        return false
      end
    end
  else
    listeners[name] = {}
  end
  table.insert(listeners[name], callback)
  return true
end

function event.onError(message)
  local log = io.open("/tmp/event.log", "a")
  if log then
    log:write(message .. "\n")
    log:close()
  end
end

function event.pull(...)
  local args = table.pack(...)
  if type(args[1]) == "string" then
    return event.pullFiltered(createPlainFilter(...))
  else
    checkArg(1, args[1], "number", "nil")
    checkArg(2, args[2], "string", "nil")
    return event.pullFiltered(args[1], createPlainFilter(select(2, ...)))
  end
end

function event.pullMultiple(...)
  local seconds
  local args
  if type(...) == "number" then
    seconds = ...
    args = table.pack(select(2,...))
    for i=1,args.n do
      checkArg(i+1, args[i], "string", "nil")
    end
  else
    args = table.pack(...)
    for i=1,args.n do
      checkArg(i, args[i], "string", "nil")
    end
  end
  return event.pullFiltered(seconds, createMultipleFilter(table.unpack(args, 1, args.n)))

end

function event.pullFiltered(...)
  local args = table.pack(...)
  local seconds, filter

  if type(args[1]) == "function" then
    filter = args[1]
  else
    checkArg(1, args[1], "number", "nil")
    checkArg(2, args[2], "function", "nil")
    seconds = args[1]
    filter = args[2]
  end

  local deadline = seconds and
                   (computer.uptime() + seconds) or
                   (filter and math.huge or 0)
  repeat
    local closest = seconds and deadline or math.huge
    for _, timer in pairs(timers) do
      closest = math.min(closest, timer.after)
    end
    local signal = table.pack(computer.pullSignal(closest - computer.uptime()))
    if signal.n > 0 then
      dispatch(table.unpack(signal, 1, signal.n))
    end
    tick()

    event.takeScreenshot()

    ----------

    --Инициализируем протокол RCON
    _G.RCON = _G.RCON or nil
    --Если принимаем сообщеньку
    if signal[1] == "modem_message" then
      --Получаем понятные для простых смертных названия говна
      local localAddress, remoteAddress, port, distance, protocol, command = signal[2], signal[3], signal[4], signal[5], signal[6], signal[7]
      --Если порт подходит нам
      if port == 512 then
        --Если протокол сообщения подходит нам
        if protocol == "RCON" then
          --Если протокол RCON еще не активирован, т.е. равен nil
          if _G.RCON == nil then
            --Если у нас запрашивают управление
            if command == "iWantToControl" then
              --Спрашиваем на данном компе, разрешить ли управлять им
              local data = ecs.universalWindow("auto", "auto", 46, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x880000, "RCON"}, {"EmptyLine"}, {"CenterText", 0x262626, "Копьютер "..ecs.stringLimit("end", remoteAddress, 8).." запрашивает управление"}, {"EmptyLine"}, {"Button", {0x880000, 0xffffff, "Разрешить"}, {0xbbbbbb, 0xffffff, "Отклонить"}})
              if data[1] == "Разрешить" then
                component.modem.send(remoteAddress, port, "RCON", "acceptControl")
                --Разрешаем коннект
                _G.RCON = true
              else
                component.modem.send(remoteAddress, port, "RCON", "denyControl")
                --Отключаем RCON на данном устройстве, чтобы никакая мразь больше не коннектилась.
                _G.RCON = false
              end
            end
          --А если RCON активирован
          elseif _G.RCON == true then
            if command == "getResolution" then
              local xSize, ySize = component.gpu.getResolution()
              component.modem.send(remoteAddress, port, "RCON", xSize, ySize)
            elseif command == "execute" then
              shell.execute(signal[8])
            elseif command == "shutdown" then
              computer.shutdown()
            elseif command == "reboot" then
              computer.shutdown(true)
            elseif command == "key_down" then
              computer.pushSignal("key_down", component.getPrimary("keyboard").address, signal[8], signal[9], signal[10])
              --print("Пушу ивент кей довн ", component.getPrimary("keyboard").address, signal[8], signal[9], signal[10])
            elseif command == "touch" then
              computer.pushSignal("touch", remoteAddress, signal[8], signal[9], signal[10], signal[11])
            elseif command == "scroll" then
              computer.pushSignal("scroll", remoteAddress, signal[8], signal[9], signal[10], signal[11])
            elseif command == "clipboard" then
              computer.pushSignal("clipboard", remoteAddress, signal[8], signal[9])
            elseif command == "closeConnection" then
              ecs.error("Клиент под ID "..remoteAddress.." отключился. Закрываю сеть RCON.")
              _G.RCON = nil
            end
          end
        end
      end
    end

    ----------

    if event.shouldInterrupt() then
      lastInterrupt = computer.uptime()
      error("interrupted", 0)
    end
    if event.shouldSoftInterrupt() and (filter == nil or filter("interrupted", computer.uptime() - lastInterrupt))  then
      local awaited = computer.uptime() - lastInterrupt
      lastInterrupt = computer.uptime()
      return "interrupted", awaited
    end
    if not (seconds or filter) or filter == nil or filter(table.unpack(signal, 1, signal.n)) then
      return table.unpack(signal, 1, signal.n)
    end
  until computer.uptime() >= deadline
end

function event.shouldInterrupt()
  return computer.uptime() - lastInterrupt > 1 and
         keyboard.isControlDown() and
         keyboard.isAltDown() and
         keyboard.isKeyDown(keyboard.keys.c)
end

function event.shouldSoftInterrupt()
  return computer.uptime() - lastInterrupt > 1 and
         keyboard.isControlDown() and
         keyboard.isKeyDown(keyboard.keys.c)
end

function event.takeScreenshot()
  if keyboard.isKeyDown(100) or keyboard.isKeyDown(183) then
    computer.beep(1500)
    local screenshotPath = "screenshot.pic"
    image.screenshot(screenshotPath)
    computer.beep(2000)
    computer.beep(2000)
    computer.pushSignal("screenshot", screenshotPath)
  end
end

function event.timer(interval, callback, times)
  checkArg(1, interval, "number")
  checkArg(2, callback, "function")
  checkArg(3, times, "number", "nil")
  local id
  repeat
    id = math.floor(math.random(1, 0x7FFFFFFF))
  until not timers[id]
  timers[id] = {
    interval = interval,
    after = computer.uptime() + interval,
    callback = callback,
    times = times or 1
  }
  return id
end

-------------------------------------------------------------------------------

return event
