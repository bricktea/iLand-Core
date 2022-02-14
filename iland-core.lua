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
	Version = {
		major = 2,
		minor = 7,
		revision = 1,
		toString = function()
			local ver = Plugin.Version
			return tostring(ver.major)..'.'..tostring(ver.minor*10 + ver.revision)
		end,
		toNumber = function()
			local ver = Plugin.Version
			return ver.major*100+ver.minor*10+ver.revision
		end,
		getApi = function()
			return 201
		end
	},
	minLL = {2,1,0},
}

Server = {
	link = "https://cdn.jsdelivr.net/gh/LiteLDev-LXL/Cloud/",
	version = 203,
	memData = {}
}

JSON = require('dkjson')

MEM = {}
DATA_PATH = 'plugins/iland/'

-- [Tpl] config.json

local cfg = {
	version = Plugin.Version.toNumber(),
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

-- Init debug mode.

DEV_MODE = false
if File.exists("EnableILandDevMode") then
	DEV_MODE = true
	DATA_PATH = 'Project/iLand/iland/'
end

-- Init logger.

logger.setTitle("ILand")
logger.setConsole(true)
function INFO(msgtype,content)
	if not content then
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

-- Register to LiteLoader.

if not ll.requireVersion(Plugin.minLL[1],Plugin.minLL[2],Plugin.minLL[3]) then
	error('Unsupported version of LiteLoader, plugin loading aborted.')
else
	--[[
	ll.registerPlugin(
		'iLand',
		'Powerful land plugin.',
		{
			major = Plugin.Version.major,
			minor = Plugin.Version.minor,
			revision = Plugin.Version.revision
		},
		{
			Author = 'RedbeanW',
			Github = 'https://github.com/LiteLScript-Dev/iLand-Core',
			License = 'GPLv3 with additional conditions.'
		}
	)
	]]
end

-- Classes.

Map = {
	Init = function()
		INFO('Load',_Tr('console.loading.map.load'))
		for landId,data in pairs(DataStorage.Land.Raw) do
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
		return true
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
			local posA,posB = ra.posA,ra.posB
			local dimid = ra.dimid
			local function chkNil(table,a,b)
				table[a] = table[a] or {}
				table[a][b] = table[a][b] or {}
			end

			local size = cfg.features.chunk_side
			local sX = posA.x
			local sZ = posA.z
			local count = 0
			while (sX+size*count<=posB.x+size) do
				local Cx,Cz = Pos.ToChunkPos({x=sX+size*count,z=sZ+size*count})
				chkNil(TxTz,Cx,Cz)
				local count2 = 0
				while (sZ+size*count2<=posB.z+size) do
					Cx,Cz = Pos.ToChunkPos({x=sX+size*count,z=sZ+size*count2})
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
						if not Array.Fetch(Map.Chunk.data[dimid][Tx][Tz],landId) then
							table.insert(Map.Chunk.data[dimid][Tx][Tz],#Map.Chunk.data[dimid][Tx][Tz]+1,landId)
						end
					elseif mode=='del' then
						Array.Remove(Map.Chunk.data[dimid][Tx][Tz],landId)
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
					local ra = DataStorage.Land.Raw[landId].range
					local posA = Array.ToIntPos(ra.start_position)
					local posB = Array.ToIntPos(ra.end_position)
					Map.Land.Position.data[landId] = Cube.Create(posA,posB,ra.dimid)
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
				local posA,posB,dimid = ra.posA,ra.posB,ra.dimid
				if mode == 'add' then
					for x = posA.x,posB.x do
						local tar = Map.Land.AXIS.data[dimid]['x']
						if not tar[x] then
							tar[x] = {}
						end
						tar[x][#tar[x]+1] = landId
					end
					for y = posA.y,posB.y do
						local tar = Map.Land.AXIS.data[dimid]['y']
						if not tar[y] then
							tar[y] = {}
						end
						tar[y][#tar[y]+1] = landId
					end
					for z = posA.z,posB.z do
						local tar = Map.Land.AXIS.data[dimid]['z']
						if not tar[z] then
							tar[z] = {}
						end
						tar[z][#tar[z]+1] = landId
					end
				elseif mode == 'del' then
					for x = posA.x,posB.x do
						Array.Remove(Map.Land.AXIS.data[dimid]['x'][x],landId)
					end
					for y = posA.y,posB.y do
						Array.Remove(Map.Land.AXIS.data[dimid]['y'][y],landId)
					end
					for z = posA.z,posB.z do
						Array.Remove(Map.Land.AXIS.data[dimid]['z'][z],landId)
					end
				end
			end
		},
		Trusted = {
			data = {},
			update = function(landId)
				Map.Land.Trusted.data[landId] = Array.ToKeyMap(DataStorage.Land.Raw[landId].settings.share)
			end
		},
		Owner = {
			data = {},
			update = function(landId)
				Map.Land.Owner.data[landId] = Land.RelationShip.Owner.getXuid(landId)
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
		end,
		check = function(listener)
			return Map.Listener.data[listener] == nil
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
		end,
		check = function(mode,name)
			return Map.Control.data[mode][name] ~= nil
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
				local strpos = Pos.ToString(pos,true)
				local map = Map.CachedQuery.SinglePos
				if map.data[strpos] then
					map.clear(strpos)
				end
				map.data[strpos] = {
					landId = landId,
					raw = Pos.ToIntPos(pos),
					querying = true
				}
				if landId then
					map.land_recorded_pos[landId][#map.land_recorded_pos[landId]+1] = strpos
				else
					map.non_land_pos[#map.non_land_pos+1] = strpos
				end
			end,
			get = function(pos)
				local strpos = Pos.ToString(pos,true)
				local map = Map.CachedQuery.SinglePos
				local record = map.data[strpos]
				if record then
					record.querying = true
					return true,record.landId
				end
				return false,nil
			end,
			clear = function(strpos) -- clear single pos's cache
				local map = Map.CachedQuery.SinglePos
				local record = map.data[strpos]
				if not record then
					return
				end
				local landId = record.landId
				if landId then
					Array.Remove(map.land_recorded_pos[landId],strpos)
				else
					Array.Remove(map.non_land_pos,strpos)
				end
				map.data[strpos] = nil
			end,
			check_noland_pos = function() -- when new land created, clear old non-land cached pos.
				local map = Map.CachedQuery.SinglePos
				for n,strpos in pairs(map.non_land_pos) do
					if Land.Query.Pos(map.data[strpos].raw,true) then
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
			add = function(lands,AABB)
				local map = Map.CachedQuery.RangeArea
				local cubestr = Cube.ToString(AABB)
				map.data[cubestr] = {
					raw = AABB,
					landlist = lands,
					querying = true
				}
				for n,landId in pairs(lands) do
					map.recorded_landId[landId][#map.recorded_landId[landId]+1] = "this."..cubestr..".landlist.(*)"..n
				end
			end,
			get = function(AABB)
				local map = Map.CachedQuery.RangeArea
				local cubestr = Cube.ToString(AABB)
				local record = map.data[cubestr]
				if record then
					record.querying = true
					return record.landlist
				end
				return nil
			end,
			clear_range = function(cubestr) -- clear single range's cache.
				local map = Map.CachedQuery.RangeArea
				for n,landId in pairs(map.data[cubestr].landlist) do
					Array.Remove(map.recorded_landId[landId],"this."..cubestr..".landlist.(*)"..n)
				end
				map.data[cubestr] = nil
			end,
			clear_by_land = function(landId) -- clear cached "range" if "range" in this range.
				local map = Map.CachedQuery.RangeArea
				for cubestr,rangeInfo in pairs(map.data) do
					if Array.Fetch(Land.Query.Area(rangeInfo.raw,true),landId) then
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
		if stat == 0 then
			return true
		elseif stat == -1 then
			ERROR('Language pack not found!')
		elseif stat == -2 then
			ERROR('The language pack used is not suitable for this version!')
		end
		return false
	end,
	Load = function(lang)
		local path = DATA_PATH..'lang/'..lang..'.json'
		if not File.exists(path) then
			return -1
		end
		local pack = JSON.decode(File.readFrom(path))
		if pack.VERSION ~= Plugin.Version.toNumber() then
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
			if not Array.Fetch(list_l,lang) then
				ERROR(_Tr('console.languages.update.notfound','<a>',lang))
			elseif JSON.decode(File.readFrom(path..lang..'.json')).VERSION == Plugin.Version.toNumber() then
				ERROR(lang..': '.._Tr('console.languages.update.alreadylatest'))
			elseif not Array.Fetch(list_o.official,lang) and not Array.Fetch(list_o['3-rd'],lang) then
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
				DataStorage.Save({1,0,0})
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
			if THISVER~=Plugin.Version.toNumber() then
				return -3
			end
			File.writeTo(DATA_PATH..'lang/'..lang..'.json',raw)
			return 0
		end,
		GetSign = function()
			local rtn = ""
			local count = 1
			while(I18N.LangPack.data['#'..count]) do
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

Dimension = {
	Get = function(id)
		if id == 0 then
			return {
				name = _Tr('talk.dim.zero'),
				max = 320,
				min = -64
			}
		elseif id == 1 then
			return {
				name = _Tr('talk.dim.one'),
				max = 128,
				min = 0
			}
		elseif id == 2 then
			return {
				name = _Tr('talk.dim.two'),
				max = 256,
				min = 0
			}
		else
			return {
				name =  _Tr('talk.dim.other'),
				max = 0,
				min = 0
			}
		end
	end
}

DataStorage = {

	Config = {

		Load = function()

			--- Init.
			local save = false

			--- Check file.
			if not File.exists(DATA_PATH..'config.json') then
				WARN(_Tr('console.loading.config.notfound'))
				File.writeTo(DATA_PATH..'config.json',JSON.encode(cfg))
			end
			local localcfg = JSON.decode(File.readFrom(DATA_PATH..'config.json'))
			if localcfg.version ~= Plugin.Version.toNumber() then
				save = true
				if not DataStorage.Config.Update(localcfg) then
					return false
				end
			end

			--- Load local configure.
			for n,path in pairs(table.getAllPaths(cfg,false)) do
				local item = table.getKey(localcfg,path)
				if path ~= 'this.version' then
					if item == nil then
						save = true
						WARN(_Tr('console.loading.config.itemlost','<a>',string.sub(path,6)))
					else
						table.setKey(cfg,path,item)
					end
				end
			end

			-- Auto correct.
			if cfg.land.bought.square_range[1] > cfg.land.bought.square_range[2] then
				WARN(_Tr('console.loading.config.autocorrect','<a>','cfg.land.bought.square_range'))
				table.sort(cfg.land.bought.square_range)
				save = true
			end
			if cfg.economic.protocol~='llmoney' and cfg.economic.protocol~='scoreboard' then
				WARN(_Tr('console.loading.config.autocorrect','<a>','cfg.economic.protocol'))
				cfg.economic.protocol = 'scoreboard'
				save = true
			end

			-- Save if needed.
			if save and not DEV_MODE then
				DataStorage.Save({1,0,0})
			end
			return true

		end,
		Update = function(origin)
			if not origin.version or origin.version < 240 then
				return false
			end
			--- Update
			if origin.version < 242 then -- OLD STRUCTURE
				local tpl = table.clone(cfg)
				tpl.plugin.language = origin.manager.default_language
				tpl.plugin.network = origin.update_check
				tpl.land.operator = origin.manager.operator
				tpl.land.max_lands = origin.land.player_max_lands
				tpl.land.bought.three_dimension.enable = origin.features.land_3D
				tpl.land.bought.three_dimension.calculate_method = origin.land_buy.calculation_3D
				tpl.land.bought.three_dimension.price = origin.land_buy.price_3D
				tpl.land.bought.two_dimension.enable = origin.features.land_2D
				tpl.land.bought.two_dimension.calculate_method = origin.land_buy.calculation_2D
				tpl.land.bought.two_dimension.price = origin.land_buy.price_2D
				tpl.land.bought.square_range = {origin.land.land_min_square,origin.land.land_max_square}
				tpl.land.bought.discount = origin.money.discount/100
				tpl.land.refund_rate = origin.land_buy.refund_rate
				tpl.economic.protocol = origin.money.protocol
				tpl.economic.scoreboard_objname = origin.money.scoreboard_objname
				tpl.economic.currency_name = origin.money.credit_name
				tpl.features.landsign.enable = origin.features.landSign
				tpl.features.landsign.frequency = origin.features.sign_frequency
				tpl.features.buttomsign.enable = origin.features.landSign
				tpl.features.buttomsign.frequency = origin.features.sign_frequency
				tpl.features.particles.enable = origin.features.particles
				tpl.features.particles.name = origin.features.particle_effects
				tpl.features.particles.max_amount = origin.features.player_max_ple
				tpl.features.player_selector.include_offline_players = origin.features.offlinePlayerInList
				tpl.features.player_selector.items_perpage = origin.features.playersPerPage
				tpl.features.selection.disable_dimension = origin.features.blockLandDims
				tpl.features.selection.tool_type = origin.features.selection_tool
				tpl.features.selection.tool_name = origin.features.selection_tool_name
				tpl.features.landtp = origin.features.landtp
				tpl.features.force_talk = origin.features.force_talk
				tpl.features.disabled_listener = origin.features.disabled_listener
				tpl.features.chunk_side = origin.features.chunk_side
				origin = tpl
			end
			if origin.version < 260 then
				origin.land.bought.three_dimension.calculate_method = nil
				origin.land.bought.three_dimension.price = nil
				origin.land.bought.two_dimension.calculate_method = nil
				origin.land.bought.two_dimension.price = nil
				origin.land.bought.three_dimension.calculate = "{square}*8+{height}*20"
				origin.land.bought.two_dimension.calculate = "{square}*25"
			end
			if origin.version < 262 then
				if type(origin.land.bought.square_range)~='table' then
					origin.land.bought.square_range = {4,50000}
				end
			end
			if origin.version < 270 then
				local sec = origin.features.selection
				sec.dimension = {true,true,true}
				if Array.Fetch(sec.disable_dimension,0) then
					sec.dimension[1] = false
				end
				if Array.Fetch(sec.disable_dimension,1) then
					sec.dimension[2] = false
				end
				if Array.Fetch(sec.disable_dimension,2) then
					sec.dimension[3] = false
				end
				origin.land.min_space = 15
				sec.disable_dimension = nil
			end
			--- Rtn
			return true
		end,
		Save = function()
			File.writeTo(DATA_PATH..'config.json',JSON.encode(cfg))
		end

	},
	Land = {

		Raw = {},
		Unloaded = {},
		Load = function()

			--- Init.
			local save = false

			--- Check file.
			if not File.exists(DATA_PATH..'data.json') then
				WARN(_Tr('console.loading.land.notfound'))
				File.writeTo(DATA_PATH..'data.json',JSON.encode({
					version = Plugin.Version.toNumber(),
					Lands = {}
				}))
			end
			local localdata = JSON.decode(File.readFrom(DATA_PATH..'data.json'))
			if localdata.version ~= Plugin.Version.toNumber() then
				DataStorage.Land.Update(localdata)
			end

			--- Load local land.
			for landId,res in pairs(localdata.Lands) do
				local m = DataStorage.Land.Template.Fill(res)
				if m then
					DataStorage.Land.Raw[landId] = m
				else
					WARN(_Tr('console.loading.land.invalild','<a>',landId))
					Land.RelationShip.Owner.destroy(landId)
				end
			end

			--- Save if needed.
			if save and not DEV_MODE then
				DataStorage.Save({0,1,0})
			end
			return true
		end,
		Update = function(origin)
			if not origin.version then

			end
			--- Update
			for landId,res in pairs(origin.Lands) do
				local perm = origin.Lands[landId].permissions
				local setting = origin.Lands[landId].settings
				if origin.version < 240 then
					return false
				end
				if origin.version < 245 then
					perm.use_armor_stand = false
					perm.eat = false
				end
				if origin.version < 260 then
					setting.ev_redstone_update = false
				end
				if origin.version < 262 then
					perm.useitem = nil
				end
			end
			return true
		end,
		Template = {
			data = {
				settings = {
					share = {},
					teleport = {},
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
					start_position = {},
					end_position = {},
					dimid = -1
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
					useitem = false
				}
			},
			Create = function()
				return table.clone(DataStorage.Land.Template.data)
			end,
			Fill = function(origin)
				local land = DataStorage.Land.Template.Create()
				for n,path in pairs(table.getAllPaths(land)) do
					local m = table.getKey(origin,path)
					local o = table.getKey(land,path)
					if m == nil or type(m) ~= type(o) then
						if string.sub(path,1,10) == 'this.range' then
							return nil
						end
						table.setKey(land,path,o)
					else
						table.setKey(land,path,m)
					end
				end
				return land
			end
		},
		Save = function()
			local localdata = {
				version = Plugin.Version.toNumber(),
				Lands = table.concatEx(DataStorage.Land.Raw,DataStorage.Land.Unloaded)
			}
			File.writeTo(DATA_PATH..'data.json',JSON.encode(localdata))
		end

	},
	RelationShip = {

		Raw = {},
		Unloaded = {},
		Load = function()
			local rel = DataStorage.RelationShip
			if not File.exists(DATA_PATH..'relationship.json') then
				WARN(_Tr('console.loading.relationship.notfound'))
				File.writeTo(DATA_PATH..'relationship.json',JSON.encode({
					version = Plugin.Version.toNumber(),
					Owner = {},
					Operator = {}
				}))
			end
			local localdata = JSON.decode(File.readFrom(DATA_PATH..'relationship.json'))
			if localdata.version ~= Plugin.Version.toNumber() then
				rel.Update(localdata)
			end
			--- Owner
			rel.Raw['Owner'] = {}
			rel.Unloaded['Owner'] = {}
			local had_unloaded_xuid = false
			for xuid,landIds in pairs(localdata.Owner) do
				if not data.xuid2name(xuid) then
					WARN(_Tr('console.loading.relationship.xuidinvalid',xuid))
					rel.Unloaded['Owner'][xuid] = landIds
					had_unloaded_xuid = true
				else
					rel.Raw['Owner'][xuid] = landIds
				end
			end
			if had_unloaded_xuid then
				INFO(_Tr('console.loading.relationship.xuidinvalidtip'))
			end
			return true
		end,
		Update = function(origin)
			if not origin.version then

			end
			return origin
		end,
		Save = function()
			local rel = DataStorage.RelationShip
			local localdata = {
				version = Plugin.Version.toNumber(),
				Owner = table.concatEx(rel.Raw['Owner'],rel.Unloaded['Owner']),
				Operator = rel.Raw['Operator']
			}
			File.writeTo(DATA_PATH..'relationship.json',JSON.encode(localdata))
		end

	},

	_stat = {false,false,false}, -- { Config, Land, RelationShip }
	INTERVAL = function()
		if DataStorage._stat[1] then
			DataStorage._stat[1] = false
			DataStorage.Config.Save()
		end
		if DataStorage._stat[2] then
			DataStorage._stat[2] = false
			DataStorage.Land.Save()
		end
		if DataStorage._stat[3] then
			DataStorage._stat[3] = false
			DataStorage.RelationShip.Save()
		end
	end,
	IsPending = function()
		local m = DataStorage._stat
		return m[1] or m[2] or m[3]
	end,
	Save = function(mode)
		if mode[1] == 1 then
			DataStorage._stat[1] = true
		end
		if mode[2] == 1 then
			DataStorage._stat[2] = true
		end
		if mode[3] == 1 then
			DataStorage._stat[3] = true
		end
	end

}

Economy = {

	Status = {
		inited = false,
		protocol = 'null',
	},
	Protocol = {
		IsVaild = function(name)
			return Array.Fetch({'llmoney','scoreboard'},string.lower(name)) ~= nil
		end,
		get = function()
			return Economy.Status.protocol
		end,
		set = function(name)
			name = string.lower(name)
			if name == 'llmoney' then
				Economy.Player.add = function(player,value)
					return money.add(player.xuid,value)
				end
				Economy.Player.del = function(player,value)
					return money.reduce(player.xuid,value)
				end
				Economy.Player.get = function(player)
					return money.get(player.xuid)
				end
				Economy.Status.protocol = 'llmoney'
				Economy.Status.inited = true
				return true
			elseif name == 'scoreboard' then
				Economy.Player.add = function(player,value)
					return player:addScore(cfg.economic.scoreboard_objname,value)
				end
				Economy.Player.del = function(player,value)
					return player:reduceScore(cfg.economic.scoreboard_objname,value)
				end
				Economy.Player.get = function(player)
					return player:getScore(cfg.economic.scoreboard_objname)
				end
				Economy.Status.protocol = 'scoreboard'
				Economy.Status.inited = true
				return true
			end
			Economy.Status.protocol = 'null'
			Economy.Status.inited = false
			return false
		end
	},
	Player = {
		add = nil,
		del = nil,
		get = nil
	}

}

Land = {

	Storage = {

		Create = function(xuid,AABB)

			--- Check land.
			if not Land.Util.IsCollision(AABB).status then
				return -1
			end

			--- Land storage.
			local posA,posB,dimid = AABB.posA,AABB.posB,AABB.dimid
			local landId = Land.IDManager.Create()
			if not EventSystem.Call(EventSystem.EV.onCreate,'Before',{landId,xuid,AABB}) then
				return -1
			end
			local tpl = DataStorage.Land.Template.Create()
			tpl.settings.teleport = Pos.ToArray(posA)
			tpl.range.start_position = Pos.ToArray(posA)
			tpl.range.end_position = Pos.ToArray(posB)
			tpl.range.dimid = dimid
			DataStorage.Land.Raw[landId] = tpl

			--- Add owner relationship.
			Land.RelationShip.Owner.set(landId,xuid)

			--- Update runtime maps.
			Map.Land.Position.update(landId,'add')
			Map.Chunk.update(landId,'add')
			Map.Land.Owner.update(landId)
			Map.Land.Trusted.update(landId)
			Map.Land.AXIS.update(landId,'add')
			Map.CachedQuery.Init(landId)
			Map.CachedQuery.RangeArea.clear_by_land(landId)
			Map.CachedQuery.SinglePos.check_noland_pos()

			DataStorage.Save({0,1,1})
			return landId

		end,
		Delete = function(landId)
			Land.RelationShip.Owner.destroy(landId)
			Map.CachedQuery.RangeArea.refresh(landId)
			Map.CachedQuery.SinglePos.refresh(landId)
			Map.CachedQuery.UnInit(landId)
			Map.Land.AXIS.update(landId,'del')
			Map.Chunk.update(landId,'del')
			Map.Land.Position.update(landId,'del')
			DataStorage.Land.Raw[landId] = nil
			DataStorage.Save({0,1,1})
			return true
		end

	},

	Options = {

		Permission = {
			get = function(landId,item)
				return DataStorage.Land.Raw[landId].permissions[item]
			end,
			set = function(landId,item,value)
				DataStorage.Land.Raw[landId].permissions[item] = value
				DataStorage.Save({0,1,0})
				return true
			end
		},

		Setting = {
			get = function(landId,item)
				return DataStorage.Land.Raw[landId].settings[item]
			end,
			set = function(landId,item,value)
				DataStorage.Land.Raw[landId].settings[item] = value
				DataStorage.Save({0,1,0})
				return true
			end
		},

		Teleport = {
			get = function(landId)
				local pos = table.clone(DataStorage.Land.Raw[landId].settings.teleport)
				pos[4] = DataStorage.Land.Raw[landId].range.dimid
				return Array.ToIntPos(pos)
			end,
			set = function(landId,pos)
				DataStorage.Land.Raw[landId].settings.teleport = {
					pos[1],pos[2],pos[3]
				}
				DataStorage.Save({0,1,0})
			end
		},

		Nickname = {
			isDefault = function(landId)
				return DataStorage.Land.Raw[landId].settings.nickname == DataStorage.Land.Template['data'].settings.nickname
			end,
			get = function(landId,rtnmode)
				--[[ Return Mode (If name default).
					nil -> return nil,
					0	-> return '',
					1	-> return landId,
					2	-> return <Unnamed>
					3	-> return <Unnamed> + landId ]]
				if Land.Options.Nickname.isDefault(landId) then
					if not rtnmode then
						return nil
					elseif rtnmode == 0 then
						return ''
					elseif rtnmode == 1 then
						return landId
					elseif rtnmode == 2 then
						return _Tr('gui.landmgr.unnamed')
					elseif rtnmode == 3 then
						return _Tr('gui.landmgr.unnamed')..' '..landId
					end
				end
				return DataStorage.Land.Raw[landId].settings.nickname
			end
		}

	},

	Query = {

		Pos = function(pos,noAccessCache)
			noAccessCache = noAccessCache or false
			if not noAccessCache then
				local hadCache,result = Map.CachedQuery.SinglePos.get(pos)
				if hadCache then
					return result
				end
			end

			local Cx,Cz = Pos.ToChunkPos(pos)
			local dimid = pos.dimid
			if Map.Chunk.data[dimid][Cx] and Map.Chunk.data[dimid][Cx][Cz] then
				for n,landId in pairs(Map.Chunk.data[dimid][Cx][Cz]) do
					if dimid==DataStorage.Land.Raw[landId].range.dimid and Cube.HadPos(pos,Cube.Create(Map.Land.Position.data[landId].posA,Map.Land.Position.data[landId].posB)) then
						if not noAccessCache then
							Map.CachedQuery.SinglePos.add(landId,pos)
						end
						return landId
					end
				end
			end

			if not noAccessCache then
				Map.CachedQuery.SinglePos.add(nil,pos)
			end
			return nil
		end,
		Area = function(AABB,noAccessCache)
			noAccessCache = noAccessCache or false
			if not noAccessCache then
				local cache_result = Map.CachedQuery.RangeArea.get(AABB)
				if cache_result then
					return cache_result
				end
			end

			local temp = { [1] = {}, [2] = {}, [3] = {} }
			local function concat(a,list)
				if not list then
					return
				end
				for n,value in pairs(list) do
					temp[a][value] = 0
				end
			end
			local function shortest(...)
				local tar = {...}
				local result = tar[1]
				for i=2,#tar do
					if #tar[i] < #result then
						result = tar[i]
						break
					end
				end
				return result
			end

			local posA,posB,dimid = AABB.posA,AABB.posB,AABB.dimid
			for x = posA.x,posB.x do
				concat(1,Map.Land.AXIS.data[dimid]['x'][x])
			end
			for y = posA.y,posB.y do
				concat(2,Map.Land.AXIS.data[dimid]['y'][y])
			end
			for z = posA.z,posB.z do
				concat(3,Map.Land.AXIS.data[dimid]['z'][z])
			end

			local result = {}
			for landId,zero in pairs(shortest(temp[1],temp[2],temp[3])) do
				if temp[1][landId]==0 and temp[2][landId]==0 and temp[3][landId]==0 then
					result[#result+1] = landId
				end
			end

			if not noAccessCache then
				Map.CachedQuery.RangeArea.add(result,AABB)
			end
			return result
		end

	},

	Util = {

		CheckPerm = function(landId,xuid)
			return Land.RelationShip.Operator.check(xuid) or
				Land.RelationShip.Owner.check(landId,xuid) or
				Land.RelationShip.Trusted.check(landId,xuid)
		end,
		GetDimension = function(landId)
			local range = Map.Land.Position.data[landId]
			local dim = Dimension.Get(range.dimid)
			if dim.min == range.posA.y and dim.max == range.posB.y then
				return '2D'
			end
			return '3D'
		end,
		IsCollision = function(AABB,ignoreList)
			ignoreList = ignoreList or {}
			local ignores = Array.ToKeyMap(ignoreList)
			local lands = Land.Query.Area(AABB)
			for i,landId in pairs(lands) do
				if not ignores[landId] then
					return { status = false, id = landId }
				end
			end
			return { status = true }
		end,
		Teleport = function(player,landId)
			SafeTeleport.Do(player,Land.Options.Teleport.get(landId))
			return true
		end

	},

	Range = {

		Get = function(landId)
			return Map.Land.Position.data[landId]
		end,
		Reset = function(landId,AABB)
			local posA,posB,dimid = AABB.posA,AABB.posB,AABB.dimid
			if not Land.Util.IsCollision(AABB,{landId}).status then
				return false
			end
			Map.Chunk.update(landId,'del')
			Map.Land.AXIS.update(landId,'del')
			Map.Land.Position.update(landId,'del')
			DataStorage.Land.Raw[landId].range.start_position = Pos.ToArray(posA)
			DataStorage.Land.Raw[landId].range.end_position = Pos.ToArray(posB)
			DataStorage.Land.Raw[landId].range.dimid = dimid
			DataStorage.Land.Raw[landId].settings.teleport = Pos.ToArray(posA)
			Map.Land.Position.update(landId,'add')
			Map.Chunk.update(landId,'add')
			Map.Land.AXIS.update(landId,'add')
			Map.CachedQuery.RangeArea.refresh(landId)
			Map.CachedQuery.SinglePos.refresh(landId)
			Map.CachedQuery.RangeArea.clear_by_land(landId)
			Map.CachedQuery.SinglePos.check_noland_pos()
			DataStorage.Save({0,1,0})
			return true
		end

	},

	IDManager = {

		IsVaild = function(landId)
			if not landId then
				return false
			end
			return DataStorage.Land.Raw[landId] ~= nil
		end,
		Create = function()
			local landId
			while true do
				landId = string.upper(string.sub(system.randomGuid(),1,12))
				if not Land.IDManager.IsVaild(landId) then break end
			end
			return landId
		end,
		DumpAll = function()
			local rtn = {}
			for landId,res in pairs(DataStorage.Land.Raw) do
				rtn[#rtn+1] = landId
			end
			return rtn
		end

	},

	RelationShip = {

		Operator = {
			check = function(xuid)
				return Map.Land.Operator.data[xuid] ~= nil
			end
		},
		Owner = {
			getXuid = function(landId)
				for xuid,v in pairs(DataStorage.RelationShip.Raw['Owner']) do
					if Array.Fetch(v,landId) then
						return xuid
					end
				end
				return nil
			end,
			getLand = function(xuid)
				return DataStorage.RelationShip.Raw['Owner'][xuid]
			end,
			set = function(landId,xuid)
				Land.RelationShip.Owner.destroy(landId)
				DataStorage.RelationShip.Raw['Owner'][xuid][#DataStorage.RelationShip.Raw['Owner'][xuid]+1] = landId
				Map.Land.Owner.update(landId)
				DataStorage.Save({0,0,1})
				return true
			end,
			destroy = function(landId) -- it makes a non-owner land.
				local owner = Land.RelationShip.Owner.getXuid(landId)
				if not owner then
					return false
				end
				Array.Remove(DataStorage.RelationShip.Raw['Owner'][owner],landId)
				DataStorage.Save({0,0,1})
				return true
			end,
			check = function(landId,xuid)
				return Map.Land.Owner.data[landId] == xuid
			end
		},
		Trusted = {
			getXuid = function(landId)
				return DataStorage.Land.Raw[landId].settings.share
			end,
			getLand = function(xuid)
				local rtn = {}
				for landId,res in pairs(DataStorage.Land.Raw) do
					if Land.RelationShip.Trusted.check(landId,xuid) then
						rtn[#rtn+1] = landId
					end
				end
				return rtn
			end,
			add = function(landId,xuid)
				local share = DataStorage.Land.Raw[landId].settings.share
				if Land.RelationShip.Trusted.check(landId,xuid) then
					return false
				end
				share[#share+1] = xuid
				Map.Land.Trusted.update(landId)
				DataStorage.Save({0,1,0})
				return true
			end,
			remove = function(landId,xuid)
				local share = DataStorage.Land.Raw[landId].settings.share
				Array.Remove(share,xuid)
				Map.Land.Trusted.update(landId)
				DataStorage.Save({0,1,0})
				return true
			end,
			check = function(landId,xuid)
				return Map.Land.Trusted.data[landId][xuid] ~= nil
			end
		},
	},

	API = {
		RunExport = function()
			for apiName,func in pairs(Land.API.Exported) do
				if not ll.export(func,'ILAPI_'..apiName) then
					ERROR('There was a problem exporting the API, export is failed!')
					return false
				end
			end
			return true
		end,
		Helper = {
			IsXuidOnline = function(xuid)
				return MEM[xuid] ~= nil
			end,
			CheckNilArgument = function(...)
				local count = 0
				local args = {...}
				for i,v in ipairs(args) do
					count = count + 1
				end
				return #args == count
			end,
			ErrMsg = {
				[1] = '[ILAPI] API received invalid value.',
				[2] = '[ILAPI] API received invaild landId.',
				[3] = '[ILAPI] API received offline xuid.'
			}
		},
		Exported = {
			['AddBeforeEventListener'] = function(event,funcname)
				local ev = EventSystem.EV[event]
				local func = ll.import(funcname)
				if not ev or not func then
					return -1
				end
				return EventSystem.AddListener(ev,'Before',func)
			end,
			['AddAfterEventListener'] = function(event,funcname)
				local ev = EventSystem.EV[event]
				local func = ll.import(funcname)
				if not ev or not func then
					return -1
				end
				return EventSystem.AddListener(ev,'After',func)
			end,
			['CreateLand'] = function(xuid,posA,posB,dimid)
				assert(Land.API.Helper.CheckNilArgument(xuid,posA,posB,dimid),Land.API.Helper.ErrMsg[1])
				Land.API.Helper.CheckNilArgument(xuid,posA,posB,dimid)
				local rtn = Land.Storage.Create(xuid,Cube.Create(posA,posB,dimid))
				rtn = rtn or -1
				return rtn
			end,
			['DeleteLand'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Storage.Delete(landId)
			end,
			['PosGetLand'] = function(pos,noAccessCache)
				assert(Land.API.Helper.CheckNilArgument(pos),Land.API.Helper.ErrMsg[1])
				local rtn = Land.Query.Pos(pos,noAccessCache) or -1
				return rtn
			end,
			['GetLandInRange'] = function(posA,posB,dimid,noAccessCache)
				assert(Land.API.Helper.CheckNilArgument(posA,posB,dimid),Land.API.Helper.ErrMsg[1])
				return Land.Query.Area(Cube.Create(posA,posB,dimid),noAccessCache)
			end,
			['GetAllLands'] = function()
				return Land.IDManager.DumpAll()
			end,
			['CheckPerm'] = function(landId,perm)
				assert(Land.API.Helper.CheckNilArgument(landId,perm),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return DataStorage.Land.Raw[landId].permissions[perm]
			end,
			['CheckSetting'] = function(landId,setting)
				assert(Land.API.Helper.CheckNilArgument(landId,setting),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return DataStorage.Land.Raw[landId].settings[setting]
			end,
			['GetRange'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Range.Get(landId)
			end,
			['GetEdge'] = function(landId,dimType,customY)
				assert(Land.API.Helper.CheckNilArgument(landId,dimType),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				local rtn
				if dimType == '3D' then
					rtn = Cube.GetEdge(Land.Range.Get(landId))
				elseif dimType == '2D' then
					rtn = Cube.GetEdge_2D(Land.Range.Get(landId),customY)
				end
				return rtn
			end,
			['GetDimension'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Util.GetDimension(landId)
			end,
			['GetName'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Options.Nickname.get(landId,0)
			end,
			['GetDescribe'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Options.Setting.get(landId,'nickname')
			end,
			['GetOwner'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Owner.getXuid(landId)
			end,
			['GetPoint'] = function(landId)
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.Options.Teleport.get(landId)
			end,
			['GetPlayerLands'] = function(xuid)
				assert(Land.API.Helper.CheckNilArgument(xuid),Land.API.Helper.ErrMsg[1])
				return Land.RelationShip.Owner.getLand(xuid)
			end,
			['IsPlayerTrusted'] = function(landId,xuid)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Trusted.check(landId,xuid)
			end,
			['IsLandOwner'] = function(landId,xuid)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Owner.check(landId,xuid)
			end,
			['IsLandOperator'] = function(xuid)
				assert(Land.API.Helper.CheckNilArgument(xuid),Land.API.Helper.ErrMsg[1])
				return Land.RelationShip.Operator.check(xuid)
			end,
			['GetAllTrustedLand'] = function(xuid)
				assert(Land.API.Helper.CheckNilArgument(xuid),Land.API.Helper.ErrMsg[1])
				return Land.RelationShip.Trusted.getLand(xuid)
			end,
			['UpdatePermission'] = function(landId,perm,value)
				assert(Land.API.Helper.CheckNilArgument(landId,perm,value),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				if not DataStorage.Land.Raw[landId].permissions[perm] then
					return false
				end
				return Land.Options.Permission.set(landId,perm,value)
			end,
			['UpdateSetting'] = function(landId,setting,value)
				assert(Land.API.Helper.CheckNilArgument(landId,setting,value),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				if not DataStorage.Land.Raw[landId].settings[setting] then
					return false
				end
				return Land.Options.Setting.set(landId,setting,value)
			end,
			['AddTrust'] = function(landId,xuid)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Trusted.add(landId,xuid)
			end,
			['RemoveTrust'] = function(landId,xuid)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Trusted.remove(landId,xuid)
			end,
			['SetOwner'] = function(landId,xuid)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				return Land.RelationShip.Owner.set(landId,xuid)
			end,
			['Teleport'] = function(xuid,landId)
				assert(Land.API.Helper.CheckNilArgument(landId,xuid),Land.API.Helper.ErrMsg[1])
				assert(Land.IDManager.IsVaild(landId),Land.API.Helper.ErrMsg[2])
				assert(Land.API.Helper.IsXuidOnline(xuid),Land.API.Helper.ErrMsg[3])
				return Land.Util.Teleport(mc.getPlayer(xuid),landId)
			end,
			['GetMoneyProtocol'] = function()
				return cfg.economic.protocol
			end,
			['GetLanguage'] = function()
				return cfg.plugin.language
			end,
			['GetChunkSide'] = function()
				return cfg.features.chunk_side
			end,
			['IsListenerDisabled'] = function(listener)
				assert(Land.API.Helper.CheckNilArgument(listener),Land.API.Helper.ErrMsg[1])
				return not Map.Listener.check(listener)
			end,
			['GetApiVersion'] = function()
				return Plugin.Version.getApi()
			end,
			['GetVersion'] = function()
				return Plugin.Version.toNumber()
			end,
			['SafeTeleport_Do'] = function(xuid,pos)
				assert(Land.API.Helper.CheckNilArgument(xuid,pos),Land.API.Helper.ErrMsg[1])
				assert(Land.API.Helper.IsXuidOnline(xuid),Land.API.Helper.ErrMsg[3])
				return SafeTeleport.Do(mc.getPlayer(xuid),pos)
			end,
		}
	},

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
		if ori.components[class] then
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
		if not Array.Fetch({'input','switch','dropdown','percent_slider','slider','step_slider'},uitype) then
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
					if not pos then
						pos = 0
					else
						pos = pos - 1
					end
					Form:addStepSlider(cmp.name,cmp.data,pos)
				end
			end
		end
		player:sendForm(Form,function(player,res)
			if not res then return end
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
					if slf.data[result+1] then
						table.setKey(cfg,slf.path,slf.data[result+1])
					end
				elseif slf.ui=='slider' then	--- testless
					table.setKey(cfg,slf.path,result)
				elseif slf.ui=='percent_slider' then
					table.setKey(cfg,slf.path,result/100)
				elseif slf.ui=='step_slider' then	--- testless
					if slf.data[result+1] then
						table.setKey(cfg,slf.path,slf.data[result+1])
					end
				end
			end
			DataStorage.Save({1,0,0})
			I18N.Load(cfg.plugin.language)
			player:sendModalForm(
				_Tr('gui.general.complete'),
				"Complete.",
				_Tr('gui.general.back'),
				_Tr('gui.general.close'),
				Callback.Form.BackTo.LandOPMgr
			)
		end)
	end
}

OpenGUI = {
	FastLMgr = function(player,isOP)
		local xuid = player.xuid
		local lands = Land.RelationShip.Owner.getLand(xuid)
		if #lands==0 and not isOP then
			SendText(player,_Tr('title.landmgr.failed'));return
		end

		local landId = MEM[xuid].landId
		if not Land.IDManager.IsVaild(landId) then
			OpenGUI.LMgr(player)
			return
		end

		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.fastlmgr.title'))
		if not isOP then
			Form:setContent(_Tr('gui.fastlmgr.content','<a>',Land.Options.Nickname.get(landId,3)))
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
				if not Id then
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

		local landlst = Land.RelationShip.Owner.getLand(ownerXuid)
		if #landlst==0 then
			SendText(player,_Tr('title.landmgr.failed'))
			return
		end
		local Form = mc.newSimpleForm()
		Form:setTitle(_Tr('gui.landmgr.title'))
		Form:setContent(_Tr('gui.landmgr.select'))
		for n,landId in pairs(landlst) do
			Form:addButton(Land.Options.Nickname.get(landId,3),'textures/ui/worldsIcon')
		end
		MEM[xuid].enableBackButton = 0
		player:sendForm(Form,function(pl,id) -- callback
			if not id then return end
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
			if not id then return end
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
						if not mode then return end
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
							local Ids = Land.IDManager.DumpAll()
							for num,landId in pairs(Ids) do
								local ownerId = Land.RelationShip.Owner.getXuid(landId)
								if ownerId then
									ownerId = data.xuid2name(ownerId)
								end
								Form:addButton(
									_Tr('gui.oplandmgr.landmgr.button',
										'<a>',Land.Options.Nickname.get(landId,3),
										'<b>',ownerId
									),
									'textures/ui/worldsIcon'
								)
							end
							player:sendForm(Form,function(pl,id) -- callback
								if not id then return end
								local landId = Ids[id+1]
								Land.Util.Teleport(pl,landId)
							end)
						end
						if mode==2 then -- 脚下
							local landId = Land.Query.Pos(player.blockPos)
							if not landId then
								SendText(player,_Tr('gui.oplandmgr.landmgr.byfeet.errbynull'))
								return
							end
							MEM[xuid].landId = landId
							OpenGUI.FastLMgr(player,true)
						end
						if mode==3 then -- 返回
							Callback.Form.BackTo.LandOPMgr(player,true)
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
				Form:addSwitch('onDestroyBlock',Map.Listener.check('onDestroyBlock'))
				Form:addSwitch('onPlaceBlock',Map.Listener.check('onPlaceBlock'))
				Form:addSwitch('onUseItemOn',Map.Listener.check('onUseItemOn'))
				Form:addSwitch('onAttackEntity',Map.Listener.check('onAttackEntity'))
				Form:addSwitch('onAttackBlock',Map.Listener.check('onAttackBlock'))
				Form:addSwitch('onExplode',Map.Listener.check('onExplode'))
				Form:addSwitch('onBedExplode',Map.Listener.check('onBedExplode'))
				Form:addSwitch('onRespawnAnchorExplode',Map.Listener.check('onRespawnAnchorExplode'))
				Form:addSwitch('onTakeItem',Map.Listener.check('onTakeItem'))
				Form:addSwitch('onDropItem',Map.Listener.check('onDropItem'))
				Form:addSwitch('onBlockInteracted',Map.Listener.check('onBlockInteracted'))
				Form:addSwitch('onUseFrameBlock',Map.Listener.check('onUseFrameBlock'))
				Form:addSwitch('onSpawnProjectile',Map.Listener.check('onSpawnProjectile'))
				Form:addSwitch('onMobHurt',Map.Listener.check('onMobHurt'))
				Form:addSwitch('onStepOnPressurePlate',Map.Listener.check('onStepOnPressurePlate'))
				Form:addSwitch('onRide',Map.Listener.check('onRide'))
				Form:addSwitch('onWitherBossDestroy',Map.Listener.check('onWitherBossDestroy'))
				Form:addSwitch('onFarmLandDecay',Map.Listener.check('onFarmLandDecay'))
				Form:addSwitch('onPistonTryPush',Map.Listener.check('onPistonTryPush'))
				Form:addSwitch('onFireSpread',Map.Listener.check('onFireSpread'))
				Form:addSwitch('onChangeArmorStand',Map.Listener.check('onChangeArmorStand'))
				Form:addSwitch('onEat',Map.Listener.check('onEat'))
				Form:addSwitch('onRedStoneUpdate',Map.Listener.check('onRedStoneUpdate'))

				player:sendForm(
					Form,
					function(player,res)
						if not res then return end

						cfg.features.disabled_listener = {}
						local dbl = cfg.features.disabled_listener
						local count = 0
						local function get()
							count = count + 1
							return res[count]
						end
						if not get() then dbl[#dbl+1] = "onDestroyBlock" end
						if not get() then dbl[#dbl+1] = "onPlaceBlock" end
						if not get() then dbl[#dbl+1] = "onUseItemOn" end
						if not get() then dbl[#dbl+1] = "onAttackEntity" end
						if not get() then dbl[#dbl+1] = "onAttackBlock" end
						if not get() then dbl[#dbl+1] = "onExplode" end
						if not get() then dbl[#dbl+1] = "onBedExplode" end
						if not get() then dbl[#dbl+1] = "onRespawnAnchorExplode" end
						if not get() then dbl[#dbl+1] = "onTakeItem" end
						if not get() then dbl[#dbl+1] = "onDropItem" end
						if not get() then dbl[#dbl+1] = "onBlockInteracted" end
						if not get() then dbl[#dbl+1] = "onUseFrameBlock" end
						if not get() then dbl[#dbl+1] = "onSpawnProjectile" end
						if not get() then dbl[#dbl+1] = "onMobHurt" end
						if not get() then dbl[#dbl+1] = "onStepOnPressurePlate" end
						if not get() then dbl[#dbl+1] = "onRide" end
						if not get() then dbl[#dbl+1] = "onWitherBossDestroy" end
						if not get() then dbl[#dbl+1] = "onFarmLandDecay" end
						if not get() then dbl[#dbl+1] = "onPistonTryPush" end
						if not get() then dbl[#dbl+1] = "onFireSpread" end
						if not get() then dbl[#dbl+1] = "onChangeArmorStand" end
						if not get() then dbl[#dbl+1] = "onEat" end
						if not get() then dbl[#dbl+1] = "onRedStoneUpdate" end

						Map.Listener.build()
						DataStorage.Save({1,0,0})
						player:sendModalForm(
							_Tr('gui.general.complete'),
							"Complete.",
							_Tr('gui.general.back'),
							_Tr('gui.general.close'),
							Callback.Form.BackTo.LandOPMgr
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
			local cubeInfo = Cube.GetInformation(Map.Land.Position.data[landId])
			local owner = Land.RelationShip.Owner.getXuid(landId)
			if owner then
				owner = data.xuid2name(owner)
			end
			player:sendModalForm(
				_Tr('gui.landmgr.landinfo.title'),
				_Tr('gui.landmgr.landinfo.content',
					'<a>',owner,
					'<b>',landId,
					'<c>',Land.Options.Nickname.get(landId,2),
					'<d>',Land.Util.GetDimension(landId),
					'<e>',Dimension.Get(Map.Land.Position.data[landId].dimid).name,
					'<f>',Pos.ToString(Map.Land.Position.data[landId].posA),
					'<g>',Pos.ToString(Map.Land.Position.data[landId].posB),
					'<h>',cubeInfo.length,'<i>',cubeInfo.width,'<j>',cubeInfo.height,
					'<k>',cubeInfo.square,'<l>',cubeInfo.volume
				),
				_Tr('gui.general.iknow'),
				_Tr('gui.general.close'),
				Callback.Form.BackTo.LandMgr
			)
		end,
		Setting = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local function isThisDisabled(feature)
				if cfg.features[feature].enable then
					return ''
				end
				return ' ('.._Tr('talk.features.closed')..')'
			end
			local Form = mc.newCustomForm()
			local settings=DataStorage.Land.Raw[landId].settings
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
					if not res then return end

					local settings = DataStorage.Land.Raw[landId].settings
					settings.signtome = res[1]
					settings.signtother = res[2]
					settings.signbuttom = res[3]
					settings.ev_explode = res[4]
					settings.ev_farmland_decay = res[5]
					settings.ev_fire_spread = res[7]
					settings.ev_piston_push = res[6]
					settings.ev_redstone_update = res[8]
					DataStorage.Save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						Callback.Form.BackTo.LandMgr
					)
				end
			)
		end,
		Permission = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local perm = DataStorage.Land.Raw[landId].permissions
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
					if not res then return end

					local perm = DataStorage.Land.Raw[landId].permissions
					local count = 0
					local function get()
						count = count + 1
						return res[count]
					end

					perm.allow_place = get()
					perm.allow_destroy = get()
					perm.allow_entity_destroy = get()
					perm.allow_dropitem = get()
					perm.allow_pickupitem = get()
					perm.allow_ride_entity = get()
					perm.allow_ride_trans = get()
					perm.allow_shoot = get()
					perm.allow_attack_player = get()
					perm.allow_attack_animal = get()
					perm.allow_attack_mobs = get()

					perm.use_crafting_table = get()
					perm.use_furnace = get()
					perm.use_blast_furnace = get()
					perm.use_smoker = get()
					perm.use_brewing_stand = get()
					perm.use_cauldron = get()
					perm.use_anvil = get()
					perm.use_grindstone = get()
					perm.use_enchanting_table = get()
					perm.use_cartography_table = get()
					perm.use_smithing_table = get()
					perm.use_loom = get()
					perm.use_stonecutter = get()
					perm.use_lectern = get()
					perm.use_beacon = get()

					perm.use_barrel = get()
					perm.use_hopper = get()
					perm.use_dropper = get()
					perm.use_dispenser = get()
					perm.use_shulker_box = get()
					perm.allow_open_chest = get()

					perm.use_campfire = get()
					perm.use_firegen = get()
					perm.use_door = get()
					perm.use_trapdoor = get()
					perm.use_fence_gate = get()
					perm.use_bell = get()
					perm.use_jukebox = get()
					perm.use_noteblock = get()
					perm.use_composter = get()
					perm.use_bed = get()
					perm.use_item_frame = get()
					perm.use_daylight_detector = get()
					perm.use_lever = get()
					perm.use_button = get()
					perm.use_pressure_plate = get()
					perm.use_armor_stand = get()
					perm.eat = get()
					perm.allow_throw_potion = get()
					perm.use_respawn_anchor = get()
					perm.use_fishing_hook = get()
					perm.use_bucket = get()

					DataStorage.Save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						Callback.Form.BackTo.LandMgr
					)
				end
			)
		end,
		Trust = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local shareList = DataStorage.Land.Raw[landId].settings.share
			local content = _Tr('gui.landtrust.tip')
			if #shareList > 0 then
				content = content..'\n'.._Tr('gui.landtrust.trusted')
			end
			for n,plXuid in pairs(shareList) do
				local id = data.xuid2name(plXuid)
				if id then
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
				if not res then return end
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
							local targetXuid = data.name2xuid(ID)
							if Land.RelationShip.Owner.getXuid(landId) == targetXuid then
								status_list[ID] = _Tr('gui.landtrust.fail.cantaddown')
								goto CONTINUE_ADDTRUST
							end
							if Land.RelationShip.Trusted.add(landId,targetXuid)==false then
								status_list[ID] = _Tr('gui.landtrust.fail.alreadyexists')
							else
								status_list[ID] = _Tr('gui.landtrust.addsuccess')
							end
							:: CONTINUE_ADDTRUST ::
						end
					end
					if res==1 then -- rm
						for n,ID in pairs(selected) do
							local targetXuid = data.name2xuid(ID)
							Land.RelationShip.Trusted.remove(landId,targetXuid)
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
						Callback.Form.BackTo.LandMgr
					)
				end,list)
			end)
		end,
		Nickname = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local Form = mc.newCustomForm()
			Form:setTitle(_Tr('gui.landtag.title'))
			Form:addLabel(_Tr('gui.landtag.tip'))
			Form:addInput("",Land.Options.Nickname.get(landId,2))
			player:sendForm(
				Form,
				function(player,res)
					if not res then return end
					DataStorage.Land.Raw[landId].settings.nickname = res[1]
					DataStorage.Save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						Callback.Form.BackTo.LandMgr
					)
				end
			)
		end,
		Describe = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local desc = Land.Options.Setting.get(landId,'describe')
			if desc=='' then desc='['.._Tr('gui.landmgr.unmodified')..']' end
			local Form = mc.newCustomForm()
			Form:setTitle(_Tr('gui.landdescribe.title'))
			Form:addLabel(_Tr('gui.landdescribe.tip'))
			Form:addInput("",desc)
			player:sendForm(
				Form,
				function(player,res)
					if not res then return end

					DataStorage.Land.Raw[landId].settings.describe=res[1]
					DataStorage.Save({0,1,0})
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						Callback.Form.BackTo.LandMgr
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
							if Land.RelationShip.Owner.check(landId,targetXuid) then
								SendText(player,_Tr('title.landtransfer.canttoown'))
								return
							end
							Land.RelationShip.Owner.set(landId,targetXuid)
							player:sendModalForm(
								_Tr('gui.general.complete'),
								_Tr('title.landtransfer.complete','<a>',Land.Options.Nickname.get(landId,3),'<b>',selected[1]),
								_Tr('gui.general.back'),
								_Tr('gui.general.close'),
								Callback.Form.BackTo.LandMgr
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
					RangeSelector.Create(player,function(player,cube,dimension)
						MEM[xuid].keepingTitle = {
							_Tr('title.selectland.complete1'),
							_Tr('title.selectland.complete2','<a>',cfg.features.selection.tool_name,'<b>','land ok')
						}
						MEM[xuid].reselectLand.range = cube
						MEM[xuid].reselectLand.dimension = dimension
					end)
				end
			)
		end,
		Delete = function(player,landId)
			local xuid = player.xuid
			MEM[xuid].landId = landId
			local cubeInfo = Cube.GetInformation(Map.Land.Position.data[landId])
			local value = math.floor(CalculatePrice(cubeInfo,Land.Util.GetDimension(landId))*cfg.land.refund_rate)
			player:sendModalForm(
				_Tr('gui.delland.title'),
				_Tr('gui.delland.content','<a>',value,'<b>',cfg.economic.currency_name),
				_Tr('gui.general.yes'),
				_Tr('gui.general.cancel'),
				function (player,id)
					if not id then return end
					if Land.RelationShip.Owner.getXuid(landId) == xuid then
						Economy.Player.add(player,value)
					end
					Land.Storage.Delete(landId)
					player:sendModalForm(
						_Tr('gui.general.complete'),
						'Complete.',
						_Tr('gui.general.back'),
						_Tr('gui.general.close'),
						Callback.Form.BackTo.LandMgr
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
			forTol = DataStorage.RelationShip.Raw['Owner']
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
		if customlist then
			MEM[xuid].psr.playerList = 	PlayerSelector.Helper.ToPages(customlist,perpage)
		else
			MEM[xuid].psr.playerList = PlayerSelector.Helper.ToPages(pl_list,perpage)
		end

		-- call
		PlayerSelector.Callback(player,'#')

	end,
	Callback = function (player,data)
		if not data then
			MEM[player.xuid].psr = nil
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
						if string.find(string.lower(name),findTarget) then
							tmpList[#tmpList+1] = name
						end
					end
				end
				local tableList = PlayerSelector.Helper.ToPages(tmpList,perpage)
				if psrdata.nowpage>#tableList then
					psrdata.nowpage = 1
				end
				if not tableList[psrdata.nowpage] then
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
			if next(selected) then
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
				rtn[num] = rtn[num] or {}
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
			(4) -> Range checks. && Show particle.
			(5) -> [Extra] Run as cmd.
		]]
		local xuid = player.xuid
		local dimid = player.pos.dimid
		local mem = MEM[xuid].rsr
		if mem.step == 0 then
			player:sendModalForm(
				_Tr('title.rangeselector.dimension.chose'),
				_Tr('title.rangeselector.dimension.tip'),
				'3D','2D',
				function (player,res)
					mem.step = 1
					if (res and not cfg.land.bought.three_dimension.enable) or (not res and not cfg.land.bought.two_dimension.enable) then
						SendText(player,_Tr('title.rangeselector.dimension.blocked'))
						player:runcmd('land giveup')
						return
					end
					if res then
						SendText(player,_Tr('title.rangeselector.dimension.chosed','<a>','3D'))
						mem.dimension = '3D'
					else
						SendText(player,_Tr('title.rangeselector.dimension.chosed','<a>','2D'))
						mem.dimension = '2D'
					end
				end
			)
		elseif mem.step == 1 then
			if not cfg.features.selection.dimension[dimid+1] then
				SendText(player,_Tr('title.rangeselector.fail.dimblocked'))
				return
			end
			if mem.dimension == '2D' then
				pos.y = Dimension.Get(dimid).min
			end
			mem.dimid = dimid
			mem.posA = pos
			mem.step = 2
			MEM[xuid].keepingTitle[2] = _Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','B')
			SendText(
				player,
				_Tr('title.rangeselector.pointed',
					'<a>','A',
					'<b>',Dimension.Get(dimid).name,
					'<c>',pos.x,'<d>',pos.y,'<e>',pos.z
				)
			)
		elseif mem.step == 2 then
			if mem.dimid ~= dimid then
				SendText(player,_Tr('title.rangeselector.fail.dimdiff'))
				return
			end

			if mem.dimension=='2D' then
				pos.y = Dimension.Get(dimid).max
			end
			mem.posB = pos
			mem.step = 3
			SendText(
				player,
				_Tr('title.rangeselector.pointed',
					'<a>','B',
					'<b>',Dimension.Get(dimid).name,
					'<c>',pos.x,'<d>',pos.y,'<e>',pos.z
				)
			)
			RangeSelector.Push(player,pos)
		elseif mem.step == 3 then
			if mem.dimension ~= '3D' then
				mem.step = 4
				RangeSelector.Push(player)
				return
			end

			local posA,posB = mem.posA,mem.posB
			local dim = Dimension.Get(dimid)
			local Form = mc.newCustomForm()
			Form:setTitle(_Tr('gui.rangeselector.title'))
			Form:addLabel(_Tr('gui.rangeselector.tip'))
			Form:addLabel(_Tr('gui.rangeselector.selectedpos','<a>',posA.x,'<b>',posA.y,'<c>',posA.z,'<d>',posB.x,'<e>',posB.y,'<f>',posB.z))
			Form:addInput(_Tr('gui.rangeselector.movestarty'),dim.min..'~'..dim.max,tostring(posA.y))
			Form:addInput(_Tr('gui.rangeselector.moveendy'),dim.min..'~'..dim.max,tostring(posB.y))
			player:sendForm(Form,function(player,res)
				if not res then return end
				local Ay,By = tonumber(res[1]),tonumber(res[2])
				if not Ay or not By then
					SendText(player,_Tr('gui.rangeselector.invalid'))
					RangeSelector.Push(player)
					return
				end
				posA.y = Ay
				posB.y = By
				mem.step = 4
				RangeSelector.Push(player)
			end)
		elseif mem.step == 4 then
			local passed = false
			local dim = Dimension.Get(mem.dimid)
			local range = Cube.Create(mem.posA,mem.posB,mem.dimid)
			local cubeInfo = Cube.GetInformation(range)
			if (range.posA.y <= dim.min or range.posB.y >= dim.max) and mem.dimension == '3D' then
				SendText(player,_Tr('title.rangeselector.fail.height'))
			elseif cubeInfo.square < cfg.land.bought.square_range[1] and not Land.RelationShip.Operator.check(xuid) then
				SendText(player,_Tr('title.rangeselector.fail.toosmall'))
			elseif cubeInfo.square > cfg.land.bought.square_range[2] and not Land.RelationShip.Operator.check(xuid) then
				SendText(player,_Tr('title.rangeselector.fail.toobig'))
			elseif cubeInfo.height < 2 and mem.dimension == '3D' then
				SendText(player,_Tr('title.rangeselector.fail.toolow'))
			else
				local chkIgnores = {}
				if MEM[xuid].reselectLand then
					chkIgnores = { MEM[xuid].reselectLand.id }
				end
				local chkColl = Land.Util.IsCollision(range,chkIgnores)
				if chkColl.status then
					local sp = cfg.land.min_space
					local chkNearby = Land.Util.IsCollision(Cube.Create(Pos.Add(mem.posA,sp),Pos.Reduce(mem.posB,sp),dimid),chkIgnores)
					if not chkNearby.status then
						SendText(player,_Tr('title.rangeselector.fail.space','<a>',chkNearby.id))
					else
						passed = true
					end
				else
					SendText(player,_Tr('title.rangeselector.fail.collision','<a>',chkColl.id))
				end
			end

			--- Check Result.
			if not passed then
				mem.step = 1
				MEM[xuid].keepingTitle[2] = _Tr('title.rangeselector.selectpoint','<a>',cfg.features.selection.tool_name,'<b>','A')
				return
			end

			MEM[xuid].keepingTitle = nil
			local edge
			if mem.dimension == '3D' then
				edge = Cube.GetEdge(range)
			else
				edge = Cube.GetEdge_2D(range,player.pos.y + 1)
			end
			if #edge < cfg.features.particles.max_amount then
				MEM[xuid].particles = edge
			else
				SendText(player,_Tr('title.rangeselector.largeparticle'))
			end
			mem.cbfunc(player,range,mem.dimension)
			mem.step = 5

		elseif mem.step == 5 then
			-- what the fxxk handle...
			if MEM[xuid].newLand then
				player:runcmd("land buy")
			elseif MEM[xuid].reselectLand then
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
		if not xuid or not MEM[xuid] or not MEM[xuid].safetp then
			return
		end
		local tpos = MEM[xuid].safetp.from_pos
		player:teleport(tpos.x,tpos.y,tpos.z,tpos.dimid)
		MEM[xuid].safetp = nil
	end,
	Do = function(player,tpos)
		local xuid = player.xuid
		local dimid = tpos.dimid
		if MEM[xuid].safetp then -- limited: one request.
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
			if cancel_check or lock or not player then
				return
			end
			local plpos = Pos.ToIntPos(player.pos)
			if tpos.x~=plpos.x or tpos.z~=plpos.z or dimid~=plpos.dimid then
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
			if plpos.y >= def_height and not chunk_loaded then
				SendTitle(player,_Tr('talk.pleasewait'),_Tr('api.safetp.tping.chunkloading'),{0,15,15})
			else
				chunk_loaded = true
				lock = true
				SendTitle(player,_Tr('talk.pleasewait'),_Tr('api.safetp.tping.foundfoothold'),{0,15,15})
				local bl_type_list = {}
				local footholds = {}
				local range = Dimension.Get(dimid)
				for i = range.min,range.max-2 do
					local bl = mc.getBlock(tpos.x,i,tpos.z,dimid)
					bl_type_list[i] = bl.type
				end
				local ct_block = {'minecraft:air','minecraft:lava','minecraft:flowing_lava'}
				for i,type in pairs(bl_type_list) do
					if not Array.Fetch(ct_block,type) and bl_type_list[i+1]==ct_block[1] and bl_type_list[i+2]==ct_block[1] then
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
			if MEM[xuid] then
				if not completed and MEM[xuid].safetp then
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
	Delay = 10,
	GetMemoryCount = function()
		return tonumber(string.format("%.2f",collectgarbage('count')/1024))
	end,
	Interval = function()
		if not DebugHelper.IsEnabled then
			return
		end
		for n,player in pairs(mc.getOnlinePlayers()) do
			local pos = player.blockPos
			local r = 50
			local list = Land.Query.Area(Cube.Create(Pos.Add(pos,r),Pos.Reduce(pos,r),pos.dimid))
			local land = Land.Query.Pos(pos) or 'null'
			INFO('Debug','Position ('..Pos.ToString(pos)..'), Land = '..land..'.')
			if #list~=0 then
				INFO('Debug','Nearby lands \n'..table.toDebugString(list))
			else
				INFO('Debug','There is no land nearby.')
			end
		end
	end
}

Cube = {
	Create = function(posA,posB,dimid)
		dimid = dimid or -1
		posA,posB = Pos.Sort(posA,posB)
		return {
			posA = Pos.ToIntPos(posA,true),
			posB = Pos.ToIntPos(posB,true),
			dimid = dimid
		}
	end,
	ToString = function(AABB)
		return Pos.ToString(AABB.posA)..'|'..Pos.ToString(AABB.posB)..'|'..AABB.dimid
	end,
	HadPos = function(pos,AABB)
		local posA,posB = AABB.posA,AABB.posB
		return (pos.x >= posA.x and pos.x <= posB.x) and
			(pos.y >= posA.y and pos.y <= posB.y) and
			(pos.z >= posA.z and pos.z <= posB.z)
	end,
	Collision = function(AABB_a,AABB_b)
		local a,b = AABB_a,AABB_b
		return (a.posA.x <= b.posB.x and a.posB.x >= b.posB.x) and
			(a.posA.y <= b.posB.y and a.posB.y >= b.posB.y) and
			(a.posA.z <= b.posB.z and a.posB.z >= b.posB.z);
	end,
	GetEdge = function(AABB)
		local edge = {}
		local posB,posA = AABB.posA,AABB.posB
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
	GetEdge_2D = function(AABB,customY)
		local edge = {}
		local posB,posA = AABB.posA,AABB.posB
		customY = customY or posA.y - 1
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
	GetInformation = function(AABB)
		local posA,posB = AABB.posA,AABB.posB
		local cube = {
			height = math.abs(posA.y-posB.y) + 1,
			length = math.max(math.abs(posA.x-posB.x),math.abs(posA.z-posB.z)) + 1,
			width = math.min(math.abs(posA.x-posB.x),math.abs(posA.z-posB.z)) + 1,
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
	ToIntPos = function(pos,removeDimId)
		local result = {
			x = math.floor(pos.x),
			y = math.floor(pos.y),
			z = math.floor(pos.z)
		}
		if not removeDimId and pos.dimid then
			result.dimid = pos.dimid
		end
		return result
	end,
	ToString = function(pos,convDimId)
		local rtn = pos.x..','..pos.y..','..pos.z
		if convDimId and pos.dimid then
			rtn = '['..pos.dimid..'] '..rtn
		end
		return rtn
	end,
	ToArray = function(pos)
		local rtn = {
			pos.x,
			pos.y,
			pos.z
		}
		if pos.dimid then
			rtn[4] = pos.dimid
		end
		return rtn
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

Array = {
	ToIntPos = function(array)
		local rtn = {
			x = math.floor(array[1]),
			y = math.floor(array[2]),
			z = math.floor(array[3])
		}
		if array[4] then
			rtn.dimid = array[4]
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
		return nil
	end,
	Concat = function(origin,array)
		for n,k in pairs(array) do
			origin[#origin+1] = k
		end
		return origin
	end,
	Remove = function(array,value)
		local pos = Array.Fetch(array,value)
		if pos then
			table.remove(array,pos)
		end
		return array
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

EventSystem = {

	EV = {
		onCreate = 1,
		onDelete = 2,
		onEnter = 3,
		onLeave = 4,
		onChangeRange = 5,
		onChangeOwner = 6,
		onChangeDescribe = 7,
		onChangeName = 8,
		onChangeTrust = 9,
		onChangeSetting = 10,
		onChangePermission = 11
	},
	_ev = {},
	_cb = {},
	Init = function()
		EventSystem._cb = {
			Before = {},
			After = {}
		}
		for ev,id in pairs(EventSystem.EV) do
			EventSystem._cb.Before[id] = {}
			EventSystem._cb.After[id] = {}
			EventSystem._ev[id] = ev
		end
		return true
	end,
	-- [enum] event, [string] Before|After, [table] extradata
	Call = function(event,type,extradata)
		local rtn = true
		for n,func in pairs(EventSystem._cb[type][event]) do
			if not func then
				goto JUMPOUT_EV_CALL;
			end
			local m = func(extradata)
			if m ~= nil and (m == 0 or not m) then
				rtn = false
			end
			:: JUMPOUT_EV_CALL ::
		end
		return rtn
	end,
	-- [enum] event, [string] Before|After, [function] callback
	AddListener = function(event,type,callback)
		local pos = -1
		pos = #EventSystem._cb[type][event] + 1
		EventSystem._cb[type][event][pos] = callback
		return pos
	end,
	getName = function(evId)
		return EventSystem._ev[evId]
	end
}
EventSystem.Init()

Callback = {
	Timer = {
		LandSign = function()
			for xuid,res in pairs(MEM) do
				local player = mc.getPlayer(xuid)

				if not player then
					goto JUMPOUT_LANDSIGN
				end

				local landId = Land.Query.Pos(player.blockPos)
				if not landId then
					MEM[xuid].inland = 'null'
					goto JUMPOUT_LANDSIGN
				end
				if landId==MEM[xuid].inland then
					goto JUMPOUT_LANDSIGN
				end

				local ownerXuid = Land.RelationShip.Owner.getXuid(landId)
				local ownerId = '?'
				if ownerXuid then
					ownerId = data.xuid2name(ownerXuid)
				end
				local landcfg = DataStorage.Land.Raw[landId].settings

				if (xuid==ownerXuid or Land.RelationShip.Trusted.check(landId,xuid)) and landcfg.signtome then
					-- owner/trusted
					if not landcfg.signtome then
						goto JUMPOUT_LANDSIGN
					end
					SendTitle(player,
						_Tr('sign.listener.ownertitle','<a>',Land.Options.Nickname.get(landId,2)),
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

				if not player then
					goto JUMPOUT_BUTTOMSIGN
				end

				local landId = Land.Query.Pos(player.blockPos)
				if not landId then
					goto JUMPOUT_BUTTOMSIGN
				end
				local landcfg = DataStorage.Land.Raw[landId].settings
				if not landcfg.signbuttom then
					goto JUMPOUT_BUTTOMSIGN
				end

				local ownerXuid = Land.RelationShip.Owner.getXuid(landId)
				local ownerId = '?'
				if ownerXuid then
					ownerId = data.xuid2name(ownerXuid)
				end
				if (xuid==ownerXuid or Land.RelationShip.Trusted.check(landId,xuid)) and landcfg.signtome then
					player:sendText(_Tr('title.landsign.ownenrbuttom','<a>',Land.Options.Nickname.get(landId,3)),4)
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
				if cfg.features.particles.enable and res.particles then -- Keeping Particles
					local player = mc.getPlayer(xuid)
					for n,pos in pairs(res.particles) do
						if MEM[xuid].newLand then
							if MEM[xuid].newLand.dimension == '2D' then
								pos.y = player.blockPos.y + 2
							end
						elseif MEM[xuid].reselectLand then
							if MEM[xuid].reselectLand.dimension == '2D' then
								pos.y = player.blockPos.y + 2
							end
						end
						--- handle box offset.
						pos = Pos.Add(pos,0.5)
						pos.y = pos.y + 1
						mc.spawnParticle(pos.x,pos.y,pos.z,player.pos.dimid,cfg.features.particles.name)
					end
				end
				if res.keepingTitle then -- Keeping Title
					local title = res.keepingTitle
					if type(title)=='table' then
						SendTitle(mc.getPlayer(xuid),title[1],title[2],{0,40,20})
					else
						SendTitle(mc.getPlayer(xuid),title,{0,100,0})
					end
				end
			end
		end
	},
	Form = {
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
	},
	Event = {
		onExplode = function(source,pos,radius,range,isDestroy,isFire)

			if not Map.Listener.check('onExplode') then
				return
			end

			local bp = Pos.ToIntPos(pos)
			local landId = Land.Query.Pos(bp)
			if not landId then
				local r = math.floor(radius) + 1
				local lands = Land.Query.Area(Cube.Create(Pos.Add(bp,r),Pos.Reduce(bp,r),pos.dimid))
				if #lands==0 then
					return
				end
				for i,landId in pairs(lands) do
					if not DataStorage.Land.Raw[landId].settings.ev_explode then
						return false
					end
				end
			else
				if DataStorage.Land.Raw[landId].settings.ev_explode then
					return
				end
			end

			return false
		end
	}
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
	if not UnNeedThisPrefix then
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

	if not tab[pathes[1]] then
		return
	end

	local T = typeEx(tab[pathes[1]])
	if T ~= 'table' and (T~='array' or (T=='array' and typeEx(value)=='array')) then
		tab[pathes[1]] = value
		return
	end

	table.setKey(tab[pathes[1]],table.concat(pathes,'.',2,#pathes),value)

end

function table.concatEx(origin,tbl)
	for a,b in pairs(tbl) do
		origin[a] = b
	end
	return origin
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
	mc.runcmdEx('ll unload iland-core.lua')
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
	local function isLLSupported(list)
		local version = ll.version()
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
	if rawInfo.Updates[2] and rawInfo.Updates[2].NumVer~=Plugin.Version.toNumber() then
		ERROR(_Tr('console.update.vacancy'))
	elseif rawInfo.FILE_Version~=Server.version then
		ERROR(_Tr('console.getonline.failbyver','<a>',rawInfo.FILE_Version))
	elseif rawInfo.DisableClientUpdate then
		ERROR(_Tr('console.update.disabled'))
	else
		updata = rawInfo.Updates[1]
		if not isLLSupported(updata.LXL) then
			ERROR(_Tr('console.update.unsupport'))
		else
			checkPassed = true
		end
	end
	if not checkPassed then
		return
	end

	-- Check Plugin version
	if updata.NumVer<=Plugin.Version.toNumber() then
		ERROR(_Tr('console.autoupdate.alreadylatest','<a>',updata.NumVer..'<='..Plugin.Version.toNumber()))
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

	INFO('AutoUpdate',Plugin.Version.toString()..' => '..updata.Version)
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

end

function Plugin.Reload()
	mc.runcmdEx('ll reload iland-core.lua')
end

-- Tools & Feature functions.

function _Tr(a,...)
	local rtn = I18N.LangPack.data[a] or a
	return string.gsubEx(rtn,...)
end
function SendTitle(player,title,subtitle,times)
	local name = player.realName
	times = times or {20,25,20}
	mc.runcmdEx('titleraw "' .. name .. '" times '..times[1]..' '..times[2]..' '..times[3])
	if subtitle then
		mc.runcmdEx('titleraw "'..name..'" subtitle {"rawtext": [{"text":"'..subtitle..'"}]}')
	end
	mc.runcmdEx('titleraw "'..name..'" title {"rawtext": [{"text":"'..title..'"}]}')
end
function SendText(player,text,mode)
	-- [mode] 0 = FORCE USE TALK
	if not mode and not cfg.features.force_talk then
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
	local price = ll.eval(string.gsubEx(
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
function EntityGetType(type)
	if type=='minecraft:player' then
		return 0
	end
	if Map.Control.data[4].animals[type] then
		return 1
	end
	if Map.Control.data[4].mobs[type] then
		return 2
	end
	return 0
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

	-- [Client] Command Registry.

	mc.regPlayerCmd('land',_Tr('command.land'),function(player,args)
		if #args~=0 then
			SendText(player,_Tr('command.error','<a>',args[1]),0)
			return
		end
		local pos = player.blockPos
		local xuid = player.xuid
		local landId = Land.Query.Pos(pos)
		if landId and Land.RelationShip.Owner.getXuid(landId) == xuid then
			MEM[xuid].landId=landId
			OpenGUI.FastLMgr(player)
		else
			local land_count = tostring(#DataStorage.RelationShip.Raw['Owner'][xuid])
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
					if not id then return end
					if id==0 then
						player:runcmd('land new')
					elseif id==1 then
						player:runcmd('land gui')
					elseif id==2 then
						player:runcmd('land tp')
					end
				end
			)
		end
	end)
	mc.regPlayerCmd('land new',_Tr('command.land_new'),function (player,args)
		local xuid = player.xuid

		if MEM[xuid].reselectLand then
			SendText(player,_Tr('title.reselectland.fail.makingnewland'))
			return
		end
		if MEM[xuid].newLand then
			SendText(player,_Tr('title.getlicense.alreadyexists'))
			return
		end
		if not Land.RelationShip.Operator.check(xuid) and #DataStorage.RelationShip.Raw['Owner'][xuid]>=cfg.land.max_lands then
			SendText(player,_Tr('title.getlicense.limit'))
			return
		end
		MEM[xuid].newLand = {}
		RangeSelector.Create(player,function(player,cube,dimension)
			MEM[xuid].keepingTitle = {
				_Tr('title.selectland.complete1'),
				_Tr('title.selectland.complete2','<a>',cfg.features.selection.tool_name,'<b>','land buy')
			}
			MEM[xuid].newLand.range = cube
			MEM[xuid].newLand.dimension = dimension
		end)

	end)
	mc.regPlayerCmd('land giveup',_Tr('command.land_giveup'),function (player,args)
		local xuid = player.xuid
		if MEM[xuid].newLand then
			MEM[xuid].newLand = nil
			RangeSelector.Clear(player)
			SendText(player,_Tr('title.giveup.succeed'))
		elseif MEM[xuid].reselectLand then
			MEM[xuid].reselectLand = nil
			RangeSelector.Clear(player)
			SendText(player,_Tr('title.reselectland.giveup.succeed'))
		end
	end)
	mc.regPlayerCmd('land gui',_Tr('command.land_gui'),function (player,args)
		OpenGUI.LMgr(player)
	end)
	mc.regPlayerCmd('land set',_Tr('command.land_set'),function (player,args)
		local xuid = player.xuid
		if MEM[xuid].rsr then
			RangeSelector.Push(player,player.blockPos)
		else
			SendText(player,_Tr('title.rangeselector.fail.outmode'))
		end
	end)
	mc.regPlayerCmd('land buy',_Tr('command.land_buy'),function (player,args)
		local xuid = player.xuid
		if not MEM[xuid].newLand or not MEM[xuid].newLand.range then
			SendText(player,_Tr('talk.invalidaction'))
			return
		end
		local res = MEM[xuid].newLand
		local cubeInfo = Cube.GetInformation(res.range)
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
			'<g>',Economy.Player.get(player)))
		Form:addButton(_Tr('gui.buyland.button.confirm'),'textures/ui/realms_green_check')
		Form:addButton(_Tr('gui.buyland.button.close'),'textures/ui/recipe_book_icon')
		Form:addButton(_Tr('gui.buyland.button.cancel'),'textures/ui/realms_red_x')
		player:sendForm(Form,
			function (player,res)
				if not res or res==1 then
					SendText(player,_Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name))
					return
				end
				if res==2 then
					player:runcmd('land giveup')
					return
				end

				local xuid = player.xuid
				local range = MEM[xuid].newLand.range
				local player_credits = Economy.Player.get(player)
				local landId
				if price > player_credits then
					SendText(player,_Tr('title.buyland.moneynotenough').._Tr('title.buyland.ordersaved','<a>',cfg.features.selection.tool_name))
					return
				else
					landId = Land.Storage.Create(xuid,range)
					if landId then
						Economy.Player.del(player,price)
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
	mc.regPlayerCmd('land ok',_Tr('command.land_ok'),function (player,args)
		local xuid = player.xuid
		local mem = MEM[xuid].reselectLand
		if not mem or not mem.range then
			SendText(player,_Tr('talk.invalidaction'))
			return
		end
		local range = mem.range
		local cubeInfo = Cube.GetInformation(range)
		local dimension = mem.dimension
		local landId = mem.id
		local old_cubeInfo = Cube.GetInformation(Map.Land.Position.data[landId])

		-- Checkout
		local nr_price = CalculatePrice(cubeInfo,dimension)
		local or_price = CalculatePrice(old_cubeInfo,dimension)
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
		player:sendModalForm(
			'Checkout',
			_Tr('gui.reselectland.content',
				'<a>',Land.Util.GetDimension(landId),
				'<c>',dimension,
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
				if payT==0 and Economy.Player.get(player)<needto then
					SendText(player,_Tr('title.buyland.moneynotenough'))
					return
				end
				status = Land.Range.Reset(landId,range)
				if status then
					if payT==0 then
						Economy.Player.del(player,needto)
					else
						Economy.Player.add(player,needto)
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
	mc.regPlayerCmd('land mgr',_Tr('command.land_mgr'),function (player,args)
		local xuid = player.xuid
		if not Land.RelationShip.Operator.check(xuid) then
			SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
			return false
		end
		OpenGUI.OPLMgr(player)
	end)
	mc.regPlayerCmd('land mgr selectool',_Tr('command.land_mgr_selectool'),function (player,args)
		local xuid = player.xuid
		if not Array.Fetch(cfg.land.operator,xuid) then
			SendText(player,_Tr('command.land_mgr.noperm','<a>',player.realName),0)
			return false
		end
		SendText(player,_Tr('title.oplandmgr.setselectool'))
		MEM[xuid].selectool=0
	end)
	mc.regPlayerCmd('land tp',_Tr('command.land_tp'),function (player,args)
		if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
		local xuid = player.xuid
		local landlst = {}
		local tplands = {}
		for i,landId in pairs(Land.RelationShip.Owner.getLand(xuid)) do
			local xpos = Land.Options.Teleport.get(landId)
			tplands[#tplands+1] = Dimension.Get(xpos.dimid).name..' ('..Pos.ToString(xpos)..') '..Land.Options.Nickname.get(landId,3)
			landlst[#landlst+1] = landId
		end
		for i,landId in pairs(Land.RelationShip.Trusted.getLand(xuid)) do
			local xpos = Land.Options.Teleport.get(landId)
			tplands[#tplands+1]='§l'.._Tr('gui.landtp.trusted')..'§r '..Dimension.Get(xpos.dimid).name..'('..Pos.ToString(xpos)..') '..Land.Options.Nickname.get(landId,3)
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
			if not id or id==0 then return end
			local landId = landlst[id]
			Land.Util.Teleport(player,landId)
		end
		)
	end)
	mc.regPlayerCmd('land tp set',_Tr('command.land_tp_set'),function (player,args)
		if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
		local xuid = player.xuid
		local pos = player.blockPos

		local landId = Land.Query.Pos(pos)
		if not landId then
			SendText(player,_Tr('title.landtp.fail.noland'))
			return false
		end
		if Land.RelationShip.Owner.getXuid(landId) ~= xuid then
			SendText(player,_Tr('title.landtp.fail.notowner'))
			return false
		end
		DataStorage.Land.Raw[landId].settings.teleport = {
			pos.x,
			pos.y + 1,
			pos.z
		}
		DataStorage.Save({0,1,0})
		player:sendModalForm(
			_Tr('gui.general.complete'),
			_Tr('gui.landtp.point','<a>',Pos.ToString({x=pos.x,y=pos.y+1,z=pos.z}),'<b>',Land.Options.Nickname.get(landId,2)),
			_Tr('gui.general.iknow'),
			_Tr('gui.general.close'),
			Callback.Form.NULL
		)
	end)
	mc.regPlayerCmd('land tp rm',_Tr('command.land_tp_rm'),function (player,args)
		if not cfg.features.landtp then SendText(player,_Tr('talk.feature.disabled'));return end
		local xuid = player.xuid
		local pos = player.blockPos

		local landId = Land.Query.Pos(pos)
		if not landId then
			SendText(player,_Tr('title.landtp.fail.noland'))
			return false
		end
		if Land.RelationShip.Owner.getXuid(landId) ~= xuid then
			SendText(player,_Tr('title.landtp.fail.notowner'))
			return false
		end
		local def = Map.Land.Position.data[landId].posA
		DataStorage.Land.Raw[landId].settings.teleport = {
			def.x,
			def.y + 1,
			def.z
		}
		SendText(player,_Tr('title.landtp.removed'))
	end)

	-- [Server] Command Registry.

	mc.regConsoleCmd('land',_Tr('command.console.land'),function(args)
		if #args~=0 then
			ERROR('Unknown parameter: "'..args[1]..'", plugin wiki: https://myland.amd.rocks/')
			return
		end
		INFO('The server is running iLand v'..Plugin.Version.toString())
		INFO('Github: https://github.com/LiteLDev-LXL/iLand-Core')
		INFO('Memory Used: '..DebugHelper.GetMemoryCount()..'MB')
	end)
	mc.regConsoleCmd('land op',_Tr('command.console.land_op'),function(args)
		local name = table.concat(args,' ')
		local xuid = data.name2xuid(name)
		if xuid == "" then
			ERROR(_Tr('console.landop.failbyxuid','<a>',name))
			return
		end
		if Land.RelationShip.Operator.check(xuid) then
			ERROR(_Tr('console.landop.add.failbyexist','<a>',name))
			return
		end
		table.insert(cfg.land.operator,#cfg.land.operator+1,xuid)
		Map.Land.Operator.update()
		DataStorage.Save({1,0,0})
		INFO('System',_Tr('console.landop.add.success','<a>',name,'<b>',xuid))
	end)
	mc.regConsoleCmd('land deop',_Tr('command.console.land_deop'),function(args)
		local name = table.concat(args,' ')
		local xuid = data.name2xuid(name)
		if xuid == "" then
			ERROR(_Tr('console.landop.failbyxuid','<a>',name))
			return
		end
		if not Land.RelationShip.Operator.check(xuid) then
			ERROR(_Tr('console.landop.del.failbynull','<a>',name))
			return
		end
		Array.Remove(cfg.land.operator,xuid)
		Map.Land.Operator.update()
		DataStorage.Save({1,0,0})
		INFO('System',_Tr('console.landop.del.success','<a>',name,'<b>',xuid))
	end)
	mc.regConsoleCmd('land update',_Tr('command.console.land_update'),function(args)
		if cfg.plugin.network then
			Plugin.Upgrade(Server.memData)
		else
			ERROR(_Tr('console.update.nodata'))
		end
	end)
	mc.regConsoleCmd('land language',_Tr('command.console.land_language'),function(args)
		INFO('I18N',_Tr('console.languages.sign','<a>',cfg.plugin.language,'<b>',_Tr('VERSION')))
		INFO('I18N',I18N.LangPack.GetSign())
	end)
	mc.regConsoleCmd('land language list',_Tr('command.console.land_language_list'),function(args)
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
	mc.regConsoleCmd('land language list-online',_Tr('command.console.land_language_list-online'),function(args)
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
	mc.regConsoleCmd('land language install',_Tr('command.console.land_language_install'),function(args)
		if not args[1] then
			ERROR(_Tr('console.languages.install.misspara'))
			return
		end
		INFO('Network',_Tr('console.languages.list-online.wait'))
		local rawdata = I18N.LangPack.GetRepo()
		if rawdata == false then
			return
		elseif Array.Fetch(I18N.LangPack.GetInstalled(),args[1]) then
			ERROR(_Tr('console.languages.install.existed'))
			return
		elseif not Array.Fetch(rawdata.official,args[1]) and not Array.Fetch(rawdata['3-rd'],args[1]) then
			ERROR(_Tr('console.languages.install.notfound','<a>',args[1]))
			return
		end
		INFO(_Tr('console.autoupdate.download'))
		if I18N.Install(args[1]) then
			INFO(_Tr('console.languages.install.succeed','<a>',args[1]))
		end
	end)
	mc.regConsoleCmd('land language update',_Tr('command.console.land_language_update'),function(args)
		local list = I18N.LangPack.GetInstalled()
		if not args[1] then
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
	mc.regConsoleCmd('land reload',_Tr('command.console.land_reload'),function(args)
		Plugin.Reload()
	end)
	mc.regConsoleCmd('land unload',_Tr('command.console.land_unload'),function(args)
		Plugin.Unload()
	end)

	return true

end

-- Minecraft Eventing.

mc.listen('onJoin',function(player)
	local xuid = player.xuid
	MEM[xuid] = { inland = 'null' }

	local rel = DataStorage.RelationShip
	if rel.Unloaded['Owner'][xuid] then
		rel.Raw['Owner'][xuid] = table.clone(rel.Unloaded['Owner'][xuid])
		for n,landId in pairs(rel.Raw['Owner'][xuid]) do
			Map.Land.Owner.update(landId)
		end
		rel.Unloaded['Owner'][xuid] = nil
	end
	rel.Raw['Owner'][xuid] = rel.Raw['Owner'][xuid] or {}

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

	local xuid = player.xuid

	if not MEM[xuid] then
		return
	end

	--- SafeTp
	if MEM[xuid].safetp then
		SafeTeleport.Cancel(player)
	end

	MEM[xuid] = nil
end)
mc.listen('onDestroyBlock',function(player,block)

	if not Map.Listener.check('onDestroyBlock') then
		return
	end

	local xuid = player.xuid

	if MEM[xuid].selectool==0 then
		local HandItem = player:getHand()
		if HandItem.isNull(HandItem) then goto PROCESS_1 end --fix crash
		SendText(player,_Tr('title.oplandmgr.setsuccess','<a>',HandItem.name))
		cfg.features.selection.tool_type=HandItem.type
		DataStorage.Save({1,0,0})
		MEM[xuid].selectool=-1
		return false
	end

	:: PROCESS_1 ::
	local landId = Land.Query.Pos(block.pos)
	if not landId then return end

	if DataStorage.Land.Raw[landId].permissions.allow_destroy then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onPlaceBlock',function(player,block)

	if not Map.Listener.check('onPlaceBlock') then
		return
	end

	local landId = Land.Query.Pos(block.pos)
	if not landId then return end

	local xuid = player.xuid
	if DataStorage.Land.Raw[landId].permissions.allow_place then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onUseItemOn',function(player,item,block)

	if not Map.Listener.check('onUseItemOn') then
		return
	end

	local landId = Land.Query.Pos(block.pos)
	if not landId then return end

	local xuid = player.xuid
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	local IsConPlus = false
	if not Map.Control.check(0,block.type) then
		if not Map.Control.check(2,item.type) then
			return
		else
			IsConPlus = true
		end
	end

	local perm = DataStorage.Land.Raw[landId].permissions

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

	if not Map.Listener.check('onAttackBlock') then
		return
	end

	local bltype = block.type
	if not Map.Control.check(5,bltype) then
		return
	end

	local landId = Land.Query.Pos(block.pos)
	if not landId then return end

	local xuid = player.xuid
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	if bltype == 'minecraft:dragon_egg' and DataStorage.Land.Raw[landId].permissions.allow_destroy then return end -- 左键龙蛋（拓充）

	SendText(player,_Tr('title.landlimit.noperm'))
	return false

end)
mc.listen('onAttackEntity',function(player,entity)

	if not Map.Listener.check('onAttackEntity') then
		return
	end

	local landId = Land.Query.Pos(entity.blockPos)
	if not landId then return end

	local xuid = player.xuid
	local en = entity.type
	local perm = DataStorage.Land.Raw[landId].permissions
	if Map.Control.check(3,en) then
		if en == 'minecraft:ender_crystal' and perm.allow_destroy then return end -- 末地水晶（拓充）
		if en == 'minecraft:armor_stand' and perm.allow_destroy then return end -- 盔甲架（拓充）
	else
		local entityType = EntityGetType(en)
		if perm.allow_attack_player and entityType == 0 then return end
		if perm.allow_attack_animal and entityType == 1 then return end
		if perm.allow_attack_mobs and entityType == 2 then return end
	end

	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onChangeArmorStand',function(entity,player,slot)

	if not Map.Listener.check('onChangeArmorStand') then
		return
	end

	local landId = Land.Query.Pos(entity.blockPos)
	if not landId then return end

	local xuid = player.xuid
	if DataStorage.Land.Raw[landId].permissions.use_armor_stand then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onTakeItem',function(player,entity)

	if not Map.Listener.check('onTakeItem') then
		return
	end

	local landId = Land.Query.Pos(entity.blockPos)
	if not landId then return end

	local xuid = player.xuid
	if DataStorage.Land.Raw[landId].permissions.allow_pickupitem then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onDropItem',function(player,item)

	if not Map.Listener.check('onDropItem') then
		return
	end

	local landId = Land.Query.Pos(player.blockPos)
	if not landId then return end

	local xuid = player.xuid
	if DataStorage.Land.Raw[landId].permissions.allow_dropitem then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onBlockInteracted',function(player,block)

	if not Map.Listener.check('onBlockInteracted') then
		return
	end

	if not Map.Control.check(1,block.type) then return end
	local landId = Land.Query.Pos(block.pos)
	if not landId then return end

	local xuid = player.xuid
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	local perm = DataStorage.Land.Raw[landId].permissions
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

	if not Map.Listener.check('onUseFrameBlock') then
		return
	end

	local landId=Land.Query.Pos(block.pos)
	if not landId then return end

	local xuid = player.xuid
	if DataStorage.Land.Raw[landId].permissions.use_item_frame then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onSpawnProjectile',function(splasher,entype)

	if not Map.Listener.check('onSpawnProjectile') or not splasher:isPlayer() then
		return
	end

	local landId = Land.Query.Pos(splasher.blockPos)
	if not landId then return end

	local player = splasher:toPlayer()
	local xuid = player.xuid
	local perm = DataStorage.Land.Raw[landId].permissions

	if entype == 'minecraft:fishing_hook' and perm.use_fishing_hook then return end -- 钓鱼竿
	if entype == 'minecraft:splash_potion' and perm.allow_throw_potion then return end -- 喷溅药水
	if entype == 'minecraft:lingering_potion' and perm.allow_throw_potion then return end -- 滞留药水
	if entype == 'minecraft:thrown_trident' and perm.allow_shoot then return end -- 三叉戟
	if entype == 'minecraft:arrow' and perm.allow_shoot then return end -- 箭
	if entype == 'minecraft:crossbow' and perm.allow_shoot then return end -- 弩射烟花
	if entype == 'minecraft:snowball' and perm.allow_dropitem then return end -- 雪球
	if entype == 'minecraft:ender_pearl' and perm.allow_dropitem then return end -- 末影珍珠
	if entype == 'minecraft:egg' and perm.allow_dropitem then return end -- 鸡蛋

	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onMobHurt',function(mob,source,damage)

	if not Map.Listener.check('onMobHurt') or not source or not source:isPlayer() then
		return
	end

	local player = source:toPlayer()
	local landId = Land.Query.Pos(mob.blockPos)
	if not landId then return end

	local entityType = EntityGetType(source.type)
	local perm = DataStorage.Land.Raw[landId].permissions
	if perm.allow_attack_player and entityType == 0 then return end
	if perm.allow_attack_animal and entityType == 1 then return end
	if perm.allow_attack_mobs and entityType == 2 then return end
	if Land.Util.CheckPerm(landId,player.xuid) then return end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onStepOnPressurePlate',function(entity,block)

	if not Map.Listener.check('onStepOnPressurePlate') then
		return
	end

	local landId = Land.Query.Pos(entity.blockPos)
	if not landId then return end

	if DataStorage.Land.Raw[landId].permissions.use_pressure_plate then return end
	if entity:isPlayer() then
		local player = entity:toPlayer()
		local xuid = player.xuid
		if Land.Util.CheckPerm(landId,xuid) then
			return
		end
		SendText(player,_Tr('title.landlimit.noperm'))
	end
	return false
end)
mc.listen('onRide',function(rider,entity)

	if not Map.Listener.check('onRide') then
		return
	end

	if not rider:isPlayer() then
		return
	end

	local landId = Land.Query.Pos(rider.blockPos)
	if not landId then return end

	local player = rider:toPlayer()
	local xuid = player.xuid
	local en=entity.type
	if en=='minecraft:minecart' or en=='minecraft:boat' then
		if DataStorage.Land.Raw[landId].permissions.allow_ride_trans then return end
	else
		if DataStorage.Land.Raw[landId].permissions.allow_ride_entity then return end
	end

	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onWitherBossDestroy',function(entity,posA,posB)

	if not Map.Listener.check('onWitherBossDestroy') then
		return
	end

	for n,landId in pairs(Land.Query.Area(Cube.Create(posA,posB,entity.pos.dimid))) do
		if not DataStorage.Land.Raw[landId].permissions.allow_entity_destroy then
			return false
		end
	end

	return true
end)
mc.listen('onFarmLandDecay',function(pos,entity)

	if not Map.Listener.check('onFarmLandDecay') then
		return
	end

	local landId = Land.Query.Pos(entity.blockPos)
	if not landId then return end
	if DataStorage.Land.Raw[landId].settings.ev_farmland_decay then return end -- EV Allow
	return false
end)
mc.listen('onPistonTryPush',function(pos,block)

	if not Map.Listener.check('onPistonTryPush') then
		return
	end

	local Id_bePushedBlock = Land.Query.Pos(block.pos)
	local Id_pistonBlock = Land.Query.Pos(pos)
	if Id_bePushedBlock and not DataStorage.Land.Raw[Id_bePushedBlock].settings.ev_piston_push and Id_pistonBlock~=Id_bePushedBlock then
		return false
	end

end)
mc.listen('onFireSpread',function(pos)

	if not Map.Listener.check('onFireSpread') then
		return
	end

	local landId = Land.Query.Pos(pos)
	if not landId then return end
	if DataStorage.Land.Raw[landId].settings.ev_fire_spread then return end
	return false
end)
mc.listen('onEat',function(player,item)

	if not Map.Listener.check('onEat') then
		return
	end

	local xuid = player.xuid
	local landId = Land.Query.Pos(player.blockPos)
	if not landId then return end

	if DataStorage.Land.Raw[landId].permissions.eat then return end
	if Land.Util.CheckPerm(landId,xuid) then
		return
	end

	SendText(player,_Tr('title.landlimit.noperm'))
	return false
end)
mc.listen('onRedStoneUpdate',function(block,level,isActive)

	if not Map.Listener.check('onRedStoneUpdate') then
		return
	end

	local pos = block.pos
	local landId = Land.Query.Pos(pos)
	if not landId then return end

	local r = 2
	local lands = Land.Query.Area(Cube.Create(Pos.Add(pos,r),Pos.Reduce(pos,r),pos.dimid))
	for i,Id in pairs(lands) do
		if not DataStorage.Land.Raw[Id].settings.ev_redstone_update then
			return false
		end
	end

end)
mc.listen('onStartDestroyBlock',function(player,block)

	local xuid = player.xuid
	if MEM[xuid].rsr and (not MEM[xuid].rsr.sleep or MEM[xuid].rsr.sleep<os.time()) then
		local HandItem = player:getHand()
		if HandItem:isNull() or HandItem.type~=cfg.features.selection.tool_type then return end
		RangeSelector.Push(player,block.pos)
		MEM[xuid].rsr.sleep = os.time() + 2
	end

end)
mc.listen('onConsoleCmd',function(cmd)
	local m = string.split(cmd,' ')
	if (m[1]=='stop' and not m[2]) and DataStorage.IsPending() then
		DataStorage.INTERVAL()
		INFO('Pending data saved.')
	end
end)
mc.listen('onServerStarted',function()

	-- load owners data
	try
	{
		function ()
			-- DO NOT CHANGE THE LOAD ORDER.
			assert(I18N.Init(),'Error loading I18N!')
			assert(DataStorage.Config.Load(),_Tr('console.loading.fail.config'))
			assert(DataStorage.RelationShip.Load(),_Tr('console.loading.fail.relationship'))
			assert(DataStorage.Land.Load(),_Tr('console.loading.fail.land'))
			assert(Economy.Protocol.set(cfg.economic.protocol),_Tr('console.loading.fail.economy'))
			assert(Map.Init(),_Tr('console.loading.fail.maps'))
			assert(RegisterCommands(),_Tr('console.loading.fail.regcmd'))
		end,
		catch
		{
			function (msg)
				WARN(msg)
				WARN('Plugin closed.')
				Plugin.Unload()
			end
		}
	}

	-- Make timer
	if cfg.features.landsign.enable then
		setInterval(Callback.Timer.LandSign,cfg.features.landsign.frequency*1000)
	end
	if cfg.features.buttomsign.enable then
		setInterval(Callback.Timer.ButtomSign,cfg.features.buttomsign.frequency*1000)
	end
	setInterval(DataStorage.INTERVAL,1000*90)
	setInterval(Callback.Timer.MEM,1000)
	if DEV_MODE then
		setInterval(DebugHelper.Interval,1000*DebugHelper.Delay)
	end

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
				if Plugin.Version.toNumber()<data.Updates[1].NumVer then
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
				if Plugin.Version.toNumber()>data.Updates[1].NumVer then
					INFO('Network',_Tr('console.update.preview','<a>',Plugin.Version.toString()))
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

	local startup_memory = DebugHelper.GetMemoryCount()
	INFO('Load',_Tr('console.loading.map.complete','<a>',startup_memory))
	setInterval(function()
		if DebugHelper.GetMemoryCount() > startup_memory * 1.2 then
			collectgarbage("collect")
		end
	end,1000*60)

end)
mc.listen('onBlockExplode',Callback.Event.onExplode)
mc.listen('onEntityExplode',Callback.Event.onExplode)

-- Export Apis.

Land.API.RunExport()

-- Signs.

INFO('Powerful land plugin is loaded! Ver-'..Plugin.Version.toString()..',')
INFO('By: RedbeanW, License: GPLv3 with additional conditions.')