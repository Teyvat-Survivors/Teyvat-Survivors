# 提瓦特幸存者 · Teyvat Survivors

面向原神「千星奇域」的纯 2D、单人 PvE 幸存者 Roguelite。目标是用 Lua 玩法核心和 GIL 原生适配实现完整的局内成长与局外进度。玩法对照版本为 2022 年 10 月 20 日发布的《吸血鬼幸存者》1.0，关卡、角色和美术采用项目原创设计及有权使用的提瓦特资源。

开发按 [Backlog.md](backlog/tasks/) 中的依赖推进。新会话从 [AGENTS.md](AGENTS.md) 进入领取满足依赖的最早任务。

## 本地验证

在仓库根目录用 Lua 5.3 运行 `lua tests/run.lua`。核心模块不依赖桌面图形、输入或文件系统。千星采用受限的 Lua 5.3 环境，编辑器打包与 GIL 适配以 TS-5 的实际实验为准。

OpenHarness 从干净工作区比对候选和目标分支。运行 `openharness --repo . verify --head HEAD --base origin/main`，需要 Lua 5.3、Node.js 和 Backlog.md 所需的 npm。

## Lua 单局

`game.run` 的 `Run.new(seed)` 启动风径试炼。`Run.update(run, dt, x, y)` 接收秒单位帧时和移动方向，通过固定步长推进战斗。升级时读取 `run.progress.choices`，把当次令牌和选项交给 `Run.choose`。终局结果写入 `run.result`，`Run.restart(run)` 重开。

`lua tests/run.lua` 包含固定种子加速 30 分钟的完整模拟。`lua tools/benchmark.lua` 比较 100、300、600 实例的 Lua 负载。千星原生控件探针和编辑器操作见 [千星 2D 验证](docs/platform-probe.md)，当前等待 PC 和移动端原生验收。

## 千星客户端接入

运行 `python3 tools/bundle_gil.py /path/to/teyvat-survivors.lua` 生成单文件映射脚本。按 [千星战斗接入](docs/gil-playtest.md) 搭建编辑器画布与模板。离线替身覆盖菜单、选关、选角、战斗、升级、结算和重开。正式设备验收记录由 TS-5、TS-11 至 TS-13 更新。
