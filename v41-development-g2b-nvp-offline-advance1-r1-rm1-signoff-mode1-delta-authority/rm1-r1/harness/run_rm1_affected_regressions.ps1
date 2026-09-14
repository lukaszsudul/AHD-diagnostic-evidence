[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [Parameter(Mandatory = $true)][string]$OutputRoot,
  [string]$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$out = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/')
$vivado = [IO.Path]::GetFullPath($VivadoBin).TrimEnd('\', '/')
$parent = 'fc37d815b5d64ef90dfbd99c57ae4cc09567b56f'
if (Test-Path -LiteralPath $out) { throw "RM1_AFFECTED_OUTPUT_NOT_FRESH:$out" }
if ($out.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'RM1_AFFECTED_OUTPUT_INSIDE_WORKTREE'
}

$inheritedRunner = Join-Path $repo 'tests\nvp_video_diag\run_nvp_video_diag1_sim.ps1'
$rm1Checker = Join-Path $repo 'tests\nvp_video_diag\check_nvp_diag2_rm1_contract.ps1'
$core = Join-Path $repo 'rtl\g2b\g2b_nvp_video_diag.sv'
$bridge = Join-Path $repo 'rtl\v41\axi_lite_host_bridge.sv'
$router = Join-Path $repo 'rtl\g2b\v41_g2b_mmio_router.sv'
$coreTb = Join-Path $repo 'tests\nvp_video_diag\tb_g2b_nvp_video_diag_mmio_protocol.sv'
$axiTb = Join-Path $repo 'tests\nvp_video_diag\tb_g2b_nvp_video_diag_axi_integration.sv'
$xvlog = Join-Path $vivado 'xvlog.bat'
$xelab = Join-Path $vivado 'xelab.bat'
$xsim = Join-Path $vivado 'xsim.bat'
$inputs = @($inheritedRunner, $rm1Checker, $core, $bridge, $router,
            $coreTb, $axiTb, $xvlog, $xelab, $xsim)
foreach ($path in $inputs) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "RM1_AFFECTED_INPUT_MISSING:$path"
  }
}

# The R3 implementation/tests are historical protected inputs.  RM1 is allowed
# to change only its parser fanout/top profile plus its new bounded island.
$r3Protected = @(
  'rtl/g2b/g2b_nvp_video_diag.sv',
  'rtl/v41/axi_lite_host_bridge.sv',
  'rtl/g2b/v41_g2b_mmio_router.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv',
  'tests/nvp_video_diag/tb_nvp_i2c_fixed_master.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag_mmio_protocol.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag_axi_integration.sv',
  'tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1',
  'tests/nvp_video_diag/run_nvp_video_diag_r3_sim.ps1',
  'tests/nvp_video_diag/check_nvp_video_diag_r3_contract.ps1'
)
foreach ($relative in $r3Protected) {
  $parentObject = (& git --no-optional-locks -C $repo rev-parse "${parent}:$relative").Trim()
  if ($LASTEXITCODE -ne 0) { throw "RM1_R3_PARENT_OBJECT_MISSING:$relative" }
  $currentObject = (& git --no-optional-locks -C $repo hash-object (
      Join-Path $repo $relative)).Trim()
  if ($LASTEXITCODE -ne 0 -or $currentObject -ne $parentObject) {
    throw "RM1_R3_PROTECTED_INPUT_CHANGED:$relative"
  }
}

$allowedChanges = @(
  'rtl/g2b/v41_g2b_onech_c2h.sv',
  'rtl/top/ahd_capture_top_xdma.sv',
  'rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv',
  'rtl/diagnostic/g2b_nvp_rm1_route_controller.sv',
  'rtl/g2b/g2b_nvp_video_diag2_rm1.sv',
  'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1',
  'tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1',
  'tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv',
  'xdc/common/g2b_nvp_diag2_rm1_cdc.xdc'
)
$changed = @(& git --no-optional-locks -C $repo status --porcelain=v1 `
    --untracked-files=all | ForEach-Object {
      if ($_.Length -ge 4) { $_.Substring(3).Replace('\', '/') }
    })
$outside = @($changed | Where-Object { $_ -notin $allowedChanges })
if ($outside.Count -ne 0) {
  throw "RM1_AFFECTED_SCOPE_VIOLATION:$($outside -join ',')"
}

[void][IO.Directory]::CreateDirectory($out)
$hashInputPaths = @($r3Protected | ForEach-Object { Join-Path $repo $_ }) +
                  @($rm1Checker)
$hashBefore = [ordered]@{}
foreach ($path in $hashInputPaths) {
  $hashBefore[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

$inheritedRoot = Join-Path $out 'inherited-r3-t1-t19'
& $inheritedRunner -RepoRoot $repo -OutputRoot $inheritedRoot `
    -VivadoBin $vivado *> (Join-Path $out 'inherited.console.log')
if ($LASTEXITCODE -ne 0) { throw 'RM1_AFFECTED_R3_T1_T19_FAILED' }
$inheritedReceipt = Get-Content -LiteralPath (
    Join-Path $inheritedRoot 'NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt') -Raw
if ($inheritedReceipt -notmatch 'RESULT=PASS' -or
    $inheritedReceipt -notmatch 'R1_SIMULATION_CASES_PASSED=19') {
  throw 'RM1_AFFECTED_R3_T1_T19_RECEIPT_INVALID'
}

& $rm1Checker -RepoRoot $repo *> (Join-Path $out 'rm1-static.console.log')
if ($LASTEXITCODE -ne 0) { throw 'RM1_AFFECTED_RM1_STATIC_FAILED' }

Push-Location $out
try {
  & $xvlog '--sv' '--work' 'work' $core $bridge $router $coreTb $axiTb `
      *> (Join-Path $out 'r3-t20-t25-compile.console.log')
  if ($LASTEXITCODE -ne 0) { throw "RM1_AFFECTED_XVLOG_FAILED:$LASTEXITCODE" }

  & $xelab 'work.tb_g2b_nvp_video_diag_mmio_protocol' '-s' `
      'rm1_affected_r3_core' '--debug' 'typical' '--relax' `
      *> (Join-Path $out 'r3-t20-elaborate.console.log')
  if ($LASTEXITCODE -ne 0) { throw "RM1_AFFECTED_T20_XELAB_FAILED:$LASTEXITCODE" }
  & $xsim 'rm1_affected_r3_core' '-runall' '-log' `
      (Join-Path $out 'r3-t20-xsim.log') `
      *> (Join-Path $out 'r3-t20-run.console.log')
  if ($LASTEXITCODE -ne 0) { throw "RM1_AFFECTED_T20_XSIM_FAILED:$LASTEXITCODE" }

  & $xelab 'work.tb_g2b_nvp_video_diag_axi_integration' '-s' `
      'rm1_affected_r3_axi' '--debug' 'typical' '--relax' `
      *> (Join-Path $out 'r3-t21-t25-elaborate.console.log')
  if ($LASTEXITCODE -ne 0) { throw "RM1_AFFECTED_AXI_XELAB_FAILED:$LASTEXITCODE" }
  & $xsim 'rm1_affected_r3_axi' '-runall' '-log' `
      (Join-Path $out 'r3-t21-t25-xsim.log') `
      *> (Join-Path $out 'r3-t21-t25-run.console.log')
  if ($LASTEXITCODE -ne 0) { throw "RM1_AFFECTED_AXI_XSIM_FAILED:$LASTEXITCODE" }
} finally {
  Pop-Location
}

$coreLog = Get-Content -LiteralPath (Join-Path $out 'r3-t20-run.console.log') -Raw
$axiLog = Get-Content -LiteralPath (Join-Path $out 'r3-t21-t25-run.console.log') -Raw
$markers = @(
  'PASS T20 CORE_WRITE_NO_RESPONSE_READ_RESPONSE_CONTRACT',
  'PASS T21 ACTUAL_AXI_LITE_BRIDGE_INTEGRATION',
  'PASS T22 AXI_LITE_ORDERING_AND_BACKPRESSURE',
  'PASS T23 1000_CYCLE_COMMAND_STRESS',
  'PASS T24 DIAGNOSTIC_PRODUCT_ADDRESS_ISOLATION',
  'PASS T25 BOUNDED_PROGRESS_PROPERTIES',
  'PASS R3_NEW_MMIO_AXI_LITE_SIMULATION_GATE 6/6'
)
foreach ($marker in $markers) {
  if (-not (($coreLog + "`n" + $axiLog).Contains($marker))) {
    throw "RM1_AFFECTED_MARKER_MISSING:$marker"
  }
}
if ($coreLog -match 'Fatal:|Error:' -or $axiLog -match 'Fatal:|Error:') {
  throw 'RM1_AFFECTED_R3_FATAL_OR_ERROR_MARKER'
}

foreach ($path in $hashBefore.Keys) {
  if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne
      $hashBefore[$path]) {
    throw "RM1_AFFECTED_INPUT_CHANGED_DURING_GATE:$path"
  }
}

$receipt = [ordered]@{
  Task = 'AHD_V41_G2B_NVP_DIAG2_RM1_AFFECTED_REGRESSIONS'
  Result = 'PASS'
  Parent = $parent
  ExplicitlyAcceptedChangeScope = $allowedChanges
  R3ProtectedInputsVsParent = 'BYTE_IDENTICAL'
  R3InheritedCases = '19/19 PASS'
  R3NewMmioAxiCases = '6/6 PASS'
  CompleteR3Regression = '25/25 PASS'
  RM1StaticFanoutAndProfileContract = 'PASS'
  HardwareAccessed = 'NO'
  InputHashes = $hashBefore
}
$receipt | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (
    Join-Path $out 'G2B_NVP_DIAG2_RM1_AFFECTED_REGRESSIONS.json') -Encoding utf8NoBOM
Write-Output 'RM1_AFFECTED_R3_REGRESSION=25/25 PASS'
Write-Output 'RM1_AFFECTED_PROTECTED_INPUTS=BYTE_IDENTICAL'
Write-Output 'HARDWARE_ACCESSED=NO'
