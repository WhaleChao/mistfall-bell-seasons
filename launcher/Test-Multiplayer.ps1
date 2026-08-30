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
function Start-Probe([string]$scenarioRoot, [int]$port, [string]$farmMode, [string]$relationshipMode, [string]$role, [string]$probeRole, [string]$name) {
    $roleRoot = Join-Path $scenarioRoot $role
    New-Item -ItemType Directory -Path $roleRoot -Force | Out-Null
    $report = Join-Path $roleRoot 'report.json'
    $stdout = Join-Path $roleRoot 'stdout.txt'
    $stderr = Join-Path $roleRoot 'stderr.txt'
    $arguments = @('--headless', '--path', $projectRoot, '--script', 'res://tests/godot/multiplayer_probe.gd', '--', "--probe-role=$probeRole", "--port=$port", "--report=$report", "--name=$name", '--expected-clients=2', "--farm-mode=$farmMode", "--relationship-mode=$relationshipMode")
    $process = Start-Process -FilePath $godot -ArgumentList $arguments -PassThru -WindowStyle Hidden -Environment @{ APPDATA = $roleRoot; LOCALAPPDATA = $roleRoot } -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    return [pscustomobject]@{ Role=$role; Process=$process; Report=$report; Stdout=$stdout; Stderr=$stderr }
}

$scenarios = @(
    [ordered]@{ id='shared'; farm='shared'; relationship='independent' },
    [ordered]@{ id='private'; farm='private'; relationship='independent' },
    [ordered]@{ id='competitive'; farm='competitive'; relationship='competitive' }
)
$scenarioReports = @()

foreach ($scenario in $scenarios) {
    $scenarioRoot = Join-Path $runRoot $scenario.id
    New-Item -ItemType Directory -Path $scenarioRoot -Force | Out-Null
    $port = Get-Random -Minimum 28200 -Maximum 30200
    $processes = @()
    $processes += Start-Probe $scenarioRoot $port $scenario.farm $scenario.relationship 'server' 'server' 'Server'
    Start-Sleep -Milliseconds 600
    $processes += Start-Probe $scenarioRoot $port $scenario.farm $scenario.relationship 'client_a' 'client' 'ProbeA'
    $processes += Start-Probe $scenarioRoot $port $scenario.farm $scenario.relationship 'client_b' 'client' 'ProbeB'

    foreach ($entry in $processes) {
        if (-not $entry.Process.WaitForExit(30000)) {
            $entry.Process.Kill()
            $entry.Process.WaitForExit()
            throw "$($scenario.id)/$($entry.Role) 多人連線測試逾時。"
        }
    }

    $summaries = @()
    foreach ($entry in $processes) {
        $output = @(
            if (Test-Path -LiteralPath $entry.Stdout) { Get-Content -LiteralPath $entry.Stdout -Raw }
            if (Test-Path -LiteralPath $entry.Stderr) { Get-Content -LiteralPath $entry.Stderr -Raw }
        ) -join "`n"
        if ($entry.Process.ExitCode -ne 0 -or $output -match '(?m)SCRIPT ERROR:|ERROR:') {
            throw "$($scenario.id)/$($entry.Role) 多人連線程序失敗（exit $($entry.Process.ExitCode)）：`n$output"
        }
        if (-not (Test-Path -LiteralPath $entry.Report)) { throw "$($scenario.id)/$($entry.Role) 未產生多人連線報告。" }
        $report = Get-Content -LiteralPath $entry.Report -Raw | ConvertFrom-Json
        if (-not $report.passed) { throw "$($scenario.id)/$($entry.Role) 驗收失敗：$($report.failures -join '；')" }
        $summaries += $report
    }
    $scenarioReports += [ordered]@{ id=$scenario.id; farm_mode=$scenario.farm; relationship_mode=$scenario.relationship; port=$port; topology='1 dedicated server + 2 clients'; processes=$summaries }
    Write-Host "多人情境通過：$($scenario.id)（$($scenario.farm)／$($scenario.relationship)），UDP $port。"
}

$evidencePath = Join-Path $projectRoot 'reports\multiplayer_acceptance.json'
$evidence = [ordered]@{
    schema_version = 1
    generated_at = [DateTime]::UtcNow.ToString('o')
    result = 'PASS'
    transport = 'Godot ENet UDP'
    topology = '3 scenarios × (1 dedicated server + 2 clients)'
    scenarios = $scenarioReports
}
$evidence | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $evidencePath -Encoding utf8
Write-Host '多人連線全情境實測通過：共同整合、私人獨立、私人競賽三種農場制度，共 3 台專用伺服器 + 6 個客戶端；版本握手、移動快照、雙人劇情、戀愛制度與世界存檔均 PASS。'
Write-Host "證據：$evidencePath"
