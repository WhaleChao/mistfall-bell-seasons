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
$smokeRoot = Join-Path $projectRoot 'work\export-smoke'
New-Item -ItemType Directory -Path $smokeRoot -Force | Out-Null
$runId = [Guid]::NewGuid().ToString('N')
$stdoutPath = Join-Path $smokeRoot "$runId.stdout.txt"
$stderrPath = Join-Path $smokeRoot "$runId.stderr.txt"
$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$isolatedUserRoot = Join-Path $smokeRoot 'appdata'
New-Item -ItemType Directory -Path $isolatedUserRoot -Force | Out-Null
$env:APPDATA = $isolatedUserRoot
$env:LOCALAPPDATA = $isolatedUserRoot
try {
    $process = Start-Process -FilePath $game `
        -ArgumentList @('--headless', '--quit-after', '120') `
        -PassThru `
        -WindowStyle Hidden `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath
    if (-not $process.WaitForExit(15000)) {
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
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
& $python (Join-Path $projectRoot 'scripts\audit_release.py') --build-dir $buildRoot
if ($LASTEXITCODE -ne 0) { throw '匯出成品稽核失敗。' }
Write-Host '匯出遊戲啟動與離線邊界驗證通過。'
