[CmdletBinding()]
param(
    [int]$Port = 18765,
    [string]$CreatorExecutable = '',
    [string]$ReportDirectory = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$python = Join-Path $projectRoot '.venv\Scripts\python.exe'
if (-not (Test-Path -LiteralPath $python)) { throw '請先執行 Setup-PixelRPG.ps1 -WithTestTools。' }
$ollama = Get-Command ollama -ErrorAction Stop
$requiredModels = @('qwen3.5:4b', 'qwen3.5:9b', 'qwen3-embedding:0.6b')
$installedModels = @((& $ollama.Source list | Select-Object -Skip 1) | ForEach-Object { ($_ -split '\s+')[0] })
$missingModels = @($requiredModels | Where-Object { $_ -notin $installedModels })
if ($missingModels.Count -gt 0) { throw "缺少真實 AI 測試模型：$($missingModels -join ', ')" }

$testRoot = Join-Path $projectRoot ('work\real-ai-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'schemas') -Destination $testRoot -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'data') -Destination $testRoot -Recurse
New-Item -ItemType Directory -Path (Join-Path $testRoot 'knowledge'), (Join-Path $testRoot 'assets\runtime\backgrounds') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'knowledge\world_bible.md') -Destination (Join-Path $testRoot 'knowledge\world_bible.md')
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets\runtime\backgrounds\mistfall_farm_commercial.png') -Destination (Join-Path $testRoot 'assets\runtime\backgrounds\mistfall_farm_commercial.png')

$tokenBytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($tokenBytes)
$token = [Convert]::ToBase64String($tokenBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$variables = @('PIXELRPG_PROJECT_ROOT', 'PIXELRPG_SESSION_TOKEN', 'PIXELRPG_PORT', 'PIXELRPG_QUALITY_MODEL', 'PIXELRPG_FAST_MODEL', 'PIXELRPG_EMBEDDING_MODEL', 'PIXELRPG_MOCK_AI')
$previous = @{}
foreach ($name in $variables) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
[Environment]::SetEnvironmentVariable('PIXELRPG_PROJECT_ROOT', $testRoot, 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_SESSION_TOKEN', $token, 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_PORT', "$Port", 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_QUALITY_MODEL', 'qwen3.5:9b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_FAST_MODEL', 'qwen3.5:4b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_EMBEDDING_MODEL', 'qwen3-embedding:0.6b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_MOCK_AI', $null, 'Process')

$stdout = Join-Path $testRoot 'service.stdout.txt'
$stderr = Join-Path $testRoot 'service.stderr.txt'
$reportPath = if ($ReportDirectory) {
    [IO.Path]::GetFullPath((Join-Path $projectRoot $ReportDirectory))
} else {
    Join-Path $projectRoot 'reports\real_ai'
}
$service = $null
$listenerOwnerProcessId = $null
try {
    if ($CreatorExecutable) {
        $resolvedCreatorExecutable = (Resolve-Path -LiteralPath $CreatorExecutable).Path
        $service = Start-Process -FilePath $resolvedCreatorExecutable `
            -WorkingDirectory $testRoot `
            -WindowStyle Hidden `
            -PassThru `
            -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr
    } else {
        $service = Start-Process -FilePath $python `
            -ArgumentList @('-m', 'app.main') `
            -WorkingDirectory (Join-Path $projectRoot 'creator_service') `
            -WindowStyle Hidden `
            -PassThru `
            -RedirectStandardOutput $stdout `
            -RedirectStandardError $stderr
    }
    $baseUrl = "http://127.0.0.1:$Port"
    $headers = @{ 'X-PixelRPG-Token' = $token }
    $ready = $false
    for ($attempt = 0; $attempt -lt 60; $attempt++) {
        if ($service.HasExited) { throw "Creator Service 提前結束：$(Get-Content -LiteralPath $stderr -Raw)" }
        try {
            $health = Invoke-RestMethod -Uri "$baseUrl/api/v1/health" -Headers $headers -TimeoutSec 2
            if ($health.service -eq 'ok') { $ready = $true; break }
        } catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $ready) { throw 'Creator Service 在 15 秒內未就緒。' }
    # Windows can publish the listener to Get-NetTCPConnection a moment after
    # Uvicorn already accepts HTTP requests. Query by the reserved test port and
    # retry, then verify both the bind address and owning service process.
    $listeners = @()
    for ($attempt = 0; $attempt -lt 20; $attempt++) {
        $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
        if ($listeners.Count -gt 0) { break }
        Start-Sleep -Milliseconds 250
    }
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1' -or $listeners[0].LocalPort -ne $Port) {
        throw "Creator Service 未嚴格綁定 127.0.0.1:$Port：$($listeners | ConvertTo-Json -Compress)"
    }
    $listenerOwnerProcessId = [int]$listeners[0].OwningProcess
    $currentProcessId = $listenerOwnerProcessId
    $belongsToServiceTree = $false
    for ($depth = 0; $depth -lt 8 -and $currentProcessId -gt 0; $depth++) {
        if ($currentProcessId -eq $service.Id) { $belongsToServiceTree = $true; break }
        $currentProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $currentProcessId" -ErrorAction SilentlyContinue
        if (-not $currentProcess) { break }
        $currentProcessId = [int]$currentProcess.ParentProcessId
    }
    if (-not $belongsToServiceTree) {
        throw "Creator Service 監聽程序不屬於啟動的程序樹：根 $($service.Id)，監聽 $listenerOwnerProcessId。"
    }
    & $python (Join-Path $projectRoot 'scripts\test_real_ai.py') `
        --base-url $baseUrl `
        "--token=$token" `
        --report-directory $reportPath
    if ($LASTEXITCODE -ne 0) { throw '真實本機 AI 驗收失敗。' }
} finally {
    if ($listenerOwnerProcessId -and $listenerOwnerProcessId -ne $service.Id) {
        Stop-Process -Id $listenerOwnerProcessId -ErrorAction SilentlyContinue
    }
    if ($service -and -not $service.HasExited) {
        Stop-Process -Id $service.Id
        $service.WaitForExit(5000) | Out-Null
    }
    foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
Write-Host "真實 AI 驗收報告：$reportPath\REPORT.md"
