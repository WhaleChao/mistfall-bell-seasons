[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$AppId,
    [Parameter(Mandatory)][ValidateRange(1, 2147483647)][int]$WindowsDepotId,
    [string]$PackageDirectory = '',
    [string]$OutputDirectory = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$version = (Get-Content -LiteralPath (Join-Path $projectRoot 'VERSION') -Raw).Trim()
$defaultPackage = Join-Path $projectRoot "dist\Mistfall-Bell-Seasons-v$version-Windows-x64"
$sourceRoot = if ($PackageDirectory) { (Resolve-Path -LiteralPath $PackageDirectory).Path } else { (Resolve-Path -LiteralPath $defaultPackage).Path }
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputRoot = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory) } else { Join-Path $projectRoot "dist\steam-preview-$version-$stamp" }
if (Test-Path -LiteralPath $outputRoot) { throw "輸出目錄已存在，為避免覆寫已停止：$outputRoot" }
if (-not (Test-Path -LiteralPath (Join-Path $sourceRoot 'Mistfall-Bell-Seasons.exe')) -or -not (Test-Path -LiteralPath (Join-Path $sourceRoot 'Mistfall-Bell-Seasons.pck'))) {
    throw 'Steam depot 來源必須包含正式 EXE 與 PCK。'
}
if (Test-Path -LiteralPath (Join-Path $sourceRoot 'steam_appid.txt')) { throw '正式 depot 不可包含開發用 steam_appid.txt。' }

$contentRoot = Join-Path $outputRoot 'content'
$scriptsRoot = Join-Path $outputRoot 'scripts'
$buildOutput = Join-Path $outputRoot 'output'
New-Item -ItemType Directory -Path $contentRoot, $scriptsRoot, $buildOutput | Out-Null
Get-ChildItem -LiteralPath $sourceRoot -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $contentRoot -Recurse
}

$vdfContentRoot = $contentRoot.Replace('\', '/')
$vdfBuildOutput = $buildOutput.Replace('\', '/')
$depotVdfPath = (Join-Path $scriptsRoot "depot_build_$WindowsDepotId.vdf").Replace('\', '/')
$depotVdf = @"
"DepotBuildConfig"
{
    "DepotID" "$WindowsDepotId"
    "ContentRoot" "$vdfContentRoot"
    "FileMapping"
    {
        "LocalPath" "*"
        "DepotPath" "."
        "recursive" "1"
    }
    "FileExclusion" "steam_appid.txt"
}
"@
$appVdf = @"
"AppBuild"
{
    "AppID" "$AppId"
    "Desc" "Mistfall Bell Seasons v$version Windows candidate"
    "BuildOutput" "$vdfBuildOutput"
    "ContentRoot" "$vdfContentRoot"
    "Preview" "1"
    "SetLive" ""
    "Depots"
    {
        "$WindowsDepotId" "$depotVdfPath"
    }
}
"@
[IO.File]::WriteAllText((Join-Path $scriptsRoot "depot_build_$WindowsDepotId.vdf"), $depotVdf, [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText((Join-Path $scriptsRoot "app_build_$AppId.vdf"), $appVdf, [Text.UTF8Encoding]::new($false))
$instructions = @"
This directory is a SteamPipe PREVIEW candidate. Preview=1 and SetLive is empty.

1. Inspect content/ and confirm no steam_appid.txt, models, indexes, or design sources exist.
2. From the Steamworks SDK ContentBuilder directory, run:
   builder\steamcmd.exe +login <STEAM_ACCOUNT> +run_app_build "$((Join-Path $scriptsRoot "app_build_$AppId.vdf").Replace('\', '/'))" +quit
3. Inspect the preview output in Steamworks. Upload to a private beta branch before any public branch.
4. Never commit credentials or steam_appid.txt.
"@
[IO.File]::WriteAllText((Join-Path $outputRoot 'UPLOAD_INSTRUCTIONS.txt'), $instructions, [Text.UTF8Encoding]::new($false))
Write-Host "SteamPipe 預覽目錄已建立：$outputRoot"
