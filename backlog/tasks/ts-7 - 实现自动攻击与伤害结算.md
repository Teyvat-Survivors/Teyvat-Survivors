---
id: TS-7
title: 实现自动攻击与伤害结算
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:37'
labels: []
milestone: m-1
dependencies:
  - TS-6
ordinal: 7
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
加入自动索敌、投射物、命中与基础伤害结算，让战斗能产生击杀。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 测试冷却、方向、伤害、穿透次数、重叠实体命中去重、击杀只结算一次和帧率独立。
- [x] #2 通过正常 Lua 入口演示玩家移动、自动攻击、敌人死亡和安全回收。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
接通近敌索敌、冷却、扫掠碰撞、穿透、伤害和回收。用同一局比较整步和半步输入，验证自然出怪、自动攻击、死亡和生命周期相同。
<!-- SECTION:FINAL_SUMMARY:END -->
