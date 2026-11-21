# 提瓦特幸存者 · 会话入口

Backlog.md 是项目唯一的工作队列。任务、验收条件和状态都在 `backlog/`，GitHub PR 承载变更和审查。项目 Google Sheet 的 Overview 保持定稿。

## Git Flow

- 从 `develop` 创建 `feature/<任务>-<名称>`，日常开发 PR 合入 `develop`。
- 从 `develop` 创建 `release/<版本>`，发版验收后提 PR 到生产分支 `main`，将发版修正同步回 `develop`。
- 从 `main` 创建 `hotfix/<名称>`，生产修复经 PR 合入 `main` 后同步回 `develop`。

## 领取一项任务

1. 从最新 `origin/develop` 开始。运行 `npx --yes backlog.md@1.53.0 task list -s "To Do" --plain`，用 `npx --yes backlog.md@1.53.0 task view TS-1 --plain` 查看任务、依赖和验收。用 `npx --yes backlog.md@1.53.0 milestone list` 查看里程碑。
2. 按编号领最早可做的一项。先核对它的前置均为 `Done`，并检查 GitHub 是否已有关联分支或 PR。初始从 **TS-1 源码验收**开始。遇到千星工具或权限阻塞，把缺口写入任务实施备注，继续满足依赖的 Lua 工作。
3. 运行 `openharness --repo . entry`。用 `git worktree add -b feature/ts-1-source-audit ../ts-1-source-audit origin/develop` 创建隔离工作区，再在其中运行 `openharness --repo . workspace --task TS-1 --change source-audit --bind`，将示例编号和变更名替换为本次任务。默认执行者为已核验的 GitHub 登录 `FurinyaDev`。换人时先通过仓库 Git 变更更新任务的 assignee 和 OpenHarness 映射。
4. 在工作区把任务改为 `In Progress`，逐条验收，记录实际运行结果和变更路径。一项任务对应一个可审查的 PR，正文加一行 `Work-Item: TS-1`（替换为实际编号）。验收全部通过后在对应 PR 勾选条件并设置 `Done`，合并后才可作为后续任务的已完成依赖。

## 工具与验收

- Backlog.md 使用 1.53.0。用同一 CLI 或其界面编辑任务。保持顶层标量和字符串列表的格式。长链接等 Markdown 引用放入任务正文，OpenHarness 的 Backlog 读取器只支持约定的 YAML 子集。
- OpenHarness 使用支持 cooperative 的固定提交 `aebb0c2255a5df275491009285c1a23d03f90771`（内部版本 0.3.0）。可在仓库外的虚拟环境安装 `python -m pip install 'git+https://github.com/FurinyaDev/OpenHarness.git@aebb0c2255a5df275491009285c1a23d03f90771'`。要求 Python 3.11+、Git 2.38+、已认证的 GitHub CLI。详见 [OpenHarness 入口](.harness/AGENT.md)。
- 提交后在干净工作区运行 `openharness --repo . verify --head HEAD --base origin/develop`。候选验收运行 Lua 5.3 测试和 Backlog CLI。GitHub Actions 检查名为 `Lua and Backlog`。用 `doctor` 观察真实状态，千星测试只记录实际设备或编辑器的结果。
