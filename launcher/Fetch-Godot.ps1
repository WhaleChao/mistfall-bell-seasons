[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$toolsRoot = Join-Path $projectRoot 'tools'
New-Item -ItemType Directory -Path $toolsRoot -Force | Out-Null
$archive = Join-Path $toolsRoot 'Godot_v4.7.2-stable_win64.exe.zip'
$executable = Join-Path $toolsRoot 'Godot_v4.7.2-stable_win64.exe'
$consoleExecutable = Join-Path $toolsRoot 'Godot_v4.7.2-stable_win64_console.exe'
$url = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip'
$expectedSha512 = '83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993'

if (-not (Test-Path -LiteralPath $executable)) {
    Write-Host '下載 Godot 4.7.2 portable（Windows x64）…'
    Invoke-WebRequest -Uri $url -OutFile $archive
    $actual = (Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash.ToLowerInvariant()
    if ($actual -ne $expectedSha512) {
        Remove-Item -LiteralPath $archive -Force
        throw "Godot checksum 不符；已刪除下載檔。實際值：$actual"
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $toolsRoot
}

if (-not (Test-Path -LiteralPath $executable)) {
    throw 'Godot 壓縮檔已驗證，但找不到預期的執行檔。'
}
$version = (& $consoleExecutable --version | Select-Object -First 1)
if (-not $version -or -not $version.StartsWith('4.7.2.stable')) {
    throw "Godot 版本不符：$version"
}
Write-Host "Godot 已就緒：$executable ($version)"
