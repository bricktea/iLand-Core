-- <ILAPI> Nearby Protect
-- Author : RedbeanW

JSON = require('dkjson')
Plugin = {
    version = "1.0",
    numver = 100,
    dependLand = 240
}

local landApis
local cfg = {
    version = 100,
    protect = {
        piston_push = {
            enabled = true,
            distance = 5
        },
        liquid_flow = {
            enabled = true
        }
    },
    ignoreLands = {}
}

mc.listen("onPistonPush",function(pos,block)
    
end)

mc.listen("onServerStarted",function ()

    -- import apis from iland
    landApis = {
        getVersion = lxl.import('ILAPI_GetVersion'),
        getLand = lxl.import('ILAPI_PosGetLand'),
        getChunk = lxl.import('ILAPI_GetChunk'),
        -- isListened = lxl.import('ILAPI_IsListened')
        -- setListener = lxl.import('ILAPI_SetListener')
        getDistance = lxl.import('ILAPI_GetDistance')
    }

    -- check
    local version = landApis.getVersion()
    if version == nil or version < Plugin.dependLand then
        error("edgeDisplay depends on iLand, but iLand is not installed or too old.")
        Unload()
        return
    end

end)

function Unload()
    mc.runcmdEx('lxl unload "[iland] nearbyProtect.lua"')
end

function INFO(msg)
    print('[iLand] |NearbyProtect| '..msg)
end