[CmdletBinding()]
param(
    [string]$BuildDirectory = '',
    [ValidateRange(300, 3600)][int]$QuitAfterFrames = 600,
    [string]$ReportPath = '',
    [switch]$UseDummyAudio
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = if ($BuildDirectory) { (Resolve-Path -LiteralPath $BuildDirectory).Path } else { Join-Path $projectRoot 'build' }
$game = Join-Path $buildRoot 'Mistfall-Bell-Seasons.exe'
$pck = Join-Path $buildRoot 'Mistfall-Bell-Seasons.pck'
if (-not (Test-Path -LiteralPath $game) -or -not (Test-Path -LiteralPath $pck)) {
    throw '找不到完整 Windows 發行檔（EXE + PCK）。'
}
$smokeRoot = Join-Path $projectRoot 'work\export-smoke'
New-Item -ItemType Directory -Path $smokeRoot -Force | Out-Null
$runId = [Guid]::NewGuid().ToString('N')
$stdoutPath = Join-Path $smokeRoot "$runId.stdout.txt"
$stderrPath = Join-Path $smokeRoot "$runId.stderr.txt"
$networkConnections = @()
$networkSamples = 0
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$isolatedUserRoot = Join-Path $smokeRoot 'appdata'
New-Item -ItemType Directory -Path $isolatedUserRoot -Force | Out-Null
$env:APPDATA = $isolatedUserRoot
$env:LOCALAPPDATA = $isolatedUserRoot
try {
    $arguments = @('--headless', '--quit-after', "$QuitAfterFrames")
    if ($UseDummyAudio) { $arguments = @('--audio-driver', 'Dummy') + $arguments }
    $process = Start-Process -FilePath $game `
        -ArgumentList $arguments `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath
    while (-not $process.HasExited -and $networkSamples -lt 100) {
        $networkSamples += 1
        $networkConnections += @(Get-NetTCPConnection -OwningProcess $process.Id -ErrorAction SilentlyContinue | ForEach-Object {
            [ordered]@{ protocol = 'TCP'; state = [string]$_.State; local = "$($_.LocalAddress):$($_.LocalPort)"; remote = "$($_.RemoteAddress):$($_.RemotePort)" }
        })
        $networkConnections += @(Get-NetUDPEndpoint -OwningProcess $process.Id -ErrorAction SilentlyContinue | ForEach-Object {
            [ordered]@{ protocol = 'UDP'; state = ''; local = "$($_.LocalAddress):$($_.LocalPort)"; remote = '' }
        })
        Start-Sleep -Milliseconds 100
    }
    if (-not $process.HasExited -and -not $process.WaitForExit(15000)) {
        $process.Kill()
        $process.WaitForExit()
        throw '匯出的遊戲啟動 smoke test 逾時。'
    }
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
}
$output = @()
if (Test-Path -LiteralPath $stdoutPath) { $output += Get-Content -LiteralPath $stdoutPath }
if (Test-Path -LiteralPath $stderrPath) { $output += Get-Content -LiteralPath $stderrPath }
$output | Write-Host
$joined = $output -join "`n"
if ($process.ExitCode -ne 0 -or $joined -match 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load|ERROR:') {
    throw '匯出的遊戲啟動 smoke test 失敗。'
}
$uniqueConnections = @($networkConnections | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 5 } | Sort-Object -Unique | ForEach-Object { $_ | ConvertFrom-Json })
if ($networkSamples -lt 3) { throw "執行期網路觀測樣本不足：$networkSamples" }
if ($uniqueConnections.Count -gt 0) {
    throw "正式遊戲執行時建立了網路端點：$($uniqueConnections | ConvertTo-Json -Compress -Depth 5)"
}
$venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
$python = if (Test-Path -LiteralPath $venvPython) { $venvPython } else { (Get-Command python -ErrorAction Stop).Source }
& $python (Join-Path $projectRoot 'scripts\audit_release.py') --build-dir $buildRoot
if ($LASTEXITCODE -ne 0) { throw '匯出成品稽核失敗。' }
$resolvedReportPath = if ($ReportPath) { $ReportPath } else { Join-Path $projectRoot 'reports\exported_build_runtime.json' }
$reportParent = Split-Path -Parent $resolvedReportPath
if ($reportParent) { New-Item -ItemType Directory -Path $reportParent -Force | Out-Null }
$report = [ordered]@{
    passed = $true
    tested_at = (Get-Date).ToString('o')
    os = [Environment]::OSVersion.VersionString
    build_directory = $buildRoot
    quit_after_frames = $QuitAfterFrames
    audio_driver = if ($UseDummyAudio) { 'Dummy' } else { 'default' }
    exit_code = $process.ExitCode
    network_samples = $networkSamples
    network_endpoints = @($uniqueConnections)
    exe_sha256 = (Get-FileHash -LiteralPath $game -Algorithm SHA256).Hash.ToLowerInvariant()
    pck_sha256 = (Get-FileHash -LiteralPath $pck -Algorithm SHA256).Hash.ToLowerInvariant()
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedReportPath -Encoding utf8NoBOM
Write-Host "匯出遊戲啟動、PCK 邊界與執行期零網路端點驗證通過（$networkSamples 個觀測樣本）。"
