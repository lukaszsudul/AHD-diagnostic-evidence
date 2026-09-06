Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$ScriptPath = Join-Path $TaskRoot 'tools\xdma_binding_feasibility_readonly.sh'
$Evidence = Join-Path $TaskRoot 'raw\XDMA_BINDING_FEASIBILITY_READONLY.log'
$PcieEvidence = Join-Path $TaskRoot 'raw\POST_REBOOT_PCIE_XDMA_INVENTORY.log'

foreach ($required in @($ControllerLock, $ScriptPath, $PcieEvidence)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "XDMA_FEASIBILITY_PRECONDITION_MISSING=$required" }
}
if (Test-Path -LiteralPath $Evidence) { throw 'XDMA_FEASIBILITY_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or $lock.linux_post_reboot_lock_state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1) {
    throw 'LOCK_GATE_FAILED_BEFORE_XDMA_FEASIBILITY'
}
$pcieText = Get-Content -LiteralPath $PcieEvidence -Raw
foreach ($marker in @('RESULT=PASS','EXACT_AHD_ENDPOINT_COUNT=1','ENDPOINT_BDF=0000:01:00.0','UPSTREAM_BDF=0000:00:01.1','CURRENT_LINK_SPEED=5.0 GT/s PCIe','CURRENT_LINK_WIDTH=1','DRIVER=NONE','XDMA_MODULE_LOADED_COUNT=0','XDMA_DEVICE_NODE_COUNT=0')) {
    if (-not $pcieText.Contains($marker, [StringComparison]::Ordinal)) { throw "PCIE_INVENTORY_MARKER_MISSING=$marker" }
}
$remoteCommand = Get-Content -LiteralPath $ScriptPath -Raw
$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_XDMA_BINDING_FEASIBILITY_READ_ONLY' `
    -TimeoutSeconds 60)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
