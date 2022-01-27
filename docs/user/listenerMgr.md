# Listener Manager

### 呼出
 - `/land mgr` 领地管理员可用

### 简介
此功能允许您关闭一些监听器，以此避免插件影响原版游戏体验或规避某些事件因自身的问题导致的插件问题。

!> **注意** 不要随意关闭一个监听器，除非你知道自己在干什么！

### 可关闭监听器

名称 | 简单介绍 | 参考建议
-|-|-
onDestroyBlock | 关闭后不再干涉玩家破坏方块 | ⛔
onPlaceBlock | 关闭后不再干涉玩家放置方块 | ⛔
onUseItemOn | 关闭后对大部分功能性方块控制失效 | ⛔
onAttackEntity | 关闭后不再干涉玩家攻击生物行为 | ⛔
onAttackBlock | 关闭后不再干涉玩家攻击方块行为 | ⛔
onExplode | 关闭后不再干涉游戏内常规爆炸 | ℹ️
onTakeItem | 关闭后不再干涉捡起物品行为 | ⛔
onDropItem | 关闭后不再干涉丢弃物品行为 | ⚠️
onBlockInteracted | 关闭后大部分功能性方块控制失效 | ⛔
onUseFrameBlock | 关闭后对展示框控制失效 | ⛔
onSpawnProjectile | 关闭后对所有弹射物发射控制失效 | ⛔
onFireworkShootWithCrossbow | 关闭后不再干涉用弩发射烟花行为 | ⛔
onStepOnPressurePlate | 关闭后不再干涉踩压力板行为 | ⛔
onRide | 关闭后不再干涉骑乘行为 | ⛔
onWitherBossDestroy | 关闭后不再干涉凋零破坏方块 | ℹ️
onFarmLandDecay | 关闭后不再干涉耕地退化 | ℹ️
onPistonPush | 关闭后不再干涉活塞推动 | ℹ️
onFireSpread | 关闭后不再干涉火焰蔓延 | ℹ️
onChangeArmorStand | 关闭后不再干涉玩家操作盔甲架 | ⛔
onEat | 关闭后不再干涉玩家吃东西 | ⛔
onRedStoneUpdate | 关闭后不再干涉红石更新 | ⛔

> ⛔代表不建议关闭  ⚠️代表该事件不完美，可以选择关闭  ℹ️代表此事件影响原版特性，可以选择关闭