Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ClassificationPath = Join-Path $TaskRoot 'raw\LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json'
$CorrectionPath = Join-Path $TaskRoot 'raw\CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json'
$Evidence = Join-Path $TaskRoot 'raw\WARM_REBOOT_COMMAND_DELIVERED.log'
$ArmingReceipt = Join-Path $TaskRoot 'raw\WARM_REBOOT_REMOTE_DELIVERY_ARMING_RECEIPT.json'
$SupervisorReceipt = Join-Path $TaskRoot 'raw\WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json'
$ExpectedBootId = '37131b8d-0e38-4b4e-b77a-b3bda55b4e97'

foreach ($required in @(
    $ControllerLock,
    $Helper,
    $Plink,
    $ClassificationPath,
    $CorrectionPath,
    (Join-Path $TaskRoot 'raw\PRE_REBOOT_AUTHORITY_RECEIPT.json'),
    (Join-Path $TaskRoot 'raw\REBOOT_RECOVERY_PLAN.json'),
    (Join-Path $TaskRoot 'raw\WARM_REBOOT_COMMAND.log'),
    (Join-Path $TaskRoot 'raw\WARM_REBOOT_ISSUANCE_SUPERVISOR.json')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "MISSING_REQUIRED_PRECONDITION=$required"
    }
}
foreach ($destination in @($Evidence, $ArmingReceipt, $SupervisorReceipt)) {
    if (Test-Path -LiteralPath $destination) {
        throw "REMOTE_DELIVERY_DESTINATION_ALREADY_EXISTS=$destination"
    }
}

$classification = Get-Content -LiteralPath $ClassificationPath -Raw | ConvertFrom-Json
if ($classification.result -ne 'PASS' -or
    $classification.determination -ne 'LOCAL_PRE_EXECUTION_ARGUMENT_REJECTION' -or
    [int]$classification.local_wrapper_attempts -ne 1 -or
    [int]$classification.remote_reboot_commands_issued -ne 0 -or
    [int]$classification.warm_reboots_executed -ne 0 -or
    [int]$classification.authorized_reboot_budget_remaining -ne 1) {
    throw 'LOCAL_REJECTION_CLASSIFICATION_MISMATCH'
}
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.task -ne 'G2B-HW0-PRODUCT-R2' -or $lock.state -ne 'HELD' -or
    [int]$lock.local_wrapper_attempts -ne 1 -or
    [int]$lock.remote_reboot_command_delivery_attempts -ne 0 -or
    [int]$lock.remote_reboot_command_deliveries -ne 0 -or
    [int]$lock.warm_reboots_executed -ne 0 -or
    [bool]$lock.reboot_budget_consumed -or
    [int]$lock.authorized_reboot_budget_remaining -ne 1 -or
    $lock.remote_reboot_command_status -ne 'NOT_ISSUED') {
    throw 'CONTROLLER_LOCK_NOT_ARMABLE_FOR_ONLY_REMOTE_DELIVERY'
}

$remoteCommand = @"
set -euo pipefail
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=FIRST_AND_ONLY_AUTHORIZED_REMOTE_WARM_REBOOT_DELIVERY
echo COMMAND_DELIVERY_UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -u)" = 1000
echo REMOTE_USER=`$(id -un)
test "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "`$(cat /proc/sys/kernel/random/boot_id)" = $ExpectedBootId
test -d /tmp/ahd-g2b-hw0-product-r2.lock
test -f /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R2"' /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
echo PRE_REBOOT_BOOT_ID=$ExpectedBootId
echo LINUX_LOCK_PRE_REBOOT=HELD
echo MAXIMUM_WARM_REBOOTS=1
echo REMOTE_REBOOT_COMMAND_NUMBER=1
set +e
sudo -S -p '' /usr/bin/systemd-run --unit=ahd-g2b-hw0-product-r2-warm-reboot --on-active=3s --collect /usr/bin/systemctl reboot
rc=`$?
set -e
echo SYSTEMD_RUN_EXIT_CODE=`$rc
test `$rc -eq 0
echo REBOOT_SCHEDULE_ACKNOWLEDGED=YES
exit 0
"@

$armedUtc = [DateTime]::UtcNow.ToString('o')
$remoteCommandBytes = [Text.Encoding]::UTF8.GetBytes($remoteCommand)
$remoteCommandSha = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($remoteCommandBytes))
$arming = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    armed_at_utc = $armedUtc
    result = 'ARMED'
    authorization = 'OWNER_WARM_REBOOT_AUTHORIZATION=GRANTED'
    maximum_warm_reboots = 1
    local_wrapper_attempts_before_arming = 1
    remote_reboot_command_delivery_attempts_before_arming = 0
    remote_reboot_command_deliveries_before_arming = 0
    warm_reboots_executed_before_arming = 0
    authorized_reboot_budget_before_arming = 1
    remote_command_sha256 = $remoteCommandSha
    evidence_destination = 'raw/WARM_REBOOT_COMMAND_DELIVERED.log'
    no_retry_after_process_launch = $true
    controller_lock_continues_held = $true
}
$arming | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ArmingReceipt -Encoding utf8

# Consume the only delivery budget before invoking the helper. If execution becomes
# ambiguous after this point, the controller guard forbids any second delivery.
$lock.remote_reboot_command_delivery_attempts = 1
$lock.reboot_budget_consumed = $true
$lock.authorized_reboot_budget_remaining = 0
$lock.remote_reboot_command_status = 'DELIVERY_IN_PROGRESS_NO_RETRY'
$lock | Add-Member -NotePropertyName remote_delivery_armed_utc -NotePropertyValue $armedUtc -Force
$lock | Add-Member -NotePropertyName remote_delivery_arming_receipt -NotePropertyValue 'raw/WARM_REBOOT_REMOTE_DELIVERY_ARMING_RECEIPT.json' -Force
$lock.controller_lock_revision = 3
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8

$helperOutput = @()
$helperExit = -1
$helperException = $null
try {
    $helperOutput = @(& $Helper `
        -PlinkPath $Plink `
        -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
        -RemoteCommand $remoteCommand `
        -EvidencePath $Evidence `
        -ExpectedIp '10.132.1.111' `
        -ExpectedUser 'vcdeagent1' `
        -EvidenceKind 'R2_SINGLE_AUTHORIZED_WARM_REBOOT_REMOTE_DELIVERY' `
        -SendPasswordToStdin `
        -SudoPasswordCopies 1 `
        -TimeoutSeconds 30)
    $helperExit = $LASTEXITCODE
}
catch {
    $helperException = $_.Exception.Message
    $helperExit = 255
}
finally {
    $endedUtc = [DateTime]::UtcNow.ToString('o')
    $evidenceText = if (Test-Path -LiteralPath $Evidence -PathType Leaf) {
        Get-Content -LiteralPath $Evidence -Raw
    } else {
        ''
    }
    $argumentAuditPassed = $evidenceText.Contains('ARGUMENT_TOKEN_AUDIT=PASS', [StringComparison]::Ordinal)
    $pwfileCreated = $evidenceText.Contains('PWFILE_CREATED=YES', [StringComparison]::Ordinal)
    $scheduleAcknowledged = (
        $helperExit -eq 0 -and
        $evidenceText.Contains('RESULT=PASS', [StringComparison]::Ordinal) -and
        $evidenceText.Contains('SYSTEMD_RUN_EXIT_CODE=0', [StringComparison]::Ordinal) -and
        $evidenceText.Contains('REBOOT_SCHEDULE_ACKNOWLEDGED=YES', [StringComparison]::Ordinal)
    )

    $lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
    $lock.remote_reboot_command_deliveries = $(if ($scheduleAcknowledged) { 1 } else { 0 })
    $lock.remote_reboot_command_status = $(if ($scheduleAcknowledged) { 'SCHEDULE_ACKNOWLEDGED_NO_RETRY' } else { 'AMBIGUOUS_STOP_NO_RETRY' })
    $lock | Add-Member -NotePropertyName remote_delivery_helper_end_utc -NotePropertyValue $endedUtc -Force
    $lock | Add-Member -NotePropertyName remote_delivery_helper_exit_code -NotePropertyValue $helperExit -Force
    $lock | Add-Member -NotePropertyName remote_delivery_argument_audit_passed -NotePropertyValue $argumentAuditPassed -Force
    $lock | Add-Member -NotePropertyName remote_delivery_password_file_created -NotePropertyValue $pwfileCreated -Force
    $lock | Add-Member -NotePropertyName remote_reboot_schedule_acknowledged -NotePropertyValue $scheduleAcknowledged -Force
    $lock.controller_lock_revision = 4
    $lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8

    $supervisor = [ordered]@{
        task = 'G2B-HW0-PRODUCT-R2'
        armed_utc = $armedUtc
        helper_end_utc = $endedUtc
        helper_exit_code = $helperExit
        helper_exception = $helperException
        helper_output = $helperOutput
        argument_token_audit_passed = $argumentAuditPassed
        password_file_created = $pwfileCreated
        remote_reboot_command_delivery_attempts = 1
        remote_reboot_command_deliveries = $(if ($scheduleAcknowledged) { 1 } else { 0 })
        reboot_schedule_acknowledged = $scheduleAcknowledged
        warm_reboots_executed = 0
        warm_reboot_execution_confirmation = 'PENDING_AUTHENTICATED_BOOT_ID_CHANGE'
        reboot_budget_consumed = $true
        authorized_reboot_budget_remaining = 0
        maximum_warm_reboots = 1
        second_reboot_authorized = $false
        controller_lock_continues_held = $true
        disposition = $(if ($scheduleAcknowledged) { 'MONITOR_EXACT_IP_NO_RETRY' } else { 'AMBIGUOUS_STOP_NO_RETRY' })
    }
    $supervisor | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SupervisorReceipt -Encoding utf8
}

$helperOutput | ForEach-Object { Write-Output $_ }
Write-Output 'REMOTE_REBOOT_COMMAND_DELIVERY_ATTEMPTS=1'
Write-Output "REMOTE_REBOOT_SCHEDULE_ACKNOWLEDGED=$(if ($helperExit -eq 0) { 'YES' } else { 'NO' })"
Write-Output 'WARM_REBOOT_BUDGET_CONSUMED=YES'
Write-Output 'SECOND_REBOOT_AUTHORIZED=NO'
Write-Output 'CONTROLLER_LOCK=HELD'
Write-Output "HELPER_EXIT_CODE=$helperExit"
exit $helperExit
