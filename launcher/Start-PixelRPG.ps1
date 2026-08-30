[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [switch]$PullModels,
    [switch]$SkipAI
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$venvPython = Join-Path $projectRoot '.venv\Scripts\python.exe'
$creatorExecutable = Join-Path $projectRoot 'creator_service\dist\PixelRPGCreatorService.exe'

function Find-Godot {
    param([string]$ExplicitPath)
    if ($ExplicitPath) {
        return (Resolve-Path -LiteralPath $ExplicitPath).Path
    }
    foreach ($name in @('godot', 'godot4', 'Godot_v4.7.2-stable_win64.exe')) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) { return $command.Source }
    }
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($bundled) { return $bundled.FullName }
    throw '找不到 Godot 4.7.2。請用 -GodotPath 指定執行檔，或將 Godot 加入 PATH。'
}

$godot = Find-Godot $GodotPath
$creatorProcess = $null
$creatorListenerProcessId = $null
$ollamaProcess = $null

try {
    if (-not $SkipAI) {
        if (-not (Test-Path -LiteralPath $creatorExecutable) -and -not (Test-Path -LiteralPath $venvPython)) {
            Write-Host '尚未安裝 Creator Service，開始執行基本安裝…'
            & (Join-Path $PSScriptRoot 'Setup-PixelRPG.ps1')
        }
        $tokenBytes = New-Object byte[] 32
        [Security.Cryptography.RandomNumberGenerator]::Fill($tokenBytes)
        $sessionToken = [Convert]::ToBase64String($tokenBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
        [Environment]::SetEnvironmentVariable('PIXELRPG_SESSION_TOKEN', $sessionToken, 'Process')
        [Environment]::SetEnvironmentVariable('PIXELRPG_PROJECT_ROOT', $projectRoot, 'Process')

        $ollama = Get-Command ollama -ErrorAction SilentlyContinue
        if ($ollama) {
            try {
                Invoke-RestMethod -Uri 'http://127.0.0.1:11434/api/tags' -TimeoutSec 2 | Out-Null
            } catch {
                $ollamaProcess = Start-Process -FilePath $ollama.Source -ArgumentList 'serve' -WindowStyle Hidden -PassThru
                Start-Sleep -Seconds 2
            }
            if ($PullModels) {
                foreach ($model in @('qwen3.5:9b', 'qwen3.5:4b', 'qwen3-embedding:0.6b')) {
                    & $ollama.Source pull $model
                }
            }
        } else {
            Write-Warning '未找到 Ollama；Studio 仍可啟動，只有 AI 頁不可用。'
        }

        $creatorDirectory = Join-Path $projectRoot '.creator'
        New-Item -ItemType Directory -Path $creatorDirectory -Force | Out-Null
        if (Test-Path -LiteralPath $creatorExecutable) {
            $creatorProcess = Start-Process -FilePath $creatorExecutable `
                -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
                -RedirectStandardOutput (Join-Path $creatorDirectory 'service.out.log') `
                -RedirectStandardError (Join-Path $creatorDirectory 'service.err.log')
        } else {
            $creatorProcess = Start-Process -FilePath $venvPython -ArgumentList '-m', 'app.main' `
                -WorkingDirectory (Join-Path $projectRoot 'creator_service') -WindowStyle Hidden -PassThru `
                -RedirectStandardOutput (Join-Path $creatorDirectory 'service.out.log') `
                -RedirectStandardError (Join-Path $creatorDirectory 'service.err.log')
        }
        $creatorReady = $false
        for ($attempt = 0; $attempt -lt 60; $attempt++) {
            if ($creatorProcess.HasExited) {
                throw "Creator Service 啟動失敗；請查看 $creatorDirectory\service.err.log"
            }
            try {
                $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8765/api/v1/health' `
                    -Headers @{ 'X-PixelRPG-Token' = $sessionToken } -TimeoutSec 2
                if ($health.service -eq 'ok') { $creatorReady = $true; break }
            } catch { Start-Sleep -Milliseconds 250 }
        }
        if (-not $creatorReady) { throw 'Creator Service 在 15 秒內未就緒。' }
        $listeners = @(Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue)
        if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1') {
            throw 'Creator Service 未嚴格綁定 127.0.0.1:8765。'
        }
        $creatorListenerProcessId = [int]$listeners[0].OwningProcess
    }

    Write-Host "開啟 PixelRPG Studio：$projectRoot"
    $godotProcess = Start-Process -FilePath $godot -ArgumentList '--editor', '--path', $projectRoot -PassThru
    $godotProcess.WaitForExit()
} finally {
    if ($creatorListenerProcessId -and $creatorListenerProcessId -ne $creatorProcess.Id) {
        Stop-Process -Id $creatorListenerProcessId -ErrorAction SilentlyContinue
    }
    if ($creatorProcess -and -not $creatorProcess.HasExited) {
        Stop-Process -Id $creatorProcess.Id
    }
    if ($ollamaProcess -and -not $ollamaProcess.HasExited) {
        Stop-Process -Id $ollamaProcess.Id
    }
}
