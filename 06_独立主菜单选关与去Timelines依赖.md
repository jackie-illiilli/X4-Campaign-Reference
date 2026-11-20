# 独立主菜单选关与去 Timelines 依赖

调研日期：2026-10-30。目标体验：**启动 X4 → 点击新战役入口 → 直接进入本 MOD 选关页 → 加载关卡 → 结算/重试/返回选关**，全程不进入 Timelines Hub。

2026-11-05 后续：上述普通独立开局路线已实现于 [协乐园0.06原型](../../extensions/concordant_eden/README.md)，
用户确认独立入口、原版结构选关/结算、两船战斗、五星记录、重试及原版确认页返回主菜单均可用。
本原型需要Terran资源；尚不能把用户当前安装环境的通过等同于未启用/未安装Timelines的专门验收。
下文“尚未实现/未安装”描述的是10月30日调研当时的状态，当前原型与加载界面研究分别见其README和第08篇。

## 1. 结论与建议

**这套体验在架构上可实现。新系列可以把主菜单入口、选关和成绩系统做成自己的前端。** MD、独立 galaxy、普通 gamestart、字幕/配音、Cutscene 和 NPC 演出都不天然要求一个 Hub。

但要把两个问题分开：

| 问题 | 判断 |
| --- | --- |
| 不进入 Timelines Hub，直接选关 | 源码支持明确的实现路线；需要 Lua 前端和完整返回路径，不是只改一个按钮 |
| 不要求安装 Timelines DLC | 可以按“基础游戏独立开局 + 自有前端/成绩 + 自给资源”的路线设计；保留原生 `<scenario>` 功能时，另需无 DLC 运行验证 |
| 现有八关仅删一行 DLC dependency 就独立 | 不成立，仍有该 DLC 的舰船/玩家宏、音乐、返回 Hub 和死亡处理依赖 |
| 原版 `ScenarioSelectionMenu` 原封不动从主菜单打开 | 不推荐；它包含控制台、特殊转场、官方章节/排行榜等假设 |

建议新系列采用：**独立前端 + 自有 ID/进度 + 逐关 gamestart/MD**。先用最小原型测试是否可在 Timelines 未启用时保留 `<scenario>` 元数据和原生评分；若不可用，改用普通 gamestart 与自算星级，前端和任务主体不用推倒重来。

本次完成源码调研和方案整理，**没有安装前端 MOD，没有关闭任何 DLC，没有进行实际菜单/无 DLC 启动测试**。基础 UI 中未见某项检查，不等于能证明闭源引擎中也没有对应限制。

## 2. 本次源码证据的新鲜度

本地 `version.dat` 是900。对以下五份解包文件与当前安装的 `08.cat / 08.dat` 内容做 SHA-256 比较，结果全部一致：[比较记录](证据/frontend_source_audit.json)。

- `ui/addons/ego_gameoptions/gameoptions.lua`
- `ui/addons/ego_detailmonitor/menu_scenario_selection.lua`
- `ui/addons/ego_detailmonitor/menu_scenario_debriefing.lua`
- `ui/addons/ego_detailmonitorhelper/helper.lua`
- `ui/core/addon.xsd`

因此以下 UI 分析确实对应当前安装数据；MD/XSD 与其他 DLC 参考仍以本地解包资料为研究依据。

## 3. 官方启动链路：Hub 是入口选择，并非任务唯一载体

### 主菜单的 Timelines 按钮

[gameoptions.lua](../参考资料/基础游戏/ui/addons/ego_gameoptions/gameoptions.lua)：

- `config.optionDefinitions["main"]` 中定义 `id="timelines"`，进入其子菜单。
- `callbackTimelines()` 在没有该扩展时走商店提示路径；有扩展时直接 `NewGame("x4ep1_gamestart_hub")`。
- 基础 [gamestarts.xml](../参考资料/基础游戏/libraries/gamestarts.xml) 中，该 Hub 开局是带 `<extension id="ego_dlc_timelines">` 的占位入口；DLC 再替换成有实际地图和角色的 Hub。

这证明官方按钮选择了“先启动 Hub”，而非证明所有独立关卡都必须先经过 Hub。我们的新入口应使用自有 ID 和回调，不接管这个官方按钮，也不改写其购买/启用判断。

### 选关菜单并不只是一张可通用打开的列表

[menu_scenario_selection.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitor/menu_scenario_selection.lua)：

- 文件属于**基础游戏 UI**，由基础 `ego_detailmonitor/ui.xml` 加载。
- `onShowMenu()` 从 `GetRegisteredModules(true)` 筛选 `module.timelinesscenario`，读取 chapter、描述与各场景的 userdata 成绩。
- 参数第三项控制隐藏场景模式；没有“只显示某个 MOD”或“从主菜单运行”的专用模式参数。
- `startScenario()` 调用 `FadeScreen2`、`EnableScenarioLoading(false, scenario.id)`、`PlaySound("hub_matrix_transition")`，随后 `onUpdate()` 执行 `NewGame(menu.startscenario)`。
- `cleanup()` 无条件调用 `LeaveScenarioConsole()`。
- 普通章节标题使用固定13列布局，并按前章/终局场景成绩判定章节解锁。它不是现成的无限章节战役浏览器。
- 联网时包含官方场景排行榜请求。

其中 `NewGame(关卡ID)` 是值得复用的启动机制；控制台状态、Hub 转场声音、官方章节规则和排行榜不是新系列所需的依赖。`EnableScenarioLoading` 在无控制台上下文时能否安全调用，本次没有运行证明；自有前端不必依赖它，先采用普通加载流程。

### 基础游戏已经有不依赖 Hub 的独立关卡

[基础 gamestarts.xml](../参考资料/基础游戏/libraries/gamestarts.xml) 的 `tutorial_flight` 等开局指定：

- 独立 `basegame_map_tutorial_*_galaxy_macro`；
- 玩家船/角色与装备；
- 关闭 Jobs、god、masstraffic；
- `tags="tutorial nosave"`，而没有 `<scenario>`。

[scenario_tutorials.xml](../参考资料/基础游戏/md/scenario_tutorials.xml) 则用普通 MD 完成任务、写入 userdata，再退出/转入其他开局。这是“不加载 Hub 也能运行独立小宇宙任务”的直接官方证据。我们应参考地图/开局/MD 的组织方式，**不用把新战役冒充成官方 tutorial 来进入教程列表或写其成就进度**。

## 4. 两条无 Hub 实现路线

| 路线 | 保留内容 | 需要自己做 | 适用条件 |
| --- | --- | --- | --- |
| A：自有前端 + 原生 scenario 元数据 | `<scenario>`、评分阈值、场景身份及可用的引擎统计接口 | 主菜单、筛选/分章、结果路由、死亡/退出、移除 Hub 资源依赖 | 适合最大限度沿用旧战役；先验证不启用 DLC 时的原生场景功能 |
| B：自有前端 + 普通独立 gamestart | 自有地图、关卡 MD、配音、镜头、NPC、目标 | 星级计算、成绩与结果显示、关卡解锁；不依赖原生 scenario 统计 | 适合明确要求无 Timelines 的新系列；有基础教程架构作依据 |

两条路线都能有封面卡片、章节页、通关星数、最佳分数、解锁条件和重试。它们的用户体验可以相同，差别在评分与场景身份的底层实现。

**路线A仍属需要验证的工程选择。** `<scenario>` 类型出现在基础 [gamestarts.xsd](../参考资料/基础游戏/libraries/gamestarts.xsd)，相关 UI/FFI 声明也在基础文件中；但这不证明 DLC 关闭时 C++ 的注册、`IsTimelinesScenario`、rating 和统计接口全部可用。不要把“文件位于基础游戏”直接等同于“所有相关功能都无条件开放”。

**路线B是规避这项未知依赖的备选，不是删掉标签就完成迁移。** 移除 `<scenario>` 后，旧库的 `player.allmodules.{player.module}.rating.…`、`add_scenario_stat`、`IsTimelinesScenario()` 及默认结果页不能继续按原假设使用；新前端/MD按自己的阈值表计算星级并显示分项。

若新系列不要求原版精确的 Timelines 评分界面，路线B更容易把 DLC 依赖边界说清楚；若路线A的最小原型全部通过，则保留它能减少改写旧结算的工作。

## 5. 主菜单入口怎样加入

### 使用独立 UI addon，不能只靠关卡 MD

主菜单出现时没有正在运行的新战役 MD 世界。若等到 `md.Setup.Start` 再创建选关页，首次启动主菜单时入口就不会完整工作。

基础 [ui/core/addon.xsd](../参考资料/基础游戏/ui/core/addon.xsd) 允许扩展声明 `menus` 环境、Lua 文件、UI addon依赖和 userdata savedvariable。新系列应在自己的扩展根目录放 `ui.xml`，在启动 UI 阶段完成注册。示意：

```xml
<addon name="next_campaign_frontend">
  <environment type="menus">
    <dependency name="ego_gameoptions" />
    <dependency name="ego_detailmonitorHelper" />
    <file name="ui/campaign_frontend.lua" />
  </environment>
</addon>
```

这里是**UI addon加载依赖**，和 `content.xml` 中 DLC/扩展依赖不是同一个系统。`ego_gameoptions` 是基础 UI，不是 Timelines DLC。示意片段不包含完整注册与生命周期代码，也没有装进现有扩展。

XSD 明确允许 `.lua` 文件；不要误认为一切新增 Lua 都必须改成 `.xpl`，或必须替换整份官方 `ui.xml`。新增自有 addon 与覆盖官方文件是不同方案。

### 当前可考察的低侵入接入点

`gameoptions.lua` 的 `config.optionDefinitions` 是局部变量，本次没有找到原生开放的 `menu.config.optionDefinitions` 注册接口，不能凭空写一个不存在的 API。

但 `OptionsMenu` 被放进全局 `Menus`，其 `displayOption(ftable, option, numCols)` 是公开表函数，`displayOptions("main")` 逐条调用它。新 Lua 可以考察**包装该函数**：保留原函数调用，在启动主菜单渲染 `timelines` 那一行后，额外通过原 `displayOption` 画出自有 `callback` 入口。其通用 row数据与选择处理支持 `option.callback`。

这是一条**源码支持、尚未运行的接入方案**，不是已经完成的 hook。实现时仍要验证：首次主菜单构建前后加载顺序、必要的下一帧刷新、鼠标/键盘/手柄选择、重载时不重复包装、与其他菜单 MOD 的包装链兼容。

优先只对 `isStartmenu + currentOption=="main"` 生效；进入战役后需要的“返回选关”属于另一项受本系列 module ID 限制的入口。保留官方菜单函数并转交未处理情况，避免新入口覆盖整个 OptionsMenu。

其他选择是使用有适配回调的 UI 框架，或替换部分官方 UI；前者引入额外依赖，后者增加版本冲突。当前阶段不必预先锁定第三方框架，更不应为了一个入口复制整份一万多行 `gameoptions.lua`。

### 保护 UI 模式

本地 [SN APIs readme](../../extensions/sn_mod_support_apis/readme.txt) 说明当前推荐用 `ui.xml` 加载新增 Lua，旧的“进游戏后通过 MD Lua_Loader 加载散文件”是历史兼容路径。它也明确区分了保护模式下的 require 限制和标准初始化方式。

本方案先按标准 UI addon 测试，避免依赖 `debug.getupvalue` 等局部变量提取。不能未经测试就宣布它在保护模式下必然可用，也不要一开始就要求关闭保护模式。若最终选择覆盖基础 UI 文件，游戏有专门的修改检测与保护提示，需明确发布要求和冲突范围。

相关第三方说明只采用作者自己的 [X4 Mod Support APIs README](https://github.com/bvbohnen/x4-projects/blob/master/extensions/sn_mod_support_apis/Readme.md)；它不等于 Egosoft 原生API，也不证明本项目的主菜单hook已经兼容。

## 6. 自有选关页与关卡清单

建议独立名称，如 `NextCampaignSelectionMenu`，不要冒用 `ScenarioSelectionMenu` 改成只服务本系列。选关清单至少有：

```text
campaign_id、chapter_id、scenario_id、gamestart_id、顺序、标题、简介、封面
所需DLC/资产包、前置条件、星级阈值、当前/最佳成绩、可重玩状态
```

只显示本系列**显式登记**的关卡，不仅靠“所有timelinesscenario”或“所有chapter=0”。以清单ID关联 `GetRegisteredModules` 的可用开局，检测缺资源/扩展时显示缺失原因并禁用开始按钮。

注册模块可能存在但尚未解锁，或模块可见但资源依赖未满足；按钮状态不能只看ID在列表里。不要复制 `GetRegisteredModules(true)` 的布尔参数却未经核对就认定其含义是“忽略所有解锁/依赖”；原生选关代码使用它不能代替前端自己的检查。

视觉上可以参考原选关菜单：左侧/中部章节与关卡卡片，右侧简介、历史成绩、星级条件和开始按钮。章节数量按清单生成可滚动布局，不延续固定13列、最多六章的隐含设计。排行榜不作为基础能力，新系列只保留本地成绩。

启动时只需要取得已经验证的 `gamestart_id`，按主菜单现有模式调用 `NewGame(id)` 并处理旧菜单清理；普通加载先不接 Hub 的镜头和 `EnableScenarioLoading`。实际API可调用性和焦点/加载顺序在原型中验证。

## 7. 结算、重试、返回选关必须一并设计

目标循环是：

```text
X4 主菜单
  └─ 新系列战役入口 → 自有选关页 → NewGame(本关)
                                      ↓
                              关卡 MD / 配音 / 演出
                                      ↓
                               成功 / 失败 / 放弃
                                      ↓
                              自有成绩与结果界面
                         ┌────────────┼────────────┐
                       重试         下一关       返回选关
                     同一开局      下一开局    退出本关到主菜单前端
```

### 不沿用默认“返回Hub”按钮

[menu_scenario_debriefing.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitor/menu_scenario_debriefing.lua) 的按钮明确调用 `returnToHub("x4ep1_gamestart_hub")`；其函数启用 reverse scenario loading 后又 `NewGame`。即使只把按钮文字改成“返回选关”，底层仍会启动Hub。

它还会请求/上传官方场景排行榜；原生函数返回 modified并不等于已经隔离本系列网络行为。自有结果设计应只读写本系列数据，未计划接榜就不调用这些上传/查询接口。

### 返回主菜单已有原生MD接口

[md.xsd](../参考资料/基础游戏/libraries/md.xsd) 定义：

```xml
<quit_to_startmenu submenu="'next_campaign'" />
```

`submenu` 指定要打开的启动菜单子页；基础 UI `init()` 会读取 `GetStartmenuParam()` 并打开 OptionsMenu相应子页。这是可用于路由的已有接口。

**这行代码单独使用并不会自动创建一个名叫 next_campaign 的菜单。** 新前端仍须处理该路由。可包装对应submenu处理，或在退出前写入本系列一次性“返回选关”标记，在主菜单UI加载后下一帧路由到自有选关页；真正显示成功后消费标记，防止反复自动弹出。后者也能处理启动时hook尚未安装、原始submenu参数已被消费的加载顺序问题。

重试/下一关可借基础 `quit_to_game game="…"` 或菜单 `NewGame(id)` 机制，但不能在MD与Lua两边同时发起切换。统一由一处执行，先保存成绩，再停止音频/镜头/循环，再启动新module。

### 真实死亡是独立的技术风险

[helper.lua](../参考资料/基础游戏/ui/addons/ego_detailmonitorhelper/helper.lua) 的 `Helper.registerMenu` 在 `showMenuCallback` 内有明确限制：`C.IsGameOver()` 时，除了 `OptionsMenu` 和 `ScenarioDebriefingMenu`，其他菜单直接返回，不显示。

这意味着“新建一个 `NextCampaignResultMenu`，玩家死了直接打开它”在当前基础UI下会被挡住。不能只验证胜利页和普通任务失败就宣称结果系统完成。

可考察的处理路线：

- 在 **OptionsMenu** 内为本系列提供结果/重试子页及死亡路由，它是已被允许的名称；不再跳进另一个被拦截的结果菜单。
- 或在原 `ScenarioDebriefingMenu` 内，仅针对本系列 module 条件分支到自己的结果内容，保留其被允许的身份，完全避开原Hub/排行榜处理。
- 或先退出实际GameOver世界，再在主菜单前端显示已持久保存的失败摘要，提供重试/选关；死亡瞬间的UI收口仍需验证。

无需为了显示结果全局取消死亡，也不建议粗暴删除Helper的所有GameOver保护。选定方案后，必须单测实际玩家死亡、仅任务目标失败、玩家换船后死亡和主动放弃。

当前星门陨落 [结算库](../../extensions/gatefall_chronicles/md/gatefall_lib_scenario.xml) 在 `$PlayerDied` 时只写 `timelines_hub_spawnmethod=2`，不自己打开结果页；非死亡时才开原结果菜单。这正是不能直接保留的Hub相关退出假设。

## 8. 去除DLC依赖：前端与资源是两份工作

当前 [content.xml](../../extensions/gatefall_chronicles/content.xml) 强制依赖 Timelines、Terran、Boron、Split。绕过Hub不自动取消这些资源依赖。至少已确认以下 Timelines 引用：

| 当前引用 | 源码依据 | 新系列无Timelines时 |
| --- | --- | --- |
| M0 `ship_xen_xl_mothership_01_a_macro` | [DLC宏索引](../参考资料/TimelineDLC/index/macros.xml) 明确指向 `extensions/ego_dlc_timelines/assets/…`；旧关3–8中部分场景使用M0或其残骸 | 换成基础/计划保留DLC的舰体，或自制资源；不能只换宏名而不重拍镜头和调整碰撞 |
| 札幌 `ship_ter_l_flagship_01_a_macro` | 同一DLC宏索引 | 不因它是Terran外观就假定归Terran DLC |
| 第六关玩家 `character_player_timelines_weaken_fleet_macro` | [本MOD gamestarts](../../extensions/gatefall_chronicles/libraries/gamestarts.xml) | 换成独立核对过的基础/所需DLC玩家宏 |
| `x4_timelines_ost_*`、结果音乐、`scenario_fail` | [DLC sound_library](../参考资料/TimelineDLC/libraries/sound_library.xml) 与本MOD调用 | 换成自有或明确可用的音乐ID/文件 |
| `hub_matrix_transition` | DLC sound_library 定义；原选关/结算Lua调用 | 不沿用，使用普通加载或自有转场声 |
| Hub开局、角色选择userdata、`timelines_hub_spawnmethod` | 原选关/结算Lua与本MOD结算库 | 独立玩家定义与前端路由 |

这只是**已经确认的例子，不是完整资源去依赖清单**。还应递归核对引用的组件、子宏、武器、特效、贴图、地图环境、loadout、文本和声音，不能用名字里有没有timelines作为唯一判据。某些功能/宏可能在基础更新中引入，另一些基础文件只提供DLC占位条目，需要按实际资源来源区分。

新系列可以取消Timelines而仍要求Terran/Boron/Split，或进一步设计成仅基础游戏；两者工作量与可用舰船/场景不同。不要为实现无DLC安装而把解包的DLC资产随MOD打包；新入口也不应绕过官方模块的购买/启用限制。

## 9. 新系列的建议文件结构

```text
extensions/next_campaign/
  content.xml
  ui.xml
  ui/
    campaign_frontend.lua          启动注册、入口包装与返回路由
    campaign_selection.lua         自有章节/关卡卡片
    campaign_results.lua           成绩显示；处理GameOver允许的宿主菜单
    campaign_manifest.lua          仅本系列的关卡、顺序、前置与评分配置
  libraries/
    gamestarts.xml
    loadouts.xml
    sound_library.xml
  index/macros.xml
  maps/next_s01_galaxy_macro.xml
  md/next_s01.xml
  md/next_campaign_results.xml
  cutscenes/…
  t/…
  voice-l044/…                     按所选配音语言布局
```

这是职责建议，未创建上述运行扩展。若选择普通gamestart，标题/描述和评分配置避免在MD、Lua和t文件中各维护一套矛盾版本；至少做一致性检查或从统一制作清单生成。

主菜单进度属于跨关/跨新开局数据，使用本系列 userdata或UI userdata存储；单关cue变量随重新启动关卡而重置。存档规则（允许存读或nosave）显式决定，不要借 `tutorial` 标签隐藏新战役。普通开局在原版“新游戏”列表中可能也会出现，第一版可接受这一备用入口；若要隐藏，只能用经验证的UI过滤方案，不能随意捏造一个schema没有的hidden标签。

## 10. 必须先做的最小原型与通过标准

不先制作整关剧情。先准备两个仅使用基础游戏资源的小关卡，前端与返回循环验证通过后，再迁入完整战役。

| 顺序 | 验证项 | 通过标准 |
| --- | --- | --- |
| 1 | 冷启动主菜单 | 未加载存档即可看到新系列入口；没有先进入Hub或隐形测试世界 |
| 2 | 独立关卡筛选 | 只显示本系列；有/无官方DLC时均不混入原版场景 |
| 3 | 普通gamestart启动 | `NewGame(自有关卡)` 进入小宇宙，MD/玩家船/退出正常 |
| 4 | 原生scenario探针 | Timelines未启用时测试模块注册、场景身份、评分/统计；失败就走路线B，不以猜测认定支持 |
| 5 | 胜利/失败/真死亡 | 均有可用结果、重试或返回；不会因GameOver菜单限制卡住 |
| 6 | 重试/下一关/返回 | 连续循环，不进入Hub、不残留暂停/黑场/语音、不重复写分 |
| 7 | 退出后冷启动 | 星级、最好成绩和解锁仍在；不会自动循环弹选关页 |
| 8 | 主菜单、沙盒、官方Timelines | 新前端只处理自有内容；官方入口和沙盒菜单正常 |
| 9 | 输入/界面环境 | 鼠标、键盘、手柄，分辨率/UI缩放，保护模式与计划支持的UI MOD组合 |
| 10 | 无DLC资源测试 | 先在Timelines未启用环境测试；若宣称支持未安装，还要在实际资源不可用环境测试，不能只删除dependency就算完成 |

不需要为测试改动用户的正式进度或重置时间线成绩。本次没有执行这些运行测试；目前可批准的是架构方向，不能宣称已做出可发行的无DLC选关系统。

## 11. 对旧路线决策的更新

旧 [Mod目标](../../extensions/gatefall_chronicles/Mod目标.md) 将“独立主菜单入口/自定义前端”列为不优先的备选，主要为了降低Lua修改成本。**这是当时的项目取舍，不是引擎无法实现。**

现在用户明确希望跳过Hub，这条路线应进入新系列的优先技术验证；旧星门陨落八关维持现状，新系列另建扩展与进度。任务编排、配音、镜头和室内演出的经验仍可复用，主要新增的是前端、结果路由、真实死亡和资源去依赖工作。
