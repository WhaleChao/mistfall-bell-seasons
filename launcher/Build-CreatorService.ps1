[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $venvPython)) {
    & (Join-Path $PSScriptRoot 'Setup-PixelRPG.ps1') -WithDocuments -WithVector
}
$bundleTarget = "$projectRoot\creator_service[documents,vector,bundle]"
& $venvPython -m pip install --editable $bundleTarget
if ($LASTEXITCODE -ne 0) { throw 'Creator Service 完整封裝依賴安裝失敗。' }
Push-Location (Join-Path $projectRoot 'creator_service')
try {
    & $venvPython -m PyInstaller --noconfirm PixelRPGCreatorService.spec
    if ($LASTEXITCODE -ne 0) { throw 'Creator Service PyInstaller 封裝失敗。' }
} finally {
    Pop-Location
}
Write-Host "完成：$projectRoot\creator_service\dist\PixelRPGCreatorService.exe"
