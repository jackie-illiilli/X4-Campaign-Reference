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
}
require=function(name) assert(name=="ffi",name); return {C=C,cdef=function() end,string=function(value) return value end} end
function DebugError(message) logs[#logs+1]=message end
function ReadText(page,line) return "text_"..page.."_"..line end
function GetRegisteredModules() return {{id=id,name="Test",description="Test description",image="gamestart_flightschool",hasunlockconditions=false}} end
function RegisterEvent(name,fn) events[name]=fn end
function UnregisterEvent(name,fn) if events[name]==fn then events[name]=nil end end
function Pause() pauseDepth=pauseDepth+1 end
function Unpause() pauseDepth=pauseDepth-1; assert(pauseDepth>=0,"Unpause underflow") end
function getElapsedTime() return now end
function getElement() return 1 end
function registerForEvent() end
function unregisterForEvent() end
function GetTextLines(text) return {text} end
function ConvertIntegerString(value) return tostring(value) end
function ConvertTimeString(value) return tostring(value) end
function GetControllerInfo() return "mouseCursor" end
function GetTopRow() return 1 end
function SelectRow() end
function SelectColumn() end
function NewGame(value) report.newGame=value end
function QuitModule() report.quit=(report.quit or 0)+1;exitSequence[#exitSequence+1]="QuitModule" end
function QuitGame() report.quitGame=(report.quitGame or 0)+1;exitSequence[#exitSequence+1]="QuitGame" end
function AddUITriggeredEvent() end
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
function Helper.clearFrame(menu,layer) menu.frames[layer]=nil end
function Helper.setTabScrollCallback(menu) menu.tabCallbacks=(menu.tabCallbacks or 0)+1 end
function Helper.removeAllTabScrollCallbacks(menu) menu.tabCallbacks=0 end
function Helper.addDelayedOneTimeCallbackOnUpdate(fn,block,time) queue[#queue+1]={fn=fn,time=time or now} end
function OpenMenu(name,param,param2) report.openName=name;report.openParam=param;report.openParam2=param2 end
function Helper.closeMenu(menu,dueToClose)
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
 local target
 for _,candidate in ipairs(Menus) do if candidate.name==report.openName then target=candidate;break end end
 assert(target,"unknown mock destination "..tostring(report.openName))
 assert(not gameover or target.name=="OptionsMenu" or target.name=="ScenarioDebriefingMenu","GameOver whitelist rejected destination")
 target.param=report.openParam;target.param2=report.openParam2
 if target.param2 and target.param2[1]=="restore" then target.param2=target.param2[3] end
 target.shown=true;target.onShowMenu();return target
end
local function drain()
 for pass=1,12 do
  if #queue==0 then return end
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
assert(loadfile(ROOT.."campaign_integration.lua"))()
drain()
check("all four runtime Lua files install",function() assert(ConcordantEden.selectionReady and ConcordantEden.debriefReady and options.concordantEdenHook) end)
check("result frames request without consuming pending",function() enterOwn();assert(pauseDepth==1);assert(data.concordant_eden_pending_result=="1");assert(native.infoFrame and native.info2Frame) end)
check("pending waits for both frames",function() native.viewCreated(5);assert(data.concordant_eden_pending_result=="1");native.viewCreated(4);assert(data.concordant_eden_pending_result=="0") end)
check("forced-close result closes without navigating",function() local n=#frames;forceClose();assert(#frames==n,"forced close rebuilt frames") end)
check("same-host result to selection to result balances Pause",function() enterOwn();ConcordantEden.showSelection(native);assert(native.shown and pauseDepth==1 and native.scenariosByID[id]);ConcordantEden.showResults(native);assert(native.shown and pauseDepth==1 and native.scenario.id==id);forceClose() end)
check("GameOver selection keeps permitted host",function() gameover=true;enterOwn();ConcordantEden.showSelection(native);assert(native.name=="ScenarioDebriefingMenu" and native.shown and pauseDepth==1);gameover=false;local n=#frames;forceClose();assert(#frames==n,"selection forced close navigated") end)
check("official module delegates original methods",function() currentModule="official_test";native.param={0,0};local before=originalCalls;native.onShowMenu();native.onTimelinesRankingsReceived();native.cleanup();assert(originalCalls-before==10011,"native delegation mismatch: "..(originalCalls-before)) end)
check("repeated page switches do not accumulate TabScroll",function() enterOwn();for n=1,4 do ConcordantEden.showSelection(native);assert((native.tabCallbacks or 0)==1,"duplicate TabScroll");ConcordantEden.showResults(native);assert((native.tabCallbacks or 0)==0,"TabScroll not removed") end;forceClose() end)
check("start requests expected gamestart after source cleanup",function() enterOwn();ConcordantEden.startMission(native,id);assert(native.starting and data.concordant_eden_pending_result=="0");drain();assert(report.newGame==id and not native.shown and pauseDepth==0) end)
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
local failures=0;for _,line in ipairs(checks) do if line:sub(1,4)=="FAIL" then failures=failures+1 end end
return table.concat(checks,"\n").."\nCHECKS="..#checks.." FAILURES="..failures.." PAUSE_DEPTH="..pauseDepth
