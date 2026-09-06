Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\acquire_linux_lock_post_reboot.sh'
$Evidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE.log'
$ExclusivityEvidence = Join-Path $TaskRoot 'raw\POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK.log'

foreach ($required in @($ControllerLock, $ScriptPath, $ExclusivityEvidence)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "POST_REBOOT_LOCK_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $Evidence) { throw 'POST_REBOOT_LOCK_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $lock.post_reboot_boot_id -ne '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac' -or
    $lock.remote_reboot_command_status -ne 'EXECUTION_CONFIRMED_NO_RETRY') {
    throw 'CONTROLLER_LOCK_NOT_READY_FOR_LINUX_RELOCK'
}
$exclusivityText = Get-Content -LiteralPath $ExclusivityEvidence -Raw
foreach ($marker in @(
    'RESULT=PASS',
    'RELEVANT_PROCESS_COMMANDS_BEGIN',
    'RELEVANT_PROCESS_COMMANDS_END',
    'XDMA_MODULE_COUNT=0',
    'XDMA_DRIVER_SYSFS=ABSENT',
    'XDMA_DEVICE_NODE_COUNT=0',
    'TASK_LOCKS_BEGIN',
    'TASK_LOCKS_END',
    'PRE_REBOOT_LINUX_LOCK=ABSENT_AFTER_REBOOT',
    'POST_REBOOT_LINUX_LOCK=ABSENT_READY_TO_ACQUIRE',
    'EXACT_AHD_ENDPOINT_COUNT=1'
)) {
    if (-not $exclusivityText.Contains($marker, [StringComparison]::Ordinal)) { throw "POST_REBOOT_EXCLUSIVITY_MARKER_MISSING=$marker" }
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_LINUX_LOCK_POST_REBOOT_ACQUIRE' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
