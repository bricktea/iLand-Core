# Commands

 - 命令前缀：`/land`

### 玩家指令表

命令 | 等级 | 解释
-|-|-
`无子命令` | player | 呼出领地Home
`new` | player | 进入圈地模式
`giveup` | player | 放弃未完成购买/未选定完范围的领地
`gui` | player | 管理领地
`set` | player | 选择领地A/B点
`buy` | player | 购买刚圈好的领地
`ok` | player | 完成重选范围
`tp` | player | 打开领地传送GUI
`tp set` | player | 设定站立点为领地传送点
`tp rm` | player | 移除脚下的领地的传送点（重置为默认）
`mgr` | landMgr | 管理全服领地，编辑配置等
`mgr selectool` | landMgr | 设置圈地工具

### 控制台指令表

命令 | 等级 | 解释
-|-|-
`无子命令` | *Console* | 打印领地介绍信息
`update` | *Console* | 在线更新iLand
`op <ID>` | *Console* | 将玩家设置为领地管理员
`deop <ID>` | *Console* | 取消某玩家的领地管理员身份
`language` | *Console* | 打印正在使用的语言信息
`language list` | *Console* | 列出已安装语言
`language list-online` | *Console* | 列出语言仓库中所有语言
`language install <LANG>` | *Console* | 从语言仓库安装语言
`language update [LANG]` | *Console* | 升级语言，若不忽略参数则升级指定语言
`reload` | *Console* | 重载iLand
`unload` | *Console* | 反加载iLand

### **⚠ 警告**

!> 请尽量避免在在线玩家较多时使用`land reload`，这可能导致许多问题！

!> 如果反加载插件，所有领地保护将立即失效。