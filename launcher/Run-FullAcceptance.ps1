[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot 視窗版；請先執行 Fetch-Godot.ps1。' }
    $godot = $bundled.FullName
}

$qaAppData = Join-Path $projectRoot 'work\full-acceptance-appdata'
New-Item -ItemType Directory -Path $qaAppData -Force | Out-Null
$report = Join-Path $projectRoot 'reports\full_feature_acceptance\report.json'
$arguments = @(
    '--path', $projectRoot,
    '--rendering-method', 'gl_compatibility',
    '--resolution', '1280x720',
    '--script', 'res://tests/godot/full_feature_acceptance.gd'
)
$process = Start-Process -FilePath $godot -ArgumentList $arguments -PassThru -Environment @{
    APPDATA = $qaAppData
    LOCALAPPDATA = $qaAppData
}
if (-not $process.WaitForExit(180000)) {
    $process.Kill()
    $process.WaitForExit()
    throw '全功能實機驗收超過 180 秒。'
}
if ($process.ExitCode -ne 0) {
    throw "全功能實機驗收失敗，Godot exit code $($process.ExitCode)。"
}
if (-not (Test-Path -LiteralPath $report)) {
    throw '全功能實機驗收沒有產生報告。'
}
$result = Get-Content -LiteralPath $report -Raw | ConvertFrom-Json
if ($result.failed -ne 0) {
    throw "全功能實機驗收有 $($result.failed) 項失敗。"
}
Write-Host "全功能實機驗收通過：$($result.passed) 項，畫面證據 $($result.screenshots.Count) 張。"
Write-Host "報告：$projectRoot\reports\full_feature_acceptance\REPORT.md"
