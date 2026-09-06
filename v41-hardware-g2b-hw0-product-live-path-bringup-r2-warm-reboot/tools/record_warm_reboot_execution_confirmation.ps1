Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$AcquireReceipt = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_ACQUIRE_RECEIPT.json'
$DeliveryEvidence = Join-Path $TaskRoot 'raw\WARM_REBOOT_COMMAND_DELIVERED.log'
$DeliverySupervisor = Join-Path $TaskRoot 'raw\WARM_REBOOT_REMOTE_DELIVERY_SUPERVISOR.json'
$ReconnectSummary = Join-Path $TaskRoot 'raw\EXACT_IP_RECONNECT_SUMMARY.json'
$IdentityEvidence = Join-Path $TaskRoot 'raw\POST_REBOOT_AUTHENTICATED_IDENTITY.log'
$ConfirmationPath = Join-Path $TaskRoot 'raw\WARM_REBOOT_EXECUTION_CONFIRMATION.json'
$LockSnapshotPath = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_POST_REBOOT_CONFIRMATION.json'
$OldBootId = '37131b8d-0e38-4b4e-b77a-b3bda55b4e97'

foreach ($required in @($ControllerLock, $AcquireReceipt, $DeliveryEvidence, $DeliverySupervisor, $ReconnectSummary, $IdentityEvidence)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "MISSING_CONFIRMATION_SOURCE=$required" }
}
foreach ($destination in @($ConfirmationPath, $LockSnapshotPath)) {
    if (Test-Path -LiteralPath $destination) { throw "CONFIRMATION_DESTINATION_ALREADY_EXISTS=$destination" }
}

$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
$supervisor = Get-Content -LiteralPath $DeliverySupervisor -Raw | ConvertFrom-Json
$reconnect = Get-Content -LiteralPath $ReconnectSummary -Raw | ConvertFrom-Json
$deliveryText = Get-Content -LiteralPath $DeliveryEvidence -Raw
$identityText = Get-Content -LiteralPath $IdentityEvidence -Raw

if ($lock.state -ne 'HELD' -or [int]$lock.remote_reboot_command_delivery_attempts -ne 1 -or
    [int]$lock.remote_reboot_command_deliveries -ne 1 -or [int]$lock.warm_reboots_executed -ne 0 -or
    -not [bool]$lock.reboot_budget_consumed -or [int]$lock.authorized_reboot_budget_remaining -ne 0 -or
    $lock.remote_reboot_command_status -ne 'SCHEDULE_ACKNOWLEDGED_NO_RETRY') {
    throw 'CONTROLLER_LOCK_PRE_CONFIRMATION_MISMATCH'
}
if (-not [bool]$supervisor.reboot_schedule_acknowledged -or [int]$supervisor.remote_reboot_command_deliveries -ne 1) {
    throw 'DELIVERY_SUPERVISOR_NOT_ACKNOWLEDGED'
}
if ($reconnect.result -ne 'PASS' -or -not [bool]$reconnect.ssh_disconnect_observed -or -not [bool]$reconnect.tcp_reconnect_observed) {
    throw 'RECONNECT_TRANSITION_NOT_PASS'
}
foreach ($marker in @('RESULT=PASS','SYSTEMD_RUN_EXIT_CODE=0','REBOOT_SCHEDULE_ACKNOWLEDGED=YES')) {
    if (-not $deliveryText.Contains($marker, [StringComparison]::Ordinal)) { throw "DELIVERY_MARKER_MISSING=$marker" }
}
foreach ($marker in @('RESULT=PASS',"PRE_REBOOT_BOOT_ID=$OldBootId",'BOOT_ID_CHANGED=YES','HOSTNAME=VCDE-DUT-1','MACHINE_ID=0e90f50d9465492b80258da5658446f8')) {
    if (-not $identityText.Contains($marker, [StringComparison]::Ordinal)) { throw "IDENTITY_MARKER_MISSING=$marker" }
}
$bootMatch = [regex]::Match($identityText, '(?m)^POST_REBOOT_BOOT_ID=([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})$')
if (-not $bootMatch.Success) { throw 'POST_REBOOT_BOOT_ID_NOT_FOUND' }
$newBootId = $bootMatch.Groups[1].Value
if ($newBootId -eq $OldBootId) { throw 'POST_REBOOT_BOOT_ID_DID_NOT_CHANGE' }

$utc = [DateTime]::UtcNow.ToString('o')
$confirmation = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = $utc
    result = 'PASS'
    reboot_type = 'GRACEFUL_OPERATING_SYSTEM_WARM_REBOOT'
    maximum_warm_reboots = 1
    remote_reboot_command_delivery_attempts = 1
    remote_reboot_command_deliveries = 1
    reboot_schedule_acknowledgements = 1
    warm_reboots_executed = 1
    second_reboot_attempted = $false
    second_reboot_authorized = $false
    power_cycle_attempted = $false
    pre_reboot_boot_id = $OldBootId
    post_reboot_boot_id = $newBootId
    authenticated_boot_id_change = $true
    exact_ip_disconnect_and_reconnect = $true
    controller_lock_held_through_transition = $true
    evidence_sha256 = [ordered]@{
        delivery = (Get-FileHash -LiteralPath $DeliveryEvidence -Algorithm SHA256).Hash
        delivery_supervisor = (Get-FileHash -LiteralPath $DeliverySupervisor -Algorithm SHA256).Hash
        reconnect_summary = (Get-FileHash -LiteralPath $ReconnectSummary -Algorithm SHA256).Hash
        authenticated_identity = (Get-FileHash -LiteralPath $IdentityEvidence -Algorithm SHA256).Hash
    }
}
$confirmation | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ConfirmationPath -Encoding utf8

$acquireText = Get-Content -LiteralPath $AcquireReceipt -Raw
$acquiredMatch = [regex]::Match($acquireText, '"acquired_utc"\s*:\s*"([^"]+)"')
if (-not $acquiredMatch.Success) { throw 'ORIGINAL_ACQUIRED_UTC_NOT_FOUND' }
$lock.acquired_utc = $acquiredMatch.Groups[1].Value
$lock.warm_reboots_executed = 1
$lock.remote_reboot_command_status = 'EXECUTION_CONFIRMED_NO_RETRY'
$lock | Add-Member -NotePropertyName warm_reboot_execution_confirmation -NotePropertyValue 'AUTHENTICATED_BOOT_ID_CHANGE' -Force
$lock | Add-Member -NotePropertyName post_reboot_boot_id -NotePropertyValue $newBootId -Force
$lock | Add-Member -NotePropertyName warm_reboot_confirmed_utc -NotePropertyValue $utc -Force
$lock | Add-Member -NotePropertyName warm_reboot_confirmation_receipt -NotePropertyValue 'raw/WARM_REBOOT_EXECUTION_CONFIRMATION.json' -Force
$lock.controller_lock_revision = 5
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $LockSnapshotPath -Encoding utf8

Write-Output 'WARM_REBOOT_EXECUTION_CONFIRMATION=PASS'
Write-Output 'WARM_REBOOTS_EXECUTED=1'
Write-Output "POST_REBOOT_BOOT_ID=$newBootId"
Write-Output 'SECOND_REBOOT_AUTHORIZED=NO'
Write-Output 'CONTROLLER_LOCK=HELD'
