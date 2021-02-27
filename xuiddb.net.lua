----------------------------------------
-- Author: RedbeanW -- License: MIT   --
----------------------------------------
local plugin_version = '1.0.0'
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[XuidDB] Where is my json library??!!')
    return false
end
if (tool:IfFile('./xuid.json') == false) then
	tool:WriteAllText('./xuid.json','{}')
	print('[XuidDB] Creating xuid.json.')
end
json = require('./ilua/lib/json')
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
luaapi:Listen('onLoadName', Event_PlayerJoin)
print('[XuidDB] plugin loaded! VER:' .. plugin_version)