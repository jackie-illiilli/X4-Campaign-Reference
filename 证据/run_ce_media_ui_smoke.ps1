$ErrorActionPreference = 'Stop'
$gameRoot = 'C:\Program Files (x86)\Steam\steamapps\common\X4 Foundations'
$sourcePath = Join-Path $PSScriptRoot 'ce_media_ui_smoke.lua'
$previousCurrentDirectory = [Environment]::CurrentDirectory
[Environment]::CurrentDirectory = $gameRoot
$dllPath = (Join-Path $gameRoot 'lua51_64.dll').Replace('\', '\\')
$interop = @"
using System;
using System.Runtime.InteropServices;
public static class ConcordantOfflineLua {
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr luaL_newstate();
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern void luaL_openlibs(IntPtr state);
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern int luaL_loadbuffer(IntPtr state, byte[] bytes, UIntPtr length, string name);
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern int lua_pcall(IntPtr state,int args,int results,int errorfunction);
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern IntPtr lua_tolstring(IntPtr state,int index,out UIntPtr length);
 [DllImport("$dllPath", CallingConvention=CallingConvention.Cdecl)] public static extern void lua_close(IntPtr state);
}
"@
Add-Type -TypeDefinition $interop
$state = [ConcordantOfflineLua]::luaL_newstate()
try {
 [ConcordantOfflineLua]::luaL_openlibs($state)
 $source = [IO.File]::ReadAllBytes($sourcePath)
 $status = [ConcordantOfflineLua]::luaL_loadbuffer($state,$source,[UIntPtr]::new($source.Length),'ce_media_ui_smoke.lua')
 if ($status -eq 0) { $status = [ConcordantOfflineLua]::lua_pcall($state,0,1,0) }
 $length=[UIntPtr]::Zero
 $pointer=[ConcordantOfflineLua]::lua_tolstring($state,-1,[ref]$length)
 $buffer=New-Object byte[] ([int]$length.ToUInt64())
 [Runtime.InteropServices.Marshal]::Copy($pointer,$buffer,0,$buffer.Length)
 $result=[Text.Encoding]::UTF8.GetString($buffer)
 if ($status -ne 0) { throw $result }
 Write-Output $result
 if ($result -notmatch 'FAILURES=0(?:\s|$)') { throw 'Offline UI smoke checks failed.' }
} finally {
 [ConcordantOfflineLua]::lua_close($state)
 [Environment]::CurrentDirectory = $previousCurrentDirectory
}
