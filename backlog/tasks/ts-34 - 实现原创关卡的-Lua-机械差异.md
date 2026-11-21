---
id: TS-34
title: 实现原创关卡的 Lua 机械差异
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:45'
updated_date: '2026-11-21 03:55'
labels: []
milestone: m-3
dependencies:
  - TS-20
ordinal: 34
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
从 TS-21 提取可独立验证的关卡数据、波次和场地机械。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 测试多个原创关卡的时长、边界、波次、特殊场地事件和重放。
- [x] #2 输出千星场景需映射的数据。实机导入、视觉和完整路线由 TS-21 验收。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
保留 30 分钟风径试炼，新增 8 分钟月芦滩及 6 分钟余烬峡。实现独立边界、一次性治疗点和周期危险区，验证三条固定种子完整路线。千星视觉场景和导出仍由 TS-21 验收。
<!-- SECTION:FINAL_SUMMARY:END -->
