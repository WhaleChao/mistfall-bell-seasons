[CmdletBinding()]
param([string]$GodotPath = '')

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bundled) {
        $godot = $bundled.FullName
    } else {
        $command = Get-Command godot -ErrorAction SilentlyContinue
        if (-not $command) { throw '找不到 Godot 4.7.2；請先執行 launcher/Fetch-Godot.ps1。' }
        $godot = $command.Source
    }
}

& $godot --path $projectRoot
