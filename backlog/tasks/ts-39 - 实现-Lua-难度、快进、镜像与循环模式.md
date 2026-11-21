---
id: TS-39
title: 实现 Lua 难度、快进、镜像与循环模式
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 04:02'
updated_date: '2026-11-21 04:11'
labels: []
milestone: m-3
dependencies:
  - TS-34
ordinal: 39
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
验证模式对波次、时钟和结算的纯 Lua 效果。实际场景和模式解锁由 TS-23 验收。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 测试各修饰的时钟、伤害、经济及组合。
- [x] #2 固定种子验证循环重置、压力增长及退出。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
验证各模式对原始规则的独立组合。覆盖时间比例、镜像生成、风险和经济、两轮重播、增长、单调敌人 ID 和主动退休结算。遗物、界面和千星验证继续由 TS-23 负责。
<!-- SECTION:FINAL_SUMMARY:END -->
