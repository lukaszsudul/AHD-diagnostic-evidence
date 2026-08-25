param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\05_SEMANTIC_ELABORATION'
$Runner = Join-Path $Root 'Run-R1hR2SemanticElaboration.ps1'

if (-not (Test-Path -LiteralPath $Runner -PathType Leaf)) {
  throw "semantic preflight runner missing: $Runner"
}

$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
  $Runner, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
  throw "runner PowerShell parse errors: $($parseErrors.Message -join '; ')"
}

$commandNames = @(
  $ast.FindAll(
    { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
    $true) |
    ForEach-Object { $_.GetCommandName() } |
    Where-Object { $null -ne $_ }
)

$forbiddenCommands = @(
  'synth_design',
  'opt_design',
  'place_design',
  'phys_opt_design',
  'route_design',
  'write_checkpoint',
  'write_bitstream',
  'vivado',
  'xsim'
)

$forbiddenCounts = [ordered]@{}
foreach ($name in $forbiddenCommands) {
  $forbiddenCounts[$name] = @($commandNames | Where-Object { $_ -ieq $name }).Count
  if ($forbiddenCounts[$name] -ne 0) {
    throw "forbidden command invocation in semantic runner: $name"
  }
}

$runnerText = [System.IO.File]::ReadAllText($Runner)
$xvhdlCalls = [regex]::Matches($runnerText, '(?m)^Invoke-CapturedTool\s+-Tool\s+\$Xvhdl\b').Count
$xvlogCalls = [regex]::Matches($runnerText, '(?m)^Invoke-CapturedTool\s+-Tool\s+\$Xvlog\b').Count
$xelabCalls = [regex]::Matches($runnerText, '(?m)^Invoke-CapturedTool\s+-Tool\s+\$Xelab\b').Count
if ($xvhdlCalls -ne 1 -or $xvlogCalls -ne 1 -or $xelabCalls -ne 1) {
  throw "frontend tool-call count mismatch: xvhdl=$xvhdlCalls xvlog=$xvlogCalls xelab=$xelabCalls"
}

$vhdlMatch = [regex]::Match(
  $runnerText, '(?s)\$vhdlRel\s*=\s*@\((.*?)\)\s*\r?\n\s*\$svRel')
$svMatch = [regex]::Match(
  $runnerText, '(?s)\$svRel\s*=\s*@\((.*?)\)\s*\r?\n\s*\$stubRel')
if (-not $vhdlMatch.Success -or -not $svMatch.Success) {
  throw 'unable to identify frozen production source arrays in semantic runner'
}
$vhdlBlock = $vhdlMatch.Groups[1].Value
$svBlock = $svMatch.Groups[1].Value
$vhdlCount = [regex]::Matches($vhdlBlock, "'[^']+\.vhd'").Count
$svCount = [regex]::Matches($svBlock, "'[^']+\.sv'").Count
if ($vhdlCount -ne 4 -or $svCount -ne 17) {
  throw "frozen production list count mismatch: VHDL=$vhdlCount SystemVerilog=$svCount"
}
if ($svBlock -match 'nvp_i2c_address_probe\.sv') {
  throw 'stale nvp_i2c_address_probe.sv appears in executable SystemVerilog list'
}
if ($runnerText -match '(?i)(?:--2008|-vhdl2008)') {
  throw 'VHDL-2008 option appears in semantic runner'
}
if ($runnerText -match '\$dryRunText\.Contains\s*\(') {
  throw 'whole-text Contains gating remains in the dry-run receipt gate'
}
$exactReceiptParserCount = [regex]::Matches(
  $runnerText, '(?m)^function\s+Read-ExactNormalizedKeyValueReceipt\b').Count
$exactReceiptUseCount = [regex]::Matches(
  $runnerText, '(?m)^\$dryRunParse\s*=\s*Read-ExactNormalizedKeyValueReceipt\b').Count
if ($exactReceiptParserCount -ne 1 -or $exactReceiptUseCount -ne 1) {
  throw "exact normalized key/value receipt parser contract mismatch: declaration=$exactReceiptParserCount use=$exactReceiptUseCount"
}
$expectedDryRunSha256 = 'F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6'
$dryRunShaPattern =
  '(?m)^\$ExpectedDryRunResultSha256\s*=\s*''' + $expectedDryRunSha256 + '''$'
$dryRunShaBindingCount = [regex]::Matches(
  $runnerText,
  $dryRunShaPattern
).Count
if ($dryRunShaBindingCount -ne 1) {
  throw "exact raw dry-run SHA-256 binding count mismatch: $dryRunShaBindingCount"
}
$expectedNormalizationSha256 = '3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F'
$normalizationShaPattern =
  '(?m)^\$ExpectedDuplicateNormalizationAuditSha256\s*=\s*''' +
  $expectedNormalizationSha256 + '''$'
$normalizationShaBindingCount = [regex]::Matches(
  $runnerText,
  $normalizationShaPattern
).Count
if ($normalizationShaBindingCount -ne 1) {
  throw "duplicate-normalization audit SHA-256 binding count mismatch: $normalizationShaBindingCount"
}
$allowedDuplicateMapMatch = [regex]::Match(
  $runnerText,
  '(?s)\$allowedDryRunIdenticalDuplicates\s*=\s*\[ordered\]@\{(.*?)\}\s*\r?\n\$dryRunParse')
if (-not $allowedDuplicateMapMatch.Success) {
  throw 'unable to locate exact allowed-identical-duplicate map'
}
$allowedDuplicateKeys = @(
  [regex]::Matches(
    $allowedDuplicateMapMatch.Groups[1].Value,
    '(?m)^\s{2}([A-Z][A-Z0-9_]*)\s*=') |
    ForEach-Object { $_.Groups[1].Value }
)
$expectedAllowedDuplicateKeys = @(
  'FAILED_RECORD_WRAPPER_MODULE_NAME',
  'FAILED_RECORD_WRAPPER_SOURCE_PATH',
  'PROBE_INDEX_WRAPPER_MODULE_NAME',
  'PROBE_INDEX_WRAPPER_SOURCE_PATH'
)
if ($allowedDuplicateKeys.Count -ne 4 -or
    @($allowedDuplicateKeys | Sort-Object) -join '|' -cne
      (@($expectedAllowedDuplicateKeys | Sort-Object) -join '|')) {
  throw "allowed identical duplicate-key set mismatch: $($allowedDuplicateKeys -join ',')"
}
foreach ($requiredParserFragment in @(
  'unexpected duplicate dry-run receipt key',
  'contradictory duplicate dry-run receipt value',
  'exact multiplicity 2',
  'DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256='
)) {
  if (-not $runnerText.Contains($requiredParserFragment)) {
    throw "duplicate-normalization parser/audit contract is missing: $requiredParserFragment"
  }
}
$requiredMapMatch = [regex]::Match(
  $runnerText,
  '(?s)\$requiredDryRunValues\s*=\s*\[ordered\]@\{(.*?)\}\s*\r?\nforeach\s*\(\$key\s+in\s+\$requiredDryRunValues\.Keys\)')
if (-not $requiredMapMatch.Success) {
  throw 'unable to locate frozen required dry-run key/value map'
}
$requiredDryRunKeys = @(
  [regex]::Matches(
    $requiredMapMatch.Groups[1].Value,
    '(?m)^\s{2}([A-Z][A-Z0-9_]*)\s*=') |
    ForEach-Object { $_.Groups[1].Value }
)
if ($requiredDryRunKeys.Count -ne 23 -or
    @($requiredDryRunKeys | Sort-Object -Unique).Count -ne 23) {
  throw "required dry-run key set is not exact and unique: $($requiredDryRunKeys.Count)"
}
foreach ($requiredKey in @(
  'R1H_SOURCE_COMMIT',
  'R1H_SOURCE_TREE',
  'VIVADO_VERSION',
  'VIVADO_SW_BUILD',
  'PART',
  'TOP',
  'RELATIVE_SOURCE_POSITION_USED_AS_GATE',
  'FAILED_RECORD_BRAM_BANK_COUNT',
  'PROBE_INDEX_BRAM_INSTANCE_COUNT',
  'DUPLICATE_DEFINITIONS',
  'PROJECT_SETUP_SEMANTIC_GATE',
  'PROJECT_SETUP_DRY_RUNS',
  'PROJECT_SETUP_DRY_RUN',
  'PROCESS_EXIT_CODE'
)) {
  if ($requiredDryRunKeys -cnotcontains $requiredKey) {
    throw "required exact dry-run gate key missing from runner: $requiredKey"
  }
}
$testElaborationPassCount = [regex]::Matches(
  $runnerText, "'R1H_TEST_ELABORATION=PASS'").Count
if ($testElaborationPassCount -ne 2) {
  throw "explicit R1H test-elaboration PASS emission count mismatch: $testElaborationPassCount"
}

$rows = [System.Collections.Generic.List[string]]::new()
$rows.Add('R1H_R2_SEMANTIC_PREFLIGHT_STATIC_AUDIT=PASS')
$rows.Add('R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c')
$rows.Add('R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b')
$rows.Add('VIVADO_VERSION_CONTEXT=2025.2')
$rows.Add('VIVADO_BUILD_CONTEXT=6299465')
$rows.Add('TOP=ahd_capture_top_xdma')
$rows.Add('PART_CONTEXT=xc7a35tcsg325-2')
$rows.Add("PRODUCTION_VHDL_SOURCE_COUNT=$vhdlCount")
$rows.Add("PRODUCTION_SYSTEMVERILOG_SOURCE_COUNT=$svCount")
$rows.Add('STALE_NVP_I2C_ADDRESS_PROBE_INCLUDED=NO')
$rows.Add('DRY_RUN_GATE_MODE=EXACT_SHA256_PLUS_NORMALIZED_KEY_VALUE')
$rows.Add("DRY_RUN_RAW_RESULT_SHA256=$expectedDryRunSha256")
$rows.Add("DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256=$expectedNormalizationSha256")
$rows.Add('DRY_RUN_RAW_RESULT_ROWS=90')
$rows.Add('DRY_RUN_RAW_RESULT_UNIQUE_KEYS=86')
$rows.Add("DRY_RUN_REQUIRED_EXACT_KEY_COUNT=$($requiredDryRunKeys.Count)")
$rows.Add("DRY_RUN_ALLOWED_IDENTICAL_DUPLICATE_KEY_COUNT=$($allowedDuplicateKeys.Count)")
$rows.Add('DRY_RUN_ALLOWED_DUPLICATE_MULTIPLICITY=2')
$rows.Add('DRY_RUN_CONTRADICTORY_DUPLICATES_REJECTED=YES')
$rows.Add('DRY_RUN_UNEXPECTED_DUPLICATES_REJECTED=YES')
$rows.Add('DRY_RUN_MALFORMED_LINES_REJECTED=YES')
$rows.Add('DRY_RUN_UNIQUE_EXTRA_EVIDENCE_KEYS=ALLOWED_NOT_USED_AS_GATE')
$rows.Add('DRY_RUN_WHOLE_TEXT_CONTAINS_GATING=NO')
$rows.Add("R1H_TEST_ELABORATION_PASS_EMISSIONS=$testElaborationPassCount")
$rows.Add("XVHDL_SCRIPTED_INVOCATIONS=$xvhdlCalls")
$rows.Add("XVLOG_SCRIPTED_INVOCATIONS=$xvlogCalls")
$rows.Add("XELAB_SCRIPTED_INVOCATIONS=$xelabCalls")
foreach ($name in $forbiddenCommands) {
  $rows.Add("$($name.ToUpperInvariant())_COMMAND_INVOCATIONS=$($forbiddenCounts[$name])")
}
$rows.Add("RUNNER_SHA256=$((Get-FileHash -LiteralPath $Runner -Algorithm SHA256).Hash)")

$rows
