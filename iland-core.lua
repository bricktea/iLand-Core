-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteXLoader            ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
plugin_version = '2.25'
DEV_MODE = true

langVer = 225
minAirVer = 220
minLXLVer = {0,4,3}

AIR = require('airLibs')
json = require('dkjson')

ArrayParticles={};ILAPI={}
newLand={};TRS_Form={}

MainCmd = 'land'
data_path = 'plugins\\iland\\'

if DEV_MODE then
	data_path = 'plugins\\LXL_Plugins\\iLand\\iland\\'
end

function updateChunk(landId,mode)
	local TxTz={}
	local dimid = land_data[landId].range.dimid
	function txz(x,z)
		if TxTz[x] == nil then TxTz[x] = {} end
		if TxTz[x][z] == nil then TxTz[x][z] = {} end
	end
	function chkmap(d,x,z)
		if ChunkMap[dimid][x] == nil then ChunkMap[dimid][x] = {} end
		if ChunkMap[dimid][x][z] == nil then ChunkMap[dimid][x][z] = {} end
	end
	function buildVec2(x,z)
		local f = {}
		f.x=x
		f.z=z
		return f
	end
	local size = cfg.features.chunk_side
	local sX = land_data[landId].range.start_position[1]
	local sZ = land_data[landId].range.start_position[3]
	local count = 0
	while (sX+size*count<=land_data[landId].range.end_position[1]+size) do
		local Cx,Cz = pos2chunk(buildVec2(sX+size*count,sZ+size*count))
		txz(Cx,Cz)
		local count2 = 0
		while (sZ+size*count2<=land_data[landId].range.end_position[3]+size) do
			local Cx,Cz = pos2chunk(buildVec2(sX+size*count,sZ+size*count2))
			txz(Cx,Cz)
			count2 = count2 + 1
		end
		count = count +1
	end

	-- add & del

	for Tx,a in pairs(TxTz) do
		for Tz,b in pairs(a) do
			-- Tx Tz
			if mode=='add' then
				chkmap(dimid,Tx,Tz)
				if AIR.isValInList(ChunkMap[dimid][Tx][Tz],landId) == -1 then
					table.insert(ChunkMap[dimid][Tx][Tz],#ChunkMap[dimid][Tx][Tz]+1,landId)
				end
			end
			if mode=='del' then
				local p = AIR.isValInList(ChunkMap[dimid][Tx][Tz],landId)
				if p~=-1 then
					table.remove(ChunkMap[dimid][Tx][Tz],p)
				end
			end
		end
	end
end
function updateVecMap(landId,mode)
	if mode=='add' then
		local spos = land_data[landId].range.start_position
		local epos = land_data[landId].range.end_position
		VecMap[landId]={}
		VecMap[landId].a={};VecMap[landId].b={}
		VecMap[landId].a = { x=spos[1], y=spos[2], z=spos[3] } --start
		VecMap[landId].b = { x=epos[1], y=epos[2], z=epos[3] } --end
	end
	if mode=='del' then
		VecMap[landId]=nil
	end
end
function updateLandTrustMap(landId)
	LandTrustedMap[landId]={}
	for n,xuid in pairs(land_data[landId].settings.share) do
		LandTrustedMap[landId][xuid]={}
	end
end
function updateLandOwnersMap(landId)
	LandOwnersMap[landId]={}
	LandOwnersMap[landId]=ILAPI.GetOwner(landId)
end
function updateLandOperatorsMap()
	LandOperatorsMap = {}
	for n,xuid in pairs(cfg.manager.operator) do
		LandOperatorsMap[xuid]={}
	end
end
function buildUIBITable()
	CanCtlMap = {}
	CanCtlMap[0] = {} -- UseItem
	CanCtlMap[1] = {} -- onBlockInteracted
	CanCtlMap[2] = {} -- ItemWhiteList
	CanCtlMap[3] = {} -- AttackWhiteList
	local useItemTmp = {
		'minecraft:bed',
		'minecraft:chest',
		'minecraft:trapped_chest',
		'minecraft:crafting_table',
		'minecraft:campfire',
		'minecraft:soul_campfire',
		'minecraft:composter',
		'minecraft:undyed_shulker_box',
		'minecraft:shulker_box',
		'minecraft:noteblock',
		'minecraft:jukebox',
		'minecraft:bell',
		'minecraft:daylight_detector_inverted',
		'minecraft:daylight_detector',
		'minecraft:lectern',
		'minecraft:cauldron',
		'minecraft:lever',
		'minecraft:stone_button','minecraft:wooden_button','minecraft:spruce_button',
		'minecraft:birch_button','minecraft:jungle_button','minecraft:acacia_button',
		'minecraft:dark_oak_button','minecraft:crimson_button','minecraft:warped_button',
		'minecraft:polished_blackstone_button',
		'minecraft:respawn_anchor'
	}
	local blockInterTmp = {
		'minecraft:cartography_table',
		'minecraft:smithing_table',
		'minecraft:furnace',
		'minecraft:blast_furnace',
		'minecraft:smoker',
		'minecraft:brewing_stand',
		'minecraft:anvil',
		'minecraft:grindstone',
		'minecraft:enchanting_table',
		'minecraft:barrel',
		'minecraft:beacon',
		'minecraft:hopper',
		'minecraft:dropper',
		'minecraft:dispenser',
		'minecraft:loom',
		'minecraft:trapdoor','minecraft:spruce_trapdoor','minecraft:birch_trapdoor',
		'minecraft:jungle_trapdoor','minecraft:acacia_trapdoor','minecraft:dark_oak_trapdoor',
		'minecraft:crimson_trapdoor','minecraft:warped_trapdoor',
		'minecraft:fence_gate','minecraft:spruce_fence_gate','minecraft:birch_fence_gate',
		'minecraft:jungle_fence_gate','minecraft:acacia_fence_gate','minecraft:dark_oak_fence_gate',
		'minecraft:crimson_fence_gate','minecraft:warped_fence_gate',
		'minecraft:wooden_door','minecraft:spruce_door','minecraft:birch_door',
		'minecraft:jungle_door','minecraft:acacia_door','minecraft:dark_oak_door',
		'minecraft:crimson_door','minecraft:warped_door',
		'minecraft:stonecutter_block'
	}
	local itemWlistTmp = {
		'minecraft:glow_ink_sac',
		'minecraft:end_crystal',
		'minecraft:ender_eye',
		'minecraft:axolotl_bucket',
		'minecraft:powder_snow_bucket',
		'minecraft:pufferfish_bucket',
		'minecraft:tropical_fish_bucket',
		'minecraft:salmon_bucket',
		'minecraft:cod_bucket',
		'minecraft:water_bucket',
		'minecraft:cod_bucket',
		'minecraft:lava_bucket',
		'minecraft:bucket'
	}
	local attackwlistTmp = {
		'minecraft:ender_crystal',
		'minecraft:armor_stand'
	}
	for n,uitem in pairs(useItemTmp) do
		CanCtlMap[0][uitem] = { 'E' }
	end
	for n,bint in pairs(blockInterTmp) do
		CanCtlMap[1][bint] = { 'E' }
	end
	for n,iwl in pairs(itemWlistTmp) do
		CanCtlMap[2][iwl] = { 'E' }
	end
		for n,awt in pairs(attackwlistTmp) do
		CanCtlMap[3][awt] = { 'E' }
	end
end
function buildChunks()
	ChunkMap={}

	ChunkMap[0] = {} -- 主世界
	ChunkMap[1] = {} -- 地狱
	ChunkMap[2] = {} -- 末地

	for landId,data in pairs(land_data) do
		updateChunk(landId,'add')
	end
end
function buildVecMap()
	VecMap={}
	for landId,data in pairs(land_data) do
		updateVecMap(landId,'add')
	end
end
function buildLTOPMap()
	-- LTOP = Land Trust|Owners|Operator
	LandTrustedMap={}
	LandOwnersMap={}
	LandOperatorsMap={}
	for landId,data in pairs(land_data) do
		updateLandTrustMap(landId)
		updateLandOwnersMap(landId)
	end
	updateLandOperatorsMap()
	buildUIBITable()
end

-- form -> callback
function FORM_NULL(player,id) end
function FORM_BACK_LandOPMgr(player,id)
	if not(id) then return end
	GUI_OPLMgr(player)
end
function FORM_BACK_LandMgr(player,id)
	if not(id) then return end
	if TRS_Form[player.xuid].backpo==1 then
		GUI_FastMgr(player)
		return
	end
	GUI_LMgr(player)
end
function FORM_land_buy(player,id)
	if not(id) then 
		sendText(player,AIR.gsubEx(_tr('title.buyland.ordersaved'),'<a>',cfg.features.selection_tool_name));return
	end

	local xuid = player.xuid
	local player_credits = money_get(player)
	if newLand[xuid].landprice>player_credits then
		sendText(player,_tr('title.buyland.moneynotenough')..AIR.gsubEx(_tr('title.buyland.ordersaved'),'<a>',cfg.features.selection_tool_name));return
	else
		money_del(player,newLand[xuid].landprice)
	end
	sendText(player,_tr('title.buyland.succeed'))
	ILAPI.CreateLand(xuid,newLand[xuid].posA,newLand[xuid].posB,newLand[xuid].dimid)
	newLand[xuid]=nil
	player:sendModalForm(
		'Complete.',
		_tr('gui.buyland.succeed'),
		_tr('gui.general.looklook'),
		_tr('gui.general.cancel'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_cfg(player,data)
	if data==nil then return end
	
	local landId = TRS_Form[player.xuid].landId
	local settings = land_data[landId].settings
	settings.signtome=data[1]
	settings.signtother=data[2]
	settings.signbuttom=data[3]
	settings.ev_explode=data[4]
	settings.ev_farmland_decay=data[5]
	settings.ev_piston_push=data[6]
	settings.ev_fire_spread=data[7]
	ILAPI.save()

	player:sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_perm(player,data)
	if data==nil then return end
	
	local perm = land_data[TRS_Form[player.xuid].landId].permissions

	perm.allow_place = data[1]
	perm.allow_destroy = data[2]
	perm.allow_dropitem = data[3]
	perm.allow_pickupitem = data[4]
	perm.allow_ride_entity = data[5]
	perm.allow_ride_trans = data[6]
	perm.allow_shoot = data[7]
	perm.allow_attack = data[8]

	perm.use_crafting_table = data[9]
	perm.use_furnace = data[10]
	perm.use_blast_furnace = data[11]
	perm.use_smoker = data[12]
	perm.use_brewing_stand = data[13]
	perm.use_cauldron = data[14]
	perm.use_anvil = data[15]
	perm.use_grindstone = data[16]
	perm.use_enchanting_table = data[17]
	perm.use_cartography_table = data[18]
	perm.use_smithing_table = data[19]
	perm.use_loom = data[20]
	perm.use_stonecutter = data[21]
	perm.use_beacon = data[22]
	
	perm.use_barrel = data[23]
	perm.use_hopper = data[24]
	perm.use_dropper = data[25]
	perm.use_dispenser = data[26]
	perm.use_shulker_box = data[27]
	perm.allow_open_chest = data[28]
	
	perm.use_campfire = data[29]
	perm.use_door = data[30]
	perm.use_trapdoor = data[31]
	perm.use_fence_gate = data[32]
	perm.use_bell = data[33]
	perm.use_jukebox = data[34]
	perm.use_noteblock = data[35]
	perm.use_composter = data[36]
	perm.use_bed = data[37]
	perm.use_item_frame = data[38]
	perm.use_daylight_detector = data[39]
	perm.use_lever = data[40]
	perm.use_button = data[41]
	perm.use_pressure_plate = data[42]
	perm.allow_throw_potion = data[43]
	perm.use_respawn_anchor = data[44]
	perm.use_fishing_hook = data[45]
	perm.use_bucket = data[46]

	ILAPI.save()
	player:sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_trust(player,data)
	if data==nil then return end
	
	local xuid = player.xuid
	local landId = TRS_Form[xuid].landId
	local shareList = land_data[landId].settings.share
	local playerList = TRS_Form[xuid].playerList
	local ownerXuid = ILAPI.GetOwner(landId)

	if data[1] then
		if data[2]==0 then return end
		local targetXuid=GetXuidFromId(playerList[data[2]+1])
		if ownerXuid==targetXuid then
			sendText(player,_tr('title.landtrust.cantaddown'));return
		end
		if AIR.isValInList(shareList,targetXuid)~=-1 then
			sendText(player,_tr('title.landtrust.alreadyexists'));return
		end
		shareList[#shareList+1]=targetXuid
		updateLandTrustMap(landId)
		ILAPI.save()
		if not(data[3]) then 
			player:sendModalForm(
				_tr('gui.general.complete'),
				'Complete.',
				_tr('gui.general.back'),
				_tr('gui.general.close'),
				FORM_BACK_LandMgr
			)
		end
	end
	if data[3] then
		if data[4]==0 then return end
		local targetXuid=shareList[data[4]]
		table.remove(shareList,AIR.isValInList(shareList,targetXuid))
		updateLandTrustMap(landId)
		ILAPI.save()
		player:sendModalForm(
			_tr('gui.general.complete'),
			'Complete.',
			_tr('gui.general.back'),
			_tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
	end
end
function FORM_land_gui_name(player,data)
	if data==nil then return end
	
	local landId=TRS_Form[player.xuid].landId
	if AIR.isTextSpecial(data[1]) then
		sendText(player,'FAILED');return
	end
	land_data[landId].settings.nickname=data[1]
	ILAPI.save()
	player:sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_describe(player,data)
	if data==nil then return end
	
	local landId=TRS_Form[player.xuid].landId
	if AIR.isTextSpecial(AIR.gsubEx(
		data[1],
		'$','Y',
		',','Y',
		'.','Y',
		'!','Y'
	))
	then
		sendText(player,'FAILED');return
	end
	land_data[landId].settings.describe=data[1]
	ILAPI.save()
	player:sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_transfer(player,data)
	if data==nil or data[1]==0 then return end
	
	local xuid=player.xuid
	local landId=TRS_Form[xuid].landId
	local ownerXuid=ILAPI.GetOwner(landId)
	local targetXuid=GetXuidFromId(TRS_Form[xuid].playerList[data[1]+1])
	if targetXuid==ownerXuid then sendText(player,_tr('title.landtransfer.canttoown'));return end
	table.remove(land_owners[ownerXuid],AIR.isValInList(land_owners[ownerXuid],landId))
	table.insert(land_owners[targetXuid],#land_owners[targetXuid]+1,landId)
	updateLandOwnersMap(landId)
	ILAPI.save()
	player:sendModalForm(
		_tr('gui.general.complete'),
		AIR.gsubEx(_tr('title.landtransfer.complete'),'<a>',ILAPI.GetNickname(landId,true),'<b>',GetIdFromXuid(targetXuid)),
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_delete(player,id)
	if not(id) then return end
	local xuid=player.xuid
	local landId=TRS_Form[xuid].landId
	ILAPI.DeleteLand(landId)
	money_add(player,TRS_Form[xuid].landvalue)
	player:sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui(player,data,lid)
	if data==nil then return end
	
	local xuid=player.xuid

	local landId
	if lid==nil or lid=='' then
		landId = land_owners[xuid][data[1]+1]
	else
		landId = lid
	end

	TRS_Form[xuid].landId=landId
	if data[2]==0 then --查看领地信息
		local dpos = land_data[landId].range
		local length = math.abs(dpos.start_position[1] - dpos.end_position[1]) + 1 
		local width = math.abs(dpos.start_position[3] - dpos.end_position[3]) + 1
		local height = math.abs(dpos.start_position[2] - dpos.end_position[2]) + 1
		local vol = length * width * height
		local squ = length * width
		player:sendModalForm(
			_tr('gui.landmgr.landinfo.title'),
			AIR.gsubEx(_tr('gui.landmgr.landinfo.content'),
					'<a>',GetIdFromXuid(ILAPI.GetOwner(landId)),
					'<b>',landId,
					'<c>',ILAPI.GetNickname(landId,false),
					'<d>',ILAPI.GetLandDimension(landId),
					'<e>',did2dim(dpos.dimid),
					'<f>',AIR.vec2text(AIR.pos2vec(dpos.start_position)),
					'<g>',AIR.vec2text(AIR.pos2vec(dpos.end_position)),
					'<h>',length,'<i>',width,'<j>',height,
					'<k>',squ,'<l>',vol),
			_tr('gui.general.iknow'),
			_tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
	end
	if data[2]==1 then --编辑领地选项
		local IsSignDisabled = ''
		if not(cfg.features.landSign) then
			IsSignDisabled=' ('.._tr('talk.features.closed')..')'
		end
		local Form = mc.newCustomForm()
		local settings=land_data[landId].settings
		Form:setTitle(_tr('gui.landcfg.title'))
		Form:addLabel(_tr('gui.landcfg.tip'))
		Form:addLabel(_tr('gui.landcfg.landsign')..IsSignDisabled)
		Form:addSwitch(_tr('gui.landcfg.landsign.tome'),settings.signtome)
		Form:addSwitch(_tr('gui.landcfg.landsign.tother'),settings.signtother)
		Form:addSwitch(_tr('gui.landcfg.landsign.bottom'),settings.signbuttom)
		Form:addLabel(_tr('gui.landcfg.inside'))
		Form:addSwitch(_tr('gui.landcfg.inside.explode'),settings.ev_explode) 
		Form:addSwitch(_tr('gui.landcfg.inside.farmland_decay'),settings.ev_farmland_decay)
		Form:addSwitch(_tr('gui.landcfg.inside.piston_push'),settings.ev_piston_push)
		Form:addSwitch(_tr('gui.landcfg.inside.fire_spread'),settings.ev_fire_spread)
		player:sendForm(Form,FORM_land_gui_cfg)
		return
	end
	if data[2]==2 then --编辑领地权限
		local perm = land_data[landId].permissions
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landmgr.landperm.title'))
		Form:addLabel(_tr('gui.landmgr.landperm.options.title'))
		Form:addLabel(_tr('gui.landmgr.landperm.basic_options'))
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.place'),perm.allow_place)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.destroy'),perm.allow_destroy)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.dropitem'),perm.allow_dropitem)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.pickupitem'),perm.allow_pickupitem)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.ride_entity'),perm.allow_ride_entity)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.ride_trans'),perm.allow_ride_trans)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.shoot'),perm.allow_shoot)
		Form:addSwitch(_tr('gui.landmgr.landperm.basic_options.attack'),perm.allow_attack)
		Form:addLabel(_tr('gui.landmgr.landperm.funcblock_options'))
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.crafting_table'),perm.use_crafting_table)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.furnace'),perm.use_furnace)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.blast_furnace'),perm.use_blast_furnace)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.smoker'),perm.use_smoker)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.brewing_stand'),perm.use_brewing_stand)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.cauldron'),perm.use_cauldron)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.anvil'),perm.use_anvil)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.grindstone'),perm.use_grindstone)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.enchanting_table'),perm.use_enchanting_table)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.cartography_table'),perm.use_cartography_table)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.smithing_table'),perm.use_smithing_table)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.loom'),perm.use_loom)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.stonecutter'),perm.use_stonecutter)
		Form:addSwitch(_tr('gui.landmgr.landperm.funcblock_options.beacon'),perm.use_beacon)
		Form:addLabel(_tr('gui.landmgr.landperm.contblock_options'))
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.barrel'),perm.use_barrel)
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.hopper'),perm.use_hopper)
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.dropper'),perm.use_dropper)
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.dispenser'),perm.use_dispenser)
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.shulker_box'),perm.use_shulker_box)
		Form:addSwitch(_tr('gui.landmgr.landperm.contblock_options.chest'),perm.allow_open_chest)
		Form:addLabel(_tr('gui.landmgr.landperm.other_options'))
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.campfire'),perm.use_campfire)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.door'),perm.use_door)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.trapdoor'),perm.use_trapdoor)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.fence_gate'),perm.use_fence_gate)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.bell'),perm.use_bell)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.jukebox'),perm.use_jukebox)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.noteblock'),perm.use_noteblock)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.composter'),perm.use_composter)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.bed'),perm.use_bed)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.item_frame'),perm.use_item_frame)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.daylight_detector'),perm.use_daylight_detector)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.lever'),perm.use_lever)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.button'),perm.use_button)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.pressure_plate'),perm.use_pressure_plate)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.throw_potion'),perm.allow_throw_potion)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.respawn_anchor'),perm.use_respawn_anchor)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.fishing'),perm.use_fishing_hook)
		Form:addSwitch(_tr('gui.landmgr.landperm.other_options.bucket'),perm.use_bucket)
		Form:addLabel(_tr('gui.landmgr.landperm.editevent'))
		player:sendForm(Form,FORM_land_gui_perm)
	end
	if data[2]==3 then --编辑信任名单
		if cfg.features.offlinePlayerInList then
			TRS_Form[xuid].playerList = GetAllPlayerList()
		else
			TRS_Form[xuid].playerList = GetOnlinePlayerList()
		end
		local shareList={}
		for num,xuid in pairs(land_data[landId].settings.share) do
			shareList[#shareList+1]=GetIdFromXuid(xuid)
		end
		table.insert(TRS_Form[xuid].playerList,1,'['.._tr('gui.general.plzchose')..']')
		table.insert(shareList,1,'['.._tr('gui.general.plzchose')..']')
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landtrust.title'))
		Form:addLabel(_tr('gui.landtrust.tip'))
		Form:addSwitch(_tr('gui.landtrust.addtrust'),false)
		Form:addDropdown(_tr('gui.landtrust.selectplayer'),TRS_Form[xuid].playerList)
		Form:addSwitch(_tr('gui.landtrust.rmtrust'),false)
		Form:addDropdown(_tr('gui.landtrust.selectplayer'),shareList)
		player:sendForm(Form,FORM_land_gui_trust)
		return
	end
	if data[2]==4 then --领地nickname
		local nickn=ILAPI.GetNickname(landId,false)
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landtag.title'))
		Form:addLabel(_tr('gui.landtag.tip'))
		Form:addInput("",nickn)
		player:sendForm(Form,FORM_land_gui_name)
		return
	end
	if data[2]==5 then --领地describe
		local desc=ILAPI.GetDescribe(landId)
		if desc=='' then desc='['.._tr('gui.landmgr.unmodified')..']' end
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landdescribe.title'))
		Form:addLabel(_tr('gui.landdescribe.tip'))
		Form:addInput("",desc)
		player:sendForm(Form,FORM_land_gui_describe)
		return
	end
	if data[2]==6 then --领地过户
		if cfg.features.offlinePlayerInList then
			TRS_Form[xuid].playerList = GetAllPlayerList()
		else
			TRS_Form[xuid].playerList = GetOnlinePlayerList()
		end
		table.insert(TRS_Form[xuid].playerList,1,'['.._tr('gui.general.plzchose')..']')
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landtransfer.title'))
		Form:addLabel(_tr('gui.landtransfer.tip'))
		Form:addDropdown(_tr('talk.land.selecttargetplayer'),TRS_Form[xuid].playerList)
		player:sendForm(Form,FORM_land_gui_transfer)
		return
	end
	if data[2]==7 then --删除领地
		local dpos = land_data[landId].range
		local height = math.abs(dpos.start_position[2] - dpos.end_position[2]) + 1
		local length = math.abs(dpos.start_position[1] - dpos.end_position[1]) + 1
		local width = math.abs(dpos.start_position[3] - dpos.end_position[3]) + 1
		TRS_Form[xuid].landvalue=math.modf(calculation_price(length,width,height,ILAPI.GetLandDimension(landId))*cfg.land_buy.refund_rate)
		player:sendModalForm(
			_tr('gui.delland.title'),
			AIR.gsubEx(_tr('gui.delland.content'),'<a>',TRS_Form[xuid].landvalue,'<b>',cfg.money.credit_name),
			_tr('gui.general.yes'),
			_tr('gui.general.cancel'),
			FORM_land_gui_delete
		);return
	end
end
function FORM_land_mgr(player,data)
	if data==nil then return end
	local xuid=player.xuid
	if data[2]~='' then
		cfg.land.player_max_lands = tonumber(data[2])
	end
	if data[3]~='' then
		cfg.land.land_max_square = tonumber(data[3])
	end
	if data[4]~='' then
		cfg.land.land_min_square = tonumber(data[4])
	end
	cfg.land_buy.refund_rate = data[5]/100
	if data[6]==0 then
		cfg.money.protocol='llmoney'
	end
	if data[6]==1 then
		cfg.money.protocol='scoreboard'
	end
	if data[7]~='' then
		cfg.money.scoreboard_objname=data[7]
	end
	if data[8]~='' then
		cfg.money.credit_name=data[8]
	end
	cfg.money.discount=data[9]
	if data[10]==0 then
		cfg.land_buy.calculation_3D='m-1'
	end
	if data[10]==1 then
		cfg.land_buy.calculation_3D='m-2'
	end
	if data[10]==2 then
		cfg.land_buy.calculation_3D='m-3'
	end
	if data[11]~='' then
		cfg.land_buy.price_3D[1]=tonumber(data[11])
	end
	if data[12]~='' then
		cfg.land_buy.price_3D[2]=tonumber(data[12])
	end
	if data[13]==0 then
		cfg.land_buy.calculation_2D='d-1'
	end
	if data[14]~='' then
		cfg.land_buy.price_2D[1]=tonumber(data[14])
	end
	cfg.manager.default_language=TRS_Form[xuid].langlist[data[15]+1]
	cfg.features.landSign = data[16]
	cfg.features.particles = data[17]
	cfg.features.force_talk = data[18]
	cfg.update_check = data[19]
	cfg.features.auto_update = data[20]
	cfg.features.offlinePlayerInList = data[21]
	cfg.features.land_2D = data[22]
	cfg.features.land_3D = data[23]
	if data[24]~='' then
		cfg.features.selection_tool_name=data[24]
	end
	if data[25]~='' then
		cfg.features.sign_frequency=tonumber(data[25])
	end
	if data[26]~='' then
		cfg.features.chunk_side=tonumber(data[26])
	end
	if data[27]~='' then
		cfg.features.player_max_ple=tonumber(data[27])
	end

	ILAPI.save()
	
	-- do rt

	if cfg.features.landSign and CLOCK_LANDSIGN==nil then
		enableLandSign()
	end
	if not(cfg.features.landSign) and CLOCK_LANDSIGN~=nil then
		clearInterval(CLOCK_LANDSIGN)
		clearInterval(BUTTOM_SIGN)
		CLOCK_LANDSIGN=nil
		BUTTOM_SIGN=nil
	end
	if cfg.features.particles and CLOCK_PARTICLES==nil then
		enableParticles()
	end
	if not(cfg.features.particles) and CLOCK_PARTICLES~=nil then
		clearInterval(CLOCK_PARTICLES)
		CLOCK_PARTICLES=nil
	end

	i18n_data = json.decode(file.readFrom(data_path..'lang\\'..cfg.manager.default_language..'.json'))

	-- lands manager
	
	if data[1]==0 then
		player:sendModalForm(
			_tr('gui.general.complete'),
			"Complete.",
			_tr('gui.general.back'),
			_tr('gui.general.close'),
			FORM_BACK_LandOPMgr
		)
		return
	end

	local IdLst={}
	for landId,data in pairs(land_data) do
		IdLst[#IdLst+1]=landId
	end
	TRS_Form[xuid].landId = IdLst[data[1]]
	GUI_FastMgr(player,true)
end
function FORM_land_choseDim(player,id)
	if id==true and not(cfg.features.land_3D) then
		sendText(player,AIR.gsubEx(_tr('gui.buyland.unsupport'),'<a>','3D'))
		return
	end
	if id==false and not(cfg.features.land_2D) then
		sendText(player,AIR.gsubEx(_tr('gui.buyland.unsupport'),'<a>','2D'))
		return
	end

	sendText(player,_tr('title.getlicense.succeed')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
	local xuid=player.xuid
	newLand[xuid]={}
	if id then
		newLand[xuid].dimension='3D'
	else
		newLand[xuid].dimension='2D'
	end
	newLand[xuid].posA={}
	newLand[xuid].posB={}
	newLand[xuid].step=0
end
function FORM_landtp(player,data)
	if data==nil or data[1]==0 then return end

	local xuid=player.xuid
	local lands = ILAPI.GetPlayerLands(xuid)
	for n,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
		lands[#lands+1]=landId
	end
	local landId = lands[data[1]]

	local pos = land_data[landId].settings.tpoint
	local dimid = land_data[landId].range.dimid

	if dimid==0 or dimid==2 then
		high=256+1
	else
		high=128+1
	end
	local safey=0
	local NMSL=false
	for i=pos[2],high do
		local bl = mc.getBlock(mc.newIntPos(pos[1],i,pos[3],dimid))
		if bl.type=='minecraft:air' then
			if NMSL then
				safey=i
				break
			end
			NMSL=true
		end
	end
	player:teleport(mc.newFloatPos(pos[1],safey,pos[3],dimid))
	local ct = 'Complete.'
	if pos[2]~=safey then
		ct = AIR.gsubEx(_tr('gui.landtp.safetp'),'<a>',tostring(safey-pos[2]))
	end
	player:sendModalForm(
		_tr('gui.general.complete'),
		ct,
		_tr('gui.general.yes'),
		_tr('gui.general.close'),
		FORM_NULL
	)
end
function FORM_land_fast(player,id)
	if id==nil then return end
	local xuid=player.xuid
	TRS_Form[xuid].backpo = 1
	FakeData = {}
	FakeData[2] = id
	if id~=8 then
		FORM_land_gui(player,FakeData,TRS_Form[xuid].landId)
	end
end
function FORM_land_gde(player,id)
	if id==nil then return end
	if id==0 then
		Eventing_onPlayerCmd(player,'land new')
	end
	if id==1 then
		Eventing_onPlayerCmd(player,'land gui')
	end
end
function BoughtProg_SelectRange(player,vec4,mode)
	local xuid = player.xuid
    local NewData = newLand[xuid]
    
    if NewData==nil then return end
    if mode==0 then -- point A
        if mode~=NewData.step then
			sendText(player,_tr('title.selectrange.failbystep'));return
        end
		NewData.dimid = vec4.dimid
		NewData.posA.x=math.modf(vec4.x) --省函数...
		if NewData.dimension=='3D' then
			NewData.posA.y=math.modf(vec4.y)
		else
			NewData.posA.y=0
		end
		NewData.posA.z=math.modf(vec4.z)
        sendText(
			player,
			AIR.gsubEx(
				_tr('title.selectrange.seled'),
				'<a>','a',
				'<b>',did2dim(vec4.dimid),
				'<c>',NewData.posA.x,
				'<d>',NewData.posA.y,
				'<e>',NewData.posA.z)
				..'\n'..
				AIR.gsubEx(
					_tr('title.selectrange.spointb'),
					'<a>',cfg.features.selection_tool_name
				)
			)
		NewData.step = 1
    end
    if mode==1 then -- point B
        if vec4.dimid~=NewData.dimid then
			sendText(player,_tr('title.selectrange.failbycdimid'));return
        end
		NewData.posB.x=math.modf(vec4.x)
		if NewData.dimension=='3D' then
			NewData.posB.y=math.modf(vec4.y)
		else
			NewData.posB.y=255
		end
		NewData.posB.z=math.modf(vec4.z)
        sendText(
			player,
			AIR.gsubEx(
				_tr('title.selectrange.seled'),
				'<a>','b',
				'<b>',did2dim(vec4.dimid),
				'<c>',NewData.posB.x,
				'<d>',NewData.posB.y,
				'<e>',NewData.posB.z)
				..'\n'..
				AIR.gsubEx(
					_tr('title.selectrange.bebuy'),
					'<a>',cfg.features.selection_tool_name
				)
			)
		NewData.step = 2

		local edges
		if NewData.dimension=='3D' then
			edges = cubeGetEdge(NewData.posA,NewData.posB)
		else
			edges = cubeGetEdge_2D(NewData.posA,NewData.posB)
		end
		if #edges>cfg.features.player_max_ple then
			sendText(player,_tr('title.selectrange.nople'),0)
		else
			ArrayParticles[xuid]={}
			ArrayParticles[xuid]=edges
		end
    end
	if mode==2 then -- buy Land
		BoughtProg_CreateOrder(player)
	end
end
function BoughtProg_CreateOrder(player)
	local xuid=player.xuid
    local NewData = newLand[xuid]
	ArrayParticles[xuid]=nil 

    if NewData==nil or NewData.step~=2 then
		sendText(player,_tr('title.createorder.failbystep'))
        return
    end

    local length = math.abs(NewData.posA.x - NewData.posB.x) + 1
    local width = math.abs(NewData.posA.z - NewData.posB.z) + 1
    local height = math.abs(NewData.posA.y - NewData.posB.y) + 1
    local vol = length * width * height
    local squ = length * width

	--- 违规圈地判断
	if squ>cfg.land.land_max_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		sendText(player,_tr('title.createorder.toobig')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		NewData.step=0
		return
	end
	if squ<cfg.land.land_min_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		sendText(player,_tr('title.createorder.toosmall')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		NewData.step=0
		return
	end
	if height<2 then
		sendText(player,_tr('title.createorder.toolow')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		NewData.step=0
		return
	end

	--- 领地冲突判断
	local edge=cubeGetEdge(NewData.posA,NewData.posB)
	for i=1,#edge do
		edge[i].dimid=NewData.dimid
		local tryLand = ILAPI.PosGetLand(edge[i])
		if tryLand ~= -1 then
			sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',tryLand,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
			NewData.step=0;return
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dimid==NewData.dimid then
			edge=cubeGetEdge(VecMap[landId].a,VecMap[landId].b)
			for i=1,#edge do
				if isPosInCube(edge[i],NewData.posA,NewData.posB)==true then
					sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',landId,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
					NewData.step=0;return
				end
			end
		end
	end

	--- 购买
    NewData.landprice = calculation_price(length,width,height,NewData.dimension)
	local dis_info = ''
	local dim_info = ''
	if cfg.money.discount<100 then
		dis_info=AIR.gsubEx(_tr('gui.buyland.discount'),'<a>',tostring(100-cfg.money.discount))
	end
	if NewData.dimension=='3D' then
		dim_info = '§l3D-Land §r'
	else
		dim_info = '§l2D-Land §r'
	end
	player:sendModalForm(
		dim_info.._tr('gui.buyland.title')..dis_info,
		AIR.gsubEx(
			_tr('gui.buyland.content'),
			'<a>',length,
			'<b>',width,
			'<c>',height,
			'<d>',vol,
			'<e>',NewData.landprice,
			'<f>',cfg.money.credit_name,
			'<g>',money_get(player)
		),
		_tr('gui.general.buy'),
		_tr('gui.general.close'),
		FORM_land_buy
	)

end
function BoughtProg_GiveUp(player)
    local xuid=player.xuid
	if newLand[xuid]==nil then
        sendText(player,_tr('title.giveup.failed'));return
    end
	newLand[xuid]=nil
	ArrayParticles[xuid]=nil
	sendText(player,_tr('title.giveup.succeed'))
end
function GUI_LMgr(player)
	local xuid=player.xuid
	local thelands=ILAPI.GetPlayerLands(xuid)
	if #thelands==0 then
		sendText(player,_tr('title.landmgr.failed'));return
	end

	local welcomeText=_tr('gui.landmgr.content')
	local landId=ILAPI.PosGetLand(formatPlayerPos(player.pos))

	if landId~=-1 then
		welcomeText = welcomeText..AIR.gsubEx(
			_tr('gui.landmgr.ctplus'),
			'<a>',ILAPI.GetNickname(landId,true)
		)
	end

	local features = {
		_tr('gui.landmgr.options.landinfo'),
		_tr('gui.landmgr.options.landcfg'),
		_tr('gui.landmgr.options.landperm'),
		_tr('gui.landmgr.options.landtrust'),
		_tr('gui.landmgr.options.landtag'),
		_tr('gui.landmgr.options.landdescribe'),
		_tr('gui.landmgr.options.landtransfer'),
		_tr('gui.landmgr.options.delland')
	}

	local lands={}
	for i,v in pairs(thelands) do
		local f='§l'..ILAPI.GetLandDimension(v)..'§r '..ILAPI.GetNickname(v,true)
		lands[i]=f
	end

	local Form = mc.newCustomForm()
	Form:setTitle(_tr('gui.landmgr.title'))
	Form:addLabel(welcomeText)
	Form:addDropdown(_tr('gui.landmgr.select'),lands)
	Form:addStepSlider(_tr('gui.oplandmgr.selectoption'),features)

	player:sendForm(Form,FORM_land_gui)
end
function GUI_OPLMgr(player)

	local xuid=player.xuid
	-- build land_list
	local landlst={}
	local land_default=0
	local lid=ILAPI.PosGetLand(formatPlayerPos(player.pos))
	for i,v in pairs(land_data) do
		local thisOwner=ILAPI.GetOwner(i)
		if thisOwner~='?' then thisOwner=GetIdFromXuid(thisOwner) else thisOwner='?' end
		if land_data[i].settings.nickname=='' then
			landlst[#landlst+1]='['.._tr('gui.landmgr.unnamed')..'] ('..thisOwner..') ['..i..']'
		else
			landlst[#landlst+1]=land_data[i].settings.nickname..' ('..thisOwner..') ['..i..']'
		end
		if i==lid then
			landlst[#landlst] = _tr('gui.oplandmgr.there')..landlst[#landlst]
			land_default = #landlst
		end
	end
	table.insert(landlst,1,'['.._tr('gui.general.plzchose')..']')

	-- plugin information
	local latestVer,iAnn
	if Global_LatestVersion~=nil then
		latestVer = Global_LatestVersion
	else
		latestVer = '-'
	end
	if Global_IsAnnouncementEnabled~=nil and Global_IsAnnouncementEnabled~=false then
		iAnn = Global_Announcement
	else
		iAnn = '-'
	end
	
	-- money protocol
	local money_protocols = {'LLMoney',_tr('talk.scoreboard')}
	local money_default
	if cfg.money.protocol=='scoreboard' then
		money_default=1
	else
		money_default=0
	end
	local calculation_3D = {'m-1','m-2','m-3'}
	local c3d_default=0
	if cfg.land_buy.calculation_3D=='m-1' then
		c3d_default=0
	end
	if cfg.land_buy.calculation_3D=='m-2' then
		c3d_default=1
	end
	if cfg.land_buy.calculation_3D=='m-3' then
		c3d_default=2
	end
	local calculation_2D = {'d-1'}
	local aprice = AIR.deepcopy(cfg.land_buy.price_3D)
	if aprice[2]==nil then
		aprice[2]=''
	end
	local bprice = AIR.deepcopy(cfg.land_buy.price_2D)

	-- language
	local langLst = {}
	local default_lang = 0
	for n,file in pairs(file.getFilesList(data_path..'lang\\')) do
		local tmp = AIR.split(file,'.')
		if tmp[2]=='json' then
			langLst[#langLst+1]=tmp[1]
		end
		if tmp[1]==cfg.manager.default_language then
			default_lang=#langLst-1
		end
	end
	TRS_Form[xuid].langlist = langLst

	-- build form
	local Form = mc.newCustomForm()
	Form:setTitle(_tr('gui.oplandmgr.title'))
	Form:addLabel(_tr('gui.oplandmgr.tip'))
	Form:addLabel(AIR.gsubEx(_tr('gui.oplandmgr.plugin'),'<a>',langVer))
	Form:addLabel(
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.ver'),'<a>',plugin_version)..'\n'..
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.latest'),'<a>',latestVer)..'\n'..
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.acement'),'<a>',iAnn)
	)
	Form:addLabel(_tr('gui.oplandmgr.landmgr'))
	Form:addDropdown(_tr('gui.oplandmgr.selectland'),landlst,land_default)
	Form:addLabel(_tr('gui.oplandmgr.landcfg'))
	Form:addInput(_tr('gui.oplandmgr.landcfg.maxland'),tostring(cfg.land.player_max_lands))
	Form:addInput(_tr('gui.oplandmgr.landcfg.maxsqu'),tostring(cfg.land.land_max_square))
	Form:addInput(_tr('gui.oplandmgr.landcfg.minsqu'),tostring(cfg.land.land_min_square))
	Form:addSlider(_tr('gui.oplandmgr.landcfg.refundrate'),0,100,1,cfg.land_buy.refund_rate*100)
	Form:addLabel(_tr('gui.oplandmgr.economy'))
	Form:addDropdown(_tr('gui.oplandmgr.economy.protocol'),money_protocols,money_default)
	Form:addInput(_tr('gui.oplandmgr.economy.sbname'),cfg.money.scoreboard_objname)
	Form:addInput(_tr('gui.oplandmgr.economy.credit_name'),cfg.money.credit_name)
	Form:addSlider(_tr('gui.oplandmgr.economy.discount'),0,100,1,cfg.money.discount)
	Form:addDropdown(_tr('gui.oplandmgr.economy.calculation_3D'),calculation_3D,c3d_default)
	Form:addInput(_tr('gui.oplandmgr.economy.price')..'[1]',tostring(aprice[1]))
	Form:addInput(_tr('gui.oplandmgr.economy.price')..'[2]',tostring(aprice[2]))
	Form:addDropdown(_tr('gui.oplandmgr.economy.calculation_2D'),calculation_2D)
	Form:addInput(_tr('gui.oplandmgr.economy.price')..'[1]',tostring(bprice[1]))
	Form:addLabel(_tr('gui.oplandmgr.i18n'))
	Form:addDropdown(_tr('gui.oplandmgr.i18n.default'),langLst,default_lang)
	Form:addLabel(_tr('gui.oplandmgr.features'))
	Form:addSwitch(_tr('gui.oplandmgr.features.landsign'),cfg.features.landSign)
	Form:addSwitch(_tr('gui.oplandmgr.features.particles'),cfg.features.particles)
	Form:addSwitch(_tr('gui.oplandmgr.features.forcetalk'),cfg.features.force_talk)
	Form:addSwitch(_tr('gui.oplandmgr.features.autochkupd'),cfg.update_check)
	Form:addSwitch(_tr('gui.oplandmgr.features.autoupdate'),cfg.features.auto_update)
	Form:addSwitch(_tr('gui.oplandmgr.features.offlinepls'),cfg.features.offlinePlayerInList)
	Form:addSwitch(_tr('gui.oplandmgr.features.2dland'),cfg.features.land_2D)
	Form:addSwitch(_tr('gui.oplandmgr.features.3dland'),cfg.features.land_3D)
	Form:addInput(_tr('gui.oplandmgr.features.seltolname'),cfg.features.selection_tool_name)
	Form:addInput(_tr('gui.oplandmgr.features.frequency'),tostring(cfg.features.sign_frequency))
	Form:addInput(_tr('gui.oplandmgr.features.chunksize'),tostring(cfg.features.chunk_side))
	Form:addInput(_tr('gui.oplandmgr.features.maxple'),tostring(cfg.features.player_max_ple))

	player:sendForm(Form,FORM_land_mgr)						
end
function GUI_FastMgr(player,isOP)
	local xuid=player.xuid
	local thelands=ILAPI.GetPlayerLands(xuid)
	if #thelands==0 and isOP==nil then
		sendText(player,_tr('title.landmgr.failed'));return
	end

	local landId = TRS_Form[xuid].landId
	if land_data[landId]==nil then
		return
	end

	local Form = mc.newSimpleForm()
	Form:setTitle(_tr('gui.fastlmgr.title'))
	if isOP==nil then
		Form:setContent(AIR.gsubEx(_tr('gui.fastlmgr.content'),'<a>',ILAPI.GetNickname(landId,true)))
	else
		Form:setContent(_tr('gui.fastlmgr.operator'))
	end
	Form:addButton(_tr('gui.landmgr.options.landinfo'))
	Form:addButton(_tr('gui.landmgr.options.landcfg'))
	Form:addButton(_tr('gui.landmgr.options.landperm'))
	Form:addButton(_tr('gui.landmgr.options.landtrust'))
	Form:addButton(_tr('gui.landmgr.options.landtag'))
	Form:addButton(_tr('gui.landmgr.options.landdescribe'))
	Form:addButton(_tr('gui.landmgr.options.landtransfer'))
	Form:addButton(_tr('gui.landmgr.options.delland'))
	Form:addButton(_tr('gui.general.close'),'textures/ui/icon_import')
	player:sendForm(Form,FORM_land_fast)
end

-- ILAPI
function ILAPI.CreateLand(xuid,startpos,endpos,dimid)
	local landId
	while true do
		landId=formatGuid(system.randomGuid())
		if land_data[landId]==nil then break end
	end

	-- Set newLand cfg template
	land_data[landId]={}
	land_data[landId].settings={}
	land_data[landId].range={}
	land_data[landId].settings.share={}
	land_data[landId].settings.tpoint={}
	land_data[landId].range.start_position={}
	land_data[landId].range.end_position={}
	land_data[landId].permissions={}
	
	-- Land settings
	local settings=land_data[landId].settings
	settings.nickname=""
	settings.describe=""
	settings.tpoint[1]=startpos.x
	settings.tpoint[2]=startpos.y+1
	settings.tpoint[3]=startpos.z
	settings.signtome=true
	settings.signtother=true
	settings.signbuttom=true
	settings.ev_explode=false
	settings.ev_farmland_decay=false
	settings.ev_piston_push=false
	settings.ev_fire_spread=false

	-- Land ranges
	local posA,posB = fmCube(startpos,endpos)
	table.insert(land_data[landId].range.start_position,1,posA.x)
	table.insert(land_data[landId].range.start_position,2,posA.y)
	table.insert(land_data[landId].range.start_position,3,posA.z)
	table.insert(land_data[landId].range.end_position,1,posB.x)
	table.insert(land_data[landId].range.end_position,2,posB.y)
	table.insert(land_data[landId].range.end_position,3,posB.z)
	land_data[landId].range.dimid=dimid

	local perm = land_data[landId].permissions

	-- Land permission
	perm.allow_destroy=false
	perm.allow_place=false
	perm.allow_attack=false
	perm.allow_open_chest=false
	perm.allow_pickupitem=false
	perm.allow_dropitem=false
	perm.use_anvil = false
	perm.use_barrel = false
	perm.use_beacon = false
	perm.use_bed = false
	perm.use_bell = false
	perm.use_blast_furnace = false
	perm.use_brewing_stand = false
	perm.use_campfire = false
	perm.use_cartography_table = false
	perm.use_composter = false
	perm.use_crafting_table = false
	perm.use_daylight_detector = false
	perm.use_dispenser = false
	perm.use_dropper = false
	perm.use_enchanting_table = false
	perm.use_door=false
	perm.use_fence_gate = false
	perm.use_furnace = false
	perm.use_grindstone = false
	perm.use_hopper = false
	perm.use_jukebox = false
	perm.use_loom = false
	perm.use_stonecutter = false
	perm.use_noteblock = false
	perm.use_shulker_box = false
	perm.use_smithing_table = false
	perm.use_smoker = false
	perm.use_trapdoor = false
	perm.use_lectern = false
	perm.use_cauldron = false
	perm.use_lever=false
	perm.use_button=false
	perm.use_respawn_anchor=false
	perm.use_item_frame=false
	perm.use_fishing_hook=false
	perm.use_bucket=false
	perm.use_pressure_plate=false
	perm.allow_throw_potion=false
	perm.allow_ride_entity=false
	perm.allow_ride_trans=false
	perm.allow_shoot=false

	-- Write data
	if land_owners[xuid]==nil then -- ilapi
		land_owners[xuid]={}
	end

	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	ILAPI.save()
	updateChunk(landId,'add')
	updateVecMap(landId,'add')
	updateLandOwnersMap(landId)
	updateLandTrustMap(landId)
	return landId
end
function ILAPI.DeleteLand(landId)
	if land_data[landId]==nil then
		return false
	end

	local owner=ILAPI.GetOwner(landId)
	if owner~='?' then
		table.remove(land_owners[owner],AIR.isValInList(land_owners[owner],landId))
	end
	updateChunk(landId,'del')
	updateVecMap(landId,'del')
	land_data[landId]=nil
	ILAPI.save()
	return true
end
function ILAPI.GetLand(landId)
	if land_data[landId]==nil then
		return ''
	end
	return AIR.deepcopy(land_data[landId])
end
function ILAPI.UpdatePermission(landId,perm,value)
	if land_data[landId]==nil or land_data[landId].permissions[perm]==nil or (value~=true and value~=false) then
		return false
	end
	land_data[landId].permissions[perm]=value
	ILAPI.save()
	return true
end
function ILAPI.UpdateSetting(landId,cfgname,value)
	if land_data[landId]==nil or land_data[landId].settings[cfgname]==nil or value==nil then
		return false
	end
	land_data[landId].settings[cfgname]=value
	ILAPI.save()
	return true
end
function ILAPI.GetPlayerLands(xuid)
	return AIR.deepcopy(land_owners[xuid])
end
function ILAPI.GetNickname(landId,returnIdIfNameEmpty)
	local n = land_data[landId].settings.nickname
	if n=='' then
		n='<'.._tr('gui.landmgr.unnamed')..'>'
		if returnIdIfNameEmpty then
			n=n..' '..landId
		end
	end
	return n
end
function ILAPI.GetDescribe(landId)
	return AIR.deepcopy(land_data[landId].settings.describe)
end
function ILAPI.GetOwner(landId)
	for i,v in pairs(land_owners) do
		if AIR.isValInList(v,landId)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI.PosGetLand(vec4)
	local Cx,Cz = pos2chunk(vec4)
	local dimid = vec4.dimid
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		for n,landId in pairs(ChunkMap[dimid][Cx][Cz]) do
			if dimid==land_data[landId].range.dimid and isPosInCube(vec4,VecMap[landId].a,VecMap[landId].b) then
				return landId
			end
		end
	end
	return -1
end
function ILAPI.GetChunk(vec2,dimid)
	local Cx,Cz = pos2chunk(vec2)
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		return AIR.deepcopy(ChunkMap[dimid][Cx][Cz])
	end
	return -1
end
function ILAPI.GetTpPoint(landId) --return vec4
	local i = AIR.deepcopy(land_data[landId].settings.tpoint)
	i[4] = land_data[landId].range.dimid
	return AIR.pos2vec(i)
end
function ILAPI.GetDistence(landId,vec4)
	-- 设计思路：先索引XZ，再判Y
	--[[
	function DoPT(a,b)
	
	end

	local pos = formatPlayerPos(vec4)
	if ILAPI.PosGetLand(pos)==landId then
		return 0
	end
	
	local edges = cubeGetEdge_2D(VecMap[landId].a,VecMap[landId].b)
	]]
	
	if true then -- // 未完成 //
		return 0
	end
	-- local edges = cubeGetEdge_2D({x=,y=,z=},{x=,y=,z=})
	local sameXZ = {}

	local ops_posx = 0-pos.z -- 考虑相反数
	local ops_posz = 0-poz.z
	for n,ep in pairs(edges) do
		if ep.x==pos.x or ep.x==ops_posx or ep.z==pos.z or ep.z==ops_posz then
			sameXZ[#sameXZ+1]=ep
			if #sameXZ==2 then
				break
			end
		end
	end -- 筛出2个符合要求的坐标

	for i,v in pairs(sameXZ) do
		print(v.x,v.y,v.z)
	end
	
end
function ILAPI.IsPlayerTrusted(landId,xuid)
	if LandTrustedMap[landId][xuid]==nil then
		return false
	else
		return true
	end
end
function ILAPI.IsLandOwner(landId,xuid)
	if LandOwnersMap[landId]==xuid then
		return true
	else
		return false
	end
end
function ILAPI.IsLandOperator(xuid)
	if LandOperatorsMap[xuid]==nil then
		return false
	else
		return true
	end
end
function ILAPI.GetLandDimension(landId)
	if land_data[landId].range.start_position[2]==0 and land_data[landId].range.end_position[2]==255 then
		return '2D'
	else
		return '3D'
	end
end
function ILAPI.GetAllTrustedLand(xuid)
	local trusted = {}
	for landId,data in pairs(land_data) do
		if ILAPI.IsPlayerTrusted(landId,xuid) then
			trusted[#trusted+1]=landId
		end
	end
	return trusted
end
function ILAPI.GetVersion()
	return langVer
end
function ILAPI.save()
	file.writeTo(data_path..'config.json',json.encode(cfg,{indent=true}))
	file.writeTo(data_path..'data.json',json.encode(land_data))
	file.writeTo(data_path..'owners.json',json.encode(land_owners,{indent=true}))
end
function ILAPI.CanControl(mode,name)
	-- mode [0]UseItem [1]onBlockInteracted [2]items [3]attack
	if CanCtlMap[mode][name]==nil then
		return false
	else
		return true
	end
end

-- feature function
function GetAllPlayerList() -- all player namelist
	local r = {}
	for xuid,lds in pairs(land_owners) do
		r[#r+1]=GetIdFromXuid(xuid)
	end
	return r
end
function GetOnlinePlayerList()
	local r = {}
	for xuid,lds in pairs(TRS_Form) do
		r[#r+1]=GetIdFromXuid(xuid)
	end
	return r
end
function _tr(a)
	if DEV_MODE and i18n_data[a]==nil then
		ERROR('Translation not found: '..a)
	end
	return i18n_data[a]
end
function money_add(player,value)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		player:addScore(M.scoreboard_objname,value);return
	end
	if M.protocol=='llmoney' then
		money.add(player.xuid,value);return
	end
	ERROR(AIR.gsubEx(_tr('console.error.money.protocol'),'<a>',M.protocol))
end
function money_del(player,value)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		player:setScore(M.scoreboard_objname,player:getScore(M.scoreboard_objname)-value)
		return
	end
	if M.protocol=='llmoney' then
		money.reduce(player.xuid,value)
		return
	end
	ERROR(AIR.gsubEx(_tr('console.error.money.protocol'),'<a>',M.protocol))
end
function money_get(player)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		return player:getScore(M.scoreboard_objname)
	end
	if M.protocol=='llmoney' then
		return money.get(player.xuid)
	end
	ERROR(AIR.gsubEx(_tr('console.error.money.protocol'),'<a>',M.protocol))
end
function sendTitle(player,title,subtitle)
	local name = player.realName
	mc.runcmdEx('title "' .. name .. '" times 20 25 20')
	if subtitle~=nil then
	mc.runcmdEx('title "' .. name .. '" subtitle '..subtitle) end
	mc.runcmdEx('title "' .. name .. '" title '..title)
end
function sendText(player,text,mode)
	-- [mode] 0 = FORCE USE TALK
	if mode==nil and not(cfg.features.force_talk) then 
		player:sendText(text,5)
		return
	end
	if cfg.features.force_talk and mode~=0 then
		player:sendText('§l§b———————————§a LAND §b———————————\n§r'..text)
	end
	if mode==0 then
		player:sendText('§l§b[§a LAND §b] §r'..text)
		return
	end
end
function cubeGetEdge(spos,epos)
	local edge={}
	local posB,posA = fmCube(spos,epos)
	for i=1,math.abs(posA.x-posB.x)+1 do
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posB.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posB.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posB.y-1, z=posB.z }
	end
	for i=1,math.abs(posA.y-posB.y)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-i, z=posA.z }
		edge[#edge+1] = { x=posA.x, y=posA.y-i, z=posB.z }
		edge[#edge+1] = { x=posB.x, y=posA.y-i, z=posB.z }
		edge[#edge+1] = { x=posB.x, y=posA.y-i, z=posA.z }
	end
	for i=1,math.abs(posA.z-posB.z)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posA.x, y=posB.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posB.y-1, z=posA.z-i+1 }
	end
	return edge
end
function cubeGetEdge_2D(spos,epos)
	local edge={}
	local posB,posA = fmCube(spos,epos)
	for i=1,math.abs(posA.x-posB.x)+1 do
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posA.z }
		edge[#edge+1] = { x=posA.x-i+1, y=posA.y-1, z=posB.z }
	end
	for i=1,math.abs(posA.z-posB.z)+1 do
		edge[#edge+1] = { x=posA.x, y=posA.y-1, z=posA.z-i+1 }
		edge[#edge+1] = { x=posB.x, y=posA.y-1, z=posA.z-i+1 }
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
function calculation_price(length,width,height,dimension)
	local price=0
	if dimension=='3D' then
		local t=cfg.land_buy.price_3D
		if cfg.land_buy.calculation_3D == 'm-1' then
			price=length*width*t[1]+height*t[2]
		end
		if cfg.land_buy.calculation_3D == 'm-2' then
			price=length*width*height*t[1]
		end
		if cfg.land_buy.calculation_3D == 'm-3' then
			price=length*width*t[1]
		end
	end
	if dimension=='2D' then
		local t=cfg.land_buy.price_2D
		if cfg.land_buy.calculation_2D == 'd-1' then
			price=length*width*t[1]
		end
	end
	return math.modf(price*(cfg.money.discount/100))
end
function GetIdFromXuid(xuid)
	if data.xuid2name(xuid)~=nil then
		return data.xuid2name(xuid)
	else
		return xuid
	end
end
function GetXuidFromId(playerid)
	if data.name2xuid(playerid)~=nil then
		return data.name2xuid(playerid)
	else
		return playerid
	end
end
function pos2chunk(pos)
	local p = cfg.features.chunk_side
	return math.floor(pos.x/p),math.floor(pos.z/p)
end
function fmCube(posA,posB)
	local A = posA
	local B = posB
	if A.x>B.x then A.x,B.x = B.x,A.x end
	if A.y>B.y then A.y,B.y = B.y,A.y end
	if A.z>B.z then A.z,B.z = B.z,A.z end
	return A,B
end
function formatGuid(guid)
    return string.format('%s-%s-%s-%s-%s',
        string.sub(guid,1,8),
        string.sub(guid,9,12),
        string.sub(guid,13,16),
        string.sub(guid,17,20),
        string.sub(guid,21,32)
    )
end
function formatPlayerPos(pos)
	local p={}
	p.x=math.floor(pos.x)
	p.y=math.floor(pos.y)
	p.z=math.floor(pos.z)
	if pos.dimid~=nil then
		p.dimid=pos.dimid
	end
	return p
end
function did2dim(a)
	if a==0 then return _tr('talk.dim.zero') end
	if a==1 then return _tr('talk.dim.one') end
	if a==2 then return _tr('talk.dim.two') end
	return _tr('talk.dim.other')
end
function refreshBlock(player,pos)
	local s = pos.x..' '..pos.y..' '..pos.z
	mc.runcmdEx('execute "'..player.realName..'" ~ ~ ~ clone '..s..' '..s..' '..s)
end
function TraverseAABB(AAbb,aaBB,did)
	local posA,posB = fmCube(AAbb,aaBB)
	local result = {}
	for ix=posA.x,posB.x do
		for iy=posA.y,posB.y do
			for iz=posA.z,posB.z do
				result[#result+1] = {x=ix,y=iy,z=iz,dimid=did}
			end
		end
	end
	return result
end
function Upgrade(updata)

	INFO('AutoUpdate',_tr('console.autoupdate.start'))
	function recoverBackup(dt)
		INFO('AutoUpdate',_tr('console.autoupdate.recoverbackup'))
		for n,backupfilename in pairs(dt) do
			file.rename(backupfilename..'.bak',backupfilename)
		end
	end
	
	if updata.NumVer<=langVer then
		ERROR(AIR.gsubEx(_tr('console.autoupdate.alreadylatest'),'<a>',updata.NumVer..'<='..langVer))
		return
	end
	
	local RawPath = {}
	local BackupEd = {}
	local source = 'https://cdn.jsdelivr.net/gh/McAirLand/updates/files/'..updata.NumVer..'/'
	INFO('AutoUpdate',plugin_version..' => '..updata.Version)
	RawPath['$plugin_path'] = 'plugins\\'
	RawPath['$data_path'] = data_path
	

	for n,thefile in pairs(updata.FileChanged) do
		local raw = AIR.split(thefile,'::')
		local path = RawPath[raw[1]]..raw[2]
		INFO('Network',_tr('console.autoupdate.download')..raw[2])
		
		if file.exists(path) then -- create backup
			file.rename(path,path..'.bak')
			BackupEd[#BackupEd+1]=path
		end

		local tmp = network.httpGetSync(source..raw[2])
		if tmp.status~=200 then -- download check
			ERROR(
				AIR.gsubEx(
					_tr('console.autoupdate.errorbydown'),
					'<a>',raw[2],
					'<b>',tmp.status
				)
			)
			recoverBackup(BackupEd)
			return
		end

		if data.toSHA1(tmp.data)~=updata.SHA1[n] then -- SHA1 check
			ERROR(
				AIR.gsubEx(
					_tr('console.autoupdate.errorbysha1'),
					'<a>',raw[2]
				)
			)
			recoverBackup(BackupEd)
			return
		end

		file.writeTo(path,tmp.data)
	end

	INFO('AutoUpdate',_tr('console.autoupdate.success'))
end
function isNull(val)
	return (val == nil)
end
function isNullX2(val,val2)
	return (val == nil) or (val2 == nil)
end

-- log system
function INFO(type,content)
	if content==nil then
		print('[ILand] |INFO| '..type)
		return
	end
	print('[ILand] |'..type..'| '..content)
end
function ERROR(content)
	print('[ILand] |ERROR| '..content)
end

-- Minecraft -> Eventing
function Eventing_onJoin(player)
	local xuid = player.xuid
	TRS_Form[xuid] = { inland='null',inlandv2='null' }

	if land_owners[xuid]==nil then
		land_owners[xuid] = {}
		ILAPI.save()
	end

	if player.gameMode==1 then
		ERROR(AIR.gsubEx(_tr('talk.gametype.creative'),'<a>',player.realName))
	end
end
function Eventing_onPreJoin(player)
	if player.xuid=='' then -- no xuid
		player:kick(_tr('talk.prejoin.noxuid'))
	end
end
function Eventing_onLeft(player)

	if isNull(player) then
		return
	end

	local xuid = player.xuid
	TRS_Form[xuid]=nil
	ArrayParticles[xuid]=nil
	if newLand[xuid]~=nil then
		newLand[xuid]=nil
	end
end
function Eventing_onPlayerCmd(player,cmd)

	if isNull(player) then
		return
	end

	local opt = AIR.split(cmd,' ')
	if opt[1] ~= MainCmd then return end

	local xuid = player.xuid
	local pos = formatPlayerPos(player.pos)

	-- [ ] Main Command
	if opt[1] == MainCmd and opt[2]==nil then
		local landId = ILAPI.PosGetLand(pos)
		if landId~=-1 and ILAPI.GetOwner(landId)==xuid then
			TRS_Form[xuid].landId=landId
			GUI_FastMgr(player)
		else
			local land_count = tostring(#land_owners[xuid])
			local Form = mc.newSimpleForm()
			Form:setTitle(_tr('gui.fastgde.title'))
			Form:setContent(AIR.gsubEx(_tr('gui.fastgde.content'),'<a>',land_count))
			Form:addButton(_tr('gui.fastgde.create'),'textures/ui/icon_iron_pickaxe')
			Form:addButton(_tr('gui.fastgde.manage'),'textures/ui/confirm')
			Form:addButton(_tr('gui.general.close'),'textures/ui/icon_import')
			player:sendForm(Form,FORM_land_gde)
		end
		return false
	end

	-- [new] Create newLand
	if opt[2] == 'new' then
		if newLand[xuid]~=nil then
			sendText(player,_tr('title.getlicense.alreadyexists')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
			return false
		end
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			if #land_owners[xuid]>=cfg.land.player_max_lands then
				sendText(player,_tr('title.getlicense.limit'))
				return false
			end
		end
		player:sendModalForm(
			'DimChosen',
			_tr('gui.buyland.chosedim'),
			_tr('gui.buyland.3d'),
			_tr('gui.buyland.2d'),
			FORM_land_choseDim
		)
		return false
	end

	-- [a|b|buy] Select Range
	if opt[2] == 'a' or opt[2] == 'b' or opt[2] == 'buy' then
		if newLand[xuid]==nil then
			sendText(player,_tr('title.land.nolicense'))
			return false
		end
		if (opt[2]=='a' and newLand[xuid].step~=0) or (opt[2]=='b' and newLand[xuid].step~=1) or (opt[2]=='buy' and newLand[xuid].step~=2) then
			sendText(player,_tr('title.selectrange.failbystep'))
			return false
		end
		BoughtProg_SelectRange(player,pos,newLand[xuid].step)
		return false
	end

	-- [giveup] Give up incp land
	if opt[2] == 'giveup' then
		BoughtProg_GiveUp(player)
		return false
	end

	-- [gui] LandMgr GUI
	if opt[2] == 'gui' then
		TRS_Form[xuid].backpo = 0
		GUI_LMgr(player)
		return false
	end

	-- [point] Set land tp point
	if opt[2] == 'point' and cfg.features.landtp then
		local landId=ILAPI.PosGetLand(pos)
		if landId==-1 then
			sendText(player,_tr('title.landtp.fail.noland'))
			return false
		end
		if ILAPI.GetOwner(landId)~=xuid then
			sendText(player,_tr('title.landtp.fail.notowner'))
			return false
		end
		local landname = ILAPI.GetNickname(landId,true)
		land_data[landId].settings.tpoint = {
			pos.x,
			pos.y,
			pos.z
		}
		ILAPI.save()
		player:sendModalForm(
			_tr('gui.general.complete'),
			AIR.gsubEx(_tr('gui.landtp.point'),'<a>',AIR.vec2text(pos),'<b>',landname),
			_tr('gui.general.iknow'),
			_tr('gui.general.close'),
			FORM_NULL
		)
		return false
	end

	-- [tp] LandTp GUI
	if opt[2] == 'tp' and cfg.features.landtp then
		local tplands = { '['.._tr('gui.general.plzchose')..']' }
		for i,landId in pairs(ILAPI.GetPlayerLands(xuid)) do
			local name = ILAPI.GetNickname(landId,true)
			local xpos = land_data[landId].settings.tpoint
			tplands[i+1]='('..xpos[1]..','..xpos[2]..','..xpos[3]..') '..name
		end
		for i,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
			local name = ILAPI.GetNickname(landId,true)
			local xpos = land_data[landId].settings.tpoint
			tplands[#tplands+1]='§l'.._tr('gui.landtp.trusted')..' §r('..xpos[1]..','..xpos[2]..','..xpos[3]..') '..name
		end
		local Form = mc.newCustomForm()
		Form:setTitle(_tr('gui.landtp.title'))
		Form:addLabel(_tr('gui.landtp.tip'))
		Form:addDropdown(_tr('gui.landtp.tip2'),tplands)
		player:sendForm(Form,FORM_landtp)
		return false
	end

	-- [mgr] OP-LandMgr GUI
	if opt[2] == 'mgr' then
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			sendText(player,AIR.gsubEx(_tr('command.land_mgr.noperm'),'<a>',xuid),0)
			return false
		end
		GUI_OPLMgr(player)
		return false
	end

	-- [mgr selectool] Set land_select tool
	if opt[2] == 'mgr' and opt[3] == 'selectool' then
		if AIR.isValInList(cfg.manager.operator,xuid)==-1 then
			sendText(player,AIR.gsubEx(_tr('command.land_mgr.noperm'),'<a>',xuid),0)
			return false
		end
		sendText(player,_tr('title.oplandmgr.setselectool'))
		TRS_Form[xuid].selectool=0
		return false
	end

	-- [X] Unknown key
	sendText(player,AIR.gsubEx(_tr('command.error'),'<a>',opt[2]),0)
	return false

end
function Eventing_onConsoleCmd(cmd)

	-- INFO('Debug','call event -> onConsoleCmd')

	local opt = AIR.split(cmd,' ')
	if opt[1] ~= MainCmd then return end

	-- [ ] main cmd.
	if opt[2] == nil then
		INFO('The server is running iLand v'..plugin_version)
		INFO('Github: https://github.com/McAirLand/iLand-Core')
		return false
	end

	-- [op] add land operator.
	if opt[2] == 'op' then
		if AIR.isValInList(cfg.manager.operator,opt[3])==-1 then
			if not(AIR.isNumber(opt[3])) then
				ERROR('Wrong xuid!');return false
			end
			table.insert(cfg.manager.operator,#cfg.manager.operator+1,opt[3])
			updateLandOperatorsMap()
			ILAPI.save()
			INFO('Xuid: '..opt[3]..' has been added to the LandMgr list.')
		else
			INFO('Xuid: '..opt[3]..' is already in LandMgr list.')
		end
		return false
	end

	-- [deop] add land operator.
	if opt[2] == 'deop' then
		local p = AIR.isValInList(cfg.manager.operator,opt[3])
		if p~=-1 then
			if not(AIR.isNumber(opt[3])) then
				ERROR('Wrong xuid!');return false
			end
			table.remove(cfg.manager.operator,p)
			updateLandOperatorsMap()
			ILAPI.save()
			INFO('Xuid: '..opt[3]..' has been removed from LandMgr list.')
		else
			INFO('Xuid: '..opt[3]..' is not in LandMgr list.')
		end
		return false
	end

	-- [update] Upgrade iLand
	if opt[2] == 'update' then
		local raw = network.httpGetSync('https://cdisk.amd.rocks/tmp/ILAND/server.json')
		if raw.status==200 then
			local v1 = json.decode(raw.data)
			if v1.FILE_Version==200 then
				Upgrade(v1.Updates[1])
			else
				ERROR(AIR.gsubEx(_tr('console.getonline.failbyver'),'<a>',v1.FILE_Version))
			end
		else
			ERROR(AIR.gsubEx(_tr('console.getonline.failbycode'),'<a>',raw.status))
		end
		return false
	end

	-- [test] Performance Testing
	if opt[2] == 'test' then
		INFO("Starting performance test, please wait...")
		local testTimes = 1000000
		local vec4 = {x=11451,y=419,z=19810,dimid=0}
		local startTime = os.time()
		for i=1,testTimes do
			ILAPI.PosGetLand(vec4[i])
		end
		local endTime = os.time()
		local costTime = endTime-startTime
		INFO('TEST','==================================')
		INFO('TEST','Server Lands: '..#land_data)
		INFO('TEST','Start time: '..startTime)
		INFO('TEST','End time: '..endTime)
		INFO('TEST','Query times: '..testTimes)
		INFO('TEST','Time cost: '..tostring(costTime))
		INFO('TEST','Average time used per time: '..tostring((costTime)/testTimes))
		INFO('TEST','==================================')
		return false
	end

	-- [X] Unknown key
	ERROR('Unknown parameter: "'..opt[2]..'", plugin wiki: https://git.io/JcvIw')
	return false

end
function Eventing_onDestroyBlock(player,block)

	if isNull(player) then
		return
	end

	local xuid=player.xuid

	if TRS_Form[xuid].selectool==0 then
		local HandItem = player:getHand()
		if HandItem.isNull(HandItem) then goto PROCESS_1 end --fix crash
		sendText(player,AIR.gsubEx(_tr('title.oplandmgr.setsuccess'),'<a>',HandItem.name))
		cfg.features.selection_tool=HandItem.type
		ILAPI.save()
		TRS_Form[xuid].selectool=-1
		return false
	end

	:: PROCESS_1 ::
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	if land_data[landId].permissions.allow_destroy then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onStartDestroyBlock(player,block)
	
	if isNull(player) then
		return
	end

	local xuid = player.xuid
	
	if newLand[xuid]~=nil then
		local HandItem = player:getHand()
		if HandItem:isNull() or HandItem.type~=cfg.features.selection_tool then return end
		BoughtProg_SelectRange(player,block.pos,newLand[xuid].step)
	end

end
function Eventing_onPlaceBlock(player,block)

	if isNull(player) then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_place then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onUseItemOn(player,item,block)

	if isNull(player) then
		return
	end

	local IsConPlus=false
	if not(ILAPI.CanControl(0,block.type)) then 
		if not(ILAPI.CanControl(2,item.type)) then
			return
		else
			IsConPlus=true
		end
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	local perm = land_data[landId].permissions
	if IsConPlus then
		local it = item.type
		if string.sub(it,-6,-1) == 'bucket' and perm.use_bucket then return end -- 各种桶
		if it == 'minecraft:glow_ink_sac' and perm.allow_place then return end -- 发光墨囊给木牌上色（拓充）
		if it == 'minecraft:end_crystal' and perm.allow_place then return end -- 末地水晶（拓充）
		if it == 'minecraft:ender_eye' and perm.allow_place then return end -- 放置末影之眼（拓充）
	else
		local bn = block.type
		if string.sub(bn,-6,-1) == 'button' and perm.use_button then return end -- 各种按钮
		if bn == 'minecraft:bed' and perm.use_bed then return end -- 床
		if (bn == 'minecraft:chest' or bn == 'minecraft:trapped_chest') and perm.allow_open_chest then return end -- 箱子&陷阱箱
		if bn == 'minecraft:crafting_table' and perm.use_crafting_table then return end -- 工作台
		if (bn == 'minecraft:campfire' or bn == 'minecraft:soul_campfire') and perm.use_campfire then return end -- 营火（烧烤）
		if bn == 'minecraft:composter' and perm.use_composter then return end -- 堆肥桶（放置肥料）
		if (bn == 'minecraft:undyed_shulker_box' or bn == 'minecraft:shulker_box') and perm.use_shulker_box then return end -- 潜匿箱
		if bn == 'minecraft:noteblock' and perm.use_noteblock then return end -- 音符盒（调音）
		if bn == 'minecraft:jukebox' and perm.use_jukebox then return end -- 唱片机（放置/取出唱片）
		if bn == 'minecraft:bell' and perm.use_bell then return end -- 钟（敲钟）
		if (bn == 'minecraft:daylight_detector_inverted' or bn == 'minecraft:daylight_detector') and perm.use_daylight_detector then return end -- 光线传感器（切换日夜模式）
		if bn == 'minecraft:lectern' and perm.use_lectern then return end -- 讲台
		if bn == 'minecraft:cauldron' and perm.use_cauldron then return end -- 炼药锅
		if bn == 'minecraft:lever' and perm.use_lever then return end -- 拉杆
		if bn == 'minecraft:respawn_anchor' and perm.use_respawn_anchor then return end -- 重生锚（充能）
	end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onAttack(player,entity)
	
	if isNullX2(player,entity) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(entity.pos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	local perm=land_data[landId].permissions
	local en=entity.type
	local IsConPlus = false
	if ILAPI.CanControl(3,en) then IsConPlus=true end
	if IsConPlus then
		if en == 'minecraft:ender_crystal' and perm.allow_destroy then return end -- 末地水晶（拓充）
		if en == 'minecraft:armor_stand' and perm.allow_destroy then return end -- 盔甲架（拓充）
	else
		if perm.allow_attack then return end -- Perm Allow
	end
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onTakeItem(player,entity)

	if isNullX2(player,entity) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(entity.pos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_pickupitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onDropItem(player,item)

	if isNull(player) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(player.pos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_dropitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onBlockInteracted(player,block)

	if isNull(player) then
		return
	end

	if not(ILAPI.CanControl(1,block.type)) then return end
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	local perm = land_data[landId].permissions
	local bn = block.type
	if string.sub(bn,-4,-1) == 'door' and perm.use_door then return end -- 各种门
	if string.sub(bn,-10,-1) == 'fence_gate' and perm.use_fence_gate then return end -- 各种栏栅门
	if string.sub(bn,-8,-1) == 'trapdoor' and perm.use_trapdoor then return end -- 各种活板门
	if bn == 'minecraft:cartography_table' and perm.use_cartography_table then return end -- 制图台
	if bn == 'minecraft:smithing_table' and perm.use_smithing_table then return end -- 锻造台
	if bn == 'minecraft:furnace' and perm.use_furnace then return end -- 熔炉
	if bn == 'minecraft:blast_furnace' and perm.use_blast_furnace then return end -- 高炉
	if bn == 'minecraft:smoker' and perm.use_smoker then return end -- 烟熏炉
	if bn == 'minecraft:brewing_stand' and perm.use_brewing_stand then return end -- 酿造台
	if bn == 'minecraft:anvil' and perm.use_anvil then return end -- 铁砧
	if bn == 'minecraft:grindstone' and perm.use_grindstone then return end -- 磨石
	if bn == 'minecraft:enchanting_table' and perm.use_enchanting_table then return end -- 附魔台
	if bn == 'minecraft:barrel' and perm.use_barrel then return end -- 桶
	if bn == 'minecraft:beacon' and perm.use_beacon then return end -- 信标
	if bn == 'minecraft:hopper' and perm.use_hopper then return end -- 漏斗
	if bn == 'minecraft:dropper' and perm.use_dropper then return end -- 投掷器
	if bn == 'minecraft:dispenser' and perm.use_dispenser then return end -- 发射器
	if bn == 'minecraft:loom' and perm.use_loom then return end -- 织布机
	if bn == 'minecraft:stonecutter_block' and perm.use_stonecutter then return end -- 切石机
	
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onUseFrameBlock(player,block)
		
	if isNull(player) then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.use_item_frame then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onSpawnProjectile(splasher,type)
			
	if isNull(splasher) then
		return
	end

	if splasher:toPlayer()==nil then return end
	local landId=ILAPI.PosGetLand(formatPlayerPos(splasher.pos))
	if landId==-1 then return end -- No Land

	local player=splasher:toPlayer()
	local xuid=player.xuid
	local perm=land_data[landId].permissions

	if type == 'minecraft:fishing_hook' and perm.use_fishing_hook then return end -- 钓鱼竿
	if type == 'minecraft:splash_potion' and perm.allow_throw_potion then return end -- 喷溅药水
	if type == 'minecraft:lingering_potion' and perm.allow_throw_potion then return end -- 滞留药水
	if type == 'minecraft:thrown_trident' and perm.allow_shoot then return end -- 三叉戟
	if type == 'minecraft:arrow' and perm.allow_shoot then return end -- 弓&弩（箭）
	if type == 'minecraft:snowball' and perm.allow_dropitem then return end -- 雪球
	if type == 'minecraft:ender_pearl' and perm.allow_dropitem then return end -- 末影珍珠
	if type == 'minecraft:egg' and perm.allow_dropitem then return end -- 鸡蛋

	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onFireworkShootWithCrossbow(player)
			
	if isNull(player) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(player.pos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_shoot then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onStepOnPressurePlate(entity,block)
				
	if isNull(entity) then
		return
	end

	local ispl=false
	local player
	if entity:toPlayer()~=nil then
		ispl=true
		player=entity:toPlayer()
	end

	if entity.pos==nil then -- what a silly mojang?
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(entity.pos))
	if landId==-1 then return end -- No Land
	
	if land_data[landId].permissions.use_pressure_plate then return end -- Perm Allow
	if ispl then
		local xuid=player.xuid
		if ILAPI.IsLandOperator(xuid) then return end
		if ILAPI.IsLandOwner(landId,xuid) then return end
		if ILAPI.IsPlayerTrusted(landId,xuid) then return end
		sendText(player,_tr('title.landlimit.noperm'))
	end
	return false
end
function Eventing_onRide(rider,entity)
				
	if isNullX2(rider,entity) then
		return
	end

	if rider:toPlayer()==nil then return end

	local landId=ILAPI.PosGetLand(formatPlayerPos(rider.pos))
	if landId==-1 then return end -- No Land 

	local player=rider:toPlayer()
	local xuid=player.xuid
	local en=entity.type
	if en=='minecraft:minecart' or en=='minecraft:boat' then
		if land_data[landId].permissions.allow_ride_trans then return end
	else
		if land_data[landId].permissions.allow_ride_entity then return end
	end

	 -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onWitherBossDestroy(witherBoss,AAbb,aaBB)
	local dimid = witherBoss.pos.dimid
	for n,pos in pairs(TraverseAABB(AAbb,aaBB,dimid)) do
		landId=ILAPI.PosGetLand(pos)
		if landId~=-1 and not(land_data[landId].permissions.allow_destroy) then 
			break
		end
	end
	return false
end
function Eventing_onExplode(entity,pos)

	if isNull(entity) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(entity.pos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end
function Eventing_onFarmLandDecay(pos,entity)
	
	if isNull(entity) then
		return
	end

	local landId=ILAPI.PosGetLand(formatPlayerPos(entity.pos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_farmland_decay then return end -- EV Allow
	return false
end
function Eventing_onPistonPush(pos,block)
	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_piston_push then return end -- Perm Allow
	return false
end
function Eventing_onFireSpread(pos)
	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_fire_spread then return end -- Perm Allow
	return false
end

-- Lua -> Timer Callback
function Tcb_LandSign()
	for xuid,data in pairs(TRS_Form) do
		local player=mc.getPlayer(xuid)
		
		if isNullX2(player,player.pos) then
			goto JUMPOUT_SIGN
		end

		local xuid = player.xuid
		local landId=ILAPI.PosGetLand(formatPlayerPos(player.pos))
		if landId==-1 then TRS_Form[xuid].inland='null';goto JUMPOUT_SIGN end -- no land here
		if landId==TRS_Form[xuid].inland then goto JUMPOUT_SIGN end -- signed

		local owner=ILAPI.GetOwner(landId)
		local ownername='?'
		if owner~='?' then ownername=GetIdFromXuid(owner) end
		
		if xuid==owner then 
			-- land owner in land.
			if not(land_data[landId].settings.signtome) then
				goto JUMPOUT_SIGN
			end
			sendTitle(player,AIR.gsubEx(
				_tr('sign.listener.ownertitle'),
				'<a>',ILAPI.GetNickname(landId,false)
			),
			_tr('sign.listener.ownersubtitle'))
		else  
			-- visitor in land
			if not(land_data[landId].settings.signtother) then
				goto JUMPOUT_SIGN
			end
			sendTitle(player,_tr('sign.listener.visitortitle'),AIR.gsubEx(
				_tr('sign.listener.visitorsubtitle'),
				'<a>',ownername
			))
			if land_data[landId].settings.describe~='' then
				sendText(player,AIR.gsubEx(
					land_data[landId].settings.describe,
					'$visitor',player.realName,
					'$n','\n'
				),0)
			end
		end
		TRS_Form[xuid].inland=landId
		:: JUMPOUT_SIGN ::
	end
end
function Tcb_ButtomSign()
	for xuid,data in pairs(TRS_Form) do
		local player=mc.getPlayer(xuid)

		if isNullX2(player,player.pos) then
			goto JUMPOUT_BUTTOM
		end

		local landId = ILAPI.PosGetLand(formatPlayerPos(player.pos))
		if landId==-1 then
			goto JUMPOUT_BUTTOM
		end

		local ownerXuid = ILAPI.GetOwner(landId)
		local landcfg = land_data[landId].settings
		if (xuid==ownerXuid) and landcfg.signtome and landcfg.signbuttom then
			player:sendText(AIR.gsubEx(_tr('title.landsign.ownenrbuttom'),'<a>',ILAPI.GetNickname(landId)),4)
		end
		if (xuid~=ownerXuid) and landcfg.signtother and landcfg.signbuttom then
			player:sendText(AIR.gsubEx(_tr('title.landsign.visitorbuttom'),'<a>',GetIdFromXuid(ownerXuid)),4)
		end

		:: JUMPOUT_BUTTOM ::
	end
end
function Tcb_SelectionParticles()
	for xuid,posarr in pairs(ArrayParticles) do
		for n,pos in pairs(posarr) do
			mc.runcmdEx('execute @a[name="'..GetIdFromXuid(xuid)..'"] ~ ~ ~ particle "'..cfg.features.particle_effects..'" '..pos.x..' '..tostring(pos.y+1.6)..' '..pos.z)
		end
	end
end

-- listen events,
mc.listen('onPlayerCmd',Eventing_onPlayerCmd)
mc.listen('onConsoleCmd',Eventing_onConsoleCmd)
mc.listen('onJoin',Eventing_onJoin)
mc.listen('onPreJoin',Eventing_onPreJoin)
mc.listen('onLeft',Eventing_onLeft)
mc.listen('onDestroyBlock',Eventing_onDestroyBlock)
mc.listen('onPlaceBlock',Eventing_onPlaceBlock)
mc.listen('onUseItemOn',Eventing_onUseItemOn)
mc.listen('onAttack',Eventing_onAttack)
mc.listen('onExplode',Eventing_onExplode)
mc.listen('onTakeItem',Eventing_onTakeItem)
mc.listen('onDropItem',Eventing_onDropItem)
mc.listen('onBlockInteracted',Eventing_onBlockInteracted)
mc.listen('onUseFrameBlock',Eventing_onUseFrameBlock)
mc.listen('onSpawnProjectile',Eventing_onSpawnProjectile)
mc.listen('onFireworkShootWithCrossbow',Eventing_onFireworkShootWithCrossbow)
mc.listen('onStepOnPressurePlate',Eventing_onStepOnPressurePlate)
mc.listen('onRide',Eventing_onRide)
mc.listen('onWitherBossDestroy',Eventing_onWitherBossDestroy)
mc.listen('onFarmLandDecay',Eventing_onFarmLandDecay)
mc.listen('onPistonPush',Eventing_onPistonPush)
mc.listen('onFireSpread',Eventing_onFireSpread)
mc.listen('onStartDestroyBlock',Eventing_onStartDestroyBlock)

-- timer -> landsign|particles|debugger
function enableLandSign()
	CLOCK_LANDSIGN = setInterval(Tcb_LandSign,cfg.features.sign_frequency*1000)
	BUTTOM_SIGN = setInterval(Tcb_ButtomSign,cfg.features.sign_frequency*500)
end
function enableParticles()
	CLOCK_PARTICLES = setInterval(Tcb_SelectionParticles,2*1000)
end
function DEBUG_LANDQUERY()
	if debug_landquery==nil then return end
	local pos = formatPlayerPos(debug_landquery.pos)
	local landId=ILAPI.PosGetLand(pos)
	local N = ILAPI.GetChunk(pos,pos.dimid)
	local Cx,Cz = pos2chunk(pos)
	INFO('Debug','[plPos] x='..pos.x..' y='..pos.y..' z='..pos.z)
	INFO('Debug','[Query] '..landId)
	if N==-1 then
		INFO('Debug','[Chunk] not found')
	else
		for i,v in pairs(N) do
			INFO('Debug','[Chunk] ('..Cx..','..Cz..') '..i..' '..v)
		end
	end
end

-- check update
function Ncb_online(code,result)
	if code==200 then
		local data=json.decode(result)

		-- Check File Version
		if data.FILE_Version~=200 then
			INFO('Network',AIR.gsubEx(_tr('console.getonline.failbyver'),'<a>',data.FILE_Version))
			return
		end

		-- Read Announcement
		Global_LatestVersion = data.Updates[1].Version
		Global_IsAnnouncementEnabled = data.Announcement.enabled
		Global_Announcement = ''

		if data.Announcement.enabled then
			for n,text in pairs(data.Announcement.content) do
				Global_Announcement = Global_Announcement..text..' | '
				INFO('Announcement',text)
			end
		end

		-- Do Analysis
		if data.Analysis.enabled then
			local analink = AIR.gsubEx(
				data.Analysis.link,
				'{version}',langVer,
				'{players}',#land_owners
			)
			network.httpGet(analink,function(stat,con)end)
		end

		-- Check Update
		if langVer<data.Updates[1].NumVer then
			INFO('Network',AIR.gsubEx(_tr('console.update.newversion'),'<a>',data.Updates[1].Version))
			INFO('Update',_tr('console.update.newcontent'))
			for n,text in pairs(data.Updates[1].Description) do
				INFO('Update',n..'. '..text)
			end
			if data.Force_Update then
				INFO('Update',_tr('console.update.force'))
				Upgrade(data.Updates[1])
			end
			if cfg.features.auto_update then
				INFO('Update',_tr('console.update.auto'))
				Upgrade(data.Updates[1])
			end
		end
		if langVer>data.Updates[1].NumVer then
			INFO('Network',AIR.gsubEx(_tr('console.update.preview'),'<a>',plugin_version))
		end
	else
		ERROR(AIR.gsubEx(_tr('console.getonline.failbycode'),'<a>',code))
	end
end

mc.listen('onServerStarted',function()
	function throwErr(x)
		if x==-1 then
			ERROR('Configure file not found, plugin is closing...')
		end
		if x==-2 then
			ERROR('LiteXLoader too old, please use latest version, here ↓')
		end
		if x==-3 then
			ERROR('AirLibs too old, please use latest version, here ↓')
		end
		if x==-2 or x==-3 then
			ERROR('https://www.minebbs.com/')
			ERROR('Plugin closing...')
		end
		if x==-4 then
			ERROR('Language file does not match version, plugin is closing... (!='..langVer..')')
		end
		mc.runcmd('stop')
	end

	-- Check file
	if not(file.exists(data_path..'config.json')) then
		throwErr(-1)
	end
	if not(file.exists(data_path..'data.json')) then
		file.writeTo(data_path..'data.json','{}')
	end
	if not(file.exists(data_path..'owners.json')) then
		file.writeTo(data_path..'owners.json','{}')
	end
	
	-- Check depends version
	if not(lxl.checkVersion(minLXLVer[1],minLXLVer[2],minLXLVer[3])) then
		throwErr(-2)
	end
	if AIR.VERSION < minAirVer then
		throwErr(-3)
	end

	-- Load data file
	cfg = json.decode(file.readFrom(data_path..'config.json'))
	land_data = json.decode(file.readFrom(data_path..'data.json'))
	land_owners = json.decode(file.readFrom(data_path..'owners.json'))

	-- Configure Updater
	do
		if cfg.version==nil or cfg.version<114 then
			ERROR('Configure file too old, you must rebuild it.')
			return
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
			cfg.version=200
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
			cfg.features.force_talk = false
			cfg.features.player_max_ple = 600
			ILAPI.save()
		end
		if cfg.version==200 then
			cfg.version=210
			cfg.money.credit_name='Gold-Coins'
			cfg.money.discount=100
			cfg.features.land_2D=true
			cfg.features.land_3D=true
			cfg.features.auto_update=true
			for landId,data in pairs(land_data) do
				land_data[landId].range.dimid = AIR.deepcopy(land_data[landId].range.dim)
				land_data[landId].range.dim=nil
				for n,xuid in pairs(land_data[landId].settings.share) do
					if type(xuid)~='string' then
						land_data[landId].settings.share[n]=tostring(land_data[landId].settings.share[n])
					end
				end
			end
			ILAPI.save()
		end
		if cfg.version==210 then
			cfg.version=211
			local landbuy=cfg.land_buy
			landbuy.calculation_3D='m-1'
			landbuy.calculation_2D='d-1'
			landbuy.price_3D={20,4}
			landbuy.price_2D={35}
			landbuy.price=nil
			landbuy.calculation=nil
			ILAPI.save()
		end
		if cfg.version==211 then
			cfg.version=220
			cfg.features.offlinePlayerInList=true
			for landId,data in pairs(land_data) do
				local perm=land_data[landId].permissions
				perm.use_lever=false
				perm.use_button=false
				perm.use_respawn_anchor=false
				perm.use_item_frame=false
				perm.use_fishing_hook=false
				perm.use_pressure_plate=false
				perm.allow_throw_potion=false
				perm.allow_ride_entity=false
				perm.allow_ride_trans=false
				perm.allow_shoot=false
				local settings=land_data[landId].settings
				settings.ev_explode=AIR.deepcopy(perm.allow_exploding)
				settings.ev_farmland_decay=false
				settings.ev_piston_push=false
				settings.ev_fire_spread=false
				settings.signbuttom=true
				perm.use_door=false
				perm.use_stonecutter=false
				perm.allow_exploding=nil
			end
			ILAPI.save()
		end
		if cfg.version==220 or cfg.version==221 then
			cfg.version=223
			for landId,data in pairs(land_data) do
				perm = land_data[landId].permissions
				if #perm~=46 then
					INFO('AutoRepair','Land <'..landId..'> Has wrong perm cfg, resetting...')
					perm.allow_destroy=false
					perm.allow_place=false
					perm.allow_attack=false
					perm.allow_open_chest=false
					perm.allow_pickupitem=false
					perm.allow_dropitem=false
					perm.use_anvil = false
					perm.use_barrel = false
					perm.use_beacon = false
					perm.use_bed = false
					perm.use_bell = false
					perm.use_blast_furnace = false
					perm.use_brewing_stand = false
					perm.use_campfire = false
					perm.use_cartography_table = false
					perm.use_composter = false
					perm.use_crafting_table = false
					perm.use_daylight_detector = false
					perm.use_dispenser = false
					perm.use_dropper = false
					perm.use_enchanting_table = false
					perm.use_door=false
					perm.use_fence_gate = false
					perm.use_furnace = false
					perm.use_grindstone = false
					perm.use_hopper = false
					perm.use_jukebox = false
					perm.use_loom = false
					perm.use_stonecutter = false
					perm.use_noteblock = false
					perm.use_shulker_box = false
					perm.use_smithing_table = false
					perm.use_smoker = false
					perm.use_trapdoor = false
					perm.use_lectern = false
					perm.use_cauldron = false
					perm.use_lever=false
					perm.use_button=false
					perm.use_respawn_anchor=false
					perm.use_item_frame=false
					perm.use_fishing_hook=false
					perm.use_pressure_plate=false
					perm.allow_throw_potion=false
					perm.allow_ride_entity=false
					perm.allow_ride_trans=false
					perm.allow_shoot=false
				end
			end
			ILAPI.save()
		end
		if cfg.version==223 then
			cfg.version=224
			for landId,data in pairs(land_data) do
				land_data[landId].permissions.use_bucket=false
			end
			ILAPI.save()
		end
	end
	
	-- Load&Check i18n file
	i18n_data = json.decode(file.readFrom(data_path..'lang\\'..cfg.manager.default_language..'.json'))
	if i18n_data.VERSION ~= langVer then
		throwErr(-4)
	end
	-- Build maps
	buildChunks()
	buildVecMap()
	buildLTOPMap()

	-- Make timer
	if cfg.features.landSign then
		enableLandSign()
	end
	if cfg.features.particles then
		enableParticles()
	end

	-- Check Update
	if cfg.update_check then
		network.httpGet('https://cdisk.amd.rocks/tmp/ILAND/server.json',Ncb_online)
	end

	-- register cmd.
	mc.regPlayerCmd(MainCmd,_tr('command.land'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' new',_tr('command.land_new'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' giveup',_tr('command.land_giveup'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' gui',_tr('command.land_gui'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' a',_tr('command.land_a'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' b',_tr('command.land_b'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' buy',_tr('command.land_buy'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' mgr',_tr('command.land_mgr'),function(pl,args)end)
	mc.regPlayerCmd(MainCmd..' mgr selectool',_tr('command.land_mgr_selectool'),function(pl,args)end)
	if cfg.features.landtp then
		mc.regPlayerCmd(MainCmd..' tp',_tr('command.land_tp'),function(pl,args)end)
		mc.regPlayerCmd(MainCmd..' point',_tr('command.land_point'),function(pl,args)end)
	end
	mc.regConsoleCmd(MainCmd,_tr('command.console.land'),function(args)end)
	mc.regConsoleCmd(MainCmd..' op',_tr('command.console.land_op'),function(args)end)
	mc.regConsoleCmd(MainCmd..' deop',_tr('command.console.land_deop'),function(args)end)
	mc.regConsoleCmd(MainCmd..' test',_tr('command.console.land_test'),function(args)end)
	mc.regConsoleCmd(MainCmd..' update',_tr('command.console.land_update'),function(args)end)
end)

-- export function
lxl.export(ILAPI.CreateLand,'ILAPI_CreateLand')
lxl.export(ILAPI.DeleteLand,'ILAPI_DeleteLand')
lxl.export(ILAPI.GetPlayerLands,'ILAPI_GetPlayerLands')
lxl.export(ILAPI.GetNickname,'ILAPI_GetNickname')
lxl.export(ILAPI.GetDescribe,'ILAPI_GetDescribe')
lxl.export(ILAPI.GetOwner,'ILAPI_GetOwner')
lxl.export(ILAPI.PosGetLand,'ILAPI_PosGetLand')
lxl.export(ILAPI.GetChunk,'ILAPI_GetChunk')
lxl.export(ILAPI.GetTpPoint,'ILAPI_GetTpPoint')
lxl.export(ILAPI.GetDistence,'ILAPI_GetDistence')
lxl.export(ILAPI.IsPlayerTrusted,'ILAPI_IsPlayerTrusted')
lxl.export(ILAPI.IsLandOwner,'ILAPI_IsLandOwner')
lxl.export(ILAPI.IsLandOperator,'ILAPI_IsLandOperator')
lxl.export(ILAPI.GetAllTrustedLand,'ILAPI_GetAllTrustedLand')
lxl.export(ILAPI.GetVersion,'ILAPI_GetVersion')
lxl.export(ILAPI.GetLandDimension,'ILAPI_GetLandDimension')
lxl.export(ILAPI.GetLand,'ILAPI_GetLand')
lxl.export(ILAPI.UpdatePermission,'ILAPI_UpdatePermission')
lxl.export(ILAPI.UpdateSetting,'ILAPI_UpdateSetting')
lxl.export(Eventing_onDestroyBlock,'ILENV_onDestroyBlock')

INFO('Powerful land plugin is loaded! Ver-'..plugin_version..',')
INFO('By: RedbeanW, License: GPLv3 with additional conditions.')