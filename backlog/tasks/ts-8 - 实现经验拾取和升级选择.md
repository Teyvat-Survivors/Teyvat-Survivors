---
id: TS-8
title: 实现经验拾取和升级选择
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:38'
labels: []
milestone: m-1
dependencies:
  - TS-7
ordinal: 8
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
让击杀掉落经验，等级提升暂停战斗，提供可种子重放的升级候选和武器成长。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 测试吸附与拾取、经验阈值、连续升级队列、暂停时钟、重复与无效选择以及等级上限。
- [x] #2 测试不同等级的武器属性更新能影响后续实际攻击。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
击杀生成独立经验宝石，确定性候选可逐次选择。覆盖吸附、溢出、上限、武器等级、重复令牌和选择时暂停。独立复核发现帧余量可跨过暂停边界，已修复并加回归。
<!-- SECTION:FINAL_SUMMARY:END -->
