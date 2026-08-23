[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('PreLoader', 'PostLoader')]
    [string]$Validator,
    [Parameter(Mandatory = $true)]
    [ValidateSet('FormalBootstrap', 'ArmA', 'ArmB')]
    [string]$Role,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')]
    [string]$PreviousBootId,
    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,
    [string]$PlinkPath = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
)

$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$scriptRoot = Join-Path $taskRoot 'scripts'
$helperPath = Join-Path $scriptRoot 'Invoke-ContextualPlink.ps1'
$barParserPath = Join-Path $scriptRoot 'parse_pci_bars.py'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$expectedBarParserSha = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
$expectedPreLoaderSha = '5AB73A9D90DF96A0A3809499B6381437C0FFBB85EB2A87B152F0812F1B4402B9'
$expectedPostLoaderSha = '0695281F1D212C1F90A31A6359F0D606F48AF67528D0F1E379009E72C04EEBD4'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'

function ConvertTo-GzipBase64 {
    param([byte[]]$Bytes)
    $output = [IO.MemoryStream]::new()
    try {
        $gzip = [IO.Compression.GzipStream]::new(
            $output,
            [IO.Compression.CompressionLevel]::Optimal,
            $true
        )
        try {
            $gzip.Write($Bytes, 0, $Bytes.Length)
        }
        finally {
            $gzip.Dispose()
        }
        return [Convert]::ToBase64String($output.ToArray())
    }
    finally {
        $output.Dispose()
    }
}

function Assert-ExactFileHash {
    param([string]$Path, [string]$Expected)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "required file missing: $Path"
    }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) {
        throw "SHA-256 mismatch for $Path`: $actual"
    }
}

Assert-ExactFileHash -Path $PlinkPath -Expected $expectedPlinkSha
Assert-ExactFileHash -Path $helperPath -Expected $expectedHelperSha
Assert-ExactFileHash -Path $barParserPath -Expected $expectedBarParserSha

$validatorName = if ($Validator -eq 'PreLoader') {
    'r6_post_reboot_preloader_readonly.sh'
} else {
    'r6_post_loader_readonly.sh'
}
$expectedValidatorSha = if ($Validator -eq 'PreLoader') { $expectedPreLoaderSha } else { $expectedPostLoaderSha }
$validatorPath = Join-Path $scriptRoot $validatorName
Assert-ExactFileHash -Path $validatorPath -Expected $expectedValidatorSha

$fullEvidence = [IO.Path]::GetFullPath($EvidencePath)
$fullTask = [IO.Path]::GetFullPath($taskRoot)
if (-not $fullEvidence.StartsWith(
    $fullTask + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'evidence path must stay inside the R6 task root'
}
if (Test-Path -LiteralPath $fullEvidence) {
    throw 'refusing to overwrite existing validator evidence'
}
$evidenceParent = Split-Path -Parent $fullEvidence
if (-not (Test-Path -LiteralPath $evidenceParent -PathType Container)) {
    throw 'validator evidence parent directory does not exist'
}

$roleToken = switch ($Role) {
    'FormalBootstrap' { 'formal_bootstrap' }
    'ArmA' { 'arm_a_r1e' }
    'ArmB' { 'arm_b_formal' }
}
$roleDirectory = switch ($Role) {
    'FormalBootstrap' { Join-Path $taskRoot '07_FORMAL_BOOTSTRAP' }
    'ArmA' { Join-Path $taskRoot '08_ARM_A_R1E' }
    'ArmB' { Join-Path $taskRoot '09_ARM_B_FORMAL' }
}
$roleFull = [IO.Path]::GetFullPath($roleDirectory)
if (-not $fullEvidence.StartsWith(
    $roleFull + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'validator evidence must stay inside the selected R6 phase directory'
}
$validatorBytes = [IO.File]::ReadAllBytes($validatorPath)
$barParserBytes = [IO.File]::ReadAllBytes($barParserPath)
$validatorPayload = ConvertTo-GzipBase64 -Bytes $validatorBytes
$barParserPayload = ConvertTo-GzipBase64 -Bytes $barParserBytes

# sudo reads exactly one password from Plink stdin. The validator itself is
# supplied as a compressed positional argument, so password and script bytes
# never share stdin. Both validators perform read-only operations.
$remoteTemplate = 'sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2" "$3" "$4" "$5"'' _ ''{0}'' ''{1}'' ''{2}'' ''{3}'' ''{4}'''
$remoteCommand = $remoteTemplate -f (
    $validatorPayload,
    $roleToken,
    $PreviousBootId,
    $barParserPayload,
    $expectedBarParserSha
)

& $helperPath `
    -PlinkPath $PlinkPath `
    -HostKey $hostKey `
    -RemoteCommand $remoteCommand `
    -EvidencePath $fullEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind ("R6_{0}_{1}" -f $Validator.ToUpperInvariant(), $roleToken.ToUpperInvariant()) `
    -SendPasswordToStdin `
    -SudoPasswordCopies 1 `
    -TimeoutSeconds 120
$result = $LASTEXITCODE
exit $result
