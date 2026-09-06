Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ExpectedLockDir = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$ControllerReceipt = Join-Path $ExpectedLockDir 'receipt.json'
$FinalValidation = Join-Path $TaskRoot 'raw\FINAL_STATE_VALIDATION.json'
$LinuxReleaseReceipt = Join-Path $TaskRoot 'locks\LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json'
$ReleaseReceiptPath = Join-Path $TaskRoot 'raw\CONTROLLER_LOCK_RELEASE_RECEIPT.json'
$ArchiveDir = Join-Path $TaskRoot 'raw\CONTROLLER_LOCK_RELEASED_ARCHIVE'
$ArchiveReceiptPath = Join-Path $ArchiveDir 'receipt.json'
$OperationLogPath = Join-Path $TaskRoot 'raw\CONTROLLER_LOCK_RELEASE_OPERATION.json'

foreach ($required in @($ControllerReceipt, $FinalValidation, $LinuxReleaseReceipt)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "CONTROLLER_RELEASE_PRECONDITION_MISSING=$required" }
}
foreach ($destination in @($ReleaseReceiptPath, $ArchiveDir, $ArchiveReceiptPath, $OperationLogPath)) {
    if (Test-Path -LiteralPath $destination) { throw "CONTROLLER_RELEASE_DESTINATION_EXISTS=$destination" }
}
$resolvedLockDir = (Resolve-Path -LiteralPath $ExpectedLockDir).Path
$expectedFull = [IO.Path]::GetFullPath($ExpectedLockDir).TrimEnd([IO.Path]::DirectorySeparatorChar)
$resolvedFull = [IO.Path]::GetFullPath($resolvedLockDir).TrimEnd([IO.Path]::DirectorySeparatorChar)
if (-not $resolvedFull.Equals($expectedFull, [StringComparison]::OrdinalIgnoreCase)) {
    throw "CONTROLLER_LOCK_RESOLVED_PATH_MISMATCH=$resolvedFull"
}
$entries = @(Get-ChildItem -LiteralPath $resolvedFull -Force)
if ($entries.Count -ne 1 -or $entries[0].Name -ne 'receipt.json' -or $entries[0].PSIsContainer) {
    throw 'CONTROLLER_LOCK_DIRECTORY_CONTENT_MISMATCH'
}
$validation = Get-Content -LiteralPath $FinalValidation -Raw | ConvertFrom-Json
$linuxRelease = Get-Content -LiteralPath $LinuxReleaseReceipt -Raw | ConvertFrom-Json
$lock = Get-Content -LiteralPath $ControllerReceipt -Raw | ConvertFrom-Json
if ($validation.result -ne 'PASS' -or $validation.engineering_gate -ne 'BLOCKED' -or
    $linuxRelease.lock_release_state -ne 'RELEASED_AFTER_FINAL_STATE_CAPTURE' -or
    $lock.task -ne 'G2B-HW0-PRODUCT-R2' -or $lock.state -ne 'HELD' -or
    $lock.linux_post_reboot_lock_state -ne 'RELEASED_AFTER_FINAL_STATE_CAPTURE' -or
    $lock.release_state -ne 'READY_FOR_CONTROLLER_LOCK_RELEASE' -or
    $lock.first_blocker -ne 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE') {
    throw 'CONTROLLER_LOCK_NOT_READY_FOR_LAST_RELEASE'
}

$releaseUtc = [DateTime]::UtcNow.ToString('o')
$lock.state = 'RELEASED'
$lock.release_state = 'RELEASED_AFTER_FINAL_STATE_CAPTURE'
$lock | Add-Member -NotePropertyName controller_lock_release_utc -NotePropertyValue $releaseUtc -Force
$lock | Add-Member -NotePropertyName final_state_capture -NotePropertyValue 'raw/FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log + raw/JTAG_FINAL_SESSION.csv' -Force
$lock | Add-Member -NotePropertyName final_controller_lock_present_after_release -NotePropertyValue $false -Force
$lock.controller_lock_revision = 9
New-Item -ItemType Directory -Path $ArchiveDir -ErrorAction Stop | Out-Null
$receiptText = $lock | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($ReleaseReceiptPath, $receiptText + "`n", [Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($ArchiveReceiptPath, $receiptText + "`n", [Text.UTF8Encoding]::new($false))
$releaseHash = (Get-FileHash -LiteralPath $ReleaseReceiptPath -Algorithm SHA256).Hash
if ((Get-FileHash -LiteralPath $ArchiveReceiptPath -Algorithm SHA256).Hash -ne $releaseHash) {
    throw 'CONTROLLER_RELEASE_ARCHIVE_HASH_MISMATCH'
}

Remove-Item -LiteralPath $ControllerReceipt -Force
if (@(Get-ChildItem -LiteralPath $resolvedFull -Force).Count -ne 0) {
    throw 'CONTROLLER_LOCK_DIRECTORY_NOT_EMPTY_AFTER_RECEIPT_REMOVAL'
}
Remove-Item -LiteralPath $resolvedFull -Force
if (Test-Path -LiteralPath $ExpectedLockDir) { throw 'CONTROLLER_LOCK_DIRECTORY_PRESENT_AFTER_RELEASE' }

$operation = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    result = 'PASS'
    released_at_utc = $releaseUtc
    resolved_lock_directory = $resolvedFull
    recursive_delete_used = $false
    receipt_removed_exactly = $true
    empty_directory_removed_exactly = $true
    controller_lock_present_after_release = $false
    release_receipt = 'raw/CONTROLLER_LOCK_RELEASE_RECEIPT.json'
    release_receipt_sha256 = $releaseHash
    linux_lock_released_first = $true
    controller_lock_released_last = $true
}
$operation | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $OperationLogPath -Encoding utf8
Write-Output 'CONTROLLER_LOCK_RELEASE_RESULT=PASS'
Write-Output 'CONTROLLER_LOCK_PRESENT_AFTER_RELEASE=NO'
Write-Output 'LINUX_LOCK_RELEASED_FIRST=YES'
Write-Output 'CONTROLLER_LOCK_RELEASED_LAST=YES'
Write-Output "CONTROLLER_LOCK_RELEASE_RECEIPT_SHA256=$releaseHash"
