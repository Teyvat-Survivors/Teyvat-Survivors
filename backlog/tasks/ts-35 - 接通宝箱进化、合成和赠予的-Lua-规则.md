---
id: TS-35
title: 接通宝箱进化、合成和赠予的 Lua 规则
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 04:02'
updated_date: '2026-11-21 04:04'
labels: []
milestone: m-3
dependencies:
  - TS-15
  - TS-16
ordinal: 35
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
测试正常宝箱的资格与三种原创配方。完整配方库由 TS-18 验收。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 验证材料、满槽、重复领取及掉落时机。
- [x] #2 从真实击杀到启用进化攻击及重开，测试三种配方形态。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
验证三种原创配方，按实际宝箱来源与掉落时机判定。测试材料、容量、陈旧令牌、替换后实际伤害和重开。其余配方继续 TS-18。
<!-- SECTION:FINAL_SUMMARY:END -->
