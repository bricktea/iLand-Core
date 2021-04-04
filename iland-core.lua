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
local ILAPI,newLand,TRS_Form,i18n_data={}
local json = require('cjson')

-- check file
if IfFile(data..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- load data file
local cfg = json.decode(ReadAllText(data_path..'config.json'))
local playerCfg = json.decode(ReadAllText(data_path..'players.json'))
local land_data = json.decode(ReadAllText(data_path..'data.json'))
local land_owners = json.decode(ReadAllText(data_path..'owners.json'))

-- load language file
for i,v in pairs(cfg.manager.i18n.enabled_languages) do
	if(not(tool:IfFile(luaPath..'iland\\lang\\'..v..'.json'))) then print('[ILand] ERR!!! language file('..v..') not found, plugin is closing...') return false end
	i18n_data[v]=json.decode(tool:ReadAllText(luaPath..'iland\\lang\\'..v..'.json'))
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

print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)