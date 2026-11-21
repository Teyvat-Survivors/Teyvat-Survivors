# 千星原生 2D 验证

`platform_probe.lua` 在千星客户端容器中使用原生图片控件呈现玩家和三个地标。键鼠 WASD、手柄左摇杆和触屏拖动驱动同一套移动输入，镜头跟随由世界坐标到画布坐标的投影实现。确认按钮测试 UI 点击及原生音效。四个图片实例在场景内复用，退出时释放。

## 编辑器搭建与导出

1. 新建超限模式关卡，设置固定人数 1，且玩家 1 隶属必要分组。在默认界面布局添加客户端控件容器，打开画布并建立铺满画布的内层容器节点 `ProbeRoot`。
2. 在客户端控件模板建立根类型为**图片**的模板，选择一个官方可用的图标，记录根模板索引。令 `ProbeRoot` 含三个直接子控件。放置可接收光标光线检测的 `ProbeTouchRegion`（光标检测区域，画布左下，活动范围足够拖拽），`ProbeConfirmButton`（预设按钮，右下，文案“确认”）及 `ProbeStatus`（文本框，顶部）。区域互不重叠。根节点显示光标并屏蔽键鼠事件穿透。
3. 在千星沙箱的客户端脚本资源管理器新建脚本映射，关联本地 `platform_probe.lua`。创建 `ProbeImagePrefab` 并填图片模板根索引。创建整数变量 `ProbeConfirmAudio` 并填已配置 2D 音效 ID，无音效时填 0。把脚本挂到 `ProbeRoot`，保存并单人试玩。
4. PC 用 WASD 检查斜向移动，按 **1** 或点确认。移动端从左下区域按住拖动，松手、拖出、切后台后返回均应停止。试按第二根手指，确认第一根手指的摇杆输入不串线。试听有 ID 的音效，记录音量开关和设备。
5. 退出并再次进入试玩，确认位置、监听和播放状态重置。记录游戏与编辑器版本、设备型号、分辨率及实际结果。用“我的奇域 → 存档 → 导出存档”保存 `.gil`，再用新槽位导入副本并复测。移动端使用创作者许可的客户端试玩入口。

官方入口和签名见 [客户端控件与客户端脚本](https://act.mihoyo.com/ys/ugc/tutorial/detail/mhbgxf0nynww)、[客户端控件 API](https://act.mihoyo.com/ys/ugc/tutorial/detail/mhtakr07vej4)、[2D 点击收集官方教程](https://act.mihoyo.com/ys/ugc/tutorial/course/detail/mh47p30a87qo)、[存档导入导出](https://act.mihoyo.com/ys/ugc/tutorial/course/detail/mhjuwpiubrh0)及[关卡人数设置](https://act.mihoyo.com/ys/ugc/tutorial/detail/mhn9vpia00qc)。

## 运行时与打包

官方 API 的客户端运行时是 Lua 5.3，裁剪了 `io`、`coroutine`、`string.dump` 和大部分 `os`、`debug`。编辑器仅打包已建立脚本映射的文件。官方文档确认可以用脚本映射 ID 查找已挂载脚本，并用 `Script:Invoke` 调用其全局函数。社区有 `require` 支持已映射路径、返回值和缓存的实测记录。当前环境未验证模块名、路径扩展名及导出再导入后的行为。单文件原生样例无需依赖这些细节。项目采用多源 Lua 模块时，可在验证映射加载后配置多文件，也可在构建期合并为一份映射文件。 [官方 API 可读原文](https://act-webstatic.mihoyo.com/ugc-tutorial/knowledge/cn/zh-cn/mhtakr07vej4/content.html) · [社区运行时观察](https://github.com/QHY8IV/miliastra-ugc/blob/e41e6b9f053fbcc078458b4927c867a04e60cc9f/references/api/runtime-contract.md)

官方说明提供了 `.gil` 导入导出流程及教学存档。实测教程 3.21 原始教学存档大小为 35,795 字节，SHA-256 为 `2bd7a28f8695bc50c6d55c748d4119adc3ae84abc04ca3f7b8cf2be91a372b93`。只读检查显示大端头部和 `0x679` 尾标，与社区容器记录相符。交付存档由项目场景在官方编辑器中导出。 [官方教学存档链接](https://act-webstatic.mihoyo.com/ugc-tutorial/course/cn/zh-cn/mh47p30a87qo/6b8bbfd8-1948-41e4-a772-8812dbb3eed6.gil) · [第三方容器验证笔记](https://github.com/QHY8IV/miliastra-ugc/blob/e41e6b9f053fbcc078458b4927c867a04e60cc9f/references/formats/container.md)

## 结果与待验项

- Lua 5.3.6 和 5.4.8 均执行了 `lua tests/platform_probe.lua`。离线测试替身覆盖控件创建、画布延迟、键盘斜向、模式转换、触点隔离、镜头投影、播放请求、停用及销毁。
- 当前 Linux 环境没有原神客户端及千星沙箱，未创建项目 `.gil`，未完成 PC 或移动端实测。仍需核对原生回调坐标、拖拽取消、音效和存档回读。
- 千星官方范围表给出运行时实体 1,000、单界面组控件 1,000、一屏可显示控件 10,000。公开 Lua API 未提供动态像素缓冲上传或批绘接口。100/300/600 档应分开记录 Lua 步长时间、绘制更新次数、设备帧耗时与移动触控响应。优先按每个可见对象一个预分配图片实现，减少屏幕外和无变化的属性写入。实际容量以性能任务的两端实测为准。 [官方范围限制](https://act.mihoyo.com/ys/ugc/tutorial/detail/mh74ae9fsg8i)
