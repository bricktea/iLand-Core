-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.1'
--local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\' <DEV>
local data_path = 'plugins\\LiteLuaLoader\\lua\\iland\\'
local lib_path = ''
local newLand={};local TRS_Form={}
local MainCmd = 'land'
local json = require('cjson')

-- check file
if IfFile(data_path..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- load data file
local cfg = json.decode(ReadAllText(data_path..'config.json'))
land_data = json.decode(ReadAllText(data_path..'data.json'))
land_owners = json.decode(ReadAllText(data_path..'owners.json'))
local i18n_data = json.decode(ReadAllText(data_path..'lang\\'..cfg.manager.default_language..'.json'))

-- listen -> event
function EV_playerJoin(e)
	TRS_Form[e]={}
	local xuid=Actor:getXuid(e)
	if land_owners[xuid]==nil then
		land_owners[xuid]={}
		iland_save()
	end
end
-- form -> callback
function FORM_NULL(a,b,c,d) end
function FORM_land(player,index,text)
	if text==_tr('gui.general.close') then return end
	-- GUI(player,'land_mgr',xxx)
end
function FORM_land_buy(player,index,text)
	local xuid = Actor:getXuid(player)
	local player_credits = money_get(player)
	if (newLand[player].landprice > player_credits) then
		Actor:sendText(player,_tr('title.buyland.moneynotenough'),5);return
	else
		money_del(player,newLand[player].landprice)
	end
	Actor:sendText(player,_tr('title.buyland.succeed'),5)
	ILAPI_CreateLand(player,newLand[player].posA,newLand[player].posB,newLand[player].dim)
	newLand[player]=nil
	GUI(player,'ModalForm','FORM_land_gui',
								"Complete.",
								_tr('gui.buyland.succeed'),
								_tr('gui.general.looklook'),
								_tr('gui.general.cancel'))
end
function FORM_land_gui_perm(player,raw,data)
	local landid=TRS_Form[player].landid
	-- [1]null     [2]PlaceBlock [3]DestoryBlock [4]openChest  [5]Attack 
	-- [6]DropItem [7]PickupItem [8]UseItem      [9]openBarrel [10]null
	-- [11]Explode
	land_data[landid].permissions.allow_destory=raw[3]
	land_data[landid].permissions.allow_place=raw[2]
	land_data[landid].permissions.allow_exploding=raw[11]
	land_data[landid].permissions.allow_attack=raw[5]
	land_data[landid].permissions.allow_open_chest=raw[4]
	land_data[landid].permissions.allow_pickupitem=raw[7]
	land_data[landid].permissions.allow_dropitem=raw[6]
	land_data[landid].permissions.allow_use_item=raw[8]
	land_data[landid].permissions.allow_open_barrel=raw[9]
	iland_save()
end
function FORM_land_gui_trust(player,raw,data)
	local landid=TRS_Form[player].landid
	-- [1]null [2]1(true) [3]0 [4]0(false) [5]0
	if raw[2]==1 then
		if raw[3]==0 then return end
		local x=Actor:str2xid(TRS_Form[player].playerList[raw[3]+1])
		local n=#land_data[landid].settings.share+1
		if(Actor:getXuid(player)==x) then
			Actor:sendText(player,_tr('title.landtrust.cantaddown'),5);return
		end
		if(isValInList(land_data[landid].settings.share,x)~=-1) then
			Actor:sendText(player,_tr('title.landtrust.alreadyexists'),5);return
		end
		land_data[landid].settings.share[n]=x
		iland_save()
		if(result[4]~=1) then 
			GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
		end
	end
	if raw[4]==1 then
		if raw[3]==0 then return end
		local x=land_data[landid].settings.share[raw[5]+1]
		table.remove(land_data[landid].settings.share,isValInList(land_data[landid].settings.share,x))
		iland_save()
		GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
	end
end
function FORM_land_gui_name(player,raw,data)
	local landid=TRS_Form[player].landid
	if isTextSpecial(raw[2]) then
		Actor:sendText(player,'FAILED',5);return
	end
	land_data[landid].settings.nickname=raw[2]
	iland_save()
	GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
												'Complete.',
												_tr('gui.general.back'),
												_tr('gui.general.close'))
end
function FORM_land_gui_transfer(player,raw,data)
	if raw[2]==0 then return end
	local landid=TRS_Form[player].landid
	local xuid=Actor:getXuid(player)
	local go=Actor:str2xid(TRS_Form[player].playerList[raw[2]+1])
	if go==xuid then Actor:sendText(player,_tr('title.landtransfer.canttoown'),5);return end
	if land_owners[go]==nil then land_owners[go]={} end
	table.remove(land_owners[xuid],isValInList(land_owners[xuid],landid))
	table.insert(land_owners[go],#land_owners[go]+1,landid)
	iland_save()
	GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
									gsubEx(_tr('title.landtransfer.complete'),
										'<a>',ILAPI_GetNickname(landid),
										'<b>',Actor:xid2str(go)),
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function FORM_land_gui_delete(player,index,text)
	if index==1 then return end
	local landid=TRS_Form[player].landid
	local xuid=Actor:getXuid(player)
	land_data[landid]=nil
	table.remove(land_owners[xuid],isValInList(land_owners[xuid],landid))
	money_add(player,TRS_Form[player].landvalue)
	iland_save()
	GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
										'Complete.',
										_tr('gui.general.back'),
										_tr('gui.general.close'))
end
function FORM_land_gui(player,raw,data)
	local xuid=Actor:getXuid(player)
	local landid=land_owners[xuid][raw[3]+1]
	TRS_Form[player].landid=landid
	if raw[2]==0 then --查看领地信息
		local length = math.abs(land_data[landid].range.start_position[1] - land_data[landid].range.end_position[1])
		local width = math.abs(land_data[landid].range.start_position[3] - land_data[landid].range.end_position[3])
		local height = math.abs(land_data[landid].range.start_position[2] - land_data[landid].range.end_position[2])
		local vol = length * width * height
		local squ = length * width
		local nname=ILAPI_GetNickname(landid)
		if nname=='' then nname='<'.._tr('gui.landmgr.unnamed')..'>' end
		GUI(player,'ModalForm','FORM_NULL',_tr('gui.landmgr.landinfo.title'),
									gsubEx(_tr('gui.landmgr.landinfo.content'),
										'<a>',Actor:getName(player),
										'<m>',landid,
										'<n>',nname,
										'<b>',land_data[landid].range.start_position[1],
										'<c>',land_data[landid].range.start_position[2],
										'<d>',land_data[landid].range.start_position[3],
										'<e>',land_data[landid].range.end_position[1],
										'<f>',land_data[landid].range.end_position[2],
										'<g>',land_data[landid].range.end_position[3],
										'<h>',length,'<i>',width,'<j>',height,
										'<k>',squ,'<l>',vol),
									_tr('gui.general.iknow'),
									_tr('gui.general.close'))
	end
	if raw[2]==1 then --编辑领地权限
		local d=land_data[landid].permissions
		GUI(player,'lmgr_landperm','FORM_land_gui_perm',_tr('gui.landmgr.landperm.title'),
							_tr('gui.landmgr.landperm.options.title'),
							_tr('gui.landmgr.landperm.options.place'),tostring(d.allow_place),
							_tr('gui.landmgr.landperm.options.destroy'),tostring(d.allow_destory),
							_tr('gui.landmgr.landperm.options.openchest'),tostring(d.allow_open_chest),
							_tr('gui.landmgr.landperm.options.attack'),tostring(d.allow_attack),
							_tr('gui.landmgr.landperm.options.dropitem'),tostring(d.allow_dropitem),
							_tr('gui.landmgr.landperm.options.pickupitem'),tostring(d.allow_pickupitem),
							_tr('gui.landmgr.landperm.options.useitem'),tostring(d.allow_use_item),
							_tr('gui.landmgr.landperm.options.openbarrel'),tostring(d.allow_open_barrel),
							_tr('gui.landmgr.landperm.editevent'),
							_tr('gui.landmgr.landperm.options.exploding'),tostring(d.allow_exploding)
						)
	end
	if raw[2]==2 then --编辑信任名单
		TRS_Form[player].playerList = {'['.._tr('gui.general.plzchose')..']'} --wait for fix.
		local d=shacopy(land_data[landid].settings.share)
		for i, v in pairs(d) do
			d[i]=Actor:xid2str(d[i])
		end
		table.insert(d,1,'['.._tr('gui.general.plzchose')..']') -- fuck bugs.
		GUI(player,'lmgr_landtrust','FORM_land_gui_trust',_tr('gui.landtrust.title'),
												_tr('gui.landtrust.tip'),
												_tr('gui.landtrust.addtrust'),
												_tr('gui.landtrust.selectplayer'),json.encode(TRS_Form[player].playerList),
												_tr('gui.landtrust.rmtrust'),
												_tr('gui.landtrust.selectplayer'),json.encode(d))
	end
	if raw[2]==3 then --领地nickname
		local nickn=ILAPI_GetNickname(landid)
		if nickn=='' then nickn='['.._tr('gui.landmgr.unnamed')..']' end
		GUI(player,'lmgr_landname','FORM_land_gui_name',_tr('gui.landtag.title'),
														_tr('gui.landtag.tip'),
														nickn)
	end
	if raw[2]==4 then --领地过户
		TRS_Form[player].playerList = {'['.._tr('gui.general.plzchose')..']','redbeanw'} --wait for fix.
		GUI(player,'lmgr_landtransfer','FORM_land_gui_transfer',_tr('gui.landtransfer.title'),
									_tr('gui.landtransfer.tip'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
	end
	if raw[2]==5 then --删除领地
		local height = math.abs(land_data[landid].range.start_position[2] - land_data[landid].range.end_position[2])
		local squ = math.abs(land_data[landid].range.start_position[1] - land_data[landid].range.end_position[1]) * math.abs(land_data[landid].range.start_position[3] - land_data[landid].range.end_position[3])
		TRS_Form[player].landvalue=math.floor((squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)*cfg.land_buy.refund_rate)
		GUI(player,'ModalForm','FORM_land_gui_delete',_tr('gui.delland.title'),
												gsubEx(_tr('gui.delland.content'),
													'<a>',TRS_Form[player].landvalue,
													'<b>',_tr('talk.credit_name')),
												_tr('gui.general.yes'),
												_tr('gui.general.cancel'))
	end
end
function IL_BP_SelectRange(player, vec4, mode)
    if (newLand[player]==nil) then
		Actor:sendText(player,_tr('title.selectrange.nolic'),5);return
    end
    if (mode == 0) then -- point a
        if (mode ~= newLand[player].step) then
			Actor:sendText(player,_tr('title.selectrange.failbystep'),5);return
        end
		newLand[player].dim = vec4.dim
		newLand[player].posA = vec4
		newLand[player].posA.x=math.floor(newLand[player].posA.x) --省函数...
		newLand[player].posA.y=math.floor(newLand[player].posA.y)-2
		newLand[player].posA.z=math.floor(newLand[player].posA.z)
		Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posA.x .. '\nY=' .. newLand[player].posA.y .. '\nZ=' .. newLand[player].posA.z ..'\n'.._tr('title.selectrange.spointb'),5)
        newLand[player].step = 1
    end
    if (mode == 1) then -- point b
        if (mode ~= newLand[player].step) then
			Actor:sendText(player,_tr('title.selectrange.failbystep'),5);return
        end
        if (vec4.dim ~= newLand[player].dim) then
			Actor:sendText(player,_tr('title.selectrange.failbycdim'),5);return
        end
		newLand[player].posB = vec4
		newLand[player].posB.x=math.floor(newLand[player].posB.x)
		newLand[player].posB.y=math.floor(newLand[player].posB.y)-2
		newLand[player].posB.z=math.floor(newLand[player].posB.z)
        Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posB.x .. '\nY=' .. newLand[player].posB.y .. '\nZ=' .. newLand[player].posB.z ..'\n'.._tr('title.selectrange.bebuy'),5)
		newLand[player].step = 2
    end
end
function IL_BP_CreateOrder(player)
	local xuid = Actor:getXuid(player)
    if (newLand[player]==nil or newLand[player].step ~= 2) then
		Actor:sendText(player,_tr('title.createorder.failbystep'))
        return
    end
    local length = math.abs(newLand[player].posA.x - newLand[player].posB.x)
    local width = math.abs(newLand[player].posA.z - newLand[player].posB.z)
    local height = math.abs(newLand[player].posA.y - newLand[player].posB.y)
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if(squ>cfg.land.land_max_square and isValInList(cfg.manager.operator,xuid)==-1) then
		Actor:sendText(player,_tr('title.createorder.toobig'),5)
		newLand[player].step=0
		return
	end
	if(squ<cfg.land.land_min_square and isValInList(cfg.manager.operator,xuid)==-1) then
		Actor:sendText(player,_tr('title.createorder.toosmall'),5)
		newLand[player].step=0
		return
	end
	if(height<4) then
		Actor:sendText(player,_tr('title.createorder.toolow'),5)
		newLand[player].step=0
		return
	end
	local edge=cubeGetEdge(newLand[player].posA,newLand[player].posB)
	for i=1,#edge do
		for landId, val in pairs(land_data) do
			if(land_data[landId].range.dim~=newLand[player].dim) then goto JUMPOUT_1 end --维度不同直接跳过
			local s_pos={};s_pos.x=land_data[landId].range.start_position[1];s_pos.y=land_data[landId].range.start_position[2];s_pos.z=land_data[landId].range.start_position[3]
			local e_pos={};e_pos.x=land_data[landId].range.end_position[1];e_pos.y=land_data[landId].range.end_position[2];e_pos.z=land_data[landId].range.end_position[2]
			if(isPosInCube(edge[i],s_pos,e_pos)==true) then
				Actor:sendText(player,_tr('title.createorder.collision'),5)
				newLand[player].step=0
				return
			end
			:: JUMPOUT_1 ::
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if(land_data[landId].range.dim~=newLand[player].dim) then goto JUMPOUT_2 end --维度不同直接跳过
		s_pos={};e_pos={}
		s_pos.x=land_data[landId].range.start_position[1]
		s_pos.y=land_data[landId].range.start_position[2]
		s_pos.z=land_data[landId].range.start_position[3]
		e_pos.x=land_data[landId].range.end_position[1]
		e_pos.y=land_data[landId].range.end_position[2]
		e_pos.z=land_data[landId].range.end_position[3]
		edge=cubeGetEdge(s_pos,e_pos)
		for i=1,#edge do
			if(isPosInCube(edge[i],newLand[player].posA,newLand[player].posB)==true) then
				Actor:sendText(player,_tr('title.createorder.collision'),5)
				newLand[player].step=0
				return
			end
		end
		:: JUMPOUT_2 ::
	end
	--- 购买
    newLand[player].landprice = math.floor(squ * cfg.land_buy.price_ground + height * cfg.land_buy.price_sky)
	GUI(player,'ModalForm','FORM_land_buy', -- %1 callback
						_tr('gui.buyland.title'), --%2 title
						gsubEx(_tr('gui.buyland.content'),'<a>',length,'<b>',width,'<c>',height,'<d>',vol,'<e>',newLand[player].landprice,'<f>',_tr('talk.credit_name'),'<g>',money_get(player)), -- %3 content
						_tr('gui.general.buy'), -- %4 button1
						_tr('gui.general.close')) --%5 button2
end
function IL_BP_GiveUp(player)
    if (newLand[player]==nil) then
        Actor:sendText(player,_tr('title.giveup.failed'),5);return
    end
	newLand[player]=nil
	Actor:sendText(player,_tr('title.giveup.succeed'),5)
end
function IL_Manager_GUI(player)
	local xuid=Actor:getXuid(player)
	local xyz=pos2vec({Actor:getPos(player)})
	local lid=getLandFromPos(xyz)
	local welcomeText=_tr('gui.landmgr.content')
	if(lid~=-1) then
		welcomeText=welcomeText..gsubEx(_tr('gui.landmgr.ctplus'),'<a>',lid)
	end
	if(#land_owners[xuid]==0) then
		Actor:sendText(player,_tr('title.landmgr.failed'),5);return
	end
	local features={_tr('gui.landmgr.options.landinfo'),_tr('gui.landmgr.options.landperm'),_tr('gui.landmgr.options.landtrust'),_tr('gui.landmgr.options.landtag'),_tr('gui.landmgr.options.landtransfer'),_tr('gui.landmgr.options.delland')}
	local lands={}
	for i,v in pairs(land_owners[xuid]) do
		local f=ILAPI_GetNickname(v)
		if f=='' then f='['.._tr('gui.landmgr.unnamed')..'] '..v end
		lands[i]=f
	end
	GUI(player,'lmgr','FORM_land_gui', -- %1 callback
								_tr('gui.landmgr.title'), -- %2 title
								welcomeText, -- %3 label
								_tr('gui.oplandmgr.selectoption'), --%4 dropdown->text
								json.encode(features), -- %5 dropdown->args
								_tr('gui.landmgr.select'), -- %6 dropdown->text
								json.encode(lands)) -- %7 dropdown->args
end
function IL_CmdFunc(player,cmd)
	if player==0 then return end
	local xuid=Actor:getXuid(player)
	-- [ ] Main Command
	if cmd == MainCmd then
		land_count=tostring(#land_owners[xuid])
		GUI(player,'ModalForm','FORM_land', -- %1 callback
						gsubEx(_tr('gui.land.title'),'<a>',plugin_version), -- %2 title
						gsubEx(_tr('gui.land.content'),'<a>',land_count,'<b>',cfg.land_buy.price_ground,'<c>',_tr('talk.credit_name'),'<d>',cfg.land_buy.price_sky), _tr('talk.landmgr.open'), _tr('gui.general.close'), -- %3 content
						_tr('talk.landmgr.open'), --%4 button1
						_tr('gui.general.close')) --%5 button2
	end
	-- [new] Create newLand
	if cmd == MainCmd..' new' then
		if (newLand[player]~=nil) then
			Actor:sendText(player,_tr('title.getlicense.alreadyexists'),5);return -1
		end
		if(isValInList(cfg.manager.operator,xuid)==-1) then
			if(#land_owners[xuid]>=cfg.land.player_max_lands) then
				Actor:sendText(player,_tr('title.getlicense.limit'),5);return -1
			end
		end
		Actor:sendText(player,_tr('title.getlicense.succeed'),5)
		newLand[player]={}
		newLand[player].step=0
	end
	-- [a] Select point A
	if cmd == MainCmd..' a' then
		local xyz=pos2vec({Actor:getPos(player)})
		IL_BP_SelectRange(player,xyz,0)
	end
	-- [b] Select point B
	if cmd == MainCmd..' b' then
		local xyz=pos2vec({Actor:getPos(player)})
		IL_BP_SelectRange(player,xyz,1)
	end
	-- [buy] Create order to buy land
	if cmd == MainCmd..' buy' then
		IL_BP_CreateOrder(player)
	end
	-- [giveup] Give up incp land
	if cmd == MainCmd..' giveup' then
		IL_BP_GiveUp(player)
	end
	-- [gui] LandMgr GUI
	if cmd == MainCmd..' gui' then
		IL_Manager_GUI(player)
	end
	-- [mgr] OP-LandMgr GUI
	if cmd == MainCmd..' mgr' then
	end
	-- [X] Disable Output
	if string.sub(cmd,1,5)==MainCmd..' ' or string.sub(cmd,1,4)==MainCmd then
		return -1
	end
end

-- ILAPI
function ILAPI_CreateLand(playerptr,startpos,endpos,dimensionid)
	local xuid=Actor:getXuid(playerptr)
	local landId=getGuid()
	land_data[landId]={}
	land_data[landId].settings={}
	land_data[landId].settings.share={}
	land_data[landId].settings.nickname=""
	land_data[landId].range={}
	land_data[landId].range.start_position={}
	table.insert(land_data[landId].range.start_position,1,startpos.x)
	table.insert(land_data[landId].range.start_position,2,startpos.y)
	table.insert(land_data[landId].range.start_position,3,startpos.z)
	land_data[landId].range.end_position={}
	table.insert(land_data[landId].range.end_position,1,endpos.x)
	table.insert(land_data[landId].range.end_position,2,endpos.y)
	table.insert(land_data[landId].range.end_position,3,endpos.z)
	land_data[landId].range.dim=dimensionid
	land_data[landId].permissions.allow_destory=false
	land_data[landId].permissions.allow_place=false
	land_data[landId].permissions.allow_exploding=false
	land_data[landId].permissions.allow_attack=false
	land_data[landId].permissions.allow_open_chest=false
	land_data[landId].permissions.allow_open_barrel=false
	land_data[landId].permissions.allow_pickupitem=false
	land_data[landId].permissions.allow_dropitem=true
	land_data[landId].permissions.allow_use_item=true
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	iland_save()
end
function ILAPI_GetNickname(landid)
	if land_data[landid]==nil then 
		print('[ILAPI] WARN!! Getting nil land('..landid..').')
		return '' 
	end
	return land_data[landid].settings.nickname
end
-- feature function
function iland_save()
	WriteAllText(data_path..'config.json',json.encode(cfg))
	WriteAllText(data_path..'players.json',json.encode(playerCfg))
	WriteAllText(data_path..'data.json',json.encode(land_data))
	WriteAllText(data_path..'owners.json',json.encode(land_owners))
end
function _tr(a)
	return i18n_data[a]
end
function getGuid() -- [NOTICE] This function is from Internet.
    local seed={'e','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f'}
    local tb={}
	---math.randomseed(os.time)
    for i=1,32 do
        table.insert(tb,seed[math.random(1,16)])
    end
    local sid=table.concat(tb)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(sid,1,8),
        string.sub(sid,9,12),
        string.sub(sid,13,16),
        string.sub(sid,17,20),
        string.sub(sid,21,32)
    )
end
function gsubEx(y,a,a1,b,b1,c,c1,d,d1,e,e1,f,f1,g,g1,h,h1,i,i1,j,j1,k,k1,l,l1,m,m1,n,n1)
	local z=string.gsub(y,a,a1)
	if b~=nil then z=string.gsub(z,b,b1) else return z end
	if c~=nil then z=string.gsub(z,c,c1) else return z end
	if d~=nil then z=string.gsub(z,d,d1) else return z end
	if e~=nil then z=string.gsub(z,e,e1) else return z end
	if f~=nil then z=string.gsub(z,f,f1) else return z end
	if g~=nil then z=string.gsub(z,g,g1) else return z end
	if h~=nil then z=string.gsub(z,h,h1) else return z end
	if i~=nil then z=string.gsub(z,i,i1) else return z end
	if j~=nil then z=string.gsub(z,j,j1) else return z end
	if k~=nil then z=string.gsub(z,k,k1) else return z end
	if l~=nil then z=string.gsub(z,l,l1) else return z end
	if m~=nil then z=string.gsub(z,m,m1) else return z end
	if n~=nil then z=string.gsub(z,n,n1) else return z end
	return z
end

function money_add(player,value)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		runCmd('scoreboard players add "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	if cfg.money.protocol=='llmoney' then
		runCmd('money add "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..cfg.money.protocol..'\' !')
end
function money_del(player,value)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		runCmd('scoreboard players remove "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	if cfg.money.protocol=='llmoney' then
		runCmd('money reduce "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..cfg.money.protocol..'\' !')
end
function money_get(player)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		local n={runCmdEx('scoreboard players list "'..playername..'"')};n=n[2]
		local t=string.len(cfg.money.scoreboard_objname..':')
		local j=split(n,' ')
		local r,f=0
		for i,v in pairs(j) do
			f=string.find(v,cfg.money.scoreboard_objname..':',0)
			if f~=nil and string.len(v)==t then
				r=j[i+1];break
			end
		end
		return tonumber(r)
	end
	if cfg.money.protocol=='llmoney' then
		local n={runCmdEx('money query "'..playername..'"')};n=n[2]
		a=n:gsub('%D+','')
		return tonumber(a)
	end
	print('[ILand] ERR!! Unknown money protocol \''..cfg.money.protocol..'\' !')
end
function pos2vec(table) -- [x,y,z,d] => {x:x,y:y,z:z,d:d}
	local t={}
	t.x=table[1]
	t.y=table[2]
	t.z=table[3]
	t.dim=table[4]
	return t
end
function sendTitle(player,title,subtitle)
	local playername = Actor:getName(player)
	mc:runcmd('title "' .. playername .. '" times 20 25 20')
	if subtitle~=nil then
	mc:runcmd('title "' .. playername .. '" subtitle '..subtitle) end
	mc:runcmd('title "' .. playername .. '" title '..title)
end
function getLandFromPos(vec4)
	for landId, val in pairs(land_data) do
		if(land_data[landId].range.dim~=vec4.dim) then goto JUMPOUT_4 end
		local s_pos={};s_pos.x=land_data[landId].range.start_position[1];s_pos.y=land_data[landId].range.start_position[2];s_pos.z=land_data[landId].range.start_position[3]
		local e_pos={};e_pos.x=land_data[landId].range.end_position[1];e_pos.y=land_data[landId].range.end_position[2];e_pos.z=land_data[landId].range.end_position[3]
		if(isPosInCube(vec4,s_pos,e_pos)==true) then
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
function shacopy(orig)
	local r={}
	for i=1,#orig do
		r[i]=orig[i]
	end
	return r
end
function deepcopy(orig) -- [NOTICE] This function from: lua-users.org
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
function split(str,reps) -- [NOTICE] This function from: blog.csdn.net
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end

Listen('onCMD',IL_CmdFunc)
Listen('onJoin',EV_playerJoin)
print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)