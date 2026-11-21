---
id: TS-40
title: 实现 Lua 解锁、收藏与成就账本
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 04:02'
updated_date: '2026-11-21 04:13'
labels: []
milestone: m-3
dependencies:
  - TS-33
  - TS-34
  - TS-36
  - TS-37
ordinal: 40
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
接通一次性达成、收藏、隐藏资格和可序列化进度。全量历史对照和千星页面由 TS-25 验收。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 测试结果触发解锁、成就和收藏，以及重复提交。
- [x] #2 保存重载后重查开放资格，验证旧存档默认。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
扩展序列化进度，加入原创成就、阶段解锁、隐藏角色及秘法旗标。真实单局结果补充收藏清单。验证旧存档加载、重复结算、拒绝无效记录和保存重载。
<!-- SECTION:FINAL_SUMMARY:END -->
