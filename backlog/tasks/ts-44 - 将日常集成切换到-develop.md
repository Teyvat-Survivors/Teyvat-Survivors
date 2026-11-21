---
id: TS-44
title: 将日常集成切换到 develop
status: Done
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 05:57'
updated_date: '2026-11-21 06:31'
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
- [x] #2 核验 GitHub 默认 PR 目标与分支保护设置。
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
本次集成凭据的 GitHub 仓库设置更新及分支保护更新请求返回 HTTP 403。
<!-- SECTION:NOTES:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
PR #38 已合入 develop。GitHub API 确认默认分支是 develop，main 的分支保护已启用，且 GitHub Actions 的 Lua and Backlog（应用 15368）是必需检查。main 仍为 dfc2924890c4e154197883f131ff705ac25e8f07。仓库管理员已从本地应用剩余设置。当前集成凭据读取完整规则仍返回 403，因此 PR 专属合并、强推及删除的选项未独立核验。
<!-- SECTION:FINAL_SUMMARY:END -->
