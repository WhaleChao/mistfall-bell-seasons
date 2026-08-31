[CmdletBinding()]
param(
    [string]$Repository = 'WhaleChao/mistfall-bell-seasons',
    [Parameter(Mandatory = $true)][string]$Tag,
    [string]$ExpectedSha256 = '',
    [string]$ReportDirectory = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$archiveName = "Mistfall-Bell-Seasons-$Tag-Windows-x64.zip"
$reportRoot = if ($ReportDirectory) { $ReportDirectory } else { Join-Path $projectRoot 'reports\published_release' }
New-Item -ItemType Directory -Path $reportRoot -Force | Out-Null
$reportRoot = (Resolve-Path -LiteralPath $reportRoot).Path
$downloadRoot = Join-Path ([IO.Path]::GetTempPath()) ("pixelrpg-published-$($Tag.TrimStart('v'))-" + [Guid]::NewGuid().ToString('N'))
$expandedRoot = Join-Path $downloadRoot 'expanded'
New-Item -ItemType Directory -Path $downloadRoot, $expandedRoot | Out-Null

& gh release download $Tag --repo $Repository --dir $downloadRoot --pattern $archiveName --pattern 'SHA256SUMS.txt'
if ($LASTEXITCODE -ne 0) { throw "無法從 GitHub Release 下載 $Tag。" }
$archive = Join-Path $downloadRoot $archiveName
$sumPath = Join-Path $downloadRoot 'SHA256SUMS.txt'
if (-not (Test-Path -LiteralPath $archive) -or -not (Test-Path -LiteralPath $sumPath)) { throw '公開 Release 缺少 ZIP 或 SHA256SUMS.txt。' }

$publishedSums = @{}
foreach ($line in Get-Content -LiteralPath $sumPath) {
    if ($line -match '^([0-9a-fA-F]{64})\s+(.+)$') { $publishedSums[$Matches[2].Trim()] = $Matches[1].ToLowerInvariant() }
}
$archiveHash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
if (-not $publishedSums.ContainsKey($archiveName) -or $publishedSums[$archiveName] -ne $archiveHash) { throw '公開 ZIP 與 SHA256SUMS.txt 不一致。' }
if ($ExpectedSha256 -and $archiveHash -ne $ExpectedSha256.ToLowerInvariant()) { throw "公開 ZIP 不符合指定雜湊：$archiveHash" }

$releaseJson = gh release view $Tag --repo $Repository --json tagName,isDraft,isPrerelease,assets,url
if ($LASTEXITCODE -ne 0) { throw '無法讀取 GitHub Release metadata。' }
$release = $releaseJson | ConvertFrom-Json
if ($release.isDraft -or $release.isPrerelease -or $release.tagName -ne $Tag) { throw 'Release 尚非正式公開版本或標籤不符。' }
$archiveAsset = @($release.assets | Where-Object { $_.name -eq $archiveName })
if ($archiveAsset.Count -ne 1 -or $archiveAsset[0].state -ne 'uploaded') { throw '公開 ZIP asset 狀態不正確。' }
if ($archiveAsset[0].digest -and $archiveAsset[0].digest -ne "sha256:$archiveHash") { throw 'GitHub asset digest 與下載檔不一致。' }

Expand-Archive -LiteralPath $archive -DestinationPath $expandedRoot -Force
$topEntries = @(Get-ChildItem -LiteralPath $expandedRoot)
if ($topEntries.Count -ne 1 -or -not $topEntries[0].PSIsContainer) { throw 'ZIP 必須只有一個頂層遊戲目錄。' }
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
$missing = @($expectedFiles | Where-Object { $_ -notin $actualFiles })
$unexpected = @($actualFiles | Where-Object { $_ -notin $expectedFiles })
if ($missing.Count -gt 0 -or $unexpected.Count -gt 0) { throw "公開 ZIP 內容不符。缺少：$($missing -join ', ')；多出：$($unexpected -join ', ')" }

$noticeHashes = @{
    'GODOT_ENGINE_LICENSE.txt' = 'b0435e3b3e4e55238f05f4b306f30524a1b2e20147810d436eaa554fa6855c80'
    'GODOT_ENGINE_COPYRIGHT.txt' = 'cb1980c88089573bcacd7221d777c689bb8bbd778799f24c27fca0fe5f774d6d'
}
foreach ($notice in $noticeHashes.Keys) {
    $actualNoticeHash = (Get-FileHash -LiteralPath (Join-Path $packageRoot $notice) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actualNoticeHash -ne $noticeHashes[$notice]) { throw "Godot 法律文件不符合 4.7.2-stable：$notice" }
}

$exePath = Join-Path $packageRoot 'Mistfall-Bell-Seasons.exe'
$pckPath = Join-Path $packageRoot 'Mistfall-Bell-Seasons.pck'
$exeHash = (Get-FileHash -LiteralPath $exePath -Algorithm SHA256).Hash.ToLowerInvariant()
$pckHash = (Get-FileHash -LiteralPath $pckPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($publishedSums['Mistfall-Bell-Seasons.exe'] -ne $exeHash -or $publishedSums['Mistfall-Bell-Seasons.pck'] -ne $pckHash) { throw '公開 EXE／PCK 與 SHA256SUMS.txt 不一致。' }

$runtimeReportPath = Join-Path $reportRoot 'runtime.json'
& (Join-Path $PSScriptRoot 'Test-ExportedBuild.ps1') -BuildDirectory $packageRoot -QuitAfterFrames 600 -ReportPath $runtimeReportPath
if ($LASTEXITCODE -ne 0) { throw '公開發行檔執行驗證失敗。' }
$runtime = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json

$report = [ordered]@{
    passed = $true
    verified_at = (Get-Date).ToString('o')
    repository = $Repository
    tag = $Tag
    release_url = $release.url
    github_asset_digest = $archiveAsset[0].digest
    archive_sha256 = $archiveHash
    archive_bytes = (Get-Item -LiteralPath $archive).Length
    extracted_package_root = $packageRoot
    files = $actualFiles
    exe_sha256 = $exeHash
    pck_sha256 = $pckHash
    executable_signature = (Get-AuthenticodeSignature -LiteralPath $exePath).Status.ToString()
    runtime_exit_code = $runtime.exit_code
    runtime_network_samples = $runtime.network_samples
    runtime_network_endpoints = @($runtime.network_endpoints)
    os = [Environment]::OSVersion.VersionString
}
$report | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $reportRoot 'report.json') -Encoding utf8NoBOM
$report | ConvertTo-Json -Depth 8
Write-Host "公開 Release 乾淨 Windows 驗證通過：$($release.url)"
