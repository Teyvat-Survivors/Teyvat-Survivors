---
id: TS-44
title: 将日常集成切换到 develop
status: In Progress
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 05:57'
updated_date: '2026-11-21 05:57'
labels: []
milestone: m-0
dependencies:
  - TS-3
ordinal: 2042
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
将 Git Flow 的日常集成目标、OpenHarness 和 CI 迁到 develop，保留 main 的生产发版职责。
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 配置和文档在 develop，既有 main 提交历史未重写。
- [ ] #2 核验 GitHub 默认 PR 目标与分支保护设置。
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
本次集成凭据的 GitHub 仓库设置更新及分支保护更新请求返回 HTTP 403。
<!-- SECTION:NOTES:END -->
