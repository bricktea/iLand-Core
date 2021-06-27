-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.5hotfix'
local langVer = 115
local minLLVer = 210613
local minAirVer = 100
local minUtilVer = 100
local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\'
local newLand={};local TRS_Form={};local ArrayParticles={};ILAPI={}
local MainCmd = 'land'
local debug_mode = false
local json = require('dkjson')
local AIR = require('airLibs')

-- check file
if Utils:isExist(data_path..'config.json') == false then
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
if tonumber(Utils:getVersion()) < minUtilVer then
end

-- load data file
local cfg = json.decode(Utils:ReadAllText(data_path..'config.json'))
land_data = json.decode(Utils:ReadAllText(data_path..'data.json'))
land_owners = json.decode(Utils:ReadAllText(data_path..'owners.json'))

-- preload function
function ILAPI.save()
	Utils:WriteAllText(data_path..'config.json',json.encode(cfg,{indent=true}))
	Utils:WriteAllText(data_path..'data.json',json.encode(land_data))
	Utils:WriteAllText(data_path..'owners.json',json.encode(land_owners,{indent=true}))
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
		ILAPI.save()
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
		ILAPI.save()
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
		ILAPI.save()
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
		ILAPI.save()
	end
	if cfg.version==114 then
		cfg.version=115
		cfg.features.landtp=true
		for landId,data in pairs(land_data) do
			land_data[landId].settings.tpoint={}
			land_data[landId].settings.tpoint[1]=land_data[landId].range.start_position[1]
			land_data[landId].settings.tpoint[2]=land_data[landId].range.start_position[2]
			land_data[landId].settings.tpoint[3]=land_data[landId].range.start_position[3]
			land_data[landId].settings.signtome=true
			land_data[landId].settings.signtother=true
		end
		ILAPI.save()
	end
	if cfg.features.selection_tool_name==nil then
		cfg.features.selection_tool_name='Wooden Axe'
		ILAPI.save()
	end
	if cfg.version==115 then
		cfg.version=116
		for landId,data in pairs(land_data) do
			local perm = land_data[landId].permissions
			local TMPPM = AIR.deepcopy(perm.allow_use_item)
			local TMPBL = AIR.deepcopy(perm.allow_open_barrel)
			perm.use_anvil = TMPPM
			perm.use_barrel = TMPPM
			perm.use_beacon = TMPPM
			perm.use_bed = TMPPM
			perm.use_bell = TMPPM
			perm.use_blast_furnace = TMPPM
			perm.use_brewing_stand = TMPPM
			perm.use_campfire = TMPPM
			perm.use_cartography_table = TMPPM
			perm.use_composter = TMPPM
			perm.use_crafting_table = TMPPM
			perm.use_daylight_detector = TMPPM
			perm.use_dispenser = TMPPM
			perm.use_dropper = TMPPM
			perm.use_enchanting_table = TMPPM
			perm.use_fence_gate = TMPPM
			perm.use_furnace = TMPPM
			perm.use_grindstone = TMPPM
			perm.use_hopper = TMPPM
			perm.use_jukebox = TMPPM
			perm.use_loom = TMPPM
			perm.use_noteblock = TMPPM
			perm.use_shulker_box = TMPPM
			perm.use_smithing_table = TMPPM
			perm.use_smoker = TMPPM
			perm.use_trapdoor = TMPPM
			perm.use_lectern = TMPPM
			perm.use_cauldron = TMPPM
			perm.allow_use_item = nil
			perm.allow_open_barrel = nil
		end
		-- ILAPI.save()
	end
end

-- load language file
local i18n_data = json.decode(Utils:ReadAllText(data_path..'lang\\'..cfg.manager.default_language..'.json'))
if i18n_data.VERSION ~= langVer then
	print('[ILand] ERR!! Language file does not match version, plugin is closing... (!='..langVer..')')
	return
end

-- load chunks
local ChunkMap={}
function updateChunk(landId,mode)

	-- get all TxTz

	local TxTz={}
	function txz(x,z)
		if TxTz[x] == nil then TxTz[x] = {} end
		if TxTz[x][z] == nil then TxTz[x][z] = {} end
	end
	function chkmap(x,z)
		if ChunkMap[x] == nil then ChunkMap[x] = {} end
		if ChunkMap[x][z] == nil then ChunkMap[x][z] = {} end
	end
	local size = cfg.features.chunk_side
	local sX = land_data[landId].range.start_position[1]
	local sZ = land_data[landId].range.start_position[3]
	local count = 0
	while (sX+size*count<=land_data[landId].range.end_position[1]+size) do
		local t = pos2chunk(sX+size*count,sZ+size*count)
		txz(t.x,t.z)
		local count2 = 0
		while (sZ+size*count2<=land_data[landId].range.end_position[3]+size) do
			local t = pos2chunk(sX+size*count,sZ+size*count2)
			txz(t.x,t.z)
			count2 = count2 + 1
		end
		count = count +1
	end

	-- add & del

	for Tx,a in pairs(TxTz) do
		for Tz,b in pairs(a) do
			-- Tx Tz
			if mode=='add' then
				chkmap(Tx,Tz)
				if AIR.isValInList(ChunkMap[Tx][Tz],landId) == -1 then
					table.insert(ChunkMap[Tx][Tz],#ChunkMap[Tx][Tz]+1,landId)
				end
			end
			if mode=='del' then
				local p = AIR.isValInList(ChunkMap[Tx][Tz],landId)
				if p~=-1 then
					table.remove(ChunkMap[Tx][Tz],p)
				end
			end
		end
	end

end
function buildChunks()
	ChunkMap={}
	for landId,data in pairs(land_data) do
		updateChunk(landId,'add')
	end
end
buildChunks()

-- load land VecMap
local vecMap={}
function updateVecMap(landId,mode)
	if mode=='add' then
		local spos = land_data[landId].range.start_position
		local epos = land_data[landId].range.end_position
		vecMap[landId]={}
		vecMap[landId].a={};vecMap[landId].b={}
		vecMap[landId].a = AIR.buildVec(spos[1],spos[2],spos[3]) --start
		vecMap[landId].b = AIR.buildVec(epos[1],epos[2],epos[3]) --end
	end
	if mode=='del' then
		vecMap[landId]=nil
	end
end
function buildVecMap()
	vecMap={}
	for landId,data in pairs(land_data) do
		updateVecMap(landId,'add')
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
function FORM_NULL(a,b,c) end
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
function FORM_land_gui_cfg(player,raw,data)

	local landId = TRS_Form[player].landid
	land_data[landId].settings.signtome=AIR.toBool(raw[3])
	land_data[landId].settings.signtother=AIR.toBool(raw[4])
	ILAPI.save()

	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
end
function FORM_land_gui_perm(player,raw,data)
	
	local perm = land_data[TRS_Form[player].landid].permissions

	perm.allow_place = AIR.toBool(raw[3])
	perm.allow_destroy = AIR.toBool(raw[4])
	perm.allow_dropitem = AIR.toBool(raw[5])
	perm.allow_pickupitem = AIR.toBool(raw[6])
	perm.allow_attack = AIR.toBool(raw[7])

	perm.use_crafting_table = AIR.toBool(raw[9])
	perm.use_furnace = AIR.toBool(raw[10])
	perm.use_blast_furnace = AIR.toBool(raw[11])
	perm.use_smoker = AIR.toBool(raw[12])
	perm.use_brewing_stand = AIR.toBool(raw[13])
	perm.use_cauldron = AIR.toBool(raw[14])
	perm.use_anvil = AIR.toBool(raw[15])
	perm.use_grindstone = AIR.toBool(raw[16])
	perm.use_enchanting_table = AIR.toBool(raw[17])
	perm.use_cartography_table = AIR.toBool(raw[18])
	perm.use_smithing_table = AIR.toBool(raw[19])
	perm.use_loom = AIR.toBool(raw[20])
	perm.use_beacon = AIR.toBool(raw[21])

	perm.use_barrel = AIR.toBool(raw[23])
	perm.use_hopper = AIR.toBool(raw[24])
	perm.use_dropper = AIR.toBool(raw[25])
	perm.use_dispenser = AIR.toBool(raw[26])
	perm.use_shulker_box = AIR.toBool(raw[27])
	perm.use_chest = AIR.toBool(raw[28])

	perm.use_campfire = AIR.toBool(raw[30])
	perm.use_trapdoor = AIR.toBool(raw[31])
	perm.use_fence_gate = AIR.toBool(raw[32])
	perm.use_bell = AIR.toBool(raw[33])
	perm.use_jukebox = AIR.toBool(raw[34])
	perm.use_noteblock = AIR.toBool(raw[35])
	perm.use_composter = AIR.toBool(raw[36])
	perm.use_bed = AIR.toBool(raw[37])
	perm.use_daylight_detector = AIR.toBool(raw[38])

	perm.allow_exploding = AIR.toBool(raw[40])

	ILAPI.save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
end
function FORM_land_gui_trust(player,raw,data)
	local landid = TRS_Form[player].landid
	local landshare = land_data[landid].settings.share
	-- [1]null [2]1(true) [3]0 [4]0(false) [5]0
	if raw[2]==1 then
		if raw[3]==0 then return end
		local x=Actor:str2xid(TRS_Form[player].playerList[raw[3]+1])
		local n=#landshare+1
		if Actor:getXuid(player)==x then
			Actor:sendText(player,_tr('title.landtrust.cantaddown'),5);return
		end
		if AIR.isValInList(landshare,x)~=-1 then
			Actor:sendText(player,_tr('title.landtrust.alreadyexists'),5);return
		end
		landshare[n]=x
		ILAPI.save()
		if raw[4]~=1 then 
			GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
													'Complete.',
													_tr('gui.general.back'),
													_tr('gui.general.close'))
		end
	end
	if raw[4]==1 then
		if raw[5]==0 then return end
		local x=Actor:str2xid(TRS_Form[player].playerList[raw[5]+1])
		table.remove(landshare,AIR.isValInList(landshare,x))
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
	if raw[3]==1 then --编辑领地选项
		local isclosed=''
		if not(cfg.features.landSign) then
			isclosed=' ('.._tr('talk.features.closed')..')'
		end
		GUI(player,'lmgr_landcfg','FORM_land_gui_cfg',_tr('gui.landcfg.title'),
													_tr('gui.landcfg.tip'),
													_tr('gui.landcfg.landsign')..isclosed,
													_tr('gui.landcfg.landsign.tome'),tostring(land_data[landid].settings.signtome),
													_tr('gui.landcfg.landsign.tother'),tostring(land_data[landid].settings.signtother)
												)
	end
	if raw[3]==2 then --编辑领地权限
		local perm = land_data[landid].permissions
		GUI(player,'lmgr_landperm','FORM_land_gui_perm',_tr('gui.landmgr.landperm.title'),
							_tr('gui.landmgr.landperm.options.title'),
							_tr('gui.landmgr.landperm.basic_options'),
							_tr('gui.landmgr.landperm.basic_options.place'),tostring(perm.allow_place),
							_tr('gui.landmgr.landperm.basic_options.destroy'),tostring(perm.allow_destroy),
							_tr('gui.landmgr.landperm.basic_options.dropitem'),tostring(perm.allow_dropitem),
							_tr('gui.landmgr.landperm.basic_options.pickupitem'),tostring(perm.allow_pickupitem),
							_tr('gui.landmgr.landperm.basic_options.attack'),tostring(perm.allow_attack),
							_tr('gui.landmgr.landperm.funcblock_options'),
							_tr('gui.landmgr.landperm.funcblock_options.crafting_table'),tostring(perm.use_crafting_table),
							_tr('gui.landmgr.landperm.funcblock_options.furnace'),tostring(perm.use_furnace),
							_tr('gui.landmgr.landperm.funcblock_options.blast_furnace'),tostring(perm.use_blast_furnace),
							_tr('gui.landmgr.landperm.funcblock_options.smoker'),tostring(perm.use_smoker),
							_tr('gui.landmgr.landperm.funcblock_options.brewing_stand'),tostring(perm.use_brewing_stand),
							_tr('gui.landmgr.landperm.funcblock_options.cauldron'),tostring(perm.use_cauldron),
							_tr('gui.landmgr.landperm.funcblock_options.anvil'),tostring(perm.use_anvil),
							_tr('gui.landmgr.landperm.funcblock_options.grindstone'),tostring(perm.use_grindstone),
							_tr('gui.landmgr.landperm.funcblock_options.enchanting_table'),tostring(perm.use_enchanting_table),
							_tr('gui.landmgr.landperm.funcblock_options.cartography_table'),tostring(perm.use_cartography_table),
							_tr('gui.landmgr.landperm.funcblock_options.smithing_table'),tostring(perm.use_smithing_table),
							_tr('gui.landmgr.landperm.funcblock_options.loom'),tostring(perm.use_loom),
							_tr('gui.landmgr.landperm.funcblock_options.beacon'),tostring(perm.use_beacon),
							_tr('gui.landmgr.landperm.contblock_options'),
							_tr('gui.landmgr.landperm.contblock_options.barrel'),tostring(perm.use_barrel),
							_tr('gui.landmgr.landperm.contblock_options.hopper'),tostring(perm.use_hopper),
							_tr('gui.landmgr.landperm.contblock_options.dropper'),tostring(perm.use_dropper),
							_tr('gui.landmgr.landperm.contblock_options.dispenser'),tostring(perm.use_dispenser),
							_tr('gui.landmgr.landperm.contblock_options.shulker_box'),tostring(perm.use_shulker_box),
							_tr('gui.landmgr.landperm.contblock_options.chest'),tostring(perm.use_chest),
							_tr('gui.landmgr.landperm.other_options'),
							_tr('gui.landmgr.landperm.other_options.campfire'),tostring(perm.use_campfire),
							_tr('gui.landmgr.landperm.other_options.trapdoor'),tostring(perm.use_trapdoor),
							_tr('gui.landmgr.landperm.other_options.fence_gate'),tostring(perm.use_fence_gate),
							_tr('gui.landmgr.landperm.other_options.bell'),tostring(perm.use_bell),
							_tr('gui.landmgr.landperm.other_options.jukebox'),tostring(perm.use_jukebox),
							_tr('gui.landmgr.landperm.other_options.noteblock'),tostring(perm.use_noteblock),
							_tr('gui.landmgr.landperm.other_options.composter'),tostring(perm.use_composter),
							_tr('gui.landmgr.landperm.other_options.bed'),tostring(perm.use_bed),
							_tr('gui.landmgr.landperm.other_options.daylight_detector'),tostring(perm.use_daylight_detector),
							_tr('gui.landmgr.landperm.editevent'),
							_tr('gui.landmgr.landperm.options.exploding'),tostring(perm.allow_exploding)
						)
	end
	if raw[3]==3 then --编辑信任名单
		TRS_Form[player].playerList = GetOnlinePlayerList()
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
	if raw[3]==4 then --领地nickname
		local nickn=ILAPI.GetNickname(landid)
		if nickn=='' then nickn='['.._tr('gui.landmgr.unnamed')..']' end
		GUI(player,'lmgr_landname','FORM_land_gui_name',_tr('gui.landtag.title'),
														_tr('gui.landtag.tip'),
														nickn)
	end
	if raw[3]==5 then --领地describe
		local desc=ILAPI.GetDescribe(landid)
		if desc=='' then desc='['.._tr('gui.landmgr.unmodified')..']' end
		GUI(player,'lmgr_landdescribe','FORM_land_gui_describe',_tr('gui.landdescribe.title'),
															_tr('gui.landdescribe.tip'),
															desc)
	end
	if raw[3]==6 then --领地过户
		TRS_Form[player].playerList = GetOnlinePlayerList()
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		GUI(player,'lmgr_landtransfer','FORM_land_gui_transfer',_tr('gui.landtransfer.title'),
									_tr('gui.landtransfer.tip'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
	end
	if raw[3]==7 then --删除领地
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
	
	-- do rt

	if cfg.features.landSign and CLOCK_LANDSIGN==nil then
		enableLandSign()
	end
	if not(cfg.features.landSign) and CLOCK_LANDSIGN~=nil then
		cancel(CLOCK_LANDSIGN)
		CLOCK_LANDSIGN=nil
	end
	if cfg.features.particles and CLOCK_PARTICLES==nil then
		enableParticles()
	end
	if not(cfg.features.particles) and CLOCK_PARTICLES~=nil then
		cancel(CLOCK_PARTICLES)
		CLOCK_PARTICLES=nil
	end
	
	-- lands manager

	if raw[5]==0 then GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),"Complete.",_tr('gui.general.back'),_tr('gui.general.close'));return end
	local count=0;local landid=-1
	for i,v in pairs(land_data) do
		count=count+1
		if count==raw[5] then landid=i;break end
	end
	if landid==-1 then return end
	if raw[6]==1 then -- tp to land.
		Actor:teleport(player,land_data[landid].settings.tpoint[1],land_data[landid].settings.tpoint[2],land_data[landid].settings.tpoint[3],land_data[landid].range.dim)
	end
	if raw[6]==2 then -- transfer land.
		TRS_Form[player].playerList = GetOnlinePlayerList()
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
function FORM_landtp(player,raw,data)
	if raw[2]==0 then return end
	local lands = ILAPI.GetPlayerLands(Actor:getXuid(player))
	local landId = lands[raw[2]]
	local tp = land_data[landId].settings.tpoint
	Actor:teleport(player,tp[1],tp[2],tp[3],land_data[landId].range.dim)
	GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
									"Complete.",
									_tr('gui.general.yes'),
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
			Actor:sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',tryLand,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
			newLand[player].step=0;return
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dim==newLand[player].dim then
			edge=cubeGetEdge(vecMap[landId].a,vecMap[landId].b)
			for i=1,#edge do
				if isPosInCube(edge[i],newLand[player].posA,newLand[player].posB)==true then
					Actor:sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',landId,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name),5)
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
	local features={_tr('gui.landmgr.options.landinfo'),_tr('gui.landmgr.options.landcfg'),_tr('gui.landmgr.options.landperm'),_tr('gui.landmgr.options.landtrust'),_tr('gui.landmgr.options.landtag'),_tr('gui.landmgr.options.landdescribe'),_tr('gui.landmgr.options.landtransfer'),_tr('gui.landmgr.options.delland')}
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
	local opt = AIR.split(cmd,' ')
	if opt[1] ~= MainCmd then return end
	
	-- ## Console ##
	if player == 0 then
		-- [ ] main cmd.
		if opt[2] == nil then
			print('The server is running ILand v'..plugin_version)
			print('Github: https://github.com/McAirLand/iLand-Core')
			return -1
		end
		-- [op] add land operator.
		if opt[2] == 'op' then
			if AIR.isValInList(cfg.manager.operator,opt[3])==-1 then
				if not(AIR.isNumber(opt[3])) then
					print('Wrong xuid!');return -1
				end
				table.insert(cfg.manager.operator,#cfg.manager.operator+1,opt[3])
				ILAPI.save()
				print('Xuid: '..opt[3]..' has been added to the LandMgr list.')
			else
				print('Xuid: '..opt[3]..' is already in LandMgr list.')
			end
			return -1
		end
		-- [deop] add land operator.
		if opt[2] == 'deop' then
			local p = AIR.isValInList(cfg.manager.operator,opt[3])
			if p~=-1 then
				if not(AIR.isNumber(opt[3])) then
					print('Wrong xuid!');return -1
				end
				table.remove(cfg.manager.operator,p)
				ILAPI.save()
				print('Xuid: '..opt[3]..' has been removed from LandMgr list.')
			else
				print('Xuid: '..opt[3]..' is not in LandMgr list.')
			end
			return -1
		end
		-- [X] Unknown key
		print('Unknown parameter: "'..opt[2]..'", plugin wiki: https://git.io/JcvIw')
		return -1
	end

	-- ## GAME ##
	local xuid=Actor:getXuid(player)
	-- [ ] Main Command
	if opt[1] == MainCmd and opt[2]==nil then
		land_count=tostring(#land_owners[xuid])
		GUI(player,'ModalForm','FORM_BACK_LandMgr', -- %1 callback
						AIR.gsubEx(_tr('gui.land.title'),'<a>',plugin_version), -- %2 title
						AIR.gsubEx(_tr('gui.land.content'),'<a>',land_count), _tr('talk.landmgr.open'), _tr('gui.general.close'), -- %3 content
						_tr('talk.landmgr.open'), --%4 button1
						_tr('gui.general.close')) --%5 button2
		return -1
	end
	-- [new] Create newLand
	if opt[2] == 'new' then
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
		return -1
	end
	-- [a|b|buy] Select Range
	if opt[2] == 'a' or opt[2] == 'b' or opt[2] == 'buy' then
		if newLand[player]==nil then
			Actor:sendText(player,_tr('title.land.nolicense'),5)
			return -1
		end
		local xyz=AIR.pos2vec({Actor:getPos(player)})
		xyz.y=xyz.y-1
		IL_BP_SelectRange(player,xyz,newLand[player].step)
		return -1
	end
	-- [giveup] Give up incp land
	if opt[2] == 'giveup' then
		IL_BP_GiveUp(player)
		return -1
	end
	-- [gui] LandMgr GUI
	if opt[2] == 'gui' then
		IL_Manager_GUI(player)
		return -1
	end
	-- [point] Set land tp point
	if opt[2] == 'point' and cfg.features.landtp then
		local xyz=AIR.pos2vec({Actor:getPos(player)})
		local landid=ILAPI.PosGetLand(xyz)
		if landid==-1 then
			Actor:sendText(player,_tr('title.landtp.fail.noland'),5)
			return -1
		end
		if ILAPI.GetOwner(landid)~=Actor:getXuid(player) then
			Actor:sendText(player,_tr('title.landtp.fail.notowner'),5)
			return -1
		end
		local landname = ILAPI.GetNickname(landid)
		if landname=='' then landname='<'.._tr('gui.landmgr.unnamed')..'> '..landid end
		land_data[landid].settings.tpoint[1]=xyz.x
		land_data[landid].settings.tpoint[2]=xyz.y
		land_data[landid].settings.tpoint[3]=xyz.z
		ILAPI.save()
		GUI(player,'ModalForm','FORM_NULL',_tr('gui.general.complete'),
														AIR.gsubEx(_tr('gui.landtp.point'),'<a>',AIR.vec2text(xyz),'<b>',landname),
														_tr('gui.general.iknow'),
														_tr('gui.general.close'))
		return -1
	end
	-- [tp] LandTp GUI
	if opt[2] == 'tp' and cfg.features.landtp then
		local tpland={}
		table.insert(tpland,1,'['.._tr('gui.general.plzchose')..']')
		for i,landId in pairs(ILAPI.GetPlayerLands(Actor:getXuid(player))) do
			local name = ILAPI.GetNickname(landId)
			local xpos = land_data[landId].settings.tpoint
			if name=='' then name='<'.._tr('gui.landmgr.unnamed')..'> '..landId end
			tpland[i+1]='('..xpos[1]..','..xpos[2]..','..xpos[3]..') '..name
		end
		GUI(player,'landtp','FORM_landtp',_tr('gui.landtp.title'),
										_tr('gui.landtp.tip'),
										_tr('gui.landtp.tip2'),
										json.encode(tpland)
									)
		return -1
	end
	-- [mgr] OP-LandMgr GUI
	if opt[2] == 'mgr' then
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			Actor:sendText(player,AIR.gsubEx('§l§b[§a LAND §b] §r'.._tr('command.land_mgr.noperm'),'<a>',xuid),0)
			return -1
		end
		IL_Manager_OPGUI(player)
		return -1
	end
	-- [mgr selectool] Set land_select tool
	if opt[2] == 'mgr' and opt[3] == 'selectool' then
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			Actor:sendText(player,AIR.gsubEx('§l§b[§a LAND §b] §r'.._tr('command.land_mgr.noperm'),'<a>',xuid),0)
			return -1
		end
		Actor:sendText(player,_tr('title.oplandmgr.setselectool'),5)
		TRS_Form[player].selectool=0
		return -1
	end
	-- [X] Unknown key
	Actor:sendText(player,'§l§b[§a LAND §b] §r'..AIR.gsubEx(_tr('command.error'),'<a>',opt[2]),0)
	return -1
end

-- ILAPI
function ILAPI.CreateLand(xuid,startpos,endpos,dimensionid)
	local landId
	while true do
		landId=AIR.getGuid()
		if land_data[landId]==nil then break end
	end

	-- Set newland cfg template
	land_data[landId]={}
	land_data[landId].settings={}
	land_data[landId].range={}
	land_data[landId].settings.share={}
	land_data[landId].settings.tpoint={}
	land_data[landId].range.start_position={}
	land_data[landId].range.end_position={}
	land_data[landId].permissions={}

	local perm = land_data[landId].permissions

	-- Land settings
	land_data[landId].settings.nickname=""
	land_data[landId].settings.describe=""
	land_data[landId].settings.tpoint[1]=startpos.x
	land_data[landId].settings.tpoint[2]=startpos.y
	land_data[landId].settings.tpoint[3]=startpos.z
	land_data[landId].settings.signtome=true
	land_data[landId].settings.signtother=true
	
	-- Land ranges
	table.insert(land_data[landId].range.start_position,1,startpos.x)
	table.insert(land_data[landId].range.start_position,2,startpos.y)
	table.insert(land_data[landId].range.start_position,3,startpos.z)
	table.insert(land_data[landId].range.end_position,1,endpos.x)
	table.insert(land_data[landId].range.end_position,2,endpos.y)
	table.insert(land_data[landId].range.end_position,3,endpos.z)
	land_data[landId].range.dim=dimensionid

	-- Land permission
	perm.allow_destroy=false
	perm.allow_place=false
	perm.allow_exploding=false
	perm.allow_attack=false
	perm.allow_open_chest=false
	perm.allow_pickupitem=false
	perm.allow_dropitem=true
	perm.use_anvil = true
	perm.use_barrel = false
	perm.use_beacon = false
	perm.use_bed = false
	perm.use_bell = true
	perm.use_blast_furnace = false
	perm.use_brewing_stand = false
	perm.use_campfire = false
	perm.use_cartography_table = true
	perm.use_composter = false
	perm.use_crafting_table = true
	perm.use_daylight_detector = false
	perm.use_dispenser = false
	perm.use_dropper = false
	perm.use_enchanting_table = true
	perm.use_fence_gate = false
	perm.use_furnace = false
	perm.use_grindstone = false
	perm.use_hopper = false
	perm.use_jukebox = false
	perm.use_loom = true
	perm.use_noteblock = false
	perm.use_shulker_box = false
	perm.use_smithing_table = false
	perm.use_smoker = false
	perm.use_trapdoor = false
	perm.use_lectern = false
	perm.use_cauldron = false

	-- Write data
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	ILAPI.save()
	updateChunk(landId,'add')
	updateVecMap(landId,'add')
end
function ILAPI.DeleteLand(landId)
	if land_data[landId]==nil then
		if debug_mode then print('[ILAPI] [DeleteLand] WARN!! Deleting nil land('..landId..').') end
		return
	end
	local owner=ILAPI.GetOwner(landId)
	if owner~='?' then
		table.remove(land_owners[owner],AIR.isValInList(land_owners[owner],landId))
	end
	updateChunk(landId,'del')
	updateVecMap(landId,'del')
	land_data[landId]=nil
	ILAPI.save()
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
function ILAPI.GetTpPoint(landid) --return vec3
	local i = AIR.deepcopy(land_data[landid].settings.tpoint)
	i[4] = land_data[landid].range.dim
	return LIB.pos2vec(i)
end
function ILAPI.GetVersion()
	return plugin_version
end

-- feature function
function GetOnlinePlayerList() -- player namelist
	local b={}
	for i,v in pairs(oList()) do
		b[#b+1] = Actor:getName(v)
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

	if TRS_Form[player].selectool==0 then
		local HandItem = Actor:getHand(player)
		if Item:isNull(HandItem) then goto PROCESS_1 end --fix crash
		Actor:sendText(player,AIR.gsubEx(_tr('title.oplandmgr.setsuccess'),'<a>',Item:getName(HandItem)),5)
		cfg.features.selection_tool=Item:getFullName(HandItem)
		ILAPI.save()
		TRS_Form[player].selectool=-1
		return -1
	end

	if newLand[player]~=nil then
		local HandItem = Actor:getHand(player)
		if Item:isNull(HandItem) or Item:getFullName(HandItem)~=cfg.features.selection_tool then goto PROCESS_1 end
		IL_BP_SelectRange(player,AIR.buildVec(x,y,z,dim),newLand[player].step)
		return -1
	end

	:: PROCESS_1 ::
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_destroy==true then return end -- Perm Allow
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
	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	
	local perm = land_data[landid].permissions
	if blockname == 'minecraft:end_portal_frame' and perm.allow_destroy then return end -- 末地门（拓充）
	if blockname == 'minecraft:lectern' and perm.allow_destroy then return end -- 讲台（拓充）
	if blockname == 'minecraft:bed' and perm.use_bed then return end -- 床
	if blockname == 'minecraft:crafting_table' and perm.use_crafting_table then return end -- 工作台
	if blockname == 'minecraft:campfire' and perm.use_campfire then return end -- 营火（烧烤）
	if blockname == 'minecraft:composter' and perm.use_composter then return end -- 堆肥桶（放置肥料）
	if (blockname == 'minecraft:undyed_shulker_box' or blockname == 'shulker_box') and perm.use_shulker_box then return end -- 潜匿箱
	if blockname == 'minecraft:noteblock' and perm.use_noteblock then return end -- 音符盒（调音）
	if blockname == 'minecraft:jukebox' and perm.use_jukebox then return end -- 唱片机（放置/取出唱片）
	if blockname == 'minecraft:bell' and perm.use_bell then return end -- 钟（敲钟）
	if (blockname == 'minecraft:daylight_detector_inverted' or blockname == 'daylight_detector') and perm.use_daylight_detector then return end -- 光线传感器（切换日夜模式）
	if blockname == 'minecraft:fence_gate' and perm.use_fence_gate then return end -- 栏栅门
	if blockname == 'minecraft:trapdoor' and perm.use_trapdoor then return end -- 活板门
	if blockname == 'minecraft:lectern' and perm.use_lectern then return end -- 讲台
	if blockname == 'minecraft:cauldron' and perm.use_cauldron then return end -- 炼药锅

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
function IL_LIS_onBlockInteractedWith(player,x,y,z)

	local plPos = {Actor:getPos(player)}
	local dim = plPos[4]
	local blockname = Utils:getBlockNameByPos(x,y,z,dim)

	local pos=AIR.buildVec(x,y,z,dim)
	local landid=ILAPI.PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust

	local perm = land_data[landid].permissions
	if blockname == 'minecraft:cartography_table' and perm.use_cartography_table then return end -- 制图台
	if blockname == 'minecraft:smithing_table' and perm.use_smithing_table then return end -- 锻造台
	if blockname == 'minecraft:furnace' and perm.use_furnace then return end -- 熔炉
	if blockname == 'minecraft:blast_furnace' and perm.use_blast_furnace then return end -- 高炉
	if blockname == 'minecraft:smoker' and perm.use_smoker then return end -- 烟熏炉
	if blockname == 'minecraft:brewing_stand' and perm.use_brewing_stand then return end -- 酿造台
	if blockname == 'minecraft:anvil' and perm.use_anvil then return end -- 铁砧
	if blockname == 'minecraft:grindstone' and perm.use_grindstone then return end -- 磨石
	if blockname == 'minecraft:enchanting_table' and perm.use_enchanting_table then return end -- 附魔台
	if blockname == 'minecraft:barrel' and perm.use_barrel then return end -- 桶
	if blockname == 'minecraft:beacon' and perm.use_beacon then return end -- 信标
	if blockname == 'minecraft:hopper' and perm.use_hopper then return end -- 漏斗
	if blockname == 'minecraft:dropper' and perm.use_dropper then return end -- 投掷器
	if blockname == 'minecraft:dispenser' and perm.use_dispenser then return end -- 发射器
	if blockname == 'minecraft:loom' and perm.use_loom then return end -- 织布机
	
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
	local players=oList()
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
			if not(land_data[landid].settings.signtome) then return end
			sendTitle(v,AIR.gsubEx(_tr('sign.listener.ownertitle'),'<a>',slname),_tr('sign.listener.ownersubtitle'))
		else
			if not(land_data[landid].settings.signtother) then return end
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
Listen('onPlayerAttack',IL_LIS_onPlayerAttack)
Listen('onExplode',IL_LIS_onExplode)
Listen('onPlayerTakeItem',IL_LIS_onPlayerTakeItem)
Listen('onPlayerDropItem',IL_LIS_onPlayerDropItem)
Listen('onBlockInteractedWith',IL_LIS_onBlockInteractedWith)

-- timer -> landsign
function enableLandSign()
	CLOCK_LANDSIGN = schedule("IL_TCB_LandSign",cfg.features.sign_frequency*2,0)
end
if cfg.features.landSign then
	enableLandSign()
end

-- timer -> particles
function enableParticles()
	CLOCK_PARTICLES = schedule("IL_TCB_SelectionParticles",2,0)
end
if cfg.features.particles then
	enableParticles()
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
makeCommand(MainCmd..' a',_tr('command.land_a'),1)
makeCommand(MainCmd..' b',_tr('command.land_b'),1)
makeCommand(MainCmd..' buy',_tr('command.land_buy'),1)
makeCommand(MainCmd..' mgr',_tr('command.land_mgr'),5)
makeCommand(MainCmd..' mgr selectool',_tr('command.land_mgr_selectool'),5)
if cfg.features.landtp then
	makeCommand(MainCmd..' tp',_tr('command.land_tp'),1)
	makeCommand(MainCmd..' point',_tr('command.land_point'),1)
end

-- print
print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version..', ')
print('[ILand] By: RedbeanW, License: GPLv3 with additional conditions.')

return ILAPI