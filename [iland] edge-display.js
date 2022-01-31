/* 
    The land edge diaplay.
    Author: RedbeanW
    License: GPLv3
    Depend: iLand.
*/


let DATA_PATH = 'plugins/iland-edge-display/'
let MEM = {}
let ShowingBox = {}
let cfg = {
    enable: true,
    permission: {
        operator: true,
        landowner: true,
        trusted: true,
        visitor: false
    }
}

logger.setTitle('EdgeDisplay')
logger.setConsole(true)

if (File.exists("EnableILandDevMode")) {
	DATA_PATH = 'plugins/LXL_Plugins/iLand/iland-edge-display/'
}
if (!File.exists(DATA_PATH)) {
	File.mkdir(DATA_PATH)
}

PluginData = {

    load: function() {
        

        if (!File.exists(DATA_PATH+'config.json')) {
            File.writeTo(DATA_PATH+'config.json',JSON.stringify(cfg))
        }
        if (!File.exists(DATA_PATH+'box.json')) {
            File.writeTo(DATA_PATH+'box.json',JSON.stringify({
                ShowingBox: {}
            }))
        }

        cfg = JSON.parse(File.readFrom(DATA_PATH+'config.json'))
        ShowingBox = JSON.parse(File.readFrom(DATA_PATH+'box.json'))

    },

    save: function() {
        
        File.writeTo(DATA_PATH+'box.json',JSON.stringify(ShowingBox))

    }
}

BoundingBox = {

    show: function(vec4) {
        
    },

    clear: function(vec4) {
        
    },

    INTERVAL: function() {
        
    }

}

mc.regPlayerCmd('land show','Show the edge of the land.',function(pl,args) {
    
})

mc.listen('onServerStarted',function() {

    PluginData.load()

})