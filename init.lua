function tostringex(v, len)
	if len == nil then len = 0 end
	local pre = string.rep('\t', len)
	local ret = ""
	if type(v) == "table" then
	   if len > 5 then return "\t{ ... }" end
	   local t = ""
	   for k, v1 in pairs(v) do
		t = t .. "\n\t" .. pre .. tostring(k) .. ":"
		t = t .. tostringex(v1, len + 1)
	   end
	   if t == "" then
		ret = ret .. pre .. "{ }\t(" .. tostring(v) .. ")"
	   else
		if len > 0 then
		 ret = ret .. "\t(" .. tostring(v) .. ")\n"
		end
		ret = ret .. pre .. "{" .. t .. "\n" .. pre .. "}"
	   end
	else
	   ret = ret .. pre .. tostring(v) .. "\t(" .. type(v) .. ")"
	end
	return ret
end
local function tracebackex()
	local ret = "stack traceback:\n"
	local level = 3
	while true do
	   --get stack info
	   local info = debug.getinfo(level, "Slnu")
	   if not info then break end
	   if info.what == "C" then                -- C function
		ret = ret .. tostring(level-2) .. string.format("\tC function `%s`\n",info.name)
	   else           -- Lua function
		ret = ret .. tostring(level-2) .. string.format("\t%s:%d in function `%s`\n", info.short_src, info.currentline, info.name or "")
	   end
	   local szarg=info.nparams
	   --get local vars
	   local i = 1
	   while true do
		local name, value = debug.getlocal(level, i)
		if not name then break end
		if i<= szarg then 
			name='<'..name..'>'
			ret = ret .. "\t\t" .. name .. " =\t" .. tostringex(value, 3) .. "\n"
			i = i + 1
		else
			break
		end
	   end
	   level = level + 1
	end
	return ret
end

function EXCEPTION(e)
	return e.."\n"..tracebackex()
end

local G_EVENTS={["onJoin"]=1,["onLeft"]=2,["onChat"]=3,["onCMD"]=4,["onMobDie"]=5,["onLCMD"]=6,["onMobHurt"]=7,["onPlayerDestroyBlock"]=8,["onPlayerPlaceBlock"]=9,["onPlayerUseItem"]=9,["onPlayerOpenChest"]=10,["onPlayerOpenBarrel"]=11,["onPlayerCloseBarrel"]=12,["onPlayerCloseChest"]=13,["onPlayerAttack"]=14,["onPlayerRespawn"]=15,["onExplode"]=17,["onPlayerTakeItem"]=18,["onPlayerDropItem"]=19}
function Listen(ename,cb)
	if G_EVENTS[ename]==nil then
		error("cant find event")
	end
	if _G["EH_"..ename]==nil then
		_G["EH_"..ename]={}
	end
	if type(cb)=="string" then
		cb=_G[cb]
	end
	if cb==nil then
		error("cant find cb,did you `Listen` before declaring the function???")
	end
	Listen2(ename,cb)
end


function append(tbl,v,i)
	tbl[TSize(tbl)+(i or 0)]=v
end
function runCmdS(cmd,break_on_error)
	local ret,res,tres
	res=""
	for i in cmd:gmatch('([^$]+)') do
		ret,tres=runCmdEx(i)
		res=res.."\n"..tres
		if ret==false and break_on_error then
			return false,res
		end
	end
	return true,res
end
function schedule(cb,interval,delay)
	-- cb:str/upvalue interval,delay:int  -> taskid:int
	if type(cb)=="string" then
		cb=_G[cb]
	end
	if cb==nil then
		error("cant find cb,did you `schedule` before declaring the function???")
	end
	if delay==nil then delay=0 end
	local tid=schapi.schedule(cb,interval,delay)
	return tid
end
function cancel(taskid)
	schapi.cancel(taskid)
end

_MSGH={}

package.cpath=".\\plugins\\LiteLuaLoader\\lualib\\?.dll"
package.path=".\\plugins\\LiteLuaLoader\\lua\\?.lua;.\\plugins\\LiteLuaLoader\\lualib\\?.lua;.\\plugins\\LiteLuaLoader\\lua\\?\\init.lua"

local Reqid2cb={}
local HttpWorker=startThread("plugins/LiteLuaLoader/lua/async/ahttp.lua",function (reqid,text,code)
	Reqid2cb[reqid](text,code)
end)
function get(url,cb)
	local id
	while true do
		id=math.random(2000000000)
		if Reqid2cb[id]==nil then break end
	end
	Reqid2cb[id]=cb
	TSendMsg(HttpWorker,"get",id,url)
end

function ReadAllText(path)
	local file=assert(io.open(path,'r'))
	local data=''
	for line in file:lines() do
		data=data..'\n'..line
	end
	file:close()
	return data
end
function WriteAllText(path,content)
    local file = assert(io.open(path,'w'))
    file:write(content)
    file:close()
end
function IfFile(path)
	local file = io.open(path,'r')
	if file == nil then return false
	else
		file:close();return true
	end
end

print("LuaInit loaded!!")
