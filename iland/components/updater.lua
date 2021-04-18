function ILTOL_chkUpd()
    if(cfg.update_check) then
        local t=tool:HttpGet('http://cdisk.amd.rocks/tmp/ILAND/version')
        latest_version=string.sub(t,string.find(t,'<',1)+1,string.find(t,'>',1)-1)
        if(latest_version=='') then latest_version=plugin_version end
        if(plugin_version~=latest_version) then
            print('[ILand] '..gsubEx(I18N('console.newversion'),'<a>',latest_version))
            print('[ILand] '..I18N('console.update'))
        end
    end
end

function ILTOL_updCfg()
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
		cfg.version==111
		cfg.manager.i18n=nil
		cfg.manager.default_language='zh_CN'
		local newData={}
		for i,v in pairs(land_data) do
			land_data[i].permissions={}
			land_data[i].permissions.allow_place=land_data[i].setting.allow_place
			land_data[i].permissions.allow_exploding=land_data[i].setting.allow_exploding
			land_data[i].permissions.allow_attack=land_data[i].setting.allow_attack
			land_data[i].permissions.allow_pickupitem=land_data[i].setting.allow_pickupitem
			land_data[i].permissions.allow_open_barrel=land_data[i].setting.allow_open_barrel
			land_data[i].permissions.allow_destory=land_data[i].setting.allow_destory
			land_data[i].permissions.allow_use_item=land_data[i].setting.allow_use_item
			land_data[i].permissions.allow_dropitem=land_data[i].setting.allow_dropitem
			land_data[i].permissions.allow_open_chest=land_data[i].setting.allow_open_chest
			land_data[i].settings={}
			land_data[i].settings.share={}
			for a,b in pairs(land_data.setting.share) do
				land_data[i].settings.share[a]=b
			end
			land_data.setting=nil
			land_data.range.start_position={}
			land_data.range.start_position[1]=land_data.range.start_x
			land_data.range.start_position[2]=land_data.range.start_y
			land_data.range.start_position[3]=land_data.range.start_z
			land_data.range.end_position[1]=land_data.range.end_x
			land_data.range.end_position[2]=land_data.range.end_y
			land_data.range.end_position[3]=land_data.range.end_z
			land_data.range.start_x=nil
			land_data.range.start_y=nil
			land_data.range.start_z=nil
			land_data.range.end_x=nil
			land_data.range.end_y=nil
			land_data.range.end_z=nil
		end
		iland_save()
	end
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