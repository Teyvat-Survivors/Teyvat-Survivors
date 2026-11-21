---
id: TS-4
title: 实现固定步长与角色移动
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:34'
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
- [x] #1 测试斜向归一化、坐标和时间边界、暂停及恢复。相同种子和输入产出相同状态。
- [x] #2 正常测试入口可启动一局、步进并查询状态，核心不依赖 GIL 或输入设备。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
通过正常入口启动确定性局内状态，60Hz 步进可暂停并输出状态事件。测试斜向移动、数值边界、帧时间上限、二分帧等价和种子重放。独立复核发现最小整数边界，已修复并加回归。
<!-- SECTION:FINAL_SUMMARY:END -->
