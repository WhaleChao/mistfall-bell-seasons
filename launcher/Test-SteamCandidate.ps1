[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [switch]$SkipResolution
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $command = Get-Command godot -ErrorAction SilentlyContinue
    if ($command) {
        $godot = $command.Source
    } else {
        $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $bundled) { throw '找不到 Godot console executable；請先執行 Fetch-Godot.ps1。' }
        $godot = $bundled.FullName
    }
}

$configurationPath = Join-Path $projectRoot 'steam\store_configuration.json'
$configuration = Get-Content -LiteralPath $configurationPath -Raw | ConvertFrom-Json
if ($configuration.store_features.full_controller_support) { throw '不可在沒有實體測試時宣稱完整手把支援。' }
if (-not $configuration.store_features.partial_controller_support) { throw 'Steam 設定應保守標示部分手把支援。' }
if ($configuration.steam_deck.compatibility_claim -ne 'not_claimed') { throw '尚未具備 Steam Deck Verified 證據。' }
if ($configuration.store_features.steam_input_api -or $configuration.store_features.steam_achievements -or $configuration.store_features.steam_cloud -or $configuration.store_features.steam_matchmaking) {
    throw 'Steam 設定宣稱了尚未整合的 Steamworks 功能。'
}
$trackedSteamAppId = @(& git -C $projectRoot ls-files '*steam_appid.txt' 2>$null)
if ($trackedSteamAppId.Count -gt 0) { throw "正式版本不可提交 steam_appid.txt：$($trackedSteamAppId -join ', ')" }
foreach ($candidate in @((Join-Path $projectRoot 'build'), (Join-Path $projectRoot 'dist'))) {
    if (Test-Path -LiteralPath $candidate) {
        $shippedAppIds = @(Get-ChildItem -LiteralPath $candidate -Filter 'steam_appid.txt' -File -Recurse -ErrorAction SilentlyContinue)
        if ($shippedAppIds.Count -gt 0) { throw "發行內容不得包含 steam_appid.txt：$($shippedAppIds.FullName -join ', ')" }
    }
}

$steamInstall = @(
    'C:\Program Files (x86)\Steam',
    'C:\Program Files\Steam'
) | Where-Object { Test-Path -LiteralPath (Join-Path $_ 'steam.exe') } | Select-Object -First 1
$steamRunning = @(Get-Process -Name steam -ErrorAction SilentlyContinue).Count -gt 0

$previousAppData = $env:APPDATA
$previousLocalAppData = $env:LOCALAPPDATA
$previousTenfoot = $env:SteamTenfoot
$isolatedRoot = Join-Path $projectRoot 'work\steam-candidate-appdata'
New-Item -ItemType Directory -Path $isolatedRoot -Force | Out-Null
$env:APPDATA = $isolatedRoot
$env:LOCALAPPDATA = $isolatedRoot
$env:SteamTenfoot = '1'
Push-Location $projectRoot
try {
    Invoke-GodotGate -GodotPath $godot -Label 'Steam Big Picture／輸入／商店設定閘門' -Arguments @('--path', '.', '--rendering-method', 'gl_compatibility', '--script', 'res://tests/godot/steam_candidate_test.gd')
} finally {
    Pop-Location
    $env:APPDATA = $previousAppData
    $env:LOCALAPPDATA = $previousLocalAppData
    $env:SteamTenfoot = $previousTenfoot
}
if (-not $SkipResolution) {
    & (Join-Path $PSScriptRoot 'Test-ResolutionLayout.ps1') -GodotPath $godot
    if ($LASTEXITCODE -ne 0) { throw 'Steam 候選版 1280×800 畫面測試失敗。' }
}

$reportPath = Join-Path $projectRoot 'reports\steam_candidate\environment.json'
$report = [ordered]@{
    passed = $true
    tested_at = (Get-Date).ToString('o')
    os = [Environment]::OSVersion.VersionString
    steam_client_installed = [bool]$steamInstall
    steam_install_path = [string]$steamInstall
    steam_client_running = $steamRunning
    controller_test_level = 'mapping_only_no_physical_device'
    store_controller_claim = 'partial'
    steam_deck_claim = 'not_claimed'
    big_picture_fullscreen = $true
    deck_resolution_1280x800 = $true
}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportPath -Encoding utf8NoBOM
Write-Host "Steam Windows 候選版通過：鍵盤滑鼠實機；手把為映射契約，未宣稱完整支援或 Deck Verified。"
