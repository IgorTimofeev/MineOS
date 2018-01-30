
--8х4
--Желтый 0xF7AF00
--Зеленый 0x5C6A00
--Бежевый 0XF9ED89
--Фиолетовый 0x660080
-- UP-119 down-115 left-97 right-100 fire-32 quit-13 pause-113
local GUI = require("GUI")
local buffer = require("doubleBuffering")
local image = require("image")
local event = require("event")
local computer = require("computer")
local DisplayWidth,DisplayHeight = buffer.getResolution()
local fs=require("filesystem")
local Debug=1
local MaxEnemyOnMap=3
local EnemyCount=0

local PlayerMoveSide="none"
local Player1Lifes = 3
local Player1Dead=false

local mainContainer = GUI.fullScreenContainer()
mainContainer:addChild(GUI.panel(1, 1, mainContainer.width, mainContainer.height, 0x0))

local cyka = mainContainer:addChild(GUI.label(1,1,mainContainer.width,1,0xFFFFFF,"Код кавиши=.."))

local BulletContainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))
local tanksContainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))
local mapComtainer = mainContainer:addChild(GUI.container(1, 1, mainContainer.width, mainContainer.height))

local function getRectangleIntersection(R1X1, R1Y1, R1X2, R1Y2, R2X1, R2Y1, R2X2, R2Y2)
	return R2X1 <= R1X2 and R2Y1 <= R1Y2 and R2X2 >= R1X1 and R2Y2 >= R1Y1
end

local config={
	FPS=0,
	FPSc=0,
	ostime=os.time(),
	work=true,
	systemtick=false,
	PathToRes=fs.path(getCurrentScript())
}

local function getTankIntersection(tank)
	for i = 1, #tanksContainer.children do
		local child = tanksContainer.children[i]
		if child ~= tank then
			if getRectangleIntersection(
				tank.x-1,
				tank.y-1,
				tank.x + tank.width+1,
				tank.y + tank.height+1,
				child.x,
				child.y,
				child.x + child.width,
				child.y + child.height
			)
			then
				return false
			end
		end
	end
	return true
end

local function getBulletIntersection(bullet) -------ПЕРЕПОСССАТЬ
	for i = 1, #tanksContainer.children do
		local child = tanksContainer.children[i]

			if getRectangleIntersection(
				bullet.x,
				bullet.y,
				bullet.x + bullet.width-1,
				bullet.y + bullet.height-1,
				child.x,
				child.y,
				child.x + child.width-1,
				child.y + child.height-1
			) and bullet.type ~= child.type then
				tanksContainer.children[i]:delete()
					if child.type=="friend" then
						Player1Lifes=Player1Lifes-1
						Player1Dead=true
					else
						EnemyCount=EnemyCount-1
					end
				return true
			end
	
	end
	for i = 1, #BulletContainer.children do
		local child = BulletContainer.children[i]

			if getRectangleIntersection(
				bullet.x,
				bullet.y,
				bullet.x + bullet.width-1,
				bullet.y + bullet.height-1,
				child.x,
				child.y,
				child.x + child.width-1,
				child.y + child.height-1
			) and bullet.type ~= child.type 
			then
				BulletContainer.children[i]:delete()
				--EnemyCount=EnemyCount-1
				return true
			end
	
	end
	return false
end

local function newBullet(x, y, type, MoveSide)
	local Pulya = GUI.object(x, y, 1, 1)
	
	Pulya.MoveSide = MoveSide
	Pulya.type = type
	Pulya.speed = 3
	-- Pulya.FriendModel = image.load(config.PathToRes.."Resources/Tanks/Bullet.pic")
	
	Pulya.draw = function()
		--if Debug then buffer.text(Pulya.x,Pulya.y-1,0xFFFFFF,"Х="..Pulya.x.." У="..Pulya.y) end
		-- buffer.image(Pulya.x, Pulya.y, Pulya.FriendModel)
		buffer.text(Pulya.x, Pulya.y, 0xFF0000, "▄")
	end
	
	Pulya.eventHandler = function(mainContainer,object,eventData)
		
		if Pulya.MoveSide == "UP" then 
			Pulya.localY = Pulya.localY - Pulya.speed
		elseif Pulya.MoveSide == "DOWN" then 
			Pulya.localY = Pulya.localY + Pulya.speed
		elseif Pulya.MoveSide == "RIGHT" then 
			Pulya.localX = Pulya.localX + Pulya.speed
		elseif Pulya.MoveSide == "LEFT" then 
			Pulya.localX = Pulya.localX - Pulya.speed
		end
		
		if getBulletIntersection(Pulya) then
			Pulya:delete()
		end
		
		if not (Pulya.x >= 1 and Pulya.x <= DisplayWidth and Pulya.y >= 1 and Pulya.y <= DisplayHeight) then
			Pulya:delete()
		end
	end
	
	return Pulya
end


local function Player1(x,y)

	local MyFuckingTank = GUI.object(x,y,8,4)
	
	MyFuckingTank.Speed = 1
	MyFuckingTank.MoveSide = "UP"
	MyFuckingTank.type = "friend"
	
	
	MyFuckingTank.ModelMoveUp = image.load(config.PathToRes.."Resources/Textures/Player1Tank/Player1NewTankUP.pic")
	MyFuckingTank.ModelMoveDown = image.load(config.PathToRes.."Resources/Textures/Player1Tank/Player1NewTankDOWN.pic")
	MyFuckingTank.ModelMoveLeft = image.load(config.PathToRes.."Resources/Textures/Player1Tank/Player1NewTankLEFT.pic")
	MyFuckingTank.ModelMoveRight = image.load(config.PathToRes.."Resources/Textures/Player1Tank/Player1NewTankRIGHT.pic")
	
	MyFuckingTank.Model = MyFuckingTank.ModelMoveUp

	
	MyFuckingTank.draw = function(MyFuckingTank)
		if MyFuckingTank.MoveSide == "UP" then 
			MyFuckingTank.Model = MyFuckingTank.ModelMoveUp
		elseif MyFuckingTank.MoveSide == "DOWN" then 
			MyFuckingTank.Model = MyFuckingTank.ModelMoveDown
		elseif MyFuckingTank.MoveSide == "RIGHT" then 
			MyFuckingTank.Model = MyFuckingTank.ModelMoveRight
		elseif MyFuckingTank.MoveSide == "LEFT" then 
			MyFuckingTank.Model = MyFuckingTank.ModelMoveLeft
		end
		
		buffer.frame(MyFuckingTank.x-1, MyFuckingTank.y-1 , MyFuckingTank.width + 2, MyFuckingTank.height + 2, 0xFFFFFF)
		buffer.image(MyFuckingTank.x, MyFuckingTank.y, MyFuckingTank.Model)
		
		if Debug then buffer.text(1,2,0xFFFFFF,"Танк Х="..MyFuckingTank.x.." Танк У="..MyFuckingTank.y) end
		buffer.text(1,3,0xFFFFFF,"EnemyCount="..EnemyCount.." MaxEnemyOnMap="..MaxEnemyOnMap)
	end
	
	return MyFuckingTank
end


local function Enemy()
	local x,y = 0,0
	local SpawnPoint = math.random(3)
	local Huy={}
	--Процедура умного спавна
		if SpawnPoint==1 then
			x=1
			y=1
		elseif SpawnPoint==2 then
			x=DisplayWidth/2
			y=1
		elseif SpawnPoint==3 then 
			x=DisplayWidth - 7
			y=1
		end
	
	
		local FuckingEnemy = GUI.object(x,y,8,4)
	
		
	if getTankIntersection(FuckingEnemy) then		
		
		FuckingEnemy.Speed = 1
		FuckingEnemy.MoveSide = "DOWN"
		FuckingEnemy.MaxBullet = 2
		
		FuckingEnemy.type = "enemy"
		
		FuckingEnemy.ModelMoveUp = image.load(config.PathToRes.."Resources/Textures/EnemyTank/EnemyTankUP.pic")
		FuckingEnemy.ModelMoveDown = image.load(config.PathToRes.."Resources/Textures/EnemyTank/EnemyTankDOWN.pic")
		FuckingEnemy.ModelMoveLeft = image.load(config.PathToRes.."Resources/Textures/EnemyTank/EnemyTankLEFT.pic")
		FuckingEnemy.ModelMoveRight = image.load(config.PathToRes.."Resources/Textures/EnemyTank/EnemyTankRIGHT.pic")
		
		FuckingEnemy.Model = FuckingEnemy.ModelMoveUp
		
		local function ChangeMoveSide()
			local ChangeSide = math.random(3)
			local Sides={
				"UP",
				"DOWN",
				"LEFT",
				"RIGHT"
			}
			
			for i=1,#Sides do
				if Sides[i] == FuckingEnemy.MoveSide then table.remove(Sides,i) break end
			end
			
			FuckingEnemy.MoveSide = Sides[ChangeSide]

		end
		
		
		FuckingEnemy.eventHandler = function(mainContainer,object,eventData) ---Мозги
			if math.random(100) <= 5 then  
				BulletContainer:addChild(newBullet(FuckingEnemy.x + 3, FuckingEnemy.y + 1, "enemy",FuckingEnemy.MoveSide)) 
			end
			
			if math.random(100) <= 4 then
				ChangeMoveSide()
			end
		end
		
		FuckingEnemy.draw = function()
		
			if FuckingEnemy.MoveSide == "UP" then 
				if FuckingEnemy.localY > 1 then 
					if getTankIntersection(FuckingEnemy) then
						FuckingEnemy.localY = FuckingEnemy.localY - FuckingEnemy.Speed 
					else
						FuckingEnemy.localY = FuckingEnemy.localY + FuckingEnemy.Speed
						ChangeMoveSide()
					end
						else 
							ChangeMoveSide() 
						end
					
				FuckingEnemy.Model = FuckingEnemy.ModelMoveUp
				
			elseif FuckingEnemy.MoveSide == "DOWN" then 
				if FuckingEnemy.localY < DisplayHeight-3 then
					if getTankIntersection(FuckingEnemy) then
						FuckingEnemy.localY = FuckingEnemy.localY + FuckingEnemy.Speed
					else
						FuckingEnemy.localY = FuckingEnemy.localY - FuckingEnemy.Speed
						ChangeMoveSide()
					end
					else 
						ChangeMoveSide() 
					end
				
				FuckingEnemy.Model = FuckingEnemy.ModelMoveDown
				
			elseif FuckingEnemy.MoveSide == "RIGHT" then 
				if FuckingEnemy.localX < DisplayWidth-8 then 
					if getTankIntersection(FuckingEnemy) then
						FuckingEnemy.localX = FuckingEnemy.localX + FuckingEnemy.Speed 
					else
						FuckingEnemy.localX = FuckingEnemy.localX - FuckingEnemy.Speed
						ChangeMoveSide() 
					end
						else 
							ChangeMoveSide() 
						end
					
				FuckingEnemy.Model = FuckingEnemy.ModelMoveRight
				
			elseif FuckingEnemy.MoveSide == "LEFT" then
				
					if  FuckingEnemy.localX > 1 then 
						if getTankIntersection(FuckingEnemy) then
							FuckingEnemy.localX = FuckingEnemy.localX - FuckingEnemy.Speed 
						else
							FuckingEnemy.localX = FuckingEnemy.localX + FuckingEnemy.Speed
							ChangeMoveSide()
						end
					else 
						ChangeMoveSide() 
					end
				
				FuckingEnemy.Model = FuckingEnemy.ModelMoveLeft
			end
				
			buffer.image(FuckingEnemy.x, FuckingEnemy.y, FuckingEnemy.Model)
			
		end
		
		return FuckingEnemy
	else 
		EnemyCount=EnemyCount-1
		return false
	end 
	
end

 local function KeyPress(keycode,lable) --для дэбага, наверное
		lable.text="Код клавиши="..keycode
	if keycode == 113 or keycode == 1081 then --если нажали Q(81) или q(113) или й 1081 - выйти нахуй
		config.work = false
	end
end

--Типа код----------------------------------------------------------------------------------------

local MyFTN = tanksContainer:addChild(Player1(50,20))
mainContainer.eventHandler = function(mainContainer, object, eventData)

if Player1Dead and Player1Lifes >= 1 then
	Player1Dead=false
	Player1Lifes=Player1Lifes-1
	MyFTN = tanksContainer:addChild(Player1(50,20))
elseif Player1Lifes<=0 then
	--GUI.error("Ты проебал!")
	--mainContainer:stopEventHandling(0)
end


if EnemyCount < MaxEnemyOnMap then
EnemyCount=EnemyCount+1
	local Obj = Enemy()
	if Obj==false then
		
	else
		tanksContainer:addChild(Obj)
		
	end
end
		local EvD=eventData
		if EvD[1] == "key_down" then
			if EvD[4] == 200 or EvD[4] == 17 then
				PlayerMoveSide = "UP"
			elseif EvD[4] == 208 or EvD[4] == 31 then
				PlayerMoveSide = "DOWN"
			elseif EvD[4] == 203 or EvD[4] == 30 then
				PlayerMoveSide = "LEFT"
			elseif EvD[4] == 205 or EvD[4] == 32 then
				PlayerMoveSide = "RIGHT"
			elseif EvD[4] == 57 then
					if Player1Dead~=true then BulletContainer:addChild(newBullet(MyFTN.x + math.random(2)+2, MyFTN.y + 1, "friend",MyFTN.MoveSide)) end
			elseif EvD[4] == 19 then
				local Obj = Enemy()
				if Obj==false then 
				else
					tanksContainer:addChild(Obj)
					EnemyCount=EnemyCount+1
				end
			end
		elseif EvD[1] == "key_up" then
			PlayerMoveSide="none"
		end
		
			if PlayerMoveSide == "UP" then
				MyFTN.MoveSide = "UP"
				if MyFTN.y > 1 then MyFTN.localY = MyFTN.y - MyFTN.Speed end
				
			elseif PlayerMoveSide == "DOWN" then
				MyFTN.MoveSide = "DOWN"
				if MyFTN.y < DisplayHeight-3 then MyFTN.localY = MyFTN.y + MyFTN.Speed end
				
			elseif PlayerMoveSide == "LEFT" then
				MyFTN.MoveSide = "LEFT"
				if MyFTN.x > 1 then MyFTN.localX = MyFTN.x - MyFTN.Speed*2 end
				
			elseif PlayerMoveSide == "RIGHT" then
				MyFTN.MoveSide = "RIGHT"
				if MyFTN.x < DisplayWidth-8 then MyFTN.localX = MyFTN.x + MyFTN.Speed*2 end
			end
		--KeyPress(EvD[4],cyka)
	
	buffer.clear(0x0)
	mainContainer:draw()
	buffer.draw()
end

mainContainer:draw()
buffer.draw(true)
mainContainer:startEventHandling(0)




