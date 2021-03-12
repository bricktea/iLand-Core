----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
--       未经许可 禁止盈利性用途      --
----------------------------------------
-- 插件版本，请勿修改
local plugin_version = '1.1.0'
local latest_version = plugin_version
local newLand = {}
local TRS_Form={}
local i18n_data={}
-- Check File and Load Library
if (tool:IfFile('./ilua/lib/dkjson.lua') == false) then
    print('[ILand] ERR!!! json library not found, plugin is closing...')
    return false
end
if (tool:IfFile('./ilua/iland/config.json') == false) then
    print('[ILand] ERR!!! configure file not found, plugin is closing...')
    return false
end
if (tool:IfFile('./ilua/xuiddb.net.lua') == false) then
    print('[ILand] ERR!!! xuiddb not found, plugin is closing...')
    return false
end
local json = require('./ilua/lib/dkjson')
-- Encode Json File
cfg = json.decode(tool:ReadAllText('./ilua/iland/config.json'))
land_data = json.decode(tool:ReadAllText('./ilua/iland/data.json'))
land_owners = json.decode(tool:ReadAllText('./ilua/iland/owners.json'))
-- 功能需要提前load的函数
function iland_save()
	local a=tool:WorkingPath()
	tool:WriteAllText(a..'ilua\\iland\\config.json',json.encode(cfg,{indent=true}))
	tool:WriteAllText(a..'ilua\\iland\\data.json',json.encode(land_data))
	tool:WriteAllText(a..'ilua\\iland\\owners.json',json.encode(land_owners))
end
function I18N(a,b) --a=key b=playername
	local n=i18n_data[cfg.manager.i18n.default_language][a]
	if(n==nil) then return '' else return n end
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
-- update configure file
do
	if(cfg.version==nil) then --version<1.0.4
		cfg.version={};cfg.version=103
		cfg.manager.operator={}
		iland_save()
	end
	if(cfg.version==103) then
		cfg.version=106
		cfg.manager.allow_op_delete_land=nil
		for landId, val in pairs(land_data) do
			if(land_data[landId].range==nil) then
				land_data[landId]=nil
			end
		end
		iland_save()
	end
	if(cfg.version==106) then
		cfg.version=107
		cfg.update_check=true
		for landId, val in pairs(land_data) do
			land_data[landId].setting.allow_open_barrel=false
		end
		iland_save()
	end
	if(cfg.version==107) then
		cfg.version=110
		cfg.money={}
		cfg.money.protocol='scoreboard'
		cfg.money.credit_name=cfg.scoreboard.credit_name
		cfg.money.scoreboard_objname=cfg.scoreboard.name
		cfg.scoreboard=nil
		cfg.manager.i18n={}
		cfg.manager.i18n.enabled_languages={"zh_CN","zh_TW","en_US"}
		cfg.manager.i18n.default_language="zh_CN"
		cfg.manager.i18n.auto_language_byIP=false
		cfg.manager.i18n.allow_players_select_lang=true
		iland_save()
	end
end
-- load language files
for i,v in pairs(cfg.manager.i18n.enabled_languages) do
	if(not(tool:IfFile('./ilua/iland/lang/'..v..'.json'))) then print('[ILand] ERR!!! language file('..v..') not found, plugin is closing...') return false end
	i18n_data[v]=json.decode(tool:ReadAllText('./ilua/iland/lang/'..v..'.json'))
end
-- Check Update
if(cfg.update_check) then
	local t=tool:HttpGet('http://cdisk.amd.rocks/tmp/ILAND/version','')
	latest_version=string.sub(t,string.find(t,'<',1)+1,string.find(t,'>',1)-1)
	if(latest_version=='') then latest_version=plugin_version end
	if(plugin_version~=latest_version) then
		print('[ILand] '..gsubEx(I18N('console.newversion'),'<a>',latest_version))
		print('[ILand] '..I18N('console.update'))
	end
end
-- Functions
function Event_PlayerJoin(a)
	TRS_Form[a.playername]={}
end
function Monitor_CommandArrived(a)
    local uuid = luaapi:GetUUID(a.playername)
	local xuid = luaapi:GetXUID(a.playername)
    local key = string.gsub(a.cmd, ' ', '', 1)
	local land_count = ''
    if (string.len(key) == 5 and key == '/land') then
		if(land_owners[xuid]==nil) then
			land_count='0'
		else
			land_count=tostring(#land_owners[xuid])
		end
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid, gsubEx(I18N('gui.land.title',a.playername),'<a>',plugin_version), gsubEx(I18N('gui.land.content',a.playername),'<a>',land_count,'<b>',cfg.land_buy.price_ground,'<c>',cfg.money.credit_name,'<d>',cfg.land_buy.price_sky), I18N('talk.landmgr.open',a.playername), I18N('gui.general.close',a.playername))
        return false
    end
    if (string.len(key) > 5 and string.sub(key, 1, 5) == '/land') then
        key = string.sub(key, 6, string.len(key))
    else
        return true
    end
    --- COMMANDS ---
    if (key == 'new') then
        Func_Buy_getLicense(a.playername)
    end
    if (key == 'a') then
        Func_Buy_selectRange(a.playername, a.XYZ, a.dimensionid, 0)
    end
    if (key == 'b') then
        Func_Buy_selectRange(a.playername, a.XYZ, a.dimensionid, 1)
    end
    if (key == 'buy') then
        Func_Buy_createOrder(a.playername)
    end
	if (key == 'giveup') then
		Func_Buy_giveup(a.playername)
	end
	if (key == 'gui') then
		Func_Manager_open(a.playername)
	end
	if (key == 'mgr') then
		if(isValInList(cfg.manager.operator,xuid)==-1) then return end
		Func_Manager_Operator(a.playername)
	end
    return false
end
function Monitor_FormArrived(a)
	mc:releaseForm(a.formid)
	if(a.selected=='null') then return end
	if(a.selected=='false') then return end
	local xuid=luaapi:GetXUID(a.playername)
	local uuid=luaapi:GetUUID(a.playername)
	local lid=TRS_Form[a.playername].landid --正在操作的landid
	--- Buy Land ---
    if (newLand[a.playername]~=nil and newLand[a.playername].formid==a.formid) then
        Func_Buy_callback(a.playername)
    end
	--- Mgr Land ---
	if(TRS_Form[a.playername].mgr==a.formid) then
		Func_Manager_callback(a.playername,a.selected)
		return
	end
	-- Land Perms ---
	-- [1]null     [2]PlaceBlock [3]DestoryBlock [4]openChest  [5]Attack 
	-- [6]DropItem [7]PickupItem [8]UseItem      [9]openBarrel [10]null
	-- [11]Explode
	if(TRS_Form[a.playername].lperm==a.formid) then
		local result=json.decode(a.selected)
		land_data[lid].setting.allow_destory=result[3]
		land_data[lid].setting.allow_place=result[2]
		land_data[lid].setting.allow_exploding=result[11]
		land_data[lid].setting.allow_attack=result[5]
		land_data[lid].setting.allow_open_chest=result[4]
		land_data[lid].setting.allow_pickupitem=result[7]
		land_data[lid].setting.allow_dropitem=result[6]
		land_data[lid].setting.allow_use_item=result[8]
		land_data[lid].setting.allow_open_barrel=result[9]
		iland_save()
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
	end
	--- Del Land ---
	if(TRS_Form[a.playername].delland==a.formid) then
		land_data[lid]=nil
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		iland_save()
		money_add(a.playername,TRS_Form[a.playername].landvalue)
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
	end
	--- Land Trust ---
	if(TRS_Form[a.playername].ltrust==a.formid) then
		-- [1]null [2]true [3]0 [4]false [5]0
		local result=json.decode(a.selected)
		if(result[2]==true) then
			local x=DbGetXUID(TRS_Form[a.playername].playerList[result[3]+1])
			local n=#land_data[lid].setting.share+1
			if(luaapi:GetXUID(a.playername)==x) then
				mc:runcmd('title "' .. a.playername .. '" actionbar '..I18N('title.landtrust.cantaddown',a.playername))
				return
			end
			if(isValInList(land_data[lid].setting.share,x)~=-1) then
				mc:runcmd('title "' .. a.playername .. '" actionbar '..I18N('title.landtrust.alreadyexists',a.playername))
				return
			end
			land_data[lid].setting.share[n]=x
			iland_save()
			if(result[4]~=true) then TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername)) end
		end
		if(result[4]==true) then
			if(#land_data[lid].setting.share==0) then return end 
			local x=land_data[lid].setting.share[result[5]+1]
			table.remove(land_data[lid].setting.share,isValInList(land_data[lid].setting.share,x))
			iland_save()
			TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
		end
	end
	--- Land Tag ---
	if(TRS_Form[a.playername].ltag==a.formid) then
		local result=json.decode(a.selected)
		if(isTextSpecial(result[2])==true) then --防止有nt玩家搞事
			mc:runcmd('title "' .. a.playername .. '" actionbar NMSL')
			return
		end
		local btag=string.find(lid,'_')
		local wdnmd=lid
		if(btag~=nil) then
			wdnmd=string.sub(lid,0,btag-1)
		end
		local tag=wdnmd..'_'..result[2]
		land_data[tag]=deepcopy(land_data[lid])
		land_data[lid]=nil
		table.insert(land_owners[xuid],#land_owners[xuid]+1,tag)
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		iland_save()
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
	end
	--- OP LandMgr ---
	if(TRS_Form[a.playername].lmop==a.formid) then
		-- [1]null          [2]null       [3]选择的领地  [4]要进行的操作 [5]null
		-- [6]货币名称       [7]计分板名称  [8]null       [9]玩家最多领地 [10]最大领地面积 
		-- [11]最小领地面积  [12]null      [13]底面积价格 [14]高度价格    [15]退款率
		-- [16]null         [17]检查更新
		local result=json.decode(a.selected)
		local doi=true
		if isTextSpecial(result[3]) or isTextSpecial(result[4]) or isTextSpecial(result[6]) or isTextSpecial(result[7]) then doi=false end
		if not(isTextNum(result[9])) or not(isTextNum(result[10])) or not(isTextNum(result[11])) or not(isTextNum(result[13])) or not(isTextNum(result[14])) then doi=false end
		if(doi==false) then mc:runcmd('title "' .. a.playername .. '" actionbar '..I18N('title.oplandmgr.invalidchar',a.playername));return end
		cfg.land.player_max_lands=tonumber(result[9])
		cfg.land.land_max_square=tonumber(result[10])
		cfg.land.land_min_square=tonumber(result[11])
		cfg.money.credit_name=result[6]
		cfg.money.scoreboard_objname=result[7]
		cfg.land_buy.refund_rate=result[15]/100
		cfg.land_buy.price_ground=tonumber(result[13])
		cfg.land_buy.price_sky=tonumber(result[14])
		cfg.update_check=result[17]
		iland_save()
		if(result[4]==0) then TRS_Form.mb_lopm=mc:sendModalForm(uuid,'Complete',I18N('gui.general.complete',a.playername),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername));return end
		local id,nid='',0 --getLandID
		for landId,val in pairs(land_data) do 
			if(nid==result[3]) then id=landId;break end
			nid=nid+1
		end
	
		if(id=='') then mc:runcmd('title "' .. a.playername .. '" actionbar '..I18N('talk.land.unselected',a.playername));return end
		-- 1=teleport 2=transfer 3=delete
		if(result[4]==1) then
			luaapi:teleport(uuid,land_data[id].range.start_x,land_data[id].range.start_y,land_data[id].range.start_z,land_data[id].range.dim)
			mc:runcmd('title "' .. a.playername .. '" actionbar '..gsubEx(I18N('title.oplandmgr.transfered',a.playername),'<a>',id))
		end
		if(result[4]==2) then
			TRS_Form[a.playername].playerList=getAllPlayersList()
			TRS_Form[a.playername].betsflid=id
			TRS_Form[a.playername].opftland=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.oplandmgr.trsland.content',a.playername)..'"},\
																	{"default":0,"options":'..json.encode(TRS_Form[a.playername].playerList)..',"type":"dropdown","text":"'..I18N('talk.land.selecttargetplayer',a.playername)..'"}],\
																	"type":"custom_form","title":"'..I18N('gui.oplandmgr.trsland.title',a.playername)..'"}')
		end
		if(result[4]==3) then
			land_data[id]=nil
			for ownerxuid,val in pairs(land_owners) do
				local nmsl=isValInList(val,id)
				if(nmsl~=-1) then
					table.remove(land_owners[ownerxuid],nmsl)
				end
			end
			iland_save()
			mc:runcmd('title "' .. a.playername .. '" actionbar '..gsubEx(I18N('title.land.deleted',a.playername),'<a>',id))
		end
	end
	--- BackTo Menu => OPMGR/LandMGR ---
	if(TRS_Form.mb_lopm==a.formid) then
		Func_Manager_Operator(a.playername)
	end
	if(TRS_Form.mb_lmgr==a.formid) then
		Func_Manager_open(a.playername)
	end
	--- Land Transfer ---
	if(TRS_Form[a.playername].ltsf==a.formid) then
		local result=json.decode(a.selected)
		local go=DbGetXUID(TRS_Form[a.playername].playerList[result[2]+1])
		if(go==xuid) then mc:runcmd('title "' .. a.playername .. '" actionbar '..I18N('title.landtransfer.canttoown',a.playername));return end
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		table.insert(land_owners[go],#land_owners[go]+1,lid)
		iland_save()
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',gsubEx(I18N('title.landtransfer.complete',a.playername),'<a>',lid,'<b>',getPlayernameFromXUID(go)),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
	end
	--- OP ForceTransfer Land ---
	if(TRS_Form[a.playername].opftland==a.formid) then
		local result=json.decode(a.selected)
		local go=DbGetXUID(TRS_Form[a.playername].playerList[result[2]+1])
		for ownerxuid,val in pairs(land_owners) do
			local nmsl=isValInList(val,TRS_Form[a.playername].betsflid)
			if(nmsl~=-1) then
				table.remove(land_owners[ownerxuid],nmsl)
			end
		end
		table.insert(land_owners[go],#land_owners[go]+1,TRS_Form[a.playername].betsflid)
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',gsubEx(I18N('title.landtransfer.complete',a.playername),'<a>',TRS_Form[a.playername].betsflid,'<b>',getPlayernameFromXUID(go)),I18N('gui.general.back',a.playername),I18N('gui.general.close',a.playername))
	end
end
function Func_Buy_giveup(playername)
    if (newLand[playername]==nil) then
        mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.giveup.failed',playername))
        return
    end
	newLand[playername]=nil
	mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.giveup.succeed',playername))
end
function Func_Buy_createOrder(playername)
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    if (newLand[playername]==nil or newLand[playername].step ~= 2) then
        mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.failbystep',playername))
        return
    end
    local length = math.abs(newLand[playername].posA.x - newLand[playername].posB.x)
    local width = math.abs(newLand[playername].posA.z - newLand[playername].posB.z)
    local height = math.abs(newLand[playername].posA.y - newLand[playername].posB.y)
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if(squ>cfg.land.land_max_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.toobig',playername))
		newLand[playername].step=0
		return
	end
	if(squ<cfg.land.land_min_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.toosmall',playername))
		newLand[playername].step=0
		return
	end
	if(height<3) then
		mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.toolow',playername))
		newLand[playername].step=0
		return
	end
	local edge=cubeGetEdge(newLand[playername].posA,newLand[playername].posB)
	for i=1,#edge do
		for landId, val in pairs(land_data) do
			if(land_data[landId].range.dim~=newLand[playername].dim) then goto JUMPOUT_1 end --维度不同直接跳过
			local s_pos={};s_pos.x=land_data[landId].range.start_x;s_pos.y=land_data[landId].range.start_y;s_pos.z=land_data[landId].range.start_z
			local e_pos={};e_pos.x=land_data[landId].range.end_x;e_pos.y=land_data[landId].range.end_y;e_pos.z=land_data[landId].range.end_z
			if(isPosInCube(edge[i],s_pos,e_pos)==true) then
				mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.collision',playername))
				newLand[playername].step=0
				return
			end
			:: JUMPOUT_1 ::
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if(land_data[landId].range.dim~=newLand[playername].dim) then goto JUMPOUT_2 end --维度不同直接跳过
		s_pos={};e_pos={}
		s_pos.x=land_data[landId].range.start_x
		s_pos.y=land_data[landId].range.start_y
		s_pos.z=land_data[landId].range.start_z
		e_pos.x=land_data[landId].range.end_x
		e_pos.y=land_data[landId].range.end_y
		e_pos.z=land_data[landId].range.end_z
		edge=cubeGetEdge(s_pos,e_pos)
		for i=1,#edge do
			if(isPosInCube(edge[i],newLand[playername].posA,newLand[playername].posB)==true) then
				mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.createorder.collision',playername))
				newLand[playername].step=0
				return
			end
		end
		:: JUMPOUT_2 ::
	end
	--- 购买
    newLand[playername].landprice = math.floor(squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)
	newLand[playername].formid = mc:sendModalForm(uuid,I18N('gui.buyland.title',playername),gsubEx(I18N('gui.buyland.content',playername),'<a>',length,'<b>',width,'<c>',height,'<d>',vol,'<e>',newLand[playername].landprice,'<f>',cfg.money.credit_name,'<g>',money_get(playername)),I18N('gui.general.buy',playername),I18N('gui.general.close',playername))
end
function Func_Buy_selectRange(playername, xyz, dim, mode)
    if (newLand[playername]==nil) then
        mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.selectrange.nolic',playername))
        return
    end
    if (mode == 0) then --posA
        if (mode ~= newLand[playername].step) then
            mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.selectrange.failbystep',playername))
            return
        end
		newLand[playername].dim = dim
		newLand[playername].posA = xyz
		newLand[playername].posA.x=math.floor(newLand[playername].posA.x) --省函数...
		newLand[playername].posA.y=math.floor(newLand[playername].posA.y)-2
		newLand[playername].posA.z=math.floor(newLand[playername].posA.z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..newLand[playername].dim..'\nX=' .. newLand[playername].posA.x .. '\nY=' .. newLand[playername].posA.y .. '\nZ=' .. newLand[playername].posA.z ..'\n'..I18N('title.selectrange.spointb',playername))
        newLand[playername].step = 1
    end
    if (mode == 1) then --posB
        if (mode ~= newLand[playername].step) then
            mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.selectrange.failbystep',playername))
            return
        end
        if (dim ~= newLand[playername].dim) then
            mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.selectrange.failbycdim',playername))
            return
        end
		newLand[playername].posB = xyz
		newLand[playername].posB.x=math.floor(newLand[playername].posB.x)
		newLand[playername].posB.y=math.floor(newLand[playername].posB.y)-2
		newLand[playername].posB.z=math.floor(newLand[playername].posB.z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..newLand[playername].dim..'\nX=' .. newLand[playername].posB.x .. '\nY=' .. newLand[playername].posB.y .. '\nZ=' .. newLand[playername].posB.z ..'\n'..I18N('title.selectrange.bebuy',playername))
        newLand[playername].step = 2
    end
end
function Func_Buy_getLicense(playername)
	if (newLand[playername]~=nil) then
	    mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.getlicense.alreadyexists',playername))
        return
	end
	if(land_owners[luaapi:GetXUID(playername)]~=nil and isValInList(cfg.manager.operator,luaapi:GetXUID(playername))==-1) then
		if(#land_owners[luaapi:GetXUID(playername)]>cfg.land.player_max_lands) then
			mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.getlicense.limit',playername))
			return
		end
	end
    mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.getlicense.succeed',playername))
	newLand[playername]={}
	newLand[playername].step=0
end
function Func_Buy_callback(playername)
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    local player_credits = money_get(playername)
    if (newLand[playername].landprice > player_credits) then
        mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.buyland.moneynotenough',playername))
        return
    else
        money_del(playername,newLand[playername].landprice)
    end
    mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.buyland.succeed',playername))
	math.randomseed(os.time())
	landId='id'..tostring(math.random(100000,999999))
	land_data[landId]={}
	land_data[landId].range={}
	land_data[landId].setting={}
	land_data[landId].range.start_x=newLand[playername].posA.x
	land_data[landId].range.start_z=newLand[playername].posA.z
	land_data[landId].range.start_y=newLand[playername].posA.y
	land_data[landId].range.end_x=newLand[playername].posB.x
	land_data[landId].range.end_z=newLand[playername].posB.z
	land_data[landId].range.end_y=newLand[playername].posB.y
	land_data[landId].range.dim=newLand[playername].dim
	land_data[landId].setting.share={}
	land_data[landId].setting.allow_destory=false
	land_data[landId].setting.allow_place=false
	land_data[landId].setting.allow_exploding=false
	land_data[landId].setting.allow_attack=false
	land_data[landId].setting.allow_open_chest=false
	land_data[landId].setting.allow_open_barrel=false
	land_data[landId].setting.allow_pickupitem=false
	land_data[landId].setting.allow_dropitem=true
	land_data[landId].setting.allow_use_item=true
	iland_save()
	if(land_owners[xuid]==nil) then
		land_owners[xuid]={}
	end
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	iland_save()
	newLand[playername]=nil
	TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',I18N('gui.buyland.succeed',playername),I18N('gui.general.looklook',playername),I18N('gui.general.cancel',playername))
end
function Func_Manager_open(playername)
	local uuid=luaapi:GetUUID(playername)
	local xuid=luaapi:GetXUID(playername)
	local b=luaapi:createPlayerObject(uuid)
	local lid=getLandFromPos(json.decode(b.Position),b.DimensionId)
	local welcomeText=I18N('gui.landmgr.content',playername)
	if(lid~=-1) then
		welcomeText=welcomeText..gsubEx(I18N('gui.landmgr.ctplus',playername),'<a>',lid)
	end
	if(land_owners[xuid]~=nil) then
		if(#land_owners[xuid]==0) then
			mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.landmgr.failed',playername))
			return
		end
	else
		mc:runcmd('title "' .. playername .. '" actionbar '..I18N('title.landmgr.failed',playername))
		return
	end
	TRS_Form[playername].mgr = mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..welcomeText..'"},{"default":0,"steps":["'..I18N('gui.landmgr.options.landinfo',playername)..'","'..I18N('gui.landmgr.options.landperm',playername)..'","'..I18N('gui.landmgr.options.landtrust',playername)..'","'..I18N('gui.landmgr.options.landtag',playername)..'","'..I18N('gui.landmgr.options.landtransfer',playername)..'","'..I18N('gui.landmgr.options.delland',playername)..'"],"type":"step_slider","text":"'..I18N('gui.oplandmgr.selectoption',playername)..'"},\
													{"default":0,"options":'..json.encode(land_owners[xuid])..',"type":"dropdown","text":"'..I18N('gui.landmgr.select',playername)..'"}],\
													"type":"custom_form","title":"'..I18N('gui.landmgr.title',playername)..'"}}]}')
end
function Func_Manager_callback(a,b) --a=playername b=selected
	local xuid=luaapi:GetXUID(a)
	local uuid=luaapi:GetUUID(a)
	local result=json.decode(b)
	TRS_Form[a].landid=land_owners[xuid][result[3]+1] --对应玩家正在操作的 landid
	if(result[2]==0) then --查看领地信息
	    local length = math.abs(land_data[TRS_Form[a].landid].range.start_x - land_data[TRS_Form[a].landid].range.end_x)
		local width = math.abs(land_data[TRS_Form[a].landid].range.start_z - land_data[TRS_Form[a].landid].range.end_z)
		local height = math.abs(land_data[TRS_Form[a].landid].range.start_y - land_data[TRS_Form[a].landid].range.end_y)
		local vol = length * width * height
		local squ = length * width
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,I18N('gui.landmgr.landinfo.title',a),gsubEx(I18N('gui.landmgr.landinfo.content',a),'<a>',a,'<b>',land_data[TRS_Form[a].landid].range.start_x,'<c>',land_data[TRS_Form[a].landid].range.start_y,'<d>',land_data[TRS_Form[a].landid].range.start_z,'<e>',land_data[TRS_Form[a].landid].range.end_x,'<f>',land_data[TRS_Form[a].landid].range.end_y,'<g>',land_data[TRS_Form[a].landid].range.end_z,'<h>',length,'<i>',width,'<j>',height,'<k>',squ,'<l>',vol),I18N('gui.general.iknow',a),I18N('gui.general.close',a))
	end
	if(result[2]==1) then --编辑领地权限
		local d=land_data[TRS_Form[a].landid].setting
		TRS_Form[a].lperm=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.landmgr.landperm.options.title',a)..'"},\
															{"default":'..tostring(d.allow_place)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.place',a)..'"},\
															{"default":'..tostring(d.allow_destory)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.destroy',a)..'"},\
															{"default":'..tostring(d.allow_open_chest)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.openchest',a)..'"},\
															{"default":'..tostring(d.allow_attack)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.attack',a)..'"},\
															{"default":'..tostring(d.allow_dropitem)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.dropitem',a)..'"},\
															{"default":'..tostring(d.allow_pickupitem)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.pickupitem',a)..'"},\
															{"default":'..tostring(d.allow_use_item)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.ustitem',a)..'"},\
															{"default":'..tostring(d.allow_open_barrel)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.openbarrel',a)..'"},\
															{"type":"label","text":"'..I18N('gui.landmgr.landperm.editevent',a)..'"},\
															{"default":'..tostring(d.allow_exploding)..',"type":"toggle","text":"'..I18N('gui.landmgr.landperm.options.exploding',a)..'"}],\
															"type":"custom_form","title":"'..I18N('gui.landmgr.landperm.title',a)..'"}')
	end
	if(result[2]==2) then --编辑信任名单
		TRS_Form[a].playerList = getAllPlayersList()
		local d={}
		for i=1,#land_data[TRS_Form[a].landid].setting.share do --复制share列表中的每个元素，至于为什么不能直接赋值......
			d[i]=land_data[TRS_Form[a].landid].setting.share[i]
		end
		for i, v in pairs(d) do
			d[i]=getPlayernameFromXUID(d[i])
		end
		TRS_Form[a].ltrust=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.landtrust.tip',a)..'"},\
															{"default":false,"type":"toggle","text":"'..I18N('gui.landtrust.addtrust',a)..'"},\
															{"type":"dropdown","text":"'..I18N('gui.landtrust.selectplayer',a)..'","default":0,"options":'..json.encode(TRS_Form[a].playerList)..'},\
															{"default":false,"type":"toggle","text":"'..I18N('gui.landtrust.rmtrust',a)..'"},\
															{"type":"dropdown","text":"'..I18N('gui.landtrust.selectplayer',a)..'","default":0,"options":'..json.encode(d)..'}],\
															"type":"custom_form","title":"'..I18N('gui.landtrust.title',a)..'"}')
	end
	if(result[2]==3) then --领地tag
		TRS_Form[a].ltag=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.landtag.tip',a)..'"},{"placeholder":"tag here","default":"","type":"input","text":""}],"type":"custom_form","title":"'..I18N('gui.landtag.title',a)..'"}')
	end
	if(result[2]==4) then --领地过户
		TRS_Form[a].playerList = getAllPlayersList()
		TRS_Form[a].ltsf=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.landtransfer.tip',a)..'"},{"type":"dropdown","text":"'..I18N('talk.land.selecttargetplayer',a)..'","default":0,"options":'..json.encode(TRS_Form[a].playerList)..'}],"type":"custom_form","title":"'..I18N('gui.landtransfer.title',a)..'"}')
	end
	if(result[2]==5) then --删除领地
		local height = math.abs(land_data[TRS_Form[a].landid].range.start_y - land_data[TRS_Form[a].landid].range.end_y)
		local squ = math.abs(land_data[TRS_Form[a].landid].range.start_x - land_data[TRS_Form[a].landid].range.end_x) * math.abs(land_data[TRS_Form[a].landid].range.start_z - land_data[TRS_Form[a].landid].range.end_z)
		TRS_Form[a].landvalue=math.floor((squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)*cfg.land_buy.refund_rate)
		TRS_Form[a].delland=mc:sendModalForm(uuid,I18N('gui.delland.title',a),gsubEx(I18N('gui.delland.content'),'<a>',TRS_Form[a].landvalue,'<b>',cfg.money.credit_name),I18N('gui.general.yes',a),I18N('gui.general.cancel',a))
	end
end
function Func_Manager_Operator(playername)
	local uuid=luaapi:GetUUID(playername)
	local lst={}
	local xuiddb=json.decode(tool:ReadAllText('./xuid.json'))
	for landId, val in pairs(land_data) do
		name=I18N('gui.oplandmgr.unknownland',playername)
		for xuid, pname in pairs(xuiddb) do
			if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],landId)~=-1) then
				name=pname
			end
		end 
		table.insert(lst,#lst+1,landId..' ('..name..')')
	end
	TRS_Form[playername].lmop=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..I18N('gui.oplandmgr.tip',playername)..'"},\
													{"type":"label","text":"'..I18N('gui.oplandmgr.landmgr',playername)..'"},\
													{"default":0,"options":'..json.encode(lst)..',"type":"dropdown","text":"'..I18N('gui.oplandmgr.select',playername)..'"},\
													{"default":0,"steps":["'..I18N('gui.oplandmgr.donothing',playername)..'","'..I18N('gui.oplandmgr.tp',playername)..'","'..I18N('gui.oplandmgr.transfer',playername)..'","'..I18N('gui.oplandmgr.delland',playername)..'"],"type":"step_slider","text":"'..I18N('gui.oplandmgr.selectoption',playername)..'"},\
													{"type":"label","text":"'..I18N('gui.oplandmgr.economy',playername)..'"},\
													{"placeholder":"'..I18N('gui.oplandmgr.creditname',playername)..'","default":"'..cfg.money.credit_name..'","type":"input","text":"'..I18N('gui.oplandmgr.creditnameV',playername)..'"},\
													{"placeholder":"'..I18N('gui.oplandmgr.sbobject',playername)..'","default":"'..cfg.money.scoreboard_objname..'","type":"input","text":"'..I18N('gui.oplandmgr.sbobjectV',playername)..'"},\
													{"type":"label","text":"'..I18N('gui.oplandmgr.landcfg',playername)..'"},\
													{"placeholder":"","default":"'..cfg.land.player_max_lands..'","type":"input","text":"'..I18N('gui.oplandmgr.maxlands',playername)..'"},\
													{"placeholder":"","default":"'..cfg.land.land_max_square..'","type":"input","text":"'..I18N('gui.oplandmgr.maxsqu',playername)..'"},\
													{"placeholder":"","default":"'..cfg.land.land_min_square..'","type":"input","text":"'..I18N('gui.oplandmgr.minsqu',playername)..'"},\
													{"type":"label","text":"'..I18N('gui.oplandmgr.',playername)..'landbuy"},\
													{"placeholder":"","default":"'..cfg.land_buy.price_ground..'","type":"input","text":"'..I18N('gui.oplandmgr.bottomprice',playername)..'"},\
													{"placeholder":"","default":"'..cfg.land_buy.price_sky..'","type":"input","text":"'..I18N('gui.oplandmgr.heightprice',playername)..'"},\
													{"min":0,"max":100,"step":1,"default":'..tostring(cfg.land_buy.refund_rate*100)..',"type":"slider","text":"'..I18N('gui.oplandmgr.refundrate',playername)..'"},\
													{"type":"label","text":"'..I18N('gui.oplandmgr.pluginconfig',playername)..'"},\
													{"default":'..tostring(cfg.update_check)..',"type":"toggle","text":"'..I18N('gui.oplandmgr.checkupdate',playername)..'"}],\
													"type":"custom_form","title":"'..I18N('gui.oplandmgr.title',playername)..'"}')
end
-- Minecraft 监听事件
function onDestroyBlock(e)
	local lid=getLandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_destory==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false	
end
function onAttack(e)
	local lid=getLandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_attack==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onUseItem(e)
	local lid=getLandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_use_item==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	if(e.blockname=='minecraft:barrel') then return end --sbmojang
	return false
end
function onPlacedBlock(e)
	local lid=getLandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_place==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onLevelExplode(e)
	local lid=getLandFromPos(e.position,e.dimensionid)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_exploding==true) then return end --权限允许
	return false
end
function onStartOpenChest(e)
	local lid=getLandFromPos(e.position,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_open_chest==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onPickUpItem(e)
	local lid=getLandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_pickupitem==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onDropItem(e)
	local lid=getLandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_dropitem==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	return false
end
function onStartOpenBarrel(e)
	local lid=getLandFromPos(e.XYZ,e.dimensionid)
	local xuid=luaapi:GetXUID(e.playername)
	if(lid==-1) then return end
	if(land_data[lid].setting.allow_open_barrel==true) then return end --权限允许
	if(isValInList(cfg.manager.operator,xuid)~=-1) then return end --manager
	if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],lid)~=-1) then return end --主人
	if(isValInList(land_data[lid].setting.share,xuid)~=-1) then return end --信任
	mc:disconnectClient(luaapi:GetUUID(e.playername),'你再开个试试？')-- 妈的，干就完了
end
-- 拓展功能函数
function money_add(a,b) --a=playername b=value
	mc:runcmd('scoreboard players add "'..a..'" "'..cfg.money.scoreboard_objname..'" '..b)
end
function money_del(a,b) --a=playername b=value
	mc:runcmd('scoreboard players remove "'..a..'" "'..cfg.money.scoreboard_objname..'" '..b)
end
function money_get(a) --a=playername
	return(mc:getscoreboard(luaapi:GetUUID(a),cfg.money.scoreboard_objname))
end
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
-- 注册监听
luaapi:Listen('onInputCommand', Monitor_CommandArrived)
luaapi:Listen('onFormSelect', Monitor_FormArrived)
luaapi:Listen('onLoadName', Event_PlayerJoin)
luaapi:Listen('onDestroyBlock',onDestroyBlock)
luaapi:Listen('onAttack',onAttack)
luaapi:Listen('onUseItem',onUseItem)
luaapi:Listen('onPlacedBlock',onPlacedBlock)
luaapi:Listen('onLevelExplode',onLevelExplode)
luaapi:Listen('onStartOpenChest',onStartOpenChest)
luaapi:Listen('onDropItem',onDropItem)
luaapi:Listen('onPickUpItem',onPickUpItem)
luaapi:Listen('onStartOpenBarrel',onStartOpenBarrel)
mc:setCommandDescribe('land', I18N('command.land',0))
mc:setCommandDescribe('land new', I18N('command.land_new',0))
mc:setCommandDescribe('land giveup', I18N('command.land_giveup',0))
mc:setCommandDescribe('land a', I18N('command.land_a',0))
mc:setCommandDescribe('land b', I18N('command.land_b',0))
mc:setCommandDescribe('land buy', I18N('command.land_buy',0))
mc:setCommandDescribe('land gui', I18N('command.land_gui',0))
print('[ILand] plugin loaded! VER:' .. plugin_version)