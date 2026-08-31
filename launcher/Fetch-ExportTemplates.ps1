[CmdletBinding()]
param([switch]$ForceRefresh)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$templateVersion = '4.7.2.stable'
$assetName = 'Godot_v4.7.2-stable_export_templates.tpz'
$url = "https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/$assetName"
$expectedSha512 = 'ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079'
$destination = Join-Path $env:APPDATA "Godot\export_templates\$templateVersion"
$releaseTemplate = Join-Path $destination 'windows_release_x86_64.exe'
$debugTemplate = Join-Path $destination 'windows_debug_x86_64.exe'
$macOSUniversalTemplate = Join-Path $destination 'macos.zip'

if ($ForceRefresh -and (Test-Path -LiteralPath $destination)) {
    Remove-Item -LiteralPath $destination -Recurse -Force
}
if ((Test-Path -LiteralPath $releaseTemplate) -and (Test-Path -LiteralPath $debugTemplate) -and (Test-Path -LiteralPath $macOSUniversalTemplate)) {
    Write-Host "Godot $templateVersion Windows x64／macOS Universal 匯出模板已就緒：$destination"
    exit 0
}

$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("pixelrpg-templates-" + [IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null
$archive = Join-Path $temporaryRoot 'export_templates.zip'
$expanded = Join-Path $temporaryRoot 'expanded'
try {
    Write-Host '下載 Godot 4.7.2 官方匯出模板（約 1.2 GB）…'
    Invoke-WebRequest -Uri $url -OutFile $archive
    $actualSha512 = (Get-FileHash -LiteralPath $archive -Algorithm SHA512).Hash.ToLowerInvariant()
    if ($actualSha512 -ne $expectedSha512) {
        throw "匯出模板 checksum 不符。實際值：$actualSha512"
    }
    Expand-Archive -LiteralPath $archive -DestinationPath $expanded
    $sourceRoot = Join-Path $expanded 'templates'
    $sourceRelease = Join-Path $sourceRoot 'windows_release_x86_64.exe'
    $sourceDebug = Join-Path $sourceRoot 'windows_debug_x86_64.exe'
    $sourceMacOS = Join-Path $sourceRoot 'macos.zip'
    if (-not (Test-Path -LiteralPath $sourceRelease) -or -not (Test-Path -LiteralPath $sourceDebug) -or -not (Test-Path -LiteralPath $sourceMacOS)) {
        throw '官方壓縮檔中找不到 Windows x64 或 macOS Universal 匯出模板。'
    }
    New-Item -ItemType Directory -Path $destination -Force | Out-Null
    Copy-Item -LiteralPath $sourceRelease -Destination $releaseTemplate -Force
    Copy-Item -LiteralPath $sourceDebug -Destination $debugTemplate -Force
    Copy-Item -LiteralPath $sourceMacOS -Destination $macOSUniversalTemplate -Force
    $versionFile = Join-Path $sourceRoot 'version.txt'
    if (Test-Path -LiteralPath $versionFile) {
        Copy-Item -LiteralPath $versionFile -Destination (Join-Path $destination 'version.txt') -Force
    }
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        $resolvedTemporary = (Resolve-Path -LiteralPath $temporaryRoot).Path
        $systemTemporary = [IO.Path]::GetTempPath()
        if ($resolvedTemporary.StartsWith($systemTemporary, [StringComparison]::OrdinalIgnoreCase) -and $resolvedTemporary.Contains('pixelrpg-templates-')) {
            Remove-Item -LiteralPath $resolvedTemporary -Recurse -Force
        }
    }
}

Write-Host "Godot Windows x64／macOS Universal 匯出模板安裝完成：$destination"
