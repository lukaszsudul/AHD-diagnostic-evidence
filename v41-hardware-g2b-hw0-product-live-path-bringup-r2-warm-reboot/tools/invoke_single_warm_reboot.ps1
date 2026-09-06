Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$Evidence = Join-Path $TaskRoot 'raw\WARM_REBOOT_COMMAND.log'
$SupervisorReceipt = Join-Path $TaskRoot 'raw\WARM_REBOOT_ISSUANCE_SUPERVISOR.json'
$ExpectedBootId = '37131b8d-0e38-4b4e-b77a-b3bda55b4e97'

if (-not (Test-Path -LiteralPath $ControllerLock -PathType Leaf)) {
    throw 'CONTROLLER_LOCK_MISSING'
}
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.task -ne 'G2B-HW0-PRODUCT-R2' -or $lock.state -ne 'HELD') {
    throw 'CONTROLLER_LOCK_STATE_MISMATCH'
}
if ([int]$lock.warm_reboots_executed -ne 0) {
    throw 'WARM_REBOOT_BUDGET_ALREADY_CONSUMED'
}
foreach ($required in @('raw\PRE_REBOOT_AUTHORITY_RECEIPT.json', 'raw\REBOOT_RECOVERY_PLAN.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $TaskRoot $required) -PathType Leaf)) {
        throw "MISSING_PRE_REBOOT_RECEIPT=$required"
    }
}
if (Test-Path -LiteralPath $Evidence) {
    throw 'WARM_REBOOT_EVIDENCE_ALREADY_EXISTS'
}

$issuedUtc = (Get-Date).ToUniversalTime().ToString('o')
$remoteCommand = @"
set -euo pipefail
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=SINGLE_AUTHORIZED_WARM_REBOOT
echo COMMAND_ISSUE_UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -un)" = vcdeagent1
test "`$(cat /proc/sys/kernel/random/boot_id)" = $ExpectedBootId
test -d /tmp/ahd-g2b-hw0-product-r2.lock
test -f /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
echo PRE_REBOOT_BOOT_ID=$ExpectedBootId
echo LINUX_LOCK_PRE_REBOOT=HELD
echo MAXIMUM_WARM_REBOOTS=1
echo REBOOT_COMMAND_NUMBER=1
sudo -S -p '' /usr/bin/systemd-run --unit=ahd-g2b-hw0-product-r2-warm-reboot --on-active=3s --collect /usr/bin/systemctl reboot
rc=`$?
echo SYSTEMD_RUN_EXIT_CODE=`$rc
echo REBOOT_SCHEDULE_ACKNOWLEDGED=YES
exit `$rc
"@

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
        -EvidenceKind 'R2_SINGLE_AUTHORIZED_WARM_REBOOT' `
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
    $endedUtc = (Get-Date).ToUniversalTime().ToString('o')
    $lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
    $lock.warm_reboots_executed = 1
    $lock | Add-Member -NotePropertyName reboot_budget_consumed -NotePropertyValue $true -Force
    $lock | Add-Member -NotePropertyName reboot_command_number -NotePropertyValue 1 -Force
    $lock | Add-Member -NotePropertyName reboot_command_issued_utc -NotePropertyValue $issuedUtc -Force
    $lock | Add-Member -NotePropertyName reboot_helper_end_utc -NotePropertyValue $endedUtc -Force
    $lock | Add-Member -NotePropertyName reboot_helper_exit_code -NotePropertyValue $helperExit -Force
    $lock | Add-Member -NotePropertyName reboot_acknowledgement -NotePropertyValue $(if ($helperExit -eq 0) { 'PASS' } else { 'AMBIGUOUS_STOP_NO_RETRY' }) -Force
    $lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8

    $supervisor = [ordered]@{
        task = 'G2B-HW0-PRODUCT-R2'
        issued_utc = $issuedUtc
        helper_end_utc = $endedUtc
        helper_exit_code = $helperExit
        helper_exception = $helperException
        helper_output = $helperOutput
        reboot_command_number = 1
        reboot_budget_consumed = $true
        maximum_warm_reboots = 1
        second_reboot_authorized = $false
        controller_lock_continues_held = $true
        acknowledgement = $(if ($helperExit -eq 0) { 'PASS' } else { 'AMBIGUOUS_STOP_NO_RETRY' })
    }
    $supervisor | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $SupervisorReceipt -Encoding utf8
}

$helperOutput | ForEach-Object { Write-Output $_ }
Write-Output "WARM_REBOOT_COMMAND_NUMBER=1"
Write-Output "WARM_REBOOT_BUDGET_CONSUMED=YES"
Write-Output "CONTROLLER_LOCK=HELD"
Write-Output "HELPER_EXIT_CODE=$helperExit"
exit $helperExit
