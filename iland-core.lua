-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteXLoader            ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '2.10'
local langVer = 210
local minAirVer = 200
local minLXLVer = 100
local data_path = 'plugins\\iland\\'
local newLand={};local TRS_Form={};local ArrayParticles={};ILAPI={}
local MainCmd = 'land'
local debug_mode = false
local json = require('dkjson')
local AIR = require('airLibs')

-- check file
if file.exists(data_path..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- check depends version
if AIR.VERSION < minAirVer then
	print('[ILand] ERR!! AirLibs too old, please use latest version, here ↓')
	print('[ILand] ERR!! https://www.minebbs.com/')
	print('[ILand] ERR!! Plugin closing...')
	return
end
function chklxlver()
	local b = lxl.version
	local nV = b.major*100+b.minor*10+b.build
	if nV<minLXLVer then
		return -1
	end
end
if chklxlver=-1 then
	print('[ILand] ERR!! LiteXLoader too old, please use latest version, here ↓')
	print('[ILand] ERR!! https://www.minebbs.com/')
	print('[ILand] ERR!! Plugin closing...')
	return
end

-- load data file
local cfg = json.decode(file.readFrom(data_path..'config.json'))
land_data = json.decode(file.readFrom(data_path..'data.json'))
land_owners = json.decode(file.readFrom(data_path..'owners.json'))

-- preload function
function ILAPI.save()
	file.writeTo(data_path..'config.json',json.encode(cfg,{indent=true}))
	file.writeTo(data_path..'data.json',json.encode(land_data))
	file.writeTo(data_path..'owners.json',json.encode(land_owners,{indent=true}))
end
function pos2chunk(pos)
	local p = cfg.features.chunk_side
	return math.floor(pos.x/p),math.floor(pos.z/p)
end
function fmCube(posA,posB)
	if posA.x>posB.x then posA.x,posB.x = posB.x,posA.x end
	if posA.y>posB.y then posA.y,posB.y = posB.y,posA.y end
	if posA.z>posB.z then posA.z,posB.z = posB.z,posA.z end
	return A,B
end

-- cfg -> updater
do
	if cfg.version==nil or cfg.version<114 then
		print('[ILand] Configure file too old, you must rebuild it.')
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
end

-- load language file
local i18n_data = json.decode(file.readFrom(data_path..'lang\\'..cfg.manager.default_language..'.json'))
if i18n_data.VERSION ~= langVer then
	print('[ILand] ERR!! Language file does not match version, plugin is closing... (!='..langVer..')')
	return
end

-- load chunks
function updateChunk(landId,mode)
	local TxTz={}
	local dim = land_data[landId].range.dim
	function txz(x,z)
		if TxTz[x] == nil then TxTz[x] = {} end
		if TxTz[x][z] == nil then TxTz[x][z] = {} end
	end
	function chkmap(d,x,z)
		if ChunkMap[dim][x] == nil then ChunkMap[dim][x] = {} end
		if ChunkMap[dim][x][z] == nil then ChunkMap[dim][x][z] = {} end
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
				chkmap(dim,Tx,Tz)
				if AIR.isValInList(ChunkMap[dim][Tx][Tz],landId) == -1 then
					table.insert(ChunkMap[dim][Tx][Tz],#ChunkMap[dim][Tx][Tz]+1,landId)
				end
			end
			if mode=='del' then
				local p = AIR.isValInList(ChunkMap[dim][Tx][Tz],landId)
				if p~=-1 then
					table.remove(ChunkMap[dim][Tx][Tz],p)
				end
			end
		end
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
buildChunks()

-- load land VecMap
local VecMap={}
function updateVecMap(landId,mode)
	if mode=='add' then
		local spos = land_data[landId].range.start_position
		local epos = land_data[landId].range.end_position
		VecMap[landId]={}
		VecMap[landId].a={};VecMap[landId].b={}
		VecMap[landId].a = AIR.buildVec(spos[1],spos[2],spos[3]) --start
		VecMap[landId].b = AIR.buildVec(epos[1],epos[2],epos[3]) --end
	end
	if mode=='del' then
		VecMap[landId]=nil
	end
end
function buildVecMap()
	VecMap={}
	for landId,data in pairs(land_data) do
		updateVecMap(landId,'add')
	end
end
buildVecMap()

-- form -> callback
function FORM_NULL(a,b) end
function FORM_BACK_LandOPMgr(player,id)
	if index==1 then return end
	GUI_OPLMgr(player)
end
function FORM_BACK_LandMgr(player,id)
	if index==1 then return end
	if TRS_From[xuid].backpo==1 then
		GUI_FastMgr(player)
		return
	end
	GUI_LMgr(player)
end
function FORM_land_buy(player,id)
	if index~=0 then 
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
	local A=newLand[xuid].posA
	local B=newLand[xuid].posB
	local result={fmCube(A,B)}
	ILAPI.CreateLand(xuid,result[1],result[2],newLand[xuid].dim)
	newLand[xuid]=nil
	player.sendModalForm(
		'Complete.',
		_tr('gui.buyland.succeed'),
		_tr('gui.general.looklook'),
		_tr('gui.general.cancel'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_cfg(player,data)

	local landId = TRS_From[xuid].landId
	land_data[landId].settings.signtome=AIR.toBool(raw[3])
	land_data[landId].settings.signtother=AIR.toBool(raw[4])
	ILAPI.save()

	player.sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_perm(player,data)
	
	local perm = land_data[TRS_From[xuid].landId].permissions

	perm.allow_place = AIR.toBool(data[3])
	perm.allow_destroy = AIR.toBool(data[4])
	perm.allow_dropitem = AIR.toBool(data[5])
	perm.allow_pickupitem = AIR.toBool(data[6])
	perm.allow_attack = AIR.toBool(data[7])

	perm.use_crafting_table = AIR.toBool(data[9])
	perm.use_furnace = AIR.toBool(data[10])
	perm.use_blast_furnace = AIR.toBool(data[11])
	perm.use_smoker = AIR.toBool(data[12])
	perm.use_brewing_stand = AIR.toBool(data[13])
	perm.use_cauldron = AIR.toBool(data[14])
	perm.use_anvil = AIR.toBool(data[15])
	perm.use_grindstone = AIR.toBool(data[16])
	perm.use_enchanting_table = AIR.toBool(data[17])
	perm.use_cartography_table = AIR.toBool(data[18])
	perm.use_smithing_table = AIR.toBool(data[19])
	perm.use_loom = AIR.toBool(data[20])
	perm.use_beacon = AIR.toBool(data[21])

	perm.use_barrel = AIR.toBool(data[23])
	perm.use_hopper = AIR.toBool(data[24])
	perm.use_dropper = AIR.toBool(data[25])
	perm.use_dispenser = AIR.toBool(data[26])
	perm.use_shulker_box = AIR.toBool(data[27])
	perm.use_chest = AIR.toBool(data[28])

	perm.use_campfire = AIR.toBool(data[30])
	perm.use_trapdoor = AIR.toBool(data[31])
	perm.use_fence_gate = AIR.toBool(data[32])
	perm.use_bell = AIR.toBool(data[33])
	perm.use_jukebox = AIR.toBool(data[34])
	perm.use_noteblock = AIR.toBool(data[35])
	perm.use_composter = AIR.toBool(data[36])
	perm.use_bed = AIR.toBool(data[37])
	perm.use_daylight_detector = AIR.toBool(data[38])

	perm.allow_exploding = AIR.toBool(data[40])

	ILAPI.save()
	player.sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_trust(player,data)
	local landId = TRS_From[xuid].landId
	local landshare = land_data[landId].settings.share
	-- [1]null [2]1(true) [3]0 [4]0(false) [5]0
	if data[2]==1 then
		if data[3]==0 then return end
		local x=GetXuidFromId(TRS_From[xuid].playerList[data[3]+1])
		local n=#landshare+1
		if player.xuid==x then
			sendText(player,_tr('title.landtrust.cantaddown'));return
		end
		if AIR.isValInList(landshare,x)~=-1 then
			sendText(player,_tr('title.landtrust.alreadyexists'));return
		end
		landshare[n]=x
		ILAPI.save()
		if data[4]~=1 then 
			player.sendModalForm(
				_tr('gui.general.complete'),
				'Complete.',
				_tr('gui.general.back'),
				_tr('gui.general.close'),
				FORM_BACK_LandMgr
			)
		end
	end
	if data[4]==1 then
		if data[5]==0 then return end
		local x=GetXuidFromId(TRS_From[xuid].playerList[data[5]+1])
		table.remove(landshare,AIR.isValInList(landshare,x))
		ILAPI.save()
		player.sendModalForm(
			_tr('gui.general.complete'),
			'Complete.',
			_tr('gui.general.back'),
			_tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
	end
end
function FORM_land_gui_name(player,data)
	local landId=TRS_From[xuid].landId
	if AIR.isTextSpecial(data[2]) then
		sendText(player,'FAILED');return
	end
	land_data[landId].settings.nickname=data[2]
	ILAPI.save()
	player.sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_describe(player,data)
	local landId=TRS_From[xuid].landId
	if AIR.isTextSpecial(AIR.gsubEx(data[2],
							'$','Y', -- allow some spec.
							',','Y',
							'.','Y',
							'!','Y'
						)) then
		sendText(player,'FAILED');return
	end
	land_data[landId].settings.describe=data[2]
	ILAPI.save()
	player.sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_transfer(player,data)
	if data[2]==0 then return end
	local xuid=player.xuid
	local landId=TRS_From[xuid].landId
	local go=GetXuidFromId(TRS_From[xuid].playerList[raw[2]+1])
	if go==xuid then sendText(player,_tr('title.landtransfer.canttoown'));return end
	table.remove(land_owners[xuid],AIR.isValInList(land_owners[xuid],landId))
	table.insert(land_owners[go],#land_owners[go]+1,landId)
	ILAPI.save()
	player.sendModalForm(
		_tr('gui.general.complete'),
		AIR.gsubEx(_tr('title.landtransfer.complete'),'<a>',ILAPI.GetNickname(landId,true),'<b>',GetIdFromXuid(go)),
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui_delete(player,id)
	if id==1 then return end
	local landId=TRS_From[xuid].landId
	ILAPI.DeleteLand(landId)
	money_add(player,TRS_From[xuid].landvalue)
	player.sendModalForm(
		_tr('gui.general.complete'),
		'Complete.',
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function FORM_land_gui(player,data,lid)
	local xuid=player.xuid

	local landId
	if lid==nil or lid=='' then
		landId = land_owners[xuid][raw[2]+1]
	else
		landId = lid
	end

	TRS_From[xuid].landId=landId
	if raw[3]==0 then --查看领地信息
		local length = math.abs(land_data[landId].range.start_position[1] - land_data[landId].range.end_position[1]) + 1 
		local width = math.abs(land_data[landId].range.start_position[3] - land_data[landId].range.end_position[3]) + 1
		local height = math.abs(land_data[landId].range.start_position[2] - land_data[landId].range.end_position[2]) + 1
		local vol = length * width * height
		local squ = length * width
		local nname=ILAPI.GetNickname(landId,false)
		player.sendModalForm(
			_tr('gui.landmgr.landinfo.title'),
			AIR.gsubEx(_tr('gui.landmgr.landinfo.content'),
					'<a>',Actor:getName(player),
					'<m>',landId,
					'<n>',nname,
					'<b>',land_data[landId].range.start_position[1],
					'<c>',land_data[landId].range.start_position[2],
					'<d>',land_data[landId].range.start_position[3],
					'<e>',land_data[landId].range.end_position[1],
					'<f>',land_data[landId].range.end_position[2],
					'<g>',land_data[landId].range.end_position[3],
					'<h>',length,'<i>',width,'<j>',height,
					'<k>',squ,'<l>',vol),
			_tr('gui.general.iknow'),
			_tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
	end
	if raw[3]==1 then --编辑领地选项
		local isclosed=''
		if not(cfg.features.landSign) then
			isclosed=' ('.._tr('talk.features.closed')..')'
		end
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landcfg.title'))
		Form.addLabel(_tr('gui.landcfg.tip'))
		Form.addLabel(_tr('gui.landcfg.landsign')..isclosed)
		Form.addSwitch(_tr('gui.landcfg.landsign.tome'),land_data[landId].settings.signtome)
		Form.addSwitch(_tr('gui.landcfg.landsign.tother'),land_data[landId].settings.signtother)
		player.sendForm(Form,FORM_land_gui_cfg)
		return
	end
	if raw[3]==2 then --编辑领地权限
		local perm = land_data[landId].permissions
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landmgr.landperm.title'))
		Form.addLabel(_tr('gui.landmgr.landperm.options.title'))
		Form.addLabel(_tr('gui.landmgr.landperm.basic_options'))
		Form.addSwitch(_tr('gui.landmgr.landperm.basic_options.place'),perm.allow_place)
		Form.addSwitch(_tr('gui.landmgr.landperm.basic_options.destroy'),perm.allow_destroy)
		Form.addSwitch(_tr('gui.landmgr.landperm.basic_options.dropitem'),perm.allow_dropitem)
		Form.addSwitch(_tr('gui.landmgr.landperm.basic_options.pickupitem'),perm.allow_pickupitem)
		Form.addSwitch(_tr('gui.landmgr.landperm.basic_options.attack'),perm.allow_attack)
		Form.addLabel(_tr('gui.landmgr.landperm.funcblock_options'))
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.crafting_table'),perm.use_crafting_table)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.furnace'),perm.use_furnace)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.blast_furnace'),perm.use_blast_furnace)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.smoker'),perm.use_smoker)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.brewing_stand'),perm.use_brewing_stand)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.cauldron'),perm.use_cauldron)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.anvil'),perm.use_anvil)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.grindstone'),perm.use_grindstone)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.enchanting_table'),perm.use_enchanting_table)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.cartography_table'),perm.use_cartography_table)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.smithing_table'),perm.use_smithing_table)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.loom'),perm.use_loom)
		Form.addSwitch(_tr('gui.landmgr.landperm.funcblock_options.beacon'),perm.use_beacon)
		Form.addLabel(_tr('gui.landmgr.landperm.contblock_options'))
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.barrel'),perm.use_barrel)
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.hopper'),perm.use_hopper)
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.dropper'),perm.use_dropper)
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.dispenser'),perm.use_dispenser)
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.shulker_box'),perm.use_shulker_box)
		Form.addSwitch(_tr('gui.landmgr.landperm.contblock_options.chest'),perm.use_chest)
		Form.addLabel(_tr('gui.landmgr.landperm.other_options'))
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.campfire'),perm.use_campfire)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.trapdoor'),perm.use_trapdoor)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.fence_gate'),perm.use_fence_gate)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.bell'),perm.use_bell)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.jukebox'),perm.use_jukebox)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.noteblock'),perm.use_noteblock)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.composter'),perm.use_composter)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.bed'),perm.use_bed)
		Form.addSwitch(_tr('gui.landmgr.landperm.other_options.daylight_detector'),perm.use_daylight_detector)
		Form.addLabel(_tr('gui.landmgr.landperm.editevent'))
		Form.addSwitch(_tr('gui.landmgr.landperm.options.exploding'),perm.allow_exploding)
		player.sendForm(Form,FORM_land_gui_perm)
	end
	if raw[3]==3 then --编辑信任名单
		TRS_From[xuid].playerList = GetOnlinePlayerList()
		local d=AIR.shacopy(land_data[landId].settings.share)
		for i, v in pairs(d) do
			d[i]=GetIdFromXuid(d[i])
		end
		table.insert(d,1,'['.._tr('gui.general.plzchose')..']')
		table.insert(TRS_From[xuid].playerList,1,'['.._tr('gui.general.plzchose')..']')
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landtrust.title'))
		Form.addLabel(_tr('gui.landtrust.tip'))
		Form.addSwitch(_tr('gui.landtrust.addtrust'),false)
		Form.addDropdown(_tr('gui.landtrust.selectplayer'),TRS_From[xuid].playerList)
		Form.addSwitch(_tr('gui.landtrust.rmtrust'),false)
		From.addDropdown(_tr('gui.landtrust.selectplayer'),d)
		player.sendForm(Form,FORM_land_gui_trust)
		return
	end
	if raw[3]==4 then --领地nickname
		local nickn=ILAPI.GetNickname(landId,false)
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landtag.title'))
		Form.addLabel(_tr('gui.landtag.tip'))
		Form.addInput("",nickn)
		player.sendForm(Form,FORM_land_gui_name)
		return
	end
	if raw[3]==5 then --领地describe
		local desc=ILAPI.GetDescribe(landId)
		if desc=='' then desc='['.._tr('gui.landmgr.unmodified')..']' end
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landdescribe.title'))
		Form.addLabel(_tr('gui.landdescribe.tip'))
		Form.addInput("",desc)
		player.sendForm(Form,FORM_land_gui_describe)
		return
	end
	if raw[3]==6 then --领地过户
		TRS_From[xuid].playerList = GetOnlinePlayerList()
		table.insert(TRS_From[xuid].playerList,1,'['.._tr('gui.general.plzchose')..']')
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landtransfer.title'))
		Form.addLabel(_tr('gui.landtransfer.tip'))
		Form.addDropdown(_tr('talk.land.selecttargetplayer'),TRS_From[xuid].playerList)
		player.sendForm(Form,FORM_land_gui_transfer)
		return
	end
	if raw[3]==7 then --删除领地
		local height = math.abs(land_data[landId].range.start_position[2] - land_data[landId].range.end_position[2]) + 1
		local length = math.abs(land_data[landId].range.start_position[1] - land_data[landId].range.end_position[1]) + 1
		local width = math.abs(land_data[landId].range.start_position[3] - land_data[landId].range.end_position[3]) + 1
		TRS_From[xuid].landvalue=math.modf(calculation_price(length,width,height)*cfg.land_buy.refund_rate)
		player.sendModalForm(
			_tr('gui.delland.title'),
			AIR.gsubEx(_tr('gui.delland.content'),'<a>',TRS_From[xuid].landvalue,'<b>',_tr('talk.credit_name')),
			_tr('gui.general.yes'),
			_tr('gui.general.cancel'),
			FORM_land_gui_delete
		);return
	end
end
function FORM_land_mgr_transfer(player,data)
	local xuid = player.xuid
	if raw[2]==0 then return end
	local landId=TRS_From[xuid].targetland
	local afrom=ILAPI.GetOwner(landId)
	if afrom=='?' then return end
	local go=GetXuidFromId(TRS_From[xuid].playerList[raw[2]+1])
	if go==afrom then return end
	table.remove(land_owners[afrom],AIR.isValInList(land_owners[afrom],landId))
	table.insert(land_owners[go],#land_owners[go]+1,landId)
	ILAPI.save()
	player.sendModalForm(
		_tr('gui.general.complete'),
		AIR.gsubEx(_tr('title.landtransfer.complete'),'<a>',landId,'<b>',GetIdFromXuid(go)),
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandOPMgr
	)
end
function FORM_land_mgr(player,data)

	if data[8]~='' then
		cfg.land.player_max_lands = tonumber(data[8])
	end
	if data[9]~='' then
		cfg.land.land_max_square = tonumber(data[9])
	end
	if data[10]~='' then
		cfg.land.land_min_square = tonumber(data[10])
	end
	cfg.land_buy.refund_rate = data[11]/100
	if data[13]==1 then
		cfg.money.protocol=='scoreboard'
	else
		cfg.money.protocol=='llmoney'
	end
	if data[14]~='' then
		cfg.money.scoreboard_objname=data[14]
	end
	if data[16]~='' then
		cfg.manager.default_language=data[16]
	end
	cfg.features.landSign = data[18]
	cfg.features.particles = data[19]
	cfg.features.force_talk = data[20]
	cfg.update_check = data[21]
	if data[22]~='' then
		cfg.features.selection_tool_name=data[22]
	end
	if data[23]~='' then
		cfg.features.sign_frequency=tonumber(data[23])
	end
	if data[24]~='' then
		cfg.features.chunk_side=tonumber(data[24])
	end
	if data[25]~='' then
		cfg.features.player_max_ple=tonumber(data[25])
	end

	ILAPI.save()
	
	-- do rt

	if cfg.features.landSign and CLOCK_LANDSIGN==nil then
		enableLandSign()
	end
	if not(cfg.features.landSign) and CLOCK_LANDSIGN~=nil then
		clearInterval(CLOCK_LANDSIGN)
		CLOCK_LANDSIGN=nil
	end
	if cfg.features.particles and CLOCK_PARTICLES==nil then
		enableParticles()
	end
	if not(cfg.features.particles) and CLOCK_PARTICLES~=nil then
		clearInterval(CLOCK_PARTICLES)
		CLOCK_PARTICLES=nil
	end
	
	-- lands manager

	if data[5]==0 then player.sendModalForm(_tr('gui.general.complete'),"Complete.",_tr('gui.general.back'),_tr('gui.general.close'),FORM_BACK_LandOPMgr);return end
	local count=0;local landId=-1
	for i,v in pairs(land_data) do
		count=count+1
		if count==data[5] then landId=i;break end
	end
	if landId==-1 then return end
	if data[6]==1 then -- tp to land.
		player.teleport(AIR.buildVec(land_data[landId].settings.tpoint[1],land_data[landId].settings.tpoint[2],land_data[landId].settings.tpoint[3],land_data[landId].range.dim))
	end
	if data[6]==2 then -- transfer land.
		local xuid = player.xuid
		TRS_From[xuid].playerList = GetOnlinePlayerList()
		TRS_From[xuid].targetland=landId
		table.insert(TRS_From[xuid].playerList,1,'['.._tr('gui.general.plzchose')..']')
		ILAPI.save()
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.oplandmgr.trsland.title'))
		Form.addLabel(_tr('gui.oplandmgr.trsland.content'))
		Form.addDropdown(_tr('talk.land.selecttargetplayer'),TRS_From[xuid].playerList)
		player.sendForm(Form,FORM_land_mgr_transfer)
		return
	end
	if data[6]==3 then -- delete land.
		ILAPI.DeleteLand(landId)
	end

	player.sendModalForm(
		_tr('gui.general.complete'),
		"Complete.",
		_tr('gui.general.back'),
		_tr('gui.general.close'),
		FORM_BACK_LandOPMgr
	)
end
function FORM_landtp(player,data)
	if data[2]==0 then return end
	local lands = ILAPI.GetPlayerLands(player.xuid)
	local landId = lands[data[2]]
	local tp = land_data[landId].settings.tpoint
	local dim = land_data[landId].range.dim
	local safey = GetTopAir(tp[1],tp[2],tp[3],dim)
	player.teleport(AIR.buildVec(tp[1],safey,tp[3],dim))
	local ct = 'Complete.'
	if safey~=tp[2] then
		ct = AIR.gsubEx(_tr('gui.landtp.safetp'),'<a>',tostring(safey-tp[2]))
	end
	player.sendModalForm(
		_tr('gui.general.complete'),
		ct,
		_tr('gui.general.yes'),
		_tr('gui.general.close'),
		FORM_NULL
	)
end
function FORM_land_fast(player,id)
	TRS_From[xuid].backpo = 1
	fakeraw = {}
	fakeraw[3] = index
	if index~=8 then
		FORM_land_gui(player,fakeraw,TRS_From[xuid].landId)
	end
end
function FORM_land_gde(player,id)
	if id==0 then
		Eventing_onPlayerCmd(player,'land new')
	end
	if id==1 then
		Eventing_onPlayerCmd(player,'land gui')
	end
end
function BoughtProg_SelectRange(player,vec4,mode)
    if newLand[xuid]==nil then return end
    if mode==0 then -- point a
        if mode~=newLand[xuid].step then
			sendText(player,_tr('title.selectrange.failbystep'));return
        end
		local newland = newLand[xuid]
		newland.dim = vec4.dim
		newland.posA = vec4
		newland.posA.x=math.modf(newland.posA.x) --省函数...
		newland.posA.y=math.modf(newland.posA.y)
		newland.posA.z=math.modf(newland.posA.z)
        sendText(player,AIR.gsubEx(_tr('title.selectrange.seled'),
									'<a>','a',
									'<b>',did2dim(vec4.dim),
									'<c>',newland.posA.x,
									'<d>',newland.posA.y,
									'<e>',newland.posA.z)
									..'\n'..string.gsub(_tr('title.selectrange.spointb'),'<a>',cfg.features.selection_tool_name))
		newland.step = 1
    end
    if mode==1 then -- point b
        if vec4.dim~=newLand[xuid].dim then
			sendText(player,_tr('title.selectrange.failbycdim'));return
        end
		local newland = newLand[xuid]
		newland.posB = vec4
		newland.posB.x=math.modf(newland.posB.x)
		newland.posB.y=math.modf(newland.posB.y)
		newland.posB.z=math.modf(newland.posB.z)
        sendText(player,AIR.gsubEx(_tr('title.selectrange.seled'),
									'<a>','b',
									'<b>',did2dim(vec4.dim),
									'<c>',newland.posB.x,
									'<d>',newland.posB.y,
									'<e>',newland.posB.z)
									..'\n'..string.gsub(_tr('title.selectrange.bebuy'),'<a>',cfg.features.selection_tool_name))
		newland.step = 2

		local edges = cubeGetEdge(newland.posA,newland.posB)
		-- print(#edges)
		if #edges>cfg.features.player_max_ple then
			sendText(player,_tr('title.selectrange.nople'),0)
		else
			ArrayParticles[player]={}
			ArrayParticles[player]=edges
		end
    end
	if mode==2 then
		BoughtProg_CreateOrder(player)
	end
end
function BoughtProg_CreateOrder(player)
	ArrayParticles[player]=nil
	local xuid = player.xuid
    if newLand[xuid]==nil or newLand[xuid].step~=2 then
		sendText(player,_tr('title.createorder.failbystep'))
        return
    end
    local length = math.abs(newLand[xuid].posA.x - newLand[xuid].posB.x) + 1
    local width = math.abs(newLand[xuid].posA.z - newLand[xuid].posB.z) + 1
    local height = math.abs(newLand[xuid].posA.y - newLand[xuid].posB.y) + 1
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if squ>cfg.land.land_max_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		sendText(player,_tr('title.createorder.toobig')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		newLand[xuid].step=0
		return
	end
	if squ<cfg.land.land_min_square and AIR.isValInList(cfg.manager.operator,xuid)==-1 then
		sendText(player,_tr('title.createorder.toosmall')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		newLand[xuid].step=0
		return
	end
	if height<2 then
		sendText(player,_tr('title.createorder.toolow')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		newLand[xuid].step=0
		return
	end
	--- 领地冲突判断
	local edge=cubeGetEdge(newLand[xuid].posA,newLand[xuid].posB)
	for i=1,#edge do
		edge[i].dim=newLand[xuid].dim
		local tryLand = ILAPI.PosGetLand(edge[i])
		if tryLand ~= -1 then
			sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',tryLand,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
			newLand[xuid].step=0;return
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dim==newLand[xuid].dim then
			edge=cubeGetEdge(VecMap[landId].a,VecMap[landId].b)
			for i=1,#edge do
				if isPosInCube(edge[i],newLand[xuid].posA,newLand[xuid].posB)==true then
					sendText(player,AIR.gsubEx(_tr('title.createorder.collision'),'<a>',landId,'<b>',AIR.vec2text(edge[i]))..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
					newLand[xuid].step=0;return
				end
			end
		end
	end
	--- 购买
    newLand[xuid].landprice = calculation_price(length,width,height)

	player.sendModalForm(
		_tr('gui.buyland.title'),
		AIR.gsubEx(_tr('gui.buyland.content'),'<a>',length,'<b>',width,'<c>',height,'<d>',vol,'<e>',newLand[xuid].landprice,'<f>',_tr('talk.credit_name'),'<g>',money_get(player)),
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
	ArrayParticles[player]=nil
	sendText(player,_tr('title.giveup.succeed'))
end
function GUI_LMgr(player)
	local xuid=player.xuid
	if #land_owners[xuid]==0 then
		sendText(player,_tr('title.landmgr.failed'));return
	end

	local welcomeText=_tr('gui.landmgr.content')
	local lid=ILAPI.PosGetLand(player.pos)
	local nname
	if lid~=-1 then
		nname = ILAPI.GetNickname(lid,true)
		welcomeText = welcomeText..AIR.gsubEx(_tr('gui.landmgr.ctplus'),'<a>',nname)
	else
		nname = lid
	end

	local features={_tr('gui.landmgr.options.landinfo'),_tr('gui.landmgr.options.landcfg'),_tr('gui.landmgr.options.landperm'),_tr('gui.landmgr.options.landtrust'),_tr('gui.landmgr.options.landtag'),_tr('gui.landmgr.options.landdescribe'),_tr('gui.landmgr.options.landtransfer'),_tr('gui.landmgr.options.delland')}
	local lands={}
	for i,v in pairs(land_owners[xuid]) do
		local f=ILAPI.GetNickname(v,true)
		lands[i]=f
	end

	local Form = mc.newForm()
	Form.setTitle(_tr('gui.landmgr.title'))
	Form.addLabel(welcomeText)
	Form.addDropdown(_tr('gui.landmgr.select'),lands)
	Form.addStepSlider(_tr('gui.oplandmgr.selectoption'),features)

	player.sendSimpleForm(Form,FORM_land_gui)
end
function GUI_OPLMgr(player)
	local landlst={}
	local lid=ILAPI.PosGetLand(player.pos)
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
	local money_protocols = {'LLMoney',_tr('talk.scoreboard')}

	local Form = mc.newForm()
	Form.setTitle(_tr('gui.oplandmgr.title'))
	Form.addLabel(_tr('gui.oplandmgr.tip'))
	Form.addLabel(AIR.gsubEx(_tr('gui.oplandmgr.plugin'),'<a>',langVer))
	Form.addLabel(
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.ver'),'<a>',plugin_version)..'\\n'..
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.latest'),'<a>',latestVer)..'\\n'..
		AIR.gsubEx(_tr('gui.oplandmgr.plugin.acement'),'<a>',iAnn)
	)
	Form.addLabel(_tr('gui.oplandmgr.landmgr'))
	Form.addDropdown(_tr('gui.oplandmgr.selectland'),landlst)
	Form.addStepSlider(_tr('gui.oplandmgr.selectoption'),features)
	Form.addLabel(_tr('gui.oplandmgr.landcfg'))
	Form.addInput(_tr('gui.oplandmgr.landcfg.maxland'),cfg.land.player_max_lands)
	Form.addInput(_tr('gui.oplandmgr.landcfg.maxsqu'),cfg.land.land_max_square)
	Form.addInput(_tr('gui.oplandmgr.landcfg.minsqu'),cfg.land.land_min_square)
	Form.addSlider(_tr('gui.oplandmgr.landcfg.refundrate'),0,100,1,tostring(cfg.land_buy.refund_rate*10))
	Form.addLabel(_tr('gui.oplandmgr.economy'))
	Form.addDropdown(_tr('gui.oplandmgr.economy.protocol'),money_protocols)
	Form.addInput(_tr('gui.oplandmgr.economy.sbname'),cfg.money.scoreboard_objname)
	Form.addLabel(_tr('gui.oplandmgr.i18n'))
	Form.addInput(_tr('gui.oplandmgr.i18n.default'),cfg.manager.default_language)
	Form.addLabel(_tr('gui.oplandmgr.features'))
	Form.addSwitch(_tr('gui.oplandmgr.features.landsign'),cfg.features.landSign)
	Form.addSwitch(_tr('gui.oplandmgr.features.particles'),cfg.features.particles)
	Form.addSwitch(_tr('gui.oplandmgr.features.forcetalk'),cfg.features.force_talk)
	Form.addSwitch(_tr('gui.oplandmgr.features.autochkupd'),cfg.update_check)
	Form.addInput(_tr('gui.oplandmgr.features.seltolname'),cfg.features.selection_tool_name)
	Form.addInput(_tr('gui.oplandmgr.features.frequency'),cfg.features.sign_frequency)
	Form.addInput(_tr('gui.oplandmgr.features.chunksize'),cfg.features.chunk_side)
	Form.addInput(_tr('gui.oplandmgr.features.maxple'),cfg.features.player_max_ple))

	player.sendForm(Form,FORM_land_mgr)						
end
function GUI_FastMgr(player)
	local landId = TRS_From[player.xuid].landId
	local buttons={
		_tr('gui.landmgr.options.landinfo'),
		_tr('gui.landmgr.options.landcfg'),
		_tr('gui.landmgr.options.landperm'),
		_tr('gui.landmgr.options.landtrust'),
		_tr('gui.landmgr.options.landtag'),
		_tr('gui.landmgr.options.landdescribe'),
		_tr('gui.landmgr.options.landtransfer'),
		_tr('gui.landmgr.options.delland'),
		_tr('gui.general.close')
	}
	local images={}
	images[9] = 'textures/ui/icon_import'
	player.sendSimpleForm(
		_tr('gui.fastlmgr.title'),
		AIR.gsubEx(_tr('gui.fastlmgr.content'),'<a>',ILAPI.GetNickname(landId,true)),
		buttons,
		images,
		FORM_land_fast
	)
end

-- ILAPI
function ILAPI.CreateLand(xuid,startpos,endpos,dimensionid)
	local landId
	while true do
		landId=system.randomGuid()
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
	return land_owners[xuid]
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
	return land_data[landId].settings.describe
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
	local dim = vec4.dim
	if ChunkMap[dim][Cx]~=nil and ChunkMap[dim][Cx][Cz]~=nil then
		for n,landId in pairs(ChunkMap[dim][Cx][Cz]) do
			if vec4.dim==land_data[landId].range.dim and isPosInCube(vec4,VecMap[landId].a,VecMap[landId].b) then
				return landId
			end
		end
	end
	return -1
end
function ILAPI.GetChunk(vec2,dim)
	local Cx,Cz = pos2chunk(vec2)
	if ChunkMap[dim][Cx]~=nil and ChunkMap[dim][Cx][Cz]~=nil then
		return ChunkMap[dim][Cx][Cz]
	end
	return -1
end
function ILAPI.GetTpPoint(landId) --return vec4
	local i = AIR.deepcopy(land_data[landId].settings.tpoint)
	i[4] = land_data[landId].range.dim
	return AIR.pos2vec(i)
end
function ILAPI.GetDistence(landId)
	-- pwt..
end
function ILAPI.GetVersion()
	return plugin_version
end

-- feature function
function GetOnlinePlayerList() -- player namelist
	local b={}
	for num,player in pairs(mc.getOnlinePlayers()) do
		b[#b+1] = player.realName
	end
	return b
end
function _tr(a)
	return i18n_data[a]
end
function money_add(player,value)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		player.addScore(M.scoreboard_objname,value);return
	end
	if M.protocol=='llmoney' then
		money.add(player.xuid,value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..M.protocol..'\' !')
end
function money_del(player,value)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		player.setScore(M.scoreboard_objname,player.getScore(M.scoreboard_objname)-value)
	end
	if M.protocol=='llmoney' then
		money.reduce(player.xuid,value);return
	end
	print('[ILand] ERR!! Unknown money protocol \''..M.protocol..'\' !')
end
function money_get(player)
	local M = cfg.money
	if M.protocol=='scoreboard' then
		return player.getScore(M.scoreboard_objname)
	end
	if M.protocol=='llmoney' then
		return money.get(player.xuid)
	end
	print('[ILand] ERR!! Unknown money protocol \''..M.protocol..'\' !')
end
function sendTitle(player,title,subtitle)
	local name = player.realName
	mc.runCmdEx('title "' .. name .. '" times 20 25 20')
	if subtitle~=nil then
	mc.runCmdEx('title "' .. name .. '" subtitle '..subtitle) end
	mc.runCmdEx('title "' .. name .. '" title '..title)
end
function sendText(player,text,mode)
	-- [mode] 0 = FORCE USE TALK
	if mode==nil and not(cfg.features.force_talk) then 
		player.sendText(text,5)
		return
	end
	if cfg.features.force_talk and mode~=0 then
		player.sendText('§l§b———————————§a LAND §b———————————\n§r'..text,0)
	end
	if mode==0 then
		player.sendText('§l§b[§a LAND §b] §r'..text,0)
		return
	end
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
function GetTopAir(vec4)
	if dim==0 or dim==2 then high=255+1 end
	if dim==1 then high=128+1 end
	local bl
	local t=vec4
	for i=y,high do
		t.y = i
		bl = mc.getBlock(t)
		if bl.type=='minecraft:air' then
			return i
		end
	end
end
function did2dim(id)
	if id==0 then return _tr('talk.dim.zero') end
	if id==1 then return _tr('talk.dim.one') end
	if id==2 then return _tr('talk.dim.two') end
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

-- Minecraft -> Eventing
function Eventing_onJoin(player)
	local xuid = player.xuid
	debug_landquery==player 
	TRS_From[xuid] = {}
	TRS_From[xuid].inland = 'null'
	if land_owners[xuid]==nil then
		land_owners[xuid] = {}
		ILAPI.save()
	end
end
function Eventing_onLeft(player)
	local xuid = player.xuid
	TRS_Form[xuid]=nil
	ArrayParticles[xuid]=nil
end
function Eventing_onPlayerCmd(player,cmd)
	local opt = AIR.split(cmd,' ')
	if opt[1] ~= MainCmd then return end

	local xuid = player.xuid
	local pos = player.pos

	-- [ ] Main Command
	if opt[1] == MainCmd and opt[2]==nil then
		local landId = ILAPI.PosGetLand(pos)
		if landId~=-1 and ILAPI.GetOwner(landId)==xuid then
			TRS_Form[xuid].landId=landId
			GUI_FastMgr(player)
		else
			local land_count = tostring(#land_owners[xuid])
			local buttons = {
				_tr('gui.fastgde.create'),
				_tr('gui.fastgde.manage'),
				_tr('gui.general.close')
			}
			local images = {
				'textures/ui/icon_iron_pickaxe',
				'textures/ui/confirm',
				'textures/ui/icon_import'
			}
			player.sendSimpleForm(
				_tr('gui.fastgde.title'),
				AIR.gsubEx(_tr('gui.fastgde.content'),'<a>',land_count),
				buttons,
				images,
				FORM_land_gde
			)
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
		sendText(player,_tr('title.getlicense.succeed')..AIR.gsubEx(_tr('title.selectrange.spointa'),'<a>',cfg.features.selection_tool_name))
		newLand[xuid]={}
		newLand[xuid].step=0
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
		TRS_From[xuid].backpo = 0
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
		player.sendModalForm(
			_tr('gui.general.complete'),
			AIR.gsubEx(_tr('gui.landtp.point'),'<a>',AIR.vec2text(xyz),'<b>',landname),
			_tr('gui.general.iknow'),
			_tr('gui.general.close'),
			FORM_NULL
		)
		return false
	end

	-- [tp] LandTp GUI
	if opt[2] == 'tp' and cfg.features.landtp then
		local tplands = { '['.._tr('gui.general.plzchose')..']' }
		for i,landId in pairs(ILAPI.GetPlayerLands(xuid) do
			local name = ILAPI.GetNickname(landId,true)
			local xpos = land_data[landId].settings.tpoint
			tplands[i+1]='('..xpos[1]..','..xpos[2]..','..xpos[3]..') '..name
		end
		local Form = mc.newForm()
		Form.setTitle(_tr('gui.landtp.title'))
		Form.addLabel(_tr('gui.landtp.tip'))
		Form.addDropdown(_tr('gui.landtp.tip2'),tplands)
		player.sendForm(Form,FORM_landtp)
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
		TRS_From[xuid].selectool=0
		return false
	end

	-- [X] Unknown key
	sendText(player,AIR.gsubEx(_tr('command.error'),'<a>',opt[2]),0)
	return false

end
function Eventing_onConsoleCmd(cmd)
	local opt = AIR.split(cmd,' ')
	if opt[1] ~= MainCmd then return end

	-- [ ] main cmd.
	if opt[2] == nil then
		print('The server is running iLand v'..plugin_version)
		print('Github: https://github.com/McAirLand/iLand-Core')
		return false
	end

	-- [op] add land operator.
	if opt[2] == 'op' then
		if AIR.isValInList(cfg.manager.operator,opt[3])==-1 then
			if not(AIR.isNumber(opt[3])) then
				print('Wrong xuid!');return false
			end
			table.insert(cfg.manager.operator,#cfg.manager.operator+1,opt[3])
			ILAPI.save()
			print('Xuid: '..opt[3]..' has been added to the LandMgr list.')
		else
			print('Xuid: '..opt[3]..' is already in LandMgr list.')
		end
		return false
	end

	-- [deop] add land operator.
	if opt[2] == 'deop' then
		local p = AIR.isValInList(cfg.manager.operator,opt[3])
		if p~=-1 then
			if not(AIR.isNumber(opt[3])) then
				print('Wrong xuid!');return false
			end
			table.remove(cfg.manager.operator,p)
			ILAPI.save()
			print('Xuid: '..opt[3]..' has been removed from LandMgr list.')
		else
			print('Xuid: '..opt[3]..' is not in LandMgr list.')
		end
		return false
	end

	-- [X] Unknown key
	print('Unknown parameter: "'..opt[2]..'", plugin wiki: https://git.io/JcvIw')
	return false

end
function Eventing_onDestroyBlock(player,block)

	if TRS_From[xuid].selectool==0 then
		local HandItem = player.getHand()
		if HandItem.isNull(HandItem) then goto PROCESS_1 end --fix crash
		sendText(player,AIR.gsubEx(_tr('title.oplandmgr.setsuccess'),'<a>',HandItem.name))
		cfg.features.selection_tool=HandItem.type
		ILAPI.save()
		TRS_From[xuid].selectool=-1
		return -1
	end

	if newLand[xuid]~=nil then
		local HandItem = player.getHand()
		if HandItem.isNull() or HandItem.type~=cfg.features.selection_tool then goto PROCESS_1 end
		BoughtProg_SelectRange(player,block.pos,newLand[xuid].step)
		return -1
	end

	:: PROCESS_1 ::
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_destroy then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onPlaceBlock(player,block)
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_place then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))

	return false
end
function Eventing_onUseItem(player,item,block)
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	
	local perm = land_data[landId].permissions
	local bn = block.type
	if bn == 'minecraft:end_portal_frame' and perm.allow_destroy then return end -- 末地门（拓充）
	if bn == 'minecraft:lectern' and perm.allow_destroy then return end -- 讲台（拓充）
	if bn == 'minecraft:bed' and perm.use_bed then return end -- 床
	if bn == 'minecraft:crafting_table' and perm.use_crafting_table then return end -- 工作台
	if bn == 'minecraft:campfire' and perm.use_campfire then return end -- 营火（烧烤）
	if bn == 'minecraft:composter' and perm.use_composter then return end -- 堆肥桶（放置肥料）
	if (bn == 'minecraft:undyed_shulker_box' or bn == 'shulker_box') and perm.use_shulker_box then return end -- 潜匿箱
	if bn == 'minecraft:noteblock' and perm.use_noteblock then return end -- 音符盒（调音）
	if bn == 'minecraft:jukebox' and perm.use_jukebox then return end -- 唱片机（放置/取出唱片）
	if bn == 'minecraft:bell' and perm.use_bell then return end -- 钟（敲钟）
	if (bn == 'minecraft:daylight_detector_inverted' or bn == 'daylight_detector') and perm.use_daylight_detector then return end -- 光线传感器（切换日夜模式）
	if bn == 'minecraft:fence_gate' and perm.use_fence_gate then return end -- 栏栅门
	if bn == 'minecraft:trapdoor' and perm.use_trapdoor then return end -- 活板门
	if bn == 'minecraft:lectern' and perm.use_lectern then return end -- 讲台
	if bn == 'minecraft:cauldron' and perm.use_cauldron then return end -- 炼药锅

	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onOpenContainer(player,block)
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_open_chest then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onAttack(player,entity)
	local landId=ILAPI.PosGetLand(entity.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_attack then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onExplode(entity,pos)
	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].permissions.allow_exploding then return end -- Perm Allow
	return false
end
function Eventing_onTakeItem(player,item)
	local landId=ILAPI.PosGetLand(player.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_pickupitem then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onDropItem(player,item)
	local landId=ILAPI.PosGetLand(player.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_dropitem then return end -- Perm Allow
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust
	sendText(player,_tr('title.landlimit.noperm'))
	return false
end
function Eventing_onBlockInteracted(player,block)

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if AIR.isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if AIR.isValInList(land_owners[xuid],landId)~=-1 then return end -- Owner
	if AIR.isValInList(land_data[landId].settings.share,xuid)~=-1 then return end -- Trust

	local perm = land_data[landId].permissions
	local bn = block.type
	if bn == 'minecraft:cartography_table' and perm.use_cartography_table then return end -- 制图台
	if bn == 'minecraft:smithing_table' and perm.use_smithing_table then return end -- 锻造台
	if bn == 'minecraft:furnace' and perm.use_furnace then return end -- 熔炉
	if bn == 'minecraft:blast_furnace' and perm.use_blast_furnace then return end -- 高炉
	if bn == 'minecraft:smoker' and perm.use_smoker then return end -- 烟熏炉
	if bn == 'minecraft:brewing_stand' and perm.use_brewing_stand then return end -- 酿造台
	if bn == 'minecraft:anvil' and perm.use_anvil then return end -- 铁砧
	if bn == 'minecraft:grindstone' and perm.use_grindstone then return end -- 磨石
	if bn == 'minecraft:enchanting_table' and perm.use_enchanting_table then return end -- 附魔台
	-- if blockname == 'minecraft:barrel' and perm.use_barrel then return end -- 桶
	if bn == 'minecraft:beacon' and perm.use_beacon then return end -- 信标
	if bn == 'minecraft:hopper' and perm.use_hopper then return end -- 漏斗
	if bn == 'minecraft:dropper' and perm.use_dropper then return end -- 投掷器
	if bn == 'minecraft:dispenser' and perm.use_dispenser then return end -- 发射器
	if bn == 'minecraft:loom' and perm.use_loom then return end -- 织布机
	
	return false
end

-- Lua -> Timer Callback
function Tcb_LandSign()
	for num,player in pairs(mc.getOnlinePlayers()) do
		local xuid = player.xuid
		local landId=ILAPI.PosGetLand(player.pos)
		if landId==-1 then TRS_Form[xuid].inland='null';return end -- no land here
		if landId==TRS_Form[xuid].inland then return end -- signed
		local owner=ILAPI.GetOwner(landId)
		local ownername='?'
		if owner~='?' then ownername=GetIdFromXuid(owner) end
		local slname = ILAPI.GetNickname(landId,false)
		if xuid==owner then
			if not(land_data[landId].settings.signtome) then return end
			sendTitle(player,AIR.gsubEx(_tr('sign.listener.ownertitle'),'<a>',slname),_tr('sign.listener.ownersubtitle'))
		else
			if not(land_data[landId].settings.signtother) then return end
			sendTitle(player,_tr('sign.listener.visitortitle'),AIR.gsubEx(_tr('sign.listener.visitorsubtitle'),'<a>',ownername))
			if land_data[landId].settings.describe~='' then
				sendText(player,AIR.gsubEx(land_data[landId].settings.describe,
													'$visitor',player.realName,
													'$n','\n'
												),0)
			end
		end
		TRS_Form[v].inland=landId
	end
end
function Tcb_SelectionParticles()
	for xuid,posarr in pairs(ArrayParticles) do
		for n,pos in pairs(posarr) do
			mc.runCmdEx('execute @a[name="'..GetIdFromXuid(xuid)..'"] ~ ~ ~ particle "'..cfg.features.particle_effects..'" '..pos.x..' '..tostring(pos.y+1.6)..' '..pos.z)
		end
	end
end

-- listen events,
mc.listen('onPlayerCmd',Eventing_onPlayerCmd)
mc.listen('onConsoleCmd',Eventing_onConsoleCmd)
mc.listen('onJoin',Eventing_onJoin)
mc.listen('onLeft',Eventing_onLeft)
mc.listen('onDestroyBlock',Eventing_onDestroyBlock)
mc.listen('onPlaceBlock',Eventing_onPlaceBlock)
mc.listen('onUseItem',Eventing_onUseItem)
mc.listen('onOpenContainer',Eventing_onOpenContainer)
mc.listen('onAttack',Eventing_onAttack)
mc.listen('onExplode',Eventing_onExplode)
mc.listen('onTakeItem',Eventing_onTakeItem)
mc.listen('onDropItem',Eventing_onDropItem)
mc.listen('onBlockInteracted',Eventing_onBlockInteracted)

-- timer -> landsign
function enableLandSign()
	CLOCK_LANDSIGN = setInterval(Tcb_LandSign,cfg.features.sign_frequency*1000)
end
if cfg.features.landSign then
	enableLandSign()
end

-- timer -> particles
function enableParticles()
	CLOCK_PARTICLES = setInterval(Tcb_SelectionParticles,2*1000)
end
if cfg.features.particles then
	enableParticles()
end

-- timer -> debugger
function DEBUG_LANDQUERY()
	if debug_landquery==nil then return end
	local pos = debug_landquery.pos
	local landId=ILAPI.PosGetLand(pos)
	local N = ILAPI.GetChunk(pos)
	local Cx,Cz = pos2chunk(pos)
	print('[ILand] Debugger: [Query] '..landId)
	if N==-1 then
		print('[ILand] Debugger: [Chunk] not found')
	else
		for i,v in pairs(N) do
			print('[ILand] Debugger: [Chunk] ('..Cx..','..Cz..') '..i..' '..v)
		end
	end
end
if debug_mode then
	setInterval(DEBUG_LANDQUERY,3*1000)
end

-- check update
function Ncb_online(code,result)
	if code==200 then
		local data=json.decode(result)
		
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
if cfg.update_check then
	network.httpGet('http://cdisk.amd.rocks/tmp/ILAND/v111_version',Ncb_online)
end

-- register cmd.
mc.regPlayerCmd(MainCmd,_tr('command.land'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' new',_tr('command.land_new'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' giveup',_tr('command.land_giveup'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' gui',_tr('command.land_gui'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' a',_tr('command.land_a'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' b',_tr('command.land_b'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' buy',_tr('command.land_buy'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' mgr',_tr('command.land_mgr'),function(pl,args){})
mc.regPlayerCmd(MainCmd..' mgr selectool',_tr('command.land_mgr_selectool'),function(pl,args){})
if cfg.features.landtp then
	mc.regPlayerCmd(MainCmd..' tp',_tr('command.land_tp'),function(pl,args){})
	mc.regPlayerCmd(MainCmd..' point',_tr('command.land_point'),function(pl,args){})
end

-- print
print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version..', ')
print('[ILand] By: RedbeanW, License: GPLv3 with additional conditions.')