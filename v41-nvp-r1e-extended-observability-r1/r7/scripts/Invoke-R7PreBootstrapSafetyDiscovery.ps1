[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$R7BootIdBaseline,
    [string]$EvidencePath = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\06_PRE_BOOTSTRAP_SAFETY\PRE_BOOTSTRAP_HOST_SAFETY.log',
    [string]$PlinkPath = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$scriptRoot = Join-Path $taskRoot 'scripts'
$helperPath = Join-Path $scriptRoot 'Invoke-ContextualPlink.ps1'
$payloadPath = Join-Path $scriptRoot 'r7_prebootstrap_safety_readonly.sh'
$barParserPath = Join-Path $scriptRoot 'parse_pci_bars.py'
$baselineGatePath = Join-Path $taskRoot '04_HOST_BASELINE\R7_HOST_BASELINE_GATE.md'
$jtagGatePath = Join-Path $taskRoot '05_JTAG_RECONFIRMATION\R7_JTAG_RECONFIRMATION_GATE.md'
$formalBitPath = Join-Path $taskRoot '01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$expectedBarParserSha = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
$expectedPayloadSha = 'FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45'
$expectedFormalBitSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$expectedFormalBitSize = 2192144L
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

function Get-ExactValue([string]$Text, [string]$Key) {
    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

Assert-ExactFileHash $PlinkPath $expectedPlinkSha
Assert-ExactFileHash $helperPath $expectedHelperSha
Assert-ExactFileHash $barParserPath $expectedBarParserSha
Assert-ExactFileHash $payloadPath $expectedPayloadSha
Assert-ExactFileHash $formalBitPath $expectedFormalBitSha
if ((Get-Item -LiteralPath $formalBitPath).Length -ne $expectedFormalBitSize) {
    throw 'exact formal bit size gate failed'
}
if (-not (Test-Path -LiteralPath $baselineGatePath -PathType Leaf)) { throw 'R7 host-baseline gate evidence missing' }
if (-not (Test-Path -LiteralPath $jtagGatePath -PathType Leaf)) { throw 'R7 JTAG-reconfirmation gate evidence missing' }
$baselineText = [IO.File]::ReadAllText($baselineGatePath)
$jtagText = [IO.File]::ReadAllText($jtagGatePath)
if ((Get-ExactValue $baselineText 'R7_HOST_BASELINE') -cne 'PASS_2_OF_2' -or
    (Get-ExactValue $baselineText 'NEXT_REBOOT_KERNEL_PROVEN') -cne '7.0.0-29-generic' -or
    (Get-ExactValue $baselineText 'R7_BOOT_ID_BASELINE') -cne $R7BootIdBaseline) {
    throw 'R7 host-baseline evidence gate failed'
}
if ((Get-ExactValue $jtagText 'R7_JTAG_RECONFIRMATION_GATE') -cne 'PASS_5_OF_5') {
    throw 'R7 selected-JTAG reconfirmation evidence gate failed'
}
$fullTargetPath = Get-ExactValue $jtagText 'R7_FULL_JTAG_TARGET_PATH'
if ($fullTargetPath -cne 'Xilinx/80802026a98b01' -and
    -not $fullTargetPath.EndsWith('/Xilinx/80802026a98b01', [StringComparison]::Ordinal)) {
    throw 'R7 selected-JTAG full target path gate failed'
}
if ((Get-ExactValue $jtagText 'R7_PREPROGRAM_DONE_VALUE') -notin @('0','1')) {
    throw 'R7 selected-JTAG DONE value gate failed'
}

$fullEvidence = [IO.Path]::GetFullPath($EvidencePath)
$allowedRoot = [IO.Path]::GetFullPath((Join-Path $taskRoot '06_PRE_BOOTSTRAP_SAFETY'))
if (-not $fullEvidence.StartsWith(
    $allowedRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) { throw 'pre-bootstrap evidence must stay inside 06_PRE_BOOTSTRAP_SAFETY' }
if (Test-Path -LiteralPath $fullEvidence) { throw 'refusing to overwrite pre-bootstrap evidence' }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $fullEvidence) -PathType Container)) {
    throw 'pre-bootstrap evidence parent missing'
}

$payload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($payloadPath))
$barPayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($barParserPath))
$remoteTemplate = 'sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'''
$remoteCommand = $remoteTemplate -f $payload, $R7BootIdBaseline, $barPayload, $expectedBarParserSha

& $helperPath `
    -PlinkPath $PlinkPath `
    -HostKey $hostKey `
    -RemoteCommand $remoteCommand `
    -EvidencePath $fullEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R7_PRE_BOOTSTRAP_HOST_SAFETY' `
    -SendPasswordToStdin `
    -SudoPasswordCopies 1 `
    -TimeoutSeconds 180
exit $LASTEXITCODE
