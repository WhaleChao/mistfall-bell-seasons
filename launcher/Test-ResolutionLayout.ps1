[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot console executable；請先執行 Fetch-Godot.ps1。' }
    $godot = $bundled.FullName
}
Push-Location $projectRoot
try {
    Invoke-GodotGate -GodotPath $godot -Label '多解析度畫面閘門' -Arguments @('--path', '.', '--rendering-method', 'gl_compatibility', '--position', '4000,4000', '--script', 'res://tests/godot/resolution_layout_test.gd')
} finally {
    Pop-Location
}
Write-Host "多解析度報告：$projectRoot\reports\resolution_layout\REPORT.md"
