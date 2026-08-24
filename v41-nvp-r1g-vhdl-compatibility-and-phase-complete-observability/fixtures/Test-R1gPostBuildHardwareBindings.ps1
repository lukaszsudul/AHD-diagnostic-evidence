[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BindingPath,
    [string]$R1gWorktree = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
)

# Offline-only post-build fixture. It performs file hashing and Git object
# inspection only. It never invokes Vivado, SSH, JTAG, MMIO, programming,
# reboot, or driver operations.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
. (Join-Path $taskRoot '09_HOST_TOOLS\R1gCampaignCommon.ps1')

$binding = Get-R1gBindingDocument -BindingPath $BindingPath
$commit = [string]$binding.r1gSourceCommit
$tree = [string]$binding.r1gSourceTree
$parent = '225544084dbfcaadb8592fcecc947aa1cec4970e'

& git -C $R1gWorktree cat-file -e ($commit + '^{commit}')
if ($LASTEXITCODE -ne 0) { throw 'R1g binding commit object is absent' }
$actualParent = (& git -C $R1gWorktree rev-parse ($commit + '^')).Trim()
$actualTree = (& git -C $R1gWorktree rev-parse ($commit + '^{tree}')).Trim()
$count = [int]((& git -C $R1gWorktree rev-list --count ($parent + '..' + $commit)).Trim())
if ($LASTEXITCODE -ne 0 -or $actualParent -cne $parent -or $actualTree -cne $tree -or $count -ne 1) {
    throw "R1g commit topology mismatch parent=$actualParent tree=$actualTree count=$count"
}

$status = (& git -C $R1gWorktree status --porcelain=v1)
if ($LASTEXITCODE -ne 0 -or @($status).Count -ne 0) { throw 'R1g worktree is not clean' }

$bit = [string]$binding.r1gBit.path
$bitHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $bit).Hash
$readerHash = (Get-FileHash -Algorithm SHA256 -LiteralPath ([string]$binding.r1gReader.path)).Hash

"POSTBUILD_BINDING_GATE=PASS_READY_FOR_FRESH_HARDWARE_PRECHECK"
"R1G_PARENT_COMMIT=$actualParent"
"R1G_SOURCE_COMMIT=$commit"
"R1G_SOURCE_TREE=$tree"
"R1G_COMMITS_ABOVE_R1F=$count"
"R1G_BIT_PATH=$bit"
"R1G_BIT_SHA256=$bitHash"
"R1G_READER_SHA256=$readerHash"
"ARM_A_REQUIRED_WAIT_SECONDS=$([double]$binding.r1gBit.requiredWaitSeconds)"
'LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0'
