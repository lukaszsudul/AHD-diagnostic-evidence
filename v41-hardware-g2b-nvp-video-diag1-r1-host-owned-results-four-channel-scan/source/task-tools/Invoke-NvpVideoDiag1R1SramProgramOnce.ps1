[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-NVP-VIDEO-DIAG1-R1'
$root = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z'
$scriptRoot = Join-Path $root 'scripts'
$lockPath = 'C:\FPGA\.AHD_G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z.lock\receipt.json'
$buildReceiptPath = Join-Path $root 'reports\vivado_full\G2B_BUILD_RESULT.txt'
$bitstreamPath = Join-Path $root 'artifacts\G2B_NVP_VIDEO_DIAG1_R1_FOUR_CHANNEL_SCAN.bit'
$tclPath = Join-Path $scriptRoot 'program-nvp-video-diag1-r1-once.tcl'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$receiptPath = Join-Path $root 'artifacts\programming-receipt.json'
$logPath = Join-Path $root 'logs\vivado-program.log'
$journalPath = Join-Path $root 'logs\vivado-program.jou'
$consolePath = Join-Path $root 'logs\vivado-program-console.log'
$expectedSourceCommit = 'fcab95726761a0666a67e31c283dbdfb9e775074'
$expectedSourceTree = 'bbf1a5fee70a2eb68bb96305ed10934a1559ca6a'

function Read-UniqueKeyValueFile {
  param([Parameter(Mandatory)][string]$Path)
  $result = @{}
  foreach ($line in [IO.File]::ReadAllLines($Path)) {
    if ([string]::IsNullOrWhiteSpace($line)) {
      continue
    }
    if ($line -notmatch '^([^=]+)=(.*)$') {
      throw 'NVP_DIAG1_R1_BUILD_RECEIPT_FORMAT_INVALID'
    }
    $key = $Matches[1]
    $value = $Matches[2]
    if ($result.ContainsKey($key)) {
      throw "NVP_DIAG1_R1_BUILD_RECEIPT_DUPLICATE_KEY:$key"
    }
    $result[$key] = $value
  }
  return $result
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne $scriptRoot) {
  throw 'NVP_DIAG1_R1_PROGRAM_HELPER_LOCATION_INVALID'
}
if (Test-Path -LiteralPath $receiptPath) {
  throw 'NVP_DIAG1_R1_PROGRAM_RECEIPT_EXISTS_NO_RETRY'
}
foreach ($runtimeOutput in @($logPath,$journalPath,$consolePath)) {
  if (Test-Path -LiteralPath $runtimeOutput) {
    throw 'NVP_DIAG1_R1_PROGRAM_RUNTIME_OUTPUT_EXISTS_NO_RETRY'
  }
}
if (-not (Test-Path -LiteralPath $lockPath -PathType Leaf)) {
  throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_NOT_HELD'
}
$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if (
  $lock.task -cne $task -or
  $lock.run_root -cne $root -or
  $lock.state -cne 'HELD'
) {
  throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_OWNER_MISMATCH'
}
foreach ($requiredFile in @($buildReceiptPath,$bitstreamPath,$tclPath,$vivado)) {
  if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
    throw "NVP_DIAG1_R1_REQUIRED_PROGRAM_INPUT_MISSING:$requiredFile"
  }
}

$build = Read-UniqueKeyValueFile -Path $buildReceiptPath
$requiredBuildValues = [ordered]@{
  TASK = 'AHD_V41_G2B_NVP_VIDEO_DIAG1_R1'
  CANDIDATE_CLASSIFICATION = 'G2B_NVP_VIDEO_DIAG1_R1_HOST_OWNED_RESULTS_CANDIDATE'
  DIAGNOSTIC_MMIO = 'G2B_NVP_VIDEO_DIAG_MMIO_V1'
  DIAGNOSTIC_VERSION = '0x00010001'
  BUILD_PROFILE = 'NVP_VIDEO_DIAGNOSTIC'
  INHERITED_DIAG1_SIMULATION_GATE = '16/16_PASS'
  NVP_VIDEO_DIAG1_R1_SIMULATION_GATE = '19/19_PASS'
  SOURCE_CLEAN = 'PASS'
  SYNTHESIS = 'PASS'
  OPTIMIZATION = 'PASS'
  POST_OPT_RESOURCE_GATE = 'PASS'
  PLACEMENT = 'PASS'
  PHYSICAL_OPTIMIZATION = 'PASS'
  ROUTING = 'PASS'
  TIMING_GATE = 'PASS'
  DRC_GATE = 'PASS'
  METHODOLOGY_GATE = 'PASS'
  CDC_GATE = 'PASS'
  BUS_SKEW_GATE = 'PASS'
  BLACK_BOX_GATE = 'PASS'
  CLOCK_GATE = 'PASS'
  RESOURCE_GATE = 'PASS'
  CONGESTION_GATE = 'PASS'
  BITSTREAM_PRODUCED = 'YES'
  SOURCE_POST_BUILD = 'PASS'
  CHECKPOINT_REUSE = 'NO'
  HARDWARE_ACCESSED = 'NO'
  HARDWARE_PROVEN = 'NO'
  G2B_OFFLINE_BUILD_QUALIFICATION = 'PASS'
  SYNTH_DESIGN = '1'
  OPT_DESIGN = '1'
  PLACE_DESIGN = '1'
  PHYS_OPT_DESIGN = '1'
  ROUTE_DESIGN = '1'
  WRITE_BITSTREAM = '1'
  WRITE_DEBUG_PROBES = '1'
  BUILD = 'PASS'
  SOURCE_TO_BIT_PROVENANCE = 'PASS_CLEAN_EXACT_COMMIT'
}
foreach ($entry in $requiredBuildValues.GetEnumerator()) {
  if (
    -not $build.ContainsKey($entry.Key) -or
    $build[$entry.Key] -cne $entry.Value
  ) {
    throw "NVP_DIAG1_R1_BUILD_GATE_NOT_PASS:$($entry.Key)"
  }
}
foreach ($identityKey in @('SOURCE_COMMIT','REPOSITORY_HEAD','REPOSITORY_HEAD_TREE')) {
  if (
    -not $build.ContainsKey($identityKey) -or
    $build[$identityKey] -cnotmatch '^[0-9a-f]{40}$'
  ) {
    throw "NVP_DIAG1_R1_BUILD_IDENTITY_INVALID:$identityKey"
  }
}
if ($build.SOURCE_COMMIT -cne $build.REPOSITORY_HEAD) {
  throw 'NVP_DIAG1_R1_BUILD_SOURCE_HEAD_MISMATCH'
}
if (
  $build.SOURCE_COMMIT -cne $expectedSourceCommit -or
  $build.REPOSITORY_HEAD -cne $expectedSourceCommit -or
  $build.REPOSITORY_HEAD_TREE -cne $expectedSourceTree
) {
  throw 'NVP_DIAG1_R1_BUILD_SOURCE_AUTHORITY_MISMATCH'
}

$receiptBitstreamPath = [IO.Path]::GetFullPath(
  $build.BITSTREAM_PATH.Replace('/',[IO.Path]::DirectorySeparatorChar)
)
if ($receiptBitstreamPath -cne $bitstreamPath) {
  throw 'NVP_DIAG1_R1_BUILD_RECEIPT_BITSTREAM_PATH_MISMATCH'
}
if ($build.BITSTREAM_SIZE -cnotmatch '^[1-9][0-9]*$') {
  throw 'NVP_DIAG1_R1_BUILD_RECEIPT_BITSTREAM_SIZE_INVALID'
}
if ($build.BITSTREAM_SHA256 -cnotmatch '^[0-9A-F]{64}$') {
  throw 'NVP_DIAG1_R1_BUILD_RECEIPT_BITSTREAM_SHA256_INVALID'
}

$bitstream = Get-Item -LiteralPath $bitstreamPath
$bitstreamHash = (
  Get-FileHash -LiteralPath $bitstreamPath -Algorithm SHA256
).Hash
if (
  $bitstream.Name -cne 'G2B_NVP_VIDEO_DIAG1_R1_FOUR_CHANNEL_SCAN.bit' -or
  $bitstream.Length -ne [int64]$build.BITSTREAM_SIZE -or
  $bitstreamHash -cne $build.BITSTREAM_SHA256
) {
  throw 'NVP_DIAG1_R1_EXACT_BITSTREAM_MANIFEST_MISMATCH'
}

$tclText = [IO.File]::ReadAllText($tclPath)
$programCalls = (
  [regex]::Matches($tclText,'(?m)^\s*program_hw_devices(?:\s|$)')
).Count
$forbiddenCalls = (
  [regex]::Matches(
    $tclText,
    '(?im)^\s*(create_hw_cfgmem|program_hw_cfgmem|write_cfgmem)\b'
  )
).Count
if ($programCalls -ne 1 -or $forbiddenCalls -ne 0) {
  throw 'NVP_DIAG1_R1_PROGRAM_STATIC_AUDIT_FAILED'
}

$receipt = [ordered]@{
  task = $task
  start_utc = [DateTime]::UtcNow.ToString('o')
  build_receipt_path = $buildReceiptPath
  build_receipt_sha256 = (
    Get-FileHash -LiteralPath $buildReceiptPath -Algorithm SHA256
  ).Hash
  source_commit = $build.SOURCE_COMMIT
  source_tree = $build.REPOSITORY_HEAD_TREE
  bitstream_path = $bitstream.FullName
  bitstream_size = $bitstream.Length
  bitstream_sha256 = $bitstreamHash
  vivado = $vivado
  tcl = $tclPath
  tcl_sha256 = (Get-FileHash -LiteralPath $tclPath -Algorithm SHA256).Hash
  expected_jtag_target = 'localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'
  expected_part = 'xc7a35t'
  expected_idcode = '0362D093'
  programmed_storage = 'FPGA_SRAM_VOLATILE_ONLY'
  program_hw_devices_calls = $programCalls
  cfgmem_calls = $forbiddenCalls
  delivery_attempt = 1
  automatic_retry = 'DENIED'
  result = 'DELIVERY_IN_PROGRESS_NO_RETRY'
}
[IO.File]::WriteAllText(
  $receiptPath,
  ($receipt | ConvertTo-Json -Depth 6) + [char]10,
  [Text.UTF8Encoding]::new($false)
)

$localProblem = $null
$vivadoExitCode = 125
$vivadoArguments = @(
  '-mode',
  'batch',
  '-journal',
  $journalPath,
  '-log',
  $logPath,
  '-source',
  $tclPath,
  '-tclargs',
  $bitstream.FullName,
  [string]$bitstream.Length,
  $bitstreamHash
)
try {
  & $vivado @vivadoArguments 2>&1 |
    Tee-Object -FilePath $consolePath
  $vivadoExitCode = $LASTEXITCODE
} catch {
  $localProblem = 'NVP_DIAG1_R1_SANITIZED_VIVADO_LAUNCH_EXCEPTION'
}

$logText = if (Test-Path -LiteralPath $logPath -PathType Leaf) {
  [IO.File]::ReadAllText($logPath)
} else {
  ''
}
$pass = (
  $vivadoExitCode -eq 0 -and
  -not $localProblem -and
  $logText.Contains(
    'PROGRAM_TCL_RESULT=PASS_DONE_1',
    [StringComparison]::Ordinal
  ) -and
  $logText.Contains(
    'POSTPROGRAM_FPGA_DONE=1',
    [StringComparison]::Ordinal
  )
)
$receipt.result = if ($pass) { 'PASS' } else { 'FAIL_NO_RETRY' }
$receipt.vivado_exit_code = $vivadoExitCode
$receipt.local_problem = $localProblem
$receipt.program_tcl_pass = $pass
$receipt.end_utc = [DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText(
  $receiptPath,
  ($receipt | ConvertTo-Json -Depth 6) + [char]10,
  [Text.UTF8Encoding]::new($false)
)
if (-not $pass) {
  throw 'NVP_DIAG1_R1_SRAM_PROGRAMMING_FAILED_NO_RETRY'
}
'NVP_DIAG1_R1_SRAM_PROGRAMMING=PASS'
