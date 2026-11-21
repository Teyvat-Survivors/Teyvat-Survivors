---
id: TS-9
title: 实现首个完整 Lua 战斗流程
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:39'
labels: []
milestone: m-1
dependencies:
  - TS-8
ordinal: 9
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
用试玩数据串联首个 30 分钟关卡、难度增长、末段威胁、玩家死亡和结果。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 固定种子分别覆盖提前阵亡、到时终局事件、终局事件击败/超时的约定与一次性结算。
- [x] #2 通过自动化加速完整时间轴，并验证重开后时间、池、随机数和候选状态重置。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
风径试炼拥有原创波次和 30 分钟终局。自动化分别验证早死、终局击败、终局超时、结算幂等、安全重开，以及 108000 步及以上的完整模拟。
<!-- SECTION:FINAL_SUMMARY:END -->
