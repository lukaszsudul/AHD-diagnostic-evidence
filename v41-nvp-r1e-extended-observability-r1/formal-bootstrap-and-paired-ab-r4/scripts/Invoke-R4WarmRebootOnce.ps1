[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('FormalBootstrap', 'ArmA', 'ArmB')]
    [string]$Role,
    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,
    [string]$PlinkPath = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
)

$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4'
$helperPath = Join-Path $taskRoot 'scripts\Invoke-ContextualPlink.ps1'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'

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

$fullEvidence = [IO.Path]::GetFullPath($EvidencePath)
$fullTask = [IO.Path]::GetFullPath($taskRoot)
if (-not $fullEvidence.StartsWith(
    $fullTask + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'evidence path must stay inside the R4 task root'
}
if (Test-Path -LiteralPath $fullEvidence) {
    throw 'refusing to overwrite existing reboot evidence'
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $fullEvidence) -PathType Container)) {
    throw 'reboot evidence parent directory does not exist'
}

# Exactly one state-changing operation appears below. There is no retry or
# polling loop; a separate post-reboot validator proves the boot-ID change.
$remoteCommand = "sudo -S -k -p '' /usr/sbin/reboot"
& $helperPath `
    -PlinkPath $PlinkPath `
    -HostKey $hostKey `
    -RemoteCommand $remoteCommand `
    -EvidencePath $fullEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind ("R4_WARM_REBOOT_{0}" -f $Role.ToUpperInvariant()) `
    -SendPasswordToStdin `
    -SudoPasswordCopies 1 `
    -TimeoutSeconds 30
$result = $LASTEXITCODE
exit $result
