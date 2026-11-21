---
id: TS-38
title: 交付千星 Lua 战斗接入脚本与打包
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 04:02'
updated_date: '2026-11-21 04:09'
labels: []
milestone: m-3
dependencies:
  - TS-16
  - TS-34
  - TS-36
ordinal: 38
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
按官方千星回调编写场景接入脚本和可映射单文件。设备验收由 TS-12/13 继续。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Lua 5.3 编译和离线接口替身覆盖选角、战斗、升级、终局与重开。
- [x] #2 提供确定性单文件打包、编辑器资源映射和设备待验记录。
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
按官方接口连接选关、选角、移动、画布渲染、升级、宝箱、终局和重开。Lua 5.3 编译、确定性打包、离线完整流程和打包后战斗烟测均通过。项目 GIL 和两端实机由 TS-5、TS-11 至 TS-13 验收。
<!-- SECTION:FINAL_SUMMARY:END -->
