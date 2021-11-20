--[[ ------------------------------------------------------

	    __    __        ______    __   __    _____
	   /\ \  /\ \      /\  __ \  /\ "-.\ \  /\  __-.
	   \ \ \ \ \ \____ \ \  __ \ \ \ \-.  \ \ \ \/\ \
	    \ \_\ \ \_____\ \ \_\ \_\ \ \_\\"\_\ \ \____-
	     \/_/  \/_____/  \/_/\/_/  \/_/ \/_/  \/____/

	  Author   RedbeanW
	  Github   https://github.com/LiteLDev-LXL/iLand-Core
	  License  GPLv3 未经许可禁止商业使用
	  
--]] ------------------------------------------------------

Plugin = {
	version = "2.42",
	numver = 242,
	minLXL = {0,5,8},
}

Server = {
	link = "https://cdn.jsdelivr.net/gh/LiteLDev-LXL/Cloud/",
	version = 203,
	memInfo = {}
}

JSON = require('dkjson')
ILAPI={};MEM={}

MainCmd = 'land'
DATA_PATH = 'plugins\\iland\\'
local land_data;local land_owners={};local wrong_landowners={}

-- [Raw] config.json
local cfg = {
	version = Plugin.numver,
	plugin = {
		network = true,
		language = "zh_CN"
	},
	land = {
		operator = {},
		max_lands = 5,
		bought = {
			three_dimension = {
				enable = true,
				calculate_method = "m-1",
				price = {20,4}
			},
			two_dimension = {
				enable = true,
				calculate_method = "d-1",
				price = {35}
			},
			square_range = {4,50000},
			discount = 1
		},
		refund_rate = 0.9
	},
	economic = {
		protocol = "llmoney",
		scoreboard_objname = "",
		currency_name = "Coin"
	},
	features = {
		landsign = {
			enable = true,
			frequency = 2
		},
		buttomsign = {
			enable = true,
			frequency = 1
		},
		particles = {
			enable = true,
			name = "minecraft:villager_happy",
			max_amount = 600
		},
		player_selector = {
			include_offline_players = true,
			items_perpage = 20,
		},
		selection = {
			disable_dimension = {},
			tool_type = "minecraft:wooden_axe",
			tool_name = "Wooden Axe"
		},
		landtp = true,
		force_talk = false,
		disabled_listener = {},
        chunk_side = 16
	}
}

DEV_MODE = false
if File.exists("EnableILandDevMode") then
	DEV_MODE = true
	DATA_PATH = 'plugins\\LXL_Plugins\\iLand\\iland\\'
end

local minY <const> = -64
local maxY <const> = 320

-- Preload Functions
function INFO(type,content)
	if content==nil then
		print('[ILand] |INFO| '..type)
		return
	end
	print('[ILand] |'..type..'| '..content)
end
function ERROR(content)
	INFO('ERROR',content)
end
function WARN(content)
	INFO('WARN',content)
end

-- map builder
function UpdateChunk(landId,mode)

	-- [CODE] Get all chunk for this land.

	local TxTz={} -- ChunkData(position)
	local ThisRange = land_data[landId].range
	local dimid = ThisRange.dimid
	local function chkNil(table,a,b)
		if table[a]==nil then
			table[a] = {}
		end
		if table[a][b]==nil then
			table[a][b] = {}
		end
	end

	local size = cfg.features.chunk_side
	local sX = ThisRange.start_position[1]
	local sZ = ThisRange.start_position[3]
	local count = 0
	while (sX+size*count<=ThisRange.end_position[1]+size) do
		local Cx,Cz = ToChunkPos({x=sX+size*count,z=sZ+size*count})
		chkNil(TxTz,Cx,Cz)
		local count2 = 0
		while (sZ+size*count2<=ThisRange.end_position[3]+size) do
			local Cx,Cz = ToChunkPos({x=sX+size*count,z=sZ+size*count2})
			chkNil(TxTz,Cx,Cz)
			count2 = count2 + 1
		end
		count = count +1
	end

	-- [CODE] Add or Del some chunks.

	for Tx,a in pairs(TxTz) do
		for Tz,b in pairs(a) do
			-- Tx Tz
			if mode=='add' then
				chkNil(ChunkMap[dimid],Tx,Tz)
				if FoundValueInList(ChunkMap[dimid][Tx][Tz],landId) == -1 then
					table.insert(ChunkMap[dimid][Tx][Tz],#ChunkMap[dimid][Tx][Tz]+1,landId)
				end
			end
			if mode=='del' then
				local p = FoundValueInList(ChunkMap[dimid][Tx][Tz],landId)
				if p~=-1 then
					table.remove(ChunkMap[dimid][Tx][Tz],p)
				end
			end
		end
	end

end
function UpdateLandPosMap(landId,mode)
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
function UpdateLandEdgeMap(landId,mode)
	if mode=='del' then
		EdgeMap[landId]=nil
		return
	end
	if mode=='add' then
		EdgeMap[landId]={}
		local spos = ArrayToPos(land_data[landId].range.start_position)
		local epos = ArrayToPos(land_data[landId].range.end_position)
		EdgeMap[landId].D2D = CubeToEdge_2D(spos,epos)
		EdgeMap[landId].D3D = CubeToEdge(spos,epos)
	end
end
function UpdateLandTrustMap(landId)
	LandTrustedMap[landId]={}
	for n,xuid in pairs(land_data[landId].settings.share) do
		LandTrustedMap[landId][xuid]={}
	end
end
function UpdateLandOwnersMap(landId)
	LandOwnersMap[landId]={}
	LandOwnersMap[landId]=ILAPI.GetOwner(landId)
end
function UpdateLandOperatorsMap()
	LandOperatorsMap = {}
	for n,xuid in pairs(cfg.land.operator) do
		LandOperatorsMap[xuid]={}
	end
end
function BuildListenerMap()
	ListenerDisabled={}
	for n,lner in pairs(cfg.features.disabled_listener) do
		ListenerDisabled[lner] = { true }
	end
end
function BuildUIBITable()
	CanCtlMap = {}
	CanCtlMap[0] = {} -- UseItem
	CanCtlMap[1] = {} -- onBlockInteracted
	CanCtlMap[2] = {} -- ItemWhiteList
	CanCtlMap[3] = {} -- AttackWhiteList
	CanCtlMap[4] = {} -- EntityTypeList
	CanCtlMap[4].animals = {}
	CanCtlMap[4].mobs = {}
	local useItemTmp = {
		'minecraft:bed','minecraft:chest','minecraft:trapped_chest','minecraft:crafting_table',
		'minecraft:campfire','minecraft:soul_campfire','minecraft:composter','minecraft:undyed_shulker_box',
		'minecraft:shulker_box','minecraft:noteblock','minecraft:jukebox','minecraft:bell',
		'minecraft:daylight_detector_inverted','minecraft:daylight_detector','minecraft:lectern',
		'minecraft:cauldron','minecraft:lever','minecraft:stone_button','minecraft:wooden_button',
		'minecraft:spruce_button','minecraft:birch_button','minecraft:jungle_button','minecraft:acacia_button',
		'minecraft:dark_oak_button','minecraft:crimson_button','minecraft:warped_button',
		'minecraft:polished_blackstone_button','minecraft:respawn_anchor','minecraft:trapdoor',
		'minecraft:spruce_trapdoor','minecraft:birch_trapdoor','minecraft:jungle_trapdoor',
		'minecraft:acacia_trapdoor','minecraft:dark_oak_trapdoor','minecraft:crimson_trapdoor',
		'minecraft:warped_trapdoor','minecraft:fence_gate','minecraft:spruce_fence_gate',
		'minecraft:birch_fence_gate','minecraft:jungle_fence_gate','minecraft:acacia_fence_gate',
		'minecraft:dark_oak_fence_gate','minecraft:crimson_fence_gate','minecraft:warped_fence_gate',
		'minecraft:wooden_door','minecraft:spruce_door','minecraft:birch_door','minecraft:jungle_door',
		'minecraft:acacia_door','minecraft:dark_oak_door','minecraft:crimson_door','minecraft:warped_door',
	}
	local blockInterTmp = {
		'minecraft:cartography_table','minecraft:smithing_table','minecraft:furnace','minecraft:blast_furnace',
		'minecraft:smoker','minecraft:brewing_stand','minecraft:anvil','minecraft:grindstone','minecraft:enchanting_table',
		'minecraft:barrel','minecraft:beacon','minecraft:hopper','minecraft:dropper','minecraft:dispenser',
		'minecraft:loom','minecraft:stonecutter_block'
	}
	local itemWlistTmp = {
		'minecraft:glow_ink_sac','minecraft:end_crystal','minecraft:ender_eye','minecraft:axolotl_bucket',
		'minecraft:powder_snow_bucket','minecraft:pufferfish_bucket','minecraft:tropical_fish_bucket',
		'minecraft:salmon_bucket','minecraft:cod_bucket','minecraft:water_bucket','minecraft:cod_bucket',
		'minecraft:lava_bucket','minecraft:bucket','minecraft:flint_and_steel'
	}
	local attackwlistTmp = {
		'minecraft:ender_crystal','minecraft:armor_stand'
	}
	local animals = {
		'minecraft:axolotl','minecraft:bat','minecraft:cat','minecraft:chicken',
		'minecraft:cod','minecraft:cow','minecraft:donkey','minecraft:fox',
		'minecraft:glow_squid','minecraft:horse','minecraft:mooshroom','minecraft:mule',
		'minecraft:ocelot','minecraft:parrot','minecraft:pig','minecraft:rabbit',
		'minecraft:salmon','minecraft:snow_golem','minecraft:sheep','minecraft:skeleton_horse',
		'minecraft:squid','minecraft:strider','minecraft:tropical_fish','minecraft:turtle',
		'minecraft:villager_v2','minecraft:wandering_trader','minecraft:npc' -- npc not animal? hengaaaaaaaa~
	}
	local mobs = {
		-- type A
		'minecraft:pufferfish','minecraft:bee','minecraft:dolphin','minecraft:goat',
		'minecraft:iron_golem','minecraft:llama','minecraft:llama_spit','minecraft:wolf',
		'minecraft:panda','minecraft:polar_bear','minecraft:enderman','minecraft:piglin',
		'minecraft:spider','minecraft:cave_spider','minecraft:zombie_pigman',
		-- type B
		'minecraft:blaze','minecraft:small_fireball','minecraft:creeper','minecraft:drowned',
		'minecraft:elder_guardian','minecraft:endermite','minecraft:evocation_illager','minecraft:evocation_fang',
		'minecraft:ghast','minecraft:fireball','minecraft:guardian','minecraft:hoglin',
		'minecraft:husk','minecraft:magma_cube','minecraft:phantom','minecraft:pillager',
		'minecraft:ravager','minecraft:shulker','minecraft:shulker_bullet','minecraft:silverfish',
		'minecraft:skeleton','minecraft:skeleton_horse','minecraft:slime','minecraft:vex',
		'minecraft:vindicator','minecraft:witch','minecraft:wither_skeleton','minecraft:zoglin',
		'minecraft:zombie','minecraft:zombie_villager_v2','minecraft:piglin_brute','minecraft:ender_dragon',
		'minecraft:dragon_fireball','minecraft:wither','minecraft:wither_skull','minecraft:wither_skull_dangerous'
	}
	for n,uitem in pairs(useItemTmp) do
		CanCtlMap[0][uitem] = { true }
	end
	for n,bint in pairs(blockInterTmp) do
		CanCtlMap[1][bint] = { true }
	end
	for n,iwl in pairs(itemWlistTmp) do
		CanCtlMap[2][iwl] = { true }
	end
	for n,awt in pairs(attackwlistTmp) do
		CanCtlMap[3][awt] = { true }
	end
	for n,anis in pairs(animals) do
		CanCtlMap[4].animals[anis] = { true }
	end
	for n,mons in pairs(mobs) do
		CanCtlMap[4].mobs[mons] = { true }
	end
end
function BuildAnyMap()
	EdgeMap={}
	VecMap={}
	LandTrustedMap={}
	LandOwnersMap={}
	LandOperatorsMap={}
	ChunkMap={}
	ChunkMap[0] = {} -- 主世界
	ChunkMap[1] = {} -- 地狱
	ChunkMap[2] = {} -- 末地
	for landId,data in pairs(land_data) do
		UpdateLandEdgeMap(landId,'add')
		UpdateLandPosMap(landId,'add')
		UpdateChunk(landId,'add')
		UpdateLandTrustMap(landId)
		UpdateLandOwnersMap(landId)
	end
	UpdateLandOperatorsMap()
	BuildUIBITable()
	BuildListenerMap()
end

--------- Plugin Load <ST> ---------

function UpdateConfig(cfg_o)
	local this,cfg_t = CloneTable(cfg_o)
	if this.version==nil or this.version<240 then
        return false
    end
	if this.version==240 then -- OLD STRUCTURE
		cfg_t = CloneTable(cfg)
		cfg_t.plugin.language = this.manager.default_language
		cfg_t.plugin.network = this.update_check
		cfg_t.land.operator = this.manager.operator
		cfg_t.land.max_lands = this.land.player_max_lands
		cfg_t.land.bought.three_dimension.enable = this.features.land_3D
		cfg_t.land.bought.three_dimension.calculate_method = this.land_buy.calculation_3D
		cfg_t.land.bought.three_dimension.price = this.land_buy.price_3D
		cfg_t.land.bought.two_dimension.enable = this.features.land_2D
		cfg_t.land.bought.two_dimension.calculate_method = this.land_buy.calculation_2D
		cfg_t.land.bought.two_dimension.price = this.land_buy.price_2D
		cfg_t.land.bought.square_range = {this.land.land_max_square,this.land.land_min_square}
		cfg_t.land.bought.discount = this.money.discount/100
		cfg_t.land.refund_rate = this.land_buy.refund_rate
		cfg_t.economic.protocol = this.money.protocol
		cfg_t.economic.scoreboard_objname = this.money.scoreboard_objname
		cfg_t.economic.currency_name = this.money.credit_name
		cfg_t.features.landsign.enable = this.features.landSign
		cfg_t.features.landsign.frequency = this.features.sign_frequency
		cfg_t.features.buttomsign.enable = this.features.landSign
		cfg_t.features.buttomsign.frequency = this.features.sign_frequency
		cfg_t.features.particles.enable = this.features.particles
		cfg_t.features.particles.name = this.features.particle_effects
		cfg_t.features.particles.max_amount = this.features.player_max_ple
		cfg_t.features.player_selector.include_offline_players = this.features.offlinePlayerInList
		cfg_t.features.player_selector.items_perpage = this.features.playersPerPage
		cfg_t.features.selection.disable_dimension = this.features.blockLandDims
		cfg_t.features.selection.tool_type = this.features.selection_tool
		cfg_t.features.selection.tool_name = this.features.selection_tool_name
		cfg_t.features.landtp = this.features.landtp
		cfg_t.features.force_talk = this.features.force_talk
		cfg_t.features.disabled_listener = this.features.disabled_listener
		cfg_t.features.chunk_side = this.features.chunk_side
	end
	if this.version==241 then
		cfg_t.version = 242
	end
	return cfg_t
end
function UpdateLand(start_ver)
	if start_ver==240 then
		for landId,res in pairs(land_data) do
			local perm = land_data[landId].permissions
			perm.use_armor_stand = false
			perm.eat = false
		end
	end
	ILAPI.save({0,1,0})
end
function load(para) -- { cfg, land, owner }
	-- load cfg
	if para==nil then
		para = {1,1,1}
	end
	local need_update = {false,0}
	if para[1]==1 then
		if not(file.exists(DATA_PATH..'config.json')) then
			WARN('Data file (config.json) does not exist, creating...')
			file.writeTo(DATA_PATH..'config.json',JSON.encode(cfg,{indent=true}))
		end
		local count = 0
		local function apply(val,typ)
			count = count + 1
			local tpe = type(val)
			if tpe ~= typ then
				error('Wrong type in data('..count..'), "'..typ..'" is required but "'..tpe..'" is provided!')
			end
			return val
		end
		local loadcfg = JSON.decode(file.readFrom(DATA_PATH..'config.json'))
		if cfg.version ~= loadcfg.version then -- need update
			need_update = {true,loadcfg.version}
			loadcfg = UpdateConfig(loadcfg)
			if loadcfg==nil or loadcfg==false then
				error('Configure file too old, you must rebuild it.')
				return false
			end
		end

		-- cfg -> plugin
		cfg.plugin.language = apply(loadcfg.plugin.language,'string')
		cfg.plugin.network = apply(loadcfg.plugin.network,'boolean')
		-- cfg -> land
		cfg.land.operator = apply(loadcfg.land.operator,'table')
		cfg.land.max_lands = apply(loadcfg.land.max_lands,'number')
		cfg.land.bought.three_dimension.enable = apply(loadcfg.land.bought.three_dimension.enable,'boolean')
		cfg.land.bought.three_dimension.calculate_method = apply(loadcfg.land.bought.three_dimension.calculate_method,'string')
		cfg.land.bought.three_dimension.price = apply(loadcfg.land.bought.three_dimension.price,'table')
		cfg.land.bought.two_dimension.enable = apply(loadcfg.land.bought.two_dimension.enable,'boolean')
		cfg.land.bought.two_dimension.calculate_method = apply(loadcfg.land.bought.two_dimension.calculate_method,'string')
		cfg.land.bought.two_dimension.price = apply(loadcfg.land.bought.two_dimension.price,'table')
		cfg.land.bought.square_range = apply(loadcfg.land.bought.square_range,'table')
		cfg.land.bought.discount = apply(loadcfg.land.bought.discount,'number')
		cfg.land.refund_rate = apply(loadcfg.land.refund_rate,'number')
		-- cfg -> economic
		cfg.economic.protocol = apply(loadcfg.economic.protocol,'string')
		cfg.economic.scoreboard_objname = apply(loadcfg.economic.scoreboard_objname,'string')
		cfg.economic.currency_name = apply(loadcfg.economic.currency_name,'string')
		-- cfg -> features
		cfg.features.landsign.enable = apply(loadcfg.features.landsign.enable,'boolean')
		cfg.features.landsign.frequency = apply(loadcfg.features.landsign.frequency,'number')
		cfg.features.buttomsign.enable = apply(loadcfg.features.buttomsign.enable,'boolean')
		cfg.features.buttomsign.frequency = apply(loadcfg.features.buttomsign.frequency,'number')
		cfg.features.particles.enable = apply(loadcfg.features.particles.enable,'boolean')
		cfg.features.particles.name = apply(loadcfg.features.particles.name,'string')
		cfg.features.particles.max_amount = apply(loadcfg.features.particles.max_amount,'number')
		cfg.features.player_selector.include_offline_players = apply(loadcfg.features.player_selector.include_offline_players,'boolean')
		cfg.features.player_selector.items_perpage = apply(loadcfg.features.player_selector.items_perpage,'number')
		cfg.features.selection.disable_dimension = apply(loadcfg.features.selection.disable_dimension,'table')
		cfg.features.selection.tool_type = apply(loadcfg.features.selection.tool_type,'string')
		cfg.features.selection.tool_name = apply(loadcfg.features.selection.tool_name,'string')
		cfg.features.landtp = apply(loadcfg.features.landtp,'boolean')
		cfg.features.force_talk = apply(loadcfg.features.force_talk,'boolean')
		cfg.features.disabled_listener = apply(loadcfg.features.disabled_listener,'table')
		cfg.features.chunk_side = apply(loadcfg.features.chunk_side,'number')

		if need_update[1] then
			ILAPI.save({1,0,0})
		end
	end
	-- load land data
	if para[2]==1 then
		if not(file.exists(DATA_PATH..'data.json')) then
			WARN('Data file (data.json) does not exist, creating...')
			file.writeTo(DATA_PATH..'data.json','{}')
		end
		land_data = JSON.decode(file.readFrom(DATA_PATH..'data.json'))
		if need_update[1] then
			UpdateLand(need_update[2])
		end
	end
	-- load owners data
	if para[3]==1 then
		if not(file.exists(DATA_PATH..'owners.json')) then
			WARN('Data file (owners.json) does not exist, creating...')
			file.writeTo(DATA_PATH..'owners.json','{}')
		end
		local wrongXuidFounded = false
		for ownerXuid,landIds in pairs(JSON.decode(file.readFrom(DATA_PATH..'owners.json'))) do
			if data.xuid2name(ownerXuid) == '' then
				ERROR(_Tr('console.error.readowner.xuid','<a>',ownerXuid))
				wrong_landowners[ownerXuid] = landIds
				wrongXuidFounded = true
			else
				land_owners[ownerXuid] = landIds
			end
		end
		if wrongXuidFounded then
			WARN(_Tr('console.error.readowner.tipxid'))
		end
	end
	return true
end
if not(lxl.checkVersion(Plugin.minLXL[1],Plugin.minLXL[2],Plugin.minLXL[3])) then
	ERROR('LiteXLoader is too old, plugin loading aborted.')
	return
end

LangPack = JSON.decode(file.readFrom(DATA_PATH..'lang\\'..cfg.plugin.language..'.json'))
if LangPack.VERSION ~= Plugin.numver then
	error('Language pack version does not correspond('..LangPack.VERSION..'!='..Plugin.numver..'), plugin loading aborted.')
	return
end

--------- Plugin Load <ED> ---------

-- Plugin funcs
function F_NULL(...) end
function FORM_BACK_LandOPMgr(player,id)
	if not(id) then return end
	GUI_OPLMgr(player)
end
function FORM_BACK_LandMgr(player,id)
	if not(id) then return end
	GUI_FastMgr(player)
end
function Handler_LandCfg(player,landId,option)
	local xuid = player.xuid

	MEM[xuid].landId=landId
	if option==0 then --查看领地信息
		local cubeInfo = CubeGetInfo(VecMap[landId].a,VecMap[landId].b)
		local owner = ILAPI.GetOwner(landId)
		if owner~='?' then owner=data.xuid2name(owner) end
		player:sendModalForm(
			_Tr('gui.landmgr.landinfo.title'),
			_Tr('gui.landmgr.landinfo.content',
				'<a>',owner,
				'<b>',landId,
				'<c>',ILAPI.GetNickname(landId,false),
				'<d>',ILAPI.GetDimension(landId),
				'<e>',ToStrDim(land_data[landId].range.dimid),
				'<f>',PosToText(VecMap[landId].a),
				'<g>',PosToText(VecMap[landId].b),
				'<h>',cubeInfo.length,'<i>',cubeInfo.width,'<j>',cubeInfo.height,
				'<k>',cubeInfo.square,'<l>',cubeInfo.volume
			),
			_Tr('gui.general.iknow'),
			_Tr('gui.general.close'),
			FORM_BACK_LandMgr
		)
		return
	end
	if option==1 then --编辑领地选项
		local function isThisDisabled(feature)
			if cfg.features[feature]~=nil and cfg.features[feature] then
				return ''
			end
			return ' ('.._Tr('talk.features.closed')..')'
		end
		local Form = mc.newCustomForm()
		local settings=land_data[landId].settings
		Form:setTitle(_Tr('gui.landcfg.title'))
		Form:addLabel(_Tr('gui.landcfg.tip'))
		Form:addLabel(_Tr('gui.landcfg.landsign'))
		Form:addSwitch(_Tr('gui.landcfg.landsign.tome')..isThisDisabled('landsign'),settings.signtome)
		Form:addSwitch(_Tr('gui.landcfg.landsign.tother')..isThisDisabled('landsign'),settings.signtother)
		Form:addSwitch(_Tr('gui.landcfg.landsign.bottom')..isThisDisabled('buttomsign'),settings.signbuttom)
		Form:addLabel(_Tr('gui.landcfg.inside'))
		Form:addSwitch(_Tr('gui.landcfg.inside.explode'),settings.ev_explode) 
		Form:addSwitch(_Tr('gui.landcfg.inside.farmland_decay'),settings.ev_farmland_decay)
		Form:addSwitch(_Tr('gui.landcfg.inside.piston_push'),settings.ev_piston_push)
		Form:addSwitch(_Tr('gui.landcfg.inside.fire_spread'),settings.ev_fire_spread)
		player:sendForm(
			Form,
			function (player,res)
				if res==nil then return end

				local settings = land_data[landId].settings
				settings.signtome=res[1]
				settings.signtother=res[2]
				settings.signbuttom=res[3]
				settings.ev_explode=res[4]
				settings.ev_farmland_decay=res[5]
				settings.ev_piston_push=res[6]
				settings.ev_fire_spread=res[7]
				ILAPI.save({0,1,0})

				player:sendModalForm(
					_Tr('gui.general.complete'),
					'Complete.',
					_Tr('gui.general.back'),
					_Tr('gui.general.close'),
					FORM_BACK_LandMgr
				)
			end
		)
		return
	end
	if option==2 then --编辑领地权限
		local perm = land_data[landId].permissions
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landmgr.landperm.title'))
		Form:addLabel(_Tr('gui.landmgr.landperm.options.title'))
		Form:addLabel(_Tr('gui.landmgr.landperm.basic_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.place'),perm.allow_place)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.destroy'),perm.allow_destroy)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.entity_destroy'),perm.allow_entity_destroy)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.dropitem'),perm.allow_dropitem)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.pickupitem'),perm.allow_pickupitem)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.ride_entity'),perm.allow_ride_entity)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.ride_trans'),perm.allow_ride_trans)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.shoot'),perm.allow_shoot)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_player'),perm.allow_attack_player)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_animal'),perm.allow_attack_animal)
		Form:addSwitch(_Tr('gui.landmgr.landperm.basic_options.attack_mobs'),perm.allow_attack_mobs)
		Form:addLabel(_Tr('gui.landmgr.landperm.funcblock_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.crafting_table'),perm.use_crafting_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.furnace'),perm.use_furnace)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.blast_furnace'),perm.use_blast_furnace)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.smoker'),perm.use_smoker)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.brewing_stand'),perm.use_brewing_stand)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.cauldron'),perm.use_cauldron)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.anvil'),perm.use_anvil)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.grindstone'),perm.use_grindstone)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.enchanting_table'),perm.use_enchanting_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.cartography_table'),perm.use_cartography_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.smithing_table'),perm.use_smithing_table)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.loom'),perm.use_loom)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.stonecutter'),perm.use_stonecutter)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.lectern'),perm.use_lectern)
		Form:addSwitch(_Tr('gui.landmgr.landperm.funcblock_options.beacon'),perm.use_beacon)
		Form:addLabel(_Tr('gui.landmgr.landperm.contblock_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.barrel'),perm.use_barrel)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.hopper'),perm.use_hopper)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.dropper'),perm.use_dropper)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.dispenser'),perm.use_dispenser)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.shulker_box'),perm.use_shulker_box)
		Form:addSwitch(_Tr('gui.landmgr.landperm.contblock_options.chest'),perm.allow_open_chest)
		Form:addLabel(_Tr('gui.landmgr.landperm.other_options'))
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.campfire'),perm.use_campfire)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.firegen'),perm.use_firegen)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.door'),perm.use_door)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.trapdoor'),perm.use_trapdoor)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.fence_gate'),perm.use_fence_gate)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bell'),perm.use_bell)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.jukebox'),perm.use_jukebox)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.noteblock'),perm.use_noteblock)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.composter'),perm.use_composter)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bed'),perm.use_bed)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.item_frame'),perm.use_item_frame)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.daylight_detector'),perm.use_daylight_detector)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.lever'),perm.use_lever)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.button'),perm.use_button)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.pressure_plate'),perm.use_pressure_plate)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.armor_stand'),perm.use_armor_stand)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.eat'),perm.eat)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.throw_potion'),perm.allow_throw_potion)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.respawn_anchor'),perm.use_respawn_anchor)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.fishing'),perm.use_fishing_hook)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.bucket'),perm.use_bucket)
		Form:addSwitch(_Tr('gui.landmgr.landperm.other_options.useitem'),perm.useitem)
		Form:addLabel(_Tr('gui.landmgr.landperm.editevent'))
		player:sendForm(
			Form,
			function (player,res)
				if res==nil then return end
				
				local perm = land_data[landId].permissions
			
				perm.allow_place = res[1]
				perm.allow_destroy = res[2]
				perm.allow_entity_destroy = res[3]
				perm.allow_dropitem = res[4]
				perm.allow_pickupitem = res[5]
				perm.allow_ride_entity = res[6]
				perm.allow_ride_trans = res[7]
				perm.allow_shoot = res[8]
				perm.allow_attack_player = res[9]
				perm.allow_attack_animal = res[10]
				perm.allow_attack_mobs = res[11]
			
				perm.use_crafting_table = res[12]
				perm.use_furnace = res[13]
				perm.use_blast_furnace = res[14]
				perm.use_smoker = res[15]
				perm.use_brewing_stand = res[16]
				perm.use_cauldron = res[17]
				perm.use_anvil = res[18]
				perm.use_grindstone = res[19]
				perm.use_enchanting_table = res[20]
				perm.use_cartography_table = res[21]
				perm.use_smithing_table = res[22]
				perm.use_loom = res[23]
				perm.use_stonecutter = res[24]
				perm.use_lectern = res[25]
				perm.use_beacon = res[26]
				
				perm.use_barrel = res[27]
				perm.use_hopper = res[28]
				perm.use_dropper = res[29]
				perm.use_dispenser = res[30]
				perm.use_shulker_box = res[31]
				perm.allow_open_chest = res[32]
				
				perm.use_campfire = res[33]
				perm.use_firegen = res[34]
				perm.use_door = res[35]
				perm.use_trapdoor = res[36]
				perm.use_fence_gate = res[37]
				perm.use_bell = res[38]
				perm.use_jukebox = res[39]
				perm.use_noteblock = res[40]
				perm.use_composter = res[41]
				perm.use_bed = res[42]
				perm.use_item_frame = res[43]
				perm.use_daylight_detector = res[44]
				perm.use_lever = res[45]
				perm.use_button = res[46]
				perm.use_pressure_plate = res[47]
				perm.use_armor_stand = res[48]
				perm.eat = res[49]
				perm.allow_throw_potion = res[50]
				perm.use_respawn_anchor = res[51]
				perm.use_fishing_hook = res[52]
				perm.use_bucket = res[53]
			
				perm.useitem = res[54]
			
				ILAPI.save({0,1,0})
				player:sendModalForm(
					_Tr('gui.general.complete'),
					'Complete.',
					_Tr('gui.general.back'),
					_Tr('gui.general.close'),
					FORM_BACK_LandMgr
				)
			end
		)
		return
	end
	if option==3 then --编辑信任名单
		local shareList = land_data[landId].settings.share
		local content = _Tr('gui.landtrust.tip')
		if #shareList > 0 then
			content = content..'\n'.._Tr('gui.landtrust.trusted')
		end
		for n,plXuid in pairs(shareList) do
			local id = data.xuid2name(plXuid)
			if id~=nil then
				content = content..'\n'..id
			end
		end
		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.landtrust.title'))
		Form:setContent(content)
		Form:addButton(_Tr('gui.landtrust.addtrust'))
		if #shareList > 0 then
			Form:addButton(_Tr('gui.landtrust.rmtrust'))
		end
		player:sendForm(Form,function(pl,dta)
			if dta==nil then return end
			local xuid = pl.xuid
			MEM[xuid].edittype = dta -- [0]add [1]del
			-- gen idlist
			if dta==1 then -- del
				local ids = {}
				for i,v in pairs(shareList) do
					ids[#ids+1] = data.xuid2name(v)
				end
				PSR_New(pl,SRCB_land_trust,ids)
				return
			end
			PSR_New(pl,SRCB_land_trust)
		end)
		return
	end
	if option==4 then --领地nickname
		local nickn=ILAPI.GetNickname(landId,false)
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landtag.title'))
		Form:addLabel(_Tr('gui.landtag.tip'))
		Form:addInput("",nickn)
		player:sendForm(
			Form,
			function(player,res)
				if res==nil then return end
				land_data[landId].settings.nickname=res[1]
				ILAPI.save({0,1,0})
				player:sendModalForm(
					_Tr('gui.general.complete'),
					'Complete.',
					_Tr('gui.general.back'),
					_Tr('gui.general.close'),
					FORM_BACK_LandMgr
				)
			end
		)
		return
	end
	if option==5 then --领地describe
		local desc=ILAPI.GetDescribe(landId)
		if desc=='' then desc='['.._Tr('gui.landmgr.unmodified')..']' end
		local Form = mc.newCustomForm()
		Form:setTitle(_Tr('gui.landdescribe.title'))
		Form:addLabel(_Tr('gui.landdescribe.tip'))
		Form:addInput("",desc)
		player:sendForm(
			Form,
			function(player,res)
				if res==nil then return end
				
				land_data[landId].settings.describe=res[1]
				ILAPI.save({0,1,0})
				player:sendModalForm(
					_Tr('gui.general.complete'),
					'Complete.',
					_Tr('gui.general.back'),
					_Tr('gui.general.close'),
					FORM_BACK_LandMgr
				)
			end
		)
		return
	end
	if option==6 then --领地过户
		player:sendModalForm(
			_Tr('gui.landtransfer.title'),
			_Tr('gui.landtransfer.tip'),
			_Tr('gui.general.yes'),
			_Tr('gui.general.close'),
			function(pl,ids)
				if not(ids) then return end
				PSR_New(
					pl,
					function (player,selected)
						if #selected > 1 then
							SendText(player,_Tr('title.landtransfer.toomanyids'))
							return
						end
					
						local targetXuid=data.name2xuid(selected[1])
						if ILAPI.IsLandOwner(landId,targetXuid) then 
							SendText(player,_Tr('title.landtransfer.canttoown'))
							return
						end
						ILAPI.SetOwner(landId,targetXuid)
					
						player:sendModalForm(
							_Tr('gui.general.complete'),
							_Tr('title.landtransfer.complete','<a>',ILAPI.GetNickname(landId,true),'<b>',selected[1]),
							_Tr('gui.general.back'),
							_Tr('gui.general.close'),
							FORM_BACK_LandMgr
						)
					end
				)
			end
		)
		return
	end
	if option==7 then --重新圈地
		player:sendModalForm(
			_Tr('gui.reselectland.title'),
			_Tr('gui.reselectland.tip'),
			_Tr('gui.general.yes'),
			_Tr('gui.general.cancel'),
			function(player,result)
				if result==nil or not(result) then return end
				local xuid = player.xuid

				MEM[xuid].reselectLand = { id = landId }
				RSR_New(player,function(player,res)
					MEM[xuid].keepingTitle = {
						_Tr('title.selectland.complete1'),
						_Tr('title.selectland.complete2','<a>',cfg.features.selection.tool_name,'<b>','land ok')
					}
					MEM[xuid].reselectLand.range = res
				end)
			end
		)
		return
	end
	if option==8 then --删除领地
		local cubeInfo = CubeGetInfo(VecMap[landId].a,VecMap[landId].b)
		local value = math.modf(CalculatePrice(cubeInfo.length,cubeInfo.width,cubeInfo.height,ILAPI.GetDimension(landId))*cfg.land.refund_rate)
		player:sendModalForm(
			_Tr('gui.delland.title'),
			_Tr('gui.delland.content','<a>',value,'<b>',cfg.economic.currency_name),
			_Tr('gui.general.yes'),
			_Tr('gui.general.cancel'),
			function (player,id)
				if not(id) then return end
				ILAPI.DeleteLand(landId)
				if ILAPI.GetOwner(landId)==xuid then
					Money_Add(player,value)
				end
				player:sendModalForm(
					_Tr('gui.general.complete'),
					'Complete.',
					_Tr('gui.general.back'),
					_Tr('gui.general.close'),
					FORM_BACK_LandMgr
				)
			end
		)
		return
	end
end
function SRCB_land_trust(player,selected)
	
	local xuid = player.xuid
	local landId = MEM[xuid].landId
	local res = MEM[xuid].edittype
	local status_list = {}

	if res==0 then -- add
		for n,ID in pairs(selected) do
			local targetXuid=data.name2xuid(ID)
			status_list[ID] = {}
			if ILAPI.GetOwner(landId)==targetXuid then
				status_list[ID] = _Tr('gui.landtrust.fail.cantaddown')
				goto CONTINUE_ADDTRUST
			end
			if ILAPI.AddTrust(landId,targetXuid)==false then
				status_list[ID] = _Tr('gui.landtrust.fail.alreadyexists')
			else
				status_list[ID] = _Tr('gui.landtrust.addsuccess')
			end
			:: CONTINUE_ADDTRUST ::
		end
	end
	if res==1 then -- rm
		for n,ID in pairs(selected) do
			local targetXuid=data.name2xuid(ID)
			ILAPI.RemoveTrust(landId,targetXuid)
			status_list[ID] = {}
			status_list[ID] = _Tr('gui.landtrust.rmsuccess')
		end
	end

	local text = "Completed."
	for i,v in pairs(status_list) do
		text = text..'\n'..i..' => '..v
	end
	player:sendModalForm(
		_Tr('gui.general.complete'),
		text,
		_Tr('gui.general.back'),
		_Tr('gui.general.close'),
		FORM_BACK_LandMgr
	)
end
function GUI_LMgr(player,targetXuid)
	local xuid = player.xuid
	local ownerXuid

	if targetXuid==nil then
		ownerXuid = xuid
	else
		ownerXuid = targetXuid
	end

	local landlst = ILAPI.GetPlayerLands(ownerXuid)
	if #landlst==0 then
		SendText(player,_Tr('title.landmgr.failed'))
		return
	end
	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.landmgr.title'))
	Form:setContent(_Tr('gui.landmgr.select'))
	for n,landId in pairs(landlst) do
		Form:addButton(ILAPI.GetNickname(landId,true),'textures/ui/worldsIcon')
	end
	MEM[xuid].enableBackButton = 0
	player:sendForm(Form,function(pl,id) -- callback
		if id==nil then return end
		local xuid = pl.xuid
		MEM[xuid].landId = landlst[id+1]
		GUI_FastMgr(pl)
	end)
end
function GUI_OPLMgr(player)

	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.oplandmgr.landmgr.title'))
	Form:setContent(_Tr('gui.oplandmgr.landmgr.tip'))
	Form:addButton(_Tr('gui.oplandmgr.mgrtype.land'),'textures/ui/icon_book_writable')
	Form:addButton(_Tr('gui.oplandmgr.mgrtype.listener'),'textures/ui/icon_bookshelf')
	Form:addButton(_Tr('gui.general.close'))
	player:sendForm(Form,function(player,id)
		if id==nil then return end
		if id==0 then -- Manage lands
			local Form = mc.newSimpleForm()
			Form:setTitle(_Tr('gui.oplandmgr.title'))
			Form:setContent(_Tr('gui.oplandmgr.landmgr.tip'))
			Form:addButton(_Tr('gui.oplandmgr.landmgr.byplayer'),'textures/ui/icon_multiplayer')
			Form:addButton(_Tr('gui.oplandmgr.landmgr.teleport'),'textures/ui/icon_blackfriday')
			Form:addButton(_Tr('gui.oplandmgr.landmgr.byfeet'),'textures/ui/icon_sign')
			Form:addButton(_Tr('gui.general.back'))
			player:sendForm(
				Form,
				function(player,mode)
					if mode==nil then return end
				
					local xuid = player.xuid
					if mode==0 then -- 按玩家
						PSR_New(player,function(pl,selected) 
							if #selected>1 then
								SendText(pl,_Tr('talk.tomany'))
								return
							end
							local thisXid = data.name2xuid(selected[1])
							GUI_LMgr(pl,thisXid)
						end)
					end
					if mode==1 then -- 传送
						local Form = mc.newSimpleForm()
						Form:setTitle(_Tr('gui.oplandmgr.landmgr.landtp.title'))
						Form:setContent(_Tr('gui.oplandmgr.landmgr.landtp.tip'))
						local landlst = ILAPI.GetAllLands()
						for num,landId in pairs(landlst) do
							local ownerId = ILAPI.GetOwner(landId)
							if ownerId~='?' then ownerId=data.xuid2name(ownerId) end
							Form:addButton(
								_Tr('gui.oplandmgr.landmgr.button',
									'<a>',ILAPI.GetNickname(landId,true),
									'<b>',ownerId
								),
								'textures/ui/worldsIcon'
							)
						end
						player:sendForm(Form,function(pl,id) -- callback
							if id==nil then return end
							local landId = landlst[id+1]
							if ILAPI.Teleport(pl,landId) then
								SendText(pl,_Tr('title.landtp.success'))
							else
								SendText(pl,_Tr('title.landtp.fail.danger'))
							end
						end)
					end
					if mode==2 then -- 脚下
						local landId = ILAPI.PosGetLand(FixBp(player.blockPos))
						if landId==-1 then
							SendText(player,_Tr('gui.oplandmgr.landmgr.byfeet.errbynull'))
							return
						end
						MEM[xuid].landId = landId
						GUI_FastMgr(player,true)
					end
					if mode==3 then -- 返回
						FORM_BACK_LandOPMgr(player,true)
					end
				
				end
			)
		end
		if id==1 then -- Manage Listener
			local Form = mc.newCustomForm()
			Form:setTitle(_Tr('gui.listenmgr.title'))
			Form:addLabel(_Tr('gui.listenmgr.tip'))
			Form:addSwitch('onDestroyBlock',not(ILAPI.IsDisabled('onDestroyBlock')))
			Form:addSwitch('onPlaceBlock',not(ILAPI.IsDisabled('onPlaceBlock')))
			Form:addSwitch('onUseItemOn',not(ILAPI.IsDisabled('onUseItemOn')))
			Form:addSwitch('onAttack',not(ILAPI.IsDisabled('onAttack')))
			Form:addSwitch('onExplode',not(ILAPI.IsDisabled('onExplode')))
			Form:addSwitch('onBedExplode',not(ILAPI.IsDisabled('onBedExplode')))
			Form:addSwitch('onRespawnAnchorExplode',not(ILAPI.IsDisabled('onRespawnAnchorExplode')))
			Form:addSwitch('onTakeItem',not(ILAPI.IsDisabled('onTakeItem')))
			Form:addSwitch('onDropItem',not(ILAPI.IsDisabled('onDropItem')))
			Form:addSwitch('onBlockInteracted',not(ILAPI.IsDisabled('onBlockInteracted')))
			Form:addSwitch('onUseFrameBlock',not(ILAPI.IsDisabled('onUseFrameBlock')))
			Form:addSwitch('onSpawnProjectile',not(ILAPI.IsDisabled('onSpawnProjectile')))
			Form:addSwitch('onFireworkShootWithCrossbow',not(ILAPI.IsDisabled('onFireworkShootWithCrossbow')))
			Form:addSwitch('onStepOnPressurePlate',not(ILAPI.IsDisabled('onStepOnPressurePlate')))
			Form:addSwitch('onRide',not(ILAPI.IsDisabled('onRide')))
			Form:addSwitch('onWitherBossDestroy',not(ILAPI.IsDisabled('onWitherBossDestroy')))
			Form:addSwitch('onFarmLandDecay',not(ILAPI.IsDisabled('onFarmLandDecay')))
			Form:addSwitch('onPistonPush',not(ILAPI.IsDisabled('onPistonPush')))
			Form:addSwitch('onFireSpread',not(ILAPI.IsDisabled('onFireSpread')))
			Form:addSwitch('onChangeArmorStand',not(ILAPI.IsDisabled('onChangeArmorStand')))
			Form:addSwitch('onEat',not(ILAPI.IsDisabled('onEat')))

			player:sendForm(
				Form,
				function(player,res)
					if res==nil then return end
				
					cfg.features.disabled_listener = {}
					local dbl = cfg.features.disabled_listener
					if not(res[1]) then dbl[#dbl+1] = "onDestroyBlock" end
					if not(res[2]) then dbl[#dbl+1] = "onPlaceBlock" end
					if not(res[3]) then dbl[#dbl+1] = "onUseItemOn" end
					if not(res[4]) then dbl[#dbl+1] = "onAttack" end
					if not(res[5]) then dbl[#dbl+1] = "onExplode" end
					if not(res[6]) then dbl[#dbl+1] = "onBedExplode" end
					if not(res[7]) then dbl[#dbl+1] = "onRespawnAnchorExplode" end
					if not(res[8]) then dbl[#dbl+1] = "onTakeItem" end
					if not(res[9]) then dbl[#dbl+1] = "onDropItem" end
					if not(res[10]) then dbl[#dbl+1] = "onBlockInteracted" end
					if not(res[11]) then dbl[#dbl+1] = "onUseFrameBlock" end
					if not(res[12]) then dbl[#dbl+1] = "onSpawnProjectile" end
					if not(res[13]) then dbl[#dbl+1] = "onFireworkShootWithCrossbow" end
					if not(res[14]) then dbl[#dbl+1] = "onStepOnPressurePlate" end
					if not(res[15]) then dbl[#dbl+1] = "onRide" end
					if not(res[16]) then dbl[#dbl+1] = "onWitherBossDestroy" end
					if not(res[17]) then dbl[#dbl+1] = "onFarmLandDecay" end
					if not(res[18]) then dbl[#dbl+1] = "onPistonPush" end
					if not(res[19]) then dbl[#dbl+1] = "onFireSpread" end
					if not(res[20]) then dbl[#dbl+1] = "onChangeArmorStand" end
					if not(res[21]) then dbl[#dbl+1] = "onEat" end
					
					BuildListenerMap()
					ILAPI.save({1,0,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						"Complete.",
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						FORM_BACK_LandOPMgr
					)
				
				end
			)
		end
	end)

end
function GUI_FastMgr(player,isOP)
	local xuid=player.xuid
	local thelands=ILAPI.GetPlayerLands(xuid)
	if #thelands==0 and isOP==nil then
		SendText(player,_Tr('title.landmgr.failed'));return
	end

	local landId = MEM[xuid].landId
	if land_data[landId]==nil then
		GUI_LMgr(player)
		return
	end

	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.fastlmgr.title'))
	if isOP==nil then
		Form:setContent(_Tr('gui.fastlmgr.content','<a>',ILAPI.GetNickname(landId,true)))
	else
		Form:setContent(_Tr('gui.fastlmgr.operator'))
	end
	Form:addButton(_Tr('gui.landmgr.options.landinfo'))
	Form:addButton(_Tr('gui.landmgr.options.landcfg'))
	Form:addButton(_Tr('gui.landmgr.options.landperm'))
	Form:addButton(_Tr('gui.landmgr.options.landtrust'))
	Form:addButton(_Tr('gui.landmgr.options.landtag'))
	Form:addButton(_Tr('gui.landmgr.options.landdescribe'))
	Form:addButton(_Tr('gui.landmgr.options.landtransfer'))
	Form:addButton(_Tr('gui.landmgr.options.reselectrange'))
	Form:addButton(_Tr('gui.landmgr.options.delland'))
	Form:addButton(_Tr('gui.general.close'),'textures/ui/icon_import')
	player:sendForm(
		Form,
		function(player,id)
			if id==nil then return end
			if id~=9 then
				Handler_LandCfg(player,landId,id)
			end
		end
	)
end

-- Selector
function PSR_New(player,callback,customlist) -- player selector
	
	-- get player list
	local pl_list = {}
	local forTol
	if cfg.features.player_selector.include_offline_players then
		forTol = land_owners
	else
		forTol = MEM
	end
	for xuid,lds in pairs(forTol) do
		pl_list[#pl_list+1] = data.xuid2name(xuid)
	end

	-- set TRS
	local xuid = player.xuid
	MEM[xuid].psr = {
		playerList = {},
		cbfunc = callback,
		nowpage = 1,
		filter = ""
	}

	local perpage = cfg.features.player_selector.items_perpage
	if customlist~=nil then
		MEM[xuid].psr.playerList = ToPages(customlist,perpage)
	else
		MEM[xuid].psr.playerList = ToPages(pl_list,perpage)
	end

	-- call
	PSR_Callback(player,'#')

end
function PSR_Callback(player,data)
	if data==nil then
		MEM[player.xuid].psr=nil
		return
	end
	
	-- get data
	local xuid = player.xuid
	local psrdata = MEM[xuid].psr

	local function buildPage(num)
		local tmp = {}
		for i=1,num do
			tmp[i]=_Tr('gui.playerselector.num','<a>',i)
		end
		return tmp
	end

	local perpage = cfg.features.player_selector.items_perpage
	local maxpage = #psrdata.playerList
	local rawList = CloneTable(psrdata.playerList[psrdata.nowpage])

	if type(data)=='table' then
		local selected = {}

		-- refresh page
		local npg = data[#data] + 1 -- custom page
		if npg~=psrdata.nowpage and npg<=maxpage then
			psrdata.nowpage = npg
			rawList = CloneTable(psrdata.playerList[npg])
			goto JUMPOUT_PSR_OTHER
		end

		-- create filter
		if data[1]~='' then
			local findTarget = string.lower(data[1])
			local tmpList = {}
			for num,pagelist in pairs(psrdata.playerList) do
				for page,name in pairs(pagelist) do
					if string.find(string.lower(name),findTarget) ~= nil then
						tmpList[#tmpList+1] = name
					end
				end
			end
			local tableList = ToPages(tmpList,perpage)
			if psrdata.nowpage>#tableList then
				psrdata.nowpage = 1
			end
			if tableList[psrdata.nowpage]==nil then
				rawList = {}
				maxpage = 1
			else
				rawList = tableList[psrdata.nowpage]
				maxpage = #tableList
			end
			if psrdata.filter~=data[1] then
				psrdata.filter = data[1]
				goto JUMPOUT_PSR_OTHER
			end
		end
		psrdata.filter = data[1]

		-- gen selects
		for num,key in pairs(data) do
			if num~=1 and num~=#data and key==true then
				selected[#selected+1] = rawList[num-1]
			end
		end
		if next(selected) ~= nil then
			psrdata.cbfunc(player,selected)
			psrdata=nil
			return
		end

		:: JUMPOUT_PSR_OTHER ::
	end

	-- build form
	local Form = mc.newCustomForm()
	Form:setTitle(_Tr('gui.playerselector.title'))
	Form:addLabel(_Tr('gui.playerselector.search.tip'))
	Form:addLabel(_Tr('gui.playerselector.search.tip2'))
	Form:addInput(_Tr('gui.playerselector.search.type'),_Tr('gui.playerselector.search.ph'),psrdata.filter)
	Form:addLabel(
		_Tr('gui.playerselector.pages',
			'<a>',psrdata.nowpage,
			'<b>',maxpage,
			'<c>',#rawList
		)
	)
	for n,plname in pairs(rawList) do
		Form:addSwitch(plname,false)
	end
	Form:addStepSlider(_Tr('gui.playerselector.jumpto'),buildPage(maxpage),psrdata.nowpage-1)
	player:sendForm(Form,PSR_Callback)
end
function RSR_New(player,callback) -- world range selector
	local xuid = player.xuid
	MEM[xuid].rsr = {
		step = 0,
		posA = {},
		posB = {},
		dimid = -1,
		dimension = '',
		cbfunc = callback
	}
	MEM[xuid].keepingTitle = {
		_Tr('title.rangeselector.inmode'),
		_Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','A')
	}
	RSR_Do(player)
end
function RSR_Do(player,pos)
	local xuid = player.xuid
	local dimid = player.pos.dimid
	if MEM[xuid].rsr.step == 0 then
		player:sendModalForm(
			_Tr('title.rangeselector.dimension.chose'),
			_Tr('title.rangeselector.dimension.tip'),
			'3D',
			'2D',
			function (player,res)
				MEM[xuid].rsr.step = 1
				if (res and not(cfg.land.bought.three_dimension.enable)) or (not(res) and not(cfg.land.bought.two_dimension.enable)) then
					SendText(player,_Tr('title.rangeselector.dimension.blocked'))
					RSR_Delete(player)
					if MEM[xuid].newLand~=nil then MEM[xuid].newLand=nil end
					if MEM[xuid].reselectLand~=nil then MEM[xuid].reselectLand=nil end
					return
				end
				if res then
					SendText(player,_Tr('title.rangeselector.dimension.chosed','<a>','3D'))
					MEM[xuid].rsr.dimension = '3D'
				else
					SendText(player,_Tr('title.rangeselector.dimension.chosed','<a>','2D'))
					MEM[xuid].rsr.dimension = '2D'
				end
			end
		)
		return
	end
	if MEM[xuid].rsr.step == 1 then
		if FoundValueInList(cfg.features.selection.disable_dimension,dimid)~=-1 then
			SendText(player,_Tr('title.rangeselector.fail.dimblocked'))
			return
		end
		MEM[xuid].rsr.posA = pos
		if MEM[xuid].rsr.dimension=='2D' then
			MEM[xuid].rsr.posA.y = minY
		end
		MEM[xuid].rsr.dimid = dimid
		MEM[xuid].rsr.step = 2
		MEM[xuid].keepingTitle[2] = _Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','B')
		SendText(
			player,
			_Tr('title.rangeselector.pointed',
				'<a>','A',
				'<b>',ToStrDim(dimid),
				'<c>',pos.x,'<d>',pos.y,'<e>',pos.z
			)
		)
		return
	end
	if MEM[xuid].rsr.step == 2 then
		if MEM[xuid].rsr.dimid ~= dimid then
			SendText(player,_Tr('title.rangeselector.fail.dimdiff'))
			return
		end

		local cubeInfo = CubeGetInfo(MEM[xuid].rsr.posA,pos)

		--- Range Check <S>
		local isOk = true
		if cubeInfo.square<cfg.land.bought.square_range[1] and not(ILAPI.IsLandOperator(xuid)) and isOk then
			isOk = false
			SendText(player,_Tr('title.rangeselector.fail.toosmall')) -- here.
		end
		if cubeInfo.square>cfg.land.bought.square_range[2] and not(ILAPI.IsLandOperator(xuid)) and isOk then
			isOk = false
			SendText(player,_Tr('title.rangeselector.fail.toobig'))
		end
		if cubeInfo.height<2 and MEM[xuid].rsr.dimension == '3D' and isOk then
			isOk = false
			SendText(player,_Tr('title.rangeselector.fail.toolow'))
		end
		local chk
		if MEM[xuid].reselectLand~=nil then -- can collision own if reselecting.
			chk = ILAPI.IsLandCollision(MEM[xuid].rsr.posA,pos,dimid,{MEM[xuid].reselectLand.id})
		else
			chk = ILAPI.IsLandCollision(MEM[xuid].rsr.posA,pos,dimid)
		end
		if not(chk.status) and isOk then
			isOk = false
			SendText(player,_Tr('title.rangeselector.fail.collision','<a>',chk.id,'<b>',PosToText(chk.pos)))
		end
		if not isOk then
			MEM[xuid].rsr.step = 1
			MEM[xuid].keepingTitle[2] = _Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','A')
			return
		end
		--- Range Check <E>

		MEM[xuid].rsr.posB = pos
		if MEM[xuid].rsr.dimension=='2D' then
			MEM[xuid].rsr.posB.y = maxY
		end
		MEM[xuid].rsr.posA,MEM[xuid].rsr.posB = SortPos(MEM[xuid].rsr.posA,MEM[xuid].rsr.posB)
		MEM[xuid].rsr.step = 3
		MEM[xuid].keepingTitle = nil
		local edge
		if MEM[xuid].rsr.dimension == '3D' then
			edge = CubeToEdge(MEM[xuid].rsr.posA,MEM[xuid].rsr.posB)
		else
			edge = CubeToEdge_2D(MEM[xuid].rsr.posA,MEM[xuid].rsr.posB)
		end
		if #edge < cfg.features.particles.max_amount then
			MEM[xuid].particles = edge
		else
			SendText(player,_Tr('title.rangeselector.largeparticle'))
		end

		SendText(
			player,
			_Tr('title.rangeselector.pointed',
				'<a>','B',
				'<b>',ToStrDim(dimid),
				'<c>',pos.x,'<d>',pos.y,'<e>',pos.z
			)
		)
		local cb = MEM[xuid].rsr.cbfunc
		cb(player,{posA=MEM[xuid].rsr.posA,posB=MEM[xuid].rsr.posB,dimid=MEM[xuid].rsr.dimid,dimension=MEM[xuid].rsr.dimension})
		return
	end
	if MEM[xuid].rsr.step == 3 then
		-- what the fxxk handle...
		if MEM[xuid].newLand~=nil then
			player:runcmd("land buy")
		end
		if MEM[xuid].reselectLand~=nil then
			player:runcmd("land ok")
		end
		return
	end
end
function RSR_Delete(player)
	local xuid = player.xuid
	MEM[xuid].rsr = nil
	MEM[xuid].keepingTitle = nil
	MEM[xuid].particles = nil
end

-- Selector Helper
function ToPages(list,perpage)
	local rtn = {}
	for n,pl in pairs(list) do
		local num = math.ceil(n/perpage)
		if rtn[num]==nil then
			rtn[num] = {}
		end
		rtn[num][#rtn[num]+1] = pl
	end
	return rtn
end
function MakeShortILD(landId)
	return string.sub(landId,0,16) .. '....'
end

-- +-+ +-+ +-+ +-+ +-+
-- |I| |L| |A| |P| |I|
-- +-+ +-+ +-+ +-+ +-+
-- Exported Apis Here!

-- [[ KERNEL ]]
function ILAPI.CreateLand(xuid,startpos,endpos,dimid)
	local landId
	while true do
		landId = GenGUID()
		if land_data[landId]==nil then break end
	end

	local posA,posB = SortPos(startpos,endpos)

	-- LandData Templete
	land_data[landId]={
		settings = {
			share = {},
			tpoint = {
				startpos.x,
				startpos.y+1,
				startpos.z
			},
			nickname = '',
			describe = '',
			signtome = true,
			signtother = true,
			signbuttom = true,
			ev_explode = false,
			ev_farmland_decay = false,
			ev_piston_push = false,
			ev_fire_spread = false
		},
		range = {
			start_position = {
				posA.x,
				posA.y,
				posA.z
			},
			end_position = {
				posB.x,
				posB.y,
				posB.z
			},
			dimid = dimid
		},
		permissions = {}
	}

	local perm = land_data[landId].permissions
	perm.allow_destroy=false
	perm.allow_entity_destroy=false
	perm.allow_place=false
	perm.allow_attack_player=false
	perm.allow_attack_animal=false
	perm.allow_attack_mobs=true
	perm.allow_open_chest=false
	perm.allow_pickupitem=false
	perm.allow_dropitem=true
	perm.use_anvil = false
	perm.use_barrel = false
	perm.use_beacon = false
	perm.use_bed = false
	perm.use_bell = false
	perm.use_blast_furnace = false
	perm.use_brewing_stand = false
	perm.use_campfire = false
	perm.use_firegen = false
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
	perm.use_armor_stand=false
	perm.eat=false
	perm.allow_throw_potion=false
	perm.allow_ride_entity=false
	perm.allow_ride_trans=false
	perm.allow_shoot=false
	perm.useitem=false

	-- Write data
	if land_owners[xuid]==nil then -- ilapi
		land_owners[xuid]={}
	end

	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	ILAPI.save({0,1,1})
	UpdateChunk(landId,'add')
	UpdateLandPosMap(landId,'add')
	UpdateLandOwnersMap(landId)
	UpdateLandTrustMap(landId)
	UpdateLandEdgeMap(landId,'add')
	return landId
end
function ILAPI.DeleteLand(landId)
	local owner=ILAPI.GetOwner(landId)
	if owner~='?' then
		table.remove(land_owners[owner],FoundValueInList(land_owners[owner],landId))
	end
	UpdateChunk(landId,'del')
	UpdateLandPosMap(landId,'del')
	UpdateLandEdgeMap(landId,'del')
	land_data[landId]=nil
	ILAPI.save({0,1,1})
	return true
end
function ILAPI.PosGetLand(vec4)
	local Cx,Cz = ToChunkPos(vec4)
	local dimid = vec4.dimid
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		for n,landId in pairs(ChunkMap[dimid][Cx][Cz]) do
			if dimid==land_data[landId].range.dimid and CubeHadPos(vec4,VecMap[landId].a,VecMap[landId].b) then
				return landId
			end
		end
	end
	return -1
end
function ILAPI.GetChunk(vec2,dimid)
	local Cx,Cz = ToChunkPos(vec2)
	if ChunkMap[dimid][Cx]~=nil and ChunkMap[dimid][Cx][Cz]~=nil then
		return CloneTable(ChunkMap[dimid][Cx][Cz])
	end
	return -1
end 
function ILAPI.GetAllLands()
	local lst = {}
	for id,v in pairs(land_data) do
		lst[#lst+1] = id
	end
	return lst
end
function ILAPI.CheckPerm(landId,perm)
	return CloneTable(land_data[landId].permissions[perm])
end
function ILAPI.CheckSetting(landId,cfgname)
	if cfgname=='share' or cfgname=='tpoint' or cfgname=='nickname' or cfgname=='describe' then
		return nil
	end
	return CloneTable(land_data[landId].settings[cfgname])
end
function ILAPI.GetRange(landId)
	return { VecMap[landId].a,VecMap[landId].b,land_data[landId].range.dimid }
end
function ILAPI.GetEdge(landId,dimtype)
	if dimtype=='2D' then
		return CloneTable(EdgeMap[landId].D2D)
	end
	if dimtype=='3D' then
		return CloneTable(EdgeMap[landId].D3D)
	end
end
function ILAPI.GetDimension(landId)
	if land_data[landId].range.start_position[2]==minY and land_data[landId].range.end_position[2]==maxY then
		return '2D'
	else
		return '3D'
	end
end
function ILAPI.GetName(landId)
	return CloneTable(land_data[landId].settings.nickname)
end
function ILAPI.GetDescribe(landId)
	return CloneTable(land_data[landId].settings.describe)
end
function ILAPI.GetOwner(landId)
	for i,v in pairs(land_owners) do
		if FoundValueInList(v,landId)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI.GetPoint(landId)
	local i = CloneTable(land_data[landId].settings.tpoint)
	i[4] = land_data[landId].range.dimid
	return ArrayToPos(i)
end
function ILAPI.Teleport(player,landId) -- can given xuid to `player`
	local pl
	if type(player)=='string' then
		pl = mc.getPlayer(player)
	else
		pl = player
	end
	if land_data[landId]==nil then
		return false
	end
	local pos = ILAPI.GetPoint(landId)
	local finalPos
	if pl.gameMode==1 then
		pl:teleport(pos.x,pos.y,pos.z,pos.dimid)
		return true
	end
	local bltypelist = {}
	local footholds = {}
	for i=minY,maxY do -- get all type
		local bl = mc.getBlock(pos.x,i,pos.z,pos.dimid)
		bltypelist[i] = bl.type
	end
	local ct_block = {'minecraft:air','minecraft:lava','minecraft:flowing_lava'}
	for i,type in pairs(bltypelist) do
		if FoundValueInList(ct_block,type)==-1 and bltypelist[i+1]==ct_block[1] and bltypelist[i+2]==ct_block[1] then
			footholds[#footholds+1] = i
		end
	end
	if #footholds==0 then
		return false
	end
	local recentY = footholds[1]
	for i,y in pairs(footholds) do
		if math.abs(pos.y-y)<math.abs(pos.y-recentY) then
			recentY = y
		end
	end
	finalPos = { x=pos.x,y=recentY,z=pos.z,dimid=pos.dimid }
	if ILAPI.PosGetLand(finalPos)~=landId then
		return false
	end
	pl:teleport(finalPos.x,finalPos.y,finalPos.z,finalPos.dimid)
	return true
end
-- [[ INFORMATION => PLAYER ]]
function ILAPI.GetPlayerLands(xuid)
	return CloneTable(land_owners[xuid])
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
function ILAPI.GetAllTrustedLand(xuid)
	local trusted = {}
	for landId,data in pairs(land_data) do
		if ILAPI.IsPlayerTrusted(landId,xuid) then
			trusted[#trusted+1]=landId
		end
	end
	return trusted
end
-- [[ CONFIGURE ]]
function ILAPI.UpdatePermission(landId,perm,value)
	if land_data[landId]==nil or land_data[landId].permissions[perm]==nil or (value~=true and value~=false) then
		return false
	end
	land_data[landId].permissions[perm]=value
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.UpdateSetting(landId,cfgname,value)
	if land_data[landId]==nil or land_data[landId].settings[cfgname]==nil or value==nil then
		return false
	end
	if cfgname=='share' then
		return false
	end
	land_data[landId].settings[cfgname]=value
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.AddTrust(landId,xuid)
	local shareList = land_data[landId].settings.share
	if ILAPI.IsPlayerTrusted(landId,xuid) then
		return false
	end
	shareList[#shareList+1]=xuid
	UpdateLandTrustMap(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.RemoveTrust(landId,xuid)
	local shareList = land_data[landId].settings.share
	table.remove(shareList,FoundValueInList(shareList,xuid))
	UpdateLandTrustMap(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.SetOwner(landId,xuid)
	local ownerXuid = ILAPI.GetOwner(landId)
	if ownerXuid ~= '?' then
		table.remove(land_owners[ownerXuid],FoundValueInList(land_owners[ownerXuid],landId))
	end
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	UpdateLandOwnersMap(landId)
	ILAPI.save({0,0,1})
	return true
end
-- [[ PLUGIN ]]
function ILAPI.GetMoneyProtocol()
	local m = cfg.economic.protocol
	if m~="llmoney" and m~="scoreboard" then
		return nil
	end
	return m
end
function ILAPI.GetLanguage()
	return cfg.plugin.language
end
function ILAPI.GetChunkSide()
	return cfg.features.chunk_side
end
function ILAPI.GetVersion()
	return Plugin.numver
end
-- [[ UNEXPORT FUNCTIONS ]]
function ILAPI.save(mode) -- {config,data,owners}
	if mode[1] == 1 then
		file.writeTo(DATA_PATH..'config.json',JSON.encode(cfg,{indent=true}))
	end
	if mode[2] == 1 then
		file.writeTo(DATA_PATH..'data.json',JSON.encode(land_data))
	end
	if mode[3] == 1 then
		local tmpowners = CloneTable(land_owners)
		for xuid,landIds in pairs(wrong_landowners) do
			tmpowners[xuid] = landIds
		end
		file.writeTo(DATA_PATH..'owners.json',JSON.encode(tmpowners,{indent=true}))
	end
end
function ILAPI.CanControl(mode,name)
	-- mode [0]UseItem [1]onBlockInteracted [2]items [3]attack
	if CanCtlMap[mode][name]==nil then
		return false
	else
		return true
	end
end
function ILAPI.GetNickname(landId,returnIdIfNameEmpty)
	local n = land_data[landId].settings.nickname
	if n=='' then
		n='<'.._Tr('gui.landmgr.unnamed')..'>'
		if returnIdIfNameEmpty then
			n=n..' '..MakeShortILD(landId)
		end
	end
	return n
end
function ILAPI.IsDisabled(listener)
	if ListenerDisabled[listener]~=nil then
		return true
	end
	return false
end
function ILAPI.GetLanguageList(type) -- [0] langs from disk [1] online
	-- [0] return list (0:zh_CN....)
	-- [1] return table (official:....)
	if type == 0 then
		local langs = {}
		for n,file in pairs(file.getFilesList(DATA_PATH..'lang\\')) do
			local tmp = StrSplit(file,'.')
			if tmp[2]=='json' then
				langs[#langs+1] = tmp[1]
			end
		end
		return langs
	end
	if type == 1 then
		local server = GetLink()
		if server ~= false then
			local raw = network.httpGetSync(server..'/languages/repo.json')
			if raw.status==200 then
				return JSON.decode(raw.data)
			else
				ERROR(_Tr('console.getonline.failbycode','<a>',raw.status))
				return false
			end
		else
			ERROR(_Tr('console.getonline.failed'))
			return false
		end
	end
end
function ILAPI.IsLandCollision(newposA,newposB,newDimid,ignoreList) -- 领地冲突判断
	local edge = CubeToEdge(newposA,newposB)
	local ignores = {} -- 建立反表提升查询性能
	if ignoreList~=nil then
		for key, value in pairs(ignoreList) do
			ignores[value] = 1
		end
	end
	for i=1,#edge do
		edge[i].dimid=newDimid
		local tryLand = ILAPI.PosGetLand(edge[i])
		if tryLand~=-1 and ignores[tryLand]==nil then
			return {
				status = false,
				pos = edge[i],
				id = tryLand
			}
		end
	end
	for landId,val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dimid==newDimid then
			edge = EdgeMap[landId].D3D
			if ignores[landId]==nil then
				for i=1,#edge do
					if CubeHadPos(edge[i],newposA,newposB)==true then
						return {
							status = false,
							pos = edge[i],
							id = landId
						}
					end
				end
			end
		end
	end
	return { status = true }
end

-- +-+ +-+ +-+   +-+ +-+ +-+
-- |T| |H| |E|   |E| |N| |D|
-- +-+ +-+ +-+   +-+ +-+ +-+

-- feature function
function _Tr(a,...)
	if DEV_MODE and LangPack[a]==nil then
		ERROR('Translation not found: '..a)
	end
	local result = CloneTable(LangPack[a])
	local args = {...}
	local thisWord = false
	for n,word in pairs(args) do
		if thisWord==true then
			result = string.gsub(result,args[n-1],word)
		end
		thisWord = not(thisWord)
	end
	return result
end
function Money_Add(player,value)
	local ptc = cfg.economic.protocol
	if ptc=='scoreboard' then
		player:addScore(cfg.economic.scoreboard_objname,value);return
	end
	if ptc=='llmoney' then
		money.add(player.xuid,value);return
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function Money_Del(player,value)
	local ptc = cfg.economic.protocol
	if ptc=='scoreboard' then
		player:setScore(cfg.economic.scoreboard_objname,player:getScore(cfg.economic.scoreboard_objname)-value)
		return
	end
	if ptc=='llmoney' then
		money.reduce(player.xuid,value)
		return
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function Money_Get(player)
	local ptc = cfg.economic.protocol
	if ptc=='scoreboard' then
		return player:getScore(cfg.economic.scoreboard_objname)
	end
	if ptc=='llmoney' then
		return money.get(player.xuid)
	end
	ERROR(_Tr('console.error.money.protocol','<a>',ptc))
end
function SendTitle(player,title,subtitle,times)
	local name = player.realName
	if times == nil then
		mc.runcmdEx('titleraw "' .. name .. '" times 20 25 20')
	else
		mc.runcmdEx('titleraw "' .. name .. '" times '..times[1]..' '..times[2]..' '..times[3])
	end
	if subtitle~=nil then
		mc.runcmdEx('titleraw "'..name..'" subtitle {"rawtext": [{"text":"'..subtitle..'"}]}')
	end
	mc.runcmdEx('titleraw "'..name..'" title {"rawtext": [{"text":"'..title..'"}]}')
end
function SendText(player,text,mode)
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
function CubeHadPos(pos,posA,posB) -- 3D
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y) then
			if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
				return true
			end
		end
	end
	return false
end
function CubeHadPos_2D(pos,posA,posB) -- 2D
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
			return true
		end
	end
	return false
end
function CalculatePrice(length,width,height,dimension)
	local price=0
	if dimension=='3D' then
		local t=cfg.land.bought.three_dimension.price
		if cfg.land.bought.three_dimension.calculate_method == 'm-1' then
			price=length*width*t[1]+height*t[2]
		end
		if cfg.land.bought.three_dimension.calculate_method == 'm-2' then
			price=length*width*height*t[1]
		end
		if cfg.land.bought.three_dimension.calculate_method == 'm-3' then
			price=length*width*t[1]
		end
	end
	if dimension=='2D' then
		local t=cfg.land.bought.two_dimension.price
		if cfg.land.bought.two_dimension.calculate_method == 'd-1' then
			price=length*width*t[1]
		end
	end
	return math.modf(price*(cfg.land.bought.discount))
end
function ToChunkPos(pos)
	local p = cfg.features.chunk_side
	return math.floor(pos.x/p),math.floor(pos.z/p)
end
function SortPos(posA,posB)
	local A = posA
	local B = posB
	if A.x>B.x then A.x,B.x = B.x,A.x end
	if A.y>B.y then A.y,B.y = B.y,A.y end
	if A.z>B.z then A.z,B.z = B.z,A.z end
	return A,B
end
function GenGUID()
	local guid = system.randomGuid()
    return string.format('%s-%s-%s-%s-%s',
        string.sub(guid,1,8),
        string.sub(guid,9,12),
        string.sub(guid,13,16),
        string.sub(guid,17,20),
        string.sub(guid,21,32)
    )
end
function FixBp(pos)
	-- pos.y=pos.y-1
	return pos
end
function ToStrDim(a)
	if a==0 then return _Tr('talk.dim.zero') end
	if a==1 then return _Tr('talk.dim.one') end
	if a==2 then return _Tr('talk.dim.two') end
	return _Tr('talk.dim.other')
end
function TraverseAABB(AAbb,aaBB,did)
	local posA,posB = SortPos(AAbb,aaBB)
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
function ChkNil(val)
	return (val == nil)
end
function ChkNil_X2(val,val2)
	return (val == nil) or (val2 == nil)
end
function EntityGetType(type)
	if type=='minecraft:player' then
		return 0
	end
	if CanCtlMap[4].animals[type]~=nil then
		return 1
	end
	if CanCtlMap[4].mobs[type]~=nil then
		return 2
	end
	return 0
end
function IsPosSafe(pos)
	local posA = {x=pos.x+1,y=pos.y+1,z=pos.z+1,dimid=pos.dimid}
	local posB = {x=pos.x-1,y=pos.y-1,z=pos.z-1,dimid=pos.dimid}
	for n,sta in pairs(TraverseAABB(posA,posB,pos.dimid)) do
		if sta.y~=pos.y-1 and mc.getBlock(sta.x,sta.y,sta.z,sta.dimid).type~='minecraft:air' then
			return false
		end
	end
	return true
end
function FoundValueInList(list, value)
	for i, nowValue in pairs(list) do
        if nowValue == value then
            return i
        end
    end
    return -1
end
function StrSplit(str,reps) -- [NOTICE] This function from: blog.csdn.net
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function (w)
        table.insert(resultStrList,w)
    end)
    return resultStrList
end
function ArrayToPos(table) -- [x,y,z,d] => {x:x,y:y,z:z,d:d}
	local t={}
	t.x=math.floor(table[1])
	t.y=math.floor(table[2])
	t.z=math.floor(table[3])
	if table[4]~=nil then
		t.dimid=table[4]
	end
		return t
end
function CubeToEdge(spos,epos)
	local edge={}
	local posB,posA = SortPos(spos,epos)
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
function CubeToEdge_2D(spos,epos)
	local edge={}
	local posB,posA = SortPos(spos,epos)
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
function CubeGetInfo(spos,epos)
	local cube = {}
	cube.height = math.abs(spos.y-epos.y) + 1
	cube.length = math.max(math.abs(spos.x-epos.x),math.abs(spos.z-epos.z)) + 1
	cube.width = math.min(math.abs(spos.x-epos.x),math.abs(spos.z-epos.z)) + 1
	cube.square = cube.length*cube.width
	cube.volume = cube.square*cube.height
	return cube
end
function CloneTable(orig) -- [NOTICE] This function from: lua-users.org
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[CloneTable(orig_key)] = CloneTable(orig_value)
        end
        setmetatable(copy, CloneTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
function PosToText(vec3)
	return vec3.x..','..vec3.y..','..vec3.z
end
local function try(func)
	local stat, res = pcall(func[1])
	if not(stat) then
		func[2](res)
	end
	return res
 end
local function catch(err)
	return err[1]
end
function SplicingArray(array,delimiter)
	local result = ''
	local max = #array
	if delimiter==nil then
		delimiter = ''
	end
	for n,res in pairs(array) do
		result = result..res
		if n~=max then
			result = result..delimiter
		end
	end
	return result
end
function GetLink()
	local tokenRaw = network.httpGetSync('https://lxl-cloud.amd.rocks/id.json')
	if tokenRaw.status~=200 then
		return false
	end
	local id = JSON.decode(tokenRaw.data).token
	return Server.link..id..'/iLand'
end

-- [Client] Command Registry
mc.regPlayerCmd(MainCmd,_Tr('command.land'),function(player,args)
	if #args~=0 then
		SendText(player,_Tr('command.error','<a>',args[1]),0)
		return
	end
	local pos = FixBp(player.blockPos)
	local xuid = player.xuid
	local landId = ILAPI.PosGetLand(pos)
	if landId~=-1 and ILAPI.GetOwner(landId)==xuid then
		MEM[xuid].landId=landId
		GUI_FastMgr(player)
	else
		local land_count = tostring(#land_owners[xuid])
		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.fastgde.title'))
		Form:setContent(_Tr('gui.fastgde.content','<a>',land_count))
		Form:addButton(_Tr('gui.fastgde.create'),'textures/ui/icon_iron_pickaxe')
		Form:addButton(_Tr('gui.fastgde.manage'),'textures/ui/confirm')
		Form:addButton(_Tr('gui.fastgde.landtp'),'textures/ui/World')
		Form:addButton(_Tr('gui.general.close'))
		player:sendForm(
			Form,
			function(player,id)
				if id==nil then return end
				if id==0 then
					player:runcmd(MainCmd..' new')
				end
				if id==1 then
					player:runcmd(MainCmd..' gui')
				end
				if id==2 then
					player:runcmd(MainCmd..' tp')
				end
			end
		)
	end
end)
mc.regPlayerCmd(MainCmd..' new',_Tr('command.land_new'),function (player,args)
	local xuid = player.xuid

	if MEM[xuid].reselectLand~=nil then
		SendText('what are u doing?')
		return
	end
	if MEM[xuid].newLand~=nil then
		SendText(player,_Tr('title.getlicense.alreadyexists'))
		return
	end
	if not(ILAPI.IsLandOperator(xuid)) and #land_owners[xuid]>=cfg.land.max_lands then
		SendText(player,_Tr('title.getlicense.limit'))
		return
	end

	MEM[xuid].newLand = {}
	RSR_New(player,function(player,res)
		MEM[xuid].keepingTitle = {
			_Tr('title.selectland.complete1'),
			_Tr('title.selectland.complete2','<a>',cfg.features.selection.tool_name,'<b>','land buy')
		}
		MEM[xuid].newLand.range = res
	end)

end)
mc.regPlayerCmd(MainCmd..' giveup',_Tr('command.land_giveup'),function (player,args)
	local xuid = player.xuid
	if MEM[xuid].newLand~=nil then
		MEM[xuid].newLand = nil
		RSR_Delete(player)
		SendText(player,_Tr('title.giveup.succeed'))
	end
	if MEM[xuid].reselectLand~=nil then
		MEM[xuid].reselectLand = nil
		RSR_Delete(player)
		SendText(player,_Tr('title.reselectland.giveup.succeed'))
	end
end)
mc.regPlayerCmd(MainCmd..' gui',_Tr('command.land_gui'),function (player,args)
	GUI_LMgr(player)
end)
mc.regPlayerCmd(MainCmd..' set',_Tr('command.land_set'),function (player,args)
	local xuid = player.xuid
	if MEM[xuid].rsr ~= nil then
		RSR_Do(player,player.blockPos)
	else
		SendText(player,_Tr('title.rangeselector.fail.outmode'))
	end
end)
mc.regPlayerCmd(MainCmd..' buy',_Tr('command.land_buy'),function (player,args)
	local xuid = player.xuid
	if MEM[xuid].newLand==nil then
		SendText(player,_Tr('talk.invalidaction'))
		return
	end
	local res = MEM[xuid].newLand.range
	local cubeInfo = CubeGetInfo(res.posA,res.posB)
	local price = CalculatePrice(cubeInfo.length,cubeInfo.width,cubeInfo.height,res.dimension)
	local discount_info = ''
	local dimension_info = ''
	if cfg.land.bought.discount<1 then
		discount_info=_Tr('gui.buyland.discount','<a>',tostring(1-cfg.land.bought.discount))
	end
	if res.dimension=='3D' then
		dimension_info = '§l3D-Land §r'
	else
		dimension_info = '§l2D-Land §r'
	end
	player:sendModalForm(
		dimension_info.._Tr('gui.buyland.title')..discount_info,
		_Tr('gui.buyland.content',
			'<a>',cubeInfo.length,
			'<b>',cubeInfo.width,
			'<c>',cubeInfo.height,
			'<d>',cubeInfo.volume,
			'<e>',price,
			'<f>',cfg.economic.currency_name,
			'<g>',Money_Get(player)
		),
		_Tr('gui.general.buy'),
		_Tr('gui.general.close'),
		function (player,id)
			if not(id) then
				SendText(player,_Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name))
				return
			end
		
			local xuid = player.xuid
			local res = MEM[xuid].newLand.range
			local player_credits = Money_Get(player)
			if price > player_credits then
				SendText(player,_Tr('title.buyland.moneynotenough').._Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name));return
			else
				Money_Del(player,price)
			end
			SendText(player,_Tr('title.buyland.succeed'))
			local landId = ILAPI.CreateLand(xuid,res.posA,res.posB,res.dimid)
			RSR_Delete(player)
			MEM[xuid].newLand = nil
			player:sendModalForm(
				'Complete.',
				_Tr('gui.buyland.succeed'),
				_Tr('gui.general.looklook'),
				_Tr('gui.general.cancel'),
				function(player,res)
					if res then
						MEM[xuid].landId = landId
						GUI_FastMgr(player)
					end
				end
			)
		end
	)
end)
mc.regPlayerCmd(MainCmd..' ok',_Tr('command.land_ok'),function (player,args)
	local xuid = player.xuid
    if MEM[xuid].reselectLand == nil then
		SendText(player,_Tr('talk.invalidaction'))
		return
	end
	local res = MEM[xuid].reselectLand.range
	local cubeInfo = CubeGetInfo(res.posA,res.posB)
	local old_cubeInfo = CubeGetInfo(VecMap[MEM[xuid].reselectLand.id].a,VecMap[MEM[xuid].reselectLand.id].b)

	-- Checkout
	local nr_price = CalculatePrice(cubeInfo.length,cubeInfo.width,cubeInfo.height,res.dimension)
	local or_price = CalculatePrice(old_cubeInfo.length,old_cubeInfo.width,old_cubeInfo.height,res.dimension)
	local mode -- pay(0) or refund(1)
	local payT
	if nr_price >= or_price then
		mode = _Tr('gui.reselectland.pay')
		payT = 0
	else
		mode = _Tr('gui.reselectland.refund')
		payT = 1
	end
	local needto = math.abs(nr_price-or_price)
	local landId = MEM[xuid].reselectLand.id
	player:sendModalForm(
		'Checkout',
		_Tr('gui.reselectland.content',
			'<a>',ILAPI.GetDimension(landId),
			'<c>',res.dimension,
			'<b>',or_price,
			'<d>',nr_price,
			'<e>',mode,
			'<f>',needto,
			'<g>',cfg.economic.currency_name
		),
		_Tr('gui.general.yes'),
		_Tr('gui.general.cancel'),
		function(player,result)
			if result==nil or not(result) then return end
			if payT==0 then
				if Money_Get(player)<needto then
					SendText(player,_Tr('title.buyland.moneynotenough'))
					return
				end
				Money_Del(player,needto)
			else
				Money_Add(player,needto)
			end
			local pA = res.posA
			local pB = res.posB
			if res.dimension == '2D' then
				pA.y = minY
				pB.y = maxY
			end

			UpdateLandEdgeMap(landId,'del') -- rebuild maps.
			UpdateChunk(landId,'del')
			UpdateLandPosMap(landId,'del')

			land_data[landId].range.start_position = {pA.x,pA.y,pA.z}
			land_data[landId].range.end_position = {pB.x,pB.y,pB.z}
			land_data[landId].range.dimid = res.dimid
			land_data[landId].settings.tpoint = {pA.x,pA.y+1,pA.z}
			MEM[xuid].reselectLand = nil
			
			UpdateLandEdgeMap(landId,'add')
			UpdateChunk(landId,'add')
			UpdateLandPosMap(landId,'add')

			ILAPI.save({0,1,0})
			SendText(player,_Tr('title.reselectland.succeed'))
			RSR_Delete(player)
		end
	)
end)
mc.regPlayerCmd(MainCmd..' mgr',_Tr('command.land_mgr'),function (player,args)
	local xuid = player.xuid
	if not(ILAPI.IsLandOperator(xuid)) then
		SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
		return false
	end
	GUI_OPLMgr(player)
end)
mc.regPlayerCmd(MainCmd..' mgr selectool',_Tr('command.land_mgr_selectool'),function (player,args)
	local xuid = player.xuid
	if FoundValueInList(cfg.land.operator,xuid)==-1 then
		SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
		return false
	end
	SendText(player,_Tr('title.oplandmgr.setselectool'))
	MEM[xuid].selectool=0
end)
mc.regPlayerCmd(MainCmd..' tp',_Tr('command.land_tp'),function (player,args)
	if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
	local xuid = player.xuid
	local landlst = {}
	local tplands = {}
	for i,landId in pairs(ILAPI.GetPlayerLands(xuid)) do
		local name = ILAPI.GetNickname(landId)
		local xpos = ILAPI.GetPoint(landId)
		tplands[#tplands+1] = ToStrDim(xpos.dimid)..' ('..PosToText(xpos)..') '..name
		landlst[#landlst+1] = landId
	end
	for i,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
		local name = ILAPI.GetNickname(landId)
		local xpos = ILAPI.GetPoint(landId)
		tplands[#tplands+1]='§l'.._Tr('gui.landtp.trusted')..'§r '..ToStrDim(xpos.dimid)..'('..PosToText(xpos)..') '..name
		landlst[#landlst+1] = landId
	end
	local Form = mc.newSimpleForm()
	Form:setTitle(_Tr('gui.landtp.title'))
	Form:setContent(_Tr('gui.landtp.tip'))
	Form:addButton(_Tr('gui.general.close'))
	for i,land in pairs(tplands) do
		Form:addButton(land,'textures/ui/world_glyph_color')
	end
	player:sendForm(Form,function(player,id)
		if id==nil or id==0 then return end
		local landId = landlst[id]
		if ILAPI.Teleport(player,landId) then
			SendText(player,_Tr('title.landtp.success'))
		else
			SendText(player,_Tr('title.landtp.fail.danger'))
		end
	end
	)
end)
mc.regPlayerCmd(MainCmd..' tp set',_Tr('command.land_tp_set'),function (player,args)
	if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
	local xuid = player.xuid
	local pos = FixBp(player.blockPos)

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then
		SendText(player,_Tr('title.landtp.fail.noland'))
		return false
	end
	if ILAPI.GetOwner(landId)~=xuid then
		SendText(player,_Tr('title.landtp.fail.notowner'))
		return false
	end
	local landname = ILAPI.GetNickname(landId,true)
	land_data[landId].settings.tpoint = {
		pos.x,
		pos.y+1,
		pos.z
	}
	ILAPI.save({0,1,0})
	player:sendModalForm(
		_Tr('gui.general.complete'),
		_Tr('gui.landtp.point','<a>',PosToText({x=pos.x,y=pos.y+1,z=pos.z}),'<b>',landname),
		_Tr('gui.general.iknow'),
		_Tr('gui.general.close'),
		F_NULL
	)
end)
mc.regPlayerCmd(MainCmd..' tp rm',_Tr('command.land_tp_rm'),function (player,args)
	if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
	local xuid = player.xuid
	local pos = FixBp(player.blockPos)

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then
		SendText(player,_Tr('title.landtp.fail.noland'))
		return false
	end
	if ILAPI.GetOwner(landId)~=xuid then
		SendText(player,_Tr('title.landtp.fail.notowner'))
		return false
	end
	local def = VecMap[landId].a
	land_data[landId].settings.tpoint = {
		def.x,
		def.y+1,
		def.z
	}
	SendText(player,_Tr('title.landtp.removed'))
end)

-- [Server] Command Registry
mc.regConsoleCmd(MainCmd,_Tr('command.console.land'),function(args)
	if #args~=0 then
		ERROR('Unknown parameter: "'..args[1]..'", plugin wiki: https://myland.amd.rocks/')
		return
	end
	INFO('The server is running iLand v'..Plugin.version)
	INFO('Github: https://github.com/LiteLDev-LXL/iLand-Core')
end)
mc.regConsoleCmd(MainCmd..' op',_Tr('command.console.land_op'),function(args)
	local name = SplicingArray(args,' ')
	local xuid = data.name2xuid(name)
	if xuid == "" then
		ERROR(_Tr('console.landop.failbyxuid','<a>',name))
		return
	end
	if ILAPI.IsLandOperator(xuid) then
		ERROR(_Tr('console.landop.add.failbyexist','<a>',name))
		return
	end
	table.insert(cfg.land.operator,#cfg.land.operator+1,xuid)
	UpdateLandOperatorsMap()
	ILAPI.save({1,0,0})
	INFO('System',_Tr('console.landop.add.success','<a>',name,'<b>',xuid))
end)
mc.regConsoleCmd(MainCmd..' deop',_Tr('command.console.land_deop'),function(args)
	local name = SplicingArray(args,' ')
	local xuid = data.name2xuid(name)
	if xuid == "" then
		ERROR(_Tr('console.landop.failbyxuid','<a>',name))
		return
	end
	if not(ILAPI.IsLandOperator(xuid)) then
		ERROR(_Tr('console.landop.del.failbynull','<a>',name))
		return
	end
	table.remove(cfg.land.operator,FoundValueInList(cfg.land.operator,xuid))
	UpdateLandOperatorsMap()
	ILAPI.save({1,0,0})
	INFO('System',_Tr('console.landop.del.success','<a>',name,'<b>',xuid))
end)
mc.regConsoleCmd(MainCmd..' update',_Tr('command.console.land_update'),function(args)
	if cfg.plugin.network then
		Upgrade(Server.memInfo)
	else
		ERROR(_Tr('console.update.nodata'))
	end
end)
mc.regConsoleCmd(MainCmd..' language',_Tr('command.console.land_language'),function(args)
	INFO('I18N',_Tr('console.languages.sign','<a>',cfg.plugin.language,'<b>',_Tr('VERSION')))
	local isNone = false
	local count = 1
	while(not(isNone)) do
		if LangPack['#'..count] ~= nil then
			INFO('I18N',_Tr('#'..count))
		else
			isNone = true
		end
		count = count + 1
	end
end)
mc.regConsoleCmd(MainCmd..' language set',_Tr('command.console.land_language_set'),function(args)
	local langpath = DATA_PATH..'lang\\'
	if args[1] == nil then
		ERROR(_Tr('console.languages.set.misspara'))
		return false;
	end
	local path = langpath..args[1]..'.json'
	if File.exists(path) then
		cfg.plugin.language = args[1]
		LangPack = JSON.decode(file.readFrom(path))
		ILAPI.save({1,0,0})
		INFO(_Tr('console.languages.set.succeed','<a>',cfg.plugin.language))
	else
		ERROR(_Tr('console.languages.set.nofile','<a>',args[1]))
	end
end)
mc.regConsoleCmd(MainCmd..' language list',_Tr('command.console.land_language_list'),function(args)
	local langlist = ILAPI.GetLanguageList(0)
	for i,lang in pairs(langlist) do
		if lang==cfg.plugin.language then
			INFO('I18N',lang..' <- Using.')
		else
			INFO('I18N',lang)
		end
	end
	INFO('I18N',_Tr('console.languages.list.count','<a>',#langlist))
end)
mc.regConsoleCmd(MainCmd..' language list-online',_Tr('command.console.land_language_list-online'),function(args)
	INFO('Network',_Tr('console.languages.list-online.wait'))
	local rawdata = ILAPI.GetLanguageList(1)
	if rawdata == false then
		return false
	end
	INFO('I18N',_Tr('console.languages.official'))
	for i,lang in pairs(rawdata.official) do
		INFO('I18N',lang)
	end
	INFO('I18N',_Tr('console.languages.3rd'))
	for i,lang in pairs(rawdata['3-rd']) do
		INFO('I18N',lang)
	end
end)
mc.regConsoleCmd(MainCmd..' language install',_Tr('command.console.land_language_install'),function(args)
	if args[1] == nil then
		ERROR(_Tr('console.languages.install.misspara'))
		return false
	end
	INFO('Network',_Tr('console.languages.list-online.wait'))
	local rawdata = ILAPI.GetLanguageList(1)
	if rawdata == false then
		return false
	end
	if FoundValueInList(ILAPI.GetLanguageList(0),args[1])~=-1 then
		ERROR(_Tr('console.languages.install.existed'))
		return false
	end
	if FoundValueInList(rawdata.official,args[1])==-1 and FoundValueInList(rawdata['3-rd'],args[1])==-1 then
		ERROR(_Tr('console.languages.install.notfound','<a>',args[1]))
		return false
	end
	INFO(_Tr('console.autoupdate.download'))
	if DownloadLanguage(args[1]) then
		INFO(_Tr('console.languages.install.succeed','<a>',args[1]))
	end
end)
mc.regConsoleCmd(MainCmd..' language update',_Tr('command.console.land_language_update'),function(args)
	local langpath = DATA_PATH..'lang\\'
	local langlist = ILAPI.GetLanguageList(0)
	local langlist_o = ILAPI.GetLanguageList(1)
	local function updateLang(lang)
		local langdata
		if File.exists(langpath..lang..'.json') then
			langdata = JSON.decode(file.readFrom(langpath..lang..'.json'))
		else
			ERROR(_Tr('console.languages.update.notfound','<a>',lang))
			return false -- this false like 'fail'
		end
		if langdata.VERSION == Plugin.numver then
			ERROR(lang..': '.._Tr('console.languages.update.alreadylatest'))
			return true -- continue
		end
		if FoundValueInList(langlist,lang)==-1 then
			ERROR(_Tr('console.languages.update.notfound','<a>',lang))
			return false
		end
		if FoundValueInList(langlist_o.official,lang)==-1 and FoundValueInList(langlist_o['3-rd'],lang)==-1 then
			ERROR(_Tr('console.languages.update.notfoundonline','<a>',lang))
			return false
		end
		if DownloadLanguage(lang) then
			INFO(_Tr('console.languages.update.succeed','<a>',lang))
		end
	end
	if args[1] == nil then
		INFO(_Tr('console.languages.update.all'))
		for i,lang in pairs(langlist) do
			if not(updateLang(lang)) then
				return false
			end
		end
	else
		INFO(_Tr('console.languages.update.single','<a>',args[1]))
		updateLang(args[1])
	end
end)

-- CmdUtils
function DownloadLanguage(name)
	local lang_n = network.httpGetSync(GetLink()..'/languages/'..name..'.json')
	local lang_v = network.httpGetSync(GetLink()..'/languages/'..name..'.json.md5.verify')
	if lang_n.status~=200 or lang_v.status~=200 then
		ERROR(_Tr('console.languages.install.statfail','<a>',name,'<b>',lang_n.status..','..lang_v.status))
		return false
	end
	local raw = string.gsub(lang_n.data,'\n','\r\n')
	if data.toMD5(raw)~=lang_v.data then
		ERROR(_Tr('console.languages.install.verifyfail','<a>',name))
		return false
	end
	local THISVER = JSON.decode(raw).VERSION
	if THISVER~=Plugin.numver then
		ERROR(_Tr('console.languages.install.versionfail','<a>',name,'<b>',THISVER,'<c>',Plugin.numver))
		return false
	end
	file.writeTo(DATA_PATH..'lang\\'..name..'.json',raw)
	return true
end

-- Timer Works
function Timer_LandSign()
	for xuid,res in pairs(MEM) do
		local player = mc.getPlayer(xuid)

		if ChkNil(player) then
			goto JUMPOUT_LANDSIGN
		end

		local xuid = player.xuid
		local landId = ILAPI.PosGetLand(FixBp(player.blockPos))
		if landId==-1 then
			MEM[xuid].inland = 'null'
			goto JUMPOUT_LANDSIGN
		end
		if landId==MEM[xuid].inland then
			goto JUMPOUT_LANDSIGN
		end

		local ownerXuid = ILAPI.GetOwner(landId)
		local ownerId = '?'
		if ownerXuid~='?' then ownerId=data.xuid2name(ownerXuid) end
		local landcfg = land_data[landId].settings

		if (xuid==ownerXuid or ILAPI.IsPlayerTrusted(landId,xuid)) and landcfg.signtome then
			-- owner/trusted
			if not(landcfg.signtome) then
				goto JUMPOUT_LANDSIGN
			end
			SendTitle(player,
				_Tr('sign.listener.ownertitle','<a>',ILAPI.GetNickname(landId,false)),
				_Tr('sign.listener.ownersubtitle')
			)
		else
			-- visitor
			if not(landcfg.signtother) then
				goto JUMPOUT_LANDSIGN
			end
			SendTitle(player,
				_Tr('sign.listener.visitortitle'),
				_Tr('sign.listener.visitorsubtitle','<a>',ownerId)
			)
			if landcfg.describe~='' then
				local des = CloneTable(landcfg.describe)
				des = string.gsub(des,'$visitor',player.name)
				des = string.gsub(des,'$n','\n')
				SendText(player,des,0)
			end
		end

		MEM[xuid].inland = landId
		:: JUMPOUT_LANDSIGN ::
	end
end
function Timer_ButtomSign()
	for xuid,res in pairs(MEM) do
		local player = mc.getPlayer(xuid)

		if ChkNil(player) then
			goto JUMPOUT_BUTTOMSIGN
		end

		local landId = ILAPI.PosGetLand(FixBp(player.blockPos))
		if landId==-1 then
			goto JUMPOUT_BUTTOMSIGN
		end
		local landcfg = land_data[landId].settings
		if not(landcfg.signbuttom) then
			goto JUMPOUT_BUTTOMSIGN
		end

		local ownerXuid = ILAPI.GetOwner(landId)
		local ownerId = '?'
		if ownerXuid~='?' then ownerId=data.xuid2name(ownerXuid) end
		
		if (xuid==ownerXuid or ILAPI.IsPlayerTrusted(landId,xuid)) and landcfg.signtome then
			player:sendText(_Tr('title.landsign.ownenrbuttom','<a>',ILAPI.GetNickname(landId)),4)
		else
			if (xuid~=ownerXuid) and landcfg.signtother then
				player:sendText(_Tr('title.landsign.visitorbuttom','<a>',ownerId),4)
			end
		end

		:: JUMPOUT_BUTTOMSIGN ::
	end
end
function Timer_MEM()
	for xuid,res in pairs(MEM) do
		if cfg.features.particles.enable and res.particles ~= nil then -- Keeping Particles
			local player = mc.getPlayer(xuid)
			for n,pos in pairs(res.particles) do
				local posY
				if MEM[xuid].newLand~=nil then
					if MEM[xuid].newLand.dimension=='2D' then
						posY = player.blockPos.y + 2
					else
						posY = pos.y + 1.6
					end
				end
				if MEM[xuid].reselectLand~=nil then
					posY = pos.y
				end
				mc.spawnParticle(pos.x,posY,pos.z,player.pos.dimid,cfg.features.particles.name)
			end
		end
		if res.keepingTitle ~= nil then -- Keeping Title
			local title = res.keepingTitle
			if type(title)=='table' then
				SendTitle(mc.getPlayer(xuid),title[1],title[2],{0,40,20})
			else
				SendTitle(mc.getPlayer(xuid),title,{0,100,0})
			end
		end
	end
end

-- Minecraft Eventing
mc.listen('onJoin',function(player)
	local xuid = player.xuid
	MEM[xuid] = { inland='null' }

	if wrong_landowners[xuid]~=nil then
		land_owners[xuid] = CloneTable(wrong_landowners[xuid])
		for n,landId in pairs(land_owners[xuid]) do
			UpdateLandOwnersMap(landId)
		end
		wrong_landowners[xuid] = nil
	end
	if land_owners[xuid]==nil then
		land_owners[xuid] = {}
		ILAPI.save({0,0,1})
	end

	if player.gameMode==1 then
		WARN(_Tr('talk.gametype.creative','<a>',player.realName))
	end
end)
mc.listen('onPreJoin',function(player)
	if player.xuid=='' then -- no xuid
		player:kick(_Tr('talk.prejoin.noxuid'))
	end
end)
mc.listen('onLeft',function(player)

	if ChkNil(player) then
		return
	end

	local xuid = player.xuid
	MEM[xuid]=nil
end)
mc.listen('onDestroyBlock',function(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onDestroyBlock') then
		return
	end

	local xuid=player.xuid

	if MEM[xuid].selectool==0 then
		local HandItem = player:getHand()
		if HandItem.isNull(HandItem) then goto PROCESS_1 end --fix crash
		SendText(player,_Tr('title.oplandmgr.setsuccess','<a>',HandItem.name))
		cfg.features.selection.tool_type=HandItem.type
		ILAPI.save({1,0,0})
		MEM[xuid].selectool=-1
		return false
	end

	:: PROCESS_1 ::
	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	if land_data[landId].permissions.allow_destroy then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onPlaceBlock',function(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onPlaceBlock') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_place then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onUseItemOn',function(player,item,block)

	if ChkNil(player) or ILAPI.IsDisabled('onUseItemOn') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	local perm = land_data[landId].permissions -- Temp perm.
	if perm.useitem then return false end

	local IsConPlus=false
	if not(ILAPI.CanControl(0,block.type)) then 
		if not(ILAPI.CanControl(2,item.type)) then
			return
		else
			IsConPlus=true
		end
	end
	
	if IsConPlus then
		local it = item.type
		if string.sub(it,-6,-1) == 'bucket' and perm.use_bucket then return end -- 各种桶
		if it == 'minecraft:glow_ink_sac' and perm.allow_place then return end -- 发光墨囊给木牌上色（拓充）
		if it == 'minecraft:end_crystal' and perm.allow_place then return end -- 末地水晶（拓充）
		if it == 'minecraft:ender_eye' and perm.allow_place then return end -- 放置末影之眼（拓充）
		if it == 'minecraft:flint_and_steel' and perm.use_firegen then return end -- 使用打火石
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
		if string.sub(bn,-4,-1) == 'door' and perm.use_door then return end -- 各种门
		if string.sub(bn,-10,-1) == 'fence_gate' and perm.use_fence_gate then return end -- 各种栏栅门
		if string.sub(bn,-8,-1) == 'trapdoor' and perm.use_trapdoor then return end -- 各种活板门
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onAttack',function(player,entity)
	
	if ChkNil_X2(player,entity) or ILAPI.IsDisabled('onAttack') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	local perm=land_data[landId].permissions
	local en=entity.type
	local IsConPlus = false
	if ILAPI.CanControl(3,en) then IsConPlus=true end
	local entityType = EntityGetType(en)
	if IsConPlus then
		if en == 'minecraft:ender_crystal' and perm.allow_destroy then return end -- 末地水晶（拓充）
		if en == 'minecraft:armor_stand' and perm.allow_destroy then return end -- 盔甲架（拓充）
	else
		if perm.allow_attack_player and entityType==0 then return end -- Perm Allow
		if perm.allow_attack_animal and entityType==1 then return end
		if perm.allow_attack_mobs and entityType==2 then return end
	end
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onChangeArmorStand',function(entity,player,slot)

	if ChkNil_X2(entity,player) or ILAPI.IsDisabled('onChangeArmorStand') then
		return
	end

	local landId = ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land

	local xuid = player.xuid
	if land_data[landId].permissions.use_armor_stand then return end
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onExplode',function(entity,pos)

	if ChkNil(entity) or ILAPI.IsDisabled('onExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end)
mc.listen('onBedExplode',function(pos)

	if ILAPI.IsDisabled('onBedExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end)
mc.listen('onRespawnAnchorExplode',function(pos,player)

	if ILAPI.IsDisabled('onRespawnAnchorExplode') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_explode then return end -- EV Allow
	return false
end)
mc.listen('onTakeItem',function(player,entity)

	if ChkNil_X2(player,entity) or ILAPI.IsDisabled('onTakeItem') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_pickupitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onDropItem',function(player,item)

	if ChkNil(player) or ILAPI.IsDisabled('onDropItem') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_dropitem then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onBlockInteracted',function(player,block)

	if ChkNil(player) or ILAPI.IsDisabled('onBlockInteracted') then
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
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onUseFrameBlock',function(player,block)
		
	if ChkNil(player) or ILAPI.IsDisabled('onUseFrameBlock') then
		return
	end

	local landId=ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.use_item_frame then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onSpawnProjectile',function(splasher,type)
			
	if ChkNil(splasher) or ILAPI.IsDisabled('onSpawnProjectile') then
		return
	end

	if splasher:toPlayer()==nil then return end
	local landId=ILAPI.PosGetLand(FixBp(splasher.blockPos))
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
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onFireworkShootWithCrossbow',function(player)
			
	if ChkNil(player) or ILAPI.IsDisabled('onFireworkShootWithCrossbow') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
	if landId==-1 then return end -- No Land

	local xuid=player.xuid
	if land_data[landId].permissions.allow_shoot then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onStepOnPressurePlate',function(entity,block)
				
	if ChkNil(entity) or ILAPI.IsDisabled('onStepOnPressurePlate') then
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

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	
	if land_data[landId].permissions.use_pressure_plate then return end -- Perm Allow
	if ispl then
		local xuid=player.xuid
		if ILAPI.IsLandOperator(xuid) then return end
		if ILAPI.IsLandOwner(landId,xuid) then return end
		if ILAPI.IsPlayerTrusted(landId,xuid) then return end
		SendText(player,_Tr('title.landlimit.noperm'))
	end
	return false
end)
mc.listen('onRide',function(rider,entity)
				
	if ChkNil_X2(rider,entity) or ILAPI.IsDisabled('onRide') then
		return
	end

	if rider:toPlayer()==nil then return end

	local landId=ILAPI.PosGetLand(FixBp(rider.blockPos))
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
	
	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onWitherBossDestroy',function(witherBoss,AAbb,aaBB)

	if ILAPI.IsDisabled('onWitherBossDestroy') then
		return
	end

	local dimid = witherBoss.pos.dimid
	for n,pos in pairs(TraverseAABB(AAbb,aaBB,dimid)) do
		local landId=ILAPI.PosGetLand(pos)
		if landId~=-1 and not(land_data[landId].permissions.allow_entity_destroy) then 
			break
		end
	end
	return false
end)
mc.listen('onFarmLandDecay',function(pos,entity)
	
	if ChkNil(entity) or ILAPI.IsDisabled('onFarmLandDecay') then
		return
	end

	local landId=ILAPI.PosGetLand(FixBp(entity.blockPos))
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_farmland_decay then return end -- EV Allow
	return false
end)
mc.listen('onPistonPush',function(pos,block)

	if ILAPI.IsDisabled('onPistonPush') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_piston_push then return end -- Perm Allow
	return false
end)
mc.listen('onFireSpread',function(pos)

	if ILAPI.IsDisabled('onFireSpread') then
		return
	end

	local landId=ILAPI.PosGetLand(pos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_fire_spread then return end -- Perm Allow
	return false
end)
mc.listen('onEat',function(player,item)

	if ChkNil(player) or ILAPI.IsDisabled('onEat') then
		return
	end

	local xuid = player.xuid
	local landId=ILAPI.PosGetLand(FixBp(player.blockPos))
	if landId==-1 then return end -- No Land

	if land_data[landId].permissions.eat then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onStartDestroyBlock',function(player,block)

	local xuid = player.xuid
	if MEM[xuid].rsr ~= nil and (MEM[xuid].rsr.sleep==nil or MEM[xuid].rsr.sleep<os.time()) then
		local HandItem = player:getHand()
		if HandItem:isNull() or HandItem.type~=cfg.features.selection.tool_type then return end
		RSR_Do(player,block.pos)
		MEM[xuid].rsr.sleep = os.time() + 2
	end

end)

-- Network Handler
function Upgrade(rawInfo)

	local function recoverBackup(dt)
		INFO('AutoUpdate',_Tr('console.autoupdate.recoverbackup'))
		for n,backupfilename in pairs(dt) do
			file.rename(backupfilename..'.bak',backupfilename)
		end
	end
	local function isLXLSupported(list)
		local version = lxl.version()
		for n,ver in pairs(list) do
			if ver[1]==version[1] and ver[2]==version[2] and ver[3]==version[3] then
				return true
			end
		end
		return false
	end

	--  Check Data
	local updata
	if rawInfo.Updates[2]~=nil and rawInfo.Updates[2].NumVer~=Plugin.numver then
		ERROR('console.update.vacancy')
		return
	end
	if rawInfo.FILE_Version==Server.version then
		updata = rawInfo.Updates[1]
	else
		ERROR(_Tr('console.getonline.failbyver','<a>',rawInfo.FILE_Version))
		return
	end
	if rawInfo.DisableClientUpdate then
		ERROR(_Tr('console.update.disabled'))
		return
	end
	if not isLXLSupported(updata.LXL) then
		ERROR(_Tr('console.update.unsupport'))
		return
	end
	
	-- Check Plugin version
	if updata.NumVer<=Plugin.numver then
		ERROR(_Tr('console.autoupdate.alreadylatest','<a>',updata.NumVer..'<='..Plugin.numver))
		return
	end
	INFO('AutoUpdate',_Tr('console.autoupdate.start'))
	
	-- Set Resource
	local RawPath = {}
	local BackupEd = {}
	local server = GetLink()
	local source
	if server ~= false then
		source = server..'/'..updata.NumVer..'/'
	else
		ERROR(_Tr('console.getonline.failed'))
		return false
	end
	
	INFO('AutoUpdate',Plugin.version..' => '..updata.Version)
	RawPath['$plugin_path'] = 'plugins\\'
	RawPath['$data_path'] = DATA_PATH
	
	-- Get it, update.
	for n,thefile in pairs(updata.FileChanged) do
		local raw = StrSplit(thefile,'::')
		local path = RawPath[raw[1]]..raw[2]
		INFO('Network',_Tr('console.autoupdate.download')..raw[2])
		
		if file.exists(path) then -- create backup
			file.rename(path,path..'.bak')
			BackupEd[#BackupEd+1]=path
		end

		local tmp = network.httpGetSync(source..raw[2])
		local tmp2 = network.httpGetSync(source..raw[2]..'.md5.verify')
		if tmp.status~=200 or tmp2.status then -- download check
			ERROR(
				_Tr('console.autoupdate.errorbydown',
					'<a>',raw[2],
					'<b>',tmp.status..','..tmp2.status
				)
			)
			recoverBackup(BackupEd)
			return
		end

		local raw = string.gsub(tmp.data,'\n','\r\n')
		if data.toMD5(raw)~=tmp2.data then -- MD5 check
			ERROR(
				_Tr('console.autoupdate.errorbyverify',
					'<a>',raw[2]
				)
			)
			recoverBackup(BackupEd)
			return
		end

		file.writeTo(path,raw)
	end

	INFO('AutoUpdate',_Tr('console.autoupdate.success'))
end

mc.listen('onServerStarted',function()
	
	-- Make timer
	if cfg.features.landsign.enable then
		setInterval(Timer_LandSign,cfg.features.landsign.frequency*1000)
	end
	if cfg.features.buttomsign.enable then
		setInterval(Timer_ButtomSign,cfg.features.buttomsign.frequency*1000)
	end
	setInterval(Timer_MEM,1000)

	-- load owners data
	try
	{
		function ()
			-- load : data
			if load() ~= true then
				error('wrong!')
			end
			-- load : maps
			INFO('Load','Building tables needed to run...')
			BuildAnyMap()
		end,
		catch
		{
			function (err)
				ERROR('Something wrong when load data, plugin closed.')
				log(err)
				mc.runcmdEx('lxl unload iland-core.lua')
			end
		}
	}

	-- Check Update
	if cfg.plugin.network then
		local server = GetLink()
		if server ~=  false then
			network.httpGet(server..'/server_203.json',function(code,result)
				if code~=200 then
					ERROR(_Tr('console.getonline.failbycode','<a>',code))
					return
				end
				local data = JSON.decode(result)
				Server.memInfo = data
		
				-- Check Server Version
				if data.FILE_Version~=Server.version then
					INFO('Network',_Tr('console.getonline.failbyver','<a>',data.FILE_Version))
					return
				end
		
				-- Check Update
				if Plugin.numver<data.Updates[1].NumVer then
					INFO('Network',_Tr('console.update.newversion','<a>',data.Updates[1].Version))
					INFO('Update',_Tr('console.update.newcontent'))
					for n,text in pairs(data.Updates[1].Description) do
						INFO('Update',n..'. '..text)
					end
					if data.Force_Update then
						INFO('Update',_Tr('console.update.force'))
						Upgrade(data)
					end
					if cfg.features.auto_update then
						INFO('Update',_Tr('console.update.auto'))
						Upgrade(data)
					end
				end
				if Plugin.numver>data.Updates[1].NumVer then
					INFO('Network',_Tr('console.update.preview','<a>',Plugin.version))
				end
			end)
		else
			ERROR(_Tr('console.getonline.failed'))
		end
	end

	INFO('Load','Completed, use memory: '..string.format("%.2f",collectgarbage('count')/1024)..'MB.')

end)

-- export function
lxl.export(ILAPI.CreateLand,'ILAPI_CreateLand')
lxl.export(ILAPI.DeleteLand,'ILAPI_DeleteLand')
lxl.export(ILAPI.PosGetLand,'ILAPI_PosGetLand')
lxl.export(ILAPI.GetChunk,'ILAPI_GetChunk')
lxl.export(ILAPI.GetAllLands,'ILAPI_GetAllLands')
lxl.export(ILAPI.CheckPerm,'ILAPI_CheckPerm')
lxl.export(ILAPI.CheckSetting,'ILAPI_CheckSetting')
lxl.export(ILAPI.GetRange,'ILAPI_GetRange')
lxl.export(ILAPI.GetEdge,'ILAPI_GetEdge')
lxl.export(ILAPI.GetDimension,'ILAPI_GetDimension')
lxl.export(ILAPI.GetName,'ILAPI_GetName')
lxl.export(ILAPI.GetDescribe,'ILAPI_GetDescribe')
lxl.export(ILAPI.GetOwner,'ILAPI_GetOwner')
lxl.export(ILAPI.GetPoint,'ILAPI_GetPoint')
lxl.export(ILAPI.GetPlayerLands,'ILAPI_GetPlayerLands')
lxl.export(ILAPI.IsPlayerTrusted,'ILAPI_IsPlayerTrusted')
lxl.export(ILAPI.IsLandOwner,'ILAPI_IsLandOwner')
lxl.export(ILAPI.IsLandOperator,'ILAPI_IsLandOperator')
lxl.export(ILAPI.GetAllTrustedLand,'ILAPI_GetAllTrustedLand')
lxl.export(ILAPI.UpdatePermission,'ILAPI_UpdatePermission')
lxl.export(ILAPI.UpdateSetting,'ILAPI_UpdateSetting')
lxl.export(ILAPI.AddTrust,'ILAPI_AddTrust')
lxl.export(ILAPI.RemoveTrust,'ILAPI_RemoveTrust')
lxl.export(ILAPI.SetOwner,'ILAPI_SetOwner')
lxl.export(ILAPI.Teleport,'ILAPI_Teleport')
lxl.export(ILAPI.GetMoneyProtocol,'ILAPI_GetMoneyProtocol')
lxl.export(ILAPI.GetLanguage,'ILAPI_GetLanguage')
lxl.export(ILAPI.GetChunkSide,'ILAPI_GetChunkSide')
lxl.export(ILAPI.GetVersion,'ILAPI_GetVersion')

INFO('Powerful land plugin is loaded! Ver-'..Plugin.version..',')
INFO('By: RedbeanW, License: GPLv3 with additional conditions.')
