# 战役加载背景图与 BGM

2026-11-10验收更新：用户确认协乐园0.13“一切顺利”，当前宣传加载图、Solara加载音乐及三段影片到结算的目标流程已通过。0.07—0.12曾遇到音乐继承、叠音、中场黑屏及片尾阻塞，历史见[测试说明](../../extensions/concordant_eden/MEDIA_TEST.md)，最终复用方法见[第12篇](12_协乐园媒体流程验收与复用.md)。下文标为初次调研的建议不覆盖最终实现状态。

初次调研日期：2026-11-09，基于本地基础游戏与Timelines源码。本文于2026-11-10补充实际方案和用户验收；游戏测试由用户完成。

## 1. 可行性结论

| 目标 | 判断与修改入口 |
| --- | --- |
| 普通加载页为每关指定一张封面 | gamestart 的 loadingscreen.ref + icons.xml 自有图标；协乐园专用宣传图已验收 |
| 向全游戏随机加载图池添加图片 | icons.xml 的 loadingscreen 标签；会影响其他开局和读档，不适合只服务协乐园 |
| 保留 Timelines 字符动画，同时加自有背景图 | 单独设置 ref 不够；需修改核心 loading.lua / presentation 的显示分支与层次 |
| 改主菜单背景场景的音乐 | startmenu.xml 的 scene.music 指向 sound_library.xml 音轨；不是独立的每关加载音乐配置 |
| 加入类似 Timelines 的一次转场音效 | 原版使用 PlaySound；可建立自有音效 ID，首次进入与重试共用启动入口 |
| 整个真实加载期间循环自有 BGM，完成后停止 | 当前采用StartPlayingSound / StopPlayingSound句柄接管与加载期间菜单停音控制，主流程已验收；极端加载和异常取消未逐项测试 |
| 战役进入后播放任务 BGM | 原生 MD play_music / stop_music 已有成熟范例；不能据此推断加载期间也能由新世界 MD 调度 |

当前基线已完成封面与加载BGM闭环。移植到其他开局或游戏版本时仍需检查完整生命周期，不能仅凭播放接口返回成功认定整段声音交接正确。

## 2. 普通加载背景：按关卡配置

[gamestarts.xsd](../参考资料/基础游戏/libraries/gamestarts.xsd) 585–627 行明确允许：

```xml
<!-- 放在自己的 gamestart 内，type 之后、location 之前。当前已使用此机制。 -->
<loadingscreen ref="ce_loading_test_01" text="{897601,100}" length="60" />
```

- ref 是图标名，不是直接填写 JPG、PNG 或视频路径。
- text 是这张图上的说明；可以留空。
- length 控制首次图片的停留/切换时间，不是加载最短时长，也不会保证用户一定看满 60 秒。
- gamestart自身的image是选关展示图，不等于loadingscreen.ref。初次调研时协乐园只有image；当前已另外指定ce_loading_test_01加载图。

在扩展 libraries/icons.xml 中添加一个独有 ID：

```xml
<diff>
  <add sel="/icons">
    <icon name="ce_loading_test_01"
          texture="extensions\concordant_eden\assets\textures\ui\loading\test_01.tga"
          width="1920" height="1080" />
  </add>
</diff>
```

这是沿用原版 TGA 图标路径形式的素材方案，图片需另行制作并确认实际资源装载。1920×1080 对齐原版加载图比例，不代表只能用这一分辨率。源美术为 PNG/JPG 时应转换为游戏支持的纹理资源，而不是仅改扩展名。

**不要给这张关卡专用图添加 tags="loadingscreen"。**
[icons.xml](../参考资料/基础游戏/libraries/icons.xml) 776 行定义全局 loading_* 图池；[loading.lua](../参考资料/基础游戏/ui/core/lua/loading.lua) 310 行附近以 GetIcons("loadingscreen") 收集随机图。
独有 ID 由本关 ref 直接引用，可以避免进入整个游戏的随机池。每关可以设置不同 ref。

显示链为 GetLoadingInfo → initialScreen → switchScreenshot → SetIcon。普通模式先进入 proverb 幻灯片，离开该段后才设置自有初始图；所以仅改 XML 不会保证从加载第一帧起就覆盖所有文字/底色/界面元素。图像仍受原版截图区域尺寸与布局限制。

### length=0 的源码矛盾

XSD 写明 0 表示只显示该图，但本次阅读的 9.00 loading.lua 存在静态疑点：

1. 274–277 行在 initialLoadingScreenTime 为 0 时保留 initialScreenTime=nil，注释称无限期显示。
2. 378 行把它传给 switchScreenshot。
3. 553 行却直接执行 getElapsedTime() + time，没有处理 nil。

因此不能把 length="0" 当作本版已验证的固定封面方案。引擎是否对该值作了预处理尚未确认；初次探针用正数，比如 60 秒。超过该时间，普通模式会切回全局随机图片。
若需要严格固定到加载结束，应在仅针对自有关卡的核心补丁中正确处理 nil/停用随机切换，而不是宣称大数时长就是无限期。

## 3. Timelines 字符加载为什么不能直接套封面

loading.lua 在 scenarioMode 分支设置 nextScreen=nil、displayingProverb=false，切到 loop / loop_reverse 幻灯片；onUpdate 也不执行普通 updateScreenshots 路线。
因此即使给同一个 gamestart 同时填 ref、text/info，也不能期待自动得到“自有插画 + 字符动画”。

要组合两者，需要核心加载补丁主动设图，并确认截图图层在特殊幻灯片中的可见性、位置和文字前后关系。背景颜色及粒子另由 loadingscreen_background、loadingscreen_scenario_dust 等颜色项控制；直接改全局颜色表也会影响原版其他加载界面。

建议以自有 initialLoadingScreen 的 ce_loading_ 前缀作为候选范围标识：loading.lua 已取得此信息，不必在新世界尚未创建时依赖 player.ship。该标识能否在全部切换路径可靠传入仍需验证。仅在“当前是协乐园指定加载”时应用补丁；其他路径执行原有逻辑。

## 4. 先区分三种音频

### 主菜单音乐

基础 [startmenu.xml](../参考资料/基础游戏/libraries/startmenu.xml) 的 scene 有 music 属性。例如 music_menu_main_music；对应 [sound_library.xml](../参考资料/基础游戏/libraries/sound_library.xml) 7388 行起的 sample、volume、fade。
Timelines 的 [startmenu.xml](../参考资料/TimelineDLC/libraries/startmenu.xml) 则引用 music_menu_main_tl_music，音轨来自它自己的 DLC。

这证明主菜单场景可以指定音乐，但不是给每个 gamestart 的加载过程配置 BGM。改共享声音 ID 或 scene，会影响相应主菜单场景；主菜单音乐是否延续到本次加载、在哪个阶段被替换，不能仅凭配置推断。新战役只在本系列使用的加载 BGM不宜通过替换共享菜单音乐来实现。

[Egosoft Wiki 的音乐替换指南](https://wiki.egosoft.com/X4%20Foundations%20Wiki/Modding%20Support/ScriptingMD/Community%20Guides/Changing%20Game%20Music/?language=en)说明了同路径 OGG 替换办法；那是资源替换，不是按关卡调度接口。

### Timelines 转场音效

基础 [menu_scenario_selection.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitor/menu_scenario_selection.lua) 765–767 行，在 EnableScenarioLoading 后调用：

```lua
PlaySound("hub_matrix_transition")
```

[menu_scenario_debriefing.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitor/menu_scenario_debriefing.lua) 的重试和回 Hub 路径也调用它。
Timelines [sound_library.xml](../参考资料/TimelineDLC/libraries/sound_library.xml) 372 行把它定义成 repeat="1" 的转场效果，并引用 DLC 的 sfx/ambience 资源。它不是一首按加载进度循环的 BGM；本地 loading.lua 本身未见音乐启动/停止调用。

协乐园可以用自有音频、自有声音 ID 仿照这个入口。不要直接借用 hub_matrix_transition 的资源作为“去 DLC 依赖”的实现。单次 PlaySound 无可管理返回句柄，不能把长曲硬塞进去就认为解决了进关时停止问题。

### 进入战役后的音乐

[common.xsd](../参考资料/基础游戏/libraries/common.xsd) 38400 行的 play_music 会打断正常音乐调度；负 repeat 的曲目须配 loop="true"，并由 stop_music 结束。Timelines 的 lib_scenario.xml 也使用此机制播放结算音乐。
这是世界内的 MD 能力。新战役 Setup.Start 触发的音乐属于战役已启动后的部分，不是覆盖此前加载阶段的办法；旧世界 MD 的计时与音频状态也不能假定会跨 NewGame 保持。

## 5. 自有加载 BGM 的实现与早期探针

### 当前已验收方案

在菜单端释放仍登记的旧声音，预先启动ce_loading_music_01并保存句柄；核心loading识别本关图标后接管该句柄，没有句柄时才兜底启动。开始新游戏前再次停止主菜单音乐；本系列加载期间每0.5秒继续停止可能重启的菜单音乐。gameLoadingDone撤销控制并停止自定义曲目，WorldReady兜底清理。既不重复启动同一曲目，也不修改全局音量。

仅调用一次StopStartMenuBGMusic曾仍出现菜单音乐与Solara叠音；增加加载期控制后，用户在0.12反馈其他问题已修复，随后确认0.13全流程顺利。`loading_menu_stop=guard:ok`本身仅证明调用返回，实际效果由用户试听确认。运行代码见[loading.lua](../../extensions/concordant_eden/source/ui/core/lua/loading.lua)和[campaign_integration.lua](../../extensions/concordant_eden/ui/campaign_integration.lua)。

### 初次调研的接口依据与设计边界

原版 [menu_map.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitor/menu_map.lua) 6108 行启动环境音，2206 行起清理句柄：

```lua
local handle = StartPlayingSound("ce_loading_music_01")
-- 在实际结束时调用，以下只表示配对关系，不是完整可安装实现。
StopPlayingSound(handle)
```

[Lua API 实测参考](https://chemodun.github.io/x4/modding-support/ui-modding/lua-globals/)记录这两个接口在 9.00 的 menus/addons 与 core 环境均存在。它支持在核心加载脚本里做声音原型的判断，但没有证明加载期间的音频连续性。

建议使用自有 OGG，注册为非 3D 循环声音；volume 可指定 Music 类别（见 sound_library.xsd 的 volume 类型），具体混音是否如预期仍待试听。例如：

```xml
<sound id="ce_loading_music_01" repeat="-1" is3d="0" preload="0">
  <sample start="extensions\concordant_eden\music\loading_01" />
  <volume start="0.4" category="Music" />
</sound>
```

这个节点应通过 sound_library.xml 的 diff 添加；实际文件为 music/loading_01.ogg。声明 Music 类别不等于自动获得 MD play_music 的“暂停原音乐调度”语义，两首声音是否叠加必须单独检查。

最值得试的实现位置是**加载 presentation 自身**：识别自有加载标识后启动，保存句柄；正常加载在 gameLoadingDone 附近停止，Timelines 正向加载则可保留至打字机尾段结束、ContinueGameStart 之前再停止。异常退出/取消也应清理且不得重复启动。
当前 loading.lua 没有现成的自有音频销毁清理回调实现，不能凭空假设添加一个任意名字的 onDestroy 就会被引擎调用；生命周期收尾需在原型阶段确认。

在选关按钮回调里预先 StartPlayingSound 也可以做较小探针，但旧菜单会 cleanup，世界会 NewGame；音频可能被截断或句柄失效，不能默认把这个更短的实现当作最终方案。

以下作为移植或扩大发布时的补充检查；本次用户整体确认不表示这些边界全部逐项测试：

1. 首次从主菜单加载、世界内重试，两条路径是否都能持续播到加载完成。
2. 原菜单/世界音乐是否叠加，是否遵守音乐音量、静音设置。
3. 加载很快/很慢、完成/失败/返回时是否正确停音，无残留或重复播放。

音频实现应独立于计分和已验证的返回主菜单流程。声音失败不能阻止 ContinueGameStart，不应通过延长关卡加载握手等待一首曲子播完。

## 6. 后续制作顺序与打包注意

先用“普通加载页 + 每关专用封面”确认图标和 ref 链；再单独试自有加载循环音；最后才组合 Timelines 字符、插画和音乐。
这条路线使用基础游戏机制和自有素材，设计上不需要 Timelines 音频资源，但未安装/未启用 Timelines 的整体行为仍由后续原型验证。

协乐园当前tools/build_catalog.ps1已包含music/、cutscenes/、assets/等目录，并编译、生成subst_v900.cat/dat中的核心loading.xpl。三个MKV保持扩展根目录松散文件。后续新增sfx或其他目录时仍须检查白名单，再重建目录包；只写XML而漏掉媒体文件不足以交付。

初次调研没有创建资源；后续原型已部署官方宣传图、三段影片和用户指定音乐，并由用户确认0.13主流程可用。
