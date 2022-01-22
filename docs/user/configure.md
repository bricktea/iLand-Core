# Config.json
> **提要** 2.41暂时删除了OPLMgr编辑配置的功能，近期将有更好的方案实现，敬请期待

```lua
{
	version = 241, // 插件版本
	plugin = {
		network = true, // 是否允许联网行为
		language = "zh_CN" // 选定语言
	},
	land = {
		operator = {}, // 领地管理员list，可以用`land op XX`设置
		max_lands = 5, // 每个玩家最多领地
		bought = {
			three_dimension = { // 三维领地
				enable = true, // 是否开启
				calculate_method = "m-1", // 价格计算方式
				price = {20,4} // 价格
			},
			two_dimension = { // 二维领地
				enable = true,
				calculate_method = "d-1",
				price = {35}
			},
			square_range = {4,50000}, // 面积范围，{min,max}
			discount = 1 // 折扣，1为无折扣，0.7为七折
		},
		refund_rate = 0.9 // 退款，1为无退款，0.7为退款70%
	},
	economic = {
		protocol = "llmoney", // 经济套件，默认llmoney，也可以改为`scoreboard`来支持计分板经济
		scoreboard_objname = "", // 如果选择计分板经济，将经济计分板的`objective`写在此
		currency_name = "Coin" // 货币名称
	},
	features = {
		landsign = { // 领地进入时Title提示
			enable = true, // 是否开启，下皆同
			frequency = 2 // 频率，单位秒
		},
		buttomsign = { // 在领地时的Buttom持续提示
			enable = true,
			frequency = 1
		},
		particles = { // 圈地粒子效果相关
			enable = true,
			name = "minecraft:villager_happy", // 粒子名称
			max_amount = 600 // 单玩家最多粒子数量，多出则不开启粒子
		},
		player_selector = { // 玩家选择器相关
			include_offline_players = true, // 允许选择离线玩家
			items_perpage = 20, // 每页玩家数量
		},
		selection = {
			disable_dimension = {}, // 禁止圈地的维度，例如 {1,2} 禁止在下界和末地圈地
			tool_type = "minecraft:wooden_axe", // 圈地工具，可以使用`land mgr selectool`调整
			tool_name = "Wooden Axe" // 圈地工具名称
		},
		landtp = true, // 是否开启领地传送
		force_talk = false, // 是否强制使用聊天方式（不推荐）
		disabled_listener = {}, // 关闭的监听器
        chunk_side = 16 // 区块大小，一般不用动
	}
}
```