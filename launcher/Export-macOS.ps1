[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION 格式錯誤：$version" }

$venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
$python = if (Test-Path -LiteralPath $venvPython) { $venvPython } else { (Get-Command python -ErrorAction Stop).Source }
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot 4.7.2 console；請先執行 Fetch-Godot.ps1。' }
    $godot = $bundled.FullName
}

$template = Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable\macos.zip'
if (-not (Test-Path -LiteralPath $template)) {
    & (Join-Path $PSScriptRoot 'Fetch-ExportTemplates.ps1')
}
if (-not (Test-Path -LiteralPath $template)) { throw '找不到 Godot 4.7.2 macOS Universal 官方匯出模板。' }

& $python (Join-Path $projectRoot 'scripts\validate_content.py') --release
if ($LASTEXITCODE -ne 0) { throw 'Release 內容閘門失敗，已停止 macOS 匯出。' }
& $python (Join-Path $projectRoot 'scripts\audit_release.py')
if ($LASTEXITCODE -ne 0) { throw '離線／匯出邊界稽核失敗，已停止 macOS 匯出。' }

$buildRoot = Join-Path $projectRoot 'build'
$archive = Join-Path $buildRoot 'Mistfall-Bell-Seasons-macOS.zip'
New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Push-Location $projectRoot
try {
    Invoke-GodotGate -GodotPath $godot -Label 'Godot macOS Universal release 匯出' -Arguments @('--headless', '--path', '.', '--export-release', 'macOS Universal', 'build/Mistfall-Bell-Seasons-macOS.zip')
} finally {
    Pop-Location
}
if (-not (Test-Path -LiteralPath $archive)) { throw 'Godot 沒有產生 macOS ZIP。' }
& $python (Join-Path $projectRoot 'scripts\audit_macos_archive.py') $archive --version $version --report (Join-Path $projectRoot 'reports\macos_archive\cross_export.json')
if ($LASTEXITCODE -ne 0) { throw 'macOS Universal ZIP 結構／架構／PCK 邊界稽核失敗。' }
Write-Host "macOS Universal 交叉匯出完成：$archive"
