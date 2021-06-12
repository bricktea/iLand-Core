-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.4hotfix'
local langVer = 114
local minLLVer = 210610
local minAirVer = 100
local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\'
local newLand={};local TRS_Form={};local ArrayParticles={};ILAPI={}
local MainCmd = 'land'
local debug_mode = false
local json = require('dkjson')
local AIR = require('airLibs')

-- check file
if AIR.IfFile(data_path..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- check depends version
if tonumber(lllVersion()) < minLLVer then
	print('[ILand] ERR!! LLLua too old, please use latest version, here ↓')
	print('[ILand] ERR!! https://www.minebbs.com/resources/litelualoader-lua.2390/')
	print('[ILand] ERR!! Plugin closing...')
	return
end
if AIR.VERSION < minAirVer then
	print('[ILand] ERR!! AirLibs too old, please use latest version, here ↓')
	print('[ILand] ERR!! https://www.minebbs.com/')
	print('[ILand] ERR!! Plugin closing...')
	return
end

-- load data file
local cfg = json.decode(AIR.ReadAllText(data_path..'config.json'))
land_data = json.decode(AIR.ReadAllText(data_path..'data.json'))
land_owners = json.decode(AIR.ReadAllText(data_path..'owners.json'))

-- preload function
function ILAPI.save()
	AIR.WriteAllText(data_path..'config.json',json.encode(cfg,{indent=true}))
	AIR.WriteAllText(data_path..'data.json',json.encode(land_data))
	AIR.WriteAllText(data_path..'owners.json',json.encode(land_owners,{indent=true}))
end
function pos2chunk(posx,posz)
	local p = cfg.features.chunk_side
	if p<=4 then p=16 end
	a={}
	a.x=math.floor(posx/p)
	a.z=math.floor(posz/p)
	return a
end
function fmCube(sX,sY,sZ,eX,eY,eZ)
	local A=AIR.buildVec(sX,sY,sZ)
	local B=AIR.buildVec(eX,eY,eZ)
	local tmp1
	if A.x>B.x then A.x,B.x = B.x,A.x end
	if A.y>B.y then A.y,B.y = B.y,A.y end
	if A.z>B.z then A.z,B.z = B.z,A.z end
	return A,B
end

-- cfg -> updater
do
	if cfg.version==nil or cfg.version<107 then
		print('[ILand] Configure file too old, you must rebuild it.')
		return
	end
	if cfg.version==107 then
		cfg.version=110
		cfg.money={}
		cfg.features={}
		cfg.money.protocol='scoreboard'
		cfg.money.scoreboard_objname=cfg.scoreboard.name
		cfg.features.landSign=false
		cfg.features.frequency=10
		cfg.scoreboard=nil
		cfg.manager.i18n={}
		cfg.manager.i18n.enabled_languages={"zh_CN","zh_TW"}
		cfg.manager.i18n.default_language="zh_CN"
		cfg.manager.i18n.auto_language_byIP=false
		cfg.manager.i18n.allow_players_select_lang=true
		iland_save()
	end
	if cfg.version==110 then
		cfg.version=111
		cfg.manager.default_language=cfg.manager.i18n.default_language
		cfg.manager.i18n=nil
		for landid,data in pairs(land_data) do
			land_data[landid].settings={}
			land_data[landid].settings.share=AIR.deepcopy(land_data[landid].setting.share)
			land_data[landid].settings.nickname=''
			land_data[landid].permissions=AIR.deepcopy(land_data[landid].setting)
			land_data[landid].setting=nil
			land_data[landid].permissions.share=nil
			land_data[landid].range.start_position={}
			land_data[landid].range.end_position={}
			land_data[landid].range.start_position[1]=AIR.deepcopy(land_data[landid].range.start_x)
			land_data[landid].range.start_position[2]=AIR.deepcopy(land_data[landid].range.start_y)
			land_data[landid].range.start_position[3]=AIR.deepcopy(land_data[landid].range.start_z)
			land_data[landid].range.end_position[1]=AIR.deepcopy(land_data[landid].range.end_x)
			land_data[landid].range.end_position[2]=AIR.deepcopy(land_data[landid].range.end_y)
			land_data[landid].range.end_position[3]=AIR.deepcopy(land_data[landid].range.end_z)
			land_data[landid].range.start_x=nil
			land_data[landid].range.start_y=nil
			land_data[landid].range.start_z=nil
			land_data[landid].range.end_x=nil
			land_data[landid].range.end_y=nil
			land_data[landid].range.end_z=nil
		end
		iland_save()
	end
	if cfg.version==111 then
		cfg.version=112
		cfg.land_buy.calculation='m-1'
		cfg.land_buy.price={}
		cfg.land_buy.price[1]=AIR.deepcopy(cfg.land_buy.price_ground)
		cfg.land_buy.price[2]=AIR.deepcopy(cfg.land_buy.price_sky)
		cfg.land_buy.price_ground=nil
		cfg.land_buy.price_sky=nil
		cfg.features.chunk_side=16
		cfg.features.sign_frequency=AIR.deepcopy(cfg.features.frequency)
		cfg.features.frequency=nil
		for landId,val in pairs(land_data) do
			land_data[landId].settings.describe=''
		end
		iland_save()
	end
	if cfg.version==112 or cfg.version==113 then
		cfg.version=114
		for landId,data in pairs(land_data) do
			local sX=land_data[landId].range.start_position[1]
			local sY=land_data[landId].range.start_position[2]
			local sZ=land_data[landId].range.start_position[3]
			local eX=land_data[landId].range.end_position[1]
			local eY=land_data[landId].range.end_position[2]
			local eZ=land_data[landId].range.end_position[3]
			local result={fmCube(sX,sY,sZ,eX,eY,eZ)}
			local posA=result[1]
			local posB=result[2]
			land_data[landId].range.start_position[1]=posA.x
			land_data[landId].range.start_position[2]=posA.y
			land_data[landId].range.start_position[3]=posA.z
			land_data[landId].range.end_position[1]=posB.x
			land_data[landId].range.end_position[2]=posB.y
			land_data[landId].range.end_position[3]=posB.z
		end
		cfg.features.particles=true
		cfg.features.selection_tool='minecraft:wooden_axe'
		cfg.features.particle_effects='minecraft:villager_happy'
		iland_save()
	end
	if cfg.version==114 then
		cfg.version=115
		for landId,data in pairs(land_data) do
		end
		-- iland_save()
	end
end

-- load language file
local i18n_data = json.decode(AIR.ReadAllText(data_path..'lang\\'..cfg.manager.default_language..'.json'))
if i18n_data.VERSION ~= langVer then
	print('[ILand] ERR!! Language file does not match version, plugin is closing... (!='..langVer..')')
	return
end

-- load chunks
local ChunkMap={}
function buildChunks()
	ChunkMap={}
	function chkmap(x,z)
		if ChunkMap[x] == nil then ChunkMap[x] = {} end
		if ChunkMap[x][z] == nil then ChunkMap[x][z] = {} end
	end
	local size = cfg.features.chunk_side
	for landId,data in pairs(land_data) do
		local sX = data.range.start_position[1]
		local sZ = data.range.start_position[3]
		local eX = data.range.end_position[1]
		local eZ = data.range.end_position[3]
		local count = 0
		while (sX+size*count<=eX+size) do
			local t = pos2chunk(sX+size*count,sZ+size*count)
			chkmap(t.x,t.z)
			table.insert(ChunkMap[t.x][t.z],#ChunkMap[t.x][t.z]+1,landId)
			local count2 = 0
			while (sZ+size*count2<=eZ+size) do
				local t = pos2chunk(sX+size*count,sZ+size*count2)
				chkmap(t.x,t.z)
				table.insert(ChunkMap[t.x][t.z],#ChunkMap[t.x][t.z]+1,landId)
				count2 = count2 + 1
			end
			count = count +1
		end
	end
end
buildChunks()

-- load land VecMap
local vecMap={}
function buildVecMap()
	vecMap={}
	for landId,data in pairs(land_data) do
		local spos = land_data[landId].range.start_position
		local epos = land_data[landId].range.end_position
		vecMap[landId]={}
		vecMap[landId].a={};vecMap[landId].b={}
		vecMap[landId].a = AIR.buildVec(spos[1],spos[2],spos[3]) --start
		vecMap[landId].b = AIR.buildVec(epos[1],epos[2],epos[3]) --end
	end
end
buildVecMap()

-- listen -> event
debug_landquery = 0
function EV_playerJoin(e)
	TRS_Form[e]={}
	TRS_Form[e].inland='null'
	local xuid=Actor:getXuid(e)
	if land_owners[xuid] == nil then
		land_owners[xuid]={}
		ILAPI.save()
	end
end
function EV_playerLeft(e)
	TRS_Form[e]=nil
	ArrayParticles[e]=nil
end

-- form -> callback
function FORM_BACK_LandOPMgr(player,index,text)
	if index==1 then return end
	IL_Manager_OPGUI(player)
end
function FORM_BACK_LandMgr(player,index,text)
	if index==1 then return end
	IL_Manager_GUI(player)
end
function FORM_land_buy(player,index,text)
	if index~=0 then 
		Actor:sendText(player,AIR.gsubEx(_tr('title.buyland.ordersaved'),'<a>',cfg.features.selection_tool_name),5);return
	end
	local xuid = Actor:getXuid(player)
	local player_credits = money_get(player)
	if newLand[player].landprice>player_credits then
		Actor:sendText(player,_tr('title.buyland.moneynotenough')..AIR.gsubEx(_tr('title.buyland.ordersaved'),'<a>',cfg.features.selection_tool_name),5);return
	else
		money_del(player,newLand[player].landprice)
	end
	Actor:sendText(player,_tr('title.buyland.succeed'),5)
	local A=newLand[player].posA
	local B=newLand[player].posB
	local result={fmCube(A.x,A.y,A.z,B.x,B.y,B.z)}
	ILAPI.CreateLand(xuid,result[1],result[2],newLand[player].dim)
	newLand[player]=nil
	GUI(player,'ModalForm','FORM_BACK_LandMgr',"Complete.",
								_tr('gui.buyland.succeed'),
								_tr('gui.general.looklook'),
								_tr('gui.general.cancel'))
end
function FORM_land_gui_perm(player,raw,data)
	local landid=TRS_Form[player].landid
	-- [1]null     [2]PlaceBlock [3]DestoryBlock [4]openChest  [5]Attack 
	-- [6]DropItem [7]PickupItem [8]UseItem      [9]openBarrel [10]null
	-- [11]Explode
	land_data[landid].permissions.allow_destory=AIR.toBool(raw[3])
	land_data[landid].permissions.allow_place=AIR.toBool(raw[2])
	land_data[landid].permissions.allow_exploding=AIR.toBool(raw[11])
	land_data[landid].permissions.allow_attack=AIR.toBool(raw[5])
	land_data[landid].permissions.allow_open_chest=AIR.toBool(raw[4])
	land_data[landid].permissions.allow_pickupitem=AIR.toBool(raw[7])
	land_data[landid].permissions.allow_dropitem=AIR.toBool(raw[6])
	land_data[landid].permissions.allow_use_item=AIR.toBool(raw[8])
	land_data[landid].permissions.allow_open_barrel=AIR.toBool(raw[9])
	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
end
function FORM_land_gui_trust(player,raw,data)
	local landid=TRS_Form[player].landid
	-- [1]null [2]1(true) [3]0 [4]0(false) [5]0
	if raw[2]==1 then
		if raw[3]==0 then return end
		local x=Actor:str2xid(TRS_Form[player].playerList[raw[3]+1])
		local n=#land_data[landid].settings.share+1
		if Actor:getXuid(player)==x then
			Actor:sendText(player,_tr('title.landtrust.cantaddown'),5);return
		end
		if AIR.isValInList(land_data[landid].settings.share,x)~=-1 then
			Actor:sendText(player,_tr('title.landtrust.alreadyexists'),5);return
		end
		land_data[landid].settings.share[n]=x
		ILAPI.save()
		if result[4]~=1 then 
			GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
		end
	end
	if raw[4]==1 then
		if raw[3]==0 then return end
		local x=land_data[landid].settings.share[raw[5]+1]
		table.remove(land_data[landid].settings.share,AIR.isValInList(land_data[landid].settings.share,x))
		ILAPI.save()
		GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
	end
end
function FORM_land_gui_name(player,raw,data)
	local landid=TRS_Form[player].landid
	if AIR.isTextSpecial(raw[2]) then
		Actor:sendText(player,'FAILED',5);return
	end
	land_data[landid].settings.nickname=raw[2]
	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
												'Complete.',
												_tr('gui.general.back'),
												_tr('gui.general.close'))
end
function FORM_land_gui_describe(player,raw,data)
	local landid=TRS_Form[player].landid
	if AIR.isTextSpecial(AIR.gsubEx(raw[2],
							'$','Y', -- allow some spec.
							',','Y',
							'.','Y',
							'!','Y'
						)) then
		Actor:sendText(player,'FAILED',5);return
	end
	land_data[landid].settings.describe=raw[2]
	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
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
	table.remove(land_owners[xuid],AIR.isValInList(land_owners[xuid],landid))
	table.insert(land_owners[go],#land_owners[go]+1,landid)
	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
									AIR.gsubEx(_tr('title.landtransfer.complete'),
										'<a>',ILAPI.GetNickname(landid),
										'<b>',Actor:xid2str(go)),
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function FORM_land_gui_delete(player,index,text)
	if index==1 then return end
	local landid=TRS_Form[player].landid
	ILAPI.DeleteLand(landid)
	money_add(player,TRS_Form[player].landvalue)
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
										'Complete.',
										_tr('gui.general.back'),
										_tr('gui.general.close'))
end
function FORM_land_gui(player,raw,data)
	local xuid=Actor:getXuid(player)
	local landid=land_owners[xuid][raw[2]+1]
	TRS_Form[player].landid=landid
	if raw[3]==0 then --查看领地信息
		local length = math.abs(land_data[landid].range.start_position[1] - land_data[landid].range.end_position[1]) + 1 
		local width = math.abs(land_data[landid].range.start_position[3] - land_data[landid].range.end_position[3]) + 1
		local height = math.abs(land_data[landid].range.start_position[2] - land_data[landid].range.end_position[2]) + 1
		local vol = length * width * height
		local squ = length * width
		local nname=ILAPI.GetNickname(landid)
		if nname=='' then nname='<'.._tr('gui.landmgr.unnamed')..'>' end
		GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.landmgr.landinfo.title'),
									AIR.gsubEx(_tr('gui.landmgr.landinfo.content'),
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
	if raw[3]==1 then --编辑领地权限
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
	if raw[3]==2 then --编辑信任名单
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		local d=AIR.shacopy(land_data[landid].settings.share)
		for i, v in pairs(d) do
			d[i]=Actor:xid2str(d[i])
		end
		table.insert(d,1,'['.._tr('gui.general.plzchose')..']')
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		GUI(player,'lmgr_landtrust','FORM_land_gui_trust',_tr('gui.landtrust.title'),
												_tr('gui.landtrust.tip'),
												_tr('gui.landtrust.addtrust'),
												_tr('gui.landtrust.selectplayer'),json.encode(TRS_Form[player].playerList),
												_tr('gui.landtrust.rmtrust'),
												_tr('gui.landtrust.selectplayer'),json.encode(d))
	end
	if raw[3]==3 then --领地nickname
		local nickn=ILAPI.GetNickname(landid)
		if nickn=='' then nickn='['.._tr('gui.landmgr.unnamed')..']' end
		GUI(player,'lmgr_landname','FORM_land_gui_name',_tr('gui.landtag.title'),
														_tr('gui.landtag.tip'),
														nickn)
	end
	if raw[3]==4 then --领地describe
		local desc=ILAPI.GetDescribe(landid)
		if desc=='' then desc='['.._tr('gui.landmgr.unmodified')..']' end
		GUI(player,'lmgr_landdescribe','FORM_land_gui_describe',_tr('gui.landdescribe.title'),
															_tr('gui.landdescribe.tip'),
															desc)
	end
	if raw[3]==5 then --领地过户
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		GUI(player,'lmgr_landtransfer','FORM_land_gui_transfer',_tr('gui.landtransfer.title'),
									_tr('gui.landtransfer.tip'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
	end
	if raw[3]==6 then --删除领地
		local height = math.abs(land_data[landid].range.start_position[2] - land_data[landid].range.end_position[2]) + 1
		local length = math.abs(land_data[landid].range.start_position[1] - land_data[landid].range.end_position[1]) + 1
		local width = math.abs(land_data[landid].range.start_position[3] - land_data[landid].range.end_position[3]) + 1
		TRS_Form[player].landvalue=math.modf(calculation_price(length,width,height)*cfg.land_buy.refund_rate)
		GUI(player,'ModalForm','FORM_land_gui_delete',_tr('gui.delland.title'),
												AIR.gsubEx(_tr('gui.delland.content'),
													'<a>',TRS_Form[player].landvalue,
													'<b>',_tr('talk.credit_name')),
												_tr('gui.general.yes'),
												_tr('gui.general.cancel'))
	end
end
function FORM_land_mgr_transfer(player,raw,data)
	if raw[2]==0 then return end
	local landid=TRS_Form[player].targetland
	local from=ILAPI.GetOwner(landid)
	if from=='?' then return end
	local go=Actor:str2xid(TRS_Form[player].playerList[raw[2]+1])
	if go==from then return end
	table.remove(land_owners[from],AIR.isValInList(land_owners[from],landid))
	table.insert(land_owners[go],#land_owners[go]+1,landid)
	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),
									AIR.gsubEx(_tr('title.landtransfer.complete'),
										'<a>',landid,
										'<b>',Actor:xid2str(go)),
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function FORM_land_mgr(player,raw,data)
	
	-- config.json

	if raw[8]~='' then
		cfg.land.player_max_lands = tonumber(raw[8])
	end
	if raw[9]~='' then
		cfg.land.land_max_square = tonumber(raw[9])
	end
	if raw[10]~='' then
		cfg.land.land_min_square = tonumber(raw[10])
	end
	if raw[13]==1 then
		if cfg.money.protocol=='scoreboard' then
			cfg.money.protocol='llmoney'
		else
			cfg.money.protocol='scoreboard'
		end
	end
	if raw[14]~='' then
		cfg.money.scoreboard_objname=raw[14]
	end
	if raw[16]~='' then
		cfg.manager.default_language=raw[16]
	end
	if raw[21]~='' then
		cfg.features.selection_tool_name=raw[21]
	end
	if raw[22]~='' then
		cfg.features.sign_frequency=tonumber(raw[22])
	end
	if raw[23]~='' then
		cfg.features.chunk_side=tonumber(raw[23])
	end

	cfg.land_buy.refund_rate = raw[11]/100
	cfg.features.landSign = AIR.toBool(raw[18])
	cfg.features.particles = AIR.toBool(raw[19])
	cfg.update_check = AIR.toBool(raw[20])

	ILAPI.save()
	
	-- lands manager

	if raw[5]==0 then GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),"Complete.",_tr('gui.general.back'),_tr('gui.general.close'));return end
	local count=0;local landid=-1
	for i,v in pairs(land_data) do
		count=count+1
		if count==raw[5] then landid=i;break end
	end
	if landid==-1 then return end
	if raw[6]==1 then -- tp to land.
		Actor:teleport(player,land_data[landid].range.start_position[1],land_data[landid].range.start_position[2],land_data[landid].range.start_position[3],land_data[landid].range.dim)
	end
	if raw[6]==2 then -- transfer land.
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		TRS_Form[player].targetland=landid
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		ILAPI.save()
		GUI(player,'lmgr_landtransfer','FORM_land_mgr_transfer',_tr('gui.oplandmgr.trsland.title'),
									_tr('gui.oplandmgr.trsland.content'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
		return
	end
	if raw[6]==3 then -- delete land.
		ILAPI.DeleteLand(landid)
	end

	GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),
									"Complete.",
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function IL_BP_SelectRange(player, vec4, mode)
    if newLand[player]==nil then return end
    if mode==0 then -- point a
        if mode~=newLand[player].step then
			Actor:sendText(player,_tr('title.selectrange.failbystep'),5);return
        end
		newLand[player].dim = vec4.dim
		newLand[player].posA = vec4
		newLand[player].posA.x=math.modf(newLand[player].posA.x) --省函数...
		newLand[player].posA.y=math.modf(newLand[player].posA.y)
		newLand[player].posA.z=math.modf(newLand[player].posA.z)
		Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posA.x .. '\nY=' .. newLand[player].posA.y .. '\nZ=' .. newLand[player].posA.z ..'\n'..AIR.gsubEx(_tr('title.selectrange.spointb'),'<a>',cfg.features.selection_tool_name),5)
        newLand[player].step = 1
    end
    if mode==1 then -- point b
        if mode ~= newLand[player].step then
			Actor:sendText(player,_tr('title.selectrange.failbystep'),5);return
        end
        if vec4.dim~=newLand[player].dim then
			Actor:sendText(player,_tr('title.selectrange.failbycdim'),5);return
        end
		newLand[player].posB = vec4
		newLand[player].posB.x=math.modf(newLand[player].posB.x)
		newLand[player].posB.y=math.modf(newLand[player].posB.y)
		newLand[player].posB.z=math.modf(newLand[player].posB.z)
        Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posB.x .. '\nY=' .. newLand[player].posB.y .. '\nZ=' .. newLand[player].posB.z ..'\n'..AIR.gsubEx(_tr('title.selectrange.bebuy'),'<a>',cfg.features.selection_tool_name),5)
		newLand[player].step = 2

		ArrayParticles[player]={}
		ArrayParticles[player]=cubeGetEdge(newLand[player].posA,newLand[player].posB)
    end
	if mode==2 then
		IL_BP_CreateOrder(player)
	end
end
function IL_BP_CreateOrder(player)
	ArrayParticles[player]=nil
	local xuid = Actor:getXuid(player)
    if newLand[player]==nil or newLand[player].step~=2 then
		Actor:sendText(player,_tr('title.createorder.failbystep'),5)
        return
    end
    local length = math.abs(newLand[player].posA.x - newLand[player].posB.x) + 1
    local width = math.abs(newLand[player].posA.z - newLand[player].posB.z) + 1
    local height = math.abs(newLand[player].posA.y - newLand[player].posB.y) + 1
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if squ>cfg.land.land_max_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		Actor:sendText(player,_tr('title.createorder.toobig')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
		newLand[player].step=0
		return
	end
	if squ<cfg.land.land_min_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		Actor:sendText(player,_tr('title.createorder.toosmall')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
		newLand[player].step=0
		return
	end
	if height<2 then
		Actor:sendText(player,_tr('title.createorder.toolow')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
		newLand[player].step=0
		return
	end
	--- 领地冲突判断
	local edge=cubeGetEdge(newLand[player].posA,newLand[player].posB)
	for i=1,#edge do
		edge[i].dim=newLand[player].dim
		local tryLand = ILAPI.PosGetLand(edge[i])
		if tryLand ~= -1 then
			Actor:sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',tryLand)..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
			newLand[player].step=0;return
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dim==newLand[player].dim then
			edge=cubeGetEdge(vecMap[landId].a,vecMap[landId].b)
			for i=1,#edge do
				if isPosInCube(edge[i],newLand[player].posA,newLand[player].posB)==true then
					Actor:sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',landId)..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
					newLand[player].step=0;return
				end
			end
		end
	end
	--- 购买
    newLand[player].landprice = calculation_price(length,width,height)
	GUI(player,'ModalForm','FORM_land_buy', -- %1 callback
						_tr('gui.buyland.title'), --%2 title
						AIR.gsubEx(_tr('gui.buyland.content'),'<a>',length,'<b>',width,'<c>',height,'<d>',vol,'<e>',newLand[player].landprice,'<f>',_tr('talk.credit_name'),'<g>',money_get(player)), -- %3 content
						_tr('gui.general.buy'), -- %4 button1
						_tr('gui.general.close')) --%5 button2
end
function IL_BP_GiveUp(player)
    if newLand[player]==nil then
        Actor:sendText(player,_tr('title.giveup.failed'),5);return
    end
	newLand[player]=nil
	ArrayParticles[player]=nil
	Actor:sendText(player,_tr('title.giveup.succeed'),5)
end
function IL_Manager_GUI(player)
	local xuid=Actor:getXuid(player)
	if #land_owners[xuid]==0 then
		Actor:sendText(player,_tr('title.landmgr.failed'),5);return
	end

	local xyz=AIR.pos2vec({Actor:getPos(player)})
	xyz.y=xyz.y-1
	local lid=ILAPI.PosGetLand(xyz)
	local nname=ILAPI.GetNickname(lid)
	if nname=='' then nname=lid end
	local welcomeText=_tr('gui.landmgr.content')
	if lid~=-1 then
		welcomeText=welcomeText..AIR.gsubEx(_tr('gui.landmgr.ctplus'),'<a>',nname)
	end
	local features={_tr('gui.landmgr.options.landinfo'),_tr('gui.landmgr.options.landperm'),_tr('gui.landmgr.options.landtrust'),_tr('gui.landmgr.options.landtag'),_tr('gui.landmgr.options.landdescribe'),_tr('gui.landmgr.options.landtransfer'),_tr('gui.landmgr.options.delland')}
	local lands={}
	for i,v in pairs(land_owners[xuid]) do
		local f=ILAPI.GetNickname(v)
		if f=='' then f='['.._tr('gui.landmgr.unnamed')..'] '..v end
		lands[i]=f
	end
	GUI(player,'lmgr','FORM_land_gui', -- %1 callback
								_tr('gui.landmgr.title'), -- %2 title
								welcomeText, -- %3 label
								_tr('gui.landmgr.select'), -- %4 dropdown->text
								json.encode(lands), -- %5 dropdown->args
								_tr('gui.oplandmgr.selectoption'), --%6 dropdown->text
								json.encode(features)) -- %7 dropdown->args
end
function IL_Manager_OPGUI(player)
	local landlst={}
	for i,v in pairs(land_data) do
		local thisOwner=ILAPI.GetOwner(i)
		if thisOwner~='?' then thisOwner=Actor:xid2str(thisOwner) else thisOwner='?' end
		if land_data[i].settings.nickname=='' then
			landlst[#landlst+1]='['.._tr('gui.landmgr.unnamed')..'] ('..thisOwner..') ['..i..']'
		else
			landlst[#landlst+1]=land_data[i].settings.nickname..' ('..thisOwner..') ['..i..']'
		end
	end
	table.insert(landlst,1,'['.._tr('gui.general.plzchose')..']')

	-- plugin information
	local latestVer,iAnn
	if iland_latestver~=nil then
		latestVer = iland_latestver
	else
		latestVer = '-'
	end
	if iland_aeb~=nil and iland_aeb~=false then
		iAnn = iland_ann
	else
		iAnn = '-'
	end

	local features={_tr('gui.oplandmgr.donothing'),_tr('gui.oplandmgr.tp'),_tr('gui.oplandmgr.transfer'),_tr('gui.oplandmgr.delland')}
	local money_protocols
	if cfg.money.protocol=='llmoney' then
		money_protocols={'LLMoney',_tr('talk.scoreboard')} -- line 498
	else
		money_protocols={_tr('talk.scoreboard'),'LLMoney'}
	end
	GUI(player,'opmgr','FORM_land_mgr',_tr('gui.oplandmgr.title'),
									_tr('gui.oplandmgr.tip'),
									AIR.gsubEx(_tr('gui.oplandmgr.plugin'),'<a>',langVer),
									AIR.gsubEx(_tr('gui.oplandmgr.plugin.ver'),'<a>',plugin_version)..'\\n'..
									AIR.gsubEx(_tr('gui.oplandmgr.plugin.latest'),'<a>',latestVer)..'\\n'..
									AIR.gsubEx(_tr('gui.oplandmgr.plugin.acement'),'<a>',iAnn),
									_tr('gui.oplandmgr.landmgr'),
									_tr('gui.oplandmgr.selectland'),json.encode(landlst),
									_tr('gui.oplandmgr.selectoption'),json.encode(features),
									_tr('gui.oplandmgr.landcfg'),
									_tr('gui.oplandmgr.landcfg.maxland'),cfg.land.player_max_lands,
									_tr('gui.oplandmgr.landcfg.maxsqu'),cfg.land.land_max_square,
									_tr('gui.oplandmgr.landcfg.minsqu'),cfg.land.land_min_square,
									_tr('gui.oplandmgr.landcfg.refundrate'),tostring(cfg.land_buy.refund_rate*10),
									_tr('gui.oplandmgr.economy'),
									_tr('gui.oplandmgr.economy.protocol'),json.encode(money_protocols),
									_tr('gui.oplandmgr.economy.sbname'),cfg.money.scoreboard_objname,
									_tr('gui.oplandmgr.i18n'),
									_tr('gui.oplandmgr.i18n.default'),cfg.manager.default_language,
									_tr('gui.oplandmgr.features'),
									_tr('gui.oplandmgr.features.landsign'),tostring(cfg.features.landSign),
									_tr('gui.oplandmgr.features.particles'),tostring(cfg.features.particles),
									_tr('gui.oplandmgr.features.autochkupd'),tostring(cfg.update_check),
									_tr('gui.oplandmgr.features.seltolname'),cfg.features.selection_tool_name,
									_tr('gui.oplandmgr.features.frequency'),cfg.features.sign_frequency,
									_tr('gui.oplandmgr.features.chunksize'),cfg.features.chunk_side)
end
function IL_CmdFunc(player,cmd)
	if player==0 then return end
	local xuid=Actor:getXuid(player)
	-- [ ] Main Command
	if cmd == MainCmd then
		land_count=tostring(#land_owners[xuid])
		GUI(player,'ModalForm','FORM_BACK_LandMgr', -- %1 callback
						AIR.gsubEx(_tr('gui.land.title'),'<a>',plugin_version), -- %2 title
						AIR.gsubEx(_tr('gui.land.content'),'<a>',land_count), _tr('talk.landmgr.open'), _tr('gui.general.close'), -- %3 content
						_tr('talk.landmgr.open'), --%4 button1
						_tr('gui.general.close')) --%5 button2
	end
	-- [new] Create newLand
	if cmd == MainCmd..' new' then
		if newLand[player]~=nil then
			Actor:sendText(player,_tr('title.getlicense.alreadyexists')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5);return -1
		end
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			if #land_owners[xuid]>=cfg.land.player_max_lands then
				Actor:sendText(player,_tr('title.getlicense.limit'),5);return -1
			end
		end
		Actor:sendText(player,_tr('title.getlicense.succeed')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
		newLand[player]={}
		newLand[player].step=0
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
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then return end
		IL_Manager_OPGUI(player)
	end
	-- [mgr selectool] Set land_select tool
	if cmd == MainCmd..' mgr selectool' then
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then return end
		Actor:sendText(player,_tr('title.oplandmgr.setselectool'),5)
		TRS_Form[player].selectool=0
	end
	-- [debug] Start to debug
	if cmd == MainCmd..' debug' and debug_mode then
		debug_landquery = player
	end
	-- [X] Disable Output
	if string.sub(cmd,1,5)==MainCmd..' ' or string.sub(cmd,1,4)==MainCmd then
		return -1
	end
end

-- ILAPI
function ILAPI.CreateLand(xuid,startpos,endpos,dimensionid)
	local landId
	while true do
		landId=AIR.getGuid()
		if land_data[landId]==nil then break end
	end
	land_data[landId]={}
	land_data[landId].settings={}
	land_data[landId].settings.share={}
	land_data[landId].settings.nickname=""
	land_data[landId].settings.describe=""
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
	land_data[landId].permissions={}
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
	ILAPI.save()
	buildChunks()
	buildVecMap()
end
function ILAPI.DeleteLand(landid)
	if land_data[landid]==nil then
		if debug_mode then print('[ILAPI] [DeleteLand] WARN!! Deleting nil land('..landid..').') end
		return
	end
	local owner=ILAPI.GetOwner(landid)
	if owner~='?' then
		table.remove(land_owners[owner],AIR.isValInList(land_owners[owner],landid))
	end
	land_data[landid]=nil
	ILAPI.save()
	buildChunks()
	buildVecMap()
end
function ILAPI.GetPlayerLands(xuid)
	if land_owners[xuid]==nil then 
		if debug_mode then print('[ILAPI] [GetPlayerLands] WARN!! Getting nil player('..xuid..').') end
		return ''
	end
	return land_owners[xuid]
end
function ILAPI.GetNickname(landid)
	if land_data[landid]==nil then 
		if debug_mode then print('[ILAPI] [GetNickname] WARN!! Getting nil land('..landid..').') end
		return ''
	end
	return land_data[landid].settings.nickname
end
function ILAPI.GetDescribe(landid)
	if land_data[landid]==nil then 
		if debug_mode then print('[ILAPI] [GetDescribe] WARN!! Getting nil land('..landid..').') end
		return ''
	end
	return land_data[landid].settings.describe
end
function ILAPI.GetOwner(landid)
	if land_data[landid]==nil then
		if debug_mode then print('[ILAPI] [GetOwner] WARN!! Getting nil land('..landid..').') end
		return '?'
	end
	for i,v in pairs(land_owners) do
		if AIR.isValInList(v,landid)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI.PosGetLand(vec4)
	local c = pos2chunk(vec4.x,vec4.z)
	if ChunkMap[c.x]~=nil and ChunkMap[c.x][c.z]~=nil then
		for n,landId in pairs(ChunkMap[c.x][c.z]) do
			if vec4.dim==land_data[landId].range.dim and isPosInCube(vec4,vecMap[landId].a,vecMap[landId].b) then
				return landId
			end
		end
	end
	return -1
end
function ILAPI.GetChunk(vec2)
	local r = pos2chunk(vec2.x,vec2.z)
	if ChunkMap[r.x]~=nil and ChunkMap[r.x][r.z]~=nil then
		return ChunkMap[r.x][r.z]
	end
	return -1
end
function ILAPI.GetVersion()
	return plugin_version
end

-- feature function
function GetOnlinePlayerList(mode) -- [0]playerptr [1]xuid [2]playername
	local b={}
	for i,v in pairs(TRS_Form) do
		if mode==0 then b[#b+1]=i end
		if mode==1 then b[#b+1]=Actor:getXuid(i) end
		if mode==2 then b[#b+1]=Actor:getName(i) end
	end
	return b
end
function _tr(a)
	return i18n_data[a]
end
function money_add(player,value)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		runCmd('scoreboard players add "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	if cfg.money.protocol=='llmoney' then
		runCmd('money add "'..playername..'" '..value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..cfg.money.protocol..'\' !')
end
function money_del(player,value)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		runCmd('scoreboard players remove "'..playername..'" "'..cfg.money.scoreboard_objname..'" '..value);return
	end
	if cfg.money.protocol=='llmoney' then
		runCmd('money reduce "'..playername..'" '..value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..cfg.money.protocol..'\' !')
end
function money_get(player)
	local playername=Actor:getName(player)
	if cfg.money.protocol=='scoreboard' then
		local n={runCmdEx('scoreboard players list "'..playername..'"')};n=n[2]
		local t=string.len(cfg.money.scoreboard_objname..':')
		local j=AIR.split(n,' ')
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
function sendTitle(player,title,subtitle)
	local playername = Actor:getName(player)
	runCmdEx('title "' .. playername .. '" times 20 25 20')
	if subtitle~=nil then
	runCmdEx('title "' .. playername .. '" subtitle '..subtitle) end
	runCmdEx('title "' .. playername .. '" title '..title)
end
function cubeGetEdge(posA,posB)
	local edge={}
	local p=0
	for i=1,math.abs(math.abs(posA.y)-math.abs(posB.y))+1 do
		if posA.y>posB.y then
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y-i,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y-i,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y-i,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y-i,posA.z)
		else
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y+i-2,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y+i-2,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y+i-2,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y+i-2,posA.z)
		end
	end
	for i=1,math.abs(math.abs(posA.x)-math.abs(posB.x))+1 do
		if posA.x>posB.x then
			p=#edge+1;edge[p]=AIR.buildVec(posA.x-i+1,posA.y-1,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x-i+1,posB.y-1,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x-i+1,posA.y-1,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x-i+1,posB.y-1,posB.z)
		else
			p=#edge+1;edge[p]=AIR.buildVec(posA.x+i-1,posA.y-1,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x+i-1,posB.y-1,posA.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x+i-1,posA.y-1,posB.z)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x+i-1,posB.y-1,posB.z)
		end
	end
	for i=1,math.abs(math.abs(posA.z)-math.abs(posB.z))+1 do
		if posA.z>posB.z then
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y-1,posA.z-i+1)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y-1,posA.z-i+1)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posB.y-1,posA.z-i+1)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posB.y-1,posA.z-i+1)
		else
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posA.y-1,posA.z+i-1)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posA.y-1,posA.z+i-1)
			p=#edge+1;edge[p]=AIR.buildVec(posA.x,posB.y-1,posA.z+i-1)
			p=#edge+1;edge[p]=AIR.buildVec(posB.x,posB.y-1,posA.z+i-1)
		end
	end
	return edge
end
function isPosInCube(pos,posA,posB)
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y) then
			if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
				return true
			end
		end
	end
	return false
end
function calculation_price(length,width,height)
	local price=0
	local t=cfg.land_buy.price
	if cfg.land_buy.calculation == 'm-1' then
		price=length*width*t[1]+height*t[2]
	end
	if cfg.land_buy.calculation == 'm-2' then
		price=length*width*height*t[1]
	end
	if cfg.land_buy.calculation == 'm-3' then
		price=length*width*t[1]
	end
	return math.modf(price)
end

-- minecraft -> events
function IL_LIS_onPlayerDestroyBlock(player,block,x,y,z,dim)
	
	local HandItem = Actor:getHand(player)
	local ItemName = Item:getName(HandItem)

	if ItemName~='' and TRS_Form[player].selectool==0 then
		Actor:sendText(player,AIR.gsubEx(_tr('title.oplandmgr.setsuccess'),'<a>',ItemName),5)
		cfg.features.selection_tool=Item:getFullName(HandItem)
		ILAPI.save()
		TRS_Form[player].selectool=-1
		return -1
	end
	if ItemName~='' and newLand[player]~=nil and Item:getFullName(HandItem)==cfg.features.selection_tool then
		IL_BP_SelectRange(player,AIR.buildVec(x,y,z,dim),newLand[player].step)
		return -1
	end

	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_destory==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerPlaceBlock(player,block,x,y,z,dim)
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_place==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerUseItem(player,item,blockname,x,y,z,dim)
	if blockname=='minecraft:barrel' then return end -- sb mojang
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_use_item==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerOpenChest(player,x,y,z,dim)
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_open_chest==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerOpenBarrel(player,x,y,z,dim)
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_open_barrel==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	return -1
end
function IL_LIS_onPlayerAttack(player,mobptr)
	local pos=AIR.pos2vec({Actor:getPos(mobptr)})
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_attack==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onExplode(ptr,x,y,z,dim)
	local pos=AIR.pos2vec({x,y,z,dim})
	local landid=ILAPI.PosGetLand(pos)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_exploding==true then return end -- Perm Allow
	return -1
end
function IL_LIS_onPlayerTakeItem(player,itemptr)
	local pos=AIR.pos2vec({Actor:getPos(itemptr)})
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_pickupitem==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerDropItem(player,itemptr)
	local pos=AIR.pos2vec({Actor:getPos(player)})
	pos.y=pos.y-1
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_dropitem==true then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_TCB_LandSign()
	local players=GetOnlinePlayerList(0)
	for i,v in pairs(players) do
		local xyz=AIR.pos2vec({Actor:getPos(v)})
		xyz.y=xyz.y-1
		local landid=ILAPI.PosGetLand(xyz)
		if landid==-1 then TRS_Form[v].inland='null';return end -- no land here
		if landid==TRS_Form[v].inland then return end -- signed
		local owner=ILAPI.GetOwner(landid)
		local ownername='?'
		if owner~='?' then ownername=Actor:xid2str(owner) end
		local slname=ILAPI.GetNickname(landid)
		if slname=='' then slname='<'.._tr('gui.landmgr.unnamed')..'>' end
		if Actor:getXuid(v)==owner then
			sendTitle(v,AIR.gsubEx(_tr('sign.listener.ownertitle'),'<a>',slname),_tr('sign.listener.ownersubtitle'))
		else
			sendTitle(v,_tr('sign.listener.visitortitle'),AIR.gsubEx(_tr('sign.listener.visitorsubtitle'),'<a>',ownername))
			if land_data[landid].settings.describe~='' then
				Actor:sendText(v,'§l§b[§a LAND §b] §r'..AIR.gsubEx(land_data[landid].settings.describe,
																	'$visitor',Actor:getName(v),
																	'$n','\n'
																),0)
			end
		end
		TRS_Form[v].inland=landid
	end
end
function IL_TCB_SelectionParticles()
	for player,posarr in pairs(ArrayParticles) do
		for n,pos in pairs(posarr) do
			runCmdEx('execute @a[name="'..Actor:getName(player)..'"] ~ ~ ~ particle "'..cfg.features.particle_effects..'" '..pos.x..' '..tostring(pos.y+1.6)..' '..pos.z)
		end
	end
end

-- listen events,
Listen('onCMD',IL_CmdFunc)
Listen('onJoin',EV_playerJoin)
Listen('onLeft',EV_playerLeft)
Listen('onPlayerDestroyBlock',IL_LIS_onPlayerDestroyBlock)
Listen('onPlayerPlaceBlock',IL_LIS_onPlayerPlaceBlock)
Listen('onPlayerUseItem',IL_LIS_onPlayerUseItem)
Listen('onPlayerOpenChest',IL_LIS_onPlayerOpenChest)
Listen('onPlayerOpenBarrel',IL_LIS_onPlayerOpenBarrel)
Listen('onPlayerAttack',IL_LIS_onPlayerAttack)
Listen('onExplode',IL_LIS_onExplode)
Listen('onPlayerTakeItem',IL_LIS_onPlayerTakeItem)
Listen('onPlayerDropItem',IL_LIS_onPlayerDropItem)

-- timer -> landsign
if cfg.features.landSign then
	schedule("IL_TCB_LandSign",cfg.features.sign_frequency*2,0)
end

-- timer -> particles
if cfg.features.particles then
	schedule("IL_TCB_SelectionParticles",2,0)
end

-- timer -> debugger
function DEBUG_LANDQUERY()
	if debug_landquery == 0 then return end
	local xyz=AIR.pos2vec({Actor:getPos(debug_landquery)})
	xyz.y=xyz.y-1
	local landid=ILAPI.PosGetLand(xyz)
	local N = ILAPI.GetChunk(xyz)
	local F = pos2chunk(xyz.x,xyz.z)
	print('[ILand] Debugger: [Query] '..landid)
	if N==-1 then
		print('[ILand] Debugger: [Chunk] not found')
	else
		for i,v in pairs(N) do
			print('[ILand] Debugger: [Chunk] ('..F.x..','..F.z..') '..i..' '..v)
		end
	end
end
if debug_mode then
	schedule("DEBUG_LANDQUERY",3,0)
end

-- check update
if cfg.update_check then
	local result=Utils:Get('http://cdisk.amd.rocks','/tmp/ILAND/v111_version')
	if result~=nil then
		local data=json.decode(result['body'])
		
		-- global
		iland_latestver = data.version
		iland_aeb = data.t_e
		iland_ann = data.text
		
		if iland_latestver~=plugin_version then
			print('[ILand] '..AIR.gsubEx(_tr('console.newversion'),'<a>',iland_latestver))
			print('[ILand] '.._tr('console.update'))
		end
		if iland_aeb then
			print('[ILand] '..iland_ann)
		end
	else
		print('[ILand] ERR!! Get version info failed.')
	end
end

-- register cmd.
makeCommand(MainCmd,_tr('command.land'),1)
makeCommand(MainCmd..' new',_tr('command.land_new'),1)
makeCommand(MainCmd..' giveup',_tr('command.land_giveup'),1)
makeCommand(MainCmd..' gui',_tr('command.land_gui'),1)
makeCommand(MainCmd..' mgr',_tr('command.land_mgr'),5)
makeCommand(MainCmd..' mgr selectool',_tr('command.land_mgr_selectool'),5)
print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)

return ILAPI