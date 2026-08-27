param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$EvidenceRoot,
  [string]$ReferenceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE',
  [string]$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
)
$ErrorActionPreference = 'Stop'
if($RepoRoot -match '[^\x00-\x7F]' -or $EvidenceRoot -match '[^\x00-\x7F]') {
  throw 'Xilinx paths must use the approved short ASCII spelling'
}
if($env:XILINX_LOCAL_USER_DATA -ne 'NO' -or
   $env:XILINX_TCLAPP_REPO -ne 'C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore' -or
   [string]::IsNullOrWhiteSpace($env:TEMP) -or $env:TEMP -ne $env:TMP -or
   $env:TEMP -match '[^\x00-\x7F]') {
  throw 'Canonical isolated Xilinx environment mismatch'
}
Write-Output "XILINX_LOCAL_USER_DATA=$env:XILINX_LOCAL_USER_DATA"
Write-Output "XILINX_TCLAPP_REPO=$env:XILINX_TCLAPP_REPO"
Write-Output "TEMP=$env:TEMP"
Write-Output "TMP=$env:TMP"

$expected = @{
  'tests/v41/tb_r1i_qualified_ack_readiness.sv' = '75B7B5B330CB4CCB41234E91BE56633A0EBA1944CB28A9F13BD48AA718B2143B'
  'tests/v41/r1i_master_test_adapter.vhd' = '0A4948D6FCD444015DB56772B455FF45F62862F754E5022478547A4954830711'
  'rtl/nvp/nvp6134c_diagnostics_pkg.vhd' = '36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156'
  'rtl/nvp/r1f_transaction_serial_counter.vhd' = 'FA92E1B52A5BB870EDBEDA5457A7021DB882AE9FF31DF880CBD97A6C7549019E'
}
foreach($relative in $expected.Keys) {
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepoRoot $relative)).Hash
  if($actual -ne $expected[$relative]) { throw "Frozen inherited input mismatch: $relative $actual" }
  Write-Output "FROZEN_INPUT_SHA256=$actual $relative"
}
$testInputs = @(
  'rtl/nvp/nvp6134c_i2c_bringup.vhd',
  'research_tests/r1i_a/tb_r1i_a_c1_semantics.sv',
  'research_tests/r1i_a/run_r1i_a_focused_sim.ps1'
)
$testInputHashes = @{}
foreach($relative in $testInputs) {
  $testInputHashes[$relative] =
    (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepoRoot $relative)).Hash
  Write-Output "TEST_INPUT_SHA256=$($testInputHashes[$relative]) $relative"
}

$referenceCommit = (& git --no-optional-locks -c "safe.directory=$ReferenceRoot" -C $ReferenceRoot rev-parse HEAD).Trim()
$referenceTree = (& git --no-optional-locks -c "safe.directory=$ReferenceRoot" -C $ReferenceRoot rev-parse 'HEAD^{tree}').Trim()
if($referenceCommit -ne 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c' -or
   $referenceTree -ne '161e561f007912d73dba93c5ecd78e3cc3a6955b') {
  throw 'Immutable R1h reference identity mismatch'
}
if(& git --no-optional-locks -c "safe.directory=$ReferenceRoot" -C $ReferenceRoot status --porcelain) {
  throw 'Immutable R1h reference worktree is dirty'
}

New-Item -ItemType Directory -Path $EvidenceRoot -Force | Out-Null
$derivedTb = Join-Path $EvidenceRoot 'tb_r1i_a_candidate_aware.sv'
$sourceTb = Join-Path $RepoRoot 'tests/v41/tb_r1i_qualified_ack_readiness.sv'
$sourceText = [System.IO.File]::ReadAllText($sourceTb)
$normalized = $sourceText -replace "`r`n", "`n"
function Replace-ExactlyOnce([string]$Text, [string]$Old, [string]$New, [string]$Label) {
  $count = ([regex]::Matches($Text, [regex]::Escape($Old))).Count
  if($count -ne 1) { throw "Expected exactly one $Label block, found $count" }
  return $Text.Replace($Old, $New)
}
$fallOld = @'
              slave_sda=(ack_bad || mode==1) ? 1:0;
              if((mode==9 || mode==17) && current_target && target_attempt==1 && ack_phase==0 &&
'@ -replace "`r`n", "`n"
$fallNew = @'
              slave_sda=(ack_bad || mode==1) ? 1:0;
              // C1 adapter: keep the end-of-LOW filtered observation at NACK,
              // then qualify ACK before the first filtered-SCL-HIGH edge.
              if(mode==1) begin late_pending=1; late_count=17; end
              if((mode==9 || mode==17) && current_target && target_attempt==1 && ack_phase==0 &&
'@ -replace "`r`n", "`n"
$caseOld = '    begin_run(1); await_done();'
$caseNew = @'
    $display("PASS CASE1_C1_FIRST_FILTERED_HIGH_STIMULUS_ADAPTER");
    begin_run(1); await_done();
'@ -replace "`r`n", "`n"
$derivedText = Replace-ExactlyOnce $normalized $fallOld $fallNew 'mode1 ACK-low'
$guardOld = '            if(!sc) $fatal(1,"late slave stimulus was not during physical SCL high");'
$guardNew = '            if(!sc && !(mode==1 && bstate==RX_ACK)) $fatal(1,"late slave stimulus was not during physical SCL high");'
$derivedText = Replace-ExactlyOnce $derivedText $guardOld $guardNew 'mode1 pre-HIGH guard'
$actionOld = '            if(bstate==RX_ACK) slave_sda=0;'
$actionNew = '            if(bstate==RX_ACK) slave_sda=(mode==1 && sc) ? 1:0;'
$derivedText = Replace-ExactlyOnce $derivedText $actionOld $actionNew 'mode1 post-HIGH live-NACK'
$derivedText = Replace-ExactlyOnce $derivedText $caseOld $caseNew 'mode1 lifecycle'
[System.IO.File]::WriteAllText($derivedTb, $derivedText, [System.Text.UTF8Encoding]::new($false))
$derivedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $derivedTb).Hash
Write-Output "CANDIDATE_AWARE_TB_SHA256=$derivedHash"
Write-Output 'CANDIDATE_AWARE_TB_DELTA=MODE1_ACK_STIMULUS_TIMING_ONLY_FULL_LIFECYCLE_RETAINED'

function Run-SimTool([string]$Tool, [string[]]$Arguments, [string]$Label) {
  Write-Output "SIM_STEP=$Label"
  & (Join-Path $VivadoBin "$Tool.bat") @Arguments 2>&1 |
    Tee-Object -FilePath (Join-Path $EvidenceRoot "$Label.console.log")
  if($LASTEXITCODE -ne 0) { throw "$Label failed: exit $LASTEXITCODE" }
}

Push-Location $EvidenceRoot
try {
  $rtl = @('rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
           'rtl/nvp/r1f_transaction_serial_counter.vhd',
           'rtl/nvp/nvp6134c_i2c_bringup.vhd')
  Run-SimTool xvhdl ((@('--work','r1h_ref')) +
    ($rtl | ForEach-Object { Join-Path $ReferenceRoot $_ })) 'reference_compile'
  Run-SimTool xvhdl ((@('--work','work')) +
    ($rtl | ForEach-Object { Join-Path $RepoRoot $_ }) +
    @((Join-Path $RepoRoot 'tests/v41/r1i_master_test_adapter.vhd'))) 'candidate_compile'
  Run-SimTool xvlog @('--sv','--work','work',$derivedTb,
    (Join-Path $RepoRoot 'research_tests/r1i_a/tb_r1i_a_c1_semantics.sv')) 'testbench_compile'

  Run-SimTool xelab @('work.tb_r1h_allack_reference','-s','r1h_allack_reference',
    '--debug','typical','--relax') 'reference_elaborate'
  Run-SimTool xsim @('r1h_allack_reference','-runall','-log','reference_xsim.log') 'reference_run'
  if(-not (Select-String -LiteralPath 'reference_xsim.log' -SimpleMatch 'PASS ALL_ACK_WIRE_SEQUENCE_AND_OUTPUT_CAPTURE REF=1')) {
    throw 'Reference semantic completion marker absent'
  }

  Run-SimTool xelab @('work.tb_r1i_qualified_ack_readiness','-s','r1i_a_inherited',
    '--debug','typical','--relax') 'candidate_aware_elaborate'
  Run-SimTool xsim @('r1i_a_inherited','-runall','-log','candidate_aware_xsim.log') 'candidate_aware_run'
  foreach($marker in @(
      'PASS CASE1_C1_FIRST_FILTERED_HIGH_STIMULUS_ADAPTER',
      'PASS CASE1_LATE_ACK_QUALIFIED_NO_RETRY',
      'PASS CASE2_WADDR_FIRST_ABORT_CASE6_RETRY1_RECOVERY',
      'PASS CASE3_REGADDR_FIRST_ABORT', 'PASS CASE4_DATA_FIRST_ABORT',
      'PASS CASE5_RADDR_FIRST_ABORT_NO_READ_DATA',
      'PASS CASE7_RETRY3_FINAL_ALLOWED_ATTEMPT_RECOVERY',
      'PASS CASE8_EXACT_FOUR_ATTEMPTS_ONE_TERMINAL_ERROR',
      'PASS CASE9_PHYSICAL_SCL_LOW_BOUNDED_TIMEOUT_STOP_RETRY',
      'PASS CASE10_READ_DATA_CHANGES_ONLY_PHYSICAL_SCL_HIGH',
      'PASS CASE12_BANK_SELECTOR_FAILURE_RECOVERY_NO_UNVERIFIED_TARGET',
      'PASS CASE12_BANK_VERIFY_NACK_RECOVERY_NO_UNVERIFIED_TARGET',
      'PASS CASE12_BANK_VERIFY_MISMATCH_CACHE_INVALIDATION',
      'PASS CASE12_BANK_SELECTOR_EXHAUSTION_NO_UNVERIFIED_TARGET',
      'PASS CASE12_BANK_VERIFY_EXHAUSTION_NO_UNVERIFIED_TARGET',
      'PASS CASE9_PERSISTENT_SCL_LOW_BOUNDED_SAFE_TERMINAL_NO_RETRY',
      'PASS R1I_FOCUSED_WIRE_SEMANTIC_SUITE')) {
    if(-not (Select-String -LiteralPath 'candidate_aware_xsim.log' -SimpleMatch $marker)) {
      throw "Candidate-aware inherited marker absent: $marker"
    }
  }

  Run-SimTool xelab @('work.tb_r1i_a_c1_semantics','-s','r1i_a_c1_semantics',
    '--debug','typical','--relax') 'c1_elaborate'
  Run-SimTool xsim @('r1i_a_c1_semantics','-runall','-log','c1_xsim.log') 'c1_run'
  if(-not (Select-String -LiteralPath 'c1_xsim.log' -SimpleMatch 'PASS R1I_A_C1_SEMANTIC_SUITE')) {
    throw 'C1 semantic completion marker absent'
  }
  foreach($phase in 0..3) {
    if(-not (Select-String -LiteralPath 'c1_xsim.log' -SimpleMatch "PASS C1_PHASE${phase}_FIRST_FILTERED_HIGH_ACK_HELD")) {
      throw "C1 phase $phase first-HIGH selection marker absent"
    }
    if(-not (Select-String -LiteralPath 'c1_xsim.log' -SimpleMatch "PASS C1_PHASE${phase}_FIRST_FILTERED_HIGH_NACK_HELD")) {
      throw "C1 phase $phase held-NACK marker absent"
    }
  }

  $referenceTrace = (Get-FileHash -Algorithm SHA256 -LiteralPath 'r1h_reference_allack.trace').Hash
  $candidateTrace = (Get-FileHash -Algorithm SHA256 -LiteralPath 'r1i_candidate_allack.trace').Hash
  if($referenceTrace -ne $candidateTrace) { throw 'All-ACK wire/output trace equivalence failed' }
  if((Get-FileHash -Algorithm SHA256 -LiteralPath $derivedTb).Hash -ne $derivedHash) {
    throw 'Generated candidate-aware testbench changed during simulation'
  }
  foreach($relative in $expected.Keys) {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepoRoot $relative)).Hash
    if($actual -ne $expected[$relative]) { throw "Frozen test input changed during run: $relative" }
  }
  foreach($relative in $testInputs) {
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath (Join-Path $RepoRoot $relative)).Hash
    if($actual -ne $testInputHashes[$relative]) { throw "Candidate test input changed during run: $relative" }
  }
  Write-Output 'TEST_INPUT_HASHES_STABLE_DURING_COMPILE_AND_RUN=PASS'
  Write-Output "ALL_ACK_TRACE_EQUIVALENCE_SHA256=$candidateTrace"
  Write-Output 'R1I_A_FOCUSED_SIMULATION=PASS'
} finally {
  Pop-Location
}
