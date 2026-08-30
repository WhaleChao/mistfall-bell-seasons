[CmdletBinding()]
param([int]$Port = 8765)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
$godot = Join-Path $projectRoot 'tools\Godot_v4.7.2-stable_win64.exe'
$godotConsole = Join-Path $projectRoot 'tools\Godot_v4.7.2-stable_win64_console.exe'
$creator = Join-Path $projectRoot 'creator_service\dist\PixelRPGCreatorService.exe'
if (-not (Test-Path -LiteralPath $godot)) { throw '找不到固定版 Godot 4.7.2。' }
if (-not (Test-Path -LiteralPath $creator)) { throw '請先執行 Build-CreatorService.ps1。' }

$tokenBytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($tokenBytes)
$token = [Convert]::ToBase64String($tokenBytes).TrimEnd('=').Replace('+', '-').Replace('/', '_')
$testRoot = Join-Path $projectRoot ('work\studio-ui-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$stdout = Join-Path $testRoot 'service.stdout.txt'
$stderr = Join-Path $testRoot 'service.stderr.txt'
$appData = Join-Path $testRoot 'appdata'
New-Item -ItemType Directory -Path $appData | Out-Null
$service = $null
$serviceListenerProcessId = $null
try {
    $environment = @{
        PIXELRPG_PROJECT_ROOT = $projectRoot
        PIXELRPG_SESSION_TOKEN = $token
        PIXELRPG_PORT = "$Port"
        PIXELRPG_QUALITY_MODEL = 'qwen3.5:9b'
        PIXELRPG_FAST_MODEL = 'qwen3.5:4b'
        PIXELRPG_EMBEDDING_MODEL = 'qwen3-embedding:0.6b'
        PIXELRPG_STUDIO_ACCEPTANCE = '1'
    }
    $service = Start-Process -FilePath $creator -WorkingDirectory $projectRoot -WindowStyle Hidden -PassThru `
        -Environment $environment -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $ready = $false
    for ($attempt = 0; $attempt -lt 80; $attempt++) {
        if ($service.HasExited) { throw "Creator Service 提前結束：$(Get-Content -LiteralPath $stderr -Raw)" }
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/api/v1/health" -Headers @{ 'X-PixelRPG-Token' = $token } -TimeoutSec 2
            if ($health.service -eq 'ok') { $ready = $true; break }
        } catch { Start-Sleep -Milliseconds 250 }
    }
    if (-not $ready) { throw 'Creator Service 未就緒。' }
    $listeners = @(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
    if ($listeners.Count -ne 1 -or $listeners[0].LocalAddress -ne '127.0.0.1') {
        throw "Creator Service 未嚴格綁定 127.0.0.1:$Port。"
    }
    $serviceListenerProcessId = [int]$listeners[0].OwningProcess
    $godotEnvironment = $environment.Clone()
    $godotEnvironment.APPDATA = $appData
    $godotEnvironment.LOCALAPPDATA = $appData
    $arguments = @('--editor', '--path', $projectRoot, '--rendering-method', 'gl_compatibility', '--script', 'res://tests/godot/studio_ui_acceptance.gd')
    $godotOut = Join-Path $testRoot 'godot.stdout.txt'
    $godotErr = Join-Path $testRoot 'godot.stderr.txt'
    $godotProcess = Start-Process -FilePath $godotConsole -ArgumentList $arguments -PassThru -Environment $godotEnvironment `
        -RedirectStandardOutput $godotOut -RedirectStandardError $godotErr
    if (-not $godotProcess.WaitForExit(420000)) {
        $godotProcess.Kill()
        $godotProcess.WaitForExit()
        throw 'Studio UI 驗收超過 7 分鐘。'
    }
    $godotOutput = @(
        if (Test-Path -LiteralPath $godotOut) { Get-Content -LiteralPath $godotOut -Raw }
        if (Test-Path -LiteralPath $godotErr) { Get-Content -LiteralPath $godotErr -Raw }
    ) -join "`n"
    if ($godotOutput) { Write-Host $godotOutput }
    $reportPath = Join-Path $projectRoot 'reports\studio_ui\report.json'
    if (-not (Test-Path -LiteralPath $reportPath)) { throw 'Studio UI 驗收沒有產生報告。' }
    $report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
    if ($report.failed -ne 0) { throw "Studio UI 驗收有 $($report.failed) 項失敗。" }

    # Godot Editor itself currently emits renderer/UI leak diagnostics during a
    # scripted Windows editor shutdown (upstream examples: godotengine/godot
    # #120035 and #84839). Keep the test strict before its PASS marker, then
    # allow only the three exact teardown-only forms below. Any other ERROR,
    # including plugin/script/resource errors, still fails this gate.
    $passMarker = 'PixelRPG Studio UI gate: PASS'
    $markerIndex = $godotOutput.LastIndexOf($passMarker, [StringComparison]::Ordinal)
    if ($markerIndex -lt 0) { throw 'Studio UI 驗收沒有輸出成功標記。' }
    $preShutdownOutput = $godotOutput.Substring(0, $markerIndex + $passMarker.Length)
    $shutdownOutput = $godotOutput.Substring($markerIndex + $passMarker.Length)
    Assert-GodotGateResult -Label 'Studio UI 功能與渲染' -ExitCode $godotProcess.ExitCode -Output $preShutdownOutput
    $unknownShutdownOutput = $shutdownOutput
    $knownShutdownPatterns = @(
        '(?m)^ERROR: \d+ RID allocations of type ''[^'']+'' were leaked at exit\.\r?\n?',
        '(?m)^ERROR: Parameter "current_window" is null\.\r?\n?',
        '(?m)^ERROR: Texture with GL ID of \d+: leaked \d+ bytes\.\r?\n?'
    )
    foreach ($pattern in $knownShutdownPatterns) {
        $unknownShutdownOutput = [regex]::Replace($unknownShutdownOutput, $pattern, '')
    }
    Assert-GodotGateResult -Label 'Studio UI 關閉' -ExitCode $godotProcess.ExitCode -Output $unknownShutdownOutput
    if ($shutdownOutput -match '(?m)^ERROR:') {
        Write-Host 'Godot Editor 已知的關閉階段 RID／視窗診斷已隔離；未忽略任何執行期或插件 ERROR。'
    }
    Write-Host "Studio UI 驗收通過：$($report.passed) 項，$($report.screenshots.Count) 張截圖。"
} finally {
    if ($serviceListenerProcessId -and $serviceListenerProcessId -ne $service.Id) {
        Stop-Process -Id $serviceListenerProcessId -ErrorAction SilentlyContinue
    }
    if ($service -and -not $service.HasExited) {
        Stop-Process -Id $service.Id -ErrorAction SilentlyContinue
        $service.WaitForExit(5000) | Out-Null
    }
}
