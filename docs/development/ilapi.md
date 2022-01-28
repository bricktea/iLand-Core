# API 接口文档
> ILAPI已在v2.30后全面升级为V2接口版本，改动部分较多，请注意适配。

!> **接口使用注意事项**<br>
    1. LXL远程调用系统传递数据实际上是使用`JSON`，不能转为JSON的参数不可以传递，故接口间不能传递引擎提供的数据类型，比如`Player`、`Entity`、`IntPos`之类的，只有语言提供的数据类型比如`number`、`boolean`、`string`可以传递，否则值会变成`nil`(Null)。<br>
    2. 由于LXL远程调用系统的问题，函数返回时若返回一个只有一个元素的数组，数组到达调用者的时候外面的数组消失，返回值只有那一个元素。<br>
    3. iLand所有坐标运算单位均为`1`，请不要向ILAPI中传递浮点数，以免出现报错。

> **数据类型约定**<br> 
1. `Vec3` 指一个含有整数元素`x`、`y`、`z`的`table`，如下：
```lua
local vec3 = {
    x = 12,
    y = 33,
    z = 45
}
```
2. `Vec4` 指一个在`Vec3`基础上又包含了维度信息的`table`，如下：
```lua
local vec4 = {
    ...
    dimid = 0
}
```
3. `XUID` 就是 `string`，请不要向接口传递整数型的XUID。 

> **调用示例**<br>

```js
// 当玩家在领地内破坏方块时，发出一个提示。
let GetLand = lxl.import('ILAPI_PosGetLand')
let GetOwner = lxl.import('ILAPI_GetOwner')
function toRawPos(pos) {
  return {
    x: pos.x,
    y: pos.y,
    z: pos.z,
    dimid: pos.dimid
  }
}
mc.listen('onDestroyBlock',function(player,block) {
  let land = GetLand(toRawPos(player.blockPos))
  if (land!=-1) {
    let owner = data.xuid2name(GetOwner(land))
    player.sendText('你在'+owner+'的领地里破坏了方块！')
  }
})
```

### 核心操作类

##### `ILAPI_CreateLand` - 创建领地
 - 传入参数
   - xuid - `string` 目标玩家的XUID
   - startpos - `Vec3` 起点坐标
   - endpos - `Vec3` 终点坐标
   - dimid - `number` 维度ID
 - 返回值 `string` 成功创建返回对应的LandID

##### `ILAPI_DeleteLand` - 删除领地
 - 传入参数
   - landId - `string` 领地ID
 - 返回值 `boolean` 是否成功删除

##### `ILAPI_PosGetLand` - 通过坐标查询领地
 - 传入参数
   - pos - `Vec4` 任意坐标
   - noAccessCache - `boolean` （可选参数）不访问缓存
 - 返回值
   - `string` landId

!> 若没有领地，返回值是`-1`

##### `ILAPI_GetChunk` - 获得一个区块内加载的领地列表
 - 传入参数
   - pos - `vec2` 任意坐标
   - dimid - `number` 维度ID
 - 返回值
   - `table` 区块内里的列表

!> 若没有领地，返回值是`-1`

##### `ILAPI_GetDistance` - 获取一个坐标与领地的最短距离
 - 传入参数
   - landId - `string` 领地ID
   - pos - `Vec4` 任意坐标
 - 返回值
   - `number` 距离

!> 若要获取一个范围内的领地，请使用`ILAPI_GetLandInRange`。

##### `ILAPI_GetLandInRange` - 获取一个长方体内所有领地
 - 传入参数
   - startpos - `Vec3` 任意坐标
   - endpos - `Vec3` 任意坐标
   - dimid - `number` 维度ID
   - noAccessCache - `boolean` （可选参数）不访问缓存
 - 返回值
   - `table` 一个数组，包含所有符合条件的领地ID

### 信息获取类 - 领地

##### `ILAPI_CheckPerm` - 检查领地某权限开启状态
 - 传入参数
   - landId - `string` 领地ID
   - perm - `string` 权限名
 - 返回值
   - `boolean` 权限控制项状态

?> 权限名可参考配置文件`data.json` >> `permissions`

##### `ILAPI_CheckSetting` - 检查领地某设置项开启状态
 - 传入参数
   - landId - `string` 领地ID
   - perm - `string` 设置项名
 - 返回值
   - `boolean` 设置项状态

?> 设置项名可参考配置文件`data.json` >> `settings`

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

##### `ILAPI_GetOwner` - 获取的领地主人
 - 传入参数
   - landId - `string` 领地ID
 - 返回值
   - `string` 主人XUID

!> 如果这是一个无主领地，返回值是`?`

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

!> 若要检查一个玩家是否有在领地内操作的权限，应把下面三个API配合使用以获得最好的性能。

##### `ILAPI_IsPlayerTrusted` - 玩家是否被领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 玩家XUID
 - 返回值
   - `boolean` 是否信任

##### `ILAPI_IsLandOwner` - 玩家是否是领地主人
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 玩家XUID
 - 返回值
   - `boolean` 是否是领地主人

##### `ILAPI_IsLandOperator` - 玩家是否是领地管理员
 - 传入参数
   - xuid - `string` 玩家XUID
 - 返回值
   - `boolean` 是否是领地管理员

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
   - value - `boolean` 允许或不允许
 - 返回值
   - `boolean` 是否修改成功

##### `ILAPI_UpdateSetting` - 更新领地设定
 - 传入参数
   - landId - `string` 领地ID
   - settingName - `string` 设定名
   - value - `boolean|table` 设置值
 - 返回值
   - `boolean` 是否修改成功

##### `ILAPI_AddTrust` - 添加领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `boolean` 是否操作成功

##### `ILAPI_RemoveTrust` - 删除领地信任
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `boolean` 是否操作成功

##### `ILAPI_SetOwner` - 设置领地主人
 - 传入参数
   - landId - `string` 领地ID
   - xuid - `string` 目标玩家的XUID
 - 返回值
   - `booleab` 是否操作成功

##### `ILAPI_Teleport` - 传送玩家到领地（安全）
 - 传入参数
   - xuid - `string` 目标玩家的XUID（必须在线!）
   - landId - `string` 领地ID
 - 返回值
   - `boolean` 是否操作成功

?> 安全传送可以避免玩家传送后卡在墙里窒息而死。

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

##### `ILAPI_IsListenerDisabled` - 获取指定监听器是否被关闭
 - 传入参数 `无`
 - 返回值
   - `boolean` 开启/关闭

##### `ILAPI_GetApiVersion` - 获取ILAPI版本号
 - 传入参数 `无`
 - 返回值
   - `number` 版本号

##### `ILAPI_GetVersion` - 获取iLand版本号
 - 传入参数 `无`
 - 返回值
   - `number` 版本号