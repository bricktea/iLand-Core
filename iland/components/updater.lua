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

function ILTOL_chkCfg()
    if(cfg.version==nil) then --version<1.0.4
		cfg.version={};cfg.version=103
		cfg.manager.operator={}
		iland_save()
	end
	if(cfg.version==103) then
		cfg.version=106
		cfg.manager.allow_op_delete_land=nil
		for landId, val in pairs(land_data) do
			if(land_data[landId].range==nil) then
				land_data[landId]=nil
			end
		end
		iland_save()
	end
	if(cfg.version==106) then
		cfg.version=107
		cfg.update_check=true
		for landId, val in pairs(land_data) do
			land_data[landId].setting.allow_open_barrel=false
		end
		iland_save()
	end
	if(cfg.version==107) then
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
end