[CmdletBinding()]
param(
    [string]$SourceExecutable = '',
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$sourceExe = if ($SourceExecutable) {
    (Resolve-Path -LiteralPath $SourceExecutable).Path
} else {
    (Resolve-Path -LiteralPath (Join-Path $projectRoot 'build\Mistfall-Bell-Seasons.exe')).Path
}
$workRoot = Join-Path $projectRoot ('work\signing-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $workRoot | Out-Null
$testExe = Join-Path $workRoot 'Mistfall-Bell-Seasons-signing-test.exe'
Copy-Item -LiteralPath $sourceExe -Destination $testExe
$sourceHash = (Get-FileHash -LiteralPath $sourceExe -Algorithm SHA256).Hash.ToLowerInvariant()
$sourceSignature = (Get-AuthenticodeSignature -LiteralPath $sourceExe).Status.ToString()
$certificate = New-SelfSignedCertificate `
    -Type CodeSigningCert `
    -Subject 'CN=PixelRPG Ephemeral Signing Pipeline Test' `
    -CertStoreLocation 'Cert:\CurrentUser\My' `
    -HashAlgorithm SHA256 `
    -NotAfter (Get-Date).AddDays(1)
$pfxPath = Join-Path $workRoot 'ephemeral-signing-test.pfx'
$passwordBytes = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Fill($passwordBytes)
$testPassword = [Convert]::ToBase64String($passwordBytes)
$passwordVariable = 'PIXELRPG_EPHEMERAL_SIGNING_PASSWORD'
$previousPassword = [Environment]::GetEnvironmentVariable($passwordVariable, 'Process')
try {
    $securePassword = ConvertTo-SecureString $testPassword -AsPlainText -Force
    Export-PfxCertificate -Cert $certificate -FilePath $pfxPath -Password $securePassword | Out-Null
    Remove-Item -LiteralPath "Cert:\CurrentUser\My\$($certificate.Thumbprint)" -Force
    [Environment]::SetEnvironmentVariable($passwordVariable, $testPassword, 'Process')
    $signingReportPath = Join-Path $workRoot 'signing.json'
    & (Join-Path $PSScriptRoot 'Sign-WindowsRelease.ps1') `
        -ExecutablePath $testExe `
        -PfxPath $pfxPath `
        -PasswordEnvironmentVariable $passwordVariable `
        -SkipTimestamp `
        -AllowUntrustedForTesting `
        -ReportPath $signingReportPath | Write-Host
    $testSignature = Get-AuthenticodeSignature -LiteralPath $testExe
    $sourceHashAfter = (Get-FileHash -LiteralPath $sourceExe -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHashAfter -ne $sourceHash) { throw '簽章測試意外修改正式 build EXE。' }
    if ($null -eq $testSignature.SignerCertificate -or $testSignature.SignerCertificate.Thumbprint -ne $certificate.Thumbprint) { throw '測試 EXE 沒有預期的 Authenticode 簽章。' }
    if ((Get-FileHash -LiteralPath $testExe -Algorithm SHA256).Hash.ToLowerInvariant() -eq $sourceHash) { throw '測試簽章未改變複本內容。' }
    $resolvedReport = if ($ReportPath) { $ReportPath } else { Join-Path $projectRoot 'reports\code_signing_pipeline.json' }
    $parent = Split-Path -Parent $resolvedReport
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    [ordered]@{
        passed = $true
        tested_at = (Get-Date).ToString('o')
        original_signature_status = $sourceSignature
        original_exe_unchanged = $true
        test_copy_signature_status = $testSignature.Status.ToString()
        test_copy_has_authenticode_signer = $true
        production_pfx_path_exercised = $true
        ephemeral_certificate_removed_after_test = $true
        production_certificate_supplied = $false
    } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $resolvedReport -Encoding utf8NoBOM
    Write-Host 'Authenticode 簽章管線測試通過；正式 build 未被修改。'
} finally {
    [Environment]::SetEnvironmentVariable($passwordVariable, $previousPassword, 'Process')
    $certificatePath = "Cert:\CurrentUser\My\$($certificate.Thumbprint)"
    if (Test-Path -LiteralPath $certificatePath) { Remove-Item -LiteralPath $certificatePath -Force }
}
