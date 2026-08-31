[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [string]$MacOSArchivePath = '',
    [switch]$AllowSoftwareRenderer,
    [switch]$UseDummyAudio
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION 格式錯誤：$version" }
$isGitHubHostedWindows = $env:GITHUB_ACTIONS -ceq 'true' -and $env:RUNNER_ENVIRONMENT -ceq 'github-hosted' -and $env:RUNNER_OS -ceq 'Windows'
if (($AllowSoftwareRenderer -or $UseDummyAudio) -and -not $isGitHubHostedWindows) {
    throw '軟體渲染／Dummy audio 發行模式只允許 GitHub hosted Windows runner。'
}
if ($AllowSoftwareRenderer -and -not $UseDummyAudio) {
    throw '軟體渲染發行模式必須同時啟用 Dummy audio，避免把 runner 缺少音效裝置誤判成遊戲錯誤。'
}

& (Join-Path $PSScriptRoot 'Test-PixelRPG.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw '自動測試未通過。' }
& (Join-Path $PSScriptRoot 'Test-Multiplayer.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw '多人連線全情境測試未通過。' }
& (Join-Path $PSScriptRoot 'Test-RenderPerformance.ps1') -GodotPath $GodotPath -AllowSoftwareRenderer:$AllowSoftwareRenderer
if ($LASTEXITCODE -ne 0) { throw '1080p 效能測試未通過。' }
& (Join-Path $PSScriptRoot 'Test-SteamCandidate.ps1') -GodotPath $GodotPath -UseDummyAudio:$UseDummyAudio
if ($LASTEXITCODE -ne 0) { throw 'Steam Windows 候選版測試未通過。' }
& (Join-Path $PSScriptRoot 'Export-Sample.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw 'Windows 匯出失敗。' }
$signingPfx = [Environment]::GetEnvironmentVariable('PIXELRPG_SIGNING_PFX', 'Process')
$requireSigning = [Environment]::GetEnvironmentVariable('PIXELRPG_REQUIRE_SIGNING', 'Process') -eq '1'
if ($signingPfx) {
    & (Join-Path $PSScriptRoot 'Sign-WindowsRelease.ps1') `
        -ExecutablePath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe') `
        -PfxPath $signingPfx
} elseif ($requireSigning) {
    throw '此發行要求 Authenticode 簽章，但未設定 PIXELRPG_SIGNING_PFX。'
}
& (Join-Path $PSScriptRoot 'Test-ExportedBuild.ps1') -UseDummyAudio:$UseDummyAudio
if ($LASTEXITCODE -ne 0) { throw '匯出遊戲 smoke test 失敗。' }
& (Join-Path $PSScriptRoot 'Test-ExportedSteamLaunch.ps1') -UseDummyAudio:$UseDummyAudio
if ($LASTEXITCODE -ne 0) { throw 'Steam Big Picture 正式 EXE 啟動測試失敗。' }

$distRoot = Join-Path $projectRoot 'dist'
$packageName = "Mistfall-Bell-Seasons-v$version-Windows-x64"
$packageRoot = Join-Path $distRoot $packageName
$archive = Join-Path $distRoot ($packageName + '.zip')
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null
if (Test-Path -LiteralPath $packageRoot) {
    $resolvedPackage = (Resolve-Path -LiteralPath $packageRoot).Path
    if (-not $resolvedPackage.StartsWith($distRoot, [StringComparison]::OrdinalIgnoreCase)) { throw "拒絕移除 dist 外路徑：$resolvedPackage" }
    Remove-Item -LiteralPath $resolvedPackage -Recurse -Force
}
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
New-Item -ItemType Directory -Path $packageRoot | Out-Null
$packageDocs = Join-Path $packageRoot 'docs'
New-Item -ItemType Directory -Path $packageDocs | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.pck') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination (Join-Path $packageRoot 'README.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\BEGINNER_GUIDE.md') -Destination (Join-Path $packageDocs 'BEGINNER_GUIDE.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs\GAMEPLAY_GUIDE.md') -Destination (Join-Path $packageDocs 'GAMEPLAY_GUIDE.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $packageRoot 'LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'GODOT_ENGINE_LICENSE.txt') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'GODOT_ENGINE_COPYRIGHT.txt') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY.md') -Destination (Join-Path $packageRoot 'THIRD_PARTY_NOTICES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot '.creator\ASSET_LICENSES.md') -Destination (Join-Path $packageRoot 'ASSET_LICENSES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'PRIVACY.md') -Destination (Join-Path $packageRoot 'PRIVACY.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'SUPPORT.md') -Destination (Join-Path $packageRoot 'SUPPORT.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'SERVER_GUIDE.md') -Destination (Join-Path $packageRoot 'SERVER_GUIDE.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'Start Dedicated Server.cmd') -Destination (Join-Path $packageRoot 'Start Dedicated Server.cmd')
Compress-Archive -LiteralPath $packageRoot -DestinationPath $archive -CompressionLevel Optimal

$hashLines = @()
foreach ($path in @((Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe'), (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.pck'), $archive)) {
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashLines += "$hash  $([IO.Path]::GetFileName($path))"
}
$requireMacOS = [Environment]::GetEnvironmentVariable('PIXELRPG_REQUIRE_MACOS', 'Process') -eq '1'
if ($MacOSArchivePath) {
    $resolvedMacOSArchive = (Resolve-Path -LiteralPath $MacOSArchivePath).Path
    $expectedMacOSName = "Mistfall-Bell-Seasons-v$version-macOS-Universal.zip"
    $distMacOSArchive = Join-Path $distRoot $expectedMacOSName
    $venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
    $python = if (Test-Path -LiteralPath $venvPython) { $venvPython } else { (Get-Command python -ErrorAction Stop).Source }
    & $python (Join-Path $projectRoot 'scripts\audit_macos_archive.py') $resolvedMacOSArchive --version $version --require-licenses --report (Join-Path $projectRoot 'reports\macos_archive\release_input.json')
    if ($LASTEXITCODE -ne 0) { throw 'macOS 發行候選的 Universal 2／授權／PCK 稽核失敗。' }
    if ([IO.Path]::GetFileName($resolvedMacOSArchive) -ne $expectedMacOSName) { throw "macOS 發行檔名必須是 $expectedMacOSName。" }
    if ($resolvedMacOSArchive -ne $distMacOSArchive) {
        Copy-Item -LiteralPath $resolvedMacOSArchive -Destination $distMacOSArchive -Force
    }
    $macOSHash = (Get-FileHash -LiteralPath $distMacOSArchive -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashLines += "$macOSHash  $expectedMacOSName"
} elseif ($requireMacOS) {
    throw '此發行要求 macOS Universal ZIP，但未提供 -MacOSArchivePath。'
}
[IO.File]::WriteAllLines((Join-Path $distRoot 'SHA256SUMS.txt'), $hashLines, [Text.UTF8Encoding]::new($false))
& (Join-Path $PSScriptRoot 'Test-ReleaseArchive.ps1') -ArchivePath $archive -UseDummyAudio:$UseDummyAudio
if ($LASTEXITCODE -ne 0) { throw '正式 ZIP 完整性驗證失敗。' }
Write-Host "發行包完成：$archive"
