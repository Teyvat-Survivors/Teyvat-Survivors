---
id: TS-3
title: 接通 Lua 测试入口和 GitHub CI
status: In Progress
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
updated_date: '2026-11-21 03:26'
labels: []
milestone: m-0
dependencies:
  - TS-2
ordinal: 3
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
在 Lua Gameplay Core、GIL Adapter、Data 三层边界下提交最小可执行 Lua 骨架。扩展已安装 OpenHarness 的实际验收命令。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 记录 Lua 与目标运行时的兼容假设，提交能运行的 Lua 测试和命令。失败断言使本地和 CI 返回失败。
- [ ] #2 接通一条仓库 GitHub Actions 工作流并用真实 PR 核验工作流、检查名与 App 来源。配置 OpenHarness verification，运行 entry、verify、doctor。
- [ ] #3 核验 main 分支规则和 PR 审查设置。按实际权限配置所需保护，记录无法读写或未启用项。
<!-- AC:END -->
