param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Run = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\top_integration_iteration_01'
$Out = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION'
$Parent = 'e112a5addb7ac62700a9a71af81bf368fad0bada'

$files = @(
  'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
  'rtl/nvp/r1f_transaction_serial_counter.vhd',
  'rtl/nvp/nvp6134c_i2c_bringup.vhd',
  'rtl/nvp/nvp6134c_autoinit.vhd',
  'rtl/v41/axi_lite_host_bridge.sv',
  'rtl/v41/axi_clock_lifecycle_monitor.sv',
  'rtl/v41/axi_clock_measurement_regs.sv',
  'rtl/v41/r1e_measurement_regs.sv',
  'rtl/v41/nvp_i2c_address_probe.sv',
  'rtl/v41/r1h_probe_index_bram_store.sv',
  'rtl/v41/nvp_i2c_tri_phase_probe.sv',
  'rtl/v41/r1f_failed_txn_logger.sv',
  'rtl/v41/r1f_measurement_regs.sv',
  'rtl/v41/r1h_mmio_read_service.sv',
  'rtl/v41/control_status_regs.sv',
  'rtl/pio/pio_slot_adapter.sv',
  'rtl/pio/pio_bar_target.sv',
  'rtl/record/bt656_record_producer.sv',
  'rtl/record/capture_mailbox.sv',
  'rtl/video/video_capture.sv',
  'rtl/video/physical_frontend.sv',
  'rtl/top/ahd_capture_top_xdma.sv',
  'tests/v41/xdma_v41_m1_elaboration_stub.sv'
)

if ((git -C $Repo rev-parse HEAD).Trim() -ne $Parent) {
  throw 'candidate HEAD changed before source commit'
}
$logPath = Join-Path $Run 'xelab_v2.log'
$logText = [System.IO.File]::ReadAllText($logPath)
if (-not $logText.Contains('Built simulation snapshot r1h_top_integration_snapshot_v2') -or
    $logText -match '(?im)^ERROR:|^FATAL:|severity failure') {
  throw 'final top elaboration log does not pass'
}
$logTime = (Get-Item -LiteralPath $logPath).LastWriteTimeUtc
$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add('relative_path,bytes,sha256,last_write_utc,compiled_before_elaboration')
foreach ($relative in $files) {
  $path = Join-Path $Repo $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "elaboration source missing: $relative"
  }
  $item = Get-Item -LiteralPath $path
  if ($item.LastWriteTimeUtc -gt $logTime) {
    throw "source is newer than final elaboration: $relative"
  }
  $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  $rows.Add(('"{0}",{1},{2},{3},YES' -f $relative,$item.Length,$sha,$item.LastWriteTimeUtc.ToString('o')))
}
[System.IO.File]::WriteAllLines(
  (Join-Path $Out 'R1H_FINAL_TOP_ELABORATION_SOURCE_SHA256.csv'),
  $rows,
  [System.Text.UTF8Encoding]::new($false))

$xvhdlSha = (Get-FileHash -LiteralPath (Join-Path $Run 'xvhdl.log') -Algorithm SHA256).Hash
$xvlogSha = (Get-FileHash -LiteralPath (Join-Path $Run 'xvlog.log') -Algorithm SHA256).Hash
$topFixSha = (Get-FileHash -LiteralPath (Join-Path $Run 'xvlog_top_fix.log') -Algorithm SHA256).Hash
$xelabSha = (Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash
[System.IO.File]::WriteAllLines(
  (Join-Path $Out 'R1H_FINAL_TOP_ELABORATION_GATE.txt'),
  @(
    "R1H_PARENT_COMMIT=$Parent",
    'VIVADO_SIMULATOR_VERSION=2025.2',
    'VIVADO_SW_BUILD=6299465',
    'TOP=ahd_capture_top_xdma',
    'PART_CONTEXT=xc7a35tcsg325-2',
    'PRODUCTION_VHDL_MODE=DEFAULT_NON_2008',
    'XPM_LIBRARY=ELABORATED',
    'TOP_ELABORATION=PASS',
    'SYNTH_DESIGN_INVOKED=NO',
    'IMPLEMENTATION_INVOKED=NO',
    "XVHDL_LOG_SHA256=$xvhdlSha",
    "XVLOG_LOG_SHA256=$xvlogSha",
    "XVLOG_FINAL_TOP_REANALYSIS_LOG_SHA256=$topFixSha",
    "XELAB_LOG_SHA256=$xelabSha"
  ),
  [System.Text.UTF8Encoding]::new($false))

Write-Output 'R1H_FINAL_TOP_ELABORATION_GATE=PASS'
