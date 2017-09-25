local c,cm=component,computer
local pr,ls,ps,ut,sd,	ee,gpu,bg,fg,re,sce=c.proxy,c.list,cm.pullSignal,cm.uptime,cm.shutdown

local function init()
	local g=ls("gpu")()
	local s=ls("screen")()
	local e=ls("eeprom")()

	if g and s and e then
		gpu,ee=pr(g),pr(e)
		cm.getBootAddress=function() return ee.getData() end
		cm.setBootAddress=function(address) return ee.setData(address) end
		gpu.bind(s)
		re={};re.width,re.height=gpu.maxResolution()
		gpu.setResolution(re.width,re.height)
		sce=math.floor(re.height/2)
	else
		error("")
	end
end

local function pu(t) while true do local e={ps()};if e[1]==t then return e end end end

local function sleep(timeout)
	local deadline=ut()+(timeout or 0)
	while ut()<deadline do ps(deadline-ut()) end
end

local colors={b=0xDDDDDD,t1=0x444444,t2=0x999999,t3=0x888888}

local function sB(c) if c~=bg then bg=c;gpu.setBackground(c) end end
local function sF(c) if c~=fg then fg=c;gpu.setForeground(c) end end
local function clear() gpu.fill(1,1,re.width,re.height," ") end
local function cT(y,c,t) sF(c);gpu.set(math.floor(re.width/2-#t/2),y,t) end
local function l() sB(colors.b);clear();cT(sce-1,colors.t1,"MineOS EFI") end

local function fade(fromColor,toColor,step)
	for i=fromColor,toColor,step do
		sB(i)
		clear()
		sleep(0.05)
	end
	sB(toColor)
	clear()
end

local function bt(fs)
	cT(sce,colors.t2,"Booting from " .. fs.address)
	ee.setData(fs.address)
	local openS,fileOrR=pcall(fs.open,"/init.lua","r")
	if openS then
		local data,rData="",""
		while rData do data=data..rData;rData=fs.read(fileOrR,math.huge) end
		fs.close(fileOrR)

		local loadS,loadR=load(data)
		if loadS then
			local xpS,xpR=xpcall(loadS,debug.traceback)
			if not xpS then error(xpR) end
		else
			error(loadR)
		end
	else
		error("init.lua not found")
	end
end

local function cbf(f) return f.exists("/init.lua") or f.exists("/MineOS/EFI.lua") end

local function gB()
	local dr={}
	for address in ls("filesystem") do local fs=pr(address);if cbf(fs) then table.insert(dr,fs) end end
	return dr
end

local function menu(t,v)
	local y,sv,b,f=math.floor(sce-#v/2-1),1
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
			return sv
		end
	end
end

local function waitForAlt(t,dr)
	local dl=ut()+t
	while ut()<dl do
		local e={ps(dl-ut())}
		if e[1]=="key_down" and e[4]==56 then
			while true do
				local v={};for i=1,#dr do v[i]=(dr[i].getLabel() or "Unnamed").." "..(dr[i].spaceTotal()>524288 and "HDD" or "FDD").." ("..dr[i].address..")" end; table.insert(v, "Back")
				local d=menu("Choose drive",v);
				if d==#v then break end
				v={"Set as bootable"};if not dr[d].isReadOnly() then v[2]="Format" end; table.insert(v, "Back")
				local a=menu("Drive \""..dr[d].address.."\"",v)
				if a==1 then
					l();bt(dr[d]);return
				elseif a==2 and #v==3 then
					for _,file in pairs(dr[d].list("/")) do dr[d].remove("/"..file) end;sd(true)
				end
			end
		end
	end

	local fs=pr(ee.getData() or "")
	l();bt((fs and cbf(fs)) and fs or dr[1])
end

init()
fade(0x0,colors.b,0x202020)
l()
cT(sce,colors.t2,"Initialising system")
local dr=gB()
if #dr>0 then cT(re.height-1,colors.t2,"Hold Alt to enter boot options menu");waitForAlt(1.2,dr) else cT(sce,colors.t2,"Bootable drives not found");pu("key_down");fade(colors.b,0x0,-0x202020);sd() end
