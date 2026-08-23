[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$PostColdResetBootIdBaseline,
    [string]$EvidencePath = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\04_HOST_SAFETY_DISCOVERY\PRE_BOOTSTRAP_HOST_SAFETY.log',
    [string]$PlinkPath = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$scriptRoot = Join-Path $taskRoot 'scripts'
$helperPath = Join-Path $scriptRoot 'Invoke-ContextualPlink.ps1'
$payloadPath = Join-Path $scriptRoot 'r5_prebootstrap_safety_readonly.sh'
$barParserPath = Join-Path $scriptRoot 'parse_pci_bars.py'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$expectedBarParserSha = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'

function Assert-ExactFileHash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "required file missing: $Path" }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) { throw "SHA-256 mismatch for $Path`: $actual" }
}

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $gzip = [IO.Compression.GzipStream]::new(
            $output, [IO.Compression.CompressionLevel]::Optimal, $true
        )
        try { $gzip.Write($Bytes, 0, $Bytes.Length) }
        finally { $gzip.Dispose() }
        return [Convert]::ToBase64String($output.ToArray())
    }
    finally { $output.Dispose() }
}

Assert-ExactFileHash $PlinkPath $expectedPlinkSha
Assert-ExactFileHash $helperPath $expectedHelperSha
Assert-ExactFileHash $barParserPath $expectedBarParserSha
if (-not (Test-Path -LiteralPath $payloadPath -PathType Leaf)) { throw 'pre-bootstrap payload missing' }

$fullEvidence = [IO.Path]::GetFullPath($EvidencePath)
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $taskRoot '04_HOST_SAFETY_DISCOVERY'))
if (-not $fullEvidence.StartsWith(
    $allowedRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) { throw 'pre-bootstrap evidence must stay inside 04_HOST_SAFETY_DISCOVERY' }
if (Test-Path -LiteralPath $fullEvidence) { throw 'refusing to overwrite pre-bootstrap evidence' }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $fullEvidence) -PathType Container)) {
    throw 'pre-bootstrap evidence parent missing'
}

$payload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($payloadPath))
$barPayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($barParserPath))
$remoteTemplate = 'sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'''
$remoteCommand = $remoteTemplate -f $payload, $PostColdResetBootIdBaseline, $barPayload, $expectedBarParserSha

& $helperPath `
    -PlinkPath $PlinkPath `
    -HostKey $hostKey `
    -RemoteCommand $remoteCommand `
    -EvidencePath $fullEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R5_POST_COLD_RESET_PRE_BOOTSTRAP_SAFETY' `
    -SendPasswordToStdin `
    -SudoPasswordCopies 1 `
    -TimeoutSeconds 180
exit $LASTEXITCODE
