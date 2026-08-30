[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython)) {
    & (Join-Path $PSScriptRoot 'Setup-PixelRPG.ps1')
}
& $venvPython -m pip install 'pyinstaller>=6.15,<7'
Push-Location (Join-Path $projectRoot 'creator_service')
try {
    & $venvPython -m PyInstaller --noconfirm PixelRPGCreatorService.spec
} finally {
    Pop-Location
}
Write-Host "完成：$projectRoot\creator_service\dist\PixelRPGCreatorService.exe"
