[CmdletBinding()]
param(
    [string]$GodotPath = '',
    [switch]$AllowSoftwareRenderer
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
. (Join-Path $PSScriptRoot 'GodotGate.ps1')
if ($GodotPath) {
    $godot = (Resolve-Path -LiteralPath $GodotPath).Path
} else {
    $bundled = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -Filter 'Godot_v4.7.2-stable_win64_console.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $bundled) { throw '找不到 Godot console executable；請先執行 Fetch-Godot.ps1。' }
    $godot = $bundled.FullName
}
Push-Location $projectRoot
try {
    $arguments = @('--path', '.', '--rendering-method', 'gl_compatibility', '--resolution', '1920x1080', '--script', 'res://tests/godot/render_performance_test.gd')
    if (-not $AllowSoftwareRenderer) {
        Invoke-GodotGate -GodotPath $godot -Label '1080p／20 敵人 render gate' -Arguments $arguments
    } else {
        $arguments = @('--audio-driver', 'Dummy') + $arguments
        $reportPath = Join-Path $projectRoot 'reports\render_performance.json'
        $environmentReportPath = Join-Path $projectRoot 'reports\render_performance_environment.json'
        $runId = [Guid]::NewGuid().ToString('N')
        $temporaryReportDirectory = Join-Path $projectRoot 'work\render-performance'
        $temporaryReportPath = Join-Path $temporaryReportDirectory "$runId.json"
        New-Item -ItemType Directory -Path $temporaryReportDirectory -Force | Out-Null
        if (Test-Path -LiteralPath $temporaryReportPath) { throw "效能測試暫存報告路徑已存在：$temporaryReportPath" }
        if (Test-Path -LiteralPath $reportPath) { Remove-Item -LiteralPath $reportPath -Force }
        if (Test-Path -LiteralPath $environmentReportPath) { Remove-Item -LiteralPath $environmentReportPath -Force }

        $previousReportTarget = [Environment]::GetEnvironmentVariable('PIXELRPG_RENDER_PERFORMANCE_REPORT', 'Process')
        $previousCompletionToken = [Environment]::GetEnvironmentVariable('PIXELRPG_RENDER_COMPLETION_TOKEN', 'Process')
        $env:PIXELRPG_RENDER_PERFORMANCE_REPORT = "res://work/render-performance/$runId.json"
        $env:PIXELRPG_RENDER_COMPLETION_TOKEN = $runId
        $PSNativeCommandUseErrorActionPreference = $false
        $startedUtc = [DateTime]::UtcNow
        try {
            $lines = @(& $godot @arguments 2>&1)
            $exitCode = $LASTEXITCODE
        } finally {
            [Environment]::SetEnvironmentVariable('PIXELRPG_RENDER_PERFORMANCE_REPORT', $previousReportTarget, 'Process')
            [Environment]::SetEnvironmentVariable('PIXELRPG_RENDER_COMPLETION_TOKEN', $previousCompletionToken, 'Process')
        }
        $finishedUtc = [DateTime]::UtcNow
        $lines | Write-Host
        $output = $lines -join "`n"

        if (-not (Test-Path -LiteralPath $temporaryReportPath -PathType Leaf)) {
            throw '1080p 效能測試未產生本次執行的唯一報告。'
        }
        $reportFile = Get-Item -LiteralPath $temporaryReportPath
        if ($reportFile.LastWriteTimeUtc -lt $startedUtc.AddSeconds(-1) -or $reportFile.LastWriteTimeUtc -gt $finishedUtc.AddSeconds(1)) {
            throw '1080p 效能測試報告不是本次執行所產生。'
        }
        try {
            $report = Get-Content -LiteralPath $temporaryReportPath -Raw | ConvertFrom-Json -ErrorAction Stop
        } catch {
            throw "1080p 效能測試報告不是有效 JSON：$($_.Exception.Message)"
        }
        $requiredProperties = @(
            'schema_version', 'viewport', 'frames', 'enemies', 'elapsed_seconds', 'average_fps',
            'empty_window_fps', 'base_scene_fps', 'capacity_ratio', 'minimum_average_fps',
            'minimum_baseline_ratio', 'renderer', 'passed', 'passed_by', 'failure_reason',
            'expected_exit_code', 'completion_token', 'completed'
        )
        foreach ($property in $requiredProperties) {
            if ($report.PSObject.Properties.Name -notcontains $property) {
                throw "1080p 效能測試報告缺少欄位：$property"
            }
        }
        foreach ($integerProperty in @('schema_version', 'frames', 'enemies', 'expected_exit_code')) {
            $integerValue = $report.PSObject.Properties[$integerProperty].Value
            if (($integerValue -isnot [int]) -and ($integerValue -isnot [long])) {
                throw "1080p 效能測試報告的 $integerProperty 必須是 JSON integer。"
            }
        }
        if ([long]$report.schema_version -ne 2) { throw '1080p 效能測試報告 schema_version 必須是 2。' }
        $viewport = @($report.viewport)
        if ($viewport.Count -ne 2 -or (($viewport[0] -isnot [int]) -and ($viewport[0] -isnot [long])) -or (($viewport[1] -isnot [int]) -and ($viewport[1] -isnot [long])) -or [long]$viewport[0] -ne 1920 -or [long]$viewport[1] -ne 1080) {
            throw '1080p 效能測試報告的 viewport 必須是 1920x1080。'
        }
        if ([long]$report.frames -ne 300 -or [long]$report.enemies -ne 20) {
            throw '1080p 效能測試報告必須完整量測 300 frames／20 enemies。'
        }
        $metrics = @{}
        foreach ($metric in @('elapsed_seconds', 'average_fps', 'empty_window_fps', 'base_scene_fps', 'capacity_ratio', 'minimum_average_fps', 'minimum_baseline_ratio')) {
            $rawValue = $report.PSObject.Properties[$metric].Value
            $isNumeric = $rawValue -is [int] -or $rawValue -is [long] -or $rawValue -is [double] -or $rawValue -is [decimal]
            if (-not $isNumeric) { throw "1080p 效能測試報告的 $metric 必須是 JSON number。" }
            $value = [double]$rawValue
            if ([double]::IsNaN($value) -or [double]::IsInfinity($value) -or $value -le 0.0) {
                throw "1080p 效能測試報告的 $metric 不是有效正數。"
            }
            $metrics[$metric] = $value
        }
        if ([Math]::Abs($metrics.minimum_average_fps - 58.0) -gt 0.000001 -or [Math]::Abs($metrics.minimum_baseline_ratio - 0.95) -gt 0.000001) {
            throw '1080p 效能測試報告的門檻值與發行政策不一致。'
        }
        if ($report.passed -isnot [bool] -or $report.completed -isnot [bool]) {
            throw '1080p 效能測試報告的 passed／completed 必須是 JSON Boolean。'
        }
        foreach ($stringProperty in @('renderer', 'passed_by', 'failure_reason', 'completion_token')) {
            if ($report.PSObject.Properties[$stringProperty].Value -isnot [string]) {
                throw "1080p 效能測試報告的 $stringProperty 必須是 JSON string。"
            }
        }
        if ([string]::IsNullOrWhiteSpace($report.renderer)) { throw '1080p 效能測試報告缺少 renderer。' }
        if ($report.completion_token -cne $runId -or $report.completed -ne $true) {
            throw '1080p 效能測試報告沒有本次執行的完成 token。'
        }
        $expectedAverageFps = 300.0 / $metrics.elapsed_seconds
        $averageTolerance = [Math]::Max(0.2, $expectedAverageFps * 0.005)
        if ([Math]::Abs($metrics.average_fps - $expectedAverageFps) -gt $averageTolerance) {
            throw '1080p 效能測試報告的 average_fps 與 frames／elapsed_seconds 不一致。'
        }
        $expectedCapacityRatio = $metrics.average_fps / $metrics.empty_window_fps
        if ([Math]::Abs($metrics.capacity_ratio - $expectedCapacityRatio) -gt 0.003) {
            throw '1080p 效能測試報告的 capacity_ratio 與 FPS 數值不一致。'
        }
        $calculatedPassedBy = if ($metrics.average_fps -ge $metrics.minimum_average_fps) {
            'average_fps'
        } elseif ($metrics.empty_window_fps -lt $metrics.minimum_average_fps -and $metrics.capacity_ratio -ge $metrics.minimum_baseline_ratio) {
            'baseline_ratio'
        } else {
            'none'
        }
        $calculatedPassed = $calculatedPassedBy -cne 'none'
        $calculatedFailureReason = if ($calculatedPassed) { '' } else { 'performance_threshold' }
        $calculatedExitCode = if ($calculatedPassed) { 0 } else { 1 }
        if ($report.passed -ne $calculatedPassed -or $report.passed_by -cne $calculatedPassedBy -or $report.failure_reason -cne $calculatedFailureReason -or [long]$report.expected_exit_code -ne $calculatedExitCode) {
            throw '1080p 效能測試報告的結果與門檻公式不一致。'
        }

        $fatalPattern = '(?im)^\s*SCRIPT ERROR:|Parse Error|Compile Error|Failed to load script|Failed to load resource'
        if ($output -match $fatalPattern) {
            throw "1080p 效能測試發生腳本／資源錯誤：`n$output"
        }
        $unexpectedErrors = @($lines | Where-Object { [string]$_ -match '^\s*ERROR:' })
        if ($unexpectedErrors.Count -gt 0) {
            throw "1080p 效能測試發生未允許的引擎錯誤：`n$($unexpectedErrors -join "`n")"
        }
        $resultLabel = if ($calculatedPassed) { 'PASS' } else { 'FAIL' }
        $expectedSentinel = "PIXELRPG_RENDER_COMPLETED token=$runId result=$resultLabel exit=$calculatedExitCode"
        $sentinelLines = @($lines | Where-Object { [string]$_ -clike 'PIXELRPG_RENDER_COMPLETED*' })
        if ($sentinelLines.Count -ne 1 -or [string]$sentinelLines[0] -cne $expectedSentinel -or $exitCode -ne $calculatedExitCode) {
            throw "1080p 效能測試沒有唯一且一致的完成標記（exit code $exitCode）。"
        }

        $microsoftSoftwarePattern = '^ANGLE \(Microsoft, Microsoft Basic Render Driver \(0x[0-9A-Fa-f]{8}\) Direct3D11 vs_5_0 ps_5_0, D3D11-[0-9.]+\)$'
        $expectedAdapterSuffix = " - Compatibility - Using Device: Google Inc. (Microsoft) - $($report.renderer)"
        $basicAdapterLines = @($lines | Where-Object {
            $adapterLine = [string]$_
            $adapterLine.StartsWith('OpenGL API ', [StringComparison]::Ordinal) -and $adapterLine.EndsWith($expectedAdapterSuffix, [StringComparison]::Ordinal)
        })
        $isGitHubHostedWindows = $env:GITHUB_ACTIONS -ceq 'true' -and $env:RUNNER_ENVIRONMENT -ceq 'github-hosted' -and $env:RUNNER_OS -ceq 'Windows'
        $reportNamesMicrosoftSoftware = $report.renderer -cmatch $microsoftSoftwarePattern
        $isMicrosoftSoftwareRenderer = $isGitHubHostedWindows -and $reportNamesMicrosoftSoftware -and $basicAdapterLines.Count -eq 1
        if (($reportNamesMicrosoftSoftware -or $basicAdapterLines.Count -gt 0) -and -not $isMicrosoftSoftwareRenderer) {
            throw 'Microsoft Basic Render Driver 證據不完整或不在 GitHub hosted Windows runner。'
        }

        $decision = [ordered]@{
            schema_version = 1
            source_report = 'reports/render_performance.json'
            source_report_sha256 = (Get-FileHash -LiteralPath $temporaryReportPath -Algorithm SHA256).Hash.ToLowerInvariant()
            renderer = $report.renderer
            observed_average_fps = $metrics.average_fps
            observed_empty_window_fps = $metrics.empty_window_fps
            observed_base_scene_fps = $metrics.base_scene_fps
            observed_capacity_ratio = $metrics.capacity_ratio
            required_average_fps = 58.0
            hardware_threshold_enforced = $true
            classification = 'hardware_threshold_passed'
            reason = 'The measured renderer met the normal hardware performance threshold.'
            test_exit_code = $exitCode
            audio_driver = 'Dummy'
            github_run_id = [string]$env:GITHUB_RUN_ID
            github_sha = [string]$env:GITHUB_SHA
            runner_name = [string]$env:RUNNER_NAME
            runner_environment = [string]$env:RUNNER_ENVIRONMENT
            runner_os = [string]$env:RUNNER_OS
        }
        if ($isMicrosoftSoftwareRenderer) {
            $decision['hardware_threshold_enforced'] = $false
            $decision['classification'] = 'github_hosted_microsoft_basic_software_renderer'
            $decision['reason'] = 'GitHub hosted runner has no hardware GPU; measured FPS is retained as environment evidence and is not presented as hardware performance.'
            Write-Warning '已完成 1080p／20 敵人量測；GitHub hosted runner 使用 Microsoft Basic 軟體渲染器，因此不以該 VM 的 FPS 取代實體顯卡門檻。'
        } elseif ($exitCode -ne 0 -or $metrics.average_fps -lt 58.0) {
            throw "1080p／20 敵人硬體 render gate 未通過（exit code $exitCode）：`n$output"
        }
        Copy-Item -LiteralPath $temporaryReportPath -Destination $reportPath -Force
        $decision | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $environmentReportPath -Encoding utf8NoBOM
        Remove-Item -LiteralPath $temporaryReportPath -Force
        $global:LASTEXITCODE = 0
    }
} finally {
    Pop-Location
}
Write-Host "效能報告：$projectRoot\reports\render_performance.json"
