[CmdletBinding(DefaultParameterSetName = 'Pfx')]
param(
    [Parameter(Mandatory = $true)][string]$ExecutablePath,
    [Parameter(Mandatory = $true, ParameterSetName = 'Pfx')][string]$PfxPath,
    [Parameter(Mandatory = $true, ParameterSetName = 'Store')][string]$CertificateThumbprint,
    [string]$PasswordEnvironmentVariable = 'PIXELRPG_SIGNING_PASSWORD',
    [string]$TimestampServer = 'http://timestamp.digicert.com',
    [switch]$SkipTimestamp,
    [switch]$AllowUntrustedForTesting,
    [string]$ReportPath = ''
)

$ErrorActionPreference = 'Stop'
$executable = (Resolve-Path -LiteralPath $ExecutablePath).Path
if ([IO.Path]::GetExtension($executable) -ne '.exe') { throw '只能簽署 Windows EXE。' }
$certificate = $null

if ($PSCmdlet.ParameterSetName -eq 'Pfx') {
    $resolvedPfx = (Resolve-Path -LiteralPath $PfxPath).Path
    $password = [Environment]::GetEnvironmentVariable($PasswordEnvironmentVariable, 'Process')
    if ([string]::IsNullOrEmpty($password)) { throw "缺少簽章密碼環境變數：$PasswordEnvironmentVariable" }
    $certificate = [Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $resolvedPfx,
        $password,
        [Security.Cryptography.X509Certificates.X509KeyStorageFlags]::EphemeralKeySet
    )
} else {
    $normalizedThumbprint = $CertificateThumbprint.Replace(' ', '').ToUpperInvariant()
    $certificate = Get-ChildItem -LiteralPath "Cert:\CurrentUser\My\$normalizedThumbprint" -ErrorAction Stop
}

if (-not $certificate.HasPrivateKey) { throw '選定憑證不含私鑰。' }
$codeSigningUsage = @($certificate.Extensions | Where-Object { $_.Oid.Value -eq '2.5.29.37' } | ForEach-Object { $_.Format($false) }) -join ' '
if ($codeSigningUsage -and $codeSigningUsage -notmatch '1\.3\.6\.1\.5\.5\.7\.3\.3|Code Signing|程式碼簽署') { throw '選定憑證不允許程式碼簽章。' }

$beforeHash = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant()
$signingParams = @{
    LiteralPath = $executable
    Certificate = $certificate
    HashAlgorithm = 'SHA256'
}
if (-not $SkipTimestamp) { $signingParams.TimestampServer = $TimestampServer }
$signature = Set-AuthenticodeSignature @signingParams
$verified = Get-AuthenticodeSignature -LiteralPath $executable
$isCryptographicallySigned = $null -ne $verified.SignerCertificate -and $verified.SignerCertificate.Thumbprint -eq $certificate.Thumbprint
if (-not $isCryptographicallySigned) { throw "Authenticode 簽章未寫入：$($signature.StatusMessage)" }
if (-not $AllowUntrustedForTesting -and $verified.Status -ne [Management.Automation.SignatureStatus]::Valid) {
    throw "正式 Authenticode 信任驗證失敗：$($verified.Status) — $($verified.StatusMessage)"
}

$report = [ordered]@{
    passed = $true
    signed_at = (Get-Date).ToString('o')
    executable = $executable
    sha256_before = $beforeHash
    sha256_after = (Get-FileHash -LiteralPath $executable -Algorithm SHA256).Hash.ToLowerInvariant()
    signature_status = $verified.Status.ToString()
    signer_subject = $verified.SignerCertificate.Subject
    signer_thumbprint = $verified.SignerCertificate.Thumbprint
    timestamped = $null -ne $verified.TimeStamperCertificate
    timestamp_server = if ($SkipTimestamp) { '' } else { $TimestampServer }
    test_untrusted_allowed = [bool]$AllowUntrustedForTesting
}
if ($ReportPath) {
    $parent = Split-Path -Parent $ReportPath
    if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    $report | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $ReportPath -Encoding utf8NoBOM
}
$report | ConvertTo-Json -Depth 5

