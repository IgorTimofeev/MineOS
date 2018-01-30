local os = require("os")
local term = require("term")
local event = require("event")
local component = require("component")
local gpu = component.gpu
math.randomseed(os.time())
local version = "Cube v1.0"
local level = {}
local doors = {}
local indicator={}
local nick_player
local markColor = {0xff0000, 0xffff00, 0x00ff00, 0x00ffff, 0x0000ff, 0xff00ff, 0xffffff}
local playerColor = 3
local sx,sy = gpu.getResolution()
sx, sy = math.modf(sx/4), math.modf(sy/2)		-- точка отступа/координата игрока на экране (статичные)/центр событий
local px,py = 3,3					-- относительные координаты игрока в комнате
local min_map, max_map = 1, 1000	-- ограничители номеров комнат, чтобы сильно не запутаться при прохождении
level[1] = {number=1, color = 0xffffff,  mark=false} -- цель игры - попасть в эту комнату
-------------------------------------------------------------------------------------
----------------------- Генерация случайных формул для дверей -----------------------
local rand_1, rand_2 ,rand_3, rand_4
while true do
	rand_1, rand_2 ,rand_3, rand_4 = math.random(1,2), math.random(10,30), math.random(1,2), math.random(10,30)
	if rand_1~=rand_3 and rand_2~=rand_4 then break end
end
formula={}
formula[1]=function(n) return n*rand_1 + rand_2 end
formula[2]=function(n) return n*rand_3 + rand_4 end
formula[-1]=function(n) return (n - rand_2)/rand_1 end
formula[-2]=function(n) return (n - rand_4)/rand_3 end
-------------------------------------------------------------------------------------
---------------------- Возвращает или генерирует новую комнату ----------------------
function gen_level(i)
	i = tonumber(i)
	if not level[i] then
		level[i]={number=i, color = math.random(0x000000, 0xffffff), mark=false}
	end
	return level[i]
end
-------------------------------------------------------------------------------------
-------------------------- Проверка, существует ли комната --------------------------
function proverka(x,y) -- где x номер формулы, y номер текущей комнаты
	local number = formula[x](y)
	return number >= min_map and number <= max_map and number == math.modf(number)
end
-------------------------------------------------------------------------------------
---------------------------- Генерация статистики комнат ----------------------------
function sorting(sorting_table, not_sorting_table)
	local trash_table={}
	while true do
		if #not_sorting_table==0 then
			break
		else
			local new_level = not_sorting_table[1]
			local power = true
			for i=1, #sorting_table do
				if sorting_table[i][1]== new_level[1] then
					power = false
					if new_level[2] < sorting_table[i][2] then
						sorting_table[i][2]=new_level[2]
						if proverka(1,new_level[1]) then
							trash_table[#trash_table+1] = {formula[1](new_level[1]), new_level[2]+1}
						end
						if proverka(2,new_level[1]) then
							trash_table[#trash_table+1] = {formula[2](new_level[1]), new_level[2]+1}
						end
						if proverka(-1,new_level[1]) then
							trash_table[#trash_table+1] = {formula[-1](new_level[1]), new_level[2]+1}
						end
						if proverka(-2,new_level[1]) then
							trash_table[#trash_table+1] = {formula[-2](new_level[1]), new_level[2]+1}
						end
					end
					table.remove(not_sorting_table,1)
				end
			end
			if power then
				sorting_table[#sorting_table+1] = new_level
				table.remove(not_sorting_table,1)
				if proverka(1,new_level[1]) then
					not_sorting_table[#not_sorting_table+1] = {formula[1](new_level[1]), new_level[2]+1}
				end
				if proverka(2,new_level[1]) then
					not_sorting_table[#not_sorting_table+1] = {formula[2](new_level[1]), new_level[2]+1}
				end
				if proverka(-1,new_level[1]) then
					not_sorting_table[#not_sorting_table+1] = {formula[-1](new_level[1]), new_level[2]+1}
				end
				if proverka(-2,new_level[1]) then
					not_sorting_table[#not_sorting_table+1] = {formula[-2](new_level[1]), new_level[2]+1}
				end
			end
		end
	end
	return sorting_table, trash_table
end

-- первая сортировка
local not_sorting_tb, trash_tb={}
not_sorting_tb[1]={1,0}
local sorting_tb, trash_tb = sorting({}, not_sorting_tb)

-- последующие сортировки
while true do
	not_sorting_tb = trash_tb
	sorting_tb, trash_tb = sorting(sorting_tb, not_sorting_tb)
	if #trash_tb == 0 then break end
end

-- очищаем память
not_sorting_tb, trash_tb = nil, nil

-- перестраиваем таблицу
local stat_table={}
for i=1, #sorting_tb do
	stat_table[sorting_tb[i][1]]=sorting_tb[i][2]
end
-------------------------------------------------------------------------------------
------------------ Находим номер самой удалённой комнаты от выхода ------------------
local j=1
for i=1, #sorting_tb do
	if sorting_tb[i][2]>sorting_tb[j][2] then
		j=i
	end
end
-------------------------------------------------------------------------------------
----------------------- Устанавливаем номер стартовой комнаты -----------------------
local chamber = gen_level(sorting_tb[j][1])

-- запишем количество комнат в игре
local max_table, max_level = #sorting_tb, sorting_tb[j][2]

-- удалим из памяти ненужную таблицу
sorting_tb = nil
-------------------------------------------------------------------------------------
--------------------------- Переставляет двери в комнате ----------------------------
function reload_doors()
	local rezerv={}
	for i=1,4 do -- занесём двери в базу данных, чтобы знать использованные формулы
		if doors[i] then
			rezerv[#rezerv+1]=doors[i]
		end
	end
	for i=1,4 do -- перебираем все 4 двери
		if not doors[i] then
			while true do
				local rand = math.random(-2,2)
				local rezerv_2 = 0
				if rand ~= 0 then
					if #rezerv > 0 then -- проверка, есть ли комната с такой же формулой
						for j=1, #rezerv do
							if rezerv[j] == rand then break else rezerv_2 = rezerv_2 + 1 end
						end
					end
					if rezerv_2 == #rezerv then -- если нет повторяющихся формул, то присваивается данная формула
						doors[i] = rand
						rezerv[#rezerv+1]=rand
						break
					end
				end
			end
		end
	end
end
-- //данная функция достаточно сложна чтобы запутаться
-------------------------------------------------------------------------------------
---------------------------------- Рисования меток ----------------------------------
function mark_print(nx, ny, number)
	if level[number].mark then
		for i=1, #level[number].mark do
			gpu.setBackground(level[number].mark[i][3])
			gpu.set((level[number].mark[i][1]+nx)*2, level[number].mark[i][2]+ny, "  ")
		end
	end
end
-------------------------------------------------------------------------------------
------------------------- Рисования комнаты по координатам --------------------------
function level_print(nx, ny, color, number)
	number = tostring(number)
	gpu.setBackground(color)
	gpu.set(nx*2, ny, "      ")
	gpu.set((nx+4)*2, ny, "      ")
	gpu.set(nx*2, ny+6, "      ")
	gpu.set((nx+4)*2, ny+6, "      ")
	
	gpu.set(nx*2, ny+1, "  ")
	gpu.set(nx*2, ny+2, "  ")
	gpu.set(nx*2, ny+4, "  ")
	gpu.set(nx*2, ny+5, "  ")
	gpu.set((nx+6)*2, ny+1, "  ")
	gpu.set((nx+6)*2, ny+2, "  ")
	gpu.set((nx+6)*2, ny+4, "  ")
	gpu.set((nx+6)*2, ny+5, "  ")
	
	gpu.setBackground(0x000000)
	gpu.set(nx*2+6-math.modf((string.len(number)-1)/2), ny+3, number)
end
-------------------------------------------------------------------------------------
----------------------------- Переходы между комнатами ------------------------------
pxx, pyy = {}, {}
pxx[-1]=function(nx)
	local rezerv_3 = doors[1]
	if proverka(rezerv_3, chamber.number) then
		doors={}
		doors[2] = -rezerv_3
		reload_doors()
		chamber = gen_level(formula[rezerv_3](chamber.number))
		ppx = 6
	else
		ppx = px
	end
end
pxx[7]=function(nx)
	local rezerv_3 = doors[2]
	if proverka(rezerv_3, chamber.number) then
		doors={}
		doors[1] = -rezerv_3
		reload_doors()
		chamber = gen_level(formula[rezerv_3](chamber.number))
		ppx = 0
	else
		ppx = px
	end
end
pyy[-1]=function(ny)
	local rezerv_3 = doors[3]
	if proverka(rezerv_3, chamber.number) then
		doors={}
		doors[4] = -rezerv_3
		reload_doors()
		chamber = gen_level(formula[rezerv_3](chamber.number))
		ppy = 6
	else
		ppy = py
	end
end
pyy[7]=function(ny)
	local rezerv_3 = doors[4]
	if proverka(rezerv_3, chamber.number) then
		doors={}
		doors[3] = -rezerv_3
		reload_doors()
		chamber = gen_level(formula[rezerv_3](chamber.number))
		ppy = 0
	else
		ppy = py
	end
end
-- //работает как надо, но лучше подредактировать
-------------------------------------------------------------------------------------
-------------------------------- Передвижение игрока --------------------------------
function player_update(nx,ny)
	ppx, ppy = px+nx, py+ny
	if not ((ppx==0 or ppy==0 or ppx==6 or ppy==6) and ppx~=3 and ppy~=3) then
		if pxx[ppx] then pxx[ppx](ppx)
		elseif pyy[ppy] then pyy[ppy](ppy)
		end
		px,py = ppx,ppy
	end
end
-- //работает как надо, но лучше подредактировать
-------------------------------------------------------------------------------------
--------------------------------- Блок отображения ----------------------------------
function update(nick)
	nick_player = nick
	term.clear()

	-- текущая комната
	gen_level(chamber.number)
	mark_print(sx-px,sy-py, chamber.number)
	level_print(sx-px,sy-py,chamber.color, chamber.number)
	
	-- комната слева
	if proverka(doors[1], chamber.number) and px==0 then
		local number = formula[doors[1]](chamber.number)
		gen_level(number)
		mark_print(sx-7-px,sy-py, number)
		level_print(sx-7-px,sy-py,gen_level(formula[doors[1]](chamber.number)).color, gen_level(formula[doors[1]](chamber.number)).number)
	end
	
	-- комната справа
	if proverka(doors[2], chamber.number) and px==6 then
		local number = formula[doors[2]](chamber.number)
		gen_level(number)
		mark_print(sx+7-px,sy-py, number)
		level_print(sx+7-px,sy-py,gen_level(formula[doors[2]](chamber.number)).color, gen_level(formula[doors[2]](chamber.number)).number)
	end
	
	-- комната сверху
	if proverka(doors[3], chamber.number) and py==0 then
		local number = formula[doors[3]](chamber.number)
		gen_level(number)
		mark_print(sx-px,sy-7-py, number)
		level_print(sx-px,sy-7-py,gen_level(formula[doors[3]](chamber.number)).color, gen_level(formula[doors[3]](chamber.number)).number)
	end
	
	-- комната снизу
	if proverka(doors[4], chamber.number) and py==6 then
		local number = formula[doors[4]](chamber.number)
		gen_level(number)
		mark_print(sx-px,sy+7-py, number)
		level_print(sx-px,sy+7-py,gen_level(formula[doors[4]](chamber.number)).color, number)
	end
	
	-- отображение игрока
	gpu.setBackground(0xff0000)
	gpu.set(sx*2, sy, "  ")
	
	-- текстовые индикаторы
	for i=1, #indicator do
	indicator[i]()
	end
	
	-- индикатор выбранного цвета
	gpu.setBackground(markColor[playerColor])
	gpu.set(2, sy*2, "     ")
end
-------------------------------------------------------------------------------------
---------------------------------- Блок управления ----------------------------------
local command={}
command[200]=function() player_update(0,-1) end	-- вверх
command[208]=function() player_update(0,1) end	-- вниз
command[203]=function() player_update(-1,0) end	-- влево
command[205]=function() player_update(1,0) end	-- вправо
command[17]=function()							-- ставить метку
				if not level[chamber.number].mark then level[chamber.number].mark={} end
				level[chamber.number].mark[#level[chamber.number].mark+1]={px,py,markColor[playerColor]}
			end
command[30]=function() if playerColor-1<1 then playerColor=#markColor else playerColor=playerColor-1 end end	-- цвет слева
command[32]=function() if playerColor+1>#markColor then playerColor=1 else playerColor=playerColor+1 end end	-- цвет справа
command[31]=function()																				-- удалить метку
				if level[chamber.number].mark then
					for i=#level[chamber.number].mark, 1, -1  do
						if px==level[chamber.number].mark[i][1] and py==level[chamber.number].mark[i][2] then
							table.remove(level[chamber.number].mark,i)
						end
					end
				end
			end
command[23]=function() -- включает режим разработчика
	if #indicator==0 then
		indicator[1]=function()
			gpu.setBackground(0x000000)
			gpu.setForeground(0xffff00)
			gpu.set(2, 2, "max level: "..max_level)
			gpu.set(2, 3, "all levels: "..max_table)
			gpu.set(2, 4, "this level: "..stat_table[chamber.number])
			gpu.setForeground(0xff0000)
			gpu.set(2, 5, "formula 1: ".."n".."*"..rand_1.." + "..rand_2)
			gpu.set(2, 6, "formula 2: ".."n".."*"..rand_3.." + "..rand_4)
			gpu.set(2, 7, "formula -1: ".."(n - "..rand_2..")/"..rand_1)
			gpu.set(2, 8, "formula -2: ".."(n - "..rand_4..")/"..rand_3)
			gpu.setForeground(0xff00ff)
			gpu.set(2, 9, "progress: " .. math.modf(100-stat_table[chamber.number]*100/max_level).."%")
			gpu.setForeground(0xff00ff)
			gpu.set(2, 10, "color: "..playerColor)
			gpu.setForeground(0xffffff)
		end
	else
		table.remove(indicator,1)
	end
end
command[35]=function()							-- отобразить управление
	term.clear()
	gpu.setForeground(0xff0000)
	print(version)
	print("")
	gpu.setForeground(0x00ff00)
	print("Target: searching chamber 1")
	print("Game 100% passable")
	gpu.setForeground(0xffff00)
	print("Control:")
	print("Q - exit game")
	print("H - help")
	print("I - info")
	print("W - set mark")
	print("S - remove mark")
	print("A - back color mark")
	print("D - next color mark")
	print("")
	gpu.setForeground(0xffffff)
	print("press enter to continue...")
	while true do
		_,_,_, key = event.pull("key_down")
		if key == 28 then
			break
		end
	end
end
-------------------------------------------------------------------------------------
---------------------- Показываем управление до начала игры -------------------------
command[35]()
-------------------------------------------------------------------------------------
------------------------- Отображение комнат до начала игры -------------------------
reload_doors()
update(nick)
gpu.setBackground(0x000000)
-------------------------------------------------------------------------------------
------------------------------------- Тело игры -------------------------------------
while true do
	_,_,_, key, nick = event.pull("key_down")
	if key==16 then
		term.clear()
		gpu.setForeground(0xff0000)
		print("Exit to game?")
		gpu.setForeground(0xffffff)
		print("")
		print("y/n")
		while true do
			_,_,_, key = event.pull("key_down")
			if key == 21 then
				term.clear()
				return
			elseif key == 49 then
				break
			end
		end
	elseif command[key] then
		command[key]()
	end
	update(nick)
	gpu.setBackground(0x000000)
	if chamber.number == 1 then break end		-- цель игры, комната с этим номером
	os.sleep(1/15)								-- задержка, для более удобного управления
end
-------------------------------------------------------------------------------------
------------------------------------- Прощание -------------------------------------
term.clear()
gpu.setForeground(0x00ff00)
print("Congratulations "..nick_player.."!")
print("You win!")
print("")
gpu.setForeground(0xffffff)
print("press enter to exit...")
while true do
	_,_,_, key = event.pull("key_down")
	if key == 28 then
		break
	end
end
term.clear()
-------------------------------------------------------------------------------------