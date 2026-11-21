# TS-1 开源源码验收

玩法范围以 2022-10-20 发售版为历史对照，版本证据由 TS-2 提供。下列实现用于比较玩法覆盖、复用条件、Lua/GIL 移植成本和可测性。项目采用原创提瓦特关卡、数值配置与有权使用的资源。本 PR 增加验收记录，参考源码和资源的实际引入量为零。

| 参考及固定提交 | 玩法覆盖与缺口 | 授权边界 |
| --- | --- | --- |
| [Pyxel Survivors](https://github.com/seanGSISG/pyxel-survivors/tree/f63b0aa4adbca8cfce9354ba48577e3822f07a31) | 参考中战斗覆盖最高。有波次、武器与进化、被动、秘法和完整计时事件。作者记录缺少 PowerUps、解锁、商店和棺材，只有五张主关卡，部分效果简化。 | [MIT 声明与例外](https://github.com/seanGSISG/pyxel-survivors/blob/f63b0aa4adbca8cfce9354ba48577e3822f07a31/README.md#credits--licensing)。`gamedata.json` 是 CC BY-NC-SA 3.0，`data.py` 也混入基于 Wiki 的数表与摆位。排除这些数据、构建器产物、地图布局及美术。 |
| [Canvas Vampire Survivors](https://github.com/ricardo-foundry/canvas-vampire-survivors/tree/e616704889e57efc9c1f49098786a95c364008d3) | 浏览器内完整的另一款幸存者类实现，有武器、波次、回放及升级。核心结构清晰、零运行时依赖，并有可执行测试。原作发售版内容有较大差异。 | [MIT 正文](https://github.com/ricardo-foundry/canvas-vampire-survivors/blob/e616704889e57efc9c1f49098786a95c364008d3/LICENSE)，Copyright (c) 2024 Survivor Game。选取算法结构和测试边界参考。本项目的资源另行验收。 |
| [vs2](https://github.com/nevatas/vs2/tree/53289c90b8b50c1956c011b2a501da6e5b6ef48a) | Lua/LÖVE 小型演示。有角色和敌人移动、碰撞、自动攻击和击杀。缺少局内成长、定时波次和长期进度。LÖVE 全局 API 与运行逻辑耦合，碰撞和敌人更新存在重复与二次复杂度。 | [Apache-2.0](https://github.com/nevatas/vs2/blob/53289c90b8b50c1956c011b2a501da6e5b6ef48a/LICENSE)。未发现独立 NOTICE 或音画资产来源记录，排除 `assets/`、`sounds/`。 |
| [SNKRX](https://github.com/a327ex/SNKRX/tree/6b93a64d694d59472375467648868ae4521d6706) | 补充比较。Lua/LÖVE 自动战斗、单位编成和商店机制，蛇形队列和分波成长，与本项目的单角色生存不同。引入 LÖVE/Steam 和物理依赖的成本高。 | [MIT 源码](https://github.com/a327ex/SNKRX/blob/6b93a64d694d59472375467648868ae4521d6706/LICENSE)。资产许可分别处理。本项目仅以其模式作比较。 |

## 模块选择

- **TS-4、TS-6、TS-7**根据 vs2 的 `player.lua` 归一化移动和最近目标、`enemy/base_enemy.lua` 追踪、`collision.lua` 交叠判定实现 Lua 模块。碰撞和伤害统一结算，固定步长和随机数由核心管理。
- **TS-8、TS-9、TS-16、TS-22**从 Pyxel 的 `world.py`、`weapons.py`、`arcanas.py` 和 `scenarios/` 提取可验证的运行顺序和测试思路。适用范围是选择、拾取、宝箱、定时事件和效果钩子。关卡、配置和显示用本项目数据及 GIL。
- **TS-10、TS-12**从 Canvas 的 `src/spatial-hash.js`、`src/pool.js`、`src/input.js` 和对应测试取候选算法与接口边界。用实际 100/300/600 档位验证是否需要分桶和对象池。`src/main.js` 使用钳制后的可变帧长，固定步长由本项目实现。
- 代码复用时逐文件记录来源提交、许可证和变更。MIT 代码再发布应保留版权及许可。Apache-2.0 代码再发布应保留许可和适用声明，并标记修改。素材按 TS-26 逐项查证。

## 固定版本运行记录

- **Pyxel** 使用 Pyxel 2.9.0。`uv run --no-project --with pyxel==2.9.0 python -m compileall -q .` 成功。以 `SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy` 启动 `main.py --pixel`，运行至预定的 5 秒停止。另在真实 Pyxel SDL 循环中用离屏探针运行 24 帧，确认进入活动战斗并生成 15 个敌人。
- **Canvas** 执行 `npm ci --no-audit --no-fund` 及 `npm run check`。lint、格式通过，未修改源码的测试在当前日期为 277/279。两项失败为基于 2026-04-25 的日期清理断言。仅在临时测试进程固定到该日 12:00 UTC 后，`node --require ../freeze-date.cjs --test test/*.test.js` 达 279/279。用 `node server.js` 和离屏 Chromium 验证 HTTP 200、开始、移动、刷怪、暂停及恢复，无页面异常。
- **vs2** 用上游 LÖVE 11.5 Linux AppImage 提取出的 `AppRun` 启动未修改的项目和临时探针。`SDL_VIDEODRIVER=offscreen ALSOFT_DRIVERS=null` 下完成 120 次更新和绘制。探针确认角色移动、敌人追踪、交叠判定和自动攻击击杀。
- **SNKRX** 用同一 LÖVE 和离屏环境尝试原始入口，启动报 `engine/external/init.lua:7: module 'luasteam' not found`。错误画面由 8 秒超时结束。上游描述的 Steam/Windows 工具链在当前 Linux 验收环境不可用。

这些是参考项目的原生运行结果。千星 Lua、资源导入和移动端验证由 TS-5、TS-11 至 TS-13 记录。
