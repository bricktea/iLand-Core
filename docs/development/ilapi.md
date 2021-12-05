# API 接口文档
> ILAPI已在v2.30后全面升级为V2接口版本，改动部分较多，请注意适配。

### 核心操作类

##### `ILAPI_CreateLand` - 创建领地
 - 传入参数
   - xuid - `string` 玩家XUID
   - startpos - `Vec3` 起点坐标
   - endpos - `Vec3` 终点坐标
   - dimid - `number` 维度ID
 - 返回值 `string` 成功创建返回对应的LandID

##### `ILAPI_DeleteLand` - 删除领地
 - 传入参数
   - landId - `string` 领地ID
 - 返回值 `bool` 是否成功删除

##### `ILAPI_PosGetLand` - 通过坐标查询领地
 - 传入参数
   - pos - `Vec4` 任意**整数**坐标
 - 返回值
   - `string` LandID，返回`-1`代表坐标没有领地

##### `ILAPI_GetChunk` - 获得一个区块内加载的领地列表
 - 传入参数
   - pos - `vec2` 任意坐标
   - dimid - `number` 维度ID
 - 返回值
   - `table` 区块内里的列表，返回`-1`代表区块内无领地

##### `ILAPI_GetDistance` - 获取一个坐标与领地的最短距离
 - 传入参数
   - landId - `string` 领地ID
   - pos - `Vec4` 任意坐标
 - 返回值
   - `number` 距离

### 信息获取类 - 领地

##### `ILAPI_CheckPerm` - 检查领地某权限开启状态
 - 传入参数
   - landId - `string` 领地ID
   - perm - `string` 权限名
 - 返回值
   - `bool` 权限控制项状态

##### `ILAPI_CheckSetting` - 检查领地某设置项开启状态
 - 传入参数
   - landId - `string` 领地ID
   - perm - `string` 设置项名
 - 返回值
   - `bool` 设置项状态

##### `ILAPI_GetRange` - 获取领地对角坐标
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `table` 返回一个数组，第一、二成员是对角坐标，第三个成员是维度ID

##### `ILAPI_GetEdge` - 获取领地边框坐标
 - 传入参数
   - landId - `string` 领地ID
   - dimtype - `string` 可选值：`2D`、`3D`
 - 返回值
   - `table` 领地边缘坐标数组

##### `ILAPI_GetLandDimension` - 获取领地维数
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `string` 2D或3D

##### `ILAPI_GetName` - 获取领地昵称
 - 传入参数
   - landId - `string` 领地ID
 - 返回值 
   - `string` 领地昵称

##### `ILAPI_GetDescribe` - 获取领地备注
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `string` 领地备注

##### `ILAPI_GetOwer` - 获取领地主人
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `string` 主人XUID

##### `ILAPI_GetPoint` - 获取领地传送点
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `Vec4` 传送点坐标

### 信息获取类 - 玩家

##### `ILAPI_GetPlayerLands` - 获取玩家拥有的领地
 - 传入参数
   - xuid - `string` 玩家XUID
 - 返回值
   - `table` 返回一个数组，包含玩家拥有的LandID

##### `ILAPI_IsPlayerTrusted` - 玩家是否被领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 玩家XUID
 - 返回值
   - `bool` 是否信任

##### `ILAPI_IsLandOwner` - 玩家是否是领地主人
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 玩家XUID
 - 返回值
   - `bool` 是否是领地主人

##### `ILAPI_IsLandOperator` - 玩家是否是领地管理员
 - 传入参数
   - xuid - `string` 玩家XUID
 - 返回值
   - `bool` 是否是领地管理员

##### `ILAPI_GetAllTrustedLand` - 获取玩家被信任的领地列表
 - 传入参数
   - xuid - `string` 玩家XUID
 - 返回值
   - `table` 所有信任该玩家的领地LandID表

### 领地管理类

##### `ILAPI_GetAllLands` - 获取所有LandID
 - 传入参数 `无`
 - 返回值
   - `table` 返回一个数组，包含全部领地ID

##### `ILAPI_UpdatePermission` - 更新领地权限
 - 传入参数
   - landId - `string` 领地ID
   - permName - `string` 权限名
   - value - `bool` 允许或不允许
 - 返回值
   - `bool` 是否修改成功

##### `ILAPI_UpdateSetting` - 更新领地设定
 - 传入参数
   - landId - `string` 领地ID
   - settingName - `string` 设定名
   - value - `bool|table` 设置值
 - 返回值
   - `bool` 是否修改成功

##### `ILAPI_AddTrust` - 添加领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `bool` 是否操作成功

##### `ILAPI_RemoveTrust` - 删除领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `bool` 是否操作成功

##### `ILAPI_SetOwner` - 设置领地主人
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `bool` 是否操作成功

##### `ILAPI_Teleport` - 传送玩家到领地（安全）
 - 传入参数
   - xuid - `string` 目标玩家的XUID（必须在线!）
   - landId - `string` 领地ID
 - 返回值
   - `bool` 是否操作成功

### 插件类

##### `ILAPI_GetMoneyProtocol` - 获取正在使用的经济组件
 - 传入参数 `无`
 - 返回值
   - `string` 经济套件名称，如`llmoney`、`scoreboard`

##### `ILAPI_GetLanguage` - 获取设定的语言类型
 - 传入参数 `无`
 - 返回值
   - `string` 语言类型，如`zh_CN`

##### `ILAPI_GetChunkSide` - 获取设定的区块边长
 - 传入参数 `无`
 - 返回值
   - `number` 区块边长

##### `ILAPI_GetVersion` - 获取iLand版本号
 - 传入参数 `无`
 - 返回值
   - `number` 版本号

##### Example
```lua
-- 示例：调用ILAPI创建领地
cl = lxl.import("ILAPI_CreateLand")
cl('1145141919810',{x=11,y=4,z=51},{x=41,y=91,z=98},1)

```