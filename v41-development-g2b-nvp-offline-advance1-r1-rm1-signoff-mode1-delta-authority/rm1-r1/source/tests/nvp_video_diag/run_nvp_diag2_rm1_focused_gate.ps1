[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [Parameter(Mandatory = $true)][string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = [IO.Path]::GetFullPath($RepoRoot)
$out = [IO.Path]::GetFullPath($OutputRoot)
$vivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$xvlog = Join-Path $vivadoBin 'xvlog.bat'
$xelab = Join-Path $vivadoBin 'xelab.bat'
$xsim = Join-Path $vivadoBin 'xsim.bat'
$glbl = 'C:\AMDDesignTools\2025.2\data\verilog\src\glbl.v'
$contract = Join-Path $repo 'tests\nvp_video_diag\check_nvp_diag2_rm1_contract.ps1'
$monitor = Join-Path $repo 'rtl\diagnostic\g2b_nvp_raw_marker_monitor.sv'
$routeController = Join-Path $repo 'rtl\diagnostic\g2b_nvp_rm1_route_controller.sv'
$parser = Join-Path $repo 'rtl\g2b\v41_g2b_onech_c2h.sv'
$testbench = Join-Path $repo 'tests\nvp_video_diag\tb_g2b_nvp_diag2_rm1_focused.sv'
$routeTestbench = Join-Path $repo 'tests\nvp_video_diag\tb_g2b_nvp_rm1_route_controller.sv'
$parserTestbench = Join-Path $repo 'tests\nvp_video_diag\tb_g2b_nvp_rm1_parser_tap.sv'

foreach ($path in @($repo, $xvlog, $xelab, $xsim, $glbl,
                     $contract, $monitor, $routeController, $parser,
                     $testbench, $routeTestbench, $parserTestbench)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "RM1_GATE_REQUIRED_INPUT_ABSENT:$path"
  }
}
if (Test-Path -LiteralPath $out) {
  throw "RM1_GATE_OUTPUT_NOT_FRESH:$out"
}
[void](New-Item -ItemType Directory -Path $out)

$governedSources = @(
  $monitor,
  $routeController,
  (Join-Path $repo 'rtl\g2b\g2b_nvp_video_diag2_rm1.sv'),
  $parser,
  (Join-Path $repo 'rtl\top\ahd_capture_top_xdma.sv'),
  (Join-Path $repo 'xdc\common\g2b_nvp_diag2_rm1_cdc.xdc'),
  $contract,
  $testbench,
  $routeTestbench,
  $parserTestbench,
  $PSCommandPath
)
$hashBefore = [ordered]@{}
foreach ($path in $governedSources) {
  $hashBefore[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

$staticLog = Join-Path $out 'static-contract.log'
& $contract -RepoRoot $repo *> $staticLog

$case = Join-Path $out 'focused-simulation'
[void](New-Item -ItemType Directory -Path $case)
Push-Location $case
try {
  $compileLog = Join-Path $case 'xvlog.console.log'
  & $xvlog '--sv' '--work' 'work' $glbl $monitor $testbench *> $compileLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_XVLOG_FAILED:$LASTEXITCODE" }

  $elabLog = Join-Path $case 'xelab.console.log'
  & $xelab 'work.tb_g2b_nvp_diag2_rm1_focused' 'work.glbl' `
      '-L' 'xpm' '-L' 'unisims_ver' '-L' 'secureip' '--debug' 'typical' `
      '--relax' '-s' 'rm1_focused_xsim' *> $elabLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_XELAB_FAILED:$LASTEXITCODE" }

  $simLog = Join-Path $case 'xsim.console.log'
  & $xsim 'rm1_focused_xsim' '-runall' `
      '-log' (Join-Path $case 'xsim.log') *> $simLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_XSIM_FAILED:$LASTEXITCODE" }
} finally {
  Pop-Location
}

$routeCase = Join-Path $out 'route-controller-integration'
[void](New-Item -ItemType Directory -Path $routeCase)
Push-Location $routeCase
try {
  $routeCompileLog = Join-Path $routeCase 'xvlog.console.log'
  & $xvlog '--sv' '--work' 'work' $glbl $monitor $routeController $routeTestbench `
      *> $routeCompileLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_ROUTE_XVLOG_FAILED:$LASTEXITCODE" }

  $routeElabLog = Join-Path $routeCase 'xelab.console.log'
  & $xelab 'work.tb_g2b_nvp_rm1_route_controller' 'work.glbl' `
      '-L' 'xpm' '-L' 'unisims_ver' '-L' 'secureip' '--debug' 'typical' `
      '--relax' '-s' 'rm1_route_xsim' *> $routeElabLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_ROUTE_XELAB_FAILED:$LASTEXITCODE" }

  $routeSimLog = Join-Path $routeCase 'xsim.console.log'
  & $xsim 'rm1_route_xsim' '-runall' `
      '-log' (Join-Path $routeCase 'xsim.log') *> $routeSimLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_ROUTE_XSIM_FAILED:$LASTEXITCODE" }
} finally {
  Pop-Location
}

$parserCase = Join-Path $out 'parser-tap-integration'
[void](New-Item -ItemType Directory -Path $parserCase)
Push-Location $parserCase
try {
  $parserCompileLog = Join-Path $parserCase 'xvlog.console.log'
  & $xvlog '--sv' '--work' 'work' $glbl $parser $parserTestbench `
      *> $parserCompileLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_PARSER_XVLOG_FAILED:$LASTEXITCODE" }

  $parserElabLog = Join-Path $parserCase 'xelab.console.log'
  & $xelab 'work.tb_g2b_nvp_rm1_parser_tap' 'work.glbl' `
      '-L' 'xpm' '-L' 'unisims_ver' '-L' 'secureip' '--debug' 'typical' `
      '--relax' '-s' 'rm1_parser_tap_xsim' *> $parserElabLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_PARSER_XELAB_FAILED:$LASTEXITCODE" }

  $parserSimLog = Join-Path $parserCase 'xsim.console.log'
  & $xsim 'rm1_parser_tap_xsim' '-runall' `
      '-log' (Join-Path $parserCase 'xsim.log') *> $parserSimLog
  if ($LASTEXITCODE -ne 0) { throw "RM1_PARSER_XSIM_FAILED:$LASTEXITCODE" }
} finally {
  Pop-Location
}

$routeIntegrationPassed = (Get-Content -LiteralPath $routeSimLog -Raw).Contains(
    'RM1_ROUTE_INTEGRATION_PASS')
$parserIntegrationPassed = (Get-Content -LiteralPath $parserSimLog -Raw).Contains(
    'RM1_PARSER_TAP_INTEGRATION_PASS')

$combined = (Get-Content -LiteralPath $staticLog -Raw) + "`n" +
            (Get-Content -LiteralPath $simLog -Raw)
$results = [System.Collections.Generic.List[object]]::new()
for ($test = 1; $test -le 18; $test++) {
  $pattern = "RM1_T${test}_PASS"
  $count = ([regex]::Matches($combined, [regex]::Escape($pattern))).Count
  $results.Add([pscustomobject]@{
    Test = "T$test"
    Marker = $pattern
    Count = $count
    Result = if ($count -eq 1) { 'PASS' } else { 'FAIL' }
  })
}

$sourceChanged = $false
$hashAfter = [ordered]@{}
foreach ($path in $governedSources) {
  $hashAfter[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if ($hashAfter[$path] -ne $hashBefore[$path]) { $sourceChanged = $true }
}
$passed = @($results | Where-Object Result -eq 'PASS').Count
$receipt = [ordered]@{
  Gate = 'G2B_NVP_DIAG2_RM1_FOCUSED_GATE'
  Result = if ($passed -eq 18 -and $routeIntegrationPassed -and
               $parserIntegrationPassed -and -not $sourceChanged) {
             'PASS'
           } else { 'FAIL' }
  TestsPassed = $passed
  TestsRequired = 18
  RouteControllerIntegration = if ($routeIntegrationPassed) { 'PASS' } else { 'FAIL' }
  ParserTapIntegration = if ($parserIntegrationPassed) { 'PASS' } else { 'FAIL' }
  SourceChangedDuringGate = $sourceChanged
  Results = $results
  HashBefore = $hashBefore
  HashAfter = $hashAfter
}
$receipt | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath `
    (Join-Path $out 'G2B_NVP_DIAG2_RM1_FOCUSED_GATE.json') -Encoding utf8NoBOM

if ($receipt.Result -ne 'PASS') {
  throw "RM1_FOCUSED_GATE_FAILED:$passed/18 sourceChanged=$sourceChanged"
}
Write-Output 'G2B_NVP_DIAG2_RM1_FOCUSED_GATE=18/18 PASS'
Write-Output 'ROUTE_CONTROLLER_INTEGRATION=PASS'
Write-Output 'PARSER_TAP_INTEGRATION=PASS'
Write-Output 'SOURCE_CHANGED_DURING_GATE=NO'
