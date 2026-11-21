---
id: TS-5
title: 验证千星原生 2D 最小场景
status: In Progress
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:35'
labels: []
milestone: m-1
dependencies:
  - TS-3
ordinal: 5
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
查证平台版本、Lua/GIL API、编辑器导入与原生表现方法。最小样例包括移动、精灵或平台等效表现、摄像机、输入、声音和场景进出。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 有编辑器及权限时构建并在 PC 和移动端打开样例，记录平台版本、设备、原生 API 和复现步骤。
- [x] #2 对不可用 API 实验等效方案，记录限制。平台缺失时在任务保留阻塞与证据，继续 Lua 任务。
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
提交按官方 Lua 5.3 接口编写的原生控件探针和导入导出步骤，离线替身测试验证输入、画布生命周期、图片池、相机投影和音效调用。当前 Linux 环境缺少千星编辑器和原神客户端，PC、移动端、项目 GIL 导入和导出仍待验证。任务保持 In Progress。
<!-- SECTION:NOTES:END -->
