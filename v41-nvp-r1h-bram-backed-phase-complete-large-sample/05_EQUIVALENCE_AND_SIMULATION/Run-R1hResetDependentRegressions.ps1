param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Repo = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Root = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\reset_liveness_regression_02'
$Bin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$Xvhdl = Join-Path $Bin 'xvhdl.bat'
$Xvlog = Join-Path $Bin 'xvlog.bat'
$Xelab = Join-Path $Bin 'xelab.bat'
$Xsim = Join-Path $Bin 'xsim.bat'

function Invoke-Tool {
  param([string]$Tool,[string[]]$Arguments,[string]$WorkingDirectory,[string]$Stem)
  $lines = [System.Collections.Generic.List[string]]::new()
  $lines.Add("TOOL=$Tool")
  $lines.Add("WORKING_DIRECTORY=$WorkingDirectory")
  for ($i=0; $i -lt $Arguments.Count; $i++) { $lines.Add("ARG_$i=$($Arguments[$i])") }
  [System.IO.File]::WriteAllLines("$Stem.command.txt",$lines,[System.Text.UTF8Encoding]::new($false))
  Push-Location -LiteralPath $WorkingDirectory
  try { $output=@(& $Tool @Arguments 2>&1 | ForEach-Object {$_.ToString()}); $code=$LASTEXITCODE }
  finally { Pop-Location }
  [System.IO.File]::WriteAllLines("$Stem.log",$output,[System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText("$Stem.exit.txt","PROCESS_EXIT_CODE=$code`n",[System.Text.UTF8Encoding]::new($false))
  if($code -ne 0){ throw "tool failed exit ${code}: $Tool" }
}

function New-RunTcl([string]$Path) {
  [System.IO.File]::WriteAllLines($Path,@('run all','quit'),[System.Text.UTF8Encoding]::new($false))
}

if(Test-Path -LiteralPath $Root){ throw "fresh regression directory already exists: $Root" }
[void](New-Item -ItemType Directory -Path $Root)

$serviceDir=Join-Path $Root 'service'
[void](New-Item -ItemType Directory -Path $serviceDir)
Invoke-Tool $Xvlog @('--sv','--work','work',
  (Join-Path $Repo 'rtl/v41/r1h_mmio_read_service.sv'),
  (Join-Path $Repo 'tests/v41/tb_r1h_mmio_read_service.sv')) $serviceDir (Join-Path $serviceDir 'xvlog')
Invoke-Tool $Xelab @('tb_r1h_mmio_read_service','-debug','typical','-s','r1h_reset_service_snapshot') $serviceDir (Join-Path $serviceDir 'xelab')
$serviceTcl=Join-Path $serviceDir 'run.tcl'; New-RunTcl $serviceTcl
Invoke-Tool $Xsim @('r1h_reset_service_snapshot','-tclbatch',$serviceTcl.Replace('\','/')) $serviceDir (Join-Path $serviceDir 'xsim')
$serviceText=[System.IO.File]::ReadAllText((Join-Path $serviceDir 'xsim.log'))
if(-not $serviceText.Contains('R1H_MMIO_READ_SERVICE_PASS') -or
   $serviceText -match '(?im)^FAIL:|^FATAL:|\$fatal|severity failure'){
  throw 'service regression missing PASS or contains a failure diagnostic'
}

$integrationDir=Join-Path $Root 'integration'
[void](New-Item -ItemType Directory -Path $integrationDir)
Invoke-Tool $Xvlog @('--sv','--work','work',
  (Join-Path $Repo 'tests/v41/r1g_measurement_regs_reference.sv'),
  (Join-Path $Repo 'rtl/v41/r1f_measurement_regs.sv'),
  (Join-Path $Repo 'rtl/v41/r1h_mmio_read_service.sv'),
  (Join-Path $Repo 'rtl/v41/control_status_regs.sv'),
  (Join-Path $Repo 'tests/v41/tb_r1h_mmio_integration_exhaustive.sv')) $integrationDir (Join-Path $integrationDir 'xvlog')
Invoke-Tool $Xelab @('tb_r1h_mmio_integration_exhaustive','-debug','typical','-s','r1h_reset_integration_snapshot') $integrationDir (Join-Path $integrationDir 'xelab')
$integrationTcl=Join-Path $integrationDir 'run.tcl'; New-RunTcl $integrationTcl
Invoke-Tool $Xsim @('r1h_reset_integration_snapshot','-tclbatch',$integrationTcl.Replace('\','/')) $integrationDir (Join-Path $integrationDir 'xsim')
$integrationText=[System.IO.File]::ReadAllText((Join-Path $integrationDir 'xsim.log'))
if(-not $integrationText.Contains('R1H_MMIO_INTEGRATION_EXHAUSTIVE_PASS aligned_reads=1368 unaligned_reads=4104 forwarded_writes=1368') -or
   $integrationText -match '(?im)^FAIL:|^FATAL:|\$fatal|severity failure'){
  throw 'integration regression missing PASS or contains a failure diagnostic'
}

$topDir=Join-Path $Root 'top'
[void](New-Item -ItemType Directory -Path $topDir)
$vhdl=@(
  'rtl/nvp/nvp6134c_diagnostics_pkg.vhd','rtl/nvp/r1f_transaction_serial_counter.vhd',
  'rtl/nvp/nvp6134c_i2c_bringup.vhd','rtl/nvp/nvp6134c_autoinit.vhd') | ForEach-Object {Join-Path $Repo $_}
Invoke-Tool $Xvhdl (@('--work','work')+$vhdl) $topDir (Join-Path $topDir 'xvhdl')
$sv=@(
  'rtl/v41/axi_lite_host_bridge.sv','rtl/v41/axi_clock_lifecycle_monitor.sv',
  'rtl/v41/axi_clock_measurement_regs.sv','rtl/v41/r1e_measurement_regs.sv',
  'rtl/v41/nvp_i2c_address_probe.sv','rtl/v41/r1h_probe_index_bram_store.sv',
  'rtl/v41/nvp_i2c_tri_phase_probe.sv','rtl/v41/r1f_failed_txn_logger.sv',
  'rtl/v41/r1f_measurement_regs.sv','rtl/v41/r1h_mmio_read_service.sv',
  'rtl/v41/control_status_regs.sv','rtl/pio/pio_slot_adapter.sv',
  'rtl/pio/pio_bar_target.sv','rtl/record/bt656_record_producer.sv',
  'rtl/record/capture_mailbox.sv','rtl/video/video_capture.sv',
  'rtl/video/physical_frontend.sv','rtl/top/ahd_capture_top_xdma.sv',
  'tests/v41/xdma_v41_m1_elaboration_stub.sv') | ForEach-Object {Join-Path $Repo $_}
$sv += 'C:\AMDDesignTools\2025.2\data\verilog\src\glbl.v'
Invoke-Tool $Xvlog (@('--sv','--work','work')+$sv) $topDir (Join-Path $topDir 'xvlog')
Invoke-Tool $Xelab @('ahd_capture_top_xdma','glbl','-L','xpm','-L','unisims_ver','-debug','typical','-s','r1h_reset_top_snapshot') $topDir (Join-Path $topDir 'xelab')
$topText=[System.IO.File]::ReadAllText((Join-Path $topDir 'xelab.log'))
if(-not $topText.Contains('Built simulation snapshot r1h_reset_top_snapshot')){throw 'top elaboration missing PASS marker'}

$bound=@('rtl/top/ahd_capture_top_xdma.sv','rtl/v41/r1h_mmio_read_service.sv','tests/v41/tb_r1h_mmio_read_service.sv','tests/v41/tb_r1h_mmio_integration_exhaustive.sv')
$receipt=[System.Collections.Generic.List[string]]::new()
$receipt.Add('R1H_RESET_LIVENESS_REGRESSION=PASS')
$receipt.Add('REQ_READY_DURING_RESET=0')
$receipt.Add('PENDING_MEMORY_READ_CANCELLED_BY_NVP_OR_AXI_RESET=PASS')
$receipt.Add('MMIO_COMPLETE_RANGE=PASS_1368_ALIGNED_4104_UNALIGNED_1368_WRITES')
$receipt.Add('FINAL_TOP_ELABORATION=PASS')
$receipt.Add('SYNTH_DESIGN_INVOKED=NO')
foreach($relative in $bound){$receipt.Add("SOURCE_SHA256|$relative|$((Get-FileHash (Join-Path $Repo $relative) -Algorithm SHA256).Hash)")}
foreach($path in @((Join-Path $serviceDir 'xsim.log'),(Join-Path $integrationDir 'xsim.log'),(Join-Path $topDir 'xelab.log'))){$receipt.Add("LOG_SHA256|$path|$((Get-FileHash $path -Algorithm SHA256).Hash)")}
[System.IO.File]::WriteAllLines((Join-Path $Root 'R1H_RESET_LIVENESS_REGRESSION_RESULT.txt'),$receipt,[System.Text.UTF8Encoding]::new($false))
Write-Output 'R1H_RESET_LIVENESS_REGRESSION=PASS'
