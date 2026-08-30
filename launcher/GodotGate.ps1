Set-StrictMode -Version Latest

function Assert-GodotGateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][int]$ExitCode,
        [AllowEmptyString()][string]$Output = ''
    )
    $errorPattern = '(?im)^\s*(?:SCRIPT ERROR:|ERROR:)|Parse Error|Compile Error|Failed to load script|Failed to load resource'
    if ($ExitCode -ne 0 -or $Output -match $errorPattern) {
        $reason = if ($ExitCode -ne 0) { "exit code $ExitCode" } else { 'Godot error output' }
        throw "$Label 失敗（$reason）：`n$Output"
    }
}

function Invoke-GodotGate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$GodotPath,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $lines = @(& $GodotPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $lines | Write-Host
    Assert-GodotGateResult -Label $Label -ExitCode $exitCode -Output ($lines -join "`n")
}
