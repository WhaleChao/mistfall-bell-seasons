[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    & (Join-Path $PSScriptRoot 'Setup-PixelRPG.ps1') -WithTestTools
}
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $godotCommand = Get-Command godot -ErrorAction SilentlyContinue
    if ($godotCommand) {
        $godot = $godotCommand.Source
    } else {
        $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $bundled) { throw '找不到 Godot console executable；請先執行 Fetch-Godot.ps1。' }
        $godot = $bundled.FullName
    }
}

& $python (Join-Path $projectRoot 'scripts\validate_content.py') --release
if ($LASTEXITCODE -ne 0) { throw '內容 release gate 失敗。' }
& $python (Join-Path $projectRoot 'scripts\audit_release.py')
if ($LASTEXITCODE -ne 0) { throw '離線／匯出邊界稽核失敗。' }
Push-Location $projectRoot
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousTestIsolation = $env:PIXELRPG_TEST_ISOLATED
$testUserRoot = Join-Path $projectRoot 'work\automated-test-appdata'
New-Item -ItemType Directory -Path $testUserRoot -Force | Out-Null
$env:APPDATA = $testUserRoot
$env:LOCALAPPDATA = $testUserRoot
$env:PIXELRPG_TEST_ISOLATED = '1'
try {
    & $python -m pytest tests\python -q
    if ($LASTEXITCODE -ne 0) { throw 'Python 測試失敗。' }
    Invoke-GodotGate -GodotPath $godot -Label 'Godot editor import 與腳本編譯' -Arguments @('--headless', '--path', '.', '--editor', '--quit')
    Invoke-GodotGate -GodotPath $godot -Label 'Godot smoke test' -Arguments @('--headless', '--path', '.', '--script', 'res://tests/godot/smoke_test.gd')
    Invoke-GodotGate -GodotPath $godot -Label '圖片完整性閘門' -Arguments @('--headless', '--path', '.', '--script', 'res://tests/godot/image_integrity_test.gd')
    Invoke-GodotGate -GodotPath $godot -Label '商業長期／存檔壓力閘門' -Arguments @('--headless', '--path', '.', '--script', 'res://tests/godot/commercial_stress_test.gd')
    Invoke-GodotGate -GodotPath $godot -Label '20 敵人效能閘門' -Arguments @('--headless', '--path', '.', '--script', 'res://tests/godot/performance_test.gd')
} finally {
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:PIXELRPG_TEST_ISOLATED = $previousTestIsolation
    Pop-Location
}
Write-Host 'PixelRPG 所有自動驗證均通過。'
