Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$AcquireEvidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_CORRECTED.log'
$RemoteEvidence = Join-Path $TaskRoot 'raw\POST_REBOOT_LOCKS_REMOTE_VERIFY.log'
$LinuxReceiptCopy = Join-Path $TaskRoot 'locks\LINUX_LOCK_POST_REBOOT_RECEIPT.json'
$CombinedReceipt = Join-Path $TaskRoot 'raw\POST_REBOOT_COMBINED_LOCK_VERIFICATION.json'
$ControllerSnapshot = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_POST_LINUX_RELOCK.json'

foreach ($required in @($ControllerLock, $AcquireEvidence)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "LOCK_VERIFY_SOURCE_MISSING=$required" }
}
foreach ($destination in @($RemoteEvidence, $LinuxReceiptCopy, $CombinedReceipt, $ControllerSnapshot)) {
    if (Test-Path -LiteralPath $destination) { throw "LOCK_VERIFY_DESTINATION_ALREADY_EXISTS=$destination" }
}
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $lock.post_reboot_boot_id -ne '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac') {
    throw 'CONTROLLER_LOCK_STATE_INVALID_FOR_COMBINED_VERIFY'
}

$remoteCommand = @"
set -euo pipefail
lock_path=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock
receipt_path=`$lock_path/receipt.json
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=POST_REBOOT_COMBINED_LOCK_VERIFY
echo UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -u)" = 1000
test "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "`$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
test -d "`$lock_path"
test -f "`$receipt_path"
python3 - "`$receipt_path" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as handle:
    r = json.load(handle)
expected = {
    'task_id': 'G2B-HW0-PRODUCT-R2',
    'candidate_bitstream_sha256': 'AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7',
    'hostname': 'VCDE-DUT-1',
    'pre_reboot_boot_id': '37131b8d-0e38-4b4e-b77a-b3bda55b4e97',
    'post_reboot_boot_id': '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac',
    'lock_phase': 'POST_REBOOT',
    'maximum_warm_reboots': 1,
    'warm_reboots_executed': 1,
    'authorized_reboot_budget_remaining': 0,
    'controller_lock_state': 'HELD',
    'lock_release_state': 'HELD',
}
for key, value in expected.items():
    if r.get(key) != value:
        raise SystemExit(f'LOCK_RECEIPT_MISMATCH:{key}')
print('LINUX_LOCK_RECEIPT_SEMANTICS=PASS')
PY
echo LINUX_LOCK_RECEIPT_SHA256=`$(sha256sum "`$receipt_path" | awk '{print `$1}')
echo LINUX_LOCK_DIRECTORY_STAT=`$(stat -c '%a:%U:%G' "`$lock_path")
echo LINUX_LOCK_RECEIPT_STAT=`$(stat -c '%a:%U:%G' "`$receipt_path")
relevant_process_count=`$(ps -eo comm= | awk 'BEGIN {IGNORECASE=1} /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$/ {count++} END {print count+0}')
echo RELEVANT_PROCESS_COUNT=`$relevant_process_count
test "`$relevant_process_count" -eq 0
xdma_module_count=`$(awk '`$1 == "xdma" {count++} END {print count+0}' /proc/modules)
echo XDMA_MODULE_COUNT=`$xdma_module_count
test "`$xdma_module_count" -eq 0
node_count=`$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)
echo XDMA_DEVICE_NODE_COUNT=`$node_count
test "`$node_count" -eq 0
task_lock_count=`$(find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 1 -type d \( -iname 'ahd*.lock' -o -iname 'g2b*.lock' -o -iname 'xdma*.lock' -o -iname 'fpga*.lock' \) -print | wc -l)
echo TASK_LOCK_COUNT=`$task_lock_count
test "`$task_lock_count" -eq 1
endpoint_count=`$(lspci -Dnnd 10ee:7011 | wc -l)
echo EXACT_AHD_ENDPOINT_COUNT=`$endpoint_count
test "`$endpoint_count" -eq 1
echo LINUX_POST_REBOOT_LOCK=HELD
echo RESULT=PASS
"@

$helperOutput = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $RemoteEvidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_POST_REBOOT_COMBINED_LOCK_VERIFY' `
    -TimeoutSeconds 30)
$helperExit = $LASTEXITCODE
$helperOutput | ForEach-Object { Write-Output $_ }
if ($helperExit -ne 0) { exit $helperExit }

$remoteText = Get-Content -LiteralPath $RemoteEvidence -Raw
foreach ($marker in @('RESULT=PASS','LINUX_LOCK_RECEIPT_SEMANTICS=PASS','RELEVANT_PROCESS_COUNT=0','XDMA_MODULE_COUNT=0','XDMA_DEVICE_NODE_COUNT=0','TASK_LOCK_COUNT=1','EXACT_AHD_ENDPOINT_COUNT=1','LINUX_POST_REBOOT_LOCK=HELD')) {
    if (-not $remoteText.Contains($marker, [StringComparison]::Ordinal)) { throw "REMOTE_LOCK_VERIFY_MARKER_MISSING=$marker" }
}
$remoteHashMatch = [regex]::Match($remoteText, '(?m)^LINUX_LOCK_RECEIPT_SHA256=([0-9a-f]{64})$')
if (-not $remoteHashMatch.Success) { throw 'REMOTE_LINUX_LOCK_HASH_MISSING' }
$remoteHash = $remoteHashMatch.Groups[1].Value.ToUpperInvariant()

$acquireText = Get-Content -LiteralPath $AcquireEvidence -Raw
$jsonMatch = [regex]::Match($acquireText, '(?ms)^\{\r?\n.*?^\}\r?$')
if (-not $jsonMatch.Success) { throw 'LINUX_LOCK_JSON_NOT_FOUND_IN_ACQUIRE_EVIDENCE' }
$receiptText = ($jsonMatch.Value -replace "\r\n", "\n").TrimEnd("`r", "`n") + "`n"
[IO.File]::WriteAllText($LinuxReceiptCopy, $receiptText, [Text.UTF8Encoding]::new($false))
$localHash = (Get-FileHash -LiteralPath $LinuxReceiptCopy -Algorithm SHA256).Hash
if ($localHash -ne $remoteHash) { throw "LINUX_LOCK_REMOTE_READBACK_HASH_MISMATCH local=$localHash remote=$remoteHash" }

$utc = [DateTime]::UtcNow.ToString('o')
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
$lock | Add-Member -NotePropertyName linux_post_reboot_lock_path -NotePropertyValue '/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock' -Force
$lock | Add-Member -NotePropertyName linux_post_reboot_lock_state -NotePropertyValue 'HELD' -Force
$lock | Add-Member -NotePropertyName linux_post_reboot_lock_receipt_sha256 -NotePropertyValue $localHash -Force
$lock | Add-Member -NotePropertyName post_reboot_combined_lock_verify_utc -NotePropertyValue $utc -Force
$lock.controller_lock_revision = 6
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerSnapshot -Encoding utf8

$combined = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = $utc
    result = 'PASS'
    controller_lock = 'HELD'
    controller_lock_revision = 6
    linux_post_reboot_lock = 'HELD'
    linux_post_reboot_lock_path = '/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock'
    linux_lock_receipt_remote_readback = 'PASS'
    linux_lock_receipt_sha256 = $localHash
    post_reboot_boot_id = '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac'
    relevant_process_count = 0
    xdma_module_count = 0
    xdma_device_node_count = 0
    exact_ahd_endpoint_count = 1
    warm_reboots_executed = 1
    authorized_reboot_budget_remaining = 0
}
$combined | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $CombinedReceipt -Encoding utf8
Write-Output 'POST_REBOOT_COMBINED_LOCK_VERIFICATION=PASS'
Write-Output 'LINUX_LOCK_REMOTE_READBACK=PASS'
Write-Output "LINUX_LOCK_RECEIPT_SHA256=$localHash"
Write-Output 'CONTROLLER_LOCK=HELD'
Write-Output 'LINUX_POST_REBOOT_LOCK=HELD'
