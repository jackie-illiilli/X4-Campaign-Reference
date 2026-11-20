# 无 Timelines 的开场播片与字幕缩放

调研日期：2026-11-03。承接 [独立主菜单选关方案](06_独立主菜单选关与去Timelines依赖.md)。用户所说的“开场动画”分为预制影片和游戏内实时过场，下面分别说明。

2026-11-05 增补：**视频开场和真实地图加载期间播放视频是不同问题**。Timelines 加载使用基础 loading.lua 的实时字符动画及放行握手，
视频加载的额外接口/生命周期边界见 [第08篇](08_战役加载界面与视频可行性.md)。本篇的 menus 播片依据不应直接当成后台并行加载的证据。

2026-11-16 增补：协乐园0.35已采用本篇路线C，即MD `show_overlay_text` 加HUD `overlay.lua` 补丁。本篇“尚未部署”的说明属于11月3日的调研状态。当前两行大字幕使用固定72%屏宽、92%不透明度黑底；改为原生灰底配色及按文字自适应宽度的源码依据、实施位置与防遮挡注意事项见 [第13篇](13_大字幕灰色背景与文字自适应.md)，该项改造尚未实施。

## 1. 两个问题的直接结论

| 需求 | 结论 | 实现边界 |
| --- | --- | --- |
| 不安装/不启用Timelines，播放自制开场影片 | **有明确的基础游戏实现依据，可用于新系列设计** | 基础游戏已有视频cutscene、菜单渲染和停止通知；自有文件编码、资源路径、音频和跳过需原型验证 |
| 无Timelines，关卡内实时舰队/人物过场 | **可按基础Cutscene + MD实现** | 使用基础/自有或仍声明依赖的其他DLC资源，不需要Hub |
| 用普通自建菜单Lua直接放大原生对白字幕 | **不能把它当成已有的一行设置接口** | 原生字幕由HUD/core脚本绘制，与标准addon的menus环境不同 |
| 修改原生字幕的字号、背景和位置 | **源码存在明确修改点，技术上可以研究实现** | 需要HUD脚本补丁及对应装载/保护模式/兼容性验证；不是只改选关菜单的font参数 |
| 仅让新战役使用更大的剧情字幕 | **可用自有字幕显示层实现** | 可以用MD overlay，或专门研究非抢焦点的UI层；这是替代显示，不能声称改大了所有原版字幕 |

本次没有生成影片、没有安装HUD补丁、没有修改原版字幕或启动菜单。结论来自Lua/XML/XSD解析，**尚未运行验证新的播片或字幕原型**。

## 2. 源码核对范围

对当前安装900版 `08.cat / 08.dat` 中以下七份文件，与解包参考做SHA-256比较，均一致：

- `ui/addons/ego_gameoptions/gameoptions.lua`
- `ui/addons/ego_movie/movie.lua`
- `ui/core/lua/subchannelbar.lua`
- `ui/core/lua/overlay.lua`
- `ui/core/addon.xsd`
- `libraries/common.xsd`
- `libraries/md.xsd`

另外直接从当前catalog读取了 `cutscenes/credits_movie.xml`、`cutscenes/gamestart_1.xml` 和 `cutscenes/cutscenes.xsd`。两份视频cutscene原样与校验信息保存在 [证据记录](证据/media_subtitle_source_audit.json)。该记录确认源码来源，不表示调用链已经在本MOD中跑通。

## 3. 开场影片：基础游戏已经在用

### 3.1 视频文件通过Cutscene XML引用

当前catalog中的 `gamestart_1.xml` 有如下关键结构：

```xml
<director key="gamestart_1" />
<!-- environments 等结构省略 -->
<shot name="Movie1" environment="scenezone" duration="auto">
  <video name="videos/gamestart_1" />
  <camera_follow reference="playership" orient_to="object" interpolation="smooth" />
</shot>
```

`credits_movie.xml` 同样通过 `<video name="videos/credits"/>` 播片。安装根目录实际存在 `videos/gamestart_1.mkv`、`videos/credits.mkv`。XSD的 `video` 元素要求 `name`，官方例子省略文件扩展名；shot使用 `duration="auto"`，不需要把影片长度硬写成若干分钟delay。

这条资源链属于基础游戏，与Timelines Hub、场景成绩和该DLC的安装没有结构上的必然关系。自制影片应放在自有扩展内，注册独立cutscene key，按资源路径指向自己的影片。示意名字可为 `next_campaign_intro`，影片引用可考察 `extensions/next_campaign/videos/intro`，但**扩展路径解析和打包装载必须用样片验证**，不能因字符串符合XSD就认定资源可播放。

上面是结构摘录，不是可直接投放的完整cutscene。官方文件还含environment、presentation和actions等结构；其环境/相机引用也不能不加核对就从主菜单复用到任意关卡。

### 3.2 Lua如何把影片显示出来

[gameoptions.lua](../参考资料/基础游戏/ui/addons/ego_gameoptions/gameoptions.lua) 展示了完整的主要部件：

1. `displayCredits()` 创建覆盖整个视口的frame，并调用 `addRenderTarget`。
2. `viewCreated()` 取得本次创建的render target。
3. `onUpdate()` 调用 `CreateCutsceneDescriptor("credits_movie", {})`，再通过 `StartCutscene(descriptor, GetRenderTargetTexture(target))` 播放。
4. `NotifyOnCutsceneStopped` 与 `cutsceneStopped` 通知回调处理结束。
5. `StopCutscene`、`ReleaseCutsceneDescriptor` 和菜单cleanup负责退出/释放，并恢复主菜单背景相机/音乐。

新系列可依这个模式制作“全屏片头页”，然后根据入口意图：

```text
新系列入口 → 首次片头 / 手动重看片头 → 本系列选关页
选择关卡 → 该关片头（可选） → NewGame(关卡)
```

“首次播放”与“已观看”使用本系列状态，不写Timelines进度。关卡片头播放完后再NewGame最容易让玩家明确理解流程，但这不表示影片播放时关卡已经在后台加载；是否后台加载是另一项工作，不能由存在render target推导出来。

原版新游戏列表也用 `gamestart.cutscene` 显示预览：换选项时会停止旧视频、结束旁白，并在切回条目时重新开始。**预览是选中即播，不是点击开始后的强制剧情片头。** 想做片头时应建立自己的启动状态机，不只给gamestart加一个cutscene字段。

### 3.3 不直接照抄MovieMenu

基础游戏另有 [ego_movie/movie.lua](../参考资料/基础游戏/ui/addons/ego_movie/movie.lua)，它监听 `showDetailmonitorCutscene`，依赖引擎给出的detailmonitor cutscene ID，再取得key并播放。它并非简单的“传一个文件路径即可打开”的现成通用电影菜单。

该源码的 `onShowMenu()` 中还有 `fFrame:addTable(...)`，而前面创建的局部变量名是 `frame`。本次未证明此路径的实际运行情况；不能把原文件名叫MovieMenu当成已验收样板。**优先参考当前主菜单实际使用的credits/开局预览链**，自行正确管理render target与生命周期。

### 3.4 关卡已经加载后的播放

关卡内可用基础MD接口 `play_cutscene` 调用自己的视频cutscene，或制作实时场景cutscene。`cinematicmode`、`letterbox`、`abortable`、`rendertarget` 等参数在基础 [common.xsd](../参考资料/基础游戏/libraries/common.xsd) 中定义。

基础MD的 `event_cutscene_stopped` 还定义了：param是key、param2是ID、param3为是否被中止；主动stop、超时或Esc都可能属于中止。可以据此区分自然结束与跳过，不应让两条回调各自启动一次任务。

如果在世界内播放，MD还要管理：玩家/任务对象安全、AI是否继续战斗、操作权、片头期间目标是否计时、结束后是否恢复。片头本身不需要Timelines，但一艘仅Timelines提供的剧情舰仍然需要该DLC。

## 4. 长影片的声音、字幕与退出

推荐按影片/过场真实结束事件推进，固定时长只作为异常watchdog。自然结束、点击跳过、Esc、文件打不开、切换菜单、UI重载都汇合到一个只运行一次的Resolve；根据该状态决定开始关卡、回选关或提示资源失败。

播放时保存并处理主菜单BGM；有配乐的片头不能叠着主菜单音乐。停止后清理视频、旁白序列和render target，恢复背景相机和音量。原版 `onCutsceneStopped` 有idle循环重播逻辑，新片头不能误沿用该分支变成无限循环。

对声音可先比较两种制作路径：

- **成片自带声音**：更利于片内同步，语言版可能需要分别输出影片；实际音轨支持需样片验证。
- **视频与旁白分开**：原版开局预览会调用 `StartVoiceSequence2`，说明有分离旁白的组织方式；但跳过/暂停时两者必须共同管理，不能认为它们自动成为同一播放器。

不能把此前用于BGM计时的无声voice sequence当成整段影片的播放结束证明；影片结束由相应cutscene事件决定。

当前实例证明的是MKV资源与video节点的使用，**不证明任意MP4/MKV编码、分辨率、音轨或外挂SRT都被支持**。新样片应优先贴近原版资源格式再试，不编造 `PlayMovie("intro.mp4")` 这样的API。

若字幕已经烧录到画面里，后面放大原版对白字幕不会改变这部分文字；要大字就重新输出成片，或另做经过时间同步的字幕层。若想在影片上放UI字幕，还须验证渲染层级、暂停、长宽比和跳过；本次没有确认自动读取外挂字幕文件的接口。

## 5. 原生对白字幕到底在哪里画

具体位置：[ui/core/lua/subchannelbar.lua](../参考资料/基础游戏/ui/core/lua/subchannelbar.lua)。它不是 `menu_scenario_selection.lua` 或任务MD的一部分。

主要调用链：

```text
引擎语音输出
→ NotifyVoiceOutput / voiceOutput
→ onVoiceOutput(_, text)
→ activateBar()
→ 写入原生Text元素、计算文字宽度和背景、显示字幕条
```

源码中 `onVoiceOutput` 收到的是已经生成的显示文字，不是一个包含actor/page/line/配音状态的完整剧情表。`initScale()` 则计算：

```lua
local defaultFontSize = getAttribute(private.textElement, "size")
private.fontSize = defaultFontSize * private.uiScale * invertScaling
setAttribute(private.textElement, "size", private.fontSize)
```

同时计算背景高度、跳过提示字号。`activateBar()` 使用 `C.GetTextWidth(private.text, config.font, private.fontSize)` 调整背景宽度，并设置字幕条的Y位置。

**所以字体尺寸不是不可修改的硬编码引擎黑箱：Lua层确实存在字号与背景控制点。** 例如试验性增加一个倍率可以在现有计算结果上乘1.5，并相应调整背景高度/位置；该数字只是测试建议，并非已经验证的最佳值。

不能每次刷新都读取“已经放大后的size”再乘一次，否则UI重建/刷新可能反复放大。实现需保留基准size、只应用一次倍率，并在分辨率/UI缩放变化时正确重算。

## 6. 为什么自建菜单Lua不能直接接管原生字幕

第06篇使用的普通扩展 `ui.xml` 注册到 **menus** 环境。[addon.xsd](../参考资料/基础游戏/ui/core/addon.xsd) 只枚举了menus；原生字幕脚本则以HUD presentation的 `self:onInitialize()`、Text元素和UIContract运行。

二者不能按“Lua都是Lua，因此可以访问同一个private.textElement”理解。`private`、`config` 本身也是该脚本局部数据。给选关页的 `Helper.createText` 增加fontsize，只改变那一页，既不修改原生字幕，也不能让HUD中的voiceOutput监听自动出现在menus的全局RegisterEvent里。

Egosoft Wiki的 [UI与MD通信说明](https://wiki.egosoft.com/X4%20Foundations%20Wiki/Modding%20Support/UI%20Modding%20support/Talking%20with%20MD%20and%20AI%20scripts/?language=en) 也区分menus与HUD的可用通信函数。应按当前环境核实API，不能把MD→menus的 `raise_lua_event` 当成已经支持修改HUD字号的桥。

因此“我们自己的Lua能做”要明确是：**我们编写并正确装载的HUD补丁，或自有字幕系统**。它不是现有前端Lua天然附送的一项能力。

### 字幕开关不是字幕字号API

[gameoptions.lua](../参考资料/基础游戏/ui/addons/ego_gameoptions/gameoptions.lua) 中：

- `valueGameSubtitles()` 只提供auto / true / false。
- `callbackGameSubtitles()` 调用 `SetSubtitleOption(option)`。

本次未找到一个现成的 `SetSubtitleFontSize()` 注册接口。系统UI缩放参与原生HUD的计算，但这与“只放大字幕、其他菜单维持原大小”不是一回事，实际缩放表现也需要测试。

## 7. 字幕改造的三条路线

| 路线 | 能得到什么 | 成本与限制 |
| --- | --- | --- |
| A：使用原版UI缩放 | 不做字幕补丁，先评估可读性改善 | 整体UI会受影响，不能承诺只改字幕 |
| B：原生HUD字幕补丁 | 保留引擎字幕时序、名字及所有正常发言来源，调整字号/背景/位置 | 需要正确替换/装载core脚本，处理保护模式、打包和与其他HUD补丁的冲突 |
| C：本系列自有大字幕 | 自定字体、字号、行数、边距、背景和显示规则 | 需自己同步对白/影片生命周期，处理原字幕重叠；不是修改所有原版字幕 |

若用户要求明确是“将原有字幕放大”，B最贴切。可先作为独立可选的HUD补丁验证，避免前端与全局HUD改造绑定在一个难以排错的模块里。

当前catalog同时有 `subchannelbar.lua` 与 `subchannelbar.xpl`。新增菜单addon可用 `.lua`，**不代表把另一个同名lua丢进扩展就必然覆盖HUD实际装载的脚本**。HUD补丁需验证替换catalog/实际加载路径、源码与xpl优先级以及当前保护模式；本次没有完成这部分部署，也未要求更改用户的保护设置。

如果希望倍率只在新系列生效，或在设置页动态调节，还需设计menus/MD/HUD之间经验证的配置通道。不能因为可固定乘1.5，就宣称动态滑条和按关卡自动恢复也已经可用。全局生效还是仅战役生效应作为明确选项。

### 放大字体时必须一起检查

- 背景高度和宽度、屏幕安全边距、位置是否与HUD/黑边重叠。
- 中文长句、英文长句、说话人名字和特殊图标的宽度测量。
- 该脚本没有显式的长句 `GetTextLines` 自动排版流程；放大不能保证自动出现合适的两行字幕，可能需要调节布局或在剧情稿中合理拆句。
- HUD presentation自身的文本边界；如字体仍被裁切，可能需要进一步调整界面布局资源，不能只改字号。
- UI重载、分辨率切换、超宽屏、窗口化与用户UI缩放组合。
- 原代码针对空字符串与下一句在同帧到达的情况做了“延迟到onUpdate再隐藏”的保护，不能在改造时删掉，造成新一句刚显示就被旧清理事件藏掉。

## 8. 自有大字幕的低侵入候选

若只需要本系列剧情大字幕，可以先考察基础MD的 `show_overlay_text`，未必需要新写一套Lua播放器。它的XSD明确支持 `fontsize`、`wordwrap`、相对宽度/位置、文本颜色、背景和淡入淡出；[overlay.lua](../参考资料/基础游戏/ui/core/lua/overlay.lua) 读取OverlayCellInfo3，其中就有fontsize字段。

示意片段，文本页与字号为占位配置：

```xml
<show_overlay_text relwidth="0.8" reloffsetx="0.1" reloffsety="0.08">
  <row>
    <col idx="1" text="{898101,501}" fontsize="32"
         wordwrap="true" halign="center" />
  </row>
</show_overlay_text>
```

在真正的对白结束/中止/场景退出时 `remove_overlay_text`。字号32仍需按游戏UI单位和屏幕实测，不视为固定32像素。原生语音继续用speak/UseCase，overlay只替代显示，不参与音乐计时监听。

这条方案需要注意：

1. **避免双字幕。** speak仍可能显示原生字幕。普通speak没有经本次确认的 `nosubtitles` 属性，不能随手补一个不存在的参数。
2. `SetSubtitleOption(false)` 是全局选项。若采用临时切换，需保存用户原先的auto/true/false并在所有退出/恢复路径归还，而且会影响期间其他NPC字幕。不能悄悄永久关闭用户字幕。
3. 不用极低语音优先级隐藏正常配音；音乐计时采用的-100策略不能直接用于对白，否则声音可能无法开始。
4. overlay本身可能被其他剧情/教学占用，不能把它当作支持无限独立字幕频道的窗口系统。应管理本系列显示的拥有者与清理时机。
5. 主菜单内没有正在运行的本关MD，影片在主菜单播放时不能直接套用这段关卡内overlay；那里需要前端自己的显示层。其与视频画面的合成层级仍要测试。

若选择自己写menus侧Lua字幕，MD可通过自有事件通知句子开始/结束，并用适当的数据交换方式送文本。不要假定普通菜单frame不影响飞行输入或能同时覆盖任意菜单；非抢焦点、HUD隐藏和过场层级都应作为原型验收项。

## 9. 对新系列的建议

第一阶段分开验证，避免把入口、视频解码和字幕布局同时调试：

1. **无DLC开场样片**：自有前端播放约10–20秒自制测试视频，自然结束/跳过各只进入一次选关页或关卡。测试音频、黑边、失败回退、重播与UI清理。
2. **原生字幕放大样片**：两名角色各一句较长中文/英文，先做一个固定倍率的HUD补丁，验证字号、背景、裁切、中文字体及退出恢复；不先承诺动态设置或仅战役生效。
3. **替代方案比较**：相同台词用overlay大字显示，评估是否值得为仅本系列的字幕需求承担全局HUD补丁成本。

若主打电影化片头：用自制视频 + 自有播放页；若主打在实际战场中无缝接操作：使用基础MD/Cutscene实时演出。两者都能与无Hub独立战役架构结合；字幕方案再按是否必须保留原生字幕来选择。

测试通过标准包括：Timelines资源不可用、全新主菜单、自然结束、Esc/跳过、重复播放、缺文件、暂停/恢复、UI重载、不同分辨率、真实配音中断，以及正常游玩沙盒时不误触发本系列的播片或字幕逻辑。
