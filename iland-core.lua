-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.3'
local langVer = 112
local minLLVer = 210504
local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\'
-- local data_path = 'plugins\\LiteLuaLoader\\lua\\iland\\'
local newLand={};local TRS_Form={}
local MainCmd = 'land'
local debug_mode = true
local json = require('cjson.safe')
local request = require('requests')

-- check file
if IfFile(data_path..'config.json') == false then
	print('[ILand] ERR!! Configure file not found, plugin is closing...');return
end

-- check lllua
if tonumber(lllVersion()) < minLLVer then
	print('[ILand] ERR!! LLLua too old, please use latest version, here ↓')
	print('[ILand] ERR!! https://www.minebbs.com/resources/litelualoader-lua.2390/')
	print('[ILand] ERR!! Plugin closing...')
	return
end

-- load data file
local cfg = json.decode(ReadAllText(data_path..'config.json'))
land_data = json.decode(ReadAllText(data_path..'data.json'))
land_owners = json.decode(ReadAllText(data_path..'owners.json'))

-- preload function
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
function iland_save()
	WriteAllText(data_path..'config.json',json.encode(cfg))
	WriteAllText(data_path..'data.json',json.encode(land_data))
	WriteAllText(data_path..'owners.json',json.encode(land_owners))
end
function pos2chunk(posx,posz)
	local p = cfg.features.chunk_side
	if p<=4 then p=16 end
	a={}
	a.x=math.floor(posx/p)
	a.z=math.floor(posz/p)
	return a
end
function buildVec(x,y,z,dim)
	local t={}
	t.x=x
	t.y=y
	t.z=z
	if dim~=nil then
		t.dim=dim
	end
	return t
end
function formatXYZ(sX,sY,sZ,eX,eY,eZ)
	local A=buildVec(sX,sY,sZ)
	local B=buildVec(eX,eY,eZ)
	local tmp1
	if A.x>B.x then A.x,B.x = B.x,A.x end
	if A.y>B.y then A.y,B.y = B.y,A.y end
	if A.z>B.z then A.z,B.z = B.z,A.z end
	return A,B
end

-- cfg -> updater
do
	if cfg.version==nil then --version<1.0.4
		cfg.version={};cfg.version=103
		cfg.manager.operator={}
		iland_save()
	end
	if cfg.version==103 then
		cfg.version=106
		cfg.manager.allow_op_delete_land=nil
		for landId, val in pairs(land_data) do
			if(land_data[landId].range==nil) then
				land_data[landId]=nil
			end
		end
		iland_save()
	end
	if cfg.version==106 then
		cfg.version=107
		cfg.update_check=true
		for landId, val in pairs(land_data) do
			land_data[landId].setting.allow_open_barrel=false
		end
		iland_save()
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
			land_data[landid].settings.share=deepcopy(land_data[landid].setting.share)
			land_data[landid].settings.nickname=''
			land_data[landid].permissions=deepcopy(land_data[landid].setting)
			land_data[landid].setting=nil
			land_data[landid].permissions.share=nil
			land_data[landid].range.start_position={}
			land_data[landid].range.end_position={}
			land_data[landid].range.start_position[1]=deepcopy(land_data[landid].range.start_x)
			land_data[landid].range.start_position[2]=deepcopy(land_data[landid].range.start_y)
			land_data[landid].range.start_position[3]=deepcopy(land_data[landid].range.start_z)
			land_data[landid].range.end_position[1]=deepcopy(land_data[landid].range.end_x)
			land_data[landid].range.end_position[2]=deepcopy(land_data[landid].range.end_y)
			land_data[landid].range.end_position[3]=deepcopy(land_data[landid].range.end_z)
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
		cfg.land_buy.price[1]=deepcopy(cfg.land_buy.price_ground)
		cfg.land_buy.price[2]=deepcopy(cfg.land_buy.price_sky)
		cfg.land_buy.price_ground=nil
		cfg.land_buy.price_sky=nil
		cfg.features.chunk_side=16
		cfg.features.sign_frequency=deepcopy(cfg.features.frequency)
		cfg.features.frequency=nil
		for landId,val in pairs(land_data) do
			land_data[landId].settings.describe=''
		end
		iland_save()
	end
	if cfg.version==112 then
		cfg.version=113
		for landId,data in pairs(land_data) do
			local sX=land_data[landId].range.start_position[1]
			local sY=land_data[landId].range.start_position[2]
			local sZ=land_data[landId].range.start_position[3]
			local eX=land_data[landId].range.end_position[1]
			local eY=land_data[landId].range.end_position[2]
			local eZ=land_data[landId].range.end_position[3]
			local result={formatXYZ(sX,sY,sZ,eX,eY,eZ)}
			local posA=result[1]
			local posB=result[2]
			land_data[landId].range.start_position[1]=posA.x
			land_data[landId].range.start_position[2]=posA.y
			land_data[landId].range.start_position[3]=posA.z
			land_data[landId].range.end_position[1]=posB.x
			land_data[landId].range.end_position[2]=posB.y
			land_data[landId].range.end_position[3]=posB.z
		end
		iland_save()
	end
end

-- load language file
local i18n_data = json.decode(ReadAllText(data_path..'lang\\'..cfg.manager.default_language..'.json'))
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
		while (sX+size*count<=eX) do
			local t = pos2chunk(sX+size*count,sZ+size*count)
			chkmap(t.x,t.z)
			table.insert(ChunkMap[t.x][t.z],#ChunkMap[t.x][t.z]+1,landId)
			local count2 = 0
			while (sZ+size*count2<=eZ) do
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
		vecMap[landId].a = buildVec(spos[1],spos[2],spos[3]) --start
		vecMap[landId].b = buildVec(epos[1],epos[2],epos[3]) --end
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
		iland_save()
	end
end
function EV_playerLeft(e)
	TRS_Form[e]=nil
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
	local xuid = Actor:getXuid(player)
	local player_credits = money_get(player)
	if newLand[player].landprice>player_credits then
		Actor:sendText(player,_tr('title.buyland.moneynotenough'),5);return
	else
		money_del(player,newLand[player].landprice)
	end
	Actor:sendText(player,_tr('title.buyland.succeed'),5)
	local A=newLand[player].posA
	local B=newLand[player].posB
	local result={formatXYZ(A.x,A.y,A.z,B.x,B.y,B.z)}
	ILAPI_CreateLand(xuid,result[1],result[2],newLand[player].dim)
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
	land_data[landid].permissions.allow_destory=toBool(raw[3])
	land_data[landid].permissions.allow_place=toBool(raw[2])
	land_data[landid].permissions.allow_exploding=toBool(raw[11])
	land_data[landid].permissions.allow_attack=toBool(raw[5])
	land_data[landid].permissions.allow_open_chest=toBool(raw[4])
	land_data[landid].permissions.allow_pickupitem=toBool(raw[7])
	land_data[landid].permissions.allow_dropitem=toBool(raw[6])
	land_data[landid].permissions.allow_use_item=toBool(raw[8])
	land_data[landid].permissions.allow_open_barrel=toBool(raw[9])
	iland_save()
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
		if isValInList(land_data[landid].settings.share,x)~=-1 then
			Actor:sendText(player,_tr('title.landtrust.alreadyexists'),5);return
		end
		land_data[landid].settings.share[n]=x
		iland_save()
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
		table.remove(land_data[landid].settings.share,isValInList(land_data[landid].settings.share,x))
		iland_save()
		GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
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
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
												'Complete.',
												_tr('gui.general.back'),
												_tr('gui.general.close'))
end
function FORM_land_gui_describe(player,raw,data)
	local landid=TRS_Form[player].landid
	if isTextSpecial(gsubEx(raw[2],
							'$','Y', -- allow some spec.
							',','Y',
							'.','Y',
							'!','Y'
						)) then
		Actor:sendText(player,'FAILED',5);return
	end
	land_data[landid].settings.describe=raw[2]
	iland_save()
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
	table.remove(land_owners[xuid],isValInList(land_owners[xuid],landid))
	table.insert(land_owners[go],#land_owners[go]+1,landid)
	iland_save()
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
									gsubEx(_tr('title.landtransfer.complete'),
										'<a>',ILAPI_GetNickname(landid),
										'<b>',Actor:xid2str(go)),
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function FORM_land_gui_delete(player,index,text)
	if index==1 then return end
	local landid=TRS_Form[player].landid
	ILAPI_DeleteLand(landid)
	money_add(player,TRS_Form[player].landvalue)
	GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.general.complete'),
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
		GUI(player,'ModalForm','FORM_BACK_LandMgr',_tr('gui.landmgr.landinfo.title'),
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
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		local d=shacopy(land_data[landid].settings.share)
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
	if raw[2]==3 then --领地nickname
		local nickn=ILAPI_GetNickname(landid)
		if nickn=='' then nickn='['.._tr('gui.landmgr.unnamed')..']' end
		GUI(player,'lmgr_landname','FORM_land_gui_name',_tr('gui.landtag.title'),
														_tr('gui.landtag.tip'),
														nickn)
	end
	if raw[2]==4 then --领地describe
		local desc=ILAPI_GetDescribe(landid)
		if desc=='' then desc='['.._tr('gui.landmgr.unmodified')..']' end
		GUI(player,'lmgr_landdescribe','FORM_land_gui_describe',_tr('gui.landdescribe.title'),
															_tr('gui.landdescribe.tip'),
															desc)
	end
	if raw[2]==5 then --领地过户
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		GUI(player,'lmgr_landtransfer','FORM_land_gui_transfer',_tr('gui.landtransfer.title'),
									_tr('gui.landtransfer.tip'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
	end
	if raw[2]==6 then --删除领地
		local height = math.abs(land_data[landid].range.start_position[2] - land_data[landid].range.end_position[2])
		local length = math.abs(land_data[landid].range.start_position[1] - land_data[landid].range.end_position[1])
		local width = math.abs(land_data[landid].range.start_position[3] - land_data[landid].range.end_position[3])
		TRS_Form[player].landvalue=math.modf(calculation_price(length,width,height)*cfg.land_buy.refund_rate)
		GUI(player,'ModalForm','FORM_land_gui_delete',_tr('gui.delland.title'),
												gsubEx(_tr('gui.delland.content'),
													'<a>',TRS_Form[player].landvalue,
													'<b>',_tr('talk.credit_name')),
												_tr('gui.general.yes'),
												_tr('gui.general.cancel'))
	end
end
function FORM_land_mgr_transfer(player,raw,data)
	if raw[2]==0 then return end
	local landid=TRS_Form[player].targetland
	local from=ILAPI_GetOwner(landid)
	if from=='?' then return end
	local go=Actor:str2xid(TRS_Form[player].playerList[raw[2]+1])
	if go==from then return end
	table.remove(land_owners[from],isValInList(land_owners[from],landid))
	table.insert(land_owners[go],#land_owners[go]+1,landid)
	iland_save()
	GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),
									gsubEx(_tr('title.landtransfer.complete'),
										'<a>',landid,
										'<b>',Actor:xid2str(go)),
									_tr('gui.general.back'),
									_tr('gui.general.close'))
end
function FORM_land_mgr(player,raw,data)

	cfg.land_buy.refund_rate=raw[5]/100
	cfg.features.landSign=toBool(raw[7])
	cfg.update_check=toBool(raw[8])
	iland_save()
	
	if raw[3]==0 then GUI(player,'ModalForm','FORM_BACK_LandOPMgr',_tr('gui.general.complete'),"Complete.",_tr('gui.general.back'),_tr('gui.general.close'));return end
	local count=0;local landid=-1
	for i,v in pairs(land_data) do
		count=count+1
		if count==raw[3] then landid=i;break end
	end
	if landid==-1 then return end
	if raw[4]==1 then -- tp to land.
		Actor:teleport(player,land_data[landid].range.start_position[1],land_data[landid].range.start_position[2],land_data[landid].range.start_position[3],land_data[landid].range.dim)
	end
	if raw[4]==2 then -- transfer land.
		TRS_Form[player].playerList = GetOnlinePlayerList(2)
		TRS_Form[player].targetland=landid
		table.insert(TRS_Form[player].playerList,1,'['.._tr('gui.general.plzchose')..']')
		iland_save()
		GUI(player,'lmgr_landtransfer','FORM_land_mgr_transfer',_tr('gui.oplandmgr.trsland.title'),
									_tr('gui.oplandmgr.trsland.content'),
									_tr('talk.land.selecttargetplayer'),
									json.encode(TRS_Form[player].playerList))
		return
	end
	if raw[4]==3 then -- delete land.
		ILAPI_DeleteLand(landid)
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
		Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posA.x .. '\nY=' .. newLand[player].posA.y .. '\nZ=' .. newLand[player].posA.z ..'\n'.._tr('title.selectrange.spointb'),5)
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
        Actor:sendText(player,'DIM='..newLand[player].dim..'\nX=' .. newLand[player].posB.x .. '\nY=' .. newLand[player].posB.y .. '\nZ=' .. newLand[player].posB.z ..'\n'.._tr('title.selectrange.bebuy'),5)
		newLand[player].step = 2
    end
	if mode==2 then
		IL_BP_CreateOrder(player)
	end
end
function IL_BP_CreateOrder(player)
	local xuid = Actor:getXuid(player)
    if newLand[player]==nil or newLand[player].step~=2 then
		Actor:sendText(player,_tr('title.createorder.failbystep'),5)
        return
    end
    local length = math.abs(newLand[player].posA.x - newLand[player].posB.x)
    local width = math.abs(newLand[player].posA.z - newLand[player].posB.z)
    local height = math.abs(newLand[player].posA.y - newLand[player].posB.y)
    local vol = length * width * height
    local squ = length * width
	--- 违规圈地判断
	if squ>cfg.land.land_max_square and isValInList(cfg.manager.operator,xuid)==-1 then
		Actor:sendText(player,_tr('title.createorder.toobig').._tr('title.selectrange.spointa'),5)
		newLand[player].step=0
		return
	end
	if squ<cfg.land.land_min_square and isValInList(cfg.manager.operator,xuid)==-1 then
		Actor:sendText(player,_tr('title.createorder.toosmall').._tr('title.selectrange.spointa'),5)
		newLand[player].step=0
		return
	end
	if height<2 then
		Actor:sendText(player,_tr('title.createorder.toolow').._tr('title.selectrange.spointa'),5)
		newLand[player].step=0
		return
	end
	local edge=cubeGetEdge(newLand[player].posA,newLand[player].posB)
	for i=1,#edge do
		for landId, val in pairs(land_data) do
			if land_data[landId].range.dim~=newLand[player].dim then goto JUMPOUT_1 end --维度不同直接跳过
			local s_pos={};s_pos.x=land_data[landId].range.start_position[1];s_pos.y=land_data[landId].range.start_position[2];s_pos.z=land_data[landId].range.start_position[3]
			local e_pos={};e_pos.x=land_data[landId].range.end_position[1];e_pos.y=land_data[landId].range.end_position[2];e_pos.z=land_data[landId].range.end_position[2]
			if isPosInCube(edge[i],s_pos,e_pos)==true then
				Actor:sendText(player,_tr('title.createorder.collision').._tr('title.selectrange.spointa'),5)
				newLand[player].step=0
				return
			end
			:: JUMPOUT_1 ::
		end
	end
	for landId, val in pairs(land_data) do --反向再判一次，防止直接大领地包小领地
		if land_data[landId].range.dim~=newLand[player].dim then goto JUMPOUT_2 end --维度不同直接跳过
		s_pos={};e_pos={}
		s_pos.x=land_data[landId].range.start_position[1]
		s_pos.y=land_data[landId].range.start_position[2]
		s_pos.z=land_data[landId].range.start_position[3]
		e_pos.x=land_data[landId].range.end_position[1]
		e_pos.y=land_data[landId].range.end_position[2]
		e_pos.z=land_data[landId].range.end_position[3]
		edge=cubeGetEdge(s_pos,e_pos)
		for i=1,#edge do
			if isPosInCube(edge[i],newLand[player].posA,newLand[player].posB)==true then
				Actor:sendText(player,_tr('title.createorder.collision').._tr('title.selectrange.spointa'),5)
				newLand[player].step=0
				return
			end
		end
		:: JUMPOUT_2 ::
	end
	--- 购买
    newLand[player].landprice = calculation_price(length,width,height)
	GUI(player,'ModalForm','FORM_land_buy', -- %1 callback
						_tr('gui.buyland.title'), --%2 title
						gsubEx(_tr('gui.buyland.content'),'<a>',length,'<b>',width,'<c>',height,'<d>',vol,'<e>',newLand[player].landprice,'<f>',_tr('talk.credit_name'),'<g>',money_get(player)), -- %3 content
						_tr('gui.general.buy'), -- %4 button1
						_tr('gui.general.close')) --%5 button2
end
function IL_BP_GiveUp(player)
    if newLand[player]==nil then
        Actor:sendText(player,_tr('title.giveup.failed'),5);return
    end
	newLand[player]=nil
	Actor:sendText(player,_tr('title.giveup.succeed'),5)
end
function IL_Manager_GUI(player)
	local xuid=Actor:getXuid(player)
	if #land_owners[xuid]==0 then
		Actor:sendText(player,_tr('title.landmgr.failed'),5);return
	end

	local xyz=pos2vec({Actor:getPos(player)})
	xyz.y=xyz.y-1
	local lid=ILAPI_PosGetLand(xyz)
	local nname=ILAPI_GetNickname(lid)
	if nname=='' then nname=lid end
	local welcomeText=_tr('gui.landmgr.content')
	if lid~=-1 then
		welcomeText=welcomeText..gsubEx(_tr('gui.landmgr.ctplus'),'<a>',nname)
	end
	local features={_tr('gui.landmgr.options.landinfo'),_tr('gui.landmgr.options.landperm'),_tr('gui.landmgr.options.landtrust'),_tr('gui.landmgr.options.landtag'),_tr('gui.landmgr.options.landdescribe'),_tr('gui.landmgr.options.landtransfer'),_tr('gui.landmgr.options.delland')}
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
function IL_Manager_OPGUI(player)
	local landlst={}
	for i,v in pairs(land_data) do
		local thisOwner=ILAPI_GetOwner(i)
		if thisOwner~='?' then thisOwner=Actor:xid2str(thisOwner) else thisOwner='?' end
		if land_data[i].settings.nickname=='' then
			landlst[#landlst+1]='['.._tr('gui.landmgr.unnamed')..'] ('..thisOwner..') ['..i..']'
		else
			landlst[#landlst+1]=land_data[i].settings.nickname..' ('..thisOwner..') ['..i..']'
		end
	end
	table.insert(landlst,1,'['.._tr('gui.general.plzchose')..']')
	local features={_tr('gui.oplandmgr.donothing'),_tr('gui.oplandmgr.tp'),_tr('gui.oplandmgr.transfer'),_tr('gui.oplandmgr.delland')}
	GUI(player,'opmgr','FORM_land_mgr',_tr('gui.oplandmgr.title'),
									_tr('gui.oplandmgr.tip'),
									_tr('gui.oplandmgr.landmgr'),
									_tr('gui.oplandmgr.selectland'),json.encode(landlst),
									_tr('gui.oplandmgr.selectoption'),json.encode(features),
									_tr('gui.oplandmgr.refundrate'),tostring(cfg.land_buy.refund_rate*10),
									_tr('gui.oplandmgr.pluginconfig'),
									_tr('gui.oplandmgr.enablelandsign'),tostring(cfg.features.landSign),
									_tr('gui.oplandmgr.checkupdate'),tostring(cfg.update_check))
end
function IL_CmdFunc(player,cmd)
	if player==0 then return end
	local xuid=Actor:getXuid(player)
	-- [ ] Main Command
	if cmd == MainCmd then
		land_count=tostring(#land_owners[xuid])
		GUI(player,'ModalForm','FORM_BACK_LandMgr', -- %1 callback
						gsubEx(_tr('gui.land.title'),'<a>',plugin_version), -- %2 title
						gsubEx(_tr('gui.land.content'),'<a>',land_count), _tr('talk.landmgr.open'), _tr('gui.general.close'), -- %3 content
						_tr('talk.landmgr.open'), --%4 button1
						_tr('gui.general.close')) --%5 button2
	end
	-- [new] Create newLand
	if cmd == MainCmd..' new' then
		if newLand[player]~=nil then
			Actor:sendText(player,_tr('title.getlicense.alreadyexists').._tr('title.selectrange.spointa'),5);return -1
		end
		if isValInList(cfg.manager.operator,xuid)==-1 then
			if #land_owners[xuid]>=cfg.land.player_max_lands then
				Actor:sendText(player,_tr('title.getlicense.limit'),5);return -1
			end
		end
		Actor:sendText(player,_tr('title.getlicense.succeed').._tr('title.selectrange.spointa'),5)
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
		if isValInList(cfg.manager.operator,xuid)==-1 then return end
		IL_Manager_OPGUI(player)
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
function ILAPI_CreateLand(xuid,startpos,endpos,dimensionid)
	local landId
	while true do
		landId=getGuid()
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
	iland_save()
	buildChunks()
	buildVecMap()
end
function ILAPI_DeleteLand(landid)
	if land_data[landid]==nil then
		if debug_mode then print('[ILAPI] [DeleteLand] WARN!! Deleting nil land('..landid..').') end
		return
	end
	local owner=ILAPI_GetOwner(landid)
	if owner~='?' then
		table.remove(land_owners[owner],isValInList(land_owners[owner],landid))
	end
	land_data[landid]=nil
	iland_save()
	buildChunks()
	buildVecMap()
end
function ILAPI_GetPlayerLands(xuid)
	if land_owners[xuid]==nil then 
		if debug_mode then print('[ILAPI] [GetPlayerLands] WARN!! Getting nil player('..xuid..').') end
		return ''
	end
	return land_owners[xuid]
end
function ILAPI_GetNickname(landid)
	if land_data[landid]==nil then 
		if debug_mode then print('[ILAPI] [GetNickname] WARN!! Getting nil land('..landid..').') end
		return ''
	end
	return land_data[landid].settings.nickname
end
function ILAPI_GetDescribe(landid)
	if land_data[landid]==nil then 
		if debug_mode then print('[ILAPI] [GetDescribe] WARN!! Getting nil land('..landid..').') end
		return ''
	end
	return land_data[landid].settings.describe
end
function ILAPI_GetOwner(landid)
	if land_data[landid]==nil then
		if debug_mode then print('[ILAPI] [GetOwner] WARN!! Getting nil land('..landid..').') end
		return '?'
	end
	for i,v in pairs(land_owners) do
		if isValInList(v,landid)~=-1 then
			return i
		end
	end
	return '?'
end
function ILAPI_PosGetLand(vec4)
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
function ILAPI_GetVersion()
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
	t.x=math.modf(table[1])
	t.y=math.modf(table[2])
	t.z=math.modf(table[3])
	t.dim=table[4]
	return t
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
	-- [Debug] print(edge[p].x,edge[p].y,edge[p].z,' ',edge[p-1].x,edge[p-1].y,edge[p-1].z,' ',edge[p-2].x,edge[p-2].y,edge[p-2].z,' ',edge[p-3].x,edge[p-3].y,edge[p-3].z)
	for i=1,math.abs(math.abs(posA.y)-math.abs(posB.y))+1 do
		if posA.y>posB.y then
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
		if posA.x>posB.x then
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
		if posA.z>posB.z then
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
	if (pos.x>=posA.x and pos.x<=posB.x) or (pos.x<=posA.x and pos.x>=posB.x) then
		if (pos.y>=posA.y and pos.y<=posB.y) or (pos.y<=posA.y and pos.y>=posB.y) then
			if (pos.z>=posA.z and pos.z<=posB.z) or (pos.z<=posA.z and pos.z>=posB.z) then
				return true
			end
		end
	end
	return false
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
function isTextSpecial(text)
	local flag='[%s%p%c%z]'
	if string.find(text,flag)==nil then
		return false
	end
	return true
end	
function isTextNum(text)
	if tonumber(text)==nil then
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
function toBool(num)
	if num==0 then return false else return true end
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
	-- print(Item:getFullName(Actor:getHand(player)))
	if newLand[player]~=nil and Item:getName(Actor:getHand(player))=='Wooden Axe' then
		IL_BP_SelectRange(player,buildVec(x,y,z,dim),newLand[player].step)
		return -1
	end

	local pos=buildVec(x,y,z,dim)
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_destory==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerPlaceBlock(player,block,x,y,z,dim)
	local pos=buildVec(x,y,z,dim)
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_place==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerUseItem(player,item,blockname,x,y,z,dim)
	if blockname=='minecraft:barrel' then return end -- sb mojang
	local pos=buildVec(x,y,z,dim)
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_use_item==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerOpenChest(player,x,y,z,dim)
	local pos=buildVec(x,y,z,dim)
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_open_chest==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerOpenBarrel(player,x,y,z,dim)
	local pos=buildVec(x,y,z,dim)
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_open_barrel==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:teleport(player,x,y+10,z,dim)
end
function IL_LIS_onPlayerAttack(player,mobptr)
	local pos=pos2vec({Actor:getPos(mobptr)})
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_attack==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onExplode(ptr,x,y,z,dim)
	local pos=pos2vec({x,y,z,dim})
	local landid=ILAPI_PosGetLand(pos)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_exploding==true then return end -- Perm Allow
	return -1
end
function IL_LIS_onPlayerTakeItem(player,itemptr)
	local pos=pos2vec({Actor:getPos(itemptr)})
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_pickupitem==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_LIS_onPlayerDropItem(player,itemptr)
	local pos=pos2vec({Actor:getPos(player)})
	pos.y=pos.y-1
	local landid=ILAPI_PosGetLand(pos)
	local xuid=Actor:getXuid(player)
	if landid==-1 then return end -- No Land
	if land_data[landid].permissions.allow_dropitem==true then return end -- Perm Allow
	if isValInList(cfg.manager.operator,xuid)~=-1 then return end -- Manager
	if isValInList(land_owners[xuid],landid)~=-1 then return end -- Owner
	if isValInList(land_data[landid].settings.share,xuid)~=-1 then return end -- Trust
	Actor:sendText(player,_tr('title.landlimit.noperm'),5)
	return -1
end
function IL_TCB_LandSign()
	local players=GetOnlinePlayerList(0)
	for i,v in pairs(players) do
		local xyz=pos2vec({Actor:getPos(v)})
		xyz.y=xyz.y-1
		local landid=ILAPI_PosGetLand(xyz)
		if landid==-1 then TRS_Form[v].inland='null';return end -- no land here
		if landid==TRS_Form[v].inland then return end -- signed
		local owner=ILAPI_GetOwner(landid)
		local ownername='?'
		if owner~='?' then ownername=Actor:xid2str(owner) end
		local slname=ILAPI_GetNickname(landid)
		if slname=='' then slname='<'.._tr('gui.landmgr.unnamed')..'>' end
		if Actor:getXuid(v)==owner then
			sendTitle(v,gsubEx(_tr('sign.listener.ownertitle'),'<a>',slname),_tr('sign.listener.ownersubtitle'))
		else
			sendTitle(v,_tr('sign.listener.visitortitle'),gsubEx(_tr('sign.listener.visitorsubtitle'),'<a>',ownername))
			if land_data[landid].settings.describe~='' then
				Actor:sendText(v,'§l§b[§a LAND §b] §r'..gsubEx(land_data[landid].settings.describe,
																	'$visitor',Actor:getName(v),
																	'$n','\n'
																),0)
			end
		end
		TRS_Form[v].inland=landid
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

-- timer -> debugger
function DEBUG_LANDQUERY()
	if debug_landquery == 0 then return end
	local xyz=pos2vec({Actor:getPos(debug_landquery)})
	xyz.y=xyz.y-1
	local landid=ILAPI_PosGetLand(xyz)
	print('[ILand] Debugger: '..landid)
end
if debug_mode then
schedule("DEBUG_LANDQUERY",3,0)
end

-- check update
if cfg.update_check then
	local response=request.get('http://cdisk.amd.rocks/tmp/ILAND/v111_version')
	if response.status_code~=200 then
		print('[ILand] ERR!! Get version info failed.('..response.status_code..')')
	end
	local data=json.decode(response.text)
	if data.version~=plugin_version then
		print('[ILand] '..gsubEx(_tr('console.newversion'),'<a>',data.version))
		print('[ILand] '.._tr('console.update'))
	end
	if data.t_e then
		print('[ILand] '..data.text)
	end
end

-- register cmd.
makeCommand(MainCmd,_tr('command.land'),1)
makeCommand(MainCmd..' new',_tr('command.land_new'),1)
makeCommand(MainCmd..' giveup',_tr('command.land_giveup'),1)
makeCommand(MainCmd..' gui',_tr('command.land_gui'),1)
makeCommand(MainCmd..' mgr',_tr('command.land_mgr'),5)
print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)