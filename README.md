# 提瓦特幸存者 · Teyvat Survivors

面向原神「千星奇域」的纯 2D、单人 PvE 幸存者 Roguelite。目标是用 Lua 玩法核心和 GIL 原生适配实现完整的局内成长与局外进度。玩法对照版本为 2022 年 10 月 20 日发布的《吸血鬼幸存者》1.0，关卡、角色和美术采用项目原创设计及有权使用的提瓦特资源。

开发按 [Backlog.md](backlog/tasks/) 中的依赖推进。新会话从 [AGENTS.md](AGENTS.md) 进入，首项是 [TS-1 源码验收](backlog/tasks/ts-1%20-%20验收开源参考源码.md)。

## 本地验证

在仓库根目录用 Lua 5.3 运行 `lua tests/run.lua`。核心模块不依赖桌面图形、输入或文件系统。千星采用受限的 Lua 5.3 环境，编辑器打包与 GIL 适配以 TS-5 的实际实验为准。

OpenHarness 从干净工作区比对候选和目标分支。运行 `openharness --repo . verify --head HEAD --base origin/main`，需要 Lua 5.3、Node.js 和 Backlog.md 所需的 npm。
