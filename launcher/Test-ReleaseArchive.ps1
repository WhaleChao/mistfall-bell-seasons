[CmdletBinding()]
param(
    [string]$ArchivePath = '',
    [switch]$UseDummyAudio
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
$archive = if ($ArchivePath) { (Resolve-Path -LiteralPath $ArchivePath).Path } else { (Resolve-Path -LiteralPath (Join-Path $projectRoot "dist\Mistfall-Bell-Seasons-v$version-Windows-x64.zip")).Path }
$workRoot = Join-Path $projectRoot 'work\release-archive-test'
New-Item -ItemType Directory -Path (Split-Path -Parent $workRoot) -Force | Out-Null
if (Test-Path -LiteralPath $workRoot) {
    $resolvedWork = (Resolve-Path -LiteralPath $workRoot).Path
    $allowedParent = (Resolve-Path -LiteralPath (Join-Path $projectRoot 'work')).Path
    if (-not $resolvedWork.StartsWith($allowedParent + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "拒絕清除 work 以外的路徑：$resolvedWork"
    }
    Remove-Item -LiteralPath $resolvedWork -Recurse -Force
}
New-Item -ItemType Directory -Path $workRoot | Out-Null
Expand-Archive -LiteralPath $archive -DestinationPath $workRoot -Force
$topEntries = @(Get-ChildItem -LiteralPath $workRoot)
if ($topEntries.Count -ne 1 -or -not $topEntries[0].PSIsContainer) { throw 'ZIP 必須只包含一個頂層遊戲目錄。' }
$packageRoot = $topEntries[0].FullName
$expectedFiles = @(
    'ASSET_LICENSES.md',
    'GODOT_ENGINE_COPYRIGHT.txt',
    'GODOT_ENGINE_LICENSE.txt',
    'LICENSE.txt',
    'Mistfall-Bell-Seasons.exe',
    'Mistfall-Bell-Seasons.pck',
    'PRIVACY.md',
    'README.md',
    'SERVER_GUIDE.md',
    'Start Dedicated Server.cmd',
    'SUPPORT.md',
    'THIRD_PARTY_NOTICES.md',
    'docs/BEGINNER_GUIDE.md',
    'docs/GAMEPLAY_GUIDE.md'
)
$actualFiles = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File | ForEach-Object { [IO.Path]::GetRelativePath($packageRoot, $_.FullName).Replace('\', '/') } | Sort-Object)
$unexpected = @($actualFiles | Where-Object { $_ -notin $expectedFiles })
$missing = @($expectedFiles | Where-Object { $_ -notin $actualFiles })
if ($unexpected.Count -gt 0 -or $missing.Count -gt 0) {
    throw "ZIP 內容不符。缺少：$($missing -join ', ')；多出：$($unexpected -join ', ')"
}
foreach ($relativePath in $expectedFiles) {
    $file = Get-Item -LiteralPath (Join-Path $packageRoot $relativePath)
    if ($file.Length -le 0) { throw "ZIP 含空檔案：$relativePath" }
}
$archiveExeHash = (Get-FileHash -LiteralPath (Join-Path $packageRoot 'Mistfall-Bell-Seasons.exe') -Algorithm SHA256).Hash
$buildExeHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe') -Algorithm SHA256).Hash
$archivePckHash = (Get-FileHash -LiteralPath (Join-Path $packageRoot 'Mistfall-Bell-Seasons.pck') -Algorithm SHA256).Hash
$buildPckHash = (Get-FileHash -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.pck') -Algorithm SHA256).Hash
if ($archiveExeHash -ne $buildExeHash -or $archivePckHash -ne $buildPckHash) { throw 'ZIP 內 EXE／PCK 與已驗證 build 不一致。' }
& (Join-Path $PSScriptRoot 'Test-ExportedBuild.ps1') -BuildDirectory $packageRoot -UseDummyAudio:$UseDummyAudio
if ($LASTEXITCODE -ne 0) { throw '解壓後遊戲啟動驗證失敗。' }
$reportRoot = Join-Path $projectRoot 'reports\release_archive'
New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
$report = [ordered]@{
    passed = $true
    version = $version
    archive = [IO.Path]::GetFileName($archive)
    archive_bytes = (Get-Item -LiteralPath $archive).Length
    files = $actualFiles
    exe_sha256 = $archiveExeHash.ToLowerInvariant()
    pck_sha256 = $archivePckHash.ToLowerInvariant()
    extracted_launch = $true
    audio_driver = if ($UseDummyAudio) { 'Dummy' } else { 'default' }
}
$report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $reportRoot 'report.json') -Encoding utf8NoBOM
Write-Host "正式 ZIP 完整性與解壓啟動驗證通過：$archive"
