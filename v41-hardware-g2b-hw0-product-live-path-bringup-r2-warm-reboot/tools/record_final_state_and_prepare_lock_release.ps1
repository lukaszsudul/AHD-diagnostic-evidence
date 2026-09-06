Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$FinalLog = Join-Path $TaskRoot 'raw\FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log'
$FinalJtagCsv = Join-Path $TaskRoot 'raw\JTAG_FINAL_SESSION.csv'
$FinalJtagDevice = Join-Path $TaskRoot 'raw\JTAG_FINAL_DEVICE_PROPERTIES.tsv'
$T1Decision = Join-Path $TaskRoot 'raw\T1_DRIVER_GATE_DECISION.json'
$ValidationPath = Join-Path $TaskRoot 'raw\FINAL_STATE_VALIDATION.json'
$ControllerSnapshot = Join-Path $TaskRoot 'locks\CONTROLLER_LOCK_BEFORE_LINUX_RELEASE.json'

foreach ($required in @($ControllerLock, $FinalLog, $FinalJtagCsv, $FinalJtagDevice, $T1Decision)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "FINAL_VALIDATION_SOURCE_MISSING=$required" }
}
foreach ($destination in @($ValidationPath, $ControllerSnapshot)) {
    if (Test-Path -LiteralPath $destination) { throw "FINAL_VALIDATION_DESTINATION_EXISTS=$destination" }
}
$finalText = Get-Content -LiteralPath $FinalLog -Raw
foreach ($marker in @(
    'RESULT=PASS','HOSTNAME=VCDE-DUT-1','MACHINE_ID=0e90f50d9465492b80258da5658446f8',
    'BOOT_ID=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac','RELEVANT_PROCESS_COUNT=0',
    'EXACT_AHD_ENDPOINT_COUNT=1','ENDPOINT_BDF=0000:01:00.0','ENDPOINT_VENDOR_DEVICE=0x10ee:0x7011',
    'ENDPOINT_SUBSYSTEM=0x10ee:0x0007','ENDPOINT_CLASS=0x058000','UPSTREAM_BDF=0000:00:01.1',
    'ENDPOINT_CURRENT_LINK_SPEED=5.0 GT/s PCIe','ENDPOINT_CURRENT_LINK_WIDTH=1','ENDPOINT_DRIVER=NONE',
    'XDMA_LOADED_COUNT=0','XDMA_PCI_DRIVER_SYSFS=ABSENT','XDMA_DEVICE_NODE_COUNT=0',
    'FIRST_BLOCKER=BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE','CANDIDATE_RETAINED_ACROSS_WARM_REBOOT=PASS',
    'FINAL_JTAG_DONE=1','WARM_REBOOTS_EXECUTED=1','SECOND_REBOOT_ATTEMPTED=NO','POWER_CYCLES_EXECUTED=0',
    'SRAM_PROGRAM_OPERATIONS_IN_R2=0','FLASH_PROGRAM_OPERATIONS=0','XDMA_MODULE_LOADS_IN_R2=0',
    'DRIVER_BINDS_IN_R2=0','DRIVER_UNBINDS_IN_R2=0','MMIO_READS=0','MMIO_WRITES=0','DMA_OPERATIONS=0',
    'STREAM_ENABLE_WRITES=0','PCI_RESCANS=0','PCI_RESETS=0','CANDIDATE_LEFT_IN_VOLATILE_SRAM=YES',
    'PERSISTENT_STATE_MODIFIED=NO'
)) {
    if (-not $finalText.Contains($marker, [StringComparison]::Ordinal)) { throw "FINAL_STATE_MARKER_MISSING=$marker" }
}
$rows = Import-Csv -LiteralPath $FinalJtagCsv
if ($rows.Count -ne 5 -or @($rows | Where-Object { $_.session_index -ne '3' -or $_.target_count -ne '1' -or $_.device_count -ne '1' -or $_.part -ne 'xc7a35t' -or $_.idcode -ne '0362D093' -or $_.done -ne '1' -or $_.refresh_result -ne 'PASS' }).Count -ne 0) {
    throw 'FINAL_JTAG_VALIDATION_FAILED'
}
$deviceText = Get-Content -LiteralPath $FinalJtagDevice -Raw
foreach ($marker in @("INDEX`t0","PART`txc7a35t","IDCODE_HEX`t0362D093","REGISTER.CONFIG_STATUS.BIT00_CRC_ERROR`t0","REGISTER.IR.BIT5_DONE`t1")) {
    if (-not $deviceText.Contains($marker, [StringComparison]::Ordinal)) { throw "FINAL_JTAG_DEVICE_MARKER_MISSING=$marker" }
}
$t1 = Get-Content -LiteralPath $T1Decision -Raw | ConvertFrom-Json
if ($t1.result -ne 'BLOCKED' -or $t1.first_blocker -ne 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE' -or $t1.decision -ne 'DO_NOT_LOAD_OR_BIND') {
    throw 'T1_DECISION_INVALID_AT_FINAL_STATE'
}
$utc = [DateTime]::UtcNow.ToString('o')
$validation = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    recorded_at_utc = $utc
    result = 'PASS'
    engineering_gate = 'BLOCKED'
    first_blocker = 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE'
    final_fpga_state = 'xc7a35t IDCODE 0362D093 index 0; five final DONE=1 samples; candidate retained in volatile SRAM; zero R2 programming operations'
    final_pcie_driver_state = '0000:01:00.0 10ee:7011 subsystem 10ee:0007 class 058000 behind 0000:00:01.1; Gen2 x1; unbound; xdma unloaded; zero xdma nodes'
    final_jtag_gate = 'PASS'
    final_linux_state_gate = 'PASS'
    linux_lock = 'HELD_PENDING_RELEASE'
    controller_lock = 'HELD_PENDING_LAST_RELEASE'
    operation_counts = [ordered]@{
        warm_reboots = 1
        power_cycles = 0
        sram_programs_r2 = 0
        flash_programs = 0
        xdma_module_loads = 0
        driver_binds = 0
        driver_unbinds = 0
        mmio_reads = 0
        mmio_writes = 0
        dma_operations = 0
        stream_enable_writes = 0
        pcie_rescans = 0
        pcie_resets = 0
    }
    source_sha256 = [ordered]@{
        final_linux_state = (Get-FileHash -LiteralPath $FinalLog -Algorithm SHA256).Hash
        final_jtag_csv = (Get-FileHash -LiteralPath $FinalJtagCsv -Algorithm SHA256).Hash
        final_jtag_device = (Get-FileHash -LiteralPath $FinalJtagDevice -Algorithm SHA256).Hash
        t1_decision = (Get-FileHash -LiteralPath $T1Decision -Algorithm SHA256).Hash
    }
}
$validation | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ValidationPath -Encoding utf8

$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or $lock.linux_post_reboot_lock_state -ne 'HELD') { throw 'LOCK_STATE_INVALID_AT_RELEASE_PREPARE' }
$lock | Add-Member -NotePropertyName engineering_gate -NotePropertyValue 'BLOCKED' -Force
$lock | Add-Member -NotePropertyName first_blocker -NotePropertyValue 'BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE' -Force
$lock | Add-Member -NotePropertyName final_state_validation -NotePropertyValue 'PASS' -Force
$lock | Add-Member -NotePropertyName final_state_validation_receipt -NotePropertyValue 'raw/FINAL_STATE_VALIDATION.json' -Force
$lock | Add-Member -NotePropertyName xdma_module_loads_in_r2 -NotePropertyValue 0 -Force
$lock | Add-Member -NotePropertyName driver_binds_in_r2 -NotePropertyValue 0 -Force
$lock | Add-Member -NotePropertyName mmio_reads -NotePropertyValue 0 -Force
$lock | Add-Member -NotePropertyName mmio_writes -NotePropertyValue 0 -Force
$lock | Add-Member -NotePropertyName dma_operations -NotePropertyValue 0 -Force
$lock.release_state = 'READY_FOR_LINUX_LOCK_RELEASE'
$lock.controller_lock_revision = 7
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerLock -Encoding utf8
$lock | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $ControllerSnapshot -Encoding utf8
Write-Output 'FINAL_STATE_VALIDATION=PASS'
Write-Output 'ENGINEERING_GATE=BLOCKED'
Write-Output 'FIRST_BLOCKER=BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE'
Write-Output 'LINUX_LOCK_RELEASE_READY=YES'
Write-Output 'CONTROLLER_LOCK=HELD'
