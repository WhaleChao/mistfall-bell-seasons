[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot console executable。' }
    $godot = $bundled.FullName
}

$runRoot = Join-Path $projectRoot 'work\multiplayer-acceptance'
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
function Start-Probe([string]$scenarioRoot, [int]$port, [string]$farmMode, [string]$relationshipMode, [string]$role, [string]$probeRole, [string]$name, [int]$expectedClients, [string]$probeMode) {
    $roleRoot = Join-Path $scenarioRoot $role
    New-Item -ItemType Directory -Path $roleRoot -Force | Out-Null
    $report = Join-Path $roleRoot 'report.json'
    $stdout = Join-Path $roleRoot 'stdout.txt'
    $stderr = Join-Path $roleRoot 'stderr.txt'
    $arguments = @('--headless', '--path', $projectRoot, '--script', 'res://tests/godot/multiplayer_probe.gd', '--', "--probe-role=$probeRole", "--port=$port", "--report=$report", "--name=$name", "--expected-clients=$expectedClients", "--farm-mode=$farmMode", "--relationship-mode=$relationshipMode", "--probe-mode=$probeMode")
    $process = Start-Process -FilePath $godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -Environment @{ APPDATA = $roleRoot; LOCALAPPDATA = $roleRoot } -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    return [pscustomobject]@{ Role=$role; Process=$process; Report=$report; Stdout=$stdout; Stderr=$stderr }
}

$usedPorts = @{}
function New-TestPort() {
    do { $candidate = Get-Random -Minimum 28200 -Maximum 30200 } while ($usedPorts.ContainsKey($candidate))
    $usedPorts[$candidate] = $true
    return $candidate
}

function Invoke-MultiplayerScenario([string]$id, [string]$farmMode, [string]$relationshipMode, [int]$clientCount, [string]$probeMode) {
    $scenarioRoot = Join-Path $runRoot $id
    New-Item -ItemType Directory -Path $scenarioRoot -Force | Out-Null
    $port = New-TestPort
    $processes = @()
    $processes += Start-Probe $scenarioRoot $port $farmMode $relationshipMode 'server' 'server' 'Server' $clientCount $probeMode
    Start-Sleep -Milliseconds 600
    for ($index = 0; $index -lt $clientCount; $index++) {
        $role = "client_$($index + 1)"
        $name = if ($probeMode -eq 'world' -and $index -eq 0) { 'ProbeA' } elseif ($probeMode -eq 'world' -and $index -eq 1) { 'ProbeB' } else { "Scale$($index + 1)" }
        $processes += Start-Probe $scenarioRoot $port $farmMode $relationshipMode $role 'client' $name $clientCount $probeMode
    }

    foreach ($entry in $processes) {
        if (-not $entry.Process.WaitForExit(30000)) {
            $entry.Process.Kill()
            $entry.Process.WaitForExit()
            throw "$id/$($entry.Role) 多人連線測試逾時。"
        }
    }

    $summaries = @()
    foreach ($entry in $processes) {
        $output = @(
            if (Test-Path -LiteralPath $entry.Stdout) { Get-Content -LiteralPath $entry.Stdout -Raw }
            if (Test-Path -LiteralPath $entry.Stderr) { Get-Content -LiteralPath $entry.Stderr -Raw }
        ) -join "`n"
        if ($entry.Process.ExitCode -ne 0 -or $output -match '(?m)SCRIPT ERROR:|ERROR:') {
            throw "$id/$($entry.Role) 多人連線程序失敗（exit $($entry.Process.ExitCode)）：`n$output"
        }
        if (-not (Test-Path -LiteralPath $entry.Report)) { throw "$id/$($entry.Role) 未產生多人連線報告。" }
        $report = Get-Content -LiteralPath $entry.Report -Raw | ConvertFrom-Json
        if (-not $report.passed) { throw "$id/$($entry.Role) 驗收失敗：$($report.failures -join '；')" }
        $summaries += $report
    }
    Write-Host "多人情境通過：$id（$clientCount 名玩家，$farmMode／$relationshipMode），UDP $port。"
    return [ordered]@{ id=$id; farm_mode=$farmMode; relationship_mode=$relationshipMode; player_count=$clientCount; port=$port; topology="1 dedicated server + $clientCount clients"; probe_mode=$probeMode; processes=$summaries }
}

$scenarios = @(
    [ordered]@{ id='shared'; farm='shared'; relationship='independent' },
    [ordered]@{ id='private'; farm='private'; relationship='independent' },
    [ordered]@{ id='competitive'; farm='competitive'; relationship='competitive' }
)
$scenarioReports = @()

foreach ($scenario in $scenarios) {
    $scenarioReports += Invoke-MultiplayerScenario $scenario.id $scenario.farm $scenario.relationship 2 'world'
}

$storyScalingReports = @()
foreach ($playerCount in @(1, 3, 5)) {
    $storyScalingReports += Invoke-MultiplayerScenario "story_$playerCount" 'shared' 'independent' $playerCount 'story'
}

$evidencePath = Join-Path $projectRoot 'reports\multiplayer_acceptance.json'
$evidence = [ordered]@{
    schema_version = 2
    generated_at = [DateTime]::UtcNow.ToString('o')
    result = 'PASS'
    transport = 'Godot ENet UDP'
    topology = '6 dedicated servers + 15 clients across world-mode and player-count scenarios'
    world_mode_scenarios = $scenarioReports
    story_scaling_scenarios = $storyScalingReports
}
$evidence | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $evidencePath -Encoding utf8
Write-Host '多人連線全情境實測通過：共同、私人、競賽農場與 1／2／3／5 人劇情拓撲，共 6 台專用伺服器 + 15 個客戶端；版本握手、權威移動、農場隔離／整合、戀愛制度、劇情切換與世界存檔均 PASS。'
Write-Host "證據：$evidencePath"
