Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\release_linux_task_lock_post_reboot.sh'
$Validation = Join-Path $TaskRoot 'raw\FINAL_STATE_VALIDATION.json'
$Evidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_RELEASE.log'
$ReleaseReceiptCopy = Join-Path $TaskRoot 'locks\LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json'
$ControllerSnapshot = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_AFTER_LINUX_RELEASE.json'

foreach ($required in @($ControllerLock, $ScriptPath, $Validation)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "LINUX_RELEASE_PRECONDITION_MISSING=$required" }
}
foreach ($destination in @($Evidence, $ReleaseReceiptCopy, $ControllerSnapshot)) {
    if (Test-Path -LiteralPath $destination) { throw "LINUX_RELEASE_DESTINATION_EXISTS=$destination" }
}
$validationData = Get-Content -LiteralPath $Validation -Raw | ConvertFrom-Json
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($validationData.result -ne 'PASS' -or $validationData.engineering_gate -ne 'BLOCKED' -or
    $lock.state -ne 'HELD' -or $lock.linux_post_reboot_lock_state -ne 'HELD' -or $lock.release_state -ne 'READY_FOR_LINUX_LOCK_RELEASE') {
    throw 'FINAL_VALIDATION_OR_CONTROLLER_LOCK_NOT_READY_FOR_LINUX_RELEASE'
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_LINUX_LOCK_POST_REBOOT_RELEASE' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
if ($exitCode -ne 0) { exit $exitCode }

$releaseText = Get-Content -LiteralPath $Evidence -Raw
foreach ($marker in @('RESULT=PASS','LINUX_LOCK_PRESENT_AFTER_RELEASE=NO','LINUX_LOCK_RELEASE_RESULT=PASS','RELEASED_RECEIPT_BEGIN','RELEASED_RECEIPT_END')) {
    if (-not $releaseText.Contains($marker, [StringComparison]::Ordinal)) { throw "LINUX_RELEASE_MARKER_MISSING=$marker" }
}
$hashMatch = [regex]::Match($releaseText, '(?m)^RELEASED_RECEIPT_SHA256=([0-9a-f]{64})$')
$jsonMatch = [regex]::Match($releaseText, '(?ms)^\{\r?\n.*?^\}\r?$')
if (-not $hashMatch.Success -or -not $jsonMatch.Success) { throw 'LINUX_RELEASE_RECEIPT_OR_HASH_MISSING' }
$receiptText = ($jsonMatch.Value -replace "\r\n", "\n").TrimEnd("`r", "`n") + "`n"
[IO.File]::WriteAllText($ReleaseReceiptCopy, $receiptText, [Text.UTF8Encoding]::new($false))
$localHash = (Get-FileHash -LiteralPath $ReleaseReceiptCopy -Algorithm SHA256).Hash
if ($localHash -ne $hashMatch.Groups[1].Value.ToUpperInvariant()) { throw 'LINUX_RELEASE_RECEIPT_HASH_MISMATCH' }
$receipt = Get-Content -LiteralPath $ReleaseReceiptCopy -Raw | ConvertFrom-Json
if ($receipt.lock_release_state -ne 'RELEASED_AFTER_FINAL_STATE_CAPTURE' -or $receipt.first_blocker -ne 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE') {
    throw 'LINUX_RELEASE_RECEIPT_SEMANTIC_MISMATCH'
}

$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
$lock.linux_post_reboot_lock_state = 'RELEASED_AFTER_FINAL_STATE_CAPTURE'
$lock | Add-Member -NotePropertyName linux_post_reboot_lock_release_receipt -NotePropertyValue 'locks/LINUX_LOCK_POST_REBOOT_RELEASE_RECEIPT.json' -Force
$lock | Add-Member -NotePropertyName linux_post_reboot_lock_release_receipt_sha256 -NotePropertyValue $localHash -Force
$lock.release_state = 'READY_FOR_CONTROLLER_LOCK_RELEASE'
$lock.controller_lock_revision = 8
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerSnapshot -Encoding utf8
Write-Output 'LINUX_LOCK_RELEASE_RESULT=PASS'
Write-Output "LINUX_LOCK_RELEASE_RECEIPT_SHA256=$localHash"
Write-Output 'CONTROLLER_LOCK=HELD'
Write-Output 'CONTROLLER_LOCK_RELEASE_READY=YES'
