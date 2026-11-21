---
id: TS-5
title: 验证千星原生 2D 最小场景
status: To Do
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
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
- [ ] #2 对不可用 API 实验等效方案，记录限制。平台缺失时在任务保留阻塞与证据，继续 Lua 任务。
<!-- AC:END -->
