param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('autoinit','d2b','d2b_table','power','serial','preinit')]
  [string]$TestKey
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ReferenceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY'
$CandidateRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$EvidenceRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\05_EQUIVALENCE_AND_SIMULATION\scientific_equivalence\vhdl_matrix'
$ToolRoot = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$Xvhdl = Join-Path $ToolRoot 'xvhdl.bat'
$Xelab = Join-Path $ToolRoot 'xelab.bat'
$Xsim = Join-Path $ToolRoot 'xsim.bat'
$ExactR1gCommit = 'e112a5addb7ac62700a9a71af81bf368fad0bada'
$ExactR1gTree = '3a59ebec130103055d24a3a32ecda00dedde5534'

function Invoke-CapturedTool {
  param([string]$Tool,[string[]]$Arguments,[string]$WorkingDirectory,[string]$Stem)
  $command = @("TOOL=$Tool", "WORKING_DIRECTORY=$WorkingDirectory")
  for ($i = 0; $i -lt $Arguments.Count; $i++) { $command += "ARG_$i=$($Arguments[$i])" }
  [IO.File]::WriteAllLines("$Stem.command.txt", $command, [Text.UTF8Encoding]::new($false))
  Push-Location -LiteralPath $WorkingDirectory
  try { $output = @(& $Tool @Arguments 2>&1); $exitCode = $LASTEXITCODE }
  finally { Pop-Location }
  [IO.File]::WriteAllLines("$Stem.log", @($output | ForEach-Object ToString), [Text.UTF8Encoding]::new($false))
  [IO.File]::WriteAllText("$Stem.exit.txt", "PROCESS_EXIT_CODE=$exitCode`n", [Text.UTF8Encoding]::new($false))
  if ($exitCode -ne 0) { throw "tool failed with exit $exitCode; see $Stem.log" }
}

function Get-NormalizedTranscript([string]$Path) {
  $lines = [Collections.Generic.List[string]]::new()
  foreach ($line in [IO.File]::ReadLines($Path)) {
    if ($line -match '^(Note):\s+(.*?)(?:\s+Time:.*)?$') { $lines.Add("$($Matches[1]): $($Matches[2])") }
    elseif ($line -match '^Time:\s+([^\s]+\s+[^\s]+).*Process:\s+([^\s]+)') { $lines.Add("Time: $($Matches[1]) Process: $($Matches[2])") }
    elseif ($line -match '^\$stop called at time\s*:\s*([^\s]+\s+[^\s]+)') { $lines.Add("STOP_TIME=$($Matches[1])") }
  }
  return $lines
}

$defs = @{
  autoinit = @{
    Top='tb_g0p8c5d_autoinit'; Tb='tests/nvp/tb_nvp_autoinit.vhd'; Design=@(
      'rtl/nvp/nvp6134c_diagnostics_pkg.vhd','rtl/nvp/r1f_transaction_serial_counter.vhd','rtl/nvp/nvp6134c_i2c_bringup.vhd'); Expected=@(
      'PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION','PASS EVERY_R1F_TRANSACTION_KIND_EXERCISED','PASS LEGACY_FIRST8_RECONCILIATION',
      'PASS all transactions ACK','PASS one isolated WADDR NACK','PASS one isolated REGADDR NACK','PASS one isolated DATA NACK',
      'PASS one isolated RADDR NACK','PASS exact 13-event historical pattern','PASS exact 15-event historical pattern',
      'PASS exact 36-event historical pattern','PASS operation-86-like transitional bank context')
  }
  d2b = @{
    Top='tb_nvp_d2b_sequence'; Tb='tests/nvp/tb_nvp_d2b_sequence.vhd'; Design=@(
      'rtl/nvp/nvp6134c_diagnostics_pkg.vhd','rtl/nvp/r1f_transaction_serial_counter.vhd','rtl/nvp/nvp6134c_i2c_bringup.vhd'); Expected=@(
      'PASS D2b full sequence is D1 + Z5-ALT with operations 1..148 disabled')
  }
  d2b_table = @{
    Top='tb_nvp_d2b_table_gate'; Tb='tests/nvp/tb_nvp_d2b_table_gate.vhd'; Design=@(
      'rtl/nvp/nvp6134c_diagnostics_pkg.vhd'); Expected=@(
      'PASS D2b disables operations 1..148 and retains operations 149..214')
  }
  power = @{
    Top='tb_g0p8c5d_power_timing'; Tb='tests/nvp/tb_power_timing.vhd'; Design=@(
      'rtl/nvp/nvp6134c_diagnostics_pkg.vhd','rtl/nvp/r1f_transaction_serial_counter.vhd','rtl/nvp/nvp6134c_i2c_bringup.vhd','rtl/nvp/nvp6134c_autoinit.vhd'); Expected=@(
      'PASS power enable, 500-ms reset hold, 1.5-s start scaling')
  }
  serial = @{
    Top='tb_r1f_transaction_serial_counter'; Tb='tests/v41/tb_r1f_transaction_serial_counter.vhd'; Design=@(
      'rtl/nvp/r1f_transaction_serial_counter.vhd'); Expected=@(
      'PASS TRANSACTION_INDEX_16_UNIQUE_AT_300','PASS R1F_TRANSACTION_SERIAL_CLEAR')
  }
  preinit = @{
    Top='tb_r1f_preinit_equivalence'; Tb='tests/v41/tb_r1f_preinit_equivalence.vhd'; Design=@(
      'rtl/nvp/nvp6134c_diagnostics_pkg.vhd','rtl/nvp/r1f_transaction_serial_counter.vhd','rtl/nvp/nvp6134c_i2c_bringup.vhd','rtl/nvp/nvp6134c_autoinit.vhd'); Expected=@(
      'PASS PRE_INIT_DONE_CYCLE_EQUIVALENCE','PASS AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL','PASS AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL')
  }
}

foreach ($p in @($ReferenceRoot,$CandidateRoot,$Xvhdl,$Xelab,$Xsim)) { if (!(Test-Path -LiteralPath $p)) { throw "missing $p" } }
$refCommit=(git -C $ReferenceRoot rev-parse HEAD).Trim(); $refTree=(git -C $ReferenceRoot rev-parse 'HEAD^{tree}').Trim()
$refStatus=(git -C $ReferenceRoot status --porcelain --untracked-files=all) -join "`n"
$candParent=(git -C $CandidateRoot rev-parse HEAD).Trim()
if ($refCommit -ne $ExactR1gCommit -or $refTree -ne $ExactR1gTree -or $refStatus) { throw 'exact clean R1g reference unavailable' }
if ($candParent -ne $ExactR1gCommit) { throw 'candidate is not based on exact R1g' }

$d=$defs[$TestKey]
$caseRoot=Join-Path $EvidenceRoot $TestKey
if (Test-Path -LiteralPath $caseRoot) { throw "sealed case already exists: $caseRoot" }
[void](New-Item -ItemType Directory -Path $caseRoot)

$identity=[Collections.Generic.List[string]]::new()
$identity.Add("TEST_KEY=$TestKey"); $identity.Add("REFERENCE_COMMIT=$refCommit"); $identity.Add("REFERENCE_TREE=$refTree")
$identity.Add("CANDIDATE_PARENT=$candParent"); $identity.Add('REFERENCE_AND_CANDIDATE_LANGUAGE_MODE=XVHDL_DEFAULT_PRODUCTION_COMPATIBLE')
$identity.Add('SYNTHESIS_OR_IMPLEMENTATION_INVOKED=NO')
foreach ($relative in @($d.Design)+@($d.Tb)) {
  $rh=(Get-FileHash (Join-Path $ReferenceRoot $relative) -Algorithm SHA256).Hash
  $ch=(Get-FileHash (Join-Path $CandidateRoot $relative) -Algorithm SHA256).Hash
  if ($rh -ne $ch) { throw "scientific VHDL source differs: $relative" }
  $identity.Add("BYTE_IDENTICAL=$relative,$rh")
}
[IO.File]::WriteAllLines((Join-Path $caseRoot 'PAIR_IDENTITY.txt'),$identity,[Text.UTF8Encoding]::new($false))

foreach ($variant in @('reference','candidate')) {
  $sourceRoot=if($variant -eq 'reference'){$ReferenceRoot}else{$CandidateRoot}
  $variantRoot=Join-Path $caseRoot $variant; [void](New-Item -ItemType Directory -Path $variantRoot)
  $idx=0
  foreach($relative in $d.Design) {
    Invoke-CapturedTool $Xvhdl @('--work','work',(Join-Path $sourceRoot $relative)) $variantRoot (Join-Path $variantRoot ("{0:D2}_xvhdl_design" -f $idx)); $idx++
  }
  if($TestKey -eq 'preinit') {
    $r1eRaw='C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\02_CURRENT_SEMANTICS_AUDIT\raw_r1e_source'
    foreach($f in @('nvp6134c_diagnostics_pkg.vhd','nvp6134c_i2c_bringup.vhd','nvp6134c_autoinit.vhd')) {
      Invoke-CapturedTool $Xvhdl @('--work','r1e_ref',(Join-Path $r1eRaw $f)) $variantRoot (Join-Path $variantRoot ("r1e_ref_$([IO.Path]::GetFileNameWithoutExtension($f))"))
    }
  }
  Invoke-CapturedTool $Xvhdl @('--2008','--work','work',(Join-Path $sourceRoot $d.Tb)) $variantRoot (Join-Path $variantRoot 'xvhdl_tb')
  $snap="${variant}_${TestKey}_snapshot"
  Invoke-CapturedTool $Xelab @($d.Top,'-debug','typical','-s',$snap) $variantRoot (Join-Path $variantRoot 'xelab')
  [IO.File]::WriteAllLines((Join-Path $variantRoot 'run.tcl'),@('run all','quit'),[Text.UTF8Encoding]::new($false))
  Invoke-CapturedTool $Xsim @($snap,'-tclbatch',(Join-Path $variantRoot 'run.tcl').Replace('\','/')) $variantRoot (Join-Path $variantRoot 'xsim')
  $text=[IO.File]::ReadAllText((Join-Path $variantRoot 'xsim.log'))
  foreach($marker in $d.Expected){if(!$text.Contains($marker)){throw "$variant missing marker $marker"}}
  if($text -match '(?im)^Error:|^Fatal:|Assertion violation|severity failure'){throw "$variant log contains failure"}
  [IO.File]::WriteAllLines((Join-Path $variantRoot 'xsim.normalized.txt'),@(Get-NormalizedTranscript (Join-Path $variantRoot 'xsim.log')),[Text.UTF8Encoding]::new($false))
}

$refNorm=(Join-Path $caseRoot 'reference\xsim.normalized.txt'); $candNorm=(Join-Path $caseRoot 'candidate\xsim.normalized.txt')
$diff=@(Compare-Object ([IO.File]::ReadAllLines($refNorm)) ([IO.File]::ReadAllLines($candNorm)) -SyncWindow 0)
if($diff.Count){[IO.File]::WriteAllLines((Join-Path $caseRoot 'TRANSCRIPT_DIFFERENCE.txt'),@($diff|Out-String),[Text.UTF8Encoding]::new($false));throw 'normalized transcripts differ'}
$sha=(Get-FileHash $refNorm -Algorithm SHA256).Hash
[IO.File]::WriteAllLines((Join-Path $caseRoot 'PAIR_RESULT.txt'),@("TEST_KEY=$TestKey",'REFERENCE_SIMULATION=PASS','CANDIDATE_SIMULATION=PASS','NORMALIZED_TRANSCRIPT_EQUAL=YES',"NORMALIZED_TRANSCRIPT_SHA256=$sha",'PAIR_RESULT=PASS_EXACT_SAME_BIT_SCIENTIFIC_EQUIVALENCE'),[Text.UTF8Encoding]::new($false))
Write-Output "PASS $TestKey $sha"
