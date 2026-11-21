---
id: TS-4
title: 实现固定步长与角色移动
status: To Do
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
labels: []
milestone: m-1
dependencies:
  - TS-3
ordinal: 4
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
建立可种子复现、脱离 GIL 执行的 Lua 局内状态，加入移动、暂停和基础事件输出。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 测试斜向归一化、坐标和时间边界、暂停及恢复。相同种子和输入产出相同状态。
- [ ] #2 正常测试入口可启动一局、步进并查询状态，核心不依赖 GIL 或输入设备。
<!-- AC:END -->
