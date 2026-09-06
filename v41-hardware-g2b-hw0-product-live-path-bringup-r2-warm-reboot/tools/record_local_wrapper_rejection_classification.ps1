Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$RejectedEvidence = Join-Path $TaskRoot 'raw\WARM_REBOOT_COMMAND.log'
$RejectedSupervisor = Join-Path $TaskRoot 'raw\WARM_REBOOT_ISSUANCE_SUPERVISOR.json'
$NoRebootVerify = Join-Path $TaskRoot 'raw\AFTER_LOCAL_REJECTION_NO_REBOOT_VERIFY.log'
$ClassificationPath = Join-Path $TaskRoot 'raw\LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json'
$CorrectionPath = Join-Path $TaskRoot 'raw\CONTROLLER_LOCK_BOOKKEEPING_CORRECTION.json'
$CorrectedSnapshotPath = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_AFTER_LOCAL_REJECTION_CORRECTION.json'
$ExpectedBootId = '37131b8d-0e38-4b4e-b77a-b3bda55b4e97'

foreach ($source in @($RejectedEvidence, $RejectedSupervisor, $NoRebootVerify, $ControllerLock)) {
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "MISSING_REQUIRED_SOURCE=$source"
    }
}
foreach ($destination in @($ClassificationPath, $CorrectionPath, $CorrectedSnapshotPath)) {
    if (Test-Path -LiteralPath $destination) {
        throw "CLASSIFICATION_DESTINATION_ALREADY_EXISTS=$destination"
    }
}

$evidenceText = Get-Content -LiteralPath $RejectedEvidence -Raw
$noRebootText = Get-Content -LiteralPath $NoRebootVerify -Raw
$oldSupervisor = Get-Content -LiteralPath $RejectedSupervisor -Raw | ConvertFrom-Json
$oldLockText = Get-Content -LiteralPath $ControllerLock -Raw
$oldLock = $oldLockText | ConvertFrom-Json

$requiredRejectedMarkers = @(
    'RESULT=SANITIZED_ARGUMENT_STRUCTURE',
    'EXIT_CODE=99',
    'ARGUMENT_TOKEN_AUDIT=NOT_RUN',
    'INHERITED_ENVIRONMENT_AUDIT=NOT_RUN',
    'PWFILE_CREATED=NO',
    'STDOUT_BEGIN',
    'STDOUT_END',
    'STDERR_BEGIN',
    'STDERR_END'
)
foreach ($marker in $requiredRejectedMarkers) {
    if (-not $evidenceText.Contains($marker, [StringComparison]::Ordinal)) {
        throw "REJECTED_EVIDENCE_MARKER_MISSING=$marker"
    }
}
if ($evidenceText -notmatch 'STDOUT_BEGIN\r?\n\r?\nSTDOUT_END' -or
    $evidenceText -notmatch 'STDERR_BEGIN\r?\n\r?\nSTDERR_END') {
    throw 'REJECTED_EVIDENCE_REMOTE_OUTPUT_NOT_EMPTY'
}
foreach ($marker in @(
    'RESULT=PASS',
    'EXIT_CODE=0',
    'ARGUMENT_TOKEN_AUDIT=PASS',
    'PWFILE_CREATED=YES',
    'HOSTNAME=VCDE-DUT-1',
    "BOOT_ID=$ExpectedBootId",
    'LINUX_LOCK=HELD'
)) {
    if (-not $noRebootText.Contains($marker, [StringComparison]::Ordinal)) {
        throw "NO_REBOOT_VERIFICATION_MARKER_MISSING=$marker"
    }
}
if ([int]$oldSupervisor.helper_exit_code -ne 99 -or
    $oldSupervisor.acknowledgement -ne 'AMBIGUOUS_STOP_NO_RETRY') {
    throw 'REJECTED_SUPERVISOR_UNEXPECTED'
}
if ($oldLock.task -ne 'G2B-HW0-PRODUCT-R2' -or $oldLock.state -ne 'HELD' -or
    [int]$oldLock.warm_reboots_executed -ne 1 -or -not [bool]$oldLock.reboot_budget_consumed) {
    throw 'LIVE_LOCK_PRE_CORRECTION_STATE_UNEXPECTED'
}

$utc = [DateTime]::UtcNow.ToString('o')
$sourceHashes = [ordered]@{
    rejected_wrapper_evidence_sha256 = (Get-FileHash -LiteralPath $RejectedEvidence -Algorithm SHA256).Hash
    rejected_wrapper_supervisor_sha256 = (Get-FileHash -LiteralPath $RejectedSupervisor -Algorithm SHA256).Hash
    same_boot_verification_sha256 = (Get-FileHash -LiteralPath $NoRebootVerify -Algorithm SHA256).Hash
    controller_lock_pre_correction_sha256 = (Get-FileHash -LiteralPath $ControllerLock -Algorithm SHA256).Hash
}
$classification = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = $utc
    result = 'PASS'
    determination = 'LOCAL_PRE_EXECUTION_ARGUMENT_REJECTION'
    local_wrapper_attempts = 1
    argument_token_audit = 'NOT_RUN'
    password_file_created = $false
    child_process_started = $false
    plink_started = $false
    ssh_connection_attempted = $false
    remote_stdout_bytes = 0
    remote_stderr_bytes = 0
    remote_reboot_commands_issued = 0
    reboot_schedule_acknowledgements = 0
    warm_reboots_executed = 0
    maximum_warm_reboots = 1
    authorized_reboot_budget_remaining = 1
    same_dut_reachable_after_rejection = $true
    verified_post_rejection_boot_id = $ExpectedBootId
    pre_reboot_boot_id_unchanged = $true
    linux_lock_still_held = $true
    original_evidence_preserved = $true
    original_supervisor_preserved = $true
    rationale = 'The helper rejected the command during controller-local argument validation before password-file creation or child-process launch. No Plink process, SSH session, remote command, reboot acknowledgement, or reboot occurred.'
    source_sha256 = $sourceHashes
}
$classification | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ClassificationPath -Encoding utf8

$correctedLock = [ordered]@{
    task = [string]$oldLock.task
    candidate_sha256 = [string]$oldLock.candidate_sha256
    controller_identity = [string]$oldLock.controller_identity
    controller_user = [string]$oldLock.controller_user
    dut_identity = [string]$oldLock.dut_identity
    pre_reboot_boot_id = [string]$oldLock.pre_reboot_boot_id
    task_owner_session = [string]$oldLock.task_owner_session
    acquired_utc = [string]$oldLock.acquired_utc
    maximum_warm_reboots = 1
    local_wrapper_attempts = 1
    local_wrapper_rejections = 1
    remote_reboot_command_delivery_attempts = 0
    remote_reboot_command_deliveries = 0
    warm_reboots_executed = 0
    reboot_budget_consumed = $false
    authorized_reboot_budget_remaining = 1
    remote_reboot_command_status = 'NOT_ISSUED'
    state = 'HELD'
    release_state = 'PENDING_FINAL_STATE_CAPTURE'
    controller_lock_revision = 2
    bookkeeping_correction_utc = $utc
    bookkeeping_correction_reason = 'LOCAL_PRE_EXECUTION_ARGUMENT_REJECTION'
    classification_receipt = 'raw/LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json'
    original_rejection_supervisor = 'raw/WARM_REBOOT_ISSUANCE_SUPERVISOR.json'
}

$correction = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = $utc
    result = 'PASS'
    correction_scope = 'LIVE_CONTROLLER_LOCK_BOOKKEEPING_ONLY'
    preserved_original_supervisor = 'raw/WARM_REBOOT_ISSUANCE_SUPERVISOR.json'
    preserved_original_evidence = 'raw/WARM_REBOOT_COMMAND.log'
    classification = 'raw/LOCAL_REBOOT_WRAPPER_REJECTION_CLASSIFICATION.json'
    original_live_lock_sha256 = $sourceHashes.controller_lock_pre_correction_sha256
    classification_sha256 = (Get-FileHash -LiteralPath $ClassificationPath -Algorithm SHA256).Hash
    prior_bookkeeping = [ordered]@{
        warm_reboots_executed = 1
        reboot_budget_consumed = $true
        reboot_command_number = 1
        reboot_acknowledgement = 'AMBIGUOUS_STOP_NO_RETRY'
    }
    corrected_bookkeeping = [ordered]@{
        local_wrapper_attempts = 1
        remote_reboot_command_delivery_attempts = 0
        remote_reboot_command_deliveries = 0
        warm_reboots_executed = 0
        reboot_budget_consumed = $false
        authorized_reboot_budget_remaining = 1
        remote_reboot_command_status = 'NOT_ISSUED'
    }
    correction_basis = 'Conclusive pre-dispatch evidence: argument audit NOT_RUN, password file not created, no child process, empty stdout/stderr, and same boot ID verified afterward.'
}
$correction | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CorrectionPath -Encoding utf8
$correctedLock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8
$correctedLock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CorrectedSnapshotPath -Encoding utf8

$verifyLock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($verifyLock.state -ne 'HELD' -or [int]$verifyLock.warm_reboots_executed -ne 0 -or
    [bool]$verifyLock.reboot_budget_consumed -or [int]$verifyLock.authorized_reboot_budget_remaining -ne 1 -or
    [int]$verifyLock.remote_reboot_command_deliveries -ne 0) {
    throw 'LIVE_LOCK_POST_CORRECTION_VERIFY_FAILED'
}

Write-Output 'LOCAL_WRAPPER_REJECTION_CLASSIFICATION=PASS'
Write-Output 'REMOTE_REBOOT_COMMANDS_ISSUED=0'
Write-Output 'WARM_REBOOTS_EXECUTED=0'
Write-Output 'AUTHORIZED_REBOOT_BUDGET_REMAINING=1'
Write-Output 'CONTROLLER_LOCK=HELD'
