param([string]$GameRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../..')).Path)
$ErrorActionPreference = 'Stop'
$mod = Join-Path $GameRoot 'extensions/gatefall_chronicles'
$output = Join-Path $PSScriptRoot '../证据'
[void][IO.Directory]::CreateDirectory($output)
$utf8 = New-Object Text.UTF8Encoding($true)
function Read-Xml([string]$Path) {
    $doc = New-Object Xml.XmlDocument
    $doc.Load($Path)
    return ,$doc
}
function Get-Cue($Node) {
    $p = $Node.ParentNode
    while ($p -and $p.LocalName -notin @('cue','library')) { $p = $p.ParentNode }
    if ($p) { return $p.GetAttribute('name') }
    return ''
}
$parseErrors = @()
$all = @(Get-ChildItem -LiteralPath $mod -Filter '*.xml' -Recurse)
foreach ($f in $all) {
    try { $null = Read-Xml $f.FullName } catch { $parseErrors += "$($f.FullName): $($_.Exception.Message)" }
}
$missions = @()
$calls = @()
foreach ($f in Get-ChildItem -LiteralPath (Join-Path $mod 'md') -Filter 'gatefall_scenario_*.xml' | Sort-Object Name) {
    $x = Read-Xml $f.FullName
    $speech = @($x.SelectNodes('//speak'))
    $ends = @($x.SelectNodes('//event_speak_finished'))
    $missions += [pscustomobject]@{
        File=$f.Name; Cues=$x.SelectNodes('//cue').Count; Speak=$speech.Count
        SpeakEnd=$ends.Count
        SpeakEndPages=(@($ends | ForEach-Object { $_.GetAttribute('page') } | Sort-Object -Unique) -join ',')
        Cutscene=$x.SelectNodes('//play_cutscene').Count
        CutsceneEnd=$x.SelectNodes('//event_cutscene_stopped').Count
        ActorSequence=$x.SelectNodes('//start_actor_sequence').Count
    }
    foreach ($n in $x.SelectNodes('//play_cutscene')) {
        $calls += [pscustomobject]@{
            File=$f.Name; Cue=(Get-Cue $n); Key=$n.GetAttribute('key').Trim("'")
            Result=$n.GetAttribute('result')
            Parameters=(@($n.SelectNodes('param') | ForEach-Object { $_.OuterXml }) -join ' ')
        }
    }
}
$cameras = @()
$keys = @{}
foreach ($f in Get-ChildItem -LiteralPath (Join-Path $mod 'cutscenes') -Filter '*.xml' | Sort-Object Name) {
    $x = Read-Xml $f.FullName
    foreach ($dir in $x.SelectNodes('//director')) { $keys[$dir.GetAttribute('key')] = $f.Name }
    foreach ($shot in $x.SelectNodes('//shot')) {
        $sequence = $shot.ParentNode.GetAttribute('name')
        $cam = $shot.SelectSingleNode('*[name()="camera" or starts-with(name(), "camera_")]')
        $cameras += [pscustomobject]@{
            File=$f.Name; Sequence=$sequence; Shot=$shot.GetAttribute('name')
            Duration=$shot.GetAttribute('duration')
            Camera= $(if ($cam) {$cam.OuterXml} else {''})
        }
    }
}
$missingKeys = @($calls | Where-Object { $_.Key -like 'gatefall_*' -and -not $keys.ContainsKey($_.Key) })
$languages = @{}
$duplicates = @()
foreach ($lang in @('044','086')) {
    $set = @{}
    foreach ($textFile in Get-ChildItem -LiteralPath (Join-Path $mod 't') -Filter "*-L$lang.xml") {
        $x = Read-Xml $textFile.FullName
        foreach ($page in $x.SelectNodes('//page')) {
            foreach ($entry in $page.SelectNodes('t')) {
                $key = $page.GetAttribute('id') + ',' + $entry.GetAttribute('id')
                if ($set.ContainsKey($key)) { $duplicates += "$lang/$key" }
                $set[$key] = $true
            }
        }
    }
    $languages[$lang] = $set
}
$languageDiff = @()
foreach ($lang in @('044','086')) {
    $other = if ($lang -eq '044') {'086'} else {'044'}
    foreach ($key in $languages[$lang].Keys) {
        if (-not $languages[$other].ContainsKey($key)) { $languageDiff += "$lang only: $key" }
    }
}
$schemaFindings = New-Object 'System.Collections.Generic.List[string]'
function Test-XmlSchema($Files, $Schemas) {
    foreach ($f in $Files) {
        $settings = New-Object Xml.XmlReaderSettings
        $settings.Schemas = $Schemas
        $settings.ValidationType = [Xml.ValidationType]::Schema
        $fileName = $f.Name
        $settings.add_ValidationEventHandler([Xml.Schema.ValidationEventHandler]{
            param($sender, $e)
            $schemaFindings.Add($fileName + ': ' + $e.Message)
        })
        $reader = [Xml.XmlReader]::Create($f.FullName, $settings)
        try { while ($reader.Read()) {} } finally { $reader.Dispose() }
    }
}
$mdSchemas = New-Object Xml.Schema.XmlSchemaSet
$mdSchemas.XmlResolver = New-Object Xml.XmlUrlResolver
$null = $mdSchemas.Add($null, (Join-Path $GameRoot 'GatefallChronicles/参考资料/基础游戏/md/md.xsd'))
$mdSchemas.Compile()
Test-XmlSchema (Get-ChildItem -LiteralPath (Join-Path $mod 'md') -Filter '*.xml') $mdSchemas
# Read the current base-game cutscene schema directly from its catalog; never modify game data.
$offset = 0L
$schemaSource = $null
$stream = [IO.File]::OpenRead((Join-Path $GameRoot '08.dat'))
try {
    foreach ($line in [IO.File]::ReadLines((Join-Path $GameRoot '08.cat'))) {
        if ($line -match '^(.*) ([0-9]+) ([0-9]+) ([0-9a-f]{32})$') {
            $path = $matches[1]; $length = [int]$matches[2]
            if ($path -eq 'cutscenes/cutscenes.xsd') {
                $null = $stream.Seek($offset, [IO.SeekOrigin]::Begin)
                $bytes = New-Object byte[] $length
                $read = 0
                while ($read -lt $length) {
                    $n = $stream.Read($bytes, $read, $length - $read)
                    if ($n -eq 0) { throw 'Unexpected end of 08.dat' }
                    $read += $n
                }
                $schemaSource = [Text.Encoding]::UTF8.GetString($bytes)
                break
            }
            $offset += $length
        }
    }
} finally { $stream.Dispose() }
if (-not $schemaSource) { throw 'cutscenes/cutscenes.xsd not found in 08.cat; update the catalog lookup for this game version.' }
$cutsceneSchemas = New-Object Xml.Schema.XmlSchemaSet
$stringReader = New-Object IO.StringReader($schemaSource)
$schemaReader = [Xml.XmlReader]::Create($stringReader)
try { $null = $cutsceneSchemas.Add($null, $schemaReader) } finally { $schemaReader.Dispose(); $stringReader.Dispose() }
$cutsceneSchemas.Compile()
Test-XmlSchema (Get-ChildItem -LiteralPath (Join-Path $mod 'cutscenes') -Filter '*.xml') $cutsceneSchemas
$report = [ordered]@{
    Generated=(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK'); Scope='Static XML only; no game runtime validation'
    XmlFiles=$all.Count; ParseErrors=$parseErrors; SchemaFindings=@($schemaFindings.ToArray()); Missions=$missions
    MissingLocalCutsceneKeys=$missingKeys; DuplicateTextEntries=$duplicates
    LanguageDifferences=$languageDiff; CutsceneCalls=$calls; Shots=$cameras
}
[IO.File]::WriteAllText((Join-Path $output 'campaign_static_audit.json'), ($report | ConvertTo-Json -Depth 8), $utf8)
$rows = @('# 八关静态扫描', '', '此文件由 tools/audit_campaign.ps1 生成。计数是 XML 节点数，不等于运行次数；不验证构图、可见性、时序或游戏内效果。', '', '| MD 文件 | cue | speak | speak 完成监听 | 监听 page | 镜头调用 | 镜头停止监听 | 角色动画 |', '| --- | ---: | ---: | ---: | --- | ---: | ---: | ---: |')
foreach ($m in $missions) { $rows += "| $($m.File) | $($m.Cues) | $($m.Speak) | $($m.SpeakEnd) | $($m.SpeakEndPages) | $($m.Cutscene) | $($m.CutsceneEnd) | $($m.ActorSequence) |" }
$rows += @('', "XML 文件：$($all.Count)；解析错误：$($parseErrors.Count)；MD 与 cutscene 的 XSD 发现：$($schemaFindings.Count)；本地镜头 key 缺失：$($missingKeys.Count)；重复文本项：$($duplicates.Count)；中英文 ID 差异：$($languageDiff.Count)。", '', 'MD 使用本地解包基础游戏 md.xsd；镜头使用当前 08.cat / 08.dat 中的 cutscenes.xsd。只验证这两类 XML 的 schema，不等于验证全部 diff 的合并结果。', '', '逐个镜头的 XML、调用 cue 和参数见同目录 campaign_static_audit.json。')
if ($schemaFindings.Count) { $rows += @('', '## XSD 发现', '') + @($schemaFindings | ForEach-Object { '- ' + $_ }) }
if ($languageDiff.Count) { $rows += @('', '## 中英文差异', '') + @($languageDiff | Sort-Object | ForEach-Object { '- ' + $_ }) }
[IO.File]::WriteAllText((Join-Path $output '八关静态扫描.md'), ($rows -join "`r`n"), $utf8)
$missions | Format-Table -AutoSize
Write-Output "XML=$($all.Count), ParseErrors=$($parseErrors.Count), SchemaFindings=$($schemaFindings.Count), MissingCutscenes=$($missingKeys.Count), DuplicateText=$($duplicates.Count), LanguageDifferences=$($languageDiff.Count)"
