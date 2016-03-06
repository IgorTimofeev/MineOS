
local event = require("event")
local component = require("component")
local commandBlock = component.command_block
local chatBox = component.chat_box

local nickname = "PaladinCVM"
local commanderNickname = "ECS"
local spamDelay = 1

local function execute(command)
  commandBlock.setCommand(command)
  commandBlock.executeCommand()
end

local function tellraw(from, to, message)
  local text = "/tellraw @a[name=" .. to .. "] [\"\",{\"text\":\"\n\n\n\n\n\n\n\n\n\n\n\n" .. from .. "\",\"color\":\"gold\"},{\"text\":\": " .. message .. "\",\"color\":\"none\"}]"
  execute(text)
end

local function spamDro4er()
  local message = "Удали из ЧС в скайпе и позвони мне, мой сладкий!" .. math.random(1, 1000)
  tellraw("Сообщение от Игоря", nickname, message)
  execute("/spawn @a[name=" .. nickname .. "]")
end

local function chatDro4er(...)
	local e = {...}
	if e[3] == commanderNickname then
		if e[4] == "активировать спам-бота" then
			chatBox.say("Спам-бот активирован на цель \"" .. nickname .. "\". Версия 2.4a")
			_G.spamDro4erID = event.timer(1, spamDro4er, math.huge)
		elseif e[4] == "деактивировать спам-бота" and _G.spamDro4erID then
			chatBox.say("Спам-бот на цель \"" .. nickname .. "\" деактивирован.")
			event.cancel(_G.spamDro4erID)
			_G.spamDro4erID = nil
		end
	end
end

event.listen("chat_message", chatDro4er)




