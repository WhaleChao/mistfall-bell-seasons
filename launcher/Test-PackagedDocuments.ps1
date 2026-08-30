[CmdletBinding()]
param(
    [int]$Port = 18767,
    [string]$CreatorExecutable = 'creator_service\dist\PixelRPGCreatorService.exe',
    [string]$ReportDirectory = 'reports\packaged_documents'
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$creatorExecutablePath = (Resolve-Path -LiteralPath (Join-Path $projectRoot $CreatorExecutable)).Path
$fixtureRoot = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'work') -Directory -ErrorAction Stop |
    Where-Object Name -Like 'document-formats-*' |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if (-not $fixtureRoot) { throw '找不到文件格式 fixtures；請先執行 scripts/test_document_formats.py。' }

$extensions = @('txt', 'md', 'csv', 'html', 'docx', 'pptx', 'xlsx', 'pdf', 'png')
foreach ($extension in $extensions) {
    if (-not (Test-Path -LiteralPath (Join-Path $fixtureRoot.FullName "fixture.$extension"))) {
        throw "文件 fixture 缺失：fixture.$extension"
    }
}

$testRoot = Join-Path $projectRoot ('work\packaged-documents-' + [Guid]::NewGuid().ToString('N'))
$knowledgeRoot = Join-Path $testRoot 'knowledge'
New-Item -ItemType Directory -Path $knowledgeRoot -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'schemas') -Destination $testRoot -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot 'data') -Destination $testRoot -Recurse
foreach ($extension in $extensions) {
    Copy-Item -LiteralPath (Join-Path $fixtureRoot.FullName "fixture.$extension") -Destination $knowledgeRoot
}

$tokenBytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($tokenBytes)
$token = [Convert]::ToBase64String($tokenBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$variables = @(
    'PIXELRPG_PROJECT_ROOT', 'PIXELRPG_SESSION_TOKEN', 'PIXELRPG_PORT',
    'PIXELRPG_QUALITY_MODEL', 'PIXELRPG_FAST_MODEL', 'PIXELRPG_EMBEDDING_MODEL',
    'PIXELRPG_MOCK_AI', 'HF_HUB_OFFLINE', 'TRANSFORMERS_OFFLINE', 'HF_HUB_DISABLE_TELEMETRY'
)
$previous = @{}
foreach ($name in $variables) { $previous[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
[Environment]::SetEnvironmentVariable('PIXELRPG_PROJECT_ROOT', $testRoot, 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_SESSION_TOKEN', $token, 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_PORT', "$Port", 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_QUALITY_MODEL', 'qwen3.5:9b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_FAST_MODEL', 'qwen3.5:4b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_EMBEDDING_MODEL', 'qwen3-embedding:0.6b', 'Process')
[Environment]::SetEnvironmentVariable('PIXELRPG_MOCK_AI', $null, 'Process')
[Environment]::SetEnvironmentVariable('HF_HUB_OFFLINE', '1', 'Process')
[Environment]::SetEnvironmentVariable('TRANSFORMERS_OFFLINE', '1', 'Process')
[Environment]::SetEnvironmentVariable('HF_HUB_DISABLE_TELEMETRY', '1', 'Process')

function Get-ServiceTreeProcessIds([int]$RootProcessId) {
    $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    $ids = [Collections.Generic.HashSet[int]]::new()
    [void]$ids.Add($RootProcessId)
    $changed = $true
    while ($changed) {
        $changed = $false
        foreach ($process in $all) {
            if ($ids.Contains([int]$process.ParentProcessId) -and $ids.Add([int]$process.ProcessId)) {
                $changed = $true
            }
        }
    }
    return @($ids)
}

function Test-ServiceConnections([int]$RootProcessId) {
    $script:networkSamples++
    foreach ($processId in @(Get-ServiceTreeProcessIds $RootProcessId)) {
        foreach ($connection in @(Get-NetTCPConnection -OwningProcess $processId -ErrorAction SilentlyContinue)) {
            $remote = [string]$connection.RemoteAddress
            if ($remote -and $remote -notin @('0.0.0.0', '::', '127.0.0.1', '::1')) {
                $script:externalConnections.Add([pscustomobject]@{
                    process_id = $processId
                    state = [string]$connection.State
                    remote_address = $remote
                    remote_port = [int]$connection.RemotePort
                })
            }
        }
    }
}

function Invoke-MonitoredJsonPost([string]$Uri, [hashtable]$Headers, [hashtable]$Body, [int]$RootProcessId, [string]$Name) {
    $outputPath = Join-Path $testRoot "$Name.response.json"
    $errorPath = Join-Path $testRoot "$Name.error.txt"
    $payload = $Body | ConvertTo-Json -Depth 10 -Compress
    $job = Start-Job -ScriptBlock {
        param($RequestUri, $RequestHeaders, $RequestBody, $OutputPath, $ErrorPath)
        try {
            $result = Invoke-RestMethod -Method Post -Uri $RequestUri -Headers $RequestHeaders -ContentType 'application/json; charset=utf-8' -Body $RequestBody -TimeoutSec 600
            $result | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        } catch {
            ($_ | Out-String) | Set-Content -LiteralPath $ErrorPath -Encoding UTF8
            throw
        }
    } -ArgumentList $Uri, $Headers, $payload, $outputPath, $errorPath
    try {
        while ($job.State -in @('NotStarted', 'Running')) {
            Test-ServiceConnections $RootProcessId
            Start-Sleep -Milliseconds 250
        }
        Receive-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
        if ($job.State -ne 'Completed' -or -not (Test-Path -LiteralPath $outputPath)) {
            $detail = if (Test-Path -LiteralPath $errorPath) { Get-Content -LiteralPath $errorPath -Raw } else { "job state $($job.State)" }
            throw "$Name 要求失敗：$detail"
        }
        return Get-Content -LiteralPath $outputPath -Raw | ConvertFrom-Json
    } finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
    }
}

$stdout = Join-Path $testRoot 'service.stdout.txt'
$stderr = Join-Path $testRoot 'service.stderr.txt'
$reportPath = [IO.Path]::GetFullPath((Join-Path $projectRoot $ReportDirectory))
$service = $null
$listenerOwnerProcessId = $null
$networkSamples = 0
$externalConnections = [Collections.Generic.List[object]]::new()
$startedAt = Get-Date
try {
    $service = Start-Process -FilePath $creatorExecutablePath -WorkingDirectory $testRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $baseUrl = "http://127.0.0.1:$Port"
    $headers = @{ 'X-PixelRPG-Token' = $token }
    $ready = $false
    for ($attempt = 0; $attempt -lt 480; $attempt++) {
        if ($service.HasExited) { throw "Creator Service 提前結束：$(Get-Content -LiteralPath $stderr -Raw)" }
        try {
            $healthBefore = Invoke-RestMethod -Uri "$baseUrl/api/v1/health" -Headers $headers -TimeoutSec 2
            if ($healthBefore.service -eq 'ok') { $ready = $true; break }
        } catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $ready) { throw '完整 Creator Service 在 120 秒內未就緒。' }

    $listeners = @()
    for ($attempt = 0; $attempt -lt 40; $attempt++) {
        $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
        if ($listeners.Count -gt 0) { break }
        Start-Sleep -Milliseconds 250
    }
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1') {
        throw "Creator Service 未嚴格綁定 127.0.0.1:$Port。"
    }
    $listenerOwnerProcessId = [int]$listeners[0].OwningProcess
    if ($listenerOwnerProcessId -notin @(Get-ServiceTreeProcessIds $service.Id)) {
        throw "監聽程序 $listenerOwnerProcessId 不屬於啟動的程序樹 $($service.Id)。"
    }

    $paths = @($extensions | ForEach-Object { "knowledge/fixture.$_" })
    $forced = Invoke-MonitoredJsonPost "$baseUrl/api/v1/index/rebuild" $headers @{ paths = $paths; force = $true } $service.Id 'forced'
    $incremental = Invoke-MonitoredJsonPost "$baseUrl/api/v1/index/rebuild" $headers @{ paths = $paths; force = $false } $service.Id 'incremental'
    $healthAfter = Invoke-RestMethod -Uri "$baseUrl/api/v1/health" -Headers $headers -TimeoutSec 10
    Test-ServiceConnections $service.Id

    $checks = [ordered]@{
        service_health = $healthAfter.service -eq 'ok'
        localhost_only_listener = $listeners[0].LocalAddress -eq '127.0.0.1'
        forced_indexed_all_formats = [int]$forced.indexed_files -eq $extensions.Count
        forced_chunks_present = [int]$forced.chunks -ge $extensions.Count
        forced_without_warnings = @($forced.warnings).Count -eq 0
        sqlite_vec_active = [string]$forced.vector_backend -eq 'sqlite-vec'
        incremental_skipped_all = [int]$incremental.unchanged_files -eq $extensions.Count -and [int]$incremental.indexed_files -eq 0
        health_reports_index = [int]$healthAfter.index_chunks -ge $extensions.Count
        no_external_connections = $externalConnections.Count -eq 0
    }
    $passed = @($checks.Values | Where-Object { -not $_ }).Count -eq 0
    $executable = Get-Item -LiteralPath $creatorExecutablePath
    $signature = Get-AuthenticodeSignature -LiteralPath $creatorExecutablePath
    $healthBefore.project_root = '<isolated-project-root>'
    $healthAfter.project_root = '<isolated-project-root>'
    $report = [ordered]@{
        passed = $passed
        started_at = $startedAt.ToString('o')
        elapsed_seconds = [math]::Round(((Get-Date) - $startedAt).TotalSeconds, 3)
        executable = [ordered]@{
            path = [IO.Path]::GetRelativePath($projectRoot, $creatorExecutablePath).Replace('\', '/')
            bytes = $executable.Length
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $creatorExecutablePath).Hash
            authenticode = [string]$signature.Status
        }
        formats = $extensions
        checks = $checks
        forced = $forced
        incremental = $incremental
        health_before = $healthBefore
        health_after = $healthAfter
        network_samples = $networkSamples
        external_connections = @($externalConnections)
        fixture_source = [IO.Path]::GetRelativePath($projectRoot, $fixtureRoot.FullName).Replace('\', '/')
        isolated_project_root = [IO.Path]::GetRelativePath($projectRoot, $testRoot).Replace('\', '/')
    }
    New-Item -ItemType Directory -Path $reportPath -Force | Out-Null
    $report | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $reportPath 'report.json') -Encoding UTF8
    $rows = @(
        '# PixelRPG 封裝版文件與索引驗收', '',
        "結果：**$(if ($passed) { 'PASS' } else { 'FAIL' })**　｜　9 種格式　｜　$networkSamples 次連線取樣　｜　外部連線 $($externalConnections.Count)", '',
        '| 檢查 | 結果 |', '|---|---|'
    )
    foreach ($entry in $checks.GetEnumerator()) { $rows += "| $($entry.Key) | $(if ($entry.Value) { '通過' } else { '失敗' }) |" }
    $rows += @('', "- 強制索引：$($forced.indexed_files) 個檔案／$($forced.chunks) 個片段", "- 增量索引：$($incremental.unchanged_files) 個未變更檔案", "- 向量後端：$($forced.vector_backend)", "- EXE SHA-256：$($report.executable.sha256)")
    $rows -join "`n" | Set-Content -LiteralPath (Join-Path $reportPath 'REPORT.md') -Encoding UTF8
    if (-not $passed) { throw '封裝版文件與索引驗收未通過。' }
} finally {
    if ($listenerOwnerProcessId -and $listenerOwnerProcessId -ne $service.Id) { Stop-Process -Id $listenerOwnerProcessId -ErrorAction SilentlyContinue }
    if ($service -and -not $service.HasExited) {
        Stop-Process -Id $service.Id -ErrorAction SilentlyContinue
        $service.WaitForExit(5000) | Out-Null
    }
    foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $previous[$name], 'Process') }
}
Write-Host "封裝版文件驗收報告：$reportPath\REPORT.md"
