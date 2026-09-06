Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\final_dut_state_before_lock_release.sh'
$Evidence = Join-Path $TaskRoot 'raw\FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log'
$T1Decision = Join-Path $TaskRoot 'raw\T1_DRIVER_GATE_DECISION.json'
$FinalJtag = Join-Path $TaskRoot 'raw\JTAG_FINAL_SESSION.csv'

foreach ($required in @($ControllerLock, $ScriptPath, $T1Decision, $FinalJtag)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "FINAL_STATE_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $Evidence) { throw 'FINAL_STATE_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
$t1 = Get-Content -LiteralPath $T1Decision -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or $lock.linux_post_reboot_lock_state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $t1.result -ne 'BLOCKED' -or $t1.first_blocker -ne 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE' -or $t1.decision -ne 'DO_NOT_LOAD_OR_BIND') {
    throw 'LOCK_OR_T1_DECISION_FAILED_BEFORE_FINAL_STATE'
}
$finalCsv = Import-Csv -LiteralPath $FinalJtag
if ($finalCsv.Count -ne 5 -or @($finalCsv | Where-Object { $_.done -ne '1' -or $_.part -ne 'xc7a35t' -or $_.idcode -ne '0362D093' }).Count -ne 0) {
    throw 'FINAL_JTAG_CSV_NOT_PASS'
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_FINAL_DUT_STATE_BEFORE_LOCK_RELEASE' `
    -SendPasswordToStdin `
    -SudoPasswordCopies 2 `
    -TimeoutSeconds 60)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
