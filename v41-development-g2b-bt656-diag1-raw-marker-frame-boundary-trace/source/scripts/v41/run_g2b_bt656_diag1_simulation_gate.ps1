[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoRoot,

  [Parameter(Mandatory = $true)]
  [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoPath = [IO.Path]::GetFullPath($RepoRoot)
$outputPath = [IO.Path]::GetFullPath($OutputRoot)
$vivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$xvlog = Join-Path $vivadoBin 'xvlog.bat'
$xelab = Join-Path $vivadoBin 'xelab.bat'
$xsim = Join-Path $vivadoBin 'xsim.bat'
$glbl = 'C:\AMDDesignTools\2025.2\data\verilog\src\glbl.v'

foreach ($requiredPath in @($repoPath, $xvlog, $xelab, $xsim, $glbl)) {
  if (-not (Test-Path -LiteralPath $requiredPath)) {
    throw "Required simulation input is absent: $requiredPath"
  }
}
if (Test-Path -LiteralPath $outputPath) {
  throw "Simulation output root must be fresh: $outputPath"
}
[void](New-Item -ItemType Directory -Path $outputPath)

$sourcePaths = @(
  (Join-Path $repoPath 'rtl\diagnostic\g2b_bt656_boundary_trace.sv'),
  (Join-Path $repoPath 'rtl\g2b\v41_g2b_onech_c2h.sv'),
  (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_trace.sv'),
  (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_parser.sv'),
  (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_noninterference.sv'),
  (Join-Path $repoPath 'tests\g2b\tb_v41_g2b_onech_c2h.sv')
)
foreach ($sourcePath in $sourcePaths) {
  if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "Required simulation source is absent: $sourcePath"
  }
}
$hashesBefore = @{}
foreach ($sourcePath in $sourcePaths) {
  $hashesBefore[$sourcePath] = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
}

function Invoke-SimulationCase {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Top,
    [Parameter(Mandatory = $true)][string]$Snapshot,
    [Parameter(Mandatory = $true)][string[]]$Sources
  )

  $casePath = Join-Path $outputPath $Name
  $tempPath = Join-Path $casePath 'tmp'
  [void](New-Item -ItemType Directory -Path $tempPath -Force)
  $oldTemp = $env:TEMP
  $oldTmp = $env:TMP
  $env:TEMP = $tempPath
  $env:TMP = $tempPath
  Push-Location $casePath
  try {
    $compileLog = Join-Path $casePath 'xvlog.console.log'
    & $xvlog '--sv' '--work' 'work' $glbl @Sources *> $compileLog
    if ($LASTEXITCODE -ne 0) { throw "$Name xvlog failed with $LASTEXITCODE" }

    $elaborateLog = Join-Path $casePath 'xelab.console.log'
    $elaborateArguments = @(
      "work.$Top", 'work.glbl', '-L', 'xpm', '-L', 'unisims_ver',
      '-L', 'secureip', '--debug', 'typical', '--relax', '-s', $Snapshot)
    & $xelab @elaborateArguments *> $elaborateLog
    if ($LASTEXITCODE -ne 0) { throw "$Name xelab failed with $LASTEXITCODE" }

    $simulationLog = Join-Path $casePath 'xsim.console.log'
    $simulationArguments = @(
      $Snapshot, '-runall', '-log', (Join-Path $casePath 'xsim.log'))
    & $xsim @simulationArguments *> $simulationLog
    if ($LASTEXITCODE -ne 0) { throw "$Name xsim failed with $LASTEXITCODE" }
    return $simulationLog
  } finally {
    Pop-Location
    $env:TEMP = $oldTemp
    $env:TMP = $oldTmp
  }
}

$traceLog = Invoke-SimulationCase -Name 'trace' -Top 'tb_g2b_bt656_diag1_trace' -Snapshot 'diag1_trace_xsim' -Sources @(
    (Join-Path $repoPath 'rtl\diagnostic\g2b_bt656_boundary_trace.sv'),
    (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_trace.sv'))

$parserLog = Invoke-SimulationCase -Name 'parser' -Top 'tb_g2b_bt656_diag1_parser' -Snapshot 'diag1_parser_xsim' -Sources @(
    (Join-Path $repoPath 'rtl\g2b\v41_g2b_onech_c2h.sv'),
    (Join-Path $repoPath 'rtl\diagnostic\g2b_bt656_boundary_trace.sv'),
    (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_parser.sv'))

$noninterferenceLog = Invoke-SimulationCase -Name 'noninterference' -Top 'tb_g2b_bt656_diag1_noninterference' -Snapshot 'diag1_noninterference_xsim' -Sources @(
    (Join-Path $repoPath 'rtl\g2b\v41_g2b_onech_c2h.sv'),
    (Join-Path $repoPath 'rtl\diagnostic\g2b_bt656_boundary_trace.sv'),
    (Join-Path $repoPath 'tests\g2b\tb_g2b_bt656_diag1_noninterference.sv'))

$regressionLog = Invoke-SimulationCase -Name 'affected_regression' -Top 'tb_v41_g2b_onech_c2h' -Snapshot 'g2b_onech_c2h_xsim' -Sources @(
    (Join-Path $repoPath 'rtl\g2b\v41_g2b_onech_c2h.sv'),
    (Join-Path $repoPath 'tests\g2b\tb_v41_g2b_onech_c2h.sv'))

$expected = [ordered]@{
  T1 = @{ Log = $traceLog; Pattern = 'BT656_DIAG1_T1_PASS clear_arm_status' }
  T2 = @{ Log = $traceLog; Pattern = 'BT656_DIAG1_T2_PASS marker_byte_alignment' }
  T3 = @{ Log = $traceLog; Pattern = 'BT656_DIAG1_T3_PASS pretrigger_chronological_order' }
  T4 = @{ Log = $parserLog; Pattern = 'BT656_DIAG1_T4_PASS line1079_eav_next_frame_line0_line1_stop malformed=0' }
  T5 = @{ Log = $parserLog; Pattern = 'BT656_DIAG1_T5_PASS malformed_reason_1_2_3_exact' }
  T6 = @{ Log = $parserLog; Pattern = 'BT656_DIAG1_T6_PASS ring_full_and_malformed_drop_independent' }
  T7 = @{ Log = $traceLog; Pattern = 'BT656_DIAG1_T7_PASS event_limit_clock_timeout_freeze' }
  T8 = @{ Log = $traceLog; Pattern = 'BT656_DIAG1_T8_PASS dual_clock_mmio_readback' }
  T9 = @{ Log = $noninterferenceLog; Pattern = 'BT656_DIAG1_T9_PASS side_by_side_product_equivalent_vs_trace_armed byte_identical' }
  T10 = @{ Log = $regressionLog; Pattern = 'G2B_ONECH_C2H_XSIM_PASS records=16 bytes=65536 releases=16 expected_queue=16' }
}

$results = [System.Collections.Generic.List[object]]::new()
foreach ($testName in $expected.Keys) {
  $definition = $expected[$testName]
  $matched = Select-String -LiteralPath $definition.Log -SimpleMatch -Pattern $definition.Pattern -Quiet
  $results.Add([ordered]@{
    Test = $testName
    Result = $(if ($matched) { 'PASS' } else { 'FAIL' })
    Evidence = $definition.Pattern
    Log = $definition.Log
  })
}

foreach ($sourcePath in $sourcePaths) {
  $hashAfter = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
  if ($hashAfter -ne $hashesBefore[$sourcePath]) {
    throw "Simulation mutated source: $sourcePath"
  }
}

$passed = @($results | Where-Object Result -eq 'PASS').Count
$receipt = [ordered]@{
  Gate = 'BT656_DIAG1_SIMULATION_GATE'
  Passed = $passed
  Total = 10
  Result = $(if ($passed -eq 10) { 'PASS' } else { 'FAIL' })
  FunctionalNoninterference = $results[8].Result
  SourceMutations = 0
  Tests = $results
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $outputPath 'G2B_BT656_DIAG1_SIMULATION_GATE.json') -Encoding utf8NoBOM

$markdown = [System.Collections.Generic.List[string]]::new()
$markdown.Add('# G2B BT656 DIAG1 simulation gate')
$markdown.Add('')
$markdown.Add("- Result: $($receipt.Result)")
$markdown.Add("- Passed: $passed/10")
$markdown.Add("- Functional noninterference: $($receipt.FunctionalNoninterference)")
$markdown.Add('- Source mutations during gate: 0')
$markdown.Add('')
$markdown.Add('| Test | Result | Evidence |')
$markdown.Add('|---|---|---|')
foreach ($result in $results) {
  $markdown.Add("| $($result.Test) | $($result.Result) | ``$($result.Evidence)`` |")
}
$markdown | Set-Content -LiteralPath (Join-Path $outputPath 'G2B_BT656_DIAG1_SIMULATION_GATE.md') -Encoding utf8NoBOM

if ($passed -ne 10) {
  throw "BT656_DIAG1_SIMULATION_GATE_FAILED:$passed/10"
}
Write-Output 'BT656_DIAG1_SIMULATION_GATE=10/10 PASS'
Write-Output 'FUNCTIONAL_NONINTERFERENCE=PASS'
