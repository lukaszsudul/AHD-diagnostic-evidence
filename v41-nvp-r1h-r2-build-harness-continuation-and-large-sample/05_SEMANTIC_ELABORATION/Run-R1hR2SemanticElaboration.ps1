param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Task = 'V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION'
$Repo = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Out = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\05_SEMANTIC_ELABORATION'
$Run = Join-Path $Out 'run_01'
$DryRunResult = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\04_PROJECT_SETUP_DRY_RUN\R1H_R2_PROJECT_SETUP_DRY_RUN_RESULT.txt'
$ExpectedDryRunResultSha256 = 'F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6'
$ExpectedDuplicateNormalizationAuditSha256 = '3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F'
$ExpectedCommit = 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
$ExpectedTree = '161e561f007912d73dba93c5ecd78e3cc3a6955b'
$Top = 'ahd_capture_top_xdma'
$PartContext = 'xc7a35tcsg325-2'
$Snapshot = 'r1h_r2_semantic_snapshot'
$ToolBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
$Xvhdl = Join-Path $ToolBin 'xvhdl.bat'
$Xvlog = Join-Path $ToolBin 'xvlog.bat'
$Xelab = Join-Path $ToolBin 'xelab.bat'
$Glbl = 'C:\AMDDesignTools\2025.2\data\verilog\src\glbl.v'

$vhdlRel = @(
  'rtl/nvp/nvp6134c_diagnostics_pkg.vhd',
  'rtl/nvp/r1f_transaction_serial_counter.vhd',
  'rtl/nvp/nvp6134c_i2c_bringup.vhd',
  'rtl/nvp/nvp6134c_autoinit.vhd'
)

$svRel = @(
  'rtl/v41/axi_lite_host_bridge.sv',
  'rtl/v41/axi_clock_lifecycle_monitor.sv',
  'rtl/v41/axi_clock_measurement_regs.sv',
  'rtl/v41/r1e_measurement_regs.sv',
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
  'rtl/top/ahd_capture_top_xdma.sv'
)

$stubRel = 'tests/v41/xdma_v41_m1_elaboration_stub.sv'
$staleExcluded = 'rtl/v41/nvp_i2c_address_probe.sv'

function Invoke-CapturedTool {
  param(
    [Parameter(Mandatory=$true)][string]$Tool,
    [Parameter(Mandatory=$true)][string[]]$Arguments,
    [Parameter(Mandatory=$true)][string]$WorkingDirectory,
    [Parameter(Mandatory=$true)][string]$Stem
  )

  $commandLines = [System.Collections.Generic.List[string]]::new()
  $commandLines.Add("TOOL=$Tool")
  $commandLines.Add("WORKING_DIRECTORY=$WorkingDirectory")
  for ($i = 0; $i -lt $Arguments.Count; $i++) {
    $commandLines.Add("ARG_$i=$($Arguments[$i])")
  }
  [System.IO.File]::WriteAllLines(
    "$Stem.command.txt", $commandLines, [System.Text.UTF8Encoding]::new($false))

  Push-Location -LiteralPath $WorkingDirectory
  try {
    $output = @(& $Tool @Arguments 2>&1 | ForEach-Object { $_.ToString() })
    $processExitCode = $LASTEXITCODE
  } finally {
    Pop-Location
  }

  [System.IO.File]::WriteAllLines(
    "$Stem.log", $output, [System.Text.UTF8Encoding]::new($false))
  [System.IO.File]::WriteAllText(
    "$Stem.exit.txt", "PROCESS_EXIT_CODE=$processExitCode`n",
    [System.Text.UTF8Encoding]::new($false))
  if ($processExitCode -ne 0) {
    throw "frontend tool failed with exit ${processExitCode}: $Tool"
  }
}

function Read-RepoFile {
  param([Parameter(Mandatory=$true)][string]$RelativePath)
  return [System.IO.File]::ReadAllText((Join-Path $Repo $RelativePath))
}

function Require-RegexCount {
  param(
    [Parameter(Mandatory=$true)][string]$Label,
    [Parameter(Mandatory=$true)][string]$Text,
    [Parameter(Mandatory=$true)][string]$Pattern,
    [Parameter(Mandatory=$true)][int]$Expected
  )
  $actual = [regex]::Matches($Text, $Pattern).Count
  if ($actual -ne $Expected) {
    throw "$Label count mismatch: expected $Expected, got $actual"
  }
}

function Get-DesignUnitNames {
  param(
    [Parameter(Mandatory=$true)][string[]]$Paths,
    [Parameter(Mandatory=$true)][string]$Pattern
  )
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($path in $Paths) {
    $text = [System.IO.File]::ReadAllText($path)
    foreach ($match in [regex]::Matches($text, $Pattern)) {
      $names.Add($match.Groups[1].Value.ToLowerInvariant())
    }
  }
  return $names.ToArray()
}

function Read-ExactNormalizedKeyValueReceipt {
  param(
    [Parameter(Mandatory=$true)][string]$Path,
    [Parameter(Mandatory=$true)][System.Collections.IDictionary]$AllowedIdenticalDuplicates
  )

  $values = [ordered]@{}
  $counts = [ordered]@{}
  $lineNumber = 0
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) {
      throw "blank line in key/value receipt at line $lineNumber"
    }
    $match = [regex]::Match($line, '\A([A-Z][A-Z0-9_]*)=(.*)\z')
    if (-not $match.Success) {
      throw "malformed or unknown receipt syntax at line ${lineNumber}: $line"
    }
    $key = $match.Groups[1].Value
    $value = $match.Groups[2].Value
    if ($values.Contains($key)) {
      if (-not $AllowedIdenticalDuplicates.Contains($key)) {
        throw "unexpected duplicate dry-run receipt key: $key"
      }
      $allowedValue = [string]$AllowedIdenticalDuplicates[$key]
      $firstValue = [string]$values[$key]
      if ($value -cne $firstValue -or $value -cne $allowedValue) {
        throw "contradictory duplicate dry-run receipt value for key: $key"
      }
      $counts[$key] = [int]$counts[$key] + 1
      if ([int]$counts[$key] -gt 2) {
        throw "allowed duplicate dry-run receipt key exceeds exact multiplicity 2: $key"
      }
      continue
    }
    $values.Add($key, $value)
    $counts.Add($key, 1)
  }

  foreach ($key in $AllowedIdenticalDuplicates.Keys) {
    if (-not $values.Contains($key)) {
      throw "allowed duplicate dry-run receipt key is absent: $key"
    }
    if ([int]$counts[$key] -ne 2) {
      throw "allowed duplicate dry-run receipt key multiplicity is not exactly 2: $key"
    }
    $expectedValue = [string]$AllowedIdenticalDuplicates[$key]
    if ([string]$values[$key] -cne $expectedValue) {
      throw "allowed duplicate dry-run receipt key has unexpected value: $key"
    }
  }

  $duplicateKeys = @($counts.Keys | Where-Object { [int]$counts[$_] -gt 1 })
  if ($duplicateKeys.Count -ne $AllowedIdenticalDuplicates.Count) {
    throw "normalized dry-run duplicate-key count mismatch: expected $($AllowedIdenticalDuplicates.Count), got $($duplicateKeys.Count)"
  }

  return [pscustomobject]@{
    Values = $values
    Counts = $counts
    RowCount = $lineNumber
    UniqueKeyCount = $values.Count
    DuplicateKeyCount = $duplicateKeys.Count
  }
}

if (Test-Path -LiteralPath $Run) {
  throw "exactly-once semantic preflight directory already exists: $Run"
}

foreach ($tool in @($Xvhdl, $Xvlog, $Xelab)) {
  if (-not (Test-Path -LiteralPath $tool -PathType Leaf)) {
    throw "required Vivado Simulator frontend tool is unavailable: $tool"
  }
}
if (-not (Test-Path -LiteralPath $Glbl -PathType Leaf)) {
  throw "installed Vivado glbl.v is unavailable: $Glbl"
}

$head = (& git -C $Repo rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $head -ne $ExpectedCommit) {
  throw "R1h source commit mismatch: expected $ExpectedCommit, got $head"
}
$tree = (& git -C $Repo rev-parse 'HEAD^{tree}').Trim()
if ($LASTEXITCODE -ne 0 -or $tree -ne $ExpectedTree) {
  throw "R1h source tree mismatch: expected $ExpectedTree, got $tree"
}
$status = @(& git -C $Repo status --porcelain=v1 --untracked-files=all)
if ($LASTEXITCODE -ne 0 -or $status.Count -ne 0) {
  throw 'R1h source worktree is not clean'
}

if (-not (Test-Path -LiteralPath $DryRunResult -PathType Leaf)) {
  throw 'passing one-shot project-setup dry-run receipt is required first'
}
$actualDryRunResultSha256 = (Get-FileHash -LiteralPath $DryRunResult -Algorithm SHA256).Hash
if ($actualDryRunResultSha256 -cne $ExpectedDryRunResultSha256) {
  throw "project-setup dry-run raw receipt SHA-256 mismatch: expected $ExpectedDryRunResultSha256, got $actualDryRunResultSha256"
}
$allowedDryRunIdenticalDuplicates = [ordered]@{
  FAILED_RECORD_WRAPPER_MODULE_NAME = 'v41_r1f_failed_txn_logger'
  FAILED_RECORD_WRAPPER_SOURCE_PATH = 'rtl/v41/r1f_failed_txn_logger.sv'
  PROBE_INDEX_WRAPPER_MODULE_NAME = 'r1h_probe_index_bram_store'
  PROBE_INDEX_WRAPPER_SOURCE_PATH = 'rtl/v41/r1h_probe_index_bram_store.sv'
}
$dryRunParse = Read-ExactNormalizedKeyValueReceipt `
  -Path $DryRunResult `
  -AllowedIdenticalDuplicates $allowedDryRunIdenticalDuplicates
if ($dryRunParse.RowCount -ne 90 -or
    $dryRunParse.UniqueKeyCount -ne 86 -or
    $dryRunParse.DuplicateKeyCount -ne 4) {
  throw "project-setup dry-run receipt shape mismatch: rows=$($dryRunParse.RowCount) unique=$($dryRunParse.UniqueKeyCount) duplicate_keys=$($dryRunParse.DuplicateKeyCount)"
}
$dryRunReceipt = $dryRunParse.Values
$requiredDryRunValues = [ordered]@{
  R1H_R2_BUILD_HARNESS_CORRECTION_MODE = 'TASK_LOCAL_ZERO_REPOSITORY_MUTATION'
  R1H_SOURCE_COMMIT = $ExpectedCommit
  R1H_SOURCE_TREE = $ExpectedTree
  VIVADO_VERSION = '2025.2'
  VIVADO_SW_BUILD = '6299465'
  PART = $PartContext
  TOP = $Top
  WRAPPER_SOURCE_FILE_COUNT = '1'
  CONSUMER_SOURCE_FILE_COUNT = '1'
  RELATIVE_SOURCE_POSITION_ASSERTION = 'REMOVED_OR_DISABLED'
  RELATIVE_SOURCE_POSITION_USED_AS_GATE = 'NO'
  COMPILE_ORDER_RECORDED = 'YES'
  SYSTEMVERILOG_RELATIVE_COMPILE_ORDER_USED_AS_PASS_FAIL_GATE = 'NO'
  VHDL_DEPENDENCY_ORDER_USED_AS_PASS_FAIL_GATE = 'YES'
  FAILED_RECORD_BRAM_BANK_COUNT = '6'
  PROBE_INDEX_BRAM_INSTANCE_COUNT = '3'
  DUPLICATE_DEFINITIONS = '0'
  UNRESOLVED_INCLUDE_OR_PACKAGE_DEPENDENCIES = '0'
  R1H_FALSE_ASSERTION_TRIGGERED = 'NO'
  PROJECT_SETUP_SEMANTIC_GATE = 'PASS'
  PROJECT_SETUP_DRY_RUNS = '1'
  PROJECT_SETUP_DRY_RUN = 'PASS'
  PROCESS_EXIT_CODE = '0'
}
foreach ($key in $requiredDryRunValues.Keys) {
  if (-not $dryRunReceipt.Contains($key)) {
    throw "project-setup dry-run receipt lacks exact key: $key"
  }
  $expectedValue = [string]$requiredDryRunValues[$key]
  $actualValue = [string]$dryRunReceipt[$key]
  if ($actualValue -cne $expectedValue) {
    throw "project-setup dry-run receipt value mismatch for ${key}: expected '$expectedValue', got '$actualValue'"
  }
}

$duplicateNormalizationAuditLines = [System.Collections.Generic.List[string]]::new()
$duplicateNormalizationAuditLines.Add("DRY_RUN_RAW_RESULT_SHA256=$actualDryRunResultSha256")
$duplicateNormalizationAuditLines.Add("DRY_RUN_RECEIPT_ROWS=$($dryRunParse.RowCount)")
$duplicateNormalizationAuditLines.Add("DRY_RUN_RECEIPT_UNIQUE_KEYS=$($dryRunParse.UniqueKeyCount)")
$duplicateNormalizationAuditLines.Add("DRY_RUN_ALLOWED_IDENTICAL_DUPLICATE_KEY_COUNT=$($dryRunParse.DuplicateKeyCount)")
$duplicateNormalizationAuditLines.Add('DRY_RUN_ALLOWED_DUPLICATE_MULTIPLICITY=2')
$duplicateNormalizationAuditLines.Add('DRY_RUN_CONTRADICTORY_DUPLICATES=0')
$duplicateNormalizationAuditLines.Add('DRY_RUN_UNEXPECTED_DUPLICATES=0')
foreach ($key in $allowedDryRunIdenticalDuplicates.Keys) {
  $duplicateNormalizationAuditLines.Add(
    "ALLOWED_IDENTICAL_DUPLICATE|KEY=$key|MULTIPLICITY=$($dryRunParse.Counts[$key])|VALUE=$($dryRunReceipt[$key])")
}
$duplicateNormalizationAuditLines.Add(
  'DRY_RUN_DUPLICATE_NORMALIZATION=PASS_EXACT_FOUR_KEYS_MULTIPLICITY_2_IDENTICAL_VALUES')
$duplicateNormalizationAuditCanonical =
  ($duplicateNormalizationAuditLines -join "`n") + "`n"
$sha256Provider = [System.Security.Cryptography.SHA256]::Create()
try {
  $duplicateNormalizationAuditBytes = $sha256Provider.ComputeHash(
    [System.Text.Encoding]::UTF8.GetBytes($duplicateNormalizationAuditCanonical))
} finally {
  $sha256Provider.Dispose()
}
$duplicateNormalizationAuditSha256 =
  ([System.BitConverter]::ToString($duplicateNormalizationAuditBytes)).Replace('-', '')
if ($duplicateNormalizationAuditSha256 -cne $ExpectedDuplicateNormalizationAuditSha256) {
  throw "dry-run duplicate-normalization canonical SHA-256 mismatch: expected $ExpectedDuplicateNormalizationAuditSha256, got $duplicateNormalizationAuditSha256"
}

if ($vhdlRel.Count -ne 4) { throw "VHDL source count is not exact: $($vhdlRel.Count)" }
if ($svRel.Count -ne 17) { throw "SystemVerilog source count is not exact: $($svRel.Count)" }
if (($vhdlRel + $svRel) -contains $staleExcluded) {
  throw "stale non-production source was included: $staleExcluded"
}
if ($svRel.Count -ne (@($svRel | Sort-Object -Unique)).Count) {
  throw 'duplicate SystemVerilog source path in exact list'
}
if ($vhdlRel.Count -ne (@($vhdlRel | Sort-Object -Unique)).Count) {
  throw 'duplicate VHDL source path in exact list'
}

$vhdlPaths = @($vhdlRel | ForEach-Object { Join-Path $Repo $_ })
$svPaths = @($svRel | ForEach-Object { Join-Path $Repo $_ })
$stubPath = Join-Path $Repo $stubRel
foreach ($path in @($vhdlPaths + $svPaths + $stubPath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "semantic preflight source missing: $path"
  }
}

$svDesignUnits = @(Get-DesignUnitNames -Paths @($svPaths + $stubPath) `
  -Pattern '(?m)^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b')
$svDuplicates = @($svDesignUnits | Group-Object | Where-Object Count -gt 1)
if ($svDuplicates.Count -ne 0) {
  throw "duplicate SystemVerilog module definitions: $($svDuplicates.Name -join ', ')"
}
$vhdlDesignUnits = @(Get-DesignUnitNames -Paths $vhdlPaths `
  -Pattern '(?im)^\s*(?:entity|package(?!\s+body))\s+([A-Za-z][A-Za-z0-9_]*)\s+is\b')
$vhdlDuplicates = @($vhdlDesignUnits | Group-Object | Where-Object Count -gt 1)
if ($vhdlDuplicates.Count -ne 0) {
  throw "duplicate VHDL entity/package definitions: $($vhdlDuplicates.Name -join ', ')"
}

$topText = Read-RepoFile 'rtl/top/ahd_capture_top_xdma.sv'
$probeStoreText = Read-RepoFile 'rtl/v41/r1h_probe_index_bram_store.sv'
$probeText = Read-RepoFile 'rtl/v41/nvp_i2c_tri_phase_probe.sv'
$loggerText = Read-RepoFile 'rtl/v41/r1f_failed_txn_logger.sv'
$mmioText = Read-RepoFile 'rtl/v41/r1h_mmio_read_service.sv'
$stubText = Read-RepoFile $stubRel

Require-RegexCount 'top declaration' $topText `
  '(?m)^\s*module\s+ahd_capture_top_xdma\b' 1
Require-RegexCount 'probe-index wrapper declaration' $probeStoreText `
  '(?m)^\s*module\s+r1h_probe_index_bram_store\b' 1
Require-RegexCount 'probe consumer declaration' $probeText `
  '(?m)^\s*module\s+nvp_i2c_tri_phase_probe\b' 1
Require-RegexCount 'failed-record wrapper declaration' $loggerText `
  '(?m)^\s*module\s+v41_r1f_failed_txn_logger\b' 1
Require-RegexCount 'MMIO service declaration' $mmioText `
  '(?m)^\s*module\s+v41_r1h_mmio_read_service\b' 1
Require-RegexCount 'XDMA stub declaration' $stubText `
  '(?m)^\s*module\s+xdma_v41_m1\b' 1

Require-RegexCount 'probe-index wrapper production instantiation' $probeText `
  '(?m)^\s*r1h_probe_index_bram_store\s+INDEX_PAYLOAD_STORE\s*\(' 1
Require-RegexCount 'probe consumer production instantiation' $topText `
  '(?m)^\s*nvp_i2c_tri_phase_probe\s*#\s*\(' 1
Require-RegexCount 'failed-record wrapper production instantiation' $topText `
  '(?m)^\s*v41_r1f_failed_txn_logger\s+R1F_FAILED_TXN_LOGGER\s*\(' 1
Require-RegexCount 'MMIO service production instantiation' $topText `
  '(?m)^\s*v41_r1h_mmio_read_service\s+R1H_MMIO_READ_SERVICE\s*\(' 1
Require-RegexCount 'XDMA production instantiation' $topText `
  '(?m)^\s*xdma_v41_m1\s+XDMA\s*\(' 1

Require-RegexCount 'failed-record six-bank generate' $loggerText `
  'for\s*\(\s*bank_index\s*=\s*0\s*;\s*bank_index\s*<\s*6\s*;' 1
Require-RegexCount 'probe-index three-bank generate' $probeStoreText `
  'for\s*\(\s*phase_bank\s*=\s*0\s*;\s*phase_bank\s*<\s*3\s*;' 1
Require-RegexCount 'failed-record XPM template' $loggerText `
  '(?m)^\s*xpm_memory_sdpram\s*#\s*\(' 1
Require-RegexCount 'probe-index XPM template' $probeStoreText `
  '(?m)^\s*xpm_memory_sdpram\s*#\s*\(' 1

$inputManifest = [System.Collections.Generic.List[string]]::new()
$inputManifest.Add('role,relative_or_installed_path,bytes,sha256')
$inputHashes = [ordered]@{}
foreach ($relative in $vhdlRel) {
  $path = Join-Path $Repo $relative
  $item = Get-Item -LiteralPath $path
  $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  $inputManifest.Add(('production-vhdl,"{0}",{1},{2}' -f $relative,$item.Length,$sha))
  $inputHashes[$path] = $sha
}
foreach ($relative in $svRel) {
  $path = Join-Path $Repo $relative
  $item = Get-Item -LiteralPath $path
  $sha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  $inputManifest.Add(('production-systemverilog,"{0}",{1},{2}' -f $relative,$item.Length,$sha))
  $inputHashes[$path] = $sha
}
foreach ($support in @($stubPath, $Glbl)) {
  $item = Get-Item -LiteralPath $support
  $sha = (Get-FileHash -LiteralPath $support -Algorithm SHA256).Hash
  $inputManifest.Add(('simulation-support,"{0}",{1},{2}' -f $support,$item.Length,$sha))
  $inputHashes[$support] = $sha
}

[void](New-Item -ItemType Directory -Path $Run)
[System.IO.File]::WriteAllLines(
  (Join-Path $Run 'SEMANTIC_PREFLIGHT_STARTED.txt'),
  @(
    "TASK=$Task",
    'SEMANTIC_ELABORATION_PREFLIGHTS=1',
    "SOURCE_COMMIT=$ExpectedCommit",
    "SOURCE_TREE=$ExpectedTree",
    "TOP=$Top",
    "PART_CONTEXT=$PartContext",
    'VIVADO_VERSION=2025.2',
    'VIVADO_BUILD_CONTEXT=6299465'
  ),
  [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllLines(
  (Join-Path $Run 'SEMANTIC_INPUT_SHA256.csv'),
  $inputManifest,
  [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText(
  (Join-Path $Run 'DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT.txt'),
  $duplicateNormalizationAuditCanonical,
  [System.Text.UTF8Encoding]::new($false))

Invoke-CapturedTool -Tool $Xvhdl `
  -Arguments (@('--work','work') + $vhdlPaths) `
  -WorkingDirectory $Run -Stem (Join-Path $Run 'xvhdl')
Invoke-CapturedTool -Tool $Xvlog `
  -Arguments (@('--sv','--work','work') + $svPaths + $stubPath + $Glbl) `
  -WorkingDirectory $Run -Stem (Join-Path $Run 'xvlog')
Invoke-CapturedTool -Tool $Xelab `
  -Arguments @($Top,'glbl','-L','xpm','-L','unisims_ver','-debug','typical','-s',$Snapshot) `
  -WorkingDirectory $Run -Stem (Join-Path $Run 'xelab')

$xvhdlLog = [System.IO.File]::ReadAllText((Join-Path $Run 'xvhdl.log'))
$xvlogLog = [System.IO.File]::ReadAllText((Join-Path $Run 'xvlog.log'))
$xelabLog = [System.IO.File]::ReadAllText((Join-Path $Run 'xelab.log'))
$allFrontendLog = $xvhdlLog + "`n" + $xvlogLog + "`n" + $xelabLog
$hardFailurePattern = '(?im)^\s*(?:ERROR|FATAL):|severity\s+failure|\$fatal'
$unresolvedPattern = '(?im)black\s*box|unresolved\s+(?:module|entity|design\s+unit)|cannot\s+find\s+(?:module|entity)|(?:module|entity).*not\s+found|is\s+not\s+bound|failed\s+to\s+bind'
if ($allFrontendLog -match $hardFailurePattern) {
  throw 'frontend logs contain an error, fatal diagnostic, or severity failure'
}
if ($allFrontendLog -match $unresolvedPattern) {
  throw 'frontend logs contain an unresolved design unit or black-box diagnostic'
}
if (-not $xelabLog.Contains("Built simulation snapshot $Snapshot")) {
  throw 'xelab did not report the exact semantic snapshot'
}

$requiredBindingFragments = @(
  'Compiling module work.r1h_probe_index_bram_store_',
  'Compiling module work.nvp_i2c_tri_phase_probe_',
  'Compiling module work.v41_r1f_failed_txn_logger_',
  'Compiling module work.v41_r1h_mmio_read_service',
  'Compiling module work.ahd_capture_top_xdma',
  'Compiling module work.xdma_v41_m1'
)
foreach ($fragment in $requiredBindingFragments) {
  if (-not $xelabLog.Contains($fragment)) {
    throw "xelab binding marker missing: $fragment"
  }
}

foreach ($path in $inputHashes.Keys) {
  $expectedSha = $inputHashes[$path]
  $actualSha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if ($actualSha -ne $expectedSha) {
    throw "semantic input changed during preflight: $path"
  }
}

$receipt = @(
  "TASK=$Task",
  'EXPERIMENT_NAME=R1h',
  'CONTINUATION_REVISION=R2',
  "R1H_SOURCE_COMMIT=$ExpectedCommit",
  "R1H_SOURCE_TREE=$ExpectedTree",
  'VIVADO_SIMULATOR_VERSION=2025.2',
  'VIVADO_BUILD_CONTEXT=6299465',
  "TOP=$Top",
  "PART_CONTEXT=$PartContext",
  'PRODUCTION_VHDL_MODE=DEFAULT_NON_2008',
  'PRODUCTION_VHDL_SOURCE_COUNT=4',
  'PRODUCTION_SYSTEMVERILOG_SOURCE_COUNT=17',
  'STALE_NVP_I2C_ADDRESS_PROBE_INCLUDED=NO',
  "DRY_RUN_RAW_RESULT_SHA256=$actualDryRunResultSha256",
  "DRY_RUN_RECEIPT_ROWS=$($dryRunParse.RowCount)",
  "DRY_RUN_RECEIPT_UNIQUE_KEYS=$($dryRunParse.UniqueKeyCount)",
  "DRY_RUN_ALLOWED_IDENTICAL_DUPLICATE_KEY_COUNT=$($dryRunParse.DuplicateKeyCount)",
  'DRY_RUN_ALLOWED_DUPLICATE_MULTIPLICITY=2',
  'DRY_RUN_CONTRADICTORY_DUPLICATES=0',
  'DRY_RUN_UNEXPECTED_DUPLICATES=0',
  'DRY_RUN_DUPLICATE_NORMALIZATION=PASS_EXACT_FOUR_KEYS_MULTIPLICITY_2_IDENTICAL_VALUES',
  "DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256=$duplicateNormalizationAuditSha256",
  'XDMA_ELABORATION_STUB=ACCEPTED_SIMULATION_ONLY',
  'XPM_LIBRARY=BOUND',
  'UNISIMS_VER_LIBRARY=BOUND',
  'DUPLICATE_DEFINITIONS=0',
  'UNRESOLVED_MODULES=0',
  'UNRESOLVED_BLACKBOXES=0',
  'FAILED_RECORD_WRAPPER_MODULE=v41_r1f_failed_txn_logger',
  'FAILED_RECORD_WRAPPER_INSTANTIATION_COUNT=1',
  'FAILED_RECORD_XPM_BANK_COUNT_SOURCE_DERIVED=6',
  'FAILED_RECORD_WRAPPER_BINDING=PASS',
  'PROBE_INDEX_WRAPPER_MODULE=r1h_probe_index_bram_store',
  'PROBE_INDEX_WRAPPER_INSTANTIATION_COUNT=1',
  'PROBE_INDEX_XPM_BANK_COUNT_SOURCE_DERIVED=3',
  'PROBE_INDEX_WRAPPER_BINDING=PASS',
  'PROBE_CONSUMER_MODULE=nvp_i2c_tri_phase_probe',
  'PROBE_CONSUMER_BINDING=PASS',
  'MMIO_READ_SERVICE_MODULE=v41_r1h_mmio_read_service',
  'MMIO_READ_SERVICE_BINDING=PASS',
  'R1H_TEST_ELABORATION=PASS',
  'XVHDL_INVOCATIONS=1',
  'XVLOG_INVOCATIONS=1',
  'XELAB_INVOCATIONS=1',
  'SYNTH_DESIGN_INVOCATIONS=0',
  'OPT_DESIGN_INVOCATIONS=0',
  'PLACE_DESIGN_INVOCATIONS=0',
  'PHYS_OPT_DESIGN_INVOCATIONS=0',
  'ROUTE_DESIGN_INVOCATIONS=0',
  'WRITE_CHECKPOINT_INVOCATIONS=0',
  'WRITE_BITSTREAM_INVOCATIONS=0',
  'SEMANTIC_ELABORATION_PREFLIGHTS=1',
  'SEMANTIC_ELABORATION=PASS',
  'PROCESS_EXIT_CODE=0',
  "XVHDL_LOG_SHA256=$((Get-FileHash -LiteralPath (Join-Path $Run 'xvhdl.log') -Algorithm SHA256).Hash)",
  "XVLOG_LOG_SHA256=$((Get-FileHash -LiteralPath (Join-Path $Run 'xvlog.log') -Algorithm SHA256).Hash)",
  "XELAB_LOG_SHA256=$((Get-FileHash -LiteralPath (Join-Path $Run 'xelab.log') -Algorithm SHA256).Hash)",
  "INPUT_MANIFEST_SHA256=$((Get-FileHash -LiteralPath (Join-Path $Run 'SEMANTIC_INPUT_SHA256.csv') -Algorithm SHA256).Hash)"
)
[System.IO.File]::WriteAllLines(
  (Join-Path $Run 'R1H_R2_SEMANTIC_ELABORATION_RESULT.txt'),
  $receipt,
  [System.Text.UTF8Encoding]::new($false))

Write-Output 'R1H_TEST_ELABORATION=PASS'
Write-Output 'R1H_R2_SEMANTIC_ELABORATION=PASS'
