----------------------------------------
-- Author: RedbeanW -- License: GPLv3 --
--       未经许可 禁止盈利性用途      --
----------------------------------------
-- 插件版本，请勿修改
local plugin_version = '1.0.9'
local latest_version = plugin_version
local newLand = {}
local TRS_Form={}
-- Check File and Load Library
if (tool:IfFile('./ilua/lib/json.lua') == false) then
    print('[ILand] Where is my json library??!!')
    return false
end
if (tool:IfFile('./ilua/iland/config.json') == false) then
    print('[ILand] Where is my config file??!!')
    return false
end
if (tool:IfFile('./ilua/xuiddb.net.lua') == false) then
    print('[ILand] Where is my depending plugin(xuiddb)??!!')
    return false
end
if (tool:IfFile('./py/iLand_Enhance.py') == true) then
    print('[ILand] BDSpyrunner Enhance founded!')
else
	print('[ILand] BDSpyrunner Enhance not found!')
end
local json = require('./ilua/lib/json')
-- Encode Json File
cfg = json.decode(tool:ReadAllText('./ilua/iland/config.json'))
land_data = json.decode(tool:ReadAllText('./ilua/iland/data.json'))
land_owners = json.decode(tool:ReadAllText('./ilua/iland/owners.json'))
function iland_save() --需要提前...
	local a=tool:WorkingPath()
	tool:WriteAllText(a..'ilua\\iland\\config.json',json.encode(cfg))
	tool:WriteAllText(a..'ilua\\iland\\data.json',json.encode(land_data))
	tool:WriteAllText(a..'ilua\\iland\\owners.json',json.encode(land_owners))
end
do --update configure file
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
end
-- Check Update
if(cfg.update_check) then
	local t=tool:HttpGet('http://cdisk.amd.rocks/tmp/ILAND/version','')
	latest_version=string.sub(t,string.find(t,'<',1)+1,string.find(t,'>',1)-1)
	if(latest_version=='') then latest_version=plugin_version end
	if(plugin_version~=latest_version) then
		print('[ILand] 此服务器正在使用旧版领地插件，新版本 '..latest_version..' 已发布！')
		print('[ILand] 存在新版本，请前往https://cdisk.amd.rocks/ILAND.html获取。')
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
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid, 'Land v' .. plugin_version, '欢淫使用领地系统，宁现在有'..land_count..'块领地。\n今日地价：'..cfg.land_buy.price_ground..cfg.scoreboard.credit_name..'/平面格, '..cfg.land_buy.price_sky..cfg.scoreboard.credit_name..'/高', '打开领地管理器', '关闭')
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
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭')
	end
	--- Del Land ---
	if(TRS_Form[a.playername].delland==a.formid) then
		mc:runcmd('scoreboard players add "' .. a.playername .. '" ' .. cfg.scoreboard.name .. ' ' .. TRS_Form[a.playername].landvalue)
		land_data[lid]=nil
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		iland_save()
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭')
	end
	--- Land Trust ---
	if(TRS_Form[a.playername].ltrust==a.formid) then
		-- [1]null [2]true [3]0 [4]false [5]0
		local result=json.decode(a.selected)
		if(result[2]==true) then
			local x=luaapi:GetXUID(TRS_Form[a.playername].online[result[3]+1])
			local n=#land_data[lid].setting.share+1
			if(luaapi:GetXUID(a.playername)==x) then
				mc:runcmd('title "' .. a.playername .. '" actionbar 不能将您自己添加到信任列表中')
				return
			end
			if(isValInList(land_data[lid].setting.share,x)~=-1) then
				mc:runcmd('title "' .. a.playername .. '" actionbar 该玩家已存在于信任列表中')
				return
			end
			land_data[lid].setting.share[n]=x
			iland_save()
			if(result[4]~=true) then TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭') end
		end
		if(result[4]==true) then
			if(#land_data[lid].setting.share==0) then return end 
			local x=land_data[lid].setting.share[result[5]+1]
			table.remove(land_data[lid].setting.share,isValInList(land_data[lid].setting.share,x))
			iland_save()
			TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭')
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
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭')
	end
	--- OP LandMgr ---
	if(TRS_Form[a.playername].lmop==a.formid) then
		-- [1]null          [2]null       [3]选择的领地  [4]要进行的操作 [5]null
		-- [6]货币名称      [7]计分板名称 [8]null        [9]玩家最多领地 [10]最大领地面积 
		-- [11]最小领地面积 [12]null      [13]底面积价格 [14]高度价格    [15]退款率
		-- [16]null         [17]检查更新
		local result=json.decode(a.selected)
		local doi=true
		if isTextSpecial(result[3]) or isTextSpecial(result[4]) or isTextSpecial(result[6]) or isTextSpecial(result[7]) then doi=false end
		if not(isTextNum(result[9])) or not(isTextNum(result[10])) or not(isTextNum(result[11])) or not(isTextNum(result[13])) or not(isTextNum(result[14])) then doi=false end
		if(doi==false) then mc:runcmd('title "' .. a.playername .. '" actionbar 修改项存在不合法字符，已中断操作。');return end
		cfg.land.player_max_lands=tonumber(result[9])
		cfg.land.land_max_square=tonumber(result[10])
		cfg.land.land_min_square=tonumber(result[11])
		cfg.scoreboard.credit_name=result[6]
		cfg.scoreboard.name=result[7]
		cfg.land_buy.refund_rate=result[15]/100
		cfg.land_buy.price_ground=tonumber(result[13])
		cfg.land_buy.price_sky=tonumber(result[14])
		cfg.update_check=result[17]
		iland_save()
		if(result[4]==0) then TRS_Form.mb_lopm=mc:sendModalForm(uuid,'Complete','操作已完成。','返回上级菜单','关闭');return end
		local id,nid='',0 --getLandID
		for landId,val in pairs(land_data) do 
			if(nid==result[3]) then id=landId;break end
			nid=nid+1
		end
		if(id=='') then mc:runcmd('title "' .. a.playername .. '" actionbar 未选择任何领地');return end
		-- 1=teleport 2=delete
		if(result[4]==1) then
			luaapi:teleport(uuid,land_data[id].range.start_x,land_data[id].range.start_y,land_data[id].range.start_z,land_data[id].range.dim)
			mc:runcmd('title "' .. a.playername .. '" actionbar 已传送到 '..id)
		end
		if(result[4]==2) then
			land_data[id]=nil
			for ownerxuid,val in pairs(land_owners) do
				local nmsl=isValInList(val,id)
				if(nmsl~=-1) then
					table.remove(land_owners[ownerxuid],nmsl)
				end
			end
			iland_save()
			mc:runcmd('title "' .. a.playername .. '" actionbar '..id..' 已删除')
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
		local go=luaapi:GetXUID(TRS_Form[a.playername].online[result[2]+1])
		if(go==xuid) then mc:runcmd('title "' .. a.playername .. '" actionbar 不可以向自己过户领地');return end
		table.remove(land_owners[xuid],isValInList(land_owners[xuid],lid))
		table.insert(land_owners[go],#land_owners[go]+1,lid)
		iland_save()
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete',lid..' 已过户给 '..getPlayernameFromXUID(go),'返回上级菜单','关闭')
	end
end
function Func_Buy_giveup(playername)
    if (newLand[playername]==nil) then
        mc:runcmd('title "' .. playername .. '" actionbar 没有可以放弃的圈地许可')
        return
    end
	newland[playername]=nil
	mc:runcmd('title "' .. playername .. '" actionbar 许可已被放弃')
end
function Func_Buy_createOrder(playername)
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    if (newLand[playername]==nil or newLand[playername].step ~= 2) then
        mc:runcmd('title "' .. playername .. '" actionbar 购买失败！请按步骤圈地！')
        return
    end
    local length = math.abs(newLand[playername].posA.x - newLand[playername].posB.x)
    local width = math.abs(newLand[playername].posA.z - newLand[playername].posB.z)
    local height = math.abs(newLand[playername].posA.y - newLand[playername].posB.y)
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if(squ>cfg.land.land_max_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar 所圈领地太大，请重新圈地。\n请使用“/land a”选择第一个点')
		newLand[playername].step=0
		return
	end
	if(squ<cfg.land.land_min_square and isValInList(cfg.manager.operator,xuid)==-1) then
		mc:runcmd('title "' .. playername .. '" actionbar 所圈领地太小，请重新圈地。\n请使用“/land a”选择第一个点')
		newLand[playername].step=0
		return
	end
	if(height<3) then
		mc:runcmd('title "' .. playername .. '" actionbar 三维圈地，高度至少在三格以上。\n请使用“/land a”选择第一个点')
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
				mc:runcmd('title "' .. playername .. '" actionbar 存在领地冲突，请重新圈地。\n请使用“/land a”选择第一个点')
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
				mc:runcmd('title "' .. playername .. '" actionbar 存在领地冲突，请重新圈地。\n请使用“/land a”选择第一个点')
				newLand[playername].step=0
				return
			end
		end
		:: JUMPOUT_2 ::
	end
	--- 购买
    newLand[playername].landprice = math.floor(squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)
    newLand[playername].formid = mc:sendModalForm(uuid,'领地购买','圈地成功！\n长\\宽\\高: ' ..length ..'\\' ..width..'\\' ..height..'格\n体积: ' ..vol..'块\n价格: ' ..newLand[playername].landprice..cfg.scoreboard.credit_name .. '\n钱包: ' .. mc:getscoreboard(uuid, cfg.scoreboard.name) .. cfg.scoreboard.credit_name,'购买','放弃')
end
function Func_Buy_selectRange(playername, xyz, dim, mode)
    if (newLand[playername]==nil) then
        mc:runcmd('title "' .. playername .. '" actionbar 没有圈地许可!!\n请先使用“/land new”获取')
        return
    end
    if (mode == 0) then --posA
        if (mode ~= newLand[playername].step) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！请按步骤圈地！')
            return
        end
		newLand[playername].dim = dim
		newLand[playername].posA = xyz
		newLand[playername].posA.x=math.floor(newLand[playername].posA.x) --省函数...
		newLand[playername].posA.y=math.floor(newLand[playername].posA.y)-2
		newLand[playername].posA.z=math.floor(newLand[playername].posA.z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..newLand[playername].dim..'\nX=' .. newLand[playername].posA.x .. '\nY=' .. newLand[playername].posA.y .. '\nZ=' .. newLand[playername].posA.z ..'\n请使用“/land b”选定第二个点')
        newLand[playername].step = 1
    end
    if (mode == 1) then --posB
        if (mode ~= newLand[playername].step) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！请按步骤圈地！')
            return
        end
        if (dim ~= newLand[playername].dim) then
            mc:runcmd('title "' .. playername .. '" actionbar 选点失败！禁止跨纬度选点！')
            return
        end
		newLand[playername].posB = xyz
		newLand[playername].posB.x=math.floor(newLand[playername].posB.x)
		newLand[playername].posB.y=math.floor(newLand[playername].posB.y)-2
		newLand[playername].posB.z=math.floor(newLand[playername].posB.z)
		mc:runcmd('title "' ..playername .. '" actionbar DIM='..newLand[playername].dim..'\nX=' .. newLand[playername].posB.x .. '\nY=' .. newLand[playername].posB.y .. '\nZ=' .. newLand[playername].posB.z ..'\n请使用“/land buy”创建订单')
        newLand[playername].step = 2
    end
end
function Func_Buy_getLicense(playername)
	if (newLand[playername]~=nil) then
	    mc:runcmd('title "' .. playername .. '" actionbar 请勿重复请求!!\n请使用“/land a”选定第一个点')
        return
	end
	if(land_owners[luaapi:GetXUID(playername)]~=nil and isValInList(cfg.manager.operator,luaapi:GetXUID(playername))==-1) then
		if(#land_owners[luaapi:GetXUID(playername)]>cfg.land.player_max_lands) then
			mc:runcmd('title "' .. playername .. '" actionbar 你想当地主是吧，无产阶级是不能有这么多地的。')
			return
		end
	end
    mc:runcmd('title "' .. playername .. '" actionbar 已请求新建领地\n现在请输入命令“/land a”')
	newLand[playername]={}
	newLand[playername].step=0
end
function Func_Buy_callback(playername)
    local uuid = luaapi:GetUUID(playername)
	local xuid = luaapi:GetXUID(playername)
    local player_credits = mc:getscoreboard(uuid, cfg.scoreboard.name)
    if (newLand[playername].landprice > player_credits) then
        mc:runcmd('title "' .. playername .. '" actionbar 余额不足！\n您的领地购买订单已暂存，可重新用“/land buy”打开\n放弃此次购买请使用“/land giveup”')
        return
    else
        mc:runcmd('scoreboard players remove "' .. playername .. '" ' .. cfg.scoreboard.name .. ' ' .. newLand[playername].landprice)
    end
    mc:runcmd('title "' .. playername .. '" actionbar 购买成功！\n正在为您注册领地...')
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
	land_data[landId].setting.allow_open_barrel=false --开桶，须pyr补充插件配合
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
	TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'Complete','领地购买成功！是否现在打开领地管理器？。','看看','取消')
end
function Func_Manager_open(playername)
	local uuid=luaapi:GetUUID(playername)
	local xuid=luaapi:GetXUID(playername)
	local welcome='Welcome to use Land Manager.'
	local b=luaapi:createPlayerObject(uuid)
	local lid=getLandFromPos(json.decode(b.Position),b.DimensionId)
	if(lid~=-1) then
		welcome=welcome..'\n您现在正在: §l'..lid..' §r上'
	end
	if(land_owners[xuid]~=nil) then
		if(#land_owners[xuid]==0) then
			mc:runcmd('title "' .. playername .. '" actionbar 你还没有领地哦，使用“/land new”开始创建一个吧！')
			return
		end
	else
		mc:runcmd('title "' .. playername .. '" actionbar 你还没有领地哦，使用“/land new”开始创建一个吧！')
		return
	end
	TRS_Form[playername].mgr = mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"'..welcome..'"},{"default":0,"steps":["查看领地信息","编辑领地权限","编辑信任名单","编辑领地Tag","领地过户","删除领地"],"type":"step_slider","text":"选择要进行的操作"},{"default":0,"options":'..json.encode(land_owners[xuid])..',"type":"dropdown","text":"选择你要管理的领地"}],"type":"custom_form","title":"选择目标领地"}}]}')
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
		TRS_Form.mb_lmgr=mc:sendModalForm(uuid,'领地信息','所有者:'..a..'\n范围(range): '..land_data[TRS_Form[a].landid].range.start_x..','..land_data[TRS_Form[a].landid].range.start_y..','..land_data[TRS_Form[a].landid].range.start_z..' -> '..land_data[TRS_Form[a].landid].range.end_x..','..land_data[TRS_Form[a].landid].range.end_y..','..land_data[TRS_Form[a].landid].range.end_z..'\n长/宽/高: '..length..'/'..width..'/'..height..'\n底面积: '..squ..' 平方格    体积: '..vol..' 立方格','爷知道了','关闭')
	end
	if(result[2]==1) then --编辑领地权限
		local d=land_data[TRS_Form[a].landid].setting
		TRS_Form[a].lperm=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"编辑陌生人在领地内所拥有的权限"},{"default":'..tostring(d.allow_place)..',"type":"toggle","text":"允许放置方块"},{"default":'..tostring(d.allow_destory)..',"type":"toggle","text":"允许破坏方块"},{"default":'..tostring(d.allow_open_chest)..',"type":"toggle","text":"允许开箱子"},{"default":'..tostring(d.allow_attack)..',"type":"toggle","text":"允许攻击生物"},{"default":'..tostring(d.allow_dropitem)..',"type":"toggle","text":"允许丢物品"},{"default":'..tostring(d.allow_pickupitem)..',"type":"toggle","text":"允许捡起物品"},{"default":'..tostring(d.allow_use_item)..',"type":"toggle","text":"允许使用物品"},{"default":'..tostring(d.allow_open_barrel)..',"type":"toggle","text":"允许开桶"},{"type":"label","text":"编辑领地内可以发生的事件"},{"default":'..tostring(d.allow_exploding)..',"type":"toggle","text":"允许爆炸"}],"type":"custom_form","title":"Land Perms"}')
	end
	if(result[2]==2) then --编辑信任名单
		TRS_Form[a].online = getOnLinePlayerList()
		local d={}
		for i=1,#land_data[TRS_Form[a].landid].setting.share do --复制share列表中的每个元素，至于为什么不能直接赋值......
			d[i]=land_data[TRS_Form[a].landid].setting.share[i]
		end
		for i, v in pairs(d) do
			d[i]=getPlayernameFromXUID(d[i])
		end
		TRS_Form[a].ltrust=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"打开欲操作项的开关，完成后提交。"},{"default":false,"type":"toggle","text":"添加受信任玩家\n受信任玩家将拥有所有领地权限，但不能进行权限编辑或删除领地。"},{"type":"dropdown","text":"选择一个玩家","default":0,"options":'..json.encode(TRS_Form[a].online)..'},{"default":false,"type":"toggle","text":"删除受信任玩家"},{"type":"dropdown","text":"选择一个玩家","default":0,"options":'..json.encode(d)..'}],"type":"custom_form","title":"Land Trust"}')
	end
	if(result[2]==3) then --领地tag
		TRS_Form[a].ltag=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"领地Tag有助于您区分多个领地，而不改变原有的领地配置"},{"placeholder":"tag here","default":"","type":"input","text":""}],"type":"custom_form","title":"Land Tag"}')
	end
	if(result[2]==4) then --领地过户
		TRS_Form[a].online = getOnLinePlayerList()
		TRS_Form[a].ltsf=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"领地过户完成后，所有权限将被转移，您不再是该领地的主人，但原领地的所有配置不会改变。"},{"type":"dropdown","text":"选择目标玩家","default":0,"options":'..json.encode(TRS_Form[a].online)..'}],"type":"custom_form","title":"Land Transfer"}')
	end
	if(result[2]==5) then --删除领地
		local height = math.abs(land_data[TRS_Form[a].landid].range.start_y - land_data[TRS_Form[a].landid].range.end_y)
		local squ = math.abs(land_data[TRS_Form[a].landid].range.start_x - land_data[TRS_Form[a].landid].range.end_x) * math.abs(land_data[TRS_Form[a].landid].range.start_z - land_data[TRS_Form[a].landid].range.end_z)
		TRS_Form[a].landvalue=math.floor((squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)*cfg.land_buy.refund_rate)
		TRS_Form[a].delland=mc:sendModalForm(uuid,'删除领地','您确定要删除您的领地吗？\n'..'如果确定，您将得到'..TRS_Form[a].landvalue..cfg.scoreboard.credit_name..'退款。然后您的领地将失去保护，配置文件将立刻删除。','确定','取消')
	end
end
function Func_Manager_Operator(playername)
	local uuid=luaapi:GetUUID(playername)
	local lst={}
	local xuiddb=json.decode(tool:ReadAllText('./xuid.json'))
	for landId, val in pairs(land_data) do
		name='找不到该领地的主人'
		for xuid, pname in pairs(xuiddb) do
			if(land_owners[xuid]~=nil and isValInList(land_owners[xuid],landId)~=-1) then
				name=pname
			end
		end 
		table.insert(lst,#lst+1,landId..' ('..name..')')
	end
	TRS_Form[playername].lmop=mc:sendCustomForm(uuid,'{"content":[{"type":"label","text":"这里是管理员领地管理器, 可以直接编辑插件设置和管理全服领地, 尝试一下吧!"},{"type":"label","text":"§l领地数据管理"},{"default":0,"options":'..json.encode(lst)..',"type":"dropdown","text":"选择要管理的领地"},{"default":0,"steps":["啥也不干","传送到此领地","删除此领地"],"type":"step_slider","text":"选择要进行的操作"},{"type":"label","text":"§l计分板相关"},{"placeholder":"这里是服务器的通用货币名称，如金币","default":"'..cfg.scoreboard.credit_name..'","type":"input","text":"货币名称 (类型: 字符串)"},{"placeholder":"记录货币信息的计分板项目，一般为money","default":"'..cfg.scoreboard.name..'","type":"input","text":"计分板对应项名称 (类型: 字符串)"},{"type":"label","text":"§l领地配置相关"},{"placeholder":"","default":"'..cfg.land.player_max_lands..'","type":"input","text":"玩家最多拥有领地 (类型: 整数)"},{"placeholder":"","default":"'..cfg.land.land_max_square..'","type":"input","text":"最大圈地面积 (类型: 整数)"},{"placeholder":"","default":"'..cfg.land.land_min_square..'","type":"input","text":"最小圈地面积 (类型: 整数)"},{"type":"label","text":"§l领地购买相关"},{"placeholder":"","default":"'..cfg.land_buy.price_ground..'","type":"input","text":"底面积价格 (类型: 整数)"},{"placeholder":"","default":"'..cfg.land_buy.price_sky..'","type":"input","text":"高度价格 (类型: 整数)"},{"min":0,"max":100,"step":1,"default":'..tostring(cfg.land_buy.refund_rate*100)..',"type":"slider","text":"删除领地退款率 (％)"},{"type":"label","text":"§l插件设置"},{"default":'..tostring(cfg.update_check)..',"type":"toggle","text":"允许自动检查更新"}],"type":"custom_form","title":"LandMgr for Operator"}')
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
function getOnLinePlayerList()
	local list = {}
	local ylist = json.decode(mc:getOnLinePlayers())
	for i=1, #ylist do
		list[i]=ylist[i].playername
	end
	return list
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
mc:setCommandDescribe('land', '领地系统主命令')
mc:setCommandDescribe('land new', '创建一个新领地')
mc:setCommandDescribe('land giveup', '放弃没有创建完成的领地')
mc:setCommandDescribe('land a', '三维圈地，选取第一个点')
mc:setCommandDescribe('land b', '三维圈地，选取第二个点')
mc:setCommandDescribe('land buy', '购买刚圈好的地')
mc:setCommandDescribe('land gui', '打开领地管理界面')
print('[ILand] plugin loaded! VER:' .. plugin_version)