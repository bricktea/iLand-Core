----------------------------------------
-- Author: RedbeanW -- License: MIT   --
----------------------------------------
local plugin_version = '1.0.0'
local LibPath=luaapi.LibPATH
if (tool:IfFile(LibPath..'dkjson.lua') == false) then
    print('[XuidDB] ERR!!! json library not found, plugin is closing...')
    return false
end
if (tool:IfFile('./xuid.json') == false) then
	tool:WriteAllText('./xuid.json','{}')
	print('[XuidDB] Creating xuid.json.')
end
json = require(LibPath..'dkjson')
local xuiddb=json.decode(tool:ReadAllText('./xuid.json'))
function Event_PlayerJoin(a)
	if(xuiddb[a.xuid]~=nil) then return end
	xuiddb[a.xuid]={};xuiddb[a.xuid]=a.playername
	tool:WriteAllText('./xuid.json',json.encode(xuiddb))
end
function getPlayernameFromXUID(e)
	if(xuiddb[e]==nil) then return e end
	return xuiddb[e]
end
function getAllPlayersList()
	local b={}
	for i,v in pairs(xuiddb) do
		b[#b+1]=v
	end
	return b
end
function DbGetXUID(e)
	local p=''
	for i,v in pairs(xuiddb) do
		if(v==e) then return i end
	end
	return ''
end
luaapi:Listen('onLoadName', Event_PlayerJoin)
print('[XuidDB] plugin loaded! VER:' .. plugin_version)