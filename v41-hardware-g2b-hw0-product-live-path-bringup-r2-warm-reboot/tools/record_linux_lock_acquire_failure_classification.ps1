Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$FailedEvidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE.log'
$DiagnosticEvidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_DIAGNOSTIC.log'
$FailedScript = Join-Path $TaskRoot 'tools\acquire_linux_lock_post_reboot.sh'
$ClassificationPath = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_CLASSIFICATION.json'

foreach ($required in @($FailedEvidence, $DiagnosticEvidence, $FailedScript)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "LOCK_FAILURE_SOURCE_MISSING=$required" }
}
if (Test-Path -LiteralPath $ClassificationPath) { throw 'LOCK_FAILURE_CLASSIFICATION_ALREADY_EXISTS' }
$failedText = Get-Content -LiteralPath $FailedEvidence -Raw
$diagnosticText = Get-Content -LiteralPath $DiagnosticEvidence -Raw
foreach ($marker in @('RESULT=FAIL','EXIT_CODE=1','ARGUMENT_TOKEN_AUDIT=PASS','PWFILE_CREATED=YES')) {
    if (-not $failedText.Contains($marker, [StringComparison]::Ordinal)) { throw "FAILED_LOCK_MARKER_MISSING=$marker" }
}
foreach ($marker in @(
    'GUARD_HOSTNAME=PASS','GUARD_UID=PASS','GUARD_MACHINE_ID=PASS','GUARD_BOOT_ID=PASS',
    'GUARD_NEW_LOCK_ABSENT=PASS','GUARD_OLD_LOCK_ABSENT=PASS','GUARD_RELEVANT_PROCESSES=PASS',
    'GUARD_XDMA_MODULE=PASS','GUARD_XDMA_NODES=PASS','TASK_LOCK_FIND_EXIT_CODE=1',
    'OTHER_TASK_LOCK_COUNT=0','GUARD_OTHER_TASK_LOCKS=PASS','RESULT=COMPLETE'
)) {
    if (-not $diagnosticText.Contains($marker, [StringComparison]::Ordinal)) { throw "LOCK_DIAGNOSTIC_MARKER_MISSING=$marker" }
}
$classification = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = [DateTime]::UtcNow.ToString('o')
    result = 'PASS'
    determination = 'PRE_MUTATION_TASK_LOCK_GUARD_PIPELINE_REJECTION'
    post_reboot_linux_lock_acquire_attempts = 1
    post_reboot_linux_lock_mutations_completed = 0
    post_reboot_linux_lock_created = $false
    hardware_mutations = 0
    cause = 'With pipefail enabled, the lock-namespace find command returned 1 on unreadable systemd-private directories before mkdir executed; the count itself was zero.'
    corrective_action = 'Use depth-one lock-namespace enumeration that does not descend into unrelated private directories, retain all identity/exclusivity guards, and write distinct evidence.'
    corrected_acquisition_authorized = $true
    original_evidence_preserved = $true
    source_sha256 = [ordered]@{
        failed_acquire_evidence = (Get-FileHash -LiteralPath $FailedEvidence -Algorithm SHA256).Hash
        failure_diagnostic = (Get-FileHash -LiteralPath $DiagnosticEvidence -Algorithm SHA256).Hash
        failed_acquire_script = (Get-FileHash -LiteralPath $FailedScript -Algorithm SHA256).Hash
    }
}
$classification | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ClassificationPath -Encoding utf8
Write-Output 'POST_REBOOT_LINUX_LOCK_FAILURE_CLASSIFICATION=PASS'
Write-Output 'LOCK_CREATED=NO'
Write-Output 'HARDWARE_MUTATIONS=0'
Write-Output 'CORRECTED_ACQUISITION_AUTHORIZED=YES'
