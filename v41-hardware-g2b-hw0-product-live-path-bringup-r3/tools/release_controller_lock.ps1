[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$lockDir = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$lockReceipt = Join-Path $lockDir 'receipt.json'
$linuxReleaseEvidence = Join-Path $taskRoot 'raw\FINAL_STATE_AND_LINUX_LOCK_RELEASE_CONTROLLER.log'
$releaseReceipt = Join-Path $taskRoot 'locks\CONTROLLER_LOCK_RELEASE_RECEIPT.json'

if (Test-Path -LiteralPath $releaseReceipt) { throw 'CONTROLLER_RELEASE_RECEIPT_EXISTS' }
if (-not (Test-Path -LiteralPath $linuxReleaseEvidence -PathType Leaf)) { throw 'LINUX_RELEASE_EVIDENCE_MISSING' }
$linuxText = Get-Content -LiteralPath $linuxReleaseEvidence -Raw
foreach ($required in @('LINUX_LOCK_RELEASED=YES','AHD_XDMA_MODULE_COUNT=0','PLATFORM_XDMA_MODULE_COUNT=0','XDMA_NODE_COUNT=0','ENDPOINT_DRIVER=NONE','FINAL_TECHNICAL_STATE=PASS_CLEAN_PRELOAD_STATE')) {
    if (-not $linuxText.Contains($required,[StringComparison]::Ordinal)) { throw "LINUX_RELEASE_PRECONDITION_MISSING=$required" }
}
if (-not (Test-Path -LiteralPath $lockDir -PathType Container)) { throw 'CONTROLLER_LOCK_DIRECTORY_MISSING' }
$resolved = (Resolve-Path -LiteralPath $lockDir).Path
if ($resolved -cne $lockDir) { throw "CONTROLLER_LOCK_TARGET_MISMATCH=$resolved" }
$children = @(Get-ChildItem -LiteralPath $lockDir -Force)
if ($children.Count -ne 1 -or $children[0].Name -cne 'receipt.json' -or -not $children[0].PSIsContainer -eq $false) {
    throw 'CONTROLLER_LOCK_CONTENTS_UNEXPECTED'
}
$lock = Get-Content -LiteralPath $lockReceipt -Raw | ConvertFrom-Json
if ($lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.state -cne 'HELD' -or $lock.linux_lock_state -cne 'HELD') {
    throw 'CONTROLLER_LOCK_NOT_OWNED_BY_R3'
}
$originalHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $lockReceipt).Hash
$linuxEvidenceHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $linuxReleaseEvidence).Hash
$releasedUtc = [DateTime]::UtcNow.ToString('o')

Remove-Item -LiteralPath $lockReceipt -Force
Remove-Item -LiteralPath $lockDir
if (Test-Path -LiteralPath $lockDir) { throw 'CONTROLLER_LOCK_RELEASE_FAILED' }

$receipt = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R3'
    state = 'RELEASED'
    released_utc = $releasedUtc
    exact_released_path = $lockDir
    original_lock_receipt_sha256 = $originalHash
    linux_lock_release_evidence_sha256 = $linuxEvidenceHash
    module_load_attempts = 0
    final_technical_state = 'PASS_CLEAN_PRELOAD_STATE'
    governance_result = 'FAIL_PRIOR_IMMUTABLE_ARTIFACT_BOUNDARY_VIOLATION'
}
[IO.File]::WriteAllText($releaseReceipt, ($receipt | ConvertTo-Json -Depth 4) + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
Write-Output 'CONTROLLER_LOCK_RELEASED=YES'
Write-Output "CONTROLLER_LOCK_RELEASE_RECEIPT=$releaseReceipt"
