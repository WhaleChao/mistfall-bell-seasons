[CmdletBinding()]
param(
    [switch]$WithDocuments,
    [switch]$WithVector,
    [switch]$WithTestTools
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$venvPath = Join-Path $projectRoot '.venv'

function Find-Python312 {
    $pyLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        $version = & $pyLauncher.Source -3.12 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>$null
        if ($LASTEXITCODE -eq 0 -and $version -eq '3.12') {
            return @($pyLauncher.Source, '-3.12')
        }
    }
    $python = Get-Command python -ErrorAction SilentlyContinue
    if ($python) {
        $version = & $python.Source -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
        if ($version -eq '3.12') { return @($python.Source) }
    }
    throw '需要 Python 3.12。請先從 python.org 安裝，並勾選 Add Python to PATH。'
}

$pythonCommand = @(Find-Python312)
if (-not (Test-Path -LiteralPath $venvPath)) {
    Write-Host '建立 PixelRPG Creator Service 虛擬環境…'
    if ($pythonCommand.Count -eq 2) {
        & $pythonCommand[0] $pythonCommand[1] -m venv $venvPath
    } else {
        & $pythonCommand[0] -m venv $venvPath
    }
}

$venvPython = Join-Path $venvPath 'Scripts\python.exe'
& $venvPython -m pip install --upgrade pip
$extras = @()
if ($WithDocuments) { $extras += 'documents' }
if ($WithVector) { $extras += 'vector' }
if ($WithTestTools) { $extras += 'test' }
$target = Join-Path $projectRoot 'creator_service'
if ($extras.Count -gt 0) { $target = "$target[$($extras -join ',')]" }
& $venvPython -m pip install --editable $target

Write-Host ''
Write-Host 'Creator Service 安裝完成。'
if (-not $WithDocuments) { Write-Host '提示：PDF/DOCX/PPTX 解析需重新執行並加上 -WithDocuments。' }
if (-not $WithVector) { Write-Host '提示：未裝 sqlite-vec 時仍會使用內建 cosine 向量搜尋。' }
