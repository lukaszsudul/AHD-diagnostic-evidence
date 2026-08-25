param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION\06_BUILD\PREBUILD'
$Generator = Join-Path $Root 'New-R1hR2PrebuildManifest.ps1'
$text = [System.IO.File]::ReadAllText($Generator)
$tokens = $null
$parseErrors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
  $Generator,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count -ne 0) { throw "generator parse errors: $($parseErrors.Message -join '; ')" }

$commands = @($ast.FindAll(
  { param($node) $node -is [System.Management.Automation.Language.CommandAst] },
  $true) | ForEach-Object { $_.GetCommandName() } | Where-Object { $null -ne $_ })
$forbidden = @(
  'vivado','xvhdl','xvlog','xelab','xsim','synth_design','opt_design',
  'place_design','phys_opt_design','route_design','write_checkpoint',
  'write_bitstream','program_hw_devices','open_hw_manager','connect_hw_server',
  'ssh','scp','git.exe'
)
foreach ($name in $forbidden) {
  if (@($commands | Where-Object { $_ -ieq $name }).Count -ne 0) {
    throw "forbidden P5 generator command: $name"
  }
}

if ([regex]::Matches($text,'(?m)^\s*if\s*\(-not\s+\$FinalizeAfterP4Pass\.IsPresent\)').Count -ne 1) {
  throw 'exact post-P4 finalization guard is absent or duplicated'
}
$gitCalls = @([regex]::Matches(
  $text,
  "Invoke-ReadOnlyGitLines\s+@\('([^']+)'"
) | ForEach-Object { $_.Groups[1].Value })
$expectedGitCalls = @('rev-parse','rev-parse','symbolic-ref','status','ls-files')
if (($gitCalls -join '|') -cne ($expectedGitCalls -join '|')) {
  throw "future read-only Git invocation set mismatch: $($gitCalls -join ',')"
}

$requiredLiterals = @(
  '192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79',
  '5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F',
  'c4f4bfcf577c92c3021d1fe83c05878dd12e001c',
  '161e561f007912d73dba93c5ecd78e3cc3a6955b',
  'SOURCE_RECORDS=224',
  'SOURCE_ROWS_BYTE_IDENTICAL_TO_R1H=YES',
  'R1H_RTL_BLOBS_UNCHANGED=YES',
  'R1H_XDC_UNCHANGED=YES',
  'R1H_XDMA_XCI_UNCHANGED=YES',
  'R1H_HOST_DECODERS_UNCHANGED=YES',
  'R1H_STATISTICAL_PLAN_UNCHANGED=YES',
  'R1H_R2_SEMANTIC_ELABORATION_INDEPENDENT_AUDIT.txt',
  'R1H_TEST_ELABORATION=''PASS''',
  'SEMANTIC_ELABORATION=''PASS''',
  'BLOCKERS=''NONE'''
)
foreach ($literal in $requiredLiterals) {
  if (-not $text.Contains($literal)) { throw "P5 generator contract literal missing: $literal" }
}

$outputs = @(
  'R1H_R2_PREBUILD_MANIFEST.txt',
  'R1H_R2_PREBUILD_MANIFEST_SHA256.txt',
  'R1H_R2_PREBUILD_MANIFEST_VERIFICATION.txt'
)
foreach ($output in $outputs) {
  if (Test-Path -LiteralPath (Join-Path $Root $output)) {
    throw "P5 output exists before authorized finalization: $output"
  }
}

@(
  'R1H_R2_P5_PREBUILD_GENERATOR_STATIC_AUDIT=PASS',
  'P5_PREBUILD_FINALIZED=NO',
  'P4_PASS_REQUIRED=YES',
  'GENERATOR_PARSE_ERRORS=0',
  'GENERATOR_VIVADO_COMMANDS=0',
  'GENERATOR_SYNTHESIS_IMPLEMENTATION_COMMANDS=0',
  'GENERATOR_HARDWARE_COMMANDS=0',
  'FUTURE_GIT_MODE=READ_ONLY_ALLOWLIST',
  "FUTURE_READ_ONLY_GIT_CALLS=$($gitCalls.Count)",
  'R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c',
  'R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b',
  'R1H_SOURCE_ROWS_REQUIRED=224',
  'R1H_ORIGINAL_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79',
  'CORRECTED_HARNESS_SHA256=5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F',
  "GENERATOR_SHA256=$((Get-FileHash -LiteralPath $Generator -Algorithm SHA256).Hash)"
)
