Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\post_reboot_pcie_xdma_inventory.sh'
$Evidence = Join-Path $TaskRoot 'raw\POST_REBOOT_PCIE_XDMA_INVENTORY.log'
$JtagGate = Join-Path $TaskRoot 'raw\POST_REBOOT_JTAG_RETENTION_GATE.json'

foreach ($required in @($ControllerLock, $ScriptPath, $JtagGate)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "PCIE_INVENTORY_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $Evidence) { throw 'PCIE_INVENTORY_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
$jtag = Get-Content -LiteralPath $JtagGate -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or $lock.linux_post_reboot_lock_state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $jtag.result -ne 'PASS' -or $jtag.candidate_retained_across_warm_reboot -ne 'PASS' -or [int]$jtag.fpga_program_operations_this_session -ne 0) {
    throw 'LOCK_OR_JTAG_GATE_FAILED_BEFORE_PCIE_INVENTORY'
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_POST_REBOOT_PCIE_XDMA_READ_ONLY_INVENTORY' `
    -SendPasswordToStdin `
    -SudoPasswordCopies 2 `
    -TimeoutSeconds 60)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
