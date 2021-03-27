-- ——————————————————————————————————————————————————————————————————
-- ___ _                    _    ~ ------------------------------- ~
-- |_ _| |    __ _ _ __   __| |  ~ To       LiteLoader             ~
--  | || |   / _` | '_ \ / _` |  ~ Author   RedbeanW44602          ~
--  | || |__| (_| | | | | (_| |  ~ License  GPLv3 未经许可禁止商用  ~
-- |___|_____\__,_|_| |_|\__,_|  ~ ------------------------------- ~
-- ——————————————————————————————————————————————————————————————————
local plugin_version = '1.1.1'
local data_path = 'plugins\\LiteLuaLoader\\data\\iland\\'
local ILAPI,newLand,TRS_Form,i18n_data={}
local json = require('cjson')

-- load data file
local cfg = json.decode(ReadAllText(data_path..'config.json'))
local playerCfg = json.decode(ReadAllText(data_path..'players.json'))
local land_data = json.decode(ReadAllText(data_path..'data.json'))
local land_owners = json.decode(ReadAllText(data_path..'owners.json'))

print('[ILand] Powerful land plugin is loaded! Ver-'..plugin_version)