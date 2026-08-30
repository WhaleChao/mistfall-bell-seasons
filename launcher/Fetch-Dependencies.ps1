[CmdletBinding()]
param(
    [switch]$IncludeTests,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$addonsRoot = Join-Path $projectRoot 'addons'
New-Item -ItemType Directory -Path $addonsRoot -Force | Out-Null
$temporaryRoot = Join-Path ([IO.Path]::GetTempPath()) ("pixelrpg-deps-" + [IO.Path]::GetRandomFileName())
New-Item -ItemType Directory -Path $temporaryRoot | Out-Null

$packages = @(
    @{ Name = 'Dialogue Manager'; Url = 'https://github.com/nathanhoad/godot_dialogue_manager/archive/refs/tags/v4.0.3.zip'; Folder = 'godot_dialogue_manager-4.0.3'; Addon = 'dialogue_manager' },
    @{ Name = 'QuestSystem'; Url = 'https://github.com/shomykohai/quest-system/archive/refs/tags/2.0.2.4_4.zip'; Folder = 'quest-system-2.0.2.4_4'; Addon = 'quest_system' },
    @{ Name = 'GLoot'; Url = 'https://github.com/peter-kish/gloot/archive/refs/tags/v3.0.2.zip'; Folder = 'gloot-3.0.2'; Addon = 'gloot' }
)
if ($IncludeTests) {
    $packages += @{ Name = 'gdUnit4'; Url = 'https://github.com/godot-gdunit-labs/gdUnit4/archive/refs/tags/v6.2.1.zip'; Folder = 'gdUnit4-6.2.1'; Addon = 'gdUnit4' }
}

try {
    foreach ($package in $packages) {
        $destination = Join-Path $addonsRoot $package.Addon
        if ((Test-Path -LiteralPath $destination) -and -not $Force) {
            Write-Host "$($package.Name) 已存在，略過。使用 -Force 可覆寫。"
            continue
        }
        $archive = Join-Path $temporaryRoot ($package.Addon + '.zip')
        $expanded = Join-Path $temporaryRoot $package.Addon
        Write-Host "下載 $($package.Name)…"
        Invoke-WebRequest -Uri $package.Url -OutFile $archive
        Expand-Archive -LiteralPath $archive -DestinationPath $expanded
        $source = Join-Path $expanded (Join-Path $package.Folder (Join-Path 'addons' $package.Addon))
        if (-not (Test-Path -LiteralPath $source)) {
            throw "壓縮檔沒有預期的 add-on 路徑：$source"
        }
        if (Test-Path -LiteralPath $destination) {
            $resolvedDestination = (Resolve-Path -LiteralPath $destination).Path
            if (-not $resolvedDestination.StartsWith($addonsRoot, [StringComparison]::OrdinalIgnoreCase)) {
                throw "拒絕移除 addons 外的路徑：$resolvedDestination"
            }
            Remove-Item -LiteralPath $resolvedDestination -Recurse -Force
        }
        Copy-Item -LiteralPath $source -Destination $destination -Recurse
    }
} finally {
    $resolvedTemporary = (Resolve-Path -LiteralPath $temporaryRoot).Path
    $systemTemporary = [IO.Path]::GetTempPath()
    if ($resolvedTemporary.StartsWith($systemTemporary, [StringComparison]::OrdinalIgnoreCase) -and $resolvedTemporary.Contains('pixelrpg-deps-')) {
        Remove-Item -LiteralPath $resolvedTemporary -Recurse -Force
    }
}

Write-Host '依賴已放入 addons/。請在 Godot 的 Plugins 設定中逐一啟用。'
