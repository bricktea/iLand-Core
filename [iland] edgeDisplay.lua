-- <ILAPI> Edge Display
-- Author : RedbeanW

local JSON <const> = require('dkjson')
local cfg = {
    version = 100,
    display = {
        enter = {
            enabled = false,
            show_distance = 50
        },
        command = {
            enabled = false,
            permission = 1,
            cmd = 'look'
        }
    },
    particle = {
        keep = 8,
        type = "minecraft:village_happy"
    }
}

local landApis = {
    getVersion = lxl.import('ILAPI_GetVersion'),
    getEdge = lxl.import('ILAPI_GetEdge'),
    getLand = lxl.import('ILAPI_PosGetLand')
}

function CalculateDistance(vec1,vec2)
    return math.sqrt((vec1.x-vec2.x)^2+(vec1.y-vec2.y)^2+(vec1.z-vec2.z)^2)
end

function INFO(msg)
    print('[iLand] |EdgeDisplay| '..msg)
end

if landApis.getVersion() == nil then
    error("edgeDisplay depends on iLand, but iLand is not installed.")    
    return
end

