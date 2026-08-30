[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
if ($version -notmatch '^\d+\.\d+\.\d+$') { throw "VERSION 格式錯誤：$version" }

& (Join-Path $PSScriptRoot 'Test-PixelRPG.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw '自動測試未通過。' }
& (Join-Path $PSScriptRoot 'Test-RenderPerformance.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw '1080p 效能測試未通過。' }
& (Join-Path $PSScriptRoot 'Export-Sample.ps1') -GodotPath $GodotPath
if ($LASTEXITCODE -ne 0) { throw 'Windows 匯出失敗。' }
& (Join-Path $PSScriptRoot 'Test-ExportedBuild.ps1')
if ($LASTEXITCODE -ne 0) { throw '匯出遊戲 smoke test 失敗。' }

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
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.pck') -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $projectRoot 'README.md') -Destination (Join-Path $packageRoot 'README.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $packageRoot 'LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY.md') -Destination (Join-Path $packageRoot 'THIRD_PARTY_NOTICES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot '.creator\ASSET_LICENSES.md') -Destination (Join-Path $packageRoot 'ASSET_LICENSES.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'PRIVACY.md') -Destination (Join-Path $packageRoot 'PRIVACY.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'SUPPORT.md') -Destination (Join-Path $packageRoot 'SUPPORT.md')
Compress-Archive -LiteralPath $packageRoot -DestinationPath $archive -CompressionLevel Optimal

$hashLines = @()
foreach ($path in @((Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe'), (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.pck'), $archive)) {
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    $hashLines += "$hash  $([IO.Path]::GetFileName($path))"
}
[IO.File]::WriteAllLines((Join-Path $distRoot 'SHA256SUMS.txt'), $hashLines, [Text.UTF8Encoding]::new($false))
Write-Host "發行包完成：$archive"
