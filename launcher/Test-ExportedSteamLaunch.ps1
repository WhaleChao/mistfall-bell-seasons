[CmdletBinding()]
param(
    [string]$BuildDirectory = '',
    [ValidateRange(120, 1800)][int]$QuitAfterFrames = 360,
    [string]$ReportPath = '',
    [switch]$UseDummyAudio
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = if ($BuildDirectory) { (Resolve-Path -LiteralPath $BuildDirectory).Path } else { Join-Path $projectRoot 'build' }
$game = Join-Path $buildRoot 'Mistfall-Bell-Seasons.exe'
if (-not (Test-Path -LiteralPath $game)) { throw '找不到正式 Windows EXE。' }

Add-Type -AssemblyName System.Windows.Forms
if (-not ('PixelRPGSteamWindowProbe' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class PixelRPGSteamWindowProbe {
    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
}
'@
}

$runRoot = Join-Path $projectRoot 'work\exported-steam-launch'
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null
$runId = [Guid]::NewGuid().ToString('N')
$isolatedRoot = Join-Path $runRoot "appdata-$runId"
New-Item -ItemType Directory -Path $isolatedRoot | Out-Null
$stdoutPath = Join-Path $runRoot "$runId.stdout.txt"
$stderrPath = Join-Path $runRoot "$runId.stderr.txt"
$arguments = @('--quit-after', "$QuitAfterFrames")
if ($UseDummyAudio) { $arguments = @('--audio-driver', 'Dummy') + $arguments }
$process = Start-Process -FilePath $game `
    -ArgumentList $arguments `
    -PassThru `
    -Environment @{
        APPDATA = $isolatedRoot
        LOCALAPPDATA = $isolatedRoot
        SteamTenfoot = '1'
    } `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath

$windowHandle = [IntPtr]::Zero
$windowRect = $null
$screenBounds = $null
$windowWidth = 0
$windowHeight = 0
$coversScreen = $false
for ($attempt = 0; $attempt -lt 100 -and -not $process.HasExited; $attempt += 1) {
    $process.Refresh()
    if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
        $windowHandle = $process.MainWindowHandle
        $rect = [PixelRPGSteamWindowProbe+RECT]::new()
        if ([PixelRPGSteamWindowProbe]::GetWindowRect($windowHandle, [ref]$rect)) {
            $windowRect = $rect
            $screenBounds = [System.Windows.Forms.Screen]::FromHandle($windowHandle).Bounds
            $windowWidth = $windowRect.Right - $windowRect.Left
            $windowHeight = $windowRect.Bottom - $windowRect.Top
            $coversScreen = $windowWidth -ge $screenBounds.Width -and $windowHeight -ge $screenBounds.Height
            if ($coversScreen) { break }
        }
    }
    Start-Sleep -Milliseconds 100
}
if (-not $process.HasExited -and -not $process.WaitForExit(15000)) {
    $process.Kill()
    $process.WaitForExit()
    throw 'Steam Big Picture 正式 EXE 測試逾時。'
}
$output = @()
if (Test-Path -LiteralPath $stdoutPath) { $output += Get-Content -LiteralPath $stdoutPath }
if (Test-Path -LiteralPath $stderrPath) { $output += Get-Content -LiteralPath $stderrPath }
$joined = $output -join "`n"
if ($process.ExitCode -ne 0 -or $joined -match 'SCRIPT ERROR|Parse Error|Compile Error|Failed to load|ERROR:') {
    throw "Steam Big Picture 正式 EXE 啟動失敗：`n$joined"
}
if ($windowHandle -eq [IntPtr]::Zero -or $null -eq $windowRect -or $null -eq $screenBounds) {
    throw '沒有觀察到正式 EXE 的可見主視窗。'
}
if (-not $coversScreen) {
    throw "SteamTenfoot 未產生全螢幕視窗：window=${windowWidth}x${windowHeight}, screen=$($screenBounds.Width)x$($screenBounds.Height)"
}

$resolvedReport = if ($ReportPath) { $ReportPath } else { Join-Path $projectRoot 'reports\steam_candidate\exported_launch.json' }
$reportParent = Split-Path -Parent $resolvedReport
if ($reportParent) { New-Item -ItemType Directory -Path $reportParent -Force | Out-Null }
$report = [ordered]@{
    passed = $true
    tested_at = (Get-Date).ToString('o')
    executable = $game
    exe_sha256 = (Get-FileHash -LiteralPath $game -Algorithm SHA256).Hash.ToLowerInvariant()
    steam_tenfoot = '1'
    audio_driver = if ($UseDummyAudio) { 'Dummy' } else { 'default' }
    exit_code = $process.ExitCode
    window = [ordered]@{ left = $windowRect.Left; top = $windowRect.Top; width = $windowWidth; height = $windowHeight }
    monitor = [ordered]@{ left = $screenBounds.Left; top = $screenBounds.Top; width = $screenBounds.Width; height = $screenBounds.Height }
    covers_monitor = $coversScreen
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $resolvedReport -Encoding utf8NoBOM
Write-Host "SteamTenfoot 正式 EXE 全螢幕啟動通過：window ${windowWidth}x${windowHeight} / monitor $($screenBounds.Width)x$($screenBounds.Height)。"
