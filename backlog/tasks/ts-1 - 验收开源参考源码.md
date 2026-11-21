---
id: TS-1
title: 验收开源参考源码
status: To Do
assignee:
  - '@FurinyaDev'
created_date: '2026-11-21 03:03'
labels: []
milestone: m-0
dependencies: []
ordinal: 1
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
交付仓库内源码与授权记录。先依据覆盖度、可复用权利、Lua/GIL 移植成本、性能和可测性比较候选，再按模块选择参考。

- [参考资料 1](https://github.com/seanGSISG/pyxel-survivors/commit/f63b0aa4adbca8cfce9354ba48577e3822f07a31)
- [参考资料 2](https://github.com/ricardo-foundry/canvas-vampire-survivors/commit/e616704889e57efc9c1f49098786a95c364008d3)
- [参考资料 3](https://github.com/nevatas/vs2/commit/53289c90b8b50c1956c011b2a501da6e5b6ef48a)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 检出至少三项已列候选的具体提交，记录许可证正文、运行入口、启动或测试命令及实际结果。再检索其他候选并记录比较结果。
- [ ] #2 逐项说明可复用模块、缺口和署名义务。查证 Pyxel 的 gamedata.json 独立授权，排除非商业数据、未经授权的资产和商业源码。
- [ ] #3 对选中的模块写明对应后续任务、来源路径和复用方式。
<!-- AC:END -->
