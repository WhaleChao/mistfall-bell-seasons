[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot console executable；請先執行 Fetch-Godot.ps1。' }
    $godot = $bundled.FullName
}
Push-Location $projectRoot
try {
    & $godot --path . --rendering-method gl_compatibility --resolution 1920x1080 --script res://tests/godot/render_performance_test.gd
    if ($LASTEXITCODE -ne 0) { throw '1080p／20 敵人 render gate 失敗。' }
} finally {
    Pop-Location
}
Write-Host "效能報告：$projectRoot\reports\render_performance.json"
