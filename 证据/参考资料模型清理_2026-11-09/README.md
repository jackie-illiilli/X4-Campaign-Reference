# 参考资料模型清理

日期：2026-11-09。按用户要求清理舰船和装备模型，范围限定为 `GatefallChronicles/参考资料` 内四个 DLC 解包目录。

清理规则：BOR DLC、SPL DLC、TerranDLC、TimelineDLC 下的 `assets/units`，以及 `assets/props/engines`、`weaponsystems`、`surfaceelements` 中的 `.xmf`、`.jcs`、`.ani` 文件。保留 XML 定义和宏、MD、Lua、schema、文档、图片、贴图、声音，以及环境、室内、角色和其他场景资源。

没有修改游戏安装 catalog、extensions 中的原版 DLC、星门陨落或协乐园运行文件。没有另外保存一份模型备份；如以后需要研究模型几何，可从已安装 DLC 的 catalog 重新解包。保留下来的 XML 仍可供代码研究，但上述精简目录不再是一套完整的模型预览资源。

- `deleted_files.csv`：本次删除清单、原文件大小及修改时间。
- `retained_files.csv`：删除前的保留文件清单。
- `result.json`：实际删除数量、文件字节总量和保留文件核对结果；以此文件记录为准。

执行前验证所有目标的规范化绝对路径位于指定参考目录内，且目录树没有链接目录；删除后核对保留文件的存在性、大小和修改时间。释放量按文件逻辑字节数统计，不等同于文件系统报告的物理空闲空间变化。
