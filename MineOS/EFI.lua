
local ee,gpu,screen,background,foreground,re
local pr,cm,ls,ps=component.proxy,computer,component.list,computer.pullSignal

local function init()
	local g=ls("gpu")()
	local s=ls("screen")()
	local e=ls("eeprom")()

	if g and s and e then
		gpu,screen,ee=pr(g),pr(s),pr(e)

		computer.getBootAddress=function() return ee.getData() end
		computer.setBootAddress=function(address) return ee.setData(address) end

		gpu.bind(screen.address)
		re={};re.width,re.height=gpu.maxResolution()
		gpu.setResolution(re.width,re.height)
	else
		error("")
	end
end

local function pu(t) while true do local e={ps()};if e[1]==t then return e end end end

local function sleep(timeout)
	local deadline=cm.uptime() + (timeout or 0)
	while cm.uptime()<deadline do ps(deadline - cm.uptime()) end
end

local function bindGPUToScreen()
	gpu.bind(screen.address)
	re={}
	re.width,re.height=gpu.maxResolution()
	gpu.setResolution(re.width,re.height)
end

local colors={b=0xDDDDDD,t1=0x444444,t2=0x999999,t3=0x888888}

local function sB(color) if color ~= background then background=color;gpu.setBackground(color) end end
local function sF(color) if color ~= foreground then foreground=color;gpu.setForeground(color) end end
local function clear() gpu.fill(1,1,re.width,re.height," ") end

local function fade(fromColor,toColor,step)
	for color=fromColor,toColor,step do
		sB(color)
		clear()
		sleep(0.05)
	end
	sB(toColor)
	clear()
end

local function cT(y,color,text)
	sF(color)
	gpu.set(math.floor(re.width/2-#text/2),y,text)
end

local function bt(d)
	ee.setData(d)
	local fs=pr(d)
	local openSuccesss,fileOrReason=pcall(fs.open,"/init.lua","r")
	if openSuccesss then
		local data,readedData="",""
		while readedData do data=data..readedData;readedData=fs.read(fileOrReason,math.huge) end
		fs.close(fileOrReason)
		
		local loadSuccess,loadReason=load(data)
		if loadSuccess then
			local xpcallSuccess,xpcallReason=xpcall(loadSuccess,debug.traceback)
			if not xpcallSuccess then error(xpcallReason) end
		else
			error(loadReason)
		end
	else
		error("init.lua not found")
	end
end

local function cbf(f) return f.exists("/init.lua") or f.exists("/MineOS/EFI.lua") end

local function getBootableDrives()
	local dr={}
	for address in ls("filesystem") do local fs=pr(address);if cbf(fs) then table.insert(dr,fs.address) end end
	return dr
end

local function menu(t,v)
	local y,sv,b,f=math.floor(re.height/2-#v/2-2),1
	while true do
		sB(colors.b)
		clear()
		cT(y,colors.t1,t)
		for i=1,#v do
			b,f=colors.b,colors.t3
			if i==sv then b,f=colors.t3,colors.b end
			sB(b)
			cT(y+i+1,f,"   "..v[i].."   ")
		end
		local e=pu("key_down")
		if e[4]==200 then
			sv=sv>1 and sv-1 or 1
		elseif e[4]==208 then
			sv=sv<#v and sv+1 or #v
		elseif e[4]==28 then
			return v[sv]
 		end
	end
end

local function waitForAlt(t,dr)
	local dl=cm.uptime()+(t or 0)
	while cm.uptime()<dl do
		local e={ps(dl-cm.uptime())}
		if e[1] == "key_down" and e[4] == 56 then
			local d=menu("Choose drive",dr)
			local a=menu("Drive \""..d.."\"",{"Set as bootable",not pr(d).isReadOnly() and "Format" or nil})
			if a=="Set as bootable" then
				bt(d)
			else
				local fs=pr(d);for _,file in pairs(fs.list("/")) do fs.remove("/"..file) end;cm.shutdown(true)
			end
		end
	end
	local fs=pr(ee.getData() or "")
	bt((fs and cbf(fs)) and fs.address or dr[1])
end

init()
bindGPUToScreen()
fade(0x0,colors.b,0x202020)
local y=math.floor(re.height / 2 - 1)
cT(y,colors.t1,"MineOS EFI")
cT(y+1,colors.t2,"Initialising system...")
local dr=getBootableDrives()
if #dr>0 then cT(re.height - 1,colors.t2,"Hold Alt to enter boot options menu");waitForAlt(1.2,dr) else cT(y+1,colors.t2,"Bootable drives not found");pu("key_down");fade(colors.b,0x0,-0x202020);cm.shutdown() end









