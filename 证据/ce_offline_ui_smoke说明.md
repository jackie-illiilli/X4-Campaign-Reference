# 协乐园 0.06 离线 Lua 逻辑检查

2026-11-05：使用安装目录的 `lua51_64.dll` 创建独立 Lua 5.1 状态，加载协乐园当前四份运行 Lua；没有启动 X4、调用游戏 UI 或进行网络操作。结果：**17 项通过，0 项失败，最终 Pause 计数为 0**。

- [执行结果](ce_offline_ui_smoke_result.txt)
- [被测源码 SHA-256](ce_offline_ui_smoke_sources.json)：执行前后比较一致。
- [Lua mock 与断言](ce_offline_ui_smoke.lua)
- [PowerShell DLL 调用器](run_ce_offline_ui_smoke.ps1)

在游戏目录运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File '.\GatefallChronicles\战役制作参考\证据\run_ce_offline_ui_smoke.ps1'
```

检查执行了真实适配器及其结果/选关绘制方法，但 `ffi.C`、菜单注册、widget 链、计时队列和 Pause 使用可观测的 mock。覆盖初始化、结果两帧完成后才消费 pending、两页强制关闭不导航、同宿主切页、GameOver 宿主名称保持、官方方法委托、TabScroll 清理、启动目标 ID 和 ResultReady 不自动退出世界。

0.06 增加六项退出逻辑检查：自有按钮仅转到原版 `OptionsMenu` 的 `exit` 确认页，不直接调用或排队退出；`noreturn=false` 保留原结果宿主返回链；模拟“是”时确认执行顺序为 `exit_stage=2 → QuitModule → close OptionsMenu → Unpause → exit_stage=3`；模拟“否”时在 GameOver 状态恢复原结果宿主且 Pause 配对；官方模块退出与退出桌面维持原函数委托、不写本项目的退出诊断；普通 trace 与结果创建不覆盖上次退出阶段。

OptionsMenu 的退出与取消行为在 mock 中按已核对的基础游戏函数实现：`callbackExit()` 先退出后关闭自身，取消通过 `onCloseElement("back")` 使用 Helper 的返回链。没有加载完整 OptionsMenu，更没有执行真实的 `QuitModule`；这项检查验证当前适配器的委托、顺序、状态键和暂停配对，不能证明热退出卡死已经修复。

首轮实际发现适配器包装器只返回第一个返回值，导致 `createDescTable()` 的高度丢失并在结果布局计算时报错；修复后重新执行以上检查通过。此项属于运行 Lua 逻辑验证，比单纯语法解析多覆盖函数返回与生命周期契约。

这些检查**不验证**原生 widget 描画、控制器导航、真实 GameOver 放行行为、MD/C++ 调度、世界卸载与热退出卡死。mock 的帧创建回调由测试显式触发；Pause 计数验证的是 Lua 自己的配对，不模拟引擎的死亡强制暂停。以上仍由用户进行游戏内测试。
