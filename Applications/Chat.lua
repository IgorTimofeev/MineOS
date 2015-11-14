
----------------------------------------------------------------------------------------------------------------------------------

local components = require("component")
local event = require("event")
local unicode = require("unicode")
local sides = require("sides")
local sha = require("SHA2")
local ecs = require("ECSAPI")
local commandBlock = components.command_block
local gpu = components.gpu
local chat = components.chat_box
local redstone = component.redstone

local administrators = {"IT", "Pornogion"}

local votes = {
	mute = {
	},
}
local voteTime = 5
local votesToDoSomething = 1

----------------------------------------------------------------------------------------------------------------------------------

local function execute(command)
	commandBlock.setCommand(command)
	commandBlock.executeCommand()
end

local function tellraw(toPlayer, text)
	execute("/tellraw " .. toPlayer .. " [\"\",{\"text\":\" Сервер\",\"color\":\"gold\"},{\"text\":\": " .. text .. "\",\"color\":\"none\"}]")
end

local function parseEventData(eventData)
	local nickname = eventData[3]

	local words = {}

	for word in string.gmatch(eventData[4], "[^%s]*") do
		if word ~= " " and word ~= "" then
			table.insert(words, word)
		end
	end

	return nickname, words
end

local function getCount(massiv)
	local count = 0
	for key in pairs(massiv) do
		count = count + 1
	end
	return count
end

local function analyzeMutes()
	for nameToMute in pairs(votes.mute) do
		if getCount(votes.mute[nameToMute]) >= votesToDoSomething then			
			tellraw("@a","По решению большинства игроку " .. nameToMute .. " дан мут.")	
			execute("/mute " .. nameToMute)
			votes.mute[nameToMute] = nil
		else
			tellraw("@a", "Голосование за кик игрока " .. nameToMute .. " отменяется, недостаточно голосов.")
			votes.mute[nameToMute] = nil
		end
	end
end

local function synonym(baseWord, ...)
	local synonyms = {...}
	for i = 1, #synonyms do
		if baseWord == synonyms[i] then return true end
	end
	return false
end

local function checkNicknameForAdminRights(nickname)
	local success = false
	for i = 1, #administrators do
		if nickname == administrators[i] then success = true; break end
	end

	if not success then
		tellraw("@a[name=" .. nickname .. "]", "Только админстраторы сервера имеют доступ к данной команде.")
	end

	return success
end

----------------------------------------------------------------------------------------------------------------------------------

ecs.setScale(0.8)
ecs.prepareToExit()
tellraw("@a","Система поддержки чата инициализирована.")
print(" "); print(" Ожидаю команд игроков..."); print(" ")


while true do
	local eventData = {event.pull()}
	if eventData[1] == "chat_message" then

		local nickname, words = parseEventData(eventData)
		print(eventData[3] .. ": " .. eventData[4])
		-- print("Команды: " .. table.concat(words, ","))

		if words[1] == "сервер" or words[1] == "Сервер" or words[1] == "серв" or words[1] == "Серв" then
			
			if words[2] == "замуть" then
				votes.mute[words[3]] = votes.mute[words[3]] or {}
				votes.mute[words[3]][nickname] = true
				event.timer(voteTime, analyzeMutes)
				tellraw("@a","Начинается голосование за мут игрока " .. words[3] .. ", количество голосов: " .. getCount(votes.mute[words[3]]) .. " из " .. votesToDoSomething .. ".")
			
			elseif words[2] == "телепортни" or words[2] == "тпни" or words[2] == "тп" or words[2] == "телепортируй" then

				if words[3] == "на" and words[4] == "спавн" then
					execute("/spawn " .. nickname)
				else
					tellraw("@a[name=" .. nickname .. "]", "Неизвестная локация для телепортации.")
				end

			elseif words[2] == "вылечи" or words[2] == "похиль" or words[2] == "хильни" then
				execute("/heal " .. nickname)
				tellraw("@a[name=" .. nickname .. "]", "Держи хилку!")
		
			elseif (words[2] == "накорми") or (words[2] == "дай" and (words[3] == "пожрать" or words[3] == "похавать")) then
				execute("/feed " .. nickname)
				tellraw("@a[name=" .. nickname .. "]", "Держи хавку!")
			
			elseif words[2] == "дай" then
				if words[3] == "ресов" then
					tellraw("@a[name=" .. nickname .. "]", "Ну на.")
					execute("/give @a[name=" .. nickname .. "] minecraft:dirt " .. math.random(1, 100))

				else
					tellraw("@a[name=" .. nickname .. "]", "Чего тебе дать?")
				end 

			elseif words[2] == "как" and words[3] == "дела" then

				local dela = {
					"Лови молнию в ебло, заебал с допросами.",
					"Хуево пиздец. Сейчас такую катку всрал - играл за Инвокера, вышел с мида со счетом 7 0, а в итоге всосали гейм за 20 минут.",
					"Ну, более-менее. Даже несмотря на то, что какие-то пидоры все время отвлекают от мирного афк в чате.",
					"Нормально. Сам как?",
					"Дела заебок, сегодня вытащил матч за войда с тремя ДЦП в тиме. А у тебя как успехи?",
					"Отлично! Накодил вон потный скрипт, сейчас буду тестировать.                            error[320] in cyka.lua: attempt to index countOfFatMothers (a nil value)               Бля.",
					"Старая шлюха родила! Иди на хуй со своими расспросами.",
				}

				local number = math.random(1, #dela)
				if number == 1 then execute("/shock " .. nickname) end
				tellraw("@a", dela[number])

			elseif words[2] == "скажи" and (words[3] == "админу" or words[3] == "админам") then
				local message = {}
				for i = 4, #words do
					table.insert(message, words[i])
				end
				for i = 1, #administrators do
					tellraw("@a[name=" .. administrators[i] .. "]", "Вам отправили личное сообщение как администратору. Прочтите через /mail read.")
					execute("/mail send " .. administrators[i] .. " <От " .. nickname .. "> " .. table.concat(message, " "))
				end
			
			elseif words[2] == "очисти" and words[3] == "чат" then
				tellraw("@a[name=" .. nickname .. "]", string.rep(" ", 3000))
				tellraw("@a[name=" .. nickname .. "]", "Чат очищен.")

			elseif synonym(words[2], "вруби", "включи") and synonym(words[3], "электричество", "свет") then
				if checkNicknameForAdminRights(nickname) then
					tellraw("@a", "Серверное освещение включено по приказу " .. nickname)
					redstone.setOutput(sides.bottom, 15)
				end

			elseif synonym(words[2], "выруби", "выключи", "отключи") and synonym(words[3], "электричество", "свет") then
				if checkNicknameForAdminRights(nickname) then
					tellraw("@a", "Серверное освещение отключено по приказу " .. nickname)
					redstone.setOutput(sides.bottom, 0)
				end

			elseif synonym(words[2], "хеш", "зашифруй", "хешируй") then
				if words[3] then
					tellraw("@a[name=" .. nickname .. "]", "SHA2-256 HASH: " .. sha.hash(words[3]))
				else
					tellraw("@a[name=" .. nickname .. "]", "Что тебе захешировать?")
				end 

			elseif synonym(words[2], "сделай", "вруби") and synonym(words[3], "день") then
				if checkNicknameForAdminRights(nickname) then
					tellraw("@a", "Установлено дневное время по приказу " .. nickname)
					execute("/time set 0")
				end

			elseif synonym(words[2], "сделай", "вруби") and synonym(words[3], "ночь") then
				if checkNicknameForAdminRights(nickname) then
					tellraw("@a", "Установлено ночное время по приказу " .. nickname)
					execute("/time set 18000")
				end

			elseif synonym(words[2], "выруби", "отключи") and synonym(words[3], "дождь") then
				if checkNicknameForAdminRights(nickname) then
					tellraw("@a", "Дождь отключен по приказу " .. nickname)
					execute("/minecraft:weather clear")
				end
			
			elseif synonym(words[2], "отпизди", "ебни", "убей", "отхуесось", "уничтожь") then
				if checkNicknameForAdminRights(nickname) then
					if words[3] then
						tellraw("@a", "Как прикажешь, мой повелитель. " .. words[3] .. " был убит во имя Высшей Цели.")
						execute("/kill " .. words[3])
					else
						tellraw("@a[name=" .. nickname .. "]", "Скажи только имя - и я уничтожу его.")
					end
				end

			elseif synonym(words[2], "шанс", "вероятность") then
				if words[3] then
					local strings = {
						"Вероятность ",
						"Вероятность примерно ",
						"Приблизительно ",
						"Около ",
						"Вероятность почти ",
					}

					tellraw("@a", strings[math.random(1, #strings)] .. math.random(0, 100) .. "%")
				else
					tellraw("@a[name=" .. nickname .. "]", "Не указана цель поиска вероятности.")
				end

			elseif words[2] then
				tellraw("@a[name=" .. nickname .. "]", "Команда '" .. (words[2]) .. "' не распознана.")
			else
				tellraw("@a[name=" .. nickname .. "]", "Чего надо?")
			end
		
		end

	end
end










