[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) {
    & (Join-Path $PSScriptRoot 'Setup-PixelRPG.ps1')
}
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) {
        $godot = $command.Source
    } else {
        $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $bundled) { throw '找不到 Godot；請先執行 Fetch-Godot.ps1。' }
        $godot = $bundled.FullName
    }
}

& $python (Join-Path $projectRoot 'scripts\validate_content.py') --release
if ($LASTEXITCODE -ne 0) { throw 'Release gate 失敗，已停止匯出。' }
& $python (Join-Path $projectRoot 'scripts\audit_release.py')
if ($LASTEXITCODE -ne 0) { throw '離線／匯出邊界稽核失敗，已停止匯出。' }
& $python (Join-Path $projectRoot 'scripts\generate_license_report.py')
New-Item -ItemType Directory -Path (Join-Path $projectRoot 'build') -Force | Out-Null
Push-Location $projectRoot
try {
    & $godot --headless --path . --export-release 'Windows Desktop' 'build\Mistfall-Bell-Seasons.exe'
    if ($LASTEXITCODE -ne 0) { throw 'Godot 匯出失敗；請確認已安裝 4.7.2 export templates。' }
} finally {
    Pop-Location
}
& $python (Join-Path $projectRoot 'scripts\audit_release.py') --build-dir (Join-Path $projectRoot 'build')
if ($LASTEXITCODE -ne 0) { throw '匯出後成品稽核失敗。' }
Write-Host "完成：$projectRoot\build\Mistfall-Bell-Seasons.exe"
