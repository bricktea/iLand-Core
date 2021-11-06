---@diagnostic disable: undefined-global
do
    if cfg.version==nil or cfg.version<200 then
        ERROR('Configure file too old, you must rebuild it.')
        return
    end
    if cfg.version==200 then
        cfg.version=210
        cfg.money.credit_name='Gold-Coins'
        cfg.money.discount=100
        cfg.features.land_2D=true
        cfg.features.land_3D=true
        cfg.features.auto_update=true
        for landId,data in pairs(land_data) do
            land_data[landId].range.dimid = CloneTable(land_data[landId].range.dim)
            land_data[landId].range.dim=nil
            for n,xuid in pairs(land_data[landId].settings.share) do
                if type(xuid)~='string' then
                    land_data[landId].settings.share[n]=tostring(land_data[landId].settings.share[n])
                end
            end
        end
        ILAPI.save({1,1,0})
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
        ILAPI.save({1,0,0})
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
            settings.ev_explode=CloneTable(perm.allow_exploding)
            settings.ev_farmland_decay=false
            settings.ev_piston_push=false
            settings.ev_fire_spread=false
            settings.signbuttom=true
            perm.use_door=false
            perm.use_stonecutter=false
            perm.allow_exploding=nil
        end
        ILAPI.save({1,1,0})
    end
    if cfg.version==220 or cfg.version==221 then
        cfg.version=223
        ILAPI.save({1,0,0})
    end
    if cfg.version==223 then
        cfg.version=224
        for landId,data in pairs(land_data) do
            land_data[landId].permissions.use_bucket=false
        end
        ILAPI.save({1,1,0})
    end
    if cfg.version==224 then
        cfg.version=230
        cfg.features.disabled_listener = {}
        cfg.features.blockLandDims = {}
        cfg.features.nearby_protection = {
            side = 10,
            enabled = true,
            blockselectland = true
        }
        cfg.features.regFakeCmd=true
        cfg.features.playersPerPage=20
        for landId,data in pairs(land_data) do
            local perm = land_data[landId].permissions
            if data.range.start_position.y==0 and data.range.end_position.y==255 then
                land_data[landId].range.start_position.y=minY
                land_data[landId].range.start_position.y=maxY
            end
            perm.use_firegen=false
            perm.allow_attack=nil
            perm.allow_attack_player=false
            perm.allow_attack_animal=false
            perm.allow_attack_mobs=true
        end
        ILAPI.save({1,1,0})
    end
    if cfg.version==230 then
        cfg.version=231
        cfg.verison=nil -- sb..
        for landId,data in pairs(land_data) do
            local perm = land_data[landId].permissions
            if #perm~=50 then
                INFO('AutoRepair','Land <'..landId..'> Has wrong perm cfg, resetting...')
                perm.allow_destroy=false
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
                perm.allow_throw_potion=false
                perm.allow_ride_entity=false
                perm.allow_ride_trans=false
                perm.allow_shoot=false
            end
        end
        ILAPI.save({1,1,0})
    end
    if cfg.version==231 then
        cfg.version=240
        for landId,data in pairs(land_data) do
            local perm = land_data[landId].permissions
            perm.allow_entity_destroy=false
            perm.useitem=false
        end
        ILAPI.save({1,1,0})
    end
end