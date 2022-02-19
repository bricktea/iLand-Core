# Events 事件文档

`2.80` 后，由于ILAPI已经不能满足领地拓展的需求，故设计此简单事件系统。

### 注册监听器

主要由两个ILAPI进行：

##### `ILAPI_AddBeforeEventListener` - 添加一个事件前监听器
##### `ILAPI_AddAfterEventListener` - 添加一个事件后监听器
 - 传入参数
   - event - `string` 欲监听的事件名
   - callback - `string` 导出的回调函数名
 - 返回值 `number` 监听器ID

!> **注意**<br>
    1. 以上两个ILAPI参数完全一致。<br>
    2. Before事件在行为执行前（将要执行时）触发，部分可返回`false`拦截。<br>
    3. After事件在行为执行完毕后触发，不可以拦截。<br>

回调函数原型：
```js
function callback(dict) {
    // (Object) dict > m1,m2,m3...
}
```

实例：[Github](https://github.com/LiteLScript-Dev/iLand-Mods/blob/main/iland-EventTest.js)

### 可用事件列表

##### `onAskLicense` - 请求创建领地
Before | ✔️ | After | ❌ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mPlayer - `string` 操作玩家的XUID

##### `onCreate` - 创建领地
Before | ✔️ | After | ✔️ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 将创建领地的landId
   - mPlayer - `string` 操作玩家的XUID
   - mRange - `AABB` 将创建领地的范围

!> `2.80` 使用After模式监听时，没有`mRange`回传，下个版本将解决此问题。

##### `onDelete` - 删除领地
Before | ✔️ | After | ✔️ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 将创建领地的landId

##### `onChangeRange` - 领地范围变化
Before | ✔️ | After | ❌ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 将创建领地的landId
   - mNew - `AABB` 将被变化为此范围

##### `onChangeOwner` - 领地主人变化
Before | ✔️ | After | ❌ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 将创建领地的landId
   - mNew - `string` 将成为主人的玩家XUID

##### `onChangeTrust` - 领地信任成员变化
Before | ✔️ | After | ❌ | Cancel | ✔️
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 将创建领地的landId
   - mActionType - `number` 操作类型：`0`代表增加，`1`代表删除。
   - mPlayer - `string` 被操作的玩家

##### `onEnter` - 玩家进入领地
Before | ❌ | After | ✔️ | Cancel | ❌
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 进入的领地的landId
   - mPlayer - `string` 此玩家的XUID

##### `onLeave` - 玩家离开领地
Before | ❌ | After | ✔️ | Cancel | ❌
:-----:|:---:|:-----:|:--:|:------:|:---:
 - 回调内容
   - mLandID - `string` 离开的领地的landId
   - mPlayer - `string` 此玩家的XUID