
local ecs = require("ECSAPI")
local event = require("event")
local component = require("component")
local computer = component.computer
local debug

_G.fuckTheRainSound = true

if not component.isAvailable("debug") then
	ecs.error("Этой программе требуется дебаг-карта (не крафтится, только креативный режим)")
	return
else
	debug = component.debug
end

local world = debug.getWorld()

local function dro4er()
  if world.isRaining() or world.isThundering() then
  	world.setThundering(false)
  	world.setRaining(false)
  	if _G.fuckTheRainSound then computer.beep(1500) end
  end
end

local function addDro4er(howOften)
	_G.fuckTheRainDro4erID = event.timer(howOften, dro4er, math.huge)
end

local function removeDro4er()
	event.cancel(_G.fuckTheRainDro4erID)
end

local function ask()
	local cyka1, cyka2
	if _G.fuckTheRainDro4erID then cyka1 = "Отключить"; cyka2 = "Активировать" else cyka1 = "Активировать"; cyka2 = "Отключить" end

	local data = ecs.universalWindow("auto", "auto", 36, 0x373737, true,
		{"EmptyLine"},
		{"CenterText", ecs.colors.orange, "FuckTheRain"},
		{"EmptyLine"},
		{"CenterText", 0xffffff, "Данная программа работает в отдельном"},
		{"CenterText", 0xffffff, "потоке и атоматически отключает дождь,"},
		{"CenterText", 0xffffff, "если он начался"},
		{"EmptyLine"},
		{"Selector", 0xffffff, ecs.colors.orange, cyka1, cyka2},
		{"EmptyLine"},
		{"Switch", ecs.colors.orange, 0xffffff, 0xffffff, "Звуковой сигнал", _G.fuckTheRainSound},
		{"EmptyLine"},
		{"Slider", 0xffffff, ecs.colors.orange, 1, 100, 10, "Частота проверки: раз в ", " сек"},
		{"EmptyLine"},
		{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Отмена"}}
	)

	if data[4] == "OK" then


		if data[1] == "Активировать" then
			addDro4er(data[3])
		else
			removeDro4er()
		end

		_G.fuckTheRainSound = data[2] 
	end
end

ask()








