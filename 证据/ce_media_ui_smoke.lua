-- Offline Lua 5.1 control-flow harness. This does not load X4 or native UI.
local ROOT = "extensions/concordant_eden/ui/"
local report, logs, events, queue, frames, exitSequence = {}, {}, {}, {}, {}, {}
local now, pauseDepth, closes, originalCalls = 0, 0, 0, 0
local currentModule, startmenu, gameover = "concordant_eden_test_01", false, false
local data = {concordant_eden_pending_result="1"}
local id = "concordant_eden_test_01"
for key,value in pairs({_last_result=1,_last_score=500,_last_rating=5,_best_score=500,_best_rating=5,_times_finished=1,_last_duration=24}) do data[id..key]=tostring(value) end
local C = {
 IsStartmenu=function() return startmenu end,
 IsGameOver=function() return gameover end,
 GetGameStartName=function() return currentModule end,
 GetUserData=function(key) return data[key] or "" end,
 SetUserData=function(key,value) data[key]=value;if key=="concordant_eden_exit_stage" then exitSequence[#exitSequence+1]="stage"..value end end,
 HidePromo=function() end,
 StopStartMenuBGMusic=function() report.menuMusicStopped=true end,
 StartStartMenuBGMusic=function() report.menuMusicRestored=true end,
 SetSceneCameraActive=function(v) report.camera=v end,
 ClearRendertarget=function() end,
 GetPlayerOccupiedShipID=function() return 42 end,
}
require=function(name) assert(name=="ffi",name); return {C=C,cdef=function() end,string=function(value) return value end} end
function DebugError(message) logs[#logs+1]=message end
function ReadText(page,line) return "text_"..page.."_"..line end
function GetRegisteredModules() return {{id=id,name="Test",description="Test description",image="gamestart_flightschool",hasunlockconditions=false}} end
function RegisterEvent(name,fn) events[name]=fn end
function UnregisterEvent(name,fn) if events[name]==fn then events[name]=nil end end
function Pause() pauseDepth=pauseDepth+1 end
function Unpause(force) if force then assert(startmenu); return end; pauseDepth=pauseDepth-1; assert(pauseDepth>=0,"Unpause underflow") end
function getElapsedTime() return now end
function GetCurRealTime() return now end
function GetMenuParameters2()
 if report.engineOverride then return report.engineOverride[1],report.engineOverride[2],nil end
 return report.openName,report.openParam,report.openParam2
end
function getElement() return 1 end
function registerForEvent(name,_,fn) events[name]=fn end
function unregisterForEvent() end
function GetTextLines(text) return {text} end
function ConvertIntegerString(value) return tostring(value) end
function ConvertStringTo64Bit(value) return tonumber(value) end
function StartPlayingSound(name) assert(name=="ce_loading_music_01");report.loadingStarts=(report.loadingStarts or 0)+1;return 123 end
function StopPlayingSound(sound) assert(sound==123);report.loadingStops=(report.loadingStops or 0)+1 end
function ConvertTimeString(value) return tostring(value) end
function GetControllerInfo() return "mouseCursor" end
function GetTopRow() return 1 end
function SelectRow() end
function SelectColumn() end
function NewGame(value) report.newGame=value end
function QuitModule() report.quit=(report.quit or 0)+1;exitSequence[#exitSequence+1]="QuitModule" end
function QuitGame() report.quitGame=(report.quitGame or 0)+1;exitSequence[#exitSequence+1]="QuitGame" end
function AddUITriggeredEvent(screen,control) report.uiEvent=control;report.uiEvents=(report.uiEvents or 0)+1 end
Color=setmetatable({}, {__index=function(t,k) local v={r=255,g=255,b=255,a=100};rawset(t,k,v);return v end})
ColorText=setmetatable({}, {__index=function() return "" end})

local cellMethods={}
for _,method in ipairs({"setColSpan","setBackgroundColSpan","createText","createButton","createIcon","createStatusBar","setText","setIcon","setIcon2","setText2"}) do cellMethods[method]=function(self) return self end end
function cellMethods:getWidth() return 250 end
function cellMethods:getColSpanWidth() return 250 end
local tableMethods={}
function tableMethods:addRow(value,properties)
 local row={index=#self.rows+1,rowdata=value,properties=properties or {}}
 for n=1,self.columns do row[n]=setmetatable({properties={},handlers={}}, {__index=cellMethods}) end
 self.rows[#self.rows+1]=row;return row
end
function tableMethods:addEmptyRow() return self:addRow(nil,{}) end
for _,method in ipairs({"setColWidth","setColWidthPercent","setSelectedRow","setSelectedCol","setTopRow","addConnection"}) do tableMethods[method]=function(self) return self end end
function tableMethods:getFullHeight() return #self.rows*24 end
function tableMethods:getVisibleHeight() return self:getFullHeight() end
local frameMethods={}
function frameMethods:addTable(columns,properties)
 local t=setmetatable({rows={},columns=columns,properties=properties or {},index=#self.content+1,id=100+#self.content}, {__index=tableMethods})
 self.content[#self.content+1]=t;return t
end
function frameMethods:addRenderTarget(properties) self.renderTarget=properties;return properties end
function frameMethods:setBackground() return self end
function frameMethods:setBackground2() return self end
function frameMethods:display() frames[#frames+1]=self;self.menu.frames[self.properties.layer]=self end
function frameMethods:update() end
Helper={viewWidth=1920,viewHeight=1080,borderSize=1,frameBorder=8,scrollbarWidth=16,standardTextHeight=24,standardTextOffsetx=4,standardFontSize=16,standardFont="Zekton",standardFontBold="ZektonBold",configButtonBorderSize=1,titleTextProperties={},subHeaderTextProperties={},currentTableCol={},currentTableRow={}}
function Helper.scaleX(v) return v end
function Helper.scaleY(v) return v end
function Helper.scaleFont(_,v) return v end
function Helper.registerMenu(menu) menu.frames={};menu.rowDataMap={};menu.frameData={} end
function Helper.createFrameHandle(menu,properties) return setmetatable({menu=menu,properties=properties,content={}}, {__index=frameMethods}) end
function Helper.removeAllWidgetScripts() end
function Helper.clearTableConnectionColumn() end
function Helper.clearDataForRefresh(menu,layer) menu.frames[layer]=nil end
function NotifyOnCutsceneStopped() end
function GetRenderTargetTexture() return 'mock_texture' end
function CreateCutsceneDescriptor(key,params)
 if not startmenu and not gameover then assert(key:match("_world$") and params.targetobject==42,"world movie must reference occupied ship") end
 report.movieKey=key;return 400
end
function StartCutscene() report.movieId=(report.movieId or 500)+1;return report.movieId end
function ReleaseCutsceneDescriptor() report.released=(report.released or 0)+1 end
function StopCutscene(id) if events.cutsceneStopped then events.cutsceneStopped(nil,id) end end
function Helper.clearFrame(menu,layer) menu.frames[layer]=nil end
function Helper.setTabScrollCallback(menu) menu.tabCallbacks=(menu.tabCallbacks or 0)+1 end
function Helper.removeAllTabScrollCallbacks(menu) menu.tabCallbacks=0 end
function Helper.addDelayedOneTimeCallbackOnUpdate(fn,block,time) queue[#queue+1]={fn=fn,time=time or now} end
function OpenMenu(name,param,param2) report.opens=(report.opens or 0)+1;report.openName=name;report.openParam=param;report.openParam2=param2;report.undelivered=true end
function Helper.closeMenu(menu,dueToClose)
 if ConcordantEden and ConcordantEden.movieActiveHost==menu then
  assert(not menu.cutsceneID and not menu.descriptor,"movie resource still live when closing render target")
 end
 if dueToClose=="back" and menu.param2 then OpenMenu(menu.param2[1],menu.param2[2],menu.param2[3]) end
 if menu.name=="OptionsMenu" then exitSequence[#exitSequence+1]="closeOptions" end
 closes=closes+1;menu.shown=false;menu.frames={};menu.tabCallbacks=0;menu.param=nil;menu.param2=nil
end
function Helper.closeMenuAndOpenNewMenu(menu,name,param,noreturn)
 report.noReturn=noreturn
 local returnchain=menu.param2
 if not noreturn then returnchain={menu.name,menu.param,{"restore",false,menu.param2}} end
 OpenMenu(name,param,returnchain);Helper.closeMenu(menu)
end

local native={name="ScenarioDebriefingMenu",frames={},onShowMenu=function() originalCalls=originalCalls+1 end,cleanup=function() originalCalls=originalCalls+10 end,onCloseElement=function() originalCalls=originalCalls+100 end,onTimelinesScoreUploaded=function() originalCalls=originalCalls+1000 end,onTimelinesRankingsReceived=function() originalCalls=originalCalls+10000 end}
local options={name="OptionsMenu",shown=false,isStartmenu=false,currentOption="main",frames={},displayOption=function() end,refresh=function() end}
function options.cleanup()
 if options.paused then Unpause();options.paused=nil;exitSequence[#exitSequence+1]="UnpauseOptions" end
 options.currentOption=nil;options.userQuestion=nil
end
function options.closeMenu(dueToClose) Helper.closeMenu(options,dueToClose);options.cleanup() end
function options.onCloseElement(dueToClose) options.closeMenu(dueToClose) end
function options.callbackExit(quit)
 report.originalExitCalls=(report.originalExitCalls or 0)+1
 if quit then QuitGame() else QuitModule() end
 options.closeMenu("close")
end
function options.onShowMenu()
 options.isStartmenu=startmenu
 if not startmenu then Pause();options.paused=true end
 options.currentOption="question"
 local quit=options.param=="quit"
 options.userQuestion={callback=function() return options.callbackExit(quit) end}
end
Menus={native,options}
local function deliverOpen()
 report.undelivered=false
 local target
 for _,candidate in ipairs(Menus) do if candidate.name==report.openName then target=candidate;break end end
 assert(target,"unknown mock destination "..tostring(report.openName))
 assert(not gameover or target.name=="OptionsMenu" or target.name=="ScenarioDebriefingMenu","GameOver whitelist rejected destination")
 target.param=report.openParam;target.param2=report.openParam2
 if target.param2 and target.param2[1]=="restore" then target.param2=target.param2[3] end
 target.shown=true;target.onShowMenu();return target
end
local function drain()
 for pass=1,80 do
  if #queue==0 then return end
  -- Engine delivers menu show asynchronously; don't run its open watchdog to
  -- exhaustion while a normal test is waiting to deliver that show explicitly.
  if report.undelivered and (report.openName=="ConcordantEdenMovieMenu" or
    (report.openName=="ScenarioDebriefingMenu" and type(report.openParam)=="table" and report.openParam[3]=="concordant_eden_movie")) then return end
  now=now+1;local q=queue;queue={}
  for _,entry in ipairs(q) do if entry.time<=now then entry.fn() else queue[#queue+1]=entry end end
 end
 assert(#queue==0,"timer queue did not drain")
end
local checks={}
local function check(name,fn)
 local ok,err=pcall(fn);checks[#checks+1]=(ok and "PASS " or "FAIL ")..name..(ok and "" or ": "..tostring(err))
end
local function enterOwn()
 currentModule=id;startmenu=false;native.param={0,0,"concordant_eden_result"};native.shown=true;native.onShowMenu()
end
local function forceClose()
 native.onCloseElement("close",nil,true)
 assert(native.shown==false,"forced close left host shown")
 assert(pauseDepth==0,"forced close leaked Pause")
end

assert(loadfile(ROOT.."campaign_manifest.lua"))()
assert(loadfile(ROOT.."campaign_selection.lua"))()
assert(loadfile(ROOT.."campaign_debriefing.lua"))()
assert(loadfile(ROOT.."campaign_movie.lua"))()
assert(loadfile(ROOT.."campaign_integration.lua"))()
drain()
check("all five runtime Lua files install",function() assert(ConcordantEden.selectionReady and ConcordantEden.debriefReady and ConcordantEden.movieMenu and options.concordantEdenHook) end)
check("result frames request without consuming pending",function() enterOwn();assert(pauseDepth==1);assert(data.concordant_eden_pending_result=="1");assert(native.infoFrame and native.info2Frame) end)
check("pending waits for both frames",function() native.viewCreated(5);assert(data.concordant_eden_pending_result=="1");native.viewCreated(4);assert(data.concordant_eden_pending_result=="0") end)
check("forced-close result closes without navigating",function() local n=#frames;forceClose();assert(#frames==n,"forced close rebuilt frames") end)
check("same-host result to selection to result balances Pause",function() enterOwn();ConcordantEden.showSelection(native);assert(native.shown and pauseDepth==1 and native.scenariosByID[id]);ConcordantEden.showResults(native);assert(native.shown and pauseDepth==1 and native.scenario.id==id);forceClose() end)
check("GameOver selection keeps permitted host",function() gameover=true;enterOwn();ConcordantEden.showSelection(native);assert(native.name=="ScenarioDebriefingMenu" and native.shown and pauseDepth==1);gameover=false;local n=#frames;forceClose();assert(#frames==n,"selection forced close navigated") end)
check("official module delegates original methods",function() currentModule="official_test";native.param={0,0};local before=originalCalls;native.onShowMenu();native.onTimelinesRankingsReceived();native.cleanup();assert(originalCalls-before==10011,"native delegation mismatch: "..(originalCalls-before)) end)
check("repeated page switches do not accumulate TabScroll",function() enterOwn();for n=1,4 do ConcordantEden.showSelection(native);assert((native.tabCallbacks or 0)==1,"duplicate TabScroll");ConcordantEden.showResults(native);assert((native.tabCallbacks or 0)==0,"TabScroll not removed") end;forceClose() end)
check("retry waits for intro and uses whitelisted host even at GameOver",function() gameover=true;enterOwn();ConcordantEden.startMission(native,id);assert(ConcordantEden.movieActiveHost==native and pauseDepth==0 and not report.newGame);native.viewCreated(5,1,2);now=now+1;native.onUpdate();assert(report.movieKey=="ce_movie_intro");local movieID=report.movieId;now=now+30;events.cutsceneStopped(nil,movieID);drain();assert(report.newGame==id and not native.shown and pauseDepth==0);events.cutsceneStopped(nil,movieID);assert(#queue==0);gameover=false end)
check("ResultReady schedules native host without automatic exit",function() report.openName=nil;gameover=true;data.concordant_eden_pending_result="1";assert(events["ConcordantEden.ResultReady"]);events["ConcordantEden.ResultReady"]();drain();assert(report.openName=="ScenarioDebriefingMenu");assert(not report.quit,"ResultReady automatically quit world");assert(pauseDepth==0);gameover=false end)
check("standalone selection forced close does not navigate",function() startmenu=true;local target=ConcordantEden.selectionMenu;target.shown=true;target.onShowMenu();local previous=report.openName;local n=#frames;target.onCloseElement("close",nil,true);assert(not target.shown and pauseDepth==0);assert(report.openName==previous and #frames==n,"forced standalone close navigated");startmenu=false end)
check("custom exit only routes to stock question and retains return chain",function()
 enterOwn();local previous=report.quit or 0;local queued=#queue;ConcordantEden.exitToMain(native)
 assert((report.quit or 0)==previous and #queue==queued,"custom exit called or scheduled QuitModule")
 assert(report.openName=="OptionsMenu" and report.openParam=="exit" and report.noReturn==false)
 assert(report.openParam2 and report.openParam2[1]=="ScenarioDebriefingMenu" and report.openParam2[2][3]=="concordant_eden_result")
 assert(not native.shown and pauseDepth==0 and data.concordant_eden_exit_stage=="1")
end)
check("native Yes keeps stage2 QuitModule close Unpause stage3 order",function()
 assert(deliverOpen()==options and pauseDepth==1);exitSequence={};local previous=report.originalExitCalls or 0
 options.userQuestion.callback()
 assert(report.originalExitCalls==previous+1)
 assert(table.concat(exitSequence,",")=="stage2,QuitModule,closeOptions,UnpauseOptions,stage3",table.concat(exitSequence,","))
 assert(not options.shown and pauseDepth==0 and data.concordant_eden_exit_stage=="3")
end)
check("native No restores GameOver result host with paired Pause",function()
 gameover=true;enterOwn();local previous=report.quit or 0;ConcordantEden.exitToMain(native);deliverOpen()
 assert(pauseDepth==1 and options.shown);options.onCloseElement("back")
 assert(pauseDepth==0 and report.openName=="ScenarioDebriefingMenu")
 assert(deliverOpen()==native and native.shown and pauseDepth==1 and native.scenario.id==id)
 assert((report.quit or 0)==previous and data.concordant_eden_exit_stage=="1")
 forceClose();gameover=false
end)
check("official module exit delegates without touching own diagnostic stage",function()
 currentModule="official_test";OpenMenu("OptionsMenu","exit");deliverOpen();exitSequence={};local stage=data.concordant_eden_exit_stage;local previous=report.originalExitCalls
 options.userQuestion.callback();assert(report.originalExitCalls==previous+1 and data.concordant_eden_exit_stage==stage)
 assert(table.concat(exitSequence,",")=="QuitModule,closeOptions,UnpauseOptions");assert(pauseDepth==0)
end)
check("own desktop quit delegates without marking module exit",function()
 currentModule=id;OpenMenu("OptionsMenu","quit");deliverOpen();exitSequence={};local stage=data.concordant_eden_exit_stage;local previous=report.quitGame or 0
 options.userQuestion.callback();assert(report.quitGame==previous+1 and data.concordant_eden_exit_stage==stage)
 assert(table.concat(exitSequence,",")=="QuitGame,closeOptions,UnpauseOptions");assert(pauseDepth==0)
end)
check("ordinary trace and result frames preserve last exit diagnostic",function()
 data.concordant_eden_exit_stage="2";ConcordantEden.trace(7,"mock cold-start result");enterOwn();native.viewCreated(5);native.viewCreated(4)
 assert(data.concordant_eden_exit_stage=="2");forceClose()
end)
check("main-menu intro owns audio and starts world only after movie",function()
 startmenu=true;report.newGame=nil;report.menuMusicRestored=false;local selection=ConcordantEden.selectionMenu;selection.shown=true;selection.onShowMenu()
 ConcordantEden.startMission(selection,id);assert(not report.newGame)
 local m=deliverOpen();assert(m==ConcordantEden.movieMenu and pauseDepth==0 and report.menuMusicStopped)
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();local movieID=report.movieId
 events.cutsceneStopped(nil,movieID+999);assert(not m.resolved)
 now=now+30;events.cutsceneStopped(nil,movieID);drain()
 assert(report.newGame==id and not report.menuMusicRestored and report.camera and not ConcordantEden.movieActiveHost)
 assert(data.concordant_eden_loading_sound=="123")
 startmenu=false
 events["ConcordantEden.WorldReady"]();assert(data.concordant_eden_loading_sound=="0")
end)
check("mid movie runs without Pause or visible controls and acknowledges once",function()
 report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,"mid");drain();local m=deliverOpen();assert(pauseDepth==0)
 assert(#m.frame.content==1 and #m.frame.content[1].rows==0 and m.frame.renderTarget.height==1080)
 m.viewCreated(5,1,2);assert(m.rendertarget==2);now=now+1;m.onUpdate();assert(report.movieKey=="ce_movie_mid_world");local movieID=report.movieId
 local scheduled=#queue;events["ConcordantEden.MovieReady"](nil,"mid");assert(#queue==scheduled)
 assert(report.uiEvent==nil);now=now+30;events.cutsceneStopped(nil,movieID);drain()
 assert(report.uiEvent=="movie_mid_done" and pauseDepth==0)
 events.cutsceneStopped(nil,movieID);assert(#queue==0)
 events["ConcordantEden.MovieReady"](nil,"mid");assert(#queue==0)
end)
check("early playback failure stays visible and explicit skip continues",function()
 report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,"outro");drain();local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();events.cutsceneStopped(nil,report.movieId)
 assert(m.failure and not m.resolved and report.uiEvent==nil and pauseDepth==0)
 m.onCloseElement("back");drain();assert(report.uiEvent=="movie_outro_done" and pauseDepth==0)
end)
check("forced movie close cancels without recording a completed movie",function()
 events["ConcordantEden.WorldReady"]()
 report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,"mid");drain();local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();m.onCloseElement("close",nil,true);drain()
 assert(report.uiEvent=="movie_cancelled" and pauseDepth==0 and not ConcordantEden.movieActiveHost)
end)
check("movie timeout offers retry and never automatically advances",function()
 events["ConcordantEden.WorldReady"]()
 report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,"mid");drain();local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();now=now+61;m.onUpdate()
 assert(m.failure and not m.resolved and report.uiEvent==nil)
 m.frame.content[1].rows[1][1].handlers.onClick();assert(not m.failure)
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();now=now+30;events.cutsceneStopped(nil,report.movieId);drain()
 assert(report.uiEvent=="movie_mid_done" and pauseDepth==0)
end)
check("in-world movie cannot open through an unrelated GameOver menu",function()
 gameover=true;assert(not ConcordantEden.playMovie(nil,"mid",function() error("unexpected completion") end));gameover=false
end)

-- Run the actual substituted loading source in an isolated mock core environment.
local function loadingHarness(own, audioFails, inherited, stopFails)
 local trace={started=0,stopped=0,icons=0,events={},slides={}}
 local coreC={}
 local colors={"loadingscreen_scenario_text","loadingscreen_text","loadingscreen_circle","loadingscreen_bar","loadingscreen_bar_background","loadingscreen_background","loadingscreen_scenario_dust"}
 function coreC.GetNumAllColorMapEntries() return #colors end
 function coreC.GetAllColorMapEntries(buf) for i,key in ipairs(colors) do buf[i-1]={id=key,color={red=255,green=255,blue=255,alpha=100},glowfactor=0} end;return #colors end
 function coreC.GetLocalizedText(_,_,fallback) return fallback or "mock text" end
 function coreC.GetUIScale() return 1 end
 function coreC.GetTextHeight() return 20 end
 function coreC.IsDemoVersion() return false end
 function coreC.IsScenarioLoading() return {active=false} end
 function coreC.GetNumIcons() return 1 end
 function coreC.GetIcons(buf) buf[0]="loading_normal";return 1 end
 function coreC.StopStartMenuBGMusic() if stopFails then error("core stop unavailable") end;trace.menuStopped=true;trace.menuStops=(trace.menuStops or 0)+1 end
 local shared={concordant_eden_loading_sound=inherited and "123" or "0"}
 function coreC.GetUserData(key) return shared[key] or "" end
 function coreC.SetUserData(key,value) shared[key]=value end
 local env={self={},math=math,table=table,string=string,pcall=pcall,pairs=pairs,ipairs=ipairs,tostring=tostring,tonumber=tonumber,setmetatable=setmetatable}
 env.require=function(name) if name=="utf8" then return {} end;return {C=coreC,cdef=function() end,new=function() return {} end,string=function(v) return v end} end
 env.DebugError=function() end
 env.TraceBack=function() return "mock" end
 env.getElement=function(path) return path end
 env.clone=function(_,name) return name end
 env.setAttribute=function() end
 env.SetDiffuseColor=function() end
 env.goToTime=function() end
 env.getElapsedTime=function() return now end
 env.goToSlide=function(element,slide) trace.slides[element]=slide end
 env.registerForEvent=function(name,_,fn) trace.events[name]=fn end
 env.GetLoadingInfo=function() return "Loading",50,1,false,1,own and "ce_loading_test_01" or "","caption",60 end
 env.SetIcon=function(_,icon) trace.icons=trace.icons+1;trace.icon=icon end
 env.StartPlayingSound=function(sound) if audioFails then error("audio unavailable") end;assert(sound=="ce_loading_music_01");trace.started=trace.started+1;return 123 end
 env.StopPlayingSound=function(sound) assert(sound==123);trace.stopped=trace.stopped+1 end
 setfenv(assert(loadfile("extensions/concordant_eden/source/subst_v900/ui/core/lua/loading.xpl")),env)()
 env.self:onInitialize()
 return env,trace
end
check("own loading pins cover beyond configured time and pairs BGM stop",function()
 local env,t=loadingHarness(true,false);assert(t.started==1 and t.icon=="ce_loading_test_01" and t.slides.Scene=="loading")
 now=now+1000;env.self:onUpdate();assert(t.icons==1)
 t.events.gameLoadingDone();t.events.gameLoadingDone();assert(t.stopped==1)
end)
check("ordinary loading keeps native proverb and never starts campaign audio",function()
 local env,t=loadingHarness(false,false);assert(t.started==0 and not t.menuStopped and t.slides.Scene=="proverb")
 t.events.gameLoadingDone();assert(t.stopped==0)
end)
check("loading audio failure cannot block loading completion",function()
 local env,t=loadingHarness(true,true);assert(t.icon=="ce_loading_test_01")
 t.events.gameLoadingDone();assert(t.stopped==0)
end)
check("loading adopts prestarted sound without layering a duplicate",function()
 local env,t=loadingHarness(true,false,true);assert(t.started==0)
 t.events.gameLoadingDone();t.events.gameLoadingDone();assert(t.stopped==1)
end)
check("failure to stop menu BGM does not suppress loading music start",function()
 local env,t=loadingHarness(true,false,false,true);assert(t.started==1)
 t.events.gameLoadingDone();assert(t.stopped==1)
end)
check("loading music guard re-stops native music then retires at loading done",function()
 local env,t=loadingHarness(true,false,true);assert(t.menuStops==1 and t.started==0)
 now=now+1;env.self:onUpdate();assert(t.menuStops==2 and t.started==0)
 t.events.gameLoadingDone();now=now+1;env.self:onUpdate()
 assert(t.menuStops==2 and t.stopped==1,"loading guard leaked into gameplay")
 local other,o=loadingHarness(false,false);now=now+1
 -- Ordinary loading may still be showing its proverb; provide its slide API.
 other.getCurrentSlide=function() return 1,"proverb" end
 other.self:onUpdate();assert(not o.menuStops)
end)
local function tick(seconds)
 now=now+seconds;local q=queue;queue={}
 for _,entry in ipairs(q) do if entry.time<=now then entry.fn() else queue[#queue+1]=entry end end
end
check("fresh world resets result guard and both movie acknowledgements reach result",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 for _,clip in ipairs({"mid","outro"}) do
  report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,clip);drain();local m=deliverOpen()
  m.viewCreated(5,1,2);now=now+1;m.onUpdate();now=now+30;events.cutsceneStopped(nil,report.movieId);drain()
  assert(report.uiEvent=="movie_"..clip.."_done" and not ConcordantEden.movieActiveHost)
 end
 data.concordant_eden_pending_result="1";events["ConcordantEden.ResultReady"]();tick(1)
 assert(native.shown and native.infoFrame and native.scenario.stats.currentstars==5)
 native.viewCreated(5);native.viewCreated(4);drain();forceClose()
end)
check("lost first result open retries until both frame acknowledgements",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="1"
 local opens=report.opens;events["ConcordantEden.ResultReady"]();tick(1)
 assert(report.opens==opens+1)
 -- Model an engine menu-parameter race: no show callback for the first open.
 tick(2);assert(report.opens==opens+2);deliverOpen()
 native.viewCreated(5);assert(data.concordant_eden_pending_result=="1")
 native.viewCreated(4);assert(data.concordant_eden_pending_result=="0")
 local after=report.opens;drain();assert(report.opens==after and data.concordant_eden_result_open=="ack:both-frames")
 forceClose()
end)
check("stale shown debrief cannot swallow a new result request",function()
 native.shown=true;local opens=report.opens
 ConcordantEden.showResults(native);assert(not native.shown and report.opens==opens+1)
 deliverOpen();assert(native.infoFrame and native.info2Frame and pauseDepth==1);forceClose()
end)
check("partial result rebuild balances pause and old-world timers are discarded",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="1"
 events["ConcordantEden.ResultReady"]();tick(1);deliverOpen();native.viewCreated(5)
 local opens=report.opens;tick(2);assert(report.opens==opens+1 and pauseDepth==0)
 deliverOpen();assert(pauseDepth==1);native.viewCreated(5);native.viewCreated(4);drain();forceClose()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="1"
 events["ConcordantEden.ResultReady"]();events["ConcordantEden.WorldReady"]();opens=report.opens;drain()
 assert(report.opens==opens);data.concordant_eden_pending_result="0"
end)
check("lost outro show is retried and Esc sends exactly one completion",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";report.uiEvent=nil
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);local opens=report.opens
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 assert(report.uiEvent==nil and not ConcordantEden.movieActiveHost)
 tick(1);assert(report.opens==opens+1)
 local m=deliverOpen();m.viewCreated(5,1,2);now=now+1;m.onUpdate()
 assert(report.movieKey=="ce_movie_outro_world")
 local count=report.uiEvents or 0;m.onCloseElement("back");m.onCloseElement("back");drain()
 assert(report.uiEvent=="movie_outro_done" and report.uiEvents==count+1 and not ConcordantEden.movieActiveHost)
 data.concordant_eden_pending_result="1";events["ConcordantEden.ResultReady"]();tick(1)
 assert(native.shown and native.infoFrame);native.viewCreated(5);native.viewCreated(4);drain();assert(data.concordant_eden_pending_result=="0");forceClose()
end)
check("movie open timeout releases busy without granting victory or abort",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";report.uiEvent=nil
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 for i=1,6 do tick(2) end
 assert(report.uiEvent==nil and data.concordant_eden_movie_request=="outro:open-failed:await-md-retry")
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();now=now+30;events.cutsceneStopped(nil,report.movieId);drain()
 assert(report.uiEvent=="movie_outro_done")
end)
check("world reset discards pending movie and stale show token",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);local oldParam=report.openParam
 events["ConcordantEden.WorldReady"]();events["ConcordantEden.MovieReady"](nil,"mid");tick(1)
 local newParam=report.openParam;report.openParam=oldParam;deliverOpen()
 assert(not ConcordantEden.movieActiveHost)
 report.openParam=newParam;local m=deliverOpen();assert(m.clipName=="mid")
 m.onCloseElement("back");drain();assert(report.uiEvent=="movie_mid_done")
end)
check("lost Esc acknowledgement is resent without replaying the outro",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();m.onCloseElement("back");drain()
 assert(report.uiEvent=="movie_outro_done");local opens=report.opens
 report.uiEvent=nil -- Simulate MD not receiving the first completion signal.
 events["ConcordantEden.MovieReady"](nil,"outro")
 assert(report.uiEvent=="movie_outro_done" and report.opens==opens and not ConcordantEden.movieActiveHost)
end)
check("pending movie cannot reopen over a death result",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 gameover=true;data.concordant_eden_pending_result="1"
 events["ConcordantEden.ResultReady"]();tick(2)
 assert(report.openName=="ScenarioDebriefingMenu");deliverOpen();native.viewCreated(5);native.viewCreated(4)
 local opens=report.opens;drain();assert(report.opens==opens and not ConcordantEden.movieActiveHost)
 gameover=false;forceClose()
end)
check("Esc intro and mid then native-host outro reaches five-star result",function()
 startmenu=true;gameover=false;data.concordant_eden_pending_result="0";report.newGame=nil
 local selection=ConcordantEden.selectionMenu;selection.shown=true;selection.onShowMenu()
 ConcordantEden.startMission(selection,id);local intro=deliverOpen()
 assert(intro==ConcordantEden.movieMenu)
 intro.viewCreated(5,1,2);now=now+1;intro.onUpdate();intro.onCloseElement("back");drain()
 assert(report.newGame==id and not ConcordantEden.movieActiveHost)
 startmenu=false;events["ConcordantEden.WorldReady"]()
 for _,clip in ipairs({"mid","outro"}) do
  report.uiEvent=nil;events["ConcordantEden.MovieReady"](nil,clip);tick(1)
  assert(report.openName=="ScenarioDebriefingMenu" and report.openParam[3]=="concordant_eden_movie")
  local m=deliverOpen();assert(m==native and m.clipName==clip and not m.infoFrame and pauseDepth==0)
  assert(data.concordant_eden_pending_result=="0","movie must not consume/write result")
  m.viewCreated(5,1,2);now=now+1;m.onUpdate();assert(report.movieKey=="ce_movie_"..clip.."_world")
  if clip=="mid" then m.onCloseElement("back")
  else now=now+30;events.cutsceneStopped(nil,report.movieId) end
  drain();assert(report.uiEvent=="movie_"..clip.."_done" and not ConcordantEden.movieActiveHost)
  assert(clip=="outro" and m.awaitingMovieResult and m.shown or clip=="mid" and not m.shown)
 end
 -- Simulate the MD Finish acknowledgement; real combat/MD is not emulated.
 data.concordant_eden_pending_result="1";events["ConcordantEden.ResultReady"]();tick(1)
 assert(native.shown and native.infoFrame and native.scenario.stats.currentstars==5)
 native.viewCreated(5);native.viewCreated(4);drain();forceClose()
end)
check("stale native movie show never builds or consumes results",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="1"
 OpenMenu("ScenarioDebriefingMenu",{0,0,"concordant_eden_movie",-123});deliverOpen()
 assert(not native.shown and not native.infoFrame and not ConcordantEden.movieActiveHost)
 assert(data.concordant_eden_pending_result=="1" and pauseDepth==0)
 data.concordant_eden_pending_result="0"
end)
-- Unlike deliverOpen above, these checks execute the actual 9.00 Helper
-- registration/dispatch body, with engine calls mocked at its boundary.
local stockEnv=setmetatable({Helper=setmetatable({}, {__index=Helper}),C=setmetatable({
 IsConversationActive=function() return false end,
 TrackMenu=function() end,IsNextStartAnimationSkipped=function() return false end,
 SetWidgetViewScheduled=function() end,
},{__index=C}),createCustomHooks=function() end,
 View={clearMenus=function() report.undelivered=false end},PlaySound=function() end,
 AddUITriggeredEvent=function() end,
},{__index=_G})
stockEnv.Helper.enableAutoMouseEmulation=function() end
local stockRegister=setfenv(assert(loadfile("extensions/concordant_eden/tools/reference_register_menu.lua")),stockEnv)()
check("lost engine show event recovers through actual stock Helper dispatcher",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";report.uiEvent=nil
 stockRegister(native)
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 local opens=report.opens;assert(not native.shown)
 -- No deliverOpen: simulate the engine losing the event but retaining params.
 tick(2)
 assert(native.shown and ConcordantEden.movieActiveHost==native and native.clipName=="outro")
 assert(report.opens==opens and data.concordant_eden_movie_dispatch=="outro:stock-show:accepted")
 native.viewCreated(5,1,2);now=now+1;native.onUpdate()
 native.onCloseElement("back");drain();assert(report.uiEvent=="movie_outro_done")
end)
check("MD heartbeat recovers a lost UI retry timer using stock dispatcher",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";report.uiEvent=nil
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 queue={} -- Simulate the pending Helper retry being lost.
 now=now+3;events["ConcordantEden.MovieReady"](nil,"outro")
 assert(native.shown and native.clipName=="outro")
 native.viewCreated(5,1,2);now=now+1;native.onUpdate();now=now+30
 events.cutsceneStopped(nil,report.movieId);drain();assert(report.uiEvent=="movie_outro_done")
end)
check("stock dispatcher fallback refuses another menu or stale request token",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 report.openName="OptionsMenu";report.openParam="exit"
 tick(2);assert(not native.shown and not ConcordantEden.movieActiveHost)
 report.openParam={0,0,"concordant_eden_movie",-123}
 tick(2);assert(not native.shown and not ConcordantEden.movieActiveHost)
 -- After a new proper OpenMenu, the next stock retry may display it.
 tick(2);assert(native.shown and native.clipName=="outro")
 native.onCloseElement("back");drain()
end)
check("outro recovers when engine retains previous mid token across OpenMenu attempts",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";data.concordant_eden_battle_phase="20"
 report.engineOverride={"ScenarioDebriefingMenu",{0,0,"concordant_eden_movie",1}}
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 local requestedToken=report.openParam[4];assert(requestedToken~=1)
 tick(2)
 assert(native.shown and native.clipName=="outro" and native.request.token==requestedToken,"stale engine token blocked current outro")
 native.viewCreated(5,1,2);now=now+1;native.onUpdate();assert(report.movieKey=="ce_movie_outro_world")
 native.onCloseElement("back");drain();assert(report.uiEvent=="movie_outro_done")
 local opens=report.opens
 data.concordant_eden_pending_result="1";data.concordant_eden_battle_phase="99"
 events["ConcordantEden.ResultReady"]();tick(1)
 assert(report.opens==opens and native.infoFrame and native.scenario.stats.currentstars==5,"outro result reopened stale engine parameters")
 native.viewCreated(5);native.viewCreated(4);drain()
 report.engineOverride=nil
 -- Verify the in-place switch also updates the return chain used by stock exit.
 ConcordantEden.exitToMain(native)
 assert(report.openParam2[2][3]=="concordant_eden_result","exit No would restore old movie mode")
 deliverOpen();options.onCloseElement("back");deliverOpen()
 assert(native.shown and native.infoFrame and native.scenario.stats.currentstars==5)
 forceClose();data.concordant_eden_battle_phase="1"
end)
check("stale movie parameter cannot rebind a different mission phase",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";data.concordant_eden_battle_phase="2"
 report.engineOverride={"ScenarioDebriefingMenu",{0,0,"concordant_eden_movie",1}}
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);tick(2)
 assert(not native.shown and not ConcordantEden.movieActiveHost)
 events["ConcordantEden.WorldReady"]();report.engineOverride=nil;drain();data.concordant_eden_battle_phase="1"
end)
check("resolved outro forced close releases host without another completion",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0"
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1);local m=deliverOpen()
 m.viewCreated(5,1,2);now=now+1;m.onUpdate();now=now+30;events.cutsceneStopped(nil,report.movieId);drain()
 assert(m.awaitingMovieResult and m.shown and not ConcordantEden.movieActiveHost)
 local count=report.uiEvents;m.onCloseElement("back");assert(report.uiEvents==count and m.shown)
 m.onCloseElement("close",nil,true);drain()
 assert(not m.shown and not m.awaitingMovieResult and report.uiEvents==count and pauseDepth==0)
end)
check("stale movie rebind waits while stock exit confirmation is shown",function()
 events["ConcordantEden.WorldReady"]();data.concordant_eden_pending_result="0";data.concordant_eden_battle_phase="20"
 report.engineOverride={"ScenarioDebriefingMenu",{0,0,"concordant_eden_movie",1}}
 events["ConcordantEden.MovieReady"](nil,"outro");tick(1)
 OpenMenu("OptionsMenu","exit");deliverOpen();tick(2)
 assert(options.shown and options.userQuestion and not native.shown and not ConcordantEden.movieActiveHost)
 options.onCloseElement("back");tick(2)
 assert(native.shown and native.clipName=="outro")
 native.onCloseElement("close",nil,true);drain()
 report.engineOverride=nil;data.concordant_eden_battle_phase="1";assert(pauseDepth==0)
end)
local failures=0;for _,line in ipairs(checks) do if line:sub(1,4)=="FAIL" then failures=failures+1 end end
return table.concat(checks,"\n").."\nCHECKS="..#checks.." FAILURES="..failures.." PAUSE_DEPTH="..pauseDepth
