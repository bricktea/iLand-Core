-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.1'
local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\'
local lib_path = ''
local ILAPI={};local newLand={};local TRS_Form={};local i18n_data={}
local json = require('cjson')

-- check file
if IfFile(data_path..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- load data file
local cfg = json.decode(ReadAllText(data_path..'config.json'))
local playerCfg = json.decode(ReadAllText(data_path..'players.json'))
local land_data = json.decode(ReadAllText(data_path..'data.json'))
local land_owners = json.decode(ReadAllText(data_path..'owners.json'))

-- load language file
for i,v in pairs(cfg.manager.i18n.enabled_languages) do
	if(not(IfFile(data_path..'lang\\'..v..'.json'))) then print('[ILand] ERR!!! language file('..v..') not found, plugin is closing...') return false end
	i18n_data[v]=json.decode(ReadAllText(data_path..'lang\\'..v..'.json'))
end

-- listen -> event
function EV_playerJoin(e)
	TRS_Form[e]={}
	xuid=Actor:getxuid(e)
	if playerCfg[xuid]==nil then 
		playerCfg[xuid]={};iland_save()
	else
		if playerCfg[xuid].language~=nil then TRS_Form[e].language=playerCfg[xuid].language end
	end
end
function EV_onCmd(e) end
function EV_formCB(e) end


-- feature function
function iland_save()
	WriteAllText(data_path..'config.json',json.encode(cfg))
	WriteAllText(data_path..'players.json',json.encode(playerCfg))
	WriteAllText(data_path..'data.json',json.encode(land_data))
	WriteAllText(data_path..'owners.json',json.encode(land_owners))
end

function I18N(a,b) --a=key b=playerptr
	-- TRS_Form[playerptr].language | 临时
	-- playerCfg[xuid].language      | 永久
	if b==nil then return i18n_data[cfg.manager.i18n.default_language][a] end
	-- ↑ Server ; ↓ Player
	local xuid=Actor:getxuid(b)
	if TRS_Form[b].language==nil then
		if(playerCfg[xuid].language~=nil) then
			TRS_Form[b].language=playerCfg[xuid].language
			goto HOMO1
		end
		-- ↑ Custom ; ↓ Auto
		local f=playerGetCountry(b)
		if(cfg.manager.i18n.auto_language_byIP) then
			for i,v in pairs(cfg.manager.i18n.enabled_languages) do
				for n in string.gmatch(i18n_data[v]['COUNTRY_CODE'], "%S+") do
					if n==f then TRS_Form[b].language=v;goto HOMO1 end
				end
			end 
		end
		TRS_Form[b].language=cfg.manager.i18n.default_language
		:: HOMO1 ::
	end
	return i18n_data[TRS_Form[b].language][a]
end

function gsubEx(m,a,a1,b,b1,c,c1,d,d1,e,e1,f,f1,g,g1,h,h1,i,i1,j,j1,k,k1,l,l1)
	local n=string.gsub(m,a,a1)
	if b~=nil then n=string.gsub(n,b,b1) else return n end
	if c~=nil then n=string.gsub(n,c,c1) else return n end
	if d~=nil then n=string.gsub(n,d,d1) else return n end
	if e~=nil then n=string.gsub(n,e,e1) else return n end
	if f~=nil then n=string.gsub(n,f,f1) else return n end
	if g~=nil then n=string.gsub(n,g,g1) else return n end
	if h~=nil then n=string.gsub(n,h,h1) else return n end
	if i~=nil then n=string.gsub(n,i,i1) else return n end
	if j~=nil then n=string.gsub(n,j,j1) else return n end
	if k~=nil then n=string.gsub(n,k,k1) else return n end
	if l~=nil then n=string.gsub(n,l,l1) else return n end
	return n
end

function money_add(a,b) --a=playername b=value
	runCmd('scoreboard players add "'..a..'" "'..cfg.money.scoreboard_objname..'" '..b)
end
function money_del(a,b) --a=playername b=value
	runCmd('scoreboard players remove "'..a..'" "'..cfg.money.scoreboard_objname..'" '..b)
end
-- function money_get(a) --a=playername
--	return(mc:getscoreboard(luaapi:GetUUID(a),cfg.money.scoreboard_objname))
-- end
function getLandFromPos(pos,dim)
	for landId, val in pairs(land_data) do
		if(land_data[landId].range.dim~=dim) then goto JUMPOUT_4 end
		local s_pos={};s_pos.x=land_data[landId].range.start_x;s_pos.y=land_data[landId].range.start_y;s_pos.z=land_data[landId].range.start_z
		local e_pos={};e_pos.x=land_data[landId].range.end_x;e_pos.y=land_data[landId].range.end_y;e_pos.z=land_data[landId].range.end_z
		if(isPosInCube(pos,s_pos,e_pos)==true) then
			return landId
		end
		:: JUMPOUT_4 ::
	end
	return -1
end
function cubeGetEdge(posA,posB)
	local edge={}
	local p=0
	-- [Debug] print(edge[p].x,edge[p].y,edge[p].z,' ',edge[p-1].x,edge[p-1].y,edge[p-1].z,' ',edge[p-2].x,edge[p-2].y,edge[p-2].z,' ',edge[p-3].x,edge[p-3].y,edge[p-3].z)
	for i=1,math.abs(math.abs(posA.y)-math.abs(posB.y))+1 do
		if(posA.y>posB.y) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-i;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-i;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-i;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-i;edge[p].z=posA.z
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y+i-2;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y+i-2;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y+i-2;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y+i-2;edge[p].z=posA.z
		end
	end
	for i=1,math.abs(math.abs(posA.x)-math.abs(posB.x))+1 do
		if(posA.x>posB.x) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posA.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posB.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posA.y-1;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x-i+1;edge[p].y=posB.y-1;edge[p].z=posB.z
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posA.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posB.y-1;edge[p].z=posA.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posA.y-1;edge[p].z=posB.z
			p=#edge+1;edge[p]={};edge[p].x=posA.x+i-1;edge[p].y=posB.y-1;edge[p].z=posB.z
		end
	end
	for i=1,math.abs(math.abs(posA.z)-math.abs(posB.z))+1 do
		if(posA.z>posB.z) then
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posB.y-1;edge[p].z=posA.z-i+1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posB.y-1;edge[p].z=posA.z-i+1
		else
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posA.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posA.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posA.x;edge[p].y=posB.y-1;edge[p].z=posA.z+i-1
			p=#edge+1;edge[p]={};edge[p].x=posB.x;edge[p].y=posB.y-1;edge[p].z=posA.z+i-1
		end
	end
	return edge
end
function isPosInCube(pos,posA,posB)
	if((pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x)==true) then
		if((pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y)==true) then
			if((pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z)==true) then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
function isValInList(list, value)
	for i, nowValue in pairs(list) do
        if nowValue == value then
            return i
        end
    end
    return -1
end
function deepcopy(orig) --参(chao)考(xi)自lua-users.org
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function isTextSpecial(text)
	local flag='[%s%p%c%z]'
	if(string.find(text,flag)==nil) then
		return false
	end
	return true
end	
function isTextNum(text)
	if(tonumber(text)==nil) then
		return false
	end
	return true
end
function playerGetCountry(playerptr)
	local ip=Actor:getIP(playerptr)
	ip=string.sub(ip,0,string.find(ip,"|",0)-1)
	local n=json.decode(get('http://ip-api.com/json/'..ip..'?fields=16386'))
	if n['status']=='fail' then 
		return 'Mars'
	else
		return n['countryCode']
	end
end
function isNearLand(pos,dim,nearVal) end

print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)