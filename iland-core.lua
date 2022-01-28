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
	version = "2.70",
	numver = 270,
	apiver = 200,
	minLXL = {0,5,12},
}

Server = {
	link = "https://cdn.jsdelivr.net/gh/LiteLDev-LXL/Cloud/",
	version = 203,
	memData = {}
}

JSON = require('dkjson')

ILAPI = {}; MEM = {}
MainCmd = 'land'
DATA_PATH = 'plugins/iland/'
local land_data; local land_owners = {}; local wrong_landowners = {}

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
				calculate = "{square}*8+{height}*20",
			},
			two_dimension = {
				enable = true,
				calculate = "{square}*25",
			},
			square_range = {4,50000},
			discount = 1
		},
		min_space = 15,
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
			dimension = {
				true,	-- overworld
				true,	-- nether
				true	-- end
			},
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
	DATA_PATH = 'plugins/LXL_Plugins/iLand/iland/'
end

local minY <const> = -64
local maxY <const> = 320

-- Init log system
logger.setConsole(true)
logger.setTitle("ILand")
function INFO(msgtype,content)
	if content==nil then
		content = msgtype
		msgtype = ""
	else
		msgtype = msgtype..' >> '
	end
	if string.find(content,'\n') then
		for n,msg in pairs(string.split(content,'\n')) do
			INFO(msg,nil)
		end
		return
	end
	logger.info(content)
end
function ERROR(content)
	logger.error(content)
end
function WARN(content)
	logger.warn(content)
end

-- Init map system

Map = {
	Init = function()
		INFO('Load','Building tables needed to run...')
		for landId,data in pairs(land_data) do
			Map.Land.Edge.update(landId,'add')
			Map.Land.Position.update(landId,'add')
			Map.Land.Trusted.update(landId)
			Map.Land.Owner.update(landId)
			Map.Land.AXIS.update(landId,'add')
			Map.Chunk.update(landId,'add')
			Map.CachedQuery.Init(landId)
		end
		Map.Land.Operator.update()
		Map.Control.build()
		Map.Listener.build()
		setInterval(Map.CachedQuery.CACHE_MANAGER,1000*8)
	end,
	Chunk = {
		data = {
			[0] = {},	-- 主世界
			[1] = {},	-- 地狱
			[2] = {}	-- 末地
		},
		update = function(landId,mode)
			local TxTz = {} -- ChunkData(position)
			local ra = Map.Land.Position.data[landId]
			local spos = ra.a
			local epos = ra.b
			local dimid = ra.dimid
			local function chkNil(table,a,b)
				if table[a]==nil then
					table[a] = {}
				end
				if table[a][b]==nil then
					table[a][b] = {}
				end
			end
		
			local size = cfg.features.chunk_side
			local sX = spos.x
			local sZ = spos.z
			local count = 0
			while (sX+size*count<=epos.x+size) do
				local Cx,Cz = Pos.ToChunkPos({x=sX+size*count,z=sZ+size*count})
				chkNil(TxTz,Cx,Cz)
				local count2 = 0
				while (sZ+size*count2<=epos.z+size) do
					local Cx,Cz = Pos.ToChunkPos({x=sX+size*count,z=sZ+size*count2})
					chkNil(TxTz,Cx,Cz)
					count2 = count2 + 1
				end
				count = count + 1
			end
		
			-- [CODE] Add or Del some chunks.
		
			for Tx,a in pairs(TxTz) do
				for Tz,b in pairs(a) do
					-- Tx Tz
					if mode=='add' then
						chkNil(Map.Chunk.data[dimid],Tx,Tz)
						if Array.Fetch(Map.Chunk.data[dimid][Tx][Tz],landId) == -1 then
							table.insert(Map.Chunk.data[dimid][Tx][Tz],#Map.Chunk.data[dimid][Tx][Tz]+1,landId)
						end
					elseif mode=='del' then
						local p = Array.Fetch(Map.Chunk.data[dimid][Tx][Tz],landId)
						if p~=-1 then
							table.remove(Map.Chunk.data[dimid][Tx][Tz],p)
						end
					end
				end
			end
		
		end
	},
	Land = {
		Position = {
			data = {},
			update = function(landId,mode)
				if mode=='add' then
					local ra = land_data[landId].range
					local spos = ra.start_position
					local epos = ra.end_position
					Map.Land.Position.data[landId] = {
						a = {
							x = spos[1],
							y = spos[2],
							z = spos[3]
						},
						b = {
							x = epos[1],
							y = epos[2],
							z = epos[3]
						},
						dimid = ra.dimid
					}
				elseif mode=='del' then
					Map.Land.Position.data[landId] = nil
				end
			end
		},
		AXIS = {
			data = {
				[0] = {['x'] = {},['y'] = {},['z'] = {}},	-- Overworld
				[1] = {['x'] = {},['y'] = {},['z'] = {}},	-- Nether
				[2] = {['x'] = {},['y'] = {},['z'] = {}}	-- End
			},
			update = function(landId,mode)
				local ra = Map.Land.Position.data[landId]
				local spos = ra.a
				local epos = ra.b
				local dimid = ra.dimid
				if mode == 'add' then
					for x = spos.x,epos.x do
						local tar = Map.Land.AXIS.data[dimid]['x']
						if tar[x]==nil then
							tar[x] = {}
						end
						tar[x][#tar[x]+1] = landId
					end
					for y = spos.y,epos.y do
						local tar = Map.Land.AXIS.data[dimid]['y']
						if tar[y]==nil then
							tar[y] = {}
						end
						tar[y][#tar[y]+1] = landId
					end
					for z = spos.z,epos.z do
						local tar = Map.Land.AXIS.data[dimid]['z']
						if tar[z]==nil then
							tar[z] = {}
						end
						tar[z][#tar[z]+1] = landId
					end
				elseif mode == 'del' then
					for x = spos.x,epos.x do
						local tar = Map.Land.AXIS.data[dimid]['x'][x]
						table.remove(tar,Array.Fetch(tar,landId))
					end
					for y = spos.y,epos.y do
						local tar = Map.Land.AXIS.data[dimid]['y'][y]
						table.remove(tar,Array.Fetch(tar,landId))
					end
					for z = spos.z,epos.z do
						local tar = Map.Land.AXIS.data[dimid]['z'][z]
						table.remove(tar,Array.Fetch(tar,landId))
					end
				end
			end
		},
		Edge = {
			data = {},
			update = function (landId,mode)
				if mode=='del' then
					Map.Land.Edge.data[landId]=nil
					return
				elseif mode=='add' then
					Map.Land.Edge.data[landId]={}
					local spos = Array.ToIntPos(land_data[landId].range.start_position)
					local epos = Array.ToIntPos(land_data[landId].range.end_position)
					Map.Land.Edge.data[landId].D2D = Cube.GetEdge_2D(spos,epos)
					Map.Land.Edge.data[landId].D3D = Cube.GetEdge(spos,epos)
				end
			end
		},
		Trusted = {
			data = {},
			update = function(landId)
				Map.Land.Trusted.data[landId] = Array.ToKeyMap(land_data[landId].settings.share)
			end
		},
		Owner = {
			data = {},
			update = function(landId)
				Map.Land.Owner.data[landId] = ILAPI.GetOwner(landId)
			end
		},
		Operator = {
			data = {},
			update = function()
				Map.Land.Operator.data = Array.ToKeyMap(cfg.land.operator)
			end
		}
	},
	Listener = {
		data = {},
		build = function()
			Map.Listener.data = Array.ToKeyMap(cfg.features.disabled_listener)
		end
	},
	Control = {
		data = {},
		build = function()
			Map.Control.data = {
				-- # UseItem
				[0] = Array.ToKeyMap({
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
					'minecraft:dragon_egg'
				}),
				-- # onBlockInteracted
				[1] = Array.ToKeyMap({
					'minecraft:cartography_table','minecraft:smithing_table','minecraft:furnace','minecraft:blast_furnace',
					'minecraft:smoker','minecraft:brewing_stand','minecraft:anvil','minecraft:grindstone','minecraft:enchanting_table',
					'minecraft:barrel','minecraft:beacon','minecraft:hopper','minecraft:dropper','minecraft:dispenser',
					'minecraft:loom','minecraft:stonecutter_block'
				}),
				-- # ItemWhiteList
				[2] = Array.ToKeyMap({
					'minecraft:glow_ink_sac','minecraft:end_crystal','minecraft:ender_eye','minecraft:axolotl_bucket',
					'minecraft:powder_snow_bucket','minecraft:pufferfish_bucket','minecraft:tropical_fish_bucket',
					'minecraft:salmon_bucket','minecraft:cod_bucket','minecraft:water_bucket','minecraft:cod_bucket',
					'minecraft:lava_bucket','minecraft:bucket','minecraft:flint_and_steel'
				}),
				-- # Special attack.
				[3] = Array.ToKeyMap({
					'minecraft:ender_crystal','minecraft:armor_stand'
				}),
				-- # EntityTypeList
				[4] = {
					animals = Array.ToKeyMap({
						'minecraft:axolotl','minecraft:bat','minecraft:cat','minecraft:chicken',
						'minecraft:cod','minecraft:cow','minecraft:donkey','minecraft:fox',
						'minecraft:glow_squid','minecraft:horse','minecraft:mooshroom','minecraft:mule',
						'minecraft:ocelot','minecraft:parrot','minecraft:pig','minecraft:rabbit',
						'minecraft:salmon','minecraft:snow_golem','minecraft:sheep','minecraft:skeleton_horse',
						'minecraft:squid','minecraft:strider','minecraft:tropical_fish','minecraft:turtle',
						'minecraft:villager_v2','minecraft:wandering_trader','minecraft:npc'
					}),
					mobs = Array.ToKeyMap({
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
					})
				},
				-- # AttackBlock
				[5] = Array.ToKeyMap({
					'minecraft:dragon_egg'
				})
			}
		end
	},
	CachedQuery = {
		Init = function(landId)
			local map = Map.CachedQuery
			map.RangeArea.recorded_landId[landId] = {}
			map.SinglePos.land_recorded_pos[landId] = {}
		end,
		UnInit = function(landId)
			local map = Map.CachedQuery
			map.RangeArea.recorded_landId[landId] = nil
			map.SinglePos.land_recorded_pos[landId] = nil
		end,
		SinglePos = {
			data = {},
			land_recorded_pos = {}, -- query recorded strpos by landId.
			non_land_pos = {}, -- non-land position recorded.
			add = function(landId,pos)
				local strpos = Pos.ToString(pos)
				local map = Map.CachedQuery.SinglePos
				map.data[strpos] = {
					landId = landId,
					raw = pos,
					querying = true
				}
				if landId~=-1 then
					map.land_recorded_pos[landId][#map.land_recorded_pos[landId]+1] = strpos
				else
					map.non_land_pos[#map.non_land_pos+1] = strpos
				end
			end,
			get = function(pos)
				local strpos = Pos.ToString(pos)
				local map = Map.CachedQuery.SinglePos
				local record = map.data[strpos]
				if record~=nil then
					record.querying = true
					return record.landId
				end
				return nil
			end,
			clear = function(strpos) -- clear single pos's cache
				local map = Map.CachedQuery.SinglePos
				local record = map.data[strpos]
				if record==nil then
					return
				end
				local landId = record.landId
				if landId~=-1 then
					local pos = Array.Fetch(map.land_recorded_pos[landId],strpos)
					if pos ~= -1 then
						table.remove(map.land_recorded_pos[landId],pos)
					end
				else
					local pos = Array.Fetch(map.non_land_pos,strpos)
					if pos ~= -1 then
						table.remove(map.non_land_pos,pos)
					end
				end
				map.data[strpos] = nil
			end,
			check_noland_pos = function() -- when new land created, clear old non-land cached pos.
				local map = Map.CachedQuery.SinglePos
				for n,strpos in pairs(map.non_land_pos) do
					if ILAPI.PosGetLand(map.data[strpos].raw,true)~=-1 then
						map.clear(strpos)
					end
				end
			end,
			refresh = function(landId) -- remove single land's cache
				if landId==-1 then
					return
				end
				local map = Map.CachedQuery.SinglePos
				for n,strpos in pairs(map.land_recorded_pos[landId]) do
					map.data[strpos] = nil -- DO NOT USE map.clear!!
				end
				map.land_recorded_pos[landId] = {}
			end
		},
		RangeArea = {
			data = {},
			recorded_landId = {},
			add = function(lands,spos,epos,dimid)
				local map = Map.CachedQuery.RangeArea
				local cubestr = Cube.ToString(spos,epos,dimid)
				map.data[cubestr] = {
					raw = {
						startpos = spos,
						endpos = epos,
						dimid = dimid
					},
					landlist = lands,
					querying = true
				}
				for n,landId in pairs(lands) do
					map.recorded_landId[landId][#map.recorded_landId[landId]+1] = "this."..cubestr..".landlist.(*)"..n
				end
			end,
			get = function(spos,epos,dimid)
				local map = Map.CachedQuery.RangeArea
				local cubestr = Cube.ToString(spos,epos,dimid)
				local record = map.data[cubestr]
				if record ~= nil then
					record.querying = true
					return record.landlist
				end
				return nil
			end,
			clear_range = function(cubestr) -- clear single range's cache.
				local map = Map.CachedQuery.RangeArea
				for n,landId in pairs(map.data[cubestr].landlist) do
					local pos = Array.Fetch(map.recorded_landId[landId],"this."..cubestr..".landlist.(*)"..n)
					if pos~=-1 then
						table.remove(map.recorded_landId[landId],pos)
					end
				end
				map.data[cubestr] = nil
			end,
			clear_by_land = function(landId) -- clear cached "range" if "range" in this range.
				local map = Map.CachedQuery.RangeArea
				for cubestr,rangeInfo in pairs(map.data) do
					local r = rangeInfo.raw
					if Array.Fetch(ILAPI.GetLandInRange(r.startpos,r.endpos,r.dimid,true),landId)~=-1 then
						map.clear_range(cubestr)
					end
				end
			end,
			refresh = function(landId) -- remove single land's cache
				local map = Map.CachedQuery.RangeArea
				for n,path in pairs(map.recorded_landId[landId]) do
					table.setKey(map.data,path,nil)
				end
				map.recorded_landId[landId] = {}
			end
		},
		CACHE_MANAGER = function()
			local map = Map.CachedQuery
			for strpos,Info in pairs(map.SinglePos.data) do
				if Info.querying then
					map.SinglePos.data[strpos].querying = false
				else
					map.SinglePos.clear(strpos)
				end
			end
			for cubestr,Info in pairs(map.RangeArea.data) do
				if Info.querying then
					map.RangeArea.data[cubestr].querying = false
				else
					map.RangeArea.clear_range(cubestr)
				end
			end
		end
	}
}

--#region Plugin load.

ConfigReader = {
	Load = function(para) -- { cfg, land, owner }

		para = para or {1,1,1}

		local UpdateMe = {
			needed = false,
			version = 0
		}

		if para[1] == 1 then -- Load config.

			-- ## Pre-check
			if not File.exists(DATA_PATH..'config.json') then
				WARN('Data file (config.json) does not exist, creating...')
				File.writeTo(DATA_PATH..'config.json',JSON.encode(cfg))
			end
			local loadcfg = JSON.decode(File.readFrom(DATA_PATH..'config.json'))
			if cfg.version ~= loadcfg.version then -- need update
				UpdateMe.needed = true
				UpdateMe.version = loadcfg.version
				if not ConfigReader.Updater.config(loadcfg) then
					error('Configure file too old, you must rebuild it.')
					return false
				end
			end
			
			-- ## Read config
			local item
			for n,path in pairs(table.getAllPaths(cfg,false)) do
				item = table.getKey(loadcfg,path)
				if path ~= 'this.version' then
					if item == nil then
						WARN('cfg.'..string.sub(path,6)..' not found, reset to default.')
						UpdateMe.needed = true
					else
						table.setKey(cfg,path,item)
					end
				end
			end
	
			-- ## Correct if sth wrong

			if cfg.land.bought.square_range[1]>cfg.land.bought.square_range[2] then
				WARN('cfg.land.bought.square_range has an error, which has been corrected.')
				table.sort(cfg.land.bought.square_range)
				UpdateMe.needed = true
			end
			if cfg.economic.protocol~='llmoney' and cfg.economic.protocol~='scoreboard' then
				WARN('cfg.economic.protocol has an error, which has been corrected.')
				cfg.economic.protocol = 'scoreboard'
				UpdateMe.needed = true
			end
	
			-- ## Save if need update

			if UpdateMe.needed and not DEV_MODE then
				ILAPI.save({1,0,0})
			end

		end
		if para[2] == 1 then -- Load land.
			if not File.exists(DATA_PATH..'data.json') then
				WARN('Data file (data.json) does not exist, creating...')
				File.writeTo(DATA_PATH..'data.json','{}')
			end
			land_data = JSON.decode(File.readFrom(DATA_PATH..'data.json'))
			if UpdateMe.needed then
				ConfigReader.Updater.land(UpdateMe.version)
				if not DEV_MODE then
					ILAPI.save({0,1,0})
				end
			end
		end
		if para[3] == 1 then -- Load land owners.
			if not File.exists(DATA_PATH..'owners.json') then
				WARN('Data file (owners.json) does not exist, creating...')
				File.writeTo(DATA_PATH..'owners.json','{}')
			end
			local had_unloaded_xuid = false
			for ownerXuid,landIds in pairs(JSON.decode(File.readFrom(DATA_PATH..'owners.json'))) do
				if data.xuid2name(ownerXuid) == '' then
					WARN('Player (xuid: '..ownerXuid..') not found, skipping...')
					wrong_landowners[ownerXuid] = landIds
					had_unloaded_xuid = true
				else
					land_owners[ownerXuid] = landIds
				end
			end
			if had_unloaded_xuid then
				INFO('Some players are temporarily not loading because their XUID is not recorded in the database, please have them re-enter the server to make the database recorded.')
			end
		end
		return true
	end,
	Updater = {
		config = function(this)
			if this.version==nil or this.version<240 then
				return false
			end
			--- Update
			if this.version < 241 then -- OLD STRUCTURE
				local loadcfg = table.clone(cfg)
				loadcfg.plugin.language = this.manager.default_language
				loadcfg.plugin.network = this.update_check
				loadcfg.land.operator = this.manager.operator
				loadcfg.land.max_lands = this.land.player_max_lands
				loadcfg.land.bought.three_dimension.enable = this.features.land_3D
				loadcfg.land.bought.three_dimension.calculate_method = this.land_buy.calculation_3D
				loadcfg.land.bought.three_dimension.price = this.land_buy.price_3D
				loadcfg.land.bought.two_dimension.enable = this.features.land_2D
				loadcfg.land.bought.two_dimension.calculate_method = this.land_buy.calculation_2D
				loadcfg.land.bought.two_dimension.price = this.land_buy.price_2D
				loadcfg.land.bought.square_range = {this.land.land_min_square,this.land.land_max_square}
				loadcfg.land.bought.discount = this.money.discount/100
				loadcfg.land.refund_rate = this.land_buy.refund_rate
				loadcfg.economic.protocol = this.money.protocol
				loadcfg.economic.scoreboard_objname = this.money.scoreboard_objname
				loadcfg.economic.currency_name = this.money.credit_name
				loadcfg.features.landsign.enable = this.features.landSign
				loadcfg.features.landsign.frequency = this.features.sign_frequency
				loadcfg.features.buttomsign.enable = this.features.landSign
				loadcfg.features.buttomsign.frequency = this.features.sign_frequency
				loadcfg.features.particles.enable = this.features.particles
				loadcfg.features.particles.name = this.features.particle_effects
				loadcfg.features.particles.max_amount = this.features.player_max_ple
				loadcfg.features.player_selector.include_offline_players = this.features.offlinePlayerInList
				loadcfg.features.player_selector.items_perpage = this.features.playersPerPage
				loadcfg.features.selection.disable_dimension = this.features.blockLandDims
				loadcfg.features.selection.tool_type = this.features.selection_tool
				loadcfg.features.selection.tool_name = this.features.selection_tool_name
				loadcfg.features.landtp = this.features.landtp
				loadcfg.features.force_talk = this.features.force_talk
				loadcfg.features.disabled_listener = this.features.disabled_listener
				loadcfg.features.chunk_side = this.features.chunk_side
				this = loadcfg
			end
			if this.version < 260 then
				this.land.bought.three_dimension.calculate_method = nil
				this.land.bought.three_dimension.price = nil
				this.land.bought.two_dimension.calculate_method = nil
				this.land.bought.two_dimension.price = nil
				this.land.bought.three_dimension.calculate = "{square}*8+{height}*20"
				this.land.bought.two_dimension.calculate = "{square}*25"
			end
			if this.version < 262 then
				if type(this.land.bought.square_range)~='table' then
					this.land.bought.square_range = {4,50000}
				end
			end
			if this.version < 270 then
				local sec = this.features.selection
				sec.dimension = {true,true,true}
				if Array.Fetch(sec.disable_dimension,0)~=-1 then
					sec.dimension[1] = false
				end
				if Array.Fetch(sec.disable_dimension,1)~=-1 then
					sec.dimension[2] = false
				end
				if Array.Fetch(sec.disable_dimension,2)~=-1 then
					sec.dimension[3] = false
				end
				this.land.min_space = 15
				sec.disable_dimension = nil
			end
			--- Rtn
			return true
		end,
		land = function(version)
			if version<=240 then
				for landId,res in pairs(land_data) do
					local perm = land_data[landId].permissions
					perm.use_armor_stand = false
					perm.eat = false
				end
			end
			if version<=245 then
				for landId,res in pairs(land_data) do
					local setting = land_data[landId].settings
					setting.ev_redstone_update = false
				end
			end
			if version<=260 then
				for landId,res in pairs(land_data) do
					local perm = land_data[landId].permissions
					perm.useitem = nil
				end
			end
			return true
		end
	}
}

if not lxl.checkVersion(Plugin.minLXL[1],Plugin.minLXL[2],Plugin.minLXL[3]) then
	ERROR('Unsupported version of LiteXLoader, plugin loading aborted.')
	return
end

--#endregion

I18N = {
	TriedAutoFix = false,
	Init = function()
		local lang = cfg.plugin.language
		local stat = I18N.Load(lang)
		if stat ~= 0 and not I18N.TriedAutoFix then
			I18N.LangPack.Install(lang)
			I18N.TriedAutoFix = true
			I18N.Init()
			return
		end
		if stat == -1 then
			error('Language pack not found!')
		elseif stat == -2 then
			error('The language pack used is not suitable for this version!')
		end
	end,
	Load = function(lang)
		local path = DATA_PATH..'lang/'..lang..'.json'
		if not File.exists(path) then
			return -1
		end
		local pack = JSON.decode(File.readFrom(path))
		if pack.VERSION ~= Plugin.numver then
			return -2
		else
			I18N.LangPack.data = pack
		end
		return 0
	end,
	Install = function(lang)
		local stat = I18N.LangPack.Install(lang)
		if stat==-1 then
			ERROR(_Tr('console.languages.install.fail.stat'))
		elseif stat==-2 then
			ERROR(_Tr('console.languages.install.fail.verify','<a>',lang))
		elseif stat==-3 then
			ERROR(_Tr('console.languages.install.fail.version','<a>',lang))
		end
	end,
	Update = function(lang)
		local path = DATA_PATH..'lang/'
		local list_o = I18N.LangPack.GetRepo()
		local list_l = I18N.LangPack.GetInstalled()
		if File.exists(path..lang..'.json') then
			if Array.Fetch(list_l,lang)==-1 then
				ERROR(_Tr('console.languages.update.notfound','<a>',lang))
			elseif JSON.decode(File.readFrom(path..lang..'.json')).VERSION == Plugin.numver then
				ERROR(lang..': '.._Tr('console.languages.update.alreadylatest'))
			elseif Array.Fetch(list_o.official,lang)==-1 and Array.Fetch(list_o['3-rd'],lang)==-1 then
				ERROR(_Tr('console.languages.update.notfoundonline','<a>',lang))
			elseif I18N.LangPack.Install(lang) then
				INFO(_Tr('console.languages.update.succeed','<a>',lang))
				return true
			end
		else
			ERROR(_Tr('console.languages.update.notfound','<a>',lang))
		end
		return false
	end,
	LangPack = {
		data = {},
		Set = function(lang)
			local stat = I18N.Load(lang)
			if stat==0 then
				cfg.plugin.language = lang
				ILAPI.save({1,0,0})
			end
			return stat
		end,
		Install = function(lang)
			local lang_n = network.httpGetSync(Server.GetLink()..'/languages/'..lang..'.json')
			local lang_v = network.httpGetSync(Server.GetLink()..'/languages/'..lang..'.json.md5.verify')
			if lang_n.status~=200 or lang_v.status~=200 then
				return -1
			end
			local raw = string.gsub(lang_n.data,'\n','\r\n')
			if data.toMD5(raw)~=lang_v.data then
				return -2
			end
			local THISVER = JSON.decode(raw).VERSION
			if THISVER~=Plugin.numver then
				return -3
			end
			File.writeTo(DATA_PATH..'lang/'..lang..'.json',raw)
			return 0
		end,
		GetSign = function()
			local rtn = ""
			local count = 1
			while(I18N.LangPack.data['#'..count] ~= nil) do
				rtn = '\n'.._Tr('#'..count)
				count = count + 1
			end
			return rtn
		end,
		GetInstalled = function()
			local langs = {}
			for n,filename in pairs(File.getFilesList(DATA_PATH..'lang/')) do
				local tmp = string.split(filename,'.')
				if tmp[2] == 'json' then
					langs[#langs+1] = tmp[1]
				end
			end
			return langs
		end,
		GetRepo = function()
			local server = Server.GetLink()
			if server ~= false then
				local raw = network.httpGetSync(server..'/languages/repo.json')
				if raw.status==200 then
					return JSON.decode(raw.data)
				else
					ERROR(_Tr('console.getonline.failbycode','<a>',raw.status))
					return false
				end
			else
				WARN(_Tr('console.getonline.failed'))
				return false
			end
		end
	}
}

ConfigUIEditor = {
	Create = function(title,content)
		local ori = {
			title = title or "",
			content = content or "",
			components = {},
			types = {}
		}
		return ori
	end,
	RegisterType = function(ori,class)
		if ori.components[class] ~= nil then
			return false
		end
		ori.components[class] = {}
		ori.types[#ori.types+1] = class
		return true
	end,
	AddComponent = function(ori,class,uitype,cfgpath,extradata)
		--[[
			Class:
				use self.RegisterType at first.
			UIType:
				input			=>	string, number, etc.
				switch			=>	boolean.
				dropdown		=>	array.		[extradata] => {item1,item2,item3}
				percent_slider	=>	percent.
				slider			=>	range.		[extradata] => {min=,max=,step=}
				step_slider		=>	array.		[extradata] => {item1,item2,item3}
			Default:
				Auto get from cfg(cfgpath) if extradata = nil.
		]]
		if Array.Fetch({'input','switch','dropdown','percent_slider','slider','step_slider'},uitype)==-1 then
			WARN('Unknown component: '..uitype)
			return false
		end
		ori.components[class][#ori.components[class]+1] = {
			name = _Tr('path.<config> '..cfgpath),
			ui = uitype,
			path = cfgpath,
			data = extradata
		}
		return true
	end,
	Send = function(ori,player)
		local Form = mc.newCustomForm()
		Form:setTitle(ori.title)
		Form:addLabel(ori.content)
		ori.raw_items = {}
		for n,class in pairs(ori.types) do
			Form:addLabel('§l'..class)
			for n,cmp in pairs(ori.components[class]) do
				ori.raw_items[#ori.raw_items+1] = cmp
				if cmp.ui=='input' then
					Form:addInput(cmp.name,"",tostring(table.getKey(cfg,cmp.path)))
				elseif cmp.ui=='switch' then
					Form:addSwitch(cmp.name,table.getKey(cfg,cmp.path))
				elseif cmp.ui=='dropdown' then
					local pos = Array.Fetch(cmp.data,table.getKey(cfg,cmp.path))
					if pos==-1 then
						pos = 0
					else
						pos = pos - 1
					end
					Form:addDropdown(cmp.name,cmp.data,pos)
				elseif cmp.ui=='slider' then
					Form:addSlider(cmp.name,cmp.data.min,cmp.data.max,cmp.data.step,table.getKey(cfg,cmp.path))
				elseif cmp.ui=='percent_slider' then
					Form:addSlider(cmp.name,0,100,1,table.getKey(cfg,cmp.path)*100)
				elseif cmp.ui=='step_slider' then
					local pos = Array.Fetch(cmp.data,table.getKey(cfg,cmp.path))
					if pos==-1 then
						pos = 0
					else
						pos = pos - 1
					end
					Form:addStepSlider(cmp.name,cmp.data,pos)
				end
			end
		end
		player:sendForm(Form,function(player,res)
			if res==nil then
				return
			end
			local slf
			for n,result in pairs(res) do
				slf = ori.raw_items[n]
				if slf.ui=='input' then
					local oriType = type(table.getKey(cfg,slf.path))
					if oriType == 'number' then
						table.setKey(cfg,slf.path,tonumber(result))
					elseif oriType == 'string' then
						table.setKey(cfg,slf.path,tostring(result))
					end
				elseif slf.ui=='switch' then
					table.setKey(cfg,slf.path,result)
				elseif slf.ui=='dropdown' then
					if slf.data[result+1]~=nil then
						table.setKey(cfg,slf.path,slf.data[result+1])
					end
				elseif slf.ui=='slider' then	--- testless
					table.setKey(cfg,slf.path,result)
				elseif slf.ui=='percent_slider' then
					table.setKey(cfg,slf.path,result/100)
				elseif slf.ui=='step_slider' then	--- testless
					if slf.data[result+1]~=nil then
						table.setKey(cfg,slf.path,slf.data[result+1])
					end
				end
			end
			ILAPI.save({1,0,0})
			I18N.Load(cfg.plugin.language)
			player:sendModalForm(
				_Tr('gui.general.complete'),
				"Complete.",
				_Tr('gui.general.back'),
				_Tr('gui.general.close'),
				FormCallbacks.BackTo.LandOPMgr
			)
		end)
	end
}

OpenGUI = {
	FastLMgr = function(player,isOP)
		local xuid=player.xuid
		local thelands=ILAPI.GetPlayerLands(xuid)
		if #thelands==0 and isOP==nil then
			SendText(player,_Tr('title.landmgr.failed'));return
		end
	
		local landId = MEM[xuid].landId
		if land_data[landId]==nil then
			OpenGUI.LMgr(player)
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
			function(player,Id)
				if Id==nil then
					return
				elseif Id == 0 then
					OpenGUI.LandOptions.Information(player,landId)
				elseif Id == 1 then
					OpenGUI.LandOptions.Setting(player,landId)
				elseif Id == 2 then
					OpenGUI.LandOptions.Permission(player,landId)
				elseif Id == 3 then
					OpenGUI.LandOptions.Trust(player,landId)
				elseif Id == 4 then
					OpenGUI.LandOptions.Nickname(player,landId)
				elseif Id == 5 then
					OpenGUI.LandOptions.Describe(player,landId)
				elseif Id == 6 then
					OpenGUI.LandOptions.Transfer(player,landId)
				elseif Id == 7 then
					OpenGUI.LandOptions.Reselect(player,landId)
				elseif Id == 8 then
					OpenGUI.LandOptions.Delete(player,landId)
				end
			end
		)
	end,
	LMgr = function(player,targetXuid)
		local xuid = player.xuid
		local ownerXuid = targetXuid or xuid
	
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
			OpenGUI.FastLMgr(pl)
		end)
	end,
	OPLMgr = function(player)

		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.oplandmgr.landmgr.title'))
		Form:setContent(_Tr('gui.oplandmgr.landmgr.tip'))
		Form:addButton(_Tr('gui.oplandmgr.mgrtype.land'),'textures/ui/icon_book_writable')
		Form:addButton(_Tr('gui.oplandmgr.mgrtype.plugin'),'textures/ui/icon_setting')
		Form:addButton(_Tr('gui.oplandmgr.mgrtype.listener'),'textures/ui/icon_bookshelf')
		Form:addButton(_Tr('gui.general.close'))
		player:sendForm(Form,function(player,id)
			if id==nil then return end
			if id==0 then -- Manage Lands
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
							PlayerSelector.Create(player,function(pl,selected) 
								if #selected>1 then
									SendText(pl,_Tr('talk.tomany'))
									return
								end
								local thisXid = data.name2xuid(selected[1])
								OpenGUI.LMgr(pl,thisXid)
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
								ILAPI.Teleport(pl,landId)
							end)
						end
						if mode==2 then -- 脚下
							local landId = ILAPI.PosGetLand(player.blockPos)
							if landId==-1 then
								SendText(player,_Tr('gui.oplandmgr.landmgr.byfeet.errbynull'))
								return
							end
							MEM[xuid].landId = landId
							OpenGUI.FastLMgr(player,true)
						end
						if mode==3 then -- 返回
							FormCallbacks.BackTo.LandOPMgr(player,true)
						end
					
					end
				)
				return
			end
			if id==1 then -- Manage Plugin
				local origin = ConfigUIEditor.Create(_Tr('gui.oplandmgr.plugin.title'),_Tr('gui.oplandmgr.plugin.tip'))
				local function getAllObjectives()
					local objs = mc.getAllScoreObjectives()
					local rtn = {}
					for n,obj in pairs(objs) do
						rtn[#rtn+1] = obj.name
					end
					return rtn
				end
				local class = {
					plugin = _Tr('gui.oplandmgr.plugin.class.plugin'),
					land = _Tr('gui.oplandmgr.plugin.class.land'),
					economic = _Tr('gui.oplandmgr.plugin.class.economic'),
					feature_landsign = _Tr('gui.oplandmgr.plugin.class.feature_landsign'),
					feature_particle = _Tr('gui.oplandmgr.plugin.class.feature_particle'),
					feature_playerselector = _Tr('gui.oplandmgr.plugin.class.feature_playerselector'),
					other_features = _Tr('gui.oplandmgr.plugin.class.other_features')
				}
				ConfigUIEditor.RegisterType(origin,class.plugin)
				ConfigUIEditor.RegisterType(origin,class.land)
				ConfigUIEditor.RegisterType(origin,class.economic)
				ConfigUIEditor.RegisterType(origin,class.feature_landsign)
				ConfigUIEditor.RegisterType(origin,class.feature_particle)
				ConfigUIEditor.RegisterType(origin,class.feature_playerselector)
				ConfigUIEditor.RegisterType(origin,class.other_features)
				ConfigUIEditor.AddComponent(origin,class.plugin,'switch','this.plugin.network')
				ConfigUIEditor.AddComponent(origin,class.plugin,'dropdown','this.plugin.language',I18N.LangPack.GetInstalled())
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.max_lands')
				ConfigUIEditor.AddComponent(origin,class.land,'switch','this.land.bought.three_dimension.enable')
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.bought.three_dimension.calculate')
				ConfigUIEditor.AddComponent(origin,class.land,'switch','this.land.bought.two_dimension.enable')
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.bought.two_dimension.calculate')
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.bought.square_range.(*)1')
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.bought.square_range.(*)2')
				ConfigUIEditor.AddComponent(origin,class.land,'input','this.land.min_space')
				ConfigUIEditor.AddComponent(origin,class.land,'percent_slider','this.land.bought.discount')
				ConfigUIEditor.AddComponent(origin,class.land,'percent_slider','this.land.refund_rate')
				ConfigUIEditor.AddComponent(origin,class.land,'switch','this.features.selection.dimension.(*)1')
				ConfigUIEditor.AddComponent(origin,class.land,'switch','this.features.selection.dimension.(*)2')
				ConfigUIEditor.AddComponent(origin,class.land,'switch','this.features.selection.dimension.(*)3')
				ConfigUIEditor.AddComponent(origin,class.economic,'dropdown','this.economic.protocol',{'llmoney','scoreboard'})
				ConfigUIEditor.AddComponent(origin,class.economic,'dropdown','this.economic.scoreboard_objname',getAllObjectives())
				ConfigUIEditor.AddComponent(origin,class.economic,'input','this.economic.currency_name')
				ConfigUIEditor.AddComponent(origin,class.feature_landsign,'switch','this.features.landsign.enable')
				ConfigUIEditor.AddComponent(origin,class.feature_landsign,'input','this.features.landsign.frequency')
				ConfigUIEditor.AddComponent(origin,class.feature_landsign,'switch','this.features.buttomsign.enable')
				ConfigUIEditor.AddComponent(origin,class.feature_landsign,'input','this.features.buttomsign.frequency')
				ConfigUIEditor.AddComponent(origin,class.feature_particle,'switch','this.features.particles.enable')
				ConfigUIEditor.AddComponent(origin,class.feature_particle,'input','this.features.particles.name')
				ConfigUIEditor.AddComponent(origin,class.feature_particle,'input','this.features.particles.max_amount')
				ConfigUIEditor.AddComponent(origin,class.feature_playerselector,'switch','this.features.player_selector.include_offline_players')
				ConfigUIEditor.AddComponent(origin,class.feature_playerselector,'input','this.features.player_selector.items_perpage')
				ConfigUIEditor.AddComponent(origin,class.other_features,'switch','this.features.landtp')
				ConfigUIEditor.AddComponent(origin,class.other_features,'switch','this.features.force_talk')
				ConfigUIEditor.AddComponent(origin,class.other_features,'input','this.features.chunk_side')
				ConfigUIEditor.Send(origin,player)
				return
			end
			if id==2 then -- Manage Listener
				local Form = mc.newCustomForm()
				Form:setTitle(_Tr('gui.listenmgr.title'))
				Form:addLabel(_Tr('gui.listenmgr.tip'))
				Form:addSwitch('onDestroyBlock',not(ILAPI.IsDisabled('onDestroyBlock')))
				Form:addSwitch('onPlaceBlock',not(ILAPI.IsDisabled('onPlaceBlock')))
				Form:addSwitch('onUseItemOn',not(ILAPI.IsDisabled('onUseItemOn')))
				Form:addSwitch('onAttackEntity',not(ILAPI.IsDisabled('onAttackEntity')))
				Form:addSwitch('onAttackBlock',not(ILAPI.IsDisabled('onAttackBlock')))
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
				Form:addSwitch('onPistonTryPush',not(ILAPI.IsDisabled('onPistonTryPush')))
				Form:addSwitch('onFireSpread',not(ILAPI.IsDisabled('onFireSpread')))
				Form:addSwitch('onChangeArmorStand',not(ILAPI.IsDisabled('onChangeArmorStand')))
				Form:addSwitch('onEat',not(ILAPI.IsDisabled('onEat')))
				Form:addSwitch('onRedStoneUpdate',not(ILAPI.IsDisabled('onRedStoneUpdate')))
	
				player:sendForm(
					Form,
					function(player,res)
						if res==nil then return end
					
						cfg.features.disabled_listener = {}
						local dbl = cfg.features.disabled_listener
						if not(res[1]) then dbl[#dbl+1] = "onDestroyBlock" end
						if not(res[2]) then dbl[#dbl+1] = "onPlaceBlock" end
						if not(res[3]) then dbl[#dbl+1] = "onUseItemOn" end
						if not(res[4]) then dbl[#dbl+1] = "onAttackEntity" end
						if not(res[5]) then dbl[#dbl+1] = "onAttackBlock" end
						if not(res[6]) then dbl[#dbl+1] = "onExplode" end
						if not(res[7]) then dbl[#dbl+1] = "onBedExplode" end
						if not(res[8]) then dbl[#dbl+1] = "onRespawnAnchorExplode" end
						if not(res[9]) then dbl[#dbl+1] = "onTakeItem" end
						if not(res[10]) then dbl[#dbl+1] = "onDropItem" end
						if not(res[11]) then dbl[#dbl+1] = "onBlockInteracted" end
						if not(res[12]) then dbl[#dbl+1] = "onUseFrameBlock" end
						if not(res[13]) then dbl[#dbl+1] = "onSpawnProjectile" end
						if not(res[14]) then dbl[#dbl+1] = "onFireworkShootWithCrossbow" end
						if not(res[15]) then dbl[#dbl+1] = "onStepOnPressurePlate" end
						if not(res[16]) then dbl[#dbl+1] = "onRide" end
						if not(res[17]) then dbl[#dbl+1] = "onWitherBossDestroy" end
						if not(res[18]) then dbl[#dbl+1] = "onFarmLandDecay" end
						if not(res[19]) then dbl[#dbl+1] = "onPistonTryPush" end
						if not(res[20]) then dbl[#dbl+1] = "onFireSpread" end
						if not(res[21]) then dbl[#dbl+1] = "onChangeArmorStand" end
						if not(res[22]) then dbl[#dbl+1] = "onEat" end
						if not(res[23]) then dbl[#dbl+1] = "onRedStoneUpdate" end
						
						Map.Listener.build()
						ILAPI.save({1,0,0})
						player:sendModalForm(
							_Tr('gui.general.complete'),
							"Complete.",
							_Tr('gui.general.back'),
							_Tr('gui.general.close'),
							FormCallbacks.BackTo.LandOPMgr
						)
					
					end
				)
			end
		end)
	
	end,
	LandOptions = {
		Information = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local cubeInfo = Cube.GetInformation(Map.Land.Position.data[landId].a,Map.Land.Position.data[landId].b)
			local owner = ILAPI.GetOwner(landId)
			if owner~='?' then owner=data.xuid2name(owner) end
			player:sendModalForm(
				_Tr('gui.landmgr.landinfo.title'),
				_Tr('gui.landmgr.landinfo.content',
					'<a>',owner,
					'<b>',MakeShortILD(landId),
					'<c>',ILAPI.GetNickname(landId,false),
					'<d>',ILAPI.GetDimension(landId),
					'<e>',ToStrDim(land_data[landId].range.dimid),
					'<f>',Pos.ToString(Map.Land.Position.data[landId].a),
					'<g>',Pos.ToString(Map.Land.Position.data[landId].b),
					'<h>',cubeInfo.length,'<i>',cubeInfo.width,'<j>',cubeInfo.height,
					'<k>',cubeInfo.square,'<l>',cubeInfo.volume
				),
				_Tr('gui.general.iknow'),
				_Tr('gui.general.close'),
				FormCallbacks.BackTo.LandMgr
			)
		end,
		Setting = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
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
			Form:addLabel(_Tr('gui.landcfg.event'))
			Form:addSwitch(_Tr('gui.landcfg.event.explode'),settings.ev_explode) 
			Form:addSwitch(_Tr('gui.landcfg.event.farmland_decay'),settings.ev_farmland_decay)
			Form:addSwitch(_Tr('gui.landcfg.event.fire_spread'),settings.ev_fire_spread)
			Form:addSwitch(_Tr('gui.landcfg.event.piston_push'),settings.ev_piston_push)
			Form:addSwitch(_Tr('gui.landcfg.event.redstone_update'),settings.ev_redstone_update)
			player:sendForm(
				Form,
				function (player,res)
					if res==nil then return end
	
					local settings = land_data[landId].settings
					settings.signtome = res[1]
					settings.signtother = res[2]
					settings.signbuttom = res[3]
					settings.ev_explode = res[4]
					settings.ev_farmland_decay = res[5]
					settings.ev_fire_spread = res[7]
					settings.ev_piston_push = res[6]
					settings.ev_redstone_update = res[8]
					ILAPI.save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						FormCallbacks.BackTo.LandMgr
					)
				end
			)
		end,
		Permission = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
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
				
					ILAPI.save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						FormCallbacks.BackTo.LandMgr
					)
				end
			)
		end,
		Trust = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
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
			player:sendForm(Form,function(pl,res) -- [0] add [1] del
				if res==nil then return end
				local list = {};
				if res==1 then -- del
					for i,v in pairs(shareList) do
						list[#list+1] = data.xuid2name(v)
					end
				elseif res==0 then
					list = nil
				end
				PlayerSelector.Create(pl,function(player,selected)
					local status_list = {}
					if res==0 then -- add
						for n,ID in pairs(selected) do
							local targetXuid=data.name2xuid(ID)
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
						FormCallbacks.BackTo.LandMgr
					)
				end,list)
			end)
		end,
		Nickname = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local nickn = ILAPI.GetNickname(landId,false)
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
						FormCallbacks.BackTo.LandMgr
					)
				end
			)
		end,
		Describe = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
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
						FormCallbacks.BackTo.LandMgr
					)
				end
			)
		end,
		Transfer = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			player:sendModalForm(
				_Tr('gui.landtransfer.title'),
				_Tr('gui.landtransfer.tip'),
				_Tr('gui.general.yes'),
				_Tr('gui.general.close'),
				function(pl,ids)
					if not ids then return end
					PlayerSelector.Create(
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
								FormCallbacks.BackTo.LandMgr
							)
						end
					)
				end
			)
		end,
		Reselect = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			player:sendModalForm(
				_Tr('gui.reselectland.title'),
				_Tr('gui.reselectland.tip'),
				_Tr('gui.general.yes'),
				_Tr('gui.general.cancel'),
				function(player,result)
					if not result then return end
					local xuid = player.xuid
	
					MEM[xuid].reselectLand = { id = landId }
					RangeSelector.Create(player,function(player,res)
						MEM[xuid].keepingTitle = {
							_Tr('title.selectland.complete1'),
							_Tr('title.selectland.complete2','<a>',cfg.features.selection.tool_name,'<b>','land ok')
						}
						MEM[xuid].reselectLand.range = res
					end)
				end
			)
		end,
		Delete = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local cubeInfo = Cube.GetInformation(Map.Land.Position.data[landId].a,Map.Land.Position.data[landId].b)
			local value = math.modf(CalculatePrice(cubeInfo,ILAPI.GetDimension(landId))*cfg.land.refund_rate)
			player:sendModalForm(
				_Tr('gui.delland.title'),
				_Tr('gui.delland.content','<a>',value,'<b>',cfg.economic.currency_name),
				_Tr('gui.general.yes'),
				_Tr('gui.general.cancel'),
				function (player,id)
					if not id then return end
					if ILAPI.GetOwner(landId)==xuid then
						Money.Add(player,value)
					end
					ILAPI.DeleteLand(landId)
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						FormCallbacks.BackTo.LandMgr
					)
				end
			)
		end
	}
}

PlayerSelector = {
	Create = function (player,callback,customlist) -- player selector
	
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
			MEM[xuid].psr.playerList = 	PlayerSelector.Helper.ToPages(customlist,perpage)
		else
			MEM[xuid].psr.playerList = PlayerSelector.Helper.ToPages(pl_list,perpage)
		end
	
		-- call
		PlayerSelector.Callback(player,'#')
	
	end,
	Callback = function (player,data)
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
		local rawList = table.clone(psrdata.playerList[psrdata.nowpage])
	
		if type(data)=='table' then
			local selected = {}
	
			-- refresh page
			local npg = data[#data] + 1 -- custom page
			if npg~=psrdata.nowpage and npg<=maxpage then
				psrdata.nowpage = npg
				rawList = table.clone(psrdata.playerList[npg])
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
				local tableList = PlayerSelector.Helper.ToPages(tmpList,perpage)
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
		player:sendForm(Form,PlayerSelector.Callback)
	end,
	Helper = {
		ToPages = function(list,perpage)
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
	}
}

RangeSelector = {
	Create = function(player,callback) -- world range selector
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
		RangeSelector.Push(player)
	end,
	Push = function(player,pos)
		--[[ ENUM: setps
			(0) -> Chose dimension.
			(1) -> Select posA.
			(2) -> Select posB.
			(3) -> [3D-Only] Move Y.
			(4) -> Complete.
		]]
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
					if (res and not cfg.land.bought.three_dimension.enable) or (not res and not cfg.land.bought.two_dimension.enable) then
						SendText(player,_Tr('title.rangeselector.dimension.blocked'))
						RangeSelector.Clear(player)
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
			if not cfg.features.selection.dimension[dimid+1] then
				SendText(player,_Tr('title.rangeselector.fail.dimblocked'))
				return
			end
			if MEM[xuid].rsr.dimension=='2D' then
				pos.y = minY
			end
			MEM[xuid].rsr.posA = pos
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
			if MEM[xuid].rsr.dimension ~= '3D' then
				MEM[xuid].rsr.step = 3
				RangeSelector.Push(player,pos)
				return
			end
	
			local posA = MEM[xuid].rsr.posA
			local Form = mc.newCustomForm()
			Form:setTitle(_Tr('gui.rangeselector.title'))
			Form:addLabel(_Tr('gui.rangeselector.tip'))
			Form:addLabel(_Tr('gui.rangeselector.selectedpos','<a>',posA.x,'<b>',posA.y,'<c>',posA.z,'<d>',pos.x,'<e>',pos.y,'<f>',pos.z))
			Form:addSlider(_Tr('gui.rangeselector.movestarty'),minY,maxY,1,posA.y)
			Form:addSlider(_Tr('gui.rangeselector.moveendy'),minY,maxY,1,pos.y)
			player:sendForm(Form,function(player,res)
				if res==nil then return end
				MEM[xuid].rsr.posA.y = res[1]
				pos.y = res[2]
				MEM[xuid].rsr.step = 3
				RangeSelector.Push(player,pos)
			end)
			return
		end
		if MEM[xuid].rsr.step == 3 then
			if MEM[xuid].rsr.dimid ~= dimid then
				SendText(player,_Tr('title.rangeselector.fail.dimdiff'))
				return
			end
	
			local posA = MEM[xuid].rsr.posA
			if MEM[xuid].rsr.dimension=='2D' then
				pos.y = maxY
			end
	
			--- Check Land.
			local checkPassed = false
			local cubeInfo = Cube.GetInformation(posA,pos)
			if cubeInfo.square < cfg.land.bought.square_range[1] and not ILAPI.IsLandOperator(xuid) then
				SendText(player,_Tr('title.rangeselector.fail.toosmall'))
			elseif cubeInfo.square > cfg.land.bought.square_range[2] and not ILAPI.IsLandOperator(xuid) then
				SendText(player,_Tr('title.rangeselector.fail.toobig'))
			elseif cubeInfo.height < 2 and MEM[xuid].rsr.dimension == '3D' then
				SendText(player,_Tr('title.rangeselector.fail.toolow'))
			else
				local checkIgnores = {}
				if MEM[xuid].reselectLand~=nil then
					checkIgnores = { MEM[xuid].reselectLand.id }
				end
				local checkColl = ILAPI.IsLandCollision(posA,pos,dimid,checkIgnores)
				if checkColl.status then
					local sp = cfg.land.min_space
					local nearbyLands = ILAPI.GetLandInRange(Pos.Add(posA,sp),Pos.Reduce(pos,sp),dimid)
					if #nearbyLands ~= 0 then
						SendText(player,_Tr('title.rangeselector.fail.space','<a>',MakeShortILD(nearbyLands[1])))
					else
						checkPassed = true
					end
				else
					SendText(player,_Tr('title.rangeselector.fail.collision','<a>',MakeShortILD(checkColl.id),'<b>',Pos.ToString(checkColl.pos)))
				end
			end
	
			--- Check Result.
			if not checkPassed then
				MEM[xuid].rsr.step = 1
				MEM[xuid].keepingTitle[2] = _Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','A')
				return
			end
	
			--- Apply.
			MEM[xuid].rsr.posB = pos
			MEM[xuid].rsr.posA,MEM[xuid].rsr.posB = Pos.Sort(posA,MEM[xuid].rsr.posB)
			MEM[xuid].keepingTitle = nil
			local edge
			if MEM[xuid].rsr.dimension == '3D' then
				edge = Cube.GetEdge(MEM[xuid].rsr.posA,MEM[xuid].rsr.posB)
			else
				edge = Cube.GetEdge_2D(MEM[xuid].rsr.posA,MEM[xuid].rsr.posB,player.pos.y+1)
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
	
			MEM[xuid].rsr.step = 4
			local cb = MEM[xuid].rsr.cbfunc
			cb(player,{posA=MEM[xuid].rsr.posA,posB=MEM[xuid].rsr.posB,dimid=MEM[xuid].rsr.dimid,dimension=MEM[xuid].rsr.dimension})
			return
		end
		if MEM[xuid].rsr.step == 4 then
			-- what the fxxk handle...
			if MEM[xuid].newLand~=nil then
				player:runcmd("land buy")
			end
			if MEM[xuid].reselectLand~=nil then
				player:runcmd("land ok")
			end
			return
		end
	end,
	Clear = function(player)
		local xuid = player.xuid
		MEM[xuid].rsr = nil
		MEM[xuid].keepingTitle = nil
		MEM[xuid].particles = nil
	end
}

SafeTeleport = {
	Cancel = function(player)
		local xuid = player.xuid
		if xuid==nil or MEM[xuid]==nil or MEM[xuid].safetp==nil then
			return
		end
		local tpos = MEM[xuid].safetp.from_pos
		player:teleport(tpos.x,tpos.y,tpos.z,tpos.dimid)
		MEM[xuid].safetp = nil
	end,
	Do = function(player,tpos)
		local function getHeightRange(dimensionId)
			local range = {
				[0] = {-64,320},
				[1] = {0,128 - 2}, -- because,, top bedrock.
				[2] = {0,256}
			}
			return range[dimensionId]
		end
		if type(player)=='string' then
			player = mc.getPlayer(player)
		end
		local xuid = player.xuid
		local dimid = tpos.dimid
		if MEM[xuid].safetp ~= nil then -- limited: one request.
			return false
		end
		MEM[xuid].safetp = {
			from_pos = player.pos,
			to_pos = tpos
		}
		local def_height = 500
		local timeout = 60
		player:teleport(tpos.x,def_height,tpos.z,dimid)
		SendText(player,_Tr('api.safetp.tping.talk'))
		local chunk_loaded = false
		local cancel_check = false
		local lock = false
		local completed = false
		local id = setInterval(function()
			if cancel_check or lock or player==nil then
				return
			end
			local plpos = Pos.ToIntPos(player.pos)
			if plpos==nil or tpos.x~=plpos.x or tpos.z~=plpos.z or dimid~=plpos.dimid then
				cancel_check = true
				SafeTeleport.Cancel(player)
				return
			end
			if player:getAbilities().flying==1 then
				SendTitle(player,_Tr('talk.pleasewait'),_Tr('api.safetp.tping.disablefly'),{0,5,0})
				local nbt = player:getNbt()
				nbt:getTag("abilities"):getTag("flying"):set(0)
				player:setNbt(nbt)
				return
			end
			if plpos.y == def_height and not chunk_loaded then
				SendTitle(player,_Tr('talk.pleasewait'),_Tr('api.safetp.tping.chunkloading'),{0,15,15})
			else
				chunk_loaded = true
				lock = true
				SendTitle(player,_Tr('talk.pleasewait'),_Tr('api.safetp.tping.foundfoothold'),{0,15,15})
				local bl_type_list = {}
				local footholds = {}
				local y_range = getHeightRange(dimid)
				for i=y_range[1],y_range[2] do
					local bl = mc.getBlock(tpos.x,i,tpos.z,dimid)
					bl_type_list[i] = bl.type
				end
				local ct_block = {'minecraft:air','minecraft:lava','minecraft:flowing_lava'}
				for i,type in pairs(bl_type_list) do
					if Array.Fetch(ct_block,type)==-1 and bl_type_list[i+1]==ct_block[1] and bl_type_list[i+2]==ct_block[1] then
						footholds[#footholds+1] = i
					end
				end
				if #footholds==0 then
					SendText(player,_Tr('api.safetp.fail.nofoothold'))
					SafeTeleport.Cancel(player)
					return
				end
				local recentY = footholds[1]
				for i,y in pairs(footholds) do
					if math.abs(tpos.y-y)<math.abs(tpos.y-recentY) then
						recentY = y
					end
				end
				player:teleport(tpos.x,recentY + 1,tpos.z,dimid)
				MEM[xuid].safetp = nil
				completed = true
			end
		end,500)
		setTimeout(function()
			clearInterval(id)
			if MEM[xuid]~=nil then
				if not completed and MEM[xuid].safetp~=nil then
					SendText(player,_Tr('api.safetp.fail.timeout'))
					SafeTeleport.Cancel(mc.getPlayer(xuid))
				end
				MEM[xuid].safetp = nil
			end
		end,timeout*1000)
	end
}

DebugHelper = {
	IsEnabled = false,
	Interval = function()
		if not DebugHelper.IsEnabled then
			return
		end
		for n,player in pairs(mc.getOnlinePlayers()) do
			local pos = player.blockPos
			local r = 50
			local list = ILAPI.GetLandInRange(Pos.Add(pos,r),Pos.Reduce(pos,r),pos.dimid)
			INFO('Debug','Position ('..Pos.ToString(pos)..'), Land = '..ILAPI.PosGetLand(pos)..'.')
			if #list~=0 then
				INFO('Debug','Nearby lands \n'..table.toDebugString(list))
			else
				INFO('Debug','There is no land nearby.')
			end
		end
	end
}

--#region ILAPI

-- [[ KERNEL ]]
function ILAPI.CreateLand(xuid,startpos,endpos,dimid)
	local landId
	while true do
		landId = GenGUID()
		if land_data[landId]==nil then break end
	end

	local posA,posB = Pos.Sort(startpos,endpos)
	if not ILAPI.IsLandCollision(posA,posB,dimid).status then
		return -1
	end

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
			ev_fire_spread = false,
			ev_redstone_update = false
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
		permissions = {
			allow_destroy = false,
			allow_entity_destroy = false,
			allow_place = false,
			allow_attack_player = false,
			allow_attack_animal = false,
			allow_attack_mobs = true,
			allow_open_chest = false,
			allow_pickupitem = false,
			allow_dropitem = true,
			use_anvil = false,
			use_barrel = false,
			use_beacon = false,
			use_bed = false,
			use_bell = false,
			use_blast_furnace = false,
			use_brewing_stand = false,
			use_campfire = false,
			use_firegen = false,
			use_cartography_table = false,
			use_composter = false,
			use_crafting_table = false,
			use_daylight_detector = false,
			use_dispenser = false,
			use_dropper = false,
			use_enchanting_table = false,
			use_door = false,
			use_fence_gate = false,
			use_furnace = false,
			use_grindstone = false,
			use_hopper = false,
			use_jukebox = false,
			use_loom = false,
			use_stonecutter = false,
			use_noteblock = false,
			use_shulker_box = false,
			use_smithing_table = false,
			use_smoker = false,
			use_trapdoor = false,
			use_lectern = false,
			use_cauldron = false,
			use_lever = false,
			use_button = false,
			use_respawn_anchor = false,
			use_item_frame = false,
			use_fishing_hook = false,
			use_bucket = false,
			use_pressure_plate = false,
			use_armor_stand = false,
			eat = false,
			allow_throw_potion = false,
			allow_ride_entity = false,
			allow_ride_trans = false,
			allow_shoot = false,
			useitem = false
		}
	}

	-- Write data
	if land_owners[xuid]==nil then -- ilapi
		land_owners[xuid]={}
	end

	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	ILAPI.save({0,1,1})
	Map.Land.Position.update(landId,'add')
	Map.Chunk.update(landId,'add')
	Map.Land.Owner.update(landId)
	Map.Land.Trusted.update(landId)
	Map.Land.Edge.update(landId,'add')
	Map.Land.AXIS.update(landId,'add')
	Map.CachedQuery.Init(landId)
	Map.CachedQuery.RangeArea.clear_by_land(landId)
	Map.CachedQuery.SinglePos.check_noland_pos()
	return landId
end
function ILAPI.DeleteLand(landId)
	local owner=ILAPI.GetOwner(landId)
	if owner~='?' then
		table.remove(land_owners[owner],Array.Fetch(land_owners[owner],landId))
	end
	Map.CachedQuery.RangeArea.refresh(landId)
	Map.CachedQuery.SinglePos.refresh(landId)
	Map.CachedQuery.UnInit(landId)
	Map.Land.AXIS.update(landId,'del')
	Map.Chunk.update(landId,'del')
	Map.Land.Position.update(landId,'del')
	Map.Land.Edge.update(landId,'del')
	land_data[landId] = nil
	ILAPI.save({0,1,1})
	return true
end
function ILAPI.PosGetLand(vec4,noAccessCache)

	noAccessCache = noAccessCache or false
	if not noAccessCache then
		local cache_result = Map.CachedQuery.SinglePos.get(vec4)
		if cache_result ~= nil then
			return cache_result
		end
	end 
	
	local Cx,Cz = Pos.ToChunkPos(vec4)
	local dimid = vec4.dimid
	if Map.Chunk.data[dimid][Cx]~=nil and Map.Chunk.data[dimid][Cx][Cz]~=nil then
		for n,landId in pairs(Map.Chunk.data[dimid][Cx][Cz]) do
			if dimid==land_data[landId].range.dimid and Cube.HadPos(vec4,Map.Land.Position.data[landId].a,Map.Land.Position.data[landId].b) then
				if not noAccessCache then
					Map.CachedQuery.SinglePos.add(landId,vec4)
				end
				return landId
			end
		end
	end

	if not noAccessCache then
		Map.CachedQuery.SinglePos.add(-1,vec4)
	end
	return -1

end
function ILAPI.GetChunk(vec2,dimid)
	local Cx,Cz = Pos.ToChunkPos(vec2)
	if Map.Chunk.data[dimid][Cx]~=nil and Map.Chunk.data[dimid][Cx][Cz]~=nil then
		return table.clone(Map.Chunk.data[dimid][Cx][Cz])
	end
	return -1
end
function ILAPI.GetDistence(landId,vec4)
	local function pow(num)
		return num*num
	end
	local function EucM(A,B) -- 2D
		return math.sqrt(pow(B.x-A.x)+pow(B.z-A.z))
	end

	local edge = Map.Land.Edge.data[landId].D2D
	local depos = { edge[1],EucM(edge[1],vec4) }
	for i,pos in pairs(edge) do
		local euc = EucM(pos,vec4)
		if euc<depos[2] then
			depos = { pos,euc }
		end
	end
	if ILAPI.GetDimension(landId)=='2D' then
		return depos[2]
	end
	return math.sqrt(pow(depos[2])+pow(math.min(math.abs(vec4.y-Map.Land.Position.data[landId].a.y),math.abs(vec4.y-Map.Land.Position.data[landId].b.y))))
end
function ILAPI.GetLandInRange(spos,epos,dimid,noAccessCache)

	noAccessCache = noAccessCache or false
	if not noAccessCache then
		local cache_result = Map.CachedQuery.RangeArea.get(spos,epos,dimid)
		if cache_result~=nil then
			return cache_result
		end
	end

	local result = {}
	local tmp_lands = {}
	local function keyMapEx(tab,needKey,unaddIfNon)
		if tab==nil then
			return
		end
		unaddIfNon = unaddIfNon or false
		for n,v in pairs(tab) do
			if not unaddIfNon or tmp_lands[v]~=nil then
				tmp_lands[v] = needKey
			end
		end
	end

	for x = spos.x,epos.x do
		local am = Map.Land.AXIS.data[dimid]['x'][x]
		keyMapEx(am,1)
	end
	for y = spos.y,epos.y do
		local am = Map.Land.AXIS.data[dimid]['y'][y]
		keyMapEx(am,2,true)
	end
	for z = spos.z,epos.z do
		local am = Map.Land.AXIS.data[dimid]['z'][z]
		keyMapEx(am,3,true)
	end
	
	-- add land if this meet requirements.
	for landId,count in pairs(tmp_lands) do
		if count == 3 then
			result[#result+1] = landId
		end
	end
	
	if not noAccessCache then
		Map.CachedQuery.RangeArea.add(result,spos,epos,dimid)
	end
	return result

end
function ILAPI.GetAllLands()
	local lst = {}
	for id,v in pairs(land_data) do
		lst[#lst+1] = id
	end
	return lst
end
function ILAPI.CheckPerm(landId,perm)
	return land_data[landId].permissions[perm]
end
function ILAPI.CheckSetting(landId,cfgname)
	return land_data[landId].settings[cfgname]
end
function ILAPI.GetRange(landId)
	return { Map.Land.Position.data[landId].a,Map.Land.Position.data[landId].b,land_data[landId].range.dimid }
end
function ILAPI.GetEdge(landId,dimtype)
	if dimtype=='2D' then
		return table.clone(Map.Land.Edge.data[landId].D2D)
	elseif dimtype=='3D' then
		return table.clone(Map.Land.Edge.data[landId].D3D)
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
	return land_data[landId].settings.nickname
end
function ILAPI.GetDescribe(landId)
	return land_data[landId].settings.describe
end
function ILAPI.GetOwner(landId)
	for i,v in pairs(land_owners) do
		if Array.Fetch(v,landId)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI.GetPoint(landId)
	local i = table.clone(land_data[landId].settings.tpoint)
	i[4] = land_data[landId].range.dimid
	return Array.ToIntPos(i)
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
	SafeTeleport.Do(pl,pos)
	return true
end
-- [[ INFORMATION => PLAYER ]]
function ILAPI.GetPlayerLands(xuid)
	return table.clone(land_owners[xuid])
end
function ILAPI.IsPlayerTrusted(landId,xuid)
	if Map.Land.Trusted.data[landId][xuid]==nil then
		return false
	else
		return true
	end
end
function ILAPI.IsLandOwner(landId,xuid)
	if Map.Land.Owner.data[landId]==xuid then
		return true
	else
		return false
	end
end
function ILAPI.IsLandOperator(xuid)
	if Map.Land.Operator.data[xuid]==nil then
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
	land_data[landId].permissions[perm]=value
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.UpdateSetting(landId,cfgname,value)
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
	Map.Land.Trusted.update(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.RemoveTrust(landId,xuid)
	local shareList = land_data[landId].settings.share
	table.remove(shareList,Array.Fetch(shareList,xuid))
	Map.Land.Trusted.update(landId)
	ILAPI.save({0,1,0})
	return true
end
function ILAPI.SetOwner(landId,xuid)
	local ownerXuid = ILAPI.GetOwner(landId)
	if ownerXuid ~= '?' then
		table.remove(land_owners[ownerXuid],Array.Fetch(land_owners[ownerXuid],landId))
	end
	table.insert(land_owners[xuid],#land_owners[xuid]+1,landId)
	Map.Land.Owner.update(landId)
	ILAPI.save({0,0,1})
	return true
end
-- [[ PLUGIN ]]
function ILAPI.GetMoneyProtocol()
	return cfg.economic.protocol
end
function ILAPI.GetLanguage()
	return cfg.plugin.language
end
function ILAPI.GetChunkSide()
	return cfg.features.chunk_side
end
function ILAPI.IsDisabled(listener)
	if Map.Listener.data[listener]~=nil then
		return true
	end
	return false
end
function ILAPI.GetApiVersion()
	return Plugin.apiver
end
function ILAPI.GetVersion()
	return Plugin.numver
end
-- [[ UNEXPORT FUNCTIONS ]]
function ILAPI.save(mode) -- {config,data,owners}
	if mode[1] == 1 then
		File.writeTo(DATA_PATH..'config.json',JSON.encode(cfg))
	end
	if mode[2] == 1 then
		File.writeTo(DATA_PATH..'data.json',JSON.encode(land_data))
	end
	if mode[3] == 1 then
		local tmpowners = table.clone(land_owners)
		for xuid,landIds in pairs(wrong_landowners) do
			tmpowners[xuid] = landIds
		end
		File.writeTo(DATA_PATH..'owners.json',JSON.encode(tmpowners))
	end
end
function ILAPI.CanControl(mode,name)
	if Map.Control.data[mode][name]==nil then
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
			n = n..' '..MakeShortILD(landId)
		end
	end
	return n
end
function ILAPI.IsLandCollision(newposA,newposB,newDimid,ignoreList) -- 领地冲突判断
	ignoreList = ignoreList or {}
	local ignores = Array.ToKeyMap(ignoreList)
	local edge = Cube.GetEdge(newposA,newposB)
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
			edge = Map.Land.Edge.data[landId].D3D
			if ignores[landId]==nil then
				for i=1,#edge do
					if Cube.HadPos(edge[i],newposA,newposB)==true then
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
function ILAPI.GetMemoryCount()
	return tonumber(string.format("%.2f",collectgarbage('count')/1024))
end
function ILAPI.SetRange(landId,newposA,newposB,newDimid)

	if ILAPI.GetDimension(landId) == '2D' then
		newposA.y = minY
		newposB.y = maxY
	end
	if not ILAPI.IsLandCollision(newposA,newposB,newDimid,{landId}).status then
		return false
	end
	local posA,posB = Pos.Sort(newposA,newposB)

	Map.Land.Edge.update(landId,'del')
	Map.Chunk.update(landId,'del')
	Map.Land.AXIS.update(landId,'del')
	Map.Land.Position.update(landId,'del')
	land_data[landId].range.start_position = {posA.x,posA.y,posA.z}
	land_data[landId].range.end_position = {posB.x,posB.y,posB.z}
	land_data[landId].range.dimid = newDimid
	land_data[landId].settings.tpoint = {posA.x,posA.y+1,posA.z}
	Map.Land.Edge.update(landId,'add')
	Map.Chunk.update(landId,'add')
	Map.Land.Position.update(landId,'add')
	Map.Land.AXIS.update(landId,'add')
	Map.CachedQuery.RangeArea.refresh(landId)
	Map.CachedQuery.SinglePos.refresh(landId)
	Map.CachedQuery.RangeArea.clear_by_land(landId)
	Map.CachedQuery.SinglePos.check_noland_pos()

	ILAPI.save({0,1,0})
	return true
end

--#endregion

-- Types

Money = {
	Get = function(player)
		local ptc = cfg.economic.protocol
		if ptc=='scoreboard' then
			return player:getScore(cfg.economic.scoreboard_objname)
		elseif ptc=='llmoney' then
			return money.get(player.xuid)
		else
			ERROR(_Tr('console.error.money.protocol','<a>',ptc))
		end
	end,
	Add = function(player,value)
		local ptc = cfg.economic.protocol
		if ptc=='scoreboard' then
			player:addScore(cfg.economic.scoreboard_objname,value)
		elseif ptc=='llmoney' then
			money.add(player.xuid,value)
		else
			ERROR(_Tr('console.error.money.protocol','<a>',ptc))
		end
	end,
	Del = function(player,value)
		local ptc = cfg.economic.protocol
		if ptc=='scoreboard' then
			player:setScore(cfg.economic.scoreboard_objname,player:getScore(cfg.economic.scoreboard_objname)-value)
		elseif ptc=='llmoney' then
			money.reduce(player.xuid,value)
		else
			ERROR(_Tr('console.error.money.protocol','<a>',ptc))
		end
	end
}

Cube = {
	ToString = function(spos,epos,dimid)
		spos,epos = Pos.Sort(spos,epos)
		return Pos.ToString(spos)..'|'..Pos.ToString(epos)..'|'..dimid
	end,
	HadPos = function(pos,posA,posB)
		if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
			if (pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y) then
				if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
					return true
				end
			end
		end
		return false
	end,
	GetEdge = function(spos,epos)
		local edge={}
		local posB,posA = Pos.Sort(spos,epos)
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
	end,
	GetEdge_2D = function(spos,epos,customY)
		local edge={}
		local posB,posA = Pos.Sort(spos,epos)
		if customY==nil then
			customY = posA.y - 1
		end
		for i=1,math.abs(posA.x-posB.x)+1 do
			edge[#edge+1] = { x=posA.x-i+1, y=customY, z=posA.z }
			edge[#edge+1] = { x=posA.x-i+1, y=customY, z=posB.z }
		end
		for i=1,math.abs(posA.z-posB.z)+1 do
			edge[#edge+1] = { x=posA.x, y=customY, z=posA.z-i+1 }
			edge[#edge+1] = { x=posB.x, y=customY, z=posA.z-i+1 }
		end
		return edge
	end,
	GetInformation = function(spos,epos)
		local cube = {
			height = math.abs(spos.y-epos.y) + 1,
			length = math.max(math.abs(spos.x-epos.x),math.abs(spos.z-epos.z)) + 1,
			width = math.min(math.abs(spos.x-epos.x),math.abs(spos.z-epos.z)) + 1,

		}
		cube.square = cube.length*cube.width
		cube.volume = cube.square*cube.height
		return cube
	end
}

Pos = {
	ToChunkPos = function(pos)
		local p = cfg.features.chunk_side
		return math.floor(pos.x/p),math.floor(pos.z/p)
	end,
	ToIntPos = function(pos)
		local result = {
			x = math.floor(pos.x),
			y = math.floor(pos.y),
			z = math.floor(pos.z)
		}
		if pos.dimid ~= nil then
			result.dimid = pos.dimid
		end
		return result
	end,
	ToString = function(vec3)
		return vec3.x..','..vec3.y..','..vec3.z
	end,
	Add = function(pos,value)
		return {
			x = pos.x + value,
			y = pos.y + value,
			z = pos.z + value
		}
	end,
	Reduce = function(pos,value)
		return {
			x = pos.x - value,
			y = pos.y - value,
			z = pos.z - value
		}
	end,
	IsEqual = function(posA,posB)
		if posA.x==posB.x and posA.y==posB.y and posA.z==posB.z and posA.dimid==posB.dimid then
			return true
		end
		return false
	end,
	Sort = function(posA,posB)
		local A = posA
		local B = posB
		if A.x>B.x then A.x,B.x = B.x,A.x end
		if A.y>B.y then A.y,B.y = B.y,A.y end
		if A.z>B.z then A.z,B.z = B.z,A.z end
		return A,B
	end
}

AABB = {
	Traverse = function(AAbb,aaBB,did)
		local posA,posB = Pos.Sort(AAbb,aaBB)
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
}

Array = {
	ToIntPos = function(array)
		local rtn = {
			x = math.floor(array[1]),
			y = math.floor(array[2]),
			z = math.floor(array[3])
		}
		if array[4]~=nil then
			rtn.dimid=array[4]
		end
		return rtn
	end,
	ToNonRepeated = function(array)
		local tmp = Array.ToKeyMap(array)
		local result = {}
		for i,v in pairs(tmp) do
			result[#result+1] = i
		end
		return result  
	end,
	ToKeyMap = function(array)
		local rtn = {}
		for k,v in pairs(array) do
			rtn[v] = 0
		end
		return rtn
	end,
	Fetch = function(array, value)
		for i, nowValue in pairs(array) do
			if nowValue == value then
				return i
			end
		end
		return -1
	end,
	Concat = function(origin,array)
		for n,k in pairs(array) do
			origin[#origin+1] = k
		end
		return origin
	end,
	Reverse = function(tab)
		local tmp_tab = table.clone(tab)
		local rtn = {}
		for i = 1,#tmp_tab do
			rtn[i] = table.remove(tmp_tab)
		end
		return rtn
	end
}

function Server.GetLink()
	local tokenRaw = network.httpGetSync('https://lxl-cloud.amd.rocks/id.json')
	if tokenRaw.status~=200 then
		return false
	end
	local id = JSON.decode(tokenRaw.data).token
	return Server.link..id..'/iLand'
end

--#region Native Types Helper

-- string helper

function string.split(str,reps)
	local result = {}
	string.gsub(str,'[^'..reps..']+',function (n)
		table.insert(result,n)
	end)
	return result
end

function string.gsubEx(key,...)
	local tWd = false
	local result = key
	local args = {...}

	for n,word in pairs(args) do
		if tWd then
			result = string.gsub(result,args[n-1],word)
		end
		tWd = not(tWd)
	end

	return result
end

-- table helper

local function typeEx(value)
	local T = type(value)
	if T ~= 'table' then
		return T
	else
		if table.isArray(value) then
			return 'array'
		else
			return 'table'
		end
	end
end

function table.clone(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[table.clone(orig_key)] = table.clone(orig_value)
		end
		setmetatable(copy, table.clone(getmetatable(orig)))
	else
		copy = orig
	end
	return copy
end

function table.isArray(tab)
	local count = 1
	for k,v in pairs(tab) do
		if type(k) ~= 'number' or k~=count then
			return false
		end
		count = count + 1
	end
	return true
end

function table.getAllPaths(tab,ExpandArray,UnNeedThisPrefix)
	local result = {}
	local inner_tmp
	for k,v in pairs(tab) do
		local Tk = typeEx(k)
		local Tv = typeEx(v)
		if Tv == 'table' or (ExpandArray and Tv == 'array') then
			inner_tmp = table.getAllPaths(v,ExpandArray,true)
			for a,b in pairs(inner_tmp) do
				result[#result+1] = k..'.'..b
			end
		else
			result[#result+1] = k
		end
		if Tk == 'number' then
			result[#result] = '(*)'..result[#result]
		end
	end
	if UnNeedThisPrefix==nil or not UnNeedThisPrefix then
		for i,v in pairs(result) do
			result[i] = 'this.'..result[i]
		end
	end

	return result
end

function table.getKey(tab,path)

	--[[
		What is "path"?
		[A] the_table: {a=2,b=7,n=42,ok={pap=626}}
			<path> this.b			=>		7
			<path> this.ok.pap		=>		626
		[B] the_table: {2,3,1,ff={8}}
			<path> this.(*)3		=>		1
			<path> this.ff.(*)1		=>		8
	]]
	
	if string.sub(path,1,5) == 'this.' then
		path = string.sub(path,6)
	end

	local pathes = string.split(path,'.')
	if #pathes == 0 then
		return tab
	end
	if string.sub(pathes[1],1,3) == '(*)' then
		pathes[1] = tonumber(string.sub(pathes[1],4))
	end
	local lta = tab[pathes[1]]

	if type(lta) ~= 'table' then
		return lta
	end
	
	return table.getKey(lta,table.concat(pathes,'.',2,#pathes))

end

function table.setKey(tab,path,value)

	if string.sub(path,1,5) == 'this.' then
		path = string.sub(path,6)
	end

	local pathes = string.split(path,'.')
	if string.sub(pathes[1],1,3) == '(*)' then
		pathes[1] = tonumber(string.sub(pathes[1],4))
	end

	if tab[pathes[1]] == nil then
		return
	end
	
	local T = typeEx(tab[pathes[1]])
	if T ~= 'table' and (T~='array' or (T=='array' and typeEx(value)=='array')) then
		tab[pathes[1]] = value
		return
	end
	
	table.setKey(tab[pathes[1]],table.concat(pathes,'.',2,#pathes),value)

end

function table.toDebugString(tab)
	local rtn = 'Total: '..#tab
	for k,v in pairs(tab) do
		rtn = rtn..'\n'..tostring(k)..'\t'..tostring(v)
	end
	return rtn
end

--#endregion

function Plugin.Unload()
	mc.runcmdEx('lxl unload iland-core.lua')
end

function Plugin.Upgrade(rawInfo)
	
	--[[
		The directory structure for server:
		# source = .../iLand/{numver}/...
		Vars:
		$plugin_path	plugins/
		$data_path		plugins/iland/
		Example(numver=245):
		$plugin_path::iland-core.lua	=>	H://server.link/abc/iLand/245/iland-core.lua
		$data_path::lang/zh_CN.json		=>	H://server.link/abc/iLand/245/lang/zh_CN.json
	]]

	local function recoverBackup(dt)
		INFO('AutoUpdate',_Tr('console.autoupdate.recoverbackup'))
		for n,backupfilename in pairs(dt) do
			File.rename(backupfilename..'.bak',backupfilename)
		end
	end
	local function isLXLSupported(list)
		local version = lxl.version()
		for n,ver in pairs(list) do
			if ver[1]==version.major and ver[2]==version.minor and ver[3]==version.revision then
				return true
			end
		end
		return false
	end

	--  Check Data
	local updata
	local checkPassed = false
	if rawInfo.Updates[2]~=nil and rawInfo.Updates[2].NumVer~=Plugin.numver then
		ERROR(_Tr('console.update.vacancy'))
	elseif rawInfo.FILE_Version~=Server.version then
		ERROR(_Tr('console.getonline.failbyver','<a>',rawInfo.FILE_Version))
	elseif rawInfo.DisableClientUpdate then
		ERROR(_Tr('console.update.disabled'))
	else
		updata = rawInfo.Updates[1]
		if not isLXLSupported(updata.LXL) then
			ERROR(_Tr('console.update.unsupport'))
		else
			checkPassed = true
		end
	end
	if not checkPassed then
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
	local server = Server.GetLink()
	local source
	if server ~= false then
		source = server..'/'..updata.NumVer..'/'
	else
		WARN(_Tr('console.getonline.failed'))
		return false
	end
	
	INFO('AutoUpdate',Plugin.version..' => '..updata.Version)
	RawPath['$plugin_path'] = 'plugins/'
	RawPath['$data_path'] = DATA_PATH
	
	-- Known changed files.
	updata.FileChanged[#updata.FileChanged+1] = "$plugin_path::iland-core.lua"

	-- Get it, update.
	for n,thefile in pairs(updata.FileChanged) do
		local raw = string.split(thefile,'::')
		local path = RawPath[raw[1]]..raw[2]
		INFO('Network',_Tr('console.autoupdate.download')..raw[2])
		
		if File.exists(path) then -- create backup
			File.rename(path,path..'.bak')
			BackupEd[#BackupEd+1]=path
		end

		local tmp = network.httpGetSync(source..raw[2])
		local tmp2 = network.httpGetSync(source..raw[2]..'.md5.verify')
		if tmp.status~=200 or tmp2.status~=200 then -- download check
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

		File.writeTo(path,raw)
	end
	
	INFO('AutoUpdate',_Tr('console.autoupdate.success'))
	Plugin.Reload()

end

function Plugin.Reload()
	mc.runcmdEx('lxl reload iland-core.lua')
end

-- Tools & Feature functions.

function _Tr(a,...)
	if DEV_MODE and I18N.LangPack.data[a]==nil then
		WARN('Translation not found: '..a)
		return
	end
	local rtn = I18N.LangPack.data[a]
	return string.gsubEx(rtn,...)
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
	if mode==nil and not cfg.features.force_talk then 
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
function CalculatePrice(cubeInfo,dimension)
	local ecode
	if dimension=='3D' then
		ecode = string.gsubEx(cfg.land.bought.three_dimension.calculate)
	elseif dimension=='2D' then
		ecode = string.gsubEx(cfg.land.bought.two_dimension.calculate)
	end
	local price = lxl.eval(string.gsubEx(
		'return '..ecode,
		'{height}',cubeInfo.height,
		'{length}',cubeInfo.length,
		'{width}',cubeInfo.width,
		'{square}',cubeInfo.square,
		'{volume}',cubeInfo.volume
	))
	if type(price)~='number' then
		WARN('Something wrong when calculate, dimension = '..dimension..'.')
		price = 0
	end
	return math.floor(price*(cfg.land.bought.discount))
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
function ToStrDim(a)
	if a==0 then
		return _Tr('talk.dim.zero')
	elseif a==1 then
		return _Tr('talk.dim.one')
	elseif a==2 then
		return _Tr('talk.dim.two')
	else
		return _Tr('talk.dim.other')
	end
end
function ChkNil(...)
	local list = {...}
	local count = 0
	for i,v in ipairs(list) do
		count = count + 1
	end
	return count~=#list
end
function EntityGetType(type)
	if type=='minecraft:player' then
		return 0
	end
	if Map.Control.data[4].animals[type]~=nil then
		return 1
	end
	if Map.Control.data[4].mobs[type]~=nil then
		return 2
	end
	return 0
end
function MakeShortILD(landId)
	return string.sub(landId,0,16) .. '....'
end
local function try(func)
	local stat, res = pcall(func[1])
	if not stat then
		func[2](res)
	end
	return res
 end
local function catch(err)
	return err[1]
end

function RegisterCommands()

	-- ## [Client] Command Registry

	mc.regPlayerCmd(MainCmd,_Tr('command.land'),function(player,args)
		if #args~=0 then
			SendText(player,_Tr('command.error','<a>',args[1]),0)
			return
		end
		local pos = player.blockPos
		local xuid = player.xuid
		local landId = ILAPI.PosGetLand(pos)
		if landId~=-1 and ILAPI.GetOwner(landId)==xuid then
			MEM[xuid].landId=landId
			OpenGUI.FastLMgr(player)
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
					elseif id==1 then
						player:runcmd(MainCmd..' gui')
					elseif id==2 then
						player:runcmd(MainCmd..' tp')
					end
				end
			)
		end
	end)
	mc.regPlayerCmd(MainCmd..' new',_Tr('command.land_new'),function (player,args)
		local xuid = player.xuid

		if MEM[xuid].reselectLand~=nil then
			SendText(player,_Tr('title.reselectland.fail.makingnewland'))
			return
		end
		if MEM[xuid].newLand~=nil then
			SendText(player,_Tr('title.getlicense.alreadyexists'))
			return
		end
		if not ILAPI.IsLandOperator(xuid) and #land_owners[xuid]>=cfg.land.max_lands then
			SendText(player,_Tr('title.getlicense.limit'))
			return
		end

		MEM[xuid].newLand = {}
		RangeSelector.Create(player,function(player,res)
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
			RangeSelector.Clear(player)
			SendText(player,_Tr('title.giveup.succeed'))
		elseif MEM[xuid].reselectLand~=nil then
			MEM[xuid].reselectLand = nil
			RangeSelector.Clear(player)
			SendText(player,_Tr('title.reselectland.giveup.succeed'))
		end
	end)
	mc.regPlayerCmd(MainCmd..' gui',_Tr('command.land_gui'),function (player,args)
		OpenGUI.LMgr(player)
	end)
	mc.regPlayerCmd(MainCmd..' set',_Tr('command.land_set'),function (player,args)
		local xuid = player.xuid
		if MEM[xuid].rsr ~= nil then
			RangeSelector.Push(player,player.blockPos)
		else
			SendText(player,_Tr('title.rangeselector.fail.outmode'))
		end
	end)
	mc.regPlayerCmd(MainCmd..' buy',_Tr('command.land_buy'),function (player,args)
		local xuid = player.xuid
		if MEM[xuid].newLand==nil or MEM[xuid].newLand.range==nil then
			SendText(player,_Tr('talk.invalidaction'))
			return
		end
		local res = MEM[xuid].newLand.range
		local cubeInfo = Cube.GetInformation(res.posA,res.posB)
		local price = CalculatePrice(cubeInfo,res.dimension)
		local discount_info = ''
		local dimension_info = ''
		if cfg.land.bought.discount<1 then
			discount_info=_Tr('gui.buyland.discount','<a>',tostring((1-cfg.land.bought.discount)*100))
		end
		if res.dimension=='3D' then
			dimension_info = '§l3D-Land §r'
		else
			dimension_info = '§l2D-Land §r'
		end
		local Form = mc.newSimpleForm()
		Form:setTitle(dimension_info.._Tr('gui.buyland.title')..discount_info)
		Form:setContent(
			_Tr('gui.buyland.content',
			'<a>',cubeInfo.length,
			'<b>',cubeInfo.width,
			'<c>',cubeInfo.height,
			'<d>',cubeInfo.volume,
			'<e>',price,
			'<f>',cfg.economic.currency_name,
			'<g>',Money.Get(player)
		))
		Form:addButton(_Tr('gui.buyland.button.confirm'),'textures/ui/realms_green_check')
		Form:addButton(_Tr('gui.buyland.button.close'),'textures/ui/recipe_book_icon')
		Form:addButton(_Tr('gui.buyland.button.cancel'),'textures/ui/realms_red_x')
		player:sendForm(Form,
			function (player,res)
				if res==nil or res==1 then
					SendText(player,_Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name))
					return
				end
				if res==2 then
					player:runcmd('land giveup')
					return
				end
			
				local xuid = player.xuid
				local range = MEM[xuid].newLand.range
				local player_credits = Money.Get(player)
				local landId
				if price > player_credits then
					SendText(player,_Tr('title.buyland.moneynotenough').._Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name))
					return
				else
					landId = ILAPI.CreateLand(xuid,range.posA,range.posB,range.dimid)
					if landId~=-1 then
						Money.Del(player,price)
						SendText(player,_Tr('title.buyland.succeed'))
						player:sendModalForm(
							'Complete.',
							_Tr('gui.buyland.succeed'),
							_Tr('gui.general.looklook'),
							_Tr('gui.general.cancel'),
							function(player,res)
								if res then
									MEM[xuid].landId = landId
									OpenGUI.FastLMgr(player)
								end
							end
						)
					else
						SendText(player,_Tr('title.buyland.fail.apirefuse'))
					end
					RangeSelector.Clear(player)
					MEM[xuid].newLand = nil
				end
			end)
	end)
	mc.regPlayerCmd(MainCmd..' ok',_Tr('command.land_ok'),function (player,args)
		local xuid = player.xuid
		if MEM[xuid].reselectLand==nil or MEM[xuid].reselectLand.range==nil then
			SendText(player,_Tr('talk.invalidaction'))
			return
		end
		local res = MEM[xuid].reselectLand.range
		local cubeInfo = Cube.GetInformation(res.posA,res.posB)
		local old_cubeInfo = Cube.GetInformation(Map.Land.Position.data[MEM[xuid].reselectLand.id].a,Map.Land.Position.data[MEM[xuid].reselectLand.id].b)

		-- Checkout
		local nr_price = CalculatePrice(cubeInfo,res.dimension)
		local or_price = CalculatePrice(old_cubeInfo,res.dimension)
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
				if not result then return end
				local status
				if payT==0 and Money.Get(player)<needto then
					SendText(player,_Tr('title.buyland.moneynotenough'))
					return
				end
				status = ILAPI.SetRange(landId,res.posA,res.posB,res.dimid)
				if status then
					if payT==0 then
						Money.Del(player,needto)
					else
						Money.Add(player,needto)
					end
				else
					SendText(player,_Tr('title.reselectland.fail.apirefuse'))
				end
				MEM[xuid].reselectLand = nil
				SendText(player,_Tr('title.reselectland.succeed'))
				RangeSelector.Clear(player)
			end
		)
	end)
	mc.regPlayerCmd(MainCmd..' mgr',_Tr('command.land_mgr'),function (player,args)
		local xuid = player.xuid
		if not ILAPI.IsLandOperator(xuid) then
			SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
			return false
		end
		OpenGUI.OPLMgr(player)
	end)
	mc.regPlayerCmd(MainCmd..' mgr selectool',_Tr('command.land_mgr_selectool'),function (player,args)
		local xuid = player.xuid
		if Array.Fetch(cfg.land.operator,xuid)==-1 then
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
			tplands[#tplands+1] = ToStrDim(xpos.dimid)..' ('..Pos.ToString(xpos)..') '..name
			landlst[#landlst+1] = landId
		end
		for i,landId in pairs(ILAPI.GetAllTrustedLand(xuid)) do
			local name = ILAPI.GetNickname(landId)
			local xpos = ILAPI.GetPoint(landId)
			tplands[#tplands+1]='§l'.._Tr('gui.landtp.trusted')..'§r '..ToStrDim(xpos.dimid)..'('..Pos.ToString(xpos)..') '..name
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
			ILAPI.Teleport(player,landId)
		end
		)
	end)
	mc.regPlayerCmd(MainCmd..' tp set',_Tr('command.land_tp_set'),function (player,args)
		if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
		local xuid = player.xuid
		local pos = player.blockPos

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
			pos.y + 1,
			pos.z
		}
		ILAPI.save({0,1,0})
		player:sendModalForm(
			_Tr('gui.general.complete'),
			_Tr('gui.landtp.point','<a>',Pos.ToString({x=pos.x,y=pos.y+1,z=pos.z}),'<b>',landname),
			_Tr('gui.general.iknow'),
			_Tr('gui.general.close'),
			FormCallbacks.NULL
		)
	end)
	mc.regPlayerCmd(MainCmd..' tp rm',_Tr('command.land_tp_rm'),function (player,args)
		if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
		local xuid = player.xuid
		local pos = player.blockPos

		local landId=ILAPI.PosGetLand(pos)
		if landId==-1 then
			SendText(player,_Tr('title.landtp.fail.noland'))
			return false
		end
		if ILAPI.GetOwner(landId)~=xuid then
			SendText(player,_Tr('title.landtp.fail.notowner'))
			return false
		end
		local def = Map.Land.Position.data[landId].a
		land_data[landId].settings.tpoint = {
			def.x,
			def.y + 1,
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
		INFO('Memory Used: '..ILAPI.GetMemoryCount()..'MB')
	end)
	mc.regConsoleCmd(MainCmd..' op',_Tr('command.console.land_op'),function(args)
		local name = table.concat(args,' ')
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
		Map.Land.Operator.update()
		ILAPI.save({1,0,0})
		INFO('System',_Tr('console.landop.add.success','<a>',name,'<b>',xuid))
	end)
	mc.regConsoleCmd(MainCmd..' deop',_Tr('command.console.land_deop'),function(args)
		local name = table.concat(args,' ')
		local xuid = data.name2xuid(name)
		if xuid == "" then
			ERROR(_Tr('console.landop.failbyxuid','<a>',name))
			return
		end
		if not ILAPI.IsLandOperator(xuid) then
			ERROR(_Tr('console.landop.del.failbynull','<a>',name))
			return
		end
		table.remove(cfg.land.operator,Array.Fetch(cfg.land.operator,xuid))
		Map.Land.Operator.update()
		ILAPI.save({1,0,0})
		INFO('System',_Tr('console.landop.del.success','<a>',name,'<b>',xuid))
	end)
	mc.regConsoleCmd(MainCmd..' update',_Tr('command.console.land_update'),function(args)
		if cfg.plugin.network then
			Plugin.Upgrade(Server.memData)
		else
			ERROR(_Tr('console.update.nodata'))
		end
	end)
	mc.regConsoleCmd(MainCmd..' language',_Tr('command.console.land_language'),function(args)
		INFO('I18N',_Tr('console.languages.sign','<a>',cfg.plugin.language,'<b>',_Tr('VERSION')))
		INFO('I18N',I18N.LangPack.GetSign())
	end)
	mc.regConsoleCmd(MainCmd..' language list',_Tr('command.console.land_language_list'),function(args)
		local list = I18N.LangPack.GetInstalled()
		for i,lang in pairs(list) do
			if lang==cfg.plugin.language then
				INFO('I18N',lang..' <- Using.')
			else
				INFO('I18N',lang)
			end
		end
		INFO('I18N',_Tr('console.languages.list.count','<a>',#list))
	end)
	mc.regConsoleCmd(MainCmd..' language list-online',_Tr('command.console.land_language_list-online'),function(args)
		INFO('Network',_Tr('console.languages.list-online.wait'))
		local rawdata = I18N.LangPack.GetRepo()
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
			return
		end
		INFO('Network',_Tr('console.languages.list-online.wait'))
		local rawdata = I18N.LangPack.GetRepo()
		if rawdata == false then
			return
		elseif Array.Fetch(I18N.LangPack.GetInstalled(),args[1])~=-1 then
			ERROR(_Tr('console.languages.install.existed'))
			return
		elseif Array.Fetch(rawdata.official,args[1])==-1 and Array.Fetch(rawdata['3-rd'],args[1])==-1 then
			ERROR(_Tr('console.languages.install.notfound','<a>',args[1]))
			return
		end
		INFO(_Tr('console.autoupdate.download'))
		if I18N.Install(args[1]) then
			INFO(_Tr('console.languages.install.succeed','<a>',args[1]))
		end
	end)
	mc.regConsoleCmd(MainCmd..' language update',_Tr('command.console.land_language_update'),function(args)
		local list = I18N.LangPack.GetInstalled()
		if args[1] == nil then
			INFO(_Tr('console.languages.update.all'))
			local count = 0
			for i,lang in pairs(list) do
				if I18N.Update(lang) then
					count = count + 1
				end
			end
			INFO(_Tr('console.languages.update.completed','<a>',count))
		else
			INFO(_Tr('console.languages.update.single','<a>',args[1]))
			I18N.Update(args[1])
		end
	end)
	mc.regConsoleCmd(MainCmd..' reload',_Tr('command.console.land_reload'),function(args)
		Plugin.Reload()
	end)
	mc.regConsoleCmd(MainCmd..' unload',_Tr('command.console.land_unload'),function(args)
		Plugin.Unload()
	end)

end

-- Callbacks

TimerCallbacks = {
	LandSign = function()
		for xuid,res in pairs(MEM) do
			local player = mc.getPlayer(xuid)
	
			if ChkNil(player) then
				goto JUMPOUT_LANDSIGN
			end
	
			local xuid = player.xuid
			local landId = ILAPI.PosGetLand(player.blockPos)
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
				if not landcfg.signtome then
					goto JUMPOUT_LANDSIGN
				end
				SendTitle(player,
					_Tr('sign.listener.ownertitle','<a>',ILAPI.GetNickname(landId,false)),
					_Tr('sign.listener.ownersubtitle')
				)
			else
				-- visitor
				if not landcfg.signtother then
					goto JUMPOUT_LANDSIGN
				end
				SendTitle(player,
					_Tr('sign.listener.visitortitle'),
					_Tr('sign.listener.visitorsubtitle','<a>',ownerId)
				)
				if landcfg.describe~='' then
					local des = table.clone(landcfg.describe)
					des = string.gsub(des,'$visitor',player.name)
					des = string.gsub(des,'$n','\n')
					SendText(player,des,0)
				end
			end
	
			MEM[xuid].inland = landId
			:: JUMPOUT_LANDSIGN ::
		end
	end,
	ButtomSign = function()
		for xuid,res in pairs(MEM) do
			local player = mc.getPlayer(xuid)
	
			if ChkNil(player) then
				goto JUMPOUT_BUTTOMSIGN
			end
	
			local landId = ILAPI.PosGetLand(player.blockPos)
			if landId==-1 then
				goto JUMPOUT_BUTTOMSIGN
			end
			local landcfg = land_data[landId].settings
			if not landcfg.signbuttom then
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
	end,
	MEM = function ()
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
}

FormCallbacks = {
	NULL = function(...) end,
	BackTo = {
		LandOPMgr = function(player,id)
			if not id then return end
			OpenGUI.OPLMgr(player)
		end,
		LandMgr = function (player,id)
			if not id then return end
			OpenGUI.FastLMgr(player)
		end
	}
}

EventCallbacks = {
	onExplode = function(source,pos,radius,range,isDestroy,isFire)

		if ILAPI.IsDisabled('onExplode') then
			return
		end
	
		local bp = Pos.ToIntPos(pos)
		local landId = ILAPI.PosGetLand(bp)
		if landId==-1 then
			local r = math.floor(radius) + 1
			local lands = ILAPI.GetLandInRange(Pos.Add(bp,r),Pos.Reduce(bp,r),pos.dimid)
			if #lands==0 then
				return
			end
			for i,landId in pairs(lands) do
				if not land_data[landId].settings.ev_explode then
					return false
				end 
			end
		else
			if land_data[landId].settings.ev_explode then
				return
			end 
		end
	
		return false
	end
}

-- Minecraft Eventing

mc.listen('onJoin',function(player)
	local xuid = player.xuid
	MEM[xuid] = { inland = 'null' }

	if wrong_landowners[xuid]~=nil then
		land_owners[xuid] = table.clone(wrong_landowners[xuid])
		for n,landId in pairs(land_owners[xuid]) do
			Map.Land.Owner.update(landId)
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

	if ChkNil(player,MEM[player.xuid]) then
		return
	end

	local xuid = player.xuid

	--- SafeTp
	if MEM[xuid].safetp ~= nil then
		SafeTeleport.Cancel(player)
	end
	
	MEM[xuid] = nil
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

	local landId = ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end -- No Land

	local xuid = player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	local IsConPlus = false
	if not ILAPI.CanControl(0,block.type) then 
		if not ILAPI.CanControl(2,item.type) then
			return
		else
			IsConPlus = true
		end
	end
	
	local perm = land_data[landId].permissions

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
		if bn == 'minecraft:dragon_egg' and perm.allow_destroy then return end -- 右键龙蛋（拓充）
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
mc.listen('onAttackBlock',function(player,block,item)

	if ChkNil(player,block) or ILAPI.IsDisabled('onAttackBlock') then
		return
	end

	local bltype = block.type
	if not ILAPI.CanControl(5,bltype) then
		return
	end

	local landId = ILAPI.PosGetLand(block.pos)
	if landId==-1 then return end

	local xuid = player.xuid
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	if bltype == 'minecraft:dragon_egg' and land_data[landId].permissions.allow_destroy then return end -- 左键龙蛋（拓充）

	SendText(player,_Tr('title.landlimit.noperm'))
	return false

end)
mc.listen('onAttackEntity',function(player,entity)

	if ChkNil(player,entity) or ILAPI.IsDisabled('onAttackEntity') then
		return
	end

	local landId = ILAPI.PosGetLand(entity.blockPos)
	if landId==-1 then return end

	local xuid = player.xuid
	local en = entity.type
	local perm = land_data[landId].permissions
	if ILAPI.CanControl(3,en) then
		if en == 'minecraft:ender_crystal' and perm.allow_destroy then return end -- 末地水晶（拓充）
		if en == 'minecraft:armor_stand' and perm.allow_destroy then return end -- 盔甲架（拓充）
	else
		local entityType = EntityGetType(en)
		if perm.allow_attack_player and entityType == 0 then return end
		if perm.allow_attack_animal and entityType == 1 then return end
		if perm.allow_attack_mobs and entityType == 2 then return end
	end

	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onChangeArmorStand',function(entity,player,slot)

	if ChkNil(entity,player) or ILAPI.IsDisabled('onChangeArmorStand') then
		return
	end

	local landId = ILAPI.PosGetLand(entity.blockPos)
	if landId==-1 then return end -- No Land

	local xuid = player.xuid
	if land_data[landId].permissions.use_armor_stand then return end
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onTakeItem',function(player,entity)

	if ChkNil(player,entity) or ILAPI.IsDisabled('onTakeItem') then
		return
	end

	local landId=ILAPI.PosGetLand(entity.blockPos)
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

	local landId=ILAPI.PosGetLand(player.blockPos)
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

	if not ILAPI.CanControl(1,block.type) then return end
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
mc.listen('onSpawnProjectile',function(splasher,entype)

	if ChkNil(splasher) or ILAPI.IsDisabled('onSpawnProjectile') or not splasher:isPlayer() then
		return
	end

	local landId = ILAPI.PosGetLand(splasher.blockPos)
	if landId == -1 then return end -- No Land

	local player = splasher:toPlayer()
	local xuid = player.xuid
	local perm = land_data[landId].permissions

	if entype == 'minecraft:fishing_hook' and perm.use_fishing_hook then return end -- 钓鱼竿
	if entype == 'minecraft:splash_potion' and perm.allow_throw_potion then return end -- 喷溅药水
	if entype == 'minecraft:lingering_potion' and perm.allow_throw_potion then return end -- 滞留药水
	if entype == 'minecraft:thrown_trident' and perm.allow_shoot then return end -- 三叉戟
	if entype == 'minecraft:arrow' and perm.allow_shoot then return end -- 弓&弩（箭）
	if entype == 'minecraft:snowball' and perm.allow_dropitem then return end -- 雪球
	if entype == 'minecraft:ender_pearl' and perm.allow_dropitem then return end -- 末影珍珠
	if entype == 'minecraft:egg' and perm.allow_dropitem then return end -- 鸡蛋

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

	local landId=ILAPI.PosGetLand(player.blockPos)
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

	local landId=ILAPI.PosGetLand(entity.blockPos)
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
				
	if ChkNil(rider,entity) or ILAPI.IsDisabled('onRide') then
		return
	end

	if rider:toPlayer()==nil then return end

	local landId=ILAPI.PosGetLand(rider.blockPos)
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
	for n,pos in pairs(AABB.Traverse(AAbb,aaBB,dimid)) do
		local landId=ILAPI.PosGetLand(pos)
		if landId~=-1 and not land_data[landId].permissions.allow_entity_destroy then 
			break
		end
	end
	return false
end)
mc.listen('onFarmLandDecay',function(pos,entity)
	
	if ChkNil(entity) or ILAPI.IsDisabled('onFarmLandDecay') then
		return
	end

	local landId=ILAPI.PosGetLand(entity.blockPos)
	if landId==-1 then return end -- No Land
	if land_data[landId].settings.ev_farmland_decay then return end -- EV Allow
	return false
end)
mc.listen('onPistonTryPush',function(pos,block)

	if ILAPI.IsDisabled('onPistonTryPush') then
		return
	end

	local Id_bePushedBlock = ILAPI.PosGetLand(block.pos)
	local Id_pistonBlock = ILAPI.PosGetLand(pos)
	if Id_bePushedBlock~=-1 and not land_data[Id_bePushedBlock].settings.ev_piston_push and Id_pistonBlock~=Id_bePushedBlock then
		return false
	end

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
	local landId=ILAPI.PosGetLand(player.blockPos)
	if landId==-1 then return end -- No Land

	if land_data[landId].permissions.eat then return end -- Perm Allow
	if ILAPI.IsLandOperator(xuid) then return end
	if ILAPI.IsLandOwner(landId,xuid) then return end
	if ILAPI.IsPlayerTrusted(landId,xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onRedStoneUpdate',function(block,level,isActive)

	if ILAPI.IsDisabled('onRedStoneUpdate') then
		return
	end

	local pos = block.pos
	local landId = ILAPI.PosGetLand(pos)
	if landId~=-1 then
		return
	end
	local r = 2
	local lands = ILAPI.GetLandInRange(Pos.Add(pos,r),Pos.Reduce(pos,r),pos.dimid)
	for i,Id in pairs(lands) do
		if not land_data[Id].settings.ev_redstone_update then
			return false
		end 
	end

end)
mc.listen('onStartDestroyBlock',function(player,block)

	local xuid = player.xuid
	if MEM[xuid].rsr ~= nil and (MEM[xuid].rsr.sleep==nil or MEM[xuid].rsr.sleep<os.time()) then
		local HandItem = player:getHand()
		if HandItem:isNull() or HandItem.type~=cfg.features.selection.tool_type then return end
		RangeSelector.Push(player,block.pos)
		MEM[xuid].rsr.sleep = os.time() + 2
	end

end)
mc.listen('onServerStarted',function()
	
	-- Make timer
	if cfg.features.landsign.enable then
		setInterval(TimerCallbacks.LandSign,cfg.features.landsign.frequency*1000)
	end
	if cfg.features.buttomsign.enable then
		setInterval(TimerCallbacks.ButtomSign,cfg.features.buttomsign.frequency*1000)
	end
	setInterval(TimerCallbacks.MEM,1000)
	if DEV_MODE then
		setInterval(DebugHelper.Interval,1500)
	end

	-- load owners data
	try
	{
		function ()
			-- load : data
			if ConfigReader.Load() ~= true then
				error('wrong!')
			end
			-- load : language
			I18N.Init()
			-- load : maps
			Map.Init()
			-- load : cmd
			RegisterCommands()
		end,
		catch
		{
			function (err)
				WARN(err)
				ERROR('Something wrong when load data, plugin closed.')
				Plugin.Unload()
			end
		}
	}

	-- Check Update
	if cfg.plugin.network and not DEV_MODE then
		local server = Server.GetLink()
		if server ~=  false then
			network.httpGet(server..'/server_203.json',function(code,result)
				if code~=200 then
					ERROR(_Tr('console.getonline.failbycode','<a>',code))
					return
				end
				local data = JSON.decode(result)
				Server.memData = data
		
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
						INFO('Update',_Tr('console.update.force','<a>',data.Updates[1].Version))
						Plugin.Upgrade(data)
					end
					if cfg.features.auto_update then
						INFO('Update',_Tr('console.update.auto'))
						Plugin.Upgrade(data)
					end
				end
				if Plugin.numver>data.Updates[1].NumVer then
					INFO('Network',_Tr('console.update.preview','<a>',Plugin.version))
				end

				-- Announcement
				if data.Announcement.enabled then
					INFO('Announcement',_Tr('console.announcement.founded'))
					for n,content in pairs(data.Announcement.content) do
						INFO('Announcement',n..'. '..content)
					end
				end
				
			end)
		else
			WARN(_Tr('console.getonline.failed'))
		end
	end

	INFO('Load','Completed, use memory: '..ILAPI.GetMemoryCount()..'MB.')

end)
mc.listen('onBlockExplode',EventCallbacks.onExplode)
mc.listen('onEntityExplode',EventCallbacks.onExplode)

-- Exported ILAPIs

lxl.export(ILAPI.CreateLand,'ILAPI_CreateLand')
lxl.export(ILAPI.DeleteLand,'ILAPI_DeleteLand')
lxl.export(ILAPI.PosGetLand,'ILAPI_PosGetLand')
lxl.export(ILAPI.GetChunk,'ILAPI_GetChunk')
lxl.export(ILAPI.GetDistence,'ILAPI_GetDistance')
lxl.export(ILAPI.GetLandInRange,'ILAPI_GetLandInRange')
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
lxl.export(ILAPI.IsDisabled,'ILAPI_IsListenerDisabled')
lxl.export(ILAPI.GetApiVersion,'ILAPI_GetApiVersion')
lxl.export(ILAPI.GetVersion,'ILAPI_GetVersion')
lxl.export(SafeTeleport.Do,"SafeTeleport_Do")

-- Signs.

INFO('Powerful land plugin is loaded! Ver-'..Plugin.version..',')
INFO('By: RedbeanW, License: GPLv3 with additional conditions.')