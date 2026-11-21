---
id: TS-6
title: 实现敌人追踪与基础波次
status: To Do
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
labels: []
milestone: m-1
dependencies:
  - TS-4
ordinal: 6
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
实现刷怪调度、敌人追踪、接触伤害和回收，建立可替换的敌人与波次数据接口。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 测试定时刷怪、追踪速度、伤害间隔、超出处理范围的实体及回收后的状态重置。
- [ ] #2 使用固定种子回归出生和波次时间，暴露可供负载测试读取的实体计数。
<!-- AC:END -->
