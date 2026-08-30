[CmdletBinding()]
param([string]$BuildDirectory = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = if ($BuildDirectory) { (Resolve-Path -LiteralPath $BuildDirectory).Path } else { Join-Path $projectRoot 'build' }
$game = Join-Path $buildRoot 'Mistfall-Bell-Seasons.exe'
$pck = Join-Path $buildRoot 'Mistfall-Bell-Seasons.pck'
if (-not (Test-Path -LiteralPath $game) -or -not (Test-Path -LiteralPath $pck)) {
    throw '找不到完整 Windows 發行檔（EXE + PCK）。'
}
$output = & $game --headless --quit-after 120 2>&1
$output | Write-Host
$joined = $output -join "`n"
if ($LASTEXITCODE -ne 0 -or $joined -match 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load|ERROR:') {
    throw '匯出的遊戲啟動 smoke test 失敗。'
}
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
& $python (Join-Path $projectRoot 'scripts\audit_release.py') --build-dir $buildRoot
if ($LASTEXITCODE -ne 0) { throw '匯出成品稽核失敗。' }
Write-Host '匯出遊戲啟動與離線邊界驗證通過。'
