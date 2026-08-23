param(
  [Parameter(Mandatory=$true)]
  [ValidateSet('preflight','write')]
  [string]$Mode
)

$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_NVP_R1E_POST_ROUTE_CONTINUATION_R2'
$sourceRoot = 'C:\FPGA\WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1'
$dcp = 'C:\FPGA\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1\07_BUILD\reports\PHASE3_routed.dcp'
$common = Join-Path $taskRoot 'scripts\r1e_dcp_common_r2.tcl'
$expectedDcpHash = '1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1'
$expectedCommit = 'f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd'
$expectedTree = 'db8b5581a237e19905fd01c6d453793047bc3ba7'
$launcher = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'

if ((Get-FileHash -Algorithm SHA256 -LiteralPath $dcp).Hash -ne $expectedDcpHash) { throw 'exact routed DCP hash mismatch' }
$actualCommit = git -C $sourceRoot rev-parse HEAD
if ($LASTEXITCODE -ne 0) { throw 'source commit query failed' }
if ($actualCommit.Trim() -ne $expectedCommit) { throw 'source commit mismatch' }
$actualTree = git -C $sourceRoot rev-parse 'HEAD^{tree}'
if ($LASTEXITCODE -ne 0) { throw 'source tree query failed' }
if ($actualTree.Trim() -ne $expectedTree) { throw 'source tree mismatch' }
$sourceStatus = @(git -C $sourceRoot status --porcelain --untracked-files=all)
if ($LASTEXITCODE -ne 0) { throw 'source worktree status query failed' }
if ($sourceStatus.Count -ne 0) { throw 'source worktree is not clean' }
if (!(Test-Path -LiteralPath $launcher)) { throw 'supported Vivado launcher missing' }

if ($Mode -eq 'preflight') {
  $script = Join-Path $taskRoot 'scripts\preflight_exact_r1e_routed_dcp_r2.tcl'
  $output = Join-Path $taskRoot '05_READ_ONLY_DRY_RUN'
  $bitCommands = @(Select-String -LiteralPath $script -Pattern '^\s*write_bitstream\b').Count
  if ($bitCommands -ne 0) { throw 'preflight script contains write_bitstream' }
  $tclArgs = @($common,$dcp,$output)
} else {
  $script = Join-Path $taskRoot 'scripts\continue_exact_r1e_from_routed_dcp_r2.tcl'
  $output = Join-Path $taskRoot '06_WRITE_CONTINUATION'
  $bitPath = Join-Path $taskRoot '07_BITSTREAM\ahd_capture_v41_i2c_25khz_r1e_observability.bit'
  $bitCommands = @(Select-String -LiteralPath $script -Pattern '^\s*write_bitstream\b').Count
  if ($bitCommands -ne 1) { throw 'write continuation must contain exactly one write_bitstream command' }
  if (Test-Path -LiteralPath $bitPath) { throw 'bit output pre-exists' }
  $tclArgs = @($common,$dcp,$output,$bitPath)
}

$forbiddenPattern = '^\s*(synth_design|opt_design|place_design|phys_opt_design|route_design|write_checkpoint|set_property)\b'
$forbidden = @(Select-String -LiteralPath @($common,$script) -Pattern $forbiddenPattern)
if ($forbidden.Count -ne 0) { throw 'forbidden implementation command found in continuation Tcl' }
$namespaceCompare = @(Select-String -LiteralPath @($common,$script) -Pattern '(eq|ne).*ahd_capture_top_xdma|ahd_capture_top_xdma.*(eq|ne)').Count
if ($namespaceCompare -ne 0) { throw 'current-design/RTL-top equality comparison pattern found' }

New-Item -ItemType Directory -Force -Path $output | Out-Null
$receipt = Join-Path $output 'WINDOWS_SUPERVISOR_PREFLIGHT.txt'
$receiptLines = @(
  "MODE=$Mode",
  "ROUTED_DCP_SHA256=$expectedDcpHash",
  "SOURCE_COMMIT=$expectedCommit",
  "SOURCE_TREE=$expectedTree",
  "SOURCE_WORKTREE_CLEAN=YES",
  "CURRENT_DESIGN_TO_RTL_TOP_EQUALITY_COMPARISON_COUNT=$namespaceCompare",
  "FORBIDDEN_IMPLEMENTATION_COMMAND_COUNT=$($forbidden.Count)",
  "WRITE_BITSTREAM_COMMAND_COUNT=$bitCommands",
  "SUPERVISOR_INPUT_GATE=PASS"
)
[IO.File]::WriteAllLines($receipt,$receiptLines,[Text.UTF8Encoding]::new($false))

$log = Join-Path $output "vivado_${Mode}.log"
$journal = Join-Path $output "vivado_${Mode}.jou"
$stdout = Join-Path $output "vivado_${Mode}_stdout_stderr.log"
& $launcher -mode batch -notrace -journal $journal -log $log -source $script -tclargs @tclArgs *>&1 | Tee-Object -FilePath $stdout
$code = $LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $output 'PROCESS_EXIT_CODE.txt'),"PROCESS_EXIT_CODE=$code`n",[Text.UTF8Encoding]::new($false))
exit $code
