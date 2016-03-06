
local event = require("event")
local commandBlock = require("component").command_block
local nickname = "Pirnogion"

local function execute(command)
  commandBlock.setCommand(command)
  commandBlock.executeCommand()
end

local function tellraw(from, to, message)
  local text = "/tellraw @a[name=" .. to .. "] [\"\",{\"text\":\"\n\n\n\n\n\n\n\n\n\n\n\n" .. from .. "\",\"color\":\"gold\"},{\"text\":\": " .. message .. "\",\"color\":\"none\"}]"
  execute(text)
end

local function dro4er()
  local message = "Удали меня из ЧС и сделай сердечко руками. Мур-мур-мур. Заходи в скайп и решай вопрос своей обиды через меня, а не через посредников, будь мужиком. Все претензии лично, все лично. Этот спам вечен. Защита от анти-спама активирована: "
  --tellraw("Сообщение от Игоря", nickname, message .. math.random(1, 1000))

  execute("/spawn @a[name=" .. nickname .. "]")
end

event.timer(1, dro4er, math.huge)