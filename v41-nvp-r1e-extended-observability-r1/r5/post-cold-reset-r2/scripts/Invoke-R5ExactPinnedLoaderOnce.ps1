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
$taskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$helperPath = Join-Path $taskRoot 'scripts\Invoke-ContextualPlink.ps1'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$moduleSha = '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A'
$loaderSha = '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F'
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

$driverDirectory = switch ($Role) {
    'FormalBootstrap' { 'bootstrap_driver' }
    'ArmA' { 'arm_a_driver' }
    'ArmB' { 'arm_b_driver' }
}
$fullEvidence = [IO.Path]::GetFullPath($EvidencePath)
$fullTask = [IO.Path]::GetFullPath($taskRoot)
if (-not $fullEvidence.StartsWith(
    $fullTask + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'evidence path must stay inside the R5 task root'
}
if (Test-Path -LiteralPath $fullEvidence) {
    throw 'refusing to overwrite existing loader evidence'
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $fullEvidence) -PathType Container)) {
    throw 'loader evidence parent directory does not exist'
}

# The command has one, and only one, loader invocation. It first rechecks the
# immutable files and freshness of the phase-specific evidence directory.
# $HOME avoids placing the contextual credential literal in RemoteCommand.
$remoteTemplate = @'
set -eu; module="$HOME/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko"; loader="$HOME/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh"; out="$HOME/FPGA_AHD_HOST/v41_nvp_r1e_r5/__DRIVER_DIRECTORY__"; test -f "$module"; test ! -L "$module"; test -f "$loader"; test ! -L "$loader"; test "$(sha256sum "$module" | awk '{print toupper($1)}')" = __MODULE_SHA__; test "$(sha256sum "$loader" | awk '{print toupper($1)}')" = __LOADER_SHA__; test "$(stat -Lc '%a' "$loader")" = 644; test ! -e "$out"; exec sudo -S -k -p '' /usr/bin/bash "$loader" "$module" __MODULE_SHA__ "$out"
'@
$remoteCommand = $remoteTemplate.Trim().Replace(
    '__DRIVER_DIRECTORY__', $driverDirectory
).Replace(
    '__MODULE_SHA__', $moduleSha
).Replace(
    '__LOADER_SHA__', $loaderSha
)

& $helperPath `
    -PlinkPath $PlinkPath `
    -HostKey $hostKey `
    -RemoteCommand $remoteCommand `
    -EvidencePath $fullEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind ("R5_EXACT_PINNED_LOADER_{0}" -f $Role.ToUpperInvariant()) `
    -SendPasswordToStdin `
    -SudoPasswordCopies 1 `
    -TimeoutSeconds 120
$result = $LASTEXITCODE
exit $result
