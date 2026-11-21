---
id: TS-33
title: 实现纯 Lua 局外金币与强化账本
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:45'
updated_date: '2026-11-21 03:54'
labels: []
milestone: m-3
dependencies:
  - TS-16
ordinal: 33
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
从 TS-24 提取可独立验证的单人局外规则，为千星存档桥保留可序列化状态。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 一次入账、购买与退款、等级和余额约束、旧版本迁移均通过回归。
- [x] #2 验证跨重新加载的重复结算、失败重试及强化对实局属性的映射。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Lua 账本支持固定币价、等级上限、退款、存档版本迁移和单局编号。测试实际战斗初始属性、金币结算、保存再加载与拒绝重复结算。千星原生存储由 TS-24 验收。
<!-- SECTION:FINAL_SUMMARY:END -->
