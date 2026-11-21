---
id: TS-33
title: 实现纯 Lua 局外金币与强化账本
status: To Do
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:45'
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
- [ ] #1 一次入账、购买与退款、等级和余额约束、旧版本迁移均通过回归。
- [ ] #2 验证跨重新加载的重复结算、失败重试及强化对实局属性的映射。
<!-- AC:END -->
