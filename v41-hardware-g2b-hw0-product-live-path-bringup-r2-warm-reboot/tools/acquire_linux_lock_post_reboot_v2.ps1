Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\acquire_linux_lock_post_reboot_v2.sh'
$Evidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED.log'
$Classification = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json'

foreach ($required in @($ControllerLock, $ScriptPath, $Classification)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "CORRECTED_LOCK_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $Evidence) { throw 'CORRECTED_POST_REBOOT_LOCK_EVIDENCE_ALREADY_EXISTS' }
$classificationData = Get-Content -LiteralPath $Classification -Raw | ConvertFrom-Json
if ($classificationData.result -ne 'PASS' -or $classificationData.determination -ne 'PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION' -or
    [int]$classificationData.post_reboot_linux_lock_mutations_completed -ne 0 -or -not [bool]$classificationData.corrected_acquisition_authorized) {
    throw 'LOCK_FAILURE_CLASSIFICATION_MISMATCH'
}
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $lock.post_reboot_boot_id -ne '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac' -or
    $lock.remote_reboot_command_status -ne 'EXECUTION_CONFIRMED_NO_RETRY') {
    throw 'CONTROLLER_LOCK_NOT_READY_FOR_CORRECTED_LINUX_RELOCK'
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
