-- Автор: qwertyMAN
-- Версия: 0.1 beta

local term				= require("term")
local event				= require("event")
local component			= require("component")
local gpu				= component.gpu
local max_mine			= 40					-- число мин на поле
local display			= {gpu.getResolution()}
local border			= {0,0}					-- отступ, который не используется
local marker			= {}					-- отмечает ПКМ мины
local size				= {16,16}				-- размер игрового поля
math.randomseed(os.time())

local colors={0x0000ff,0x00ff00,0xff0000,0xffff00,0x8800ff,0x88ff00,0x00ffff,0xff00ff}

local function conv_cord(sx,sy)
	return sx*2-1+border[1], sy+border[2]
end

-- создаем поле
local area={}
for x=1, size[1] do
	area[x]={}
	for y=1, size[2] do
		area[x][y]={mine=false, n=0}
	end
end

-- генерируем мины
for i=1, max_mine do
	while true do
		rand_x, rand_y = math.random(1, size[1]), math.random(1, size[2])
		if not area[rand_x][rand_y].mine then
			area[rand_x][rand_y].mine = true
			break
		end
	end
end

-- генерирем числа на пустых клетках
for x=1, size[1] do
	for y=1, size[2] do
		if not area[x][y].mine then
			for i=-1,1 do
				for j=-1,1 do
					if x+i>0 and y+j>0 and x+i<size[1]+1 and y+j<size[2]+1 and area[x+i][y+j].mine then
						area[x][y].n = area[x][y].n+1
					end
				end
			end
		end
	end
end

gpu.setBackground(0x000000)
gpu.setForeground(0xffffff)

-- отображение пустого поля
term.clear()
gpu.setBackground(0xAAAAAA)
for i=1, size[1] do
	for j=1, size[2] do
		local rezerv = {conv_cord(i,j)}
		gpu.set(rezerv[1], rezerv[2], "  ")
	end
end
gpu.setBackground(0x000000)

local function click(x,y)
	local x = math.modf((x+1)/2)
	return x,y
end

local function open(x,y)
	local not_sorting_tb		= {}
	local sorting_tb			= {}
	not_sorting_tb[1]		= {x,y}
	gpu.setBackground(0xffffff)
	local rezerv = {conv_cord(x,y)}
	gpu.set(rezerv[1], rezerv[2], "  ")
	while true do
		-- выход из цикла
		if #not_sorting_tb == 0 then
			gpu.setBackground(0x000000)
			gpu.setForeground(0xffffff)
			return
		else
			local nx,ny = not_sorting_tb[1][1], not_sorting_tb[1][2]
			-- смотрим какого вида ячейка
			if area[nx][ny] then
				if area[nx][ny].n>0 then -- если не пустая
					gpu.setForeground(colors[area[nx][ny].n])
					local rezerv = {conv_cord(nx,ny)}
					gpu.set(rezerv[1], rezerv[2], " "..area[nx][ny].n)
				else
					-- если пустая
					for i=-1,1 do
						for j=-1,1 do
							local mx,my = nx+i, ny+j
							-- если ячейка существует
							if mx>=1 and my>=1 and mx<=size[1] and my<=size[2] then
								local swich = true
								-- проверяем есть ли она в бд
								for n=1, #sorting_tb do
									if mx==sorting_tb[n][1] and my==sorting_tb[n][2] then
										swich = false
									end
								end
								for n=1, #not_sorting_tb do
									if mx==not_sorting_tb[n][1] and my==not_sorting_tb[n][2] then
										swich = false
									end
								end
								if swich then
									local rezerv = {conv_cord(mx,my)}
									gpu.set(rezerv[1], rezerv[2], "  ")
									not_sorting_tb[#not_sorting_tb+1]={mx,my}
								end
							end
						end
					end
				end
				area[nx][ny]=false
			end
			sorting_tb[#sorting_tb+1] = not_sorting_tb[1]
			table.remove(not_sorting_tb,1)
		end
	end
end

-- тело программы
while true do
	local _,_,x,y,key,nick = event.pull("touch")
	local x,y = click(x,y)
	if key == 0 then
		local swich = true
		for i=1, #marker do
			if x == marker[i][1] and y == marker[i][2] then
				swich = false
			end
		end
		if area[x][y] and area[x][y].mine and swich then
			-- покажим мины
			gpu.setBackground(0xff0000)
			gpu.setForeground(0x000000)
			for i=1, size[1] do
				for j=1, size[2] do
					if area[i][j] and area[i][j].mine then
						local rezerv = {conv_cord(i,j)}
						gpu.set(rezerv[1], rezerv[2], " m")
					end
				end
			end
			gpu.setBackground(0x000000)
			gpu.setForeground(0xffffff)
			os.sleep(2)
			term.clear()
			print("game over")
			os.sleep(2)
			term.clear()
			return
		elseif swich then
			open(x,y)
			-- проверяем выигрыш
			local timer = 0
			for i=1, size[1] do
				for j=1, size[2] do
					if area[i][j] then
						timer = timer+1
					end
				end
			end
			if timer==max_mine then
				-- покажим мины
				gpu.setBackground(0xff0000)
				gpu.setForeground(0x000000)
				for i=1, size[1] do
					for j=1, size[2] do
						if area[i][j] and area[i][j].mine then
							local rezerv = {conv_cord(i,j)}
							gpu.set(rezerv[1], rezerv[2], " m")
						end
					end
				end
				gpu.setBackground(0x000000)
				gpu.setForeground(0xffffff)
				-- поздравления
				os.sleep(2)
				term.clear()
				print("You win!")
				os.sleep(2)
				term.clear()
				return
			end
		end
	elseif key == 1 then
		local swich = true
		for i=#marker, 1, -1  do
			if x == marker[i][1] and y == marker[i][2] then
				table.remove(marker,i)
				gpu.setBackground(0xAAAAAA)
				local rezerv = {conv_cord(x,y)}
				gpu.set(rezerv[1], rezerv[2], "  ")
				swich = false
			end
		end
		if swich and area[x][y] then
			marker[#marker+1]={x,y}
			gpu.setBackground(0xffaa00)
			local rezerv = {conv_cord(x,y)}
			gpu.set(rezerv[1], rezerv[2], "  ")
		end
		gpu.setBackground(0x000000)
	end
end