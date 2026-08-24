$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root='C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\scientific_equivalence\probe_pair'
$Generated=Join-Path $Root 'generated_02'
$Run=Join-Path $Root 'run_04'
$Candidate='C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Tools='C:\AMDDesignTools\2025.2\Vivado\bin'
$ExpectedProbe='D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD'

function Invoke-Captured([string]$Tool,[string[]]$Arguments,[string]$Stem) {
  $record=@("TOOL=$Tool","WORKING_DIRECTORY=$Run")
  for($i=0;$i -lt $Arguments.Count;$i++){$record+="ARG_$i=$($Arguments[$i])"}
  [IO.File]::WriteAllLines("$Stem.command.txt",$record,[Text.UTF8Encoding]::new($false))
  Push-Location $Run
  try{$output=@(& $Tool @Arguments 2>&1);$code=$LASTEXITCODE}finally{Pop-Location}
  [IO.File]::WriteAllLines("$Stem.log",@($output|ForEach-Object ToString),[Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$Stem.exit.txt","PROCESS_EXIT_CODE=$code`n",[Text.UTF8Encoding]::new($false))
  if($code -ne 0){throw "tool failed: $Tool exit=$code see $Stem.log"}
}

if(Test-Path $Run){throw "sealed run exists: $Run"}
if((Get-FileHash (Join-Path $Candidate 'rtl\v41\nvp_i2c_tri_phase_probe.sv') -Algorithm SHA256).Hash -ne $ExpectedProbe){throw 'candidate probe changed after harness generation'}
[void](New-Item -ItemType Directory -Path $Run)

$xvlog=Join-Path $Tools 'xvlog.bat';$xelab=Join-Path $Tools 'xelab.bat';$xsim=Join-Path $Tools 'xsim.bat'
$sources=@(
  (Join-Path $Generated 'r1g_nvp_i2c_tri_phase_probe_reference_generated.sv'),
  (Join-Path $Candidate 'rtl\v41\r1h_probe_index_bram_store.sv'),
  (Join-Path $Candidate 'rtl\v41\nvp_i2c_tri_phase_probe.sv'),
  (Join-Path $Root 'tb_r1g_r1h_probe_functional_pair.sv'))
$compileArgs=[Collections.Generic.List[string]]::new()
foreach($arg in @('--sv','--work','work','-i',$Generated)){$compileArgs.Add($arg)}
foreach($source in $sources){$compileArgs.Add($source)}
Invoke-Captured -Tool $xvlog -Arguments $compileArgs.ToArray() -Stem (Join-Path $Run 'xvlog')
Invoke-Captured -Tool $xelab -Arguments @('tb_r1g_r1h_probe_functional_pair','-L','xpm','-debug','typical','-s','r1g_r1h_probe_pair_snapshot') -Stem (Join-Path $Run 'xelab')
$vcd=(Join-Path $Run 'probe_pair_common_observables.vcd').Replace('\','/')
[IO.File]::WriteAllLines((Join-Path $Run 'run.tcl'),@(
  "open_vcd {$vcd}",
  'log_vcd [get_objects /tb_r1g_r1h_probe_functional_pair/*]',
  'run all','close_vcd','quit'),[Text.UTF8Encoding]::new($false))
Invoke-Captured -Tool $xsim -Arguments @('r1g_r1h_probe_pair_snapshot','-tclbatch',(Join-Path $Run 'run.tcl').Replace('\','/')) -Stem (Join-Path $Run 'xsim')
$log=Get-Content (Join-Path $Run 'xsim.log') -Raw
$markers=@('R1G_R1H_PROBE_CYCLE_BY_CYCLE_COMMON_OUTPUT_EQUIVALENCE=PASS','R1G_R1H_PROBE_I2C_AND_FSM_EVENT_STREAM_EQUIVALENCE=PASS','R1G_R1H_PROBE_BLOCK_STATISTICS_EQUIVALENCE=PASS','R1G_R1H_PROBE_INDEX_TRANSACTION_EQUIVALENCE=PASS','INDEX_CREATION_EVENTS=5')
foreach($m in $markers){if(!$log.Contains($m)){throw "missing $m"}}
if($log -match '(?im)^Error:|^Fatal:|Assertion violation|\$fatal'){throw 'failure marker in paired log'}
[IO.File]::WriteAllLines((Join-Path $Run 'PAIR_RESULT.txt'),@(
  'PAIR_RESULT=PASS_STRICT_R1G_R1H_PROBE_FUNCTIONAL_EVENT_EQUIVALENCE',
  'COMMON_OUTPUT_COUNT=83','READ_INTERFACE_LATENCY_EXCLUDED=YES_AUTHORIZED',
  "REFERENCE_PROBE_SHA256=4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552",
  "CANDIDATE_PROBE_SHA256=$ExpectedProbe",
  "CANDIDATE_INDEX_STORE_SHA256=$((Get-FileHash (Join-Path $Candidate 'rtl\v41\r1h_probe_index_bram_store.sv') -Algorithm SHA256).Hash)",
  "HARNESS_SHA256=$((Get-FileHash (Join-Path $Root 'tb_r1g_r1h_probe_functional_pair.sv') -Algorithm SHA256).Hash)",
  "XSIM_LOG_SHA256=$((Get-FileHash (Join-Path $Run 'xsim.log') -Algorithm SHA256).Hash)",
  "VCD_SHA256=$((Get-FileHash (Join-Path $Run 'probe_pair_common_observables.vcd') -Algorithm SHA256).Hash)",
  "VCD_BYTES=$((Get-Item (Join-Path $Run 'probe_pair_common_observables.vcd')).Length)"
),[Text.UTF8Encoding]::new($false))
Get-Content (Join-Path $Run 'PAIR_RESULT.txt')
