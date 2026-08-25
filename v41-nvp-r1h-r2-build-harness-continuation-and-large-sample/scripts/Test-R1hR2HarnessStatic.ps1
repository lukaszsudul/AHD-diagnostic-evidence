[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TaskRoot = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION'
$Baseline = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\r1h_build.tcl'
$Corrected = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\r1h_r2_build.tcl'
$DryRun = Join-Path $TaskRoot '04_PROJECT_SETUP_DRY_RUN\r1h_r2_project_setup_dry_run.tcl'
$ElaborationRunner = Join-Path $TaskRoot '05_SEMANTIC_ELABORATION\Run-R1hR2SemanticElaboration.ps1'
$PatchPath = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\R1H_TO_R1H_R2_HARNESS.patch'
$CsvPath = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\BUILD_COMMAND_RECONCILIATION.csv'
$AuditPath = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\R1H_R2_HARNESS_STATIC_AUDIT.txt'
$HashPath = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\R1H_R2_HARNESS_SHA256.txt'
$ExpectedBaselineSha = '2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18'

function Write-Utf8Lines {
    param([string]$Path, [string[]]$Lines)
    [System.IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [System.IO.File]::WriteAllLines($Path, $Lines, [System.Text.UTF8Encoding]::new($false))
}

function Get-LiteralRegion {
    param(
        [string]$Text,
        [string]$Start,
        [string]$End
    )
    $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
    if ($startIndex -lt 0) { throw "Region start not found: $Start" }
    $endIndex = $Text.IndexOf($End, $startIndex, [StringComparison]::Ordinal)
    if ($endIndex -lt 0) { throw "Region end not found after start: $End" }
    return $Text.Substring($startIndex, $endIndex - $startIndex)
}

function Remove-LiteralRegion {
    param(
        [string]$Text,
        [string]$Start,
        [string]$End,
        [string]$Replacement
    )
    $startIndex = $Text.IndexOf($Start, [StringComparison]::Ordinal)
    if ($startIndex -lt 0) { throw "Region start not found: $Start" }
    $endIndex = $Text.IndexOf($End, $startIndex, [StringComparison]::Ordinal)
    if ($endIndex -lt 0) { throw "Region end not found after start: $End" }
    return $Text.Substring(0, $startIndex) + $Replacement + $Text.Substring($endIndex)
}

function Assert-Equal {
    param([object]$Actual, [object]$Expected, [string]$Label)
    if ($Actual -cne $Expected) {
        throw "$Label differs"
    }
}

foreach ($path in @($Baseline, $Corrected, $DryRun, $ElaborationRunner)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required harness artifact missing: $path"
    }
}

$baselineSha = (Get-FileHash -LiteralPath $Baseline -Algorithm SHA256).Hash
Assert-Equal $baselineSha $ExpectedBaselineSha 'Exact terminal R1h harness SHA-256'
$baselineText = [System.IO.File]::ReadAllText($Baseline)
$correctedText = [System.IO.File]::ReadAllText($Corrected)
$dryRunText = [System.IO.File]::ReadAllText($DryRun)
$elaborationText = [System.IO.File]::ReadAllText($ElaborationRunner)

# Prove the corrected full-build harness differs only inside the queried
# compile-order/semantic-gate region.  Everything before and after that region,
# including source/XDC/XCI registration, synthesis, resource gates,
# implementation, bitstream, and provenance, must be byte-identical.
$regionStart = "  set actual_compile_objects \`r`n"
$regionEnd = "  write_lines [file join `$evidence_root R1H_BUILD_PROVENANCE.txt] [list \`r`n"
if (-not $baselineText.Contains($regionStart)) {
    $regionStart = "  set actual_compile_objects \`n"
}
if (-not $baselineText.Contains($regionEnd)) {
    $regionEnd = "  write_lines [file join `$evidence_root R1H_BUILD_PROVENANCE.txt] [list \`n"
}
$baselineOutside = Remove-LiteralRegion -Text $baselineText -Start $regionStart -End $regionEnd -Replacement '<R1H_PROJECT_GATE_REGION>'
$correctedOutside = Remove-LiteralRegion -Text $correctedText -Start $regionStart -End $regionEnd -Replacement '<R1H_PROJECT_GATE_REGION>'
Assert-Equal $correctedOutside $baselineOutside 'Full-build harness outside project semantic gate'

$presenceStart = "  foreach required [concat `$vhdl_files `$sv_files] {"
$presenceEnd = "  # R1h-R2 semantic SystemVerilog gate."
$correctedPresence = Get-LiteralRegion -Text $correctedText -Start $presenceStart -End $presenceEnd
$baselinePresenceEnd = "  set top_compile_index [compile_order_index `$actual_compile_names \"
$baselinePresence = Get-LiteralRegion -Text $baselineText -Start $presenceStart -End $baselinePresenceEnd
Assert-Equal $correctedPresence.TrimEnd() $baselinePresence.TrimEnd() 'Required-source and VHDL dependency-order gate'

$sourceBlockStart = 'set sv_rel_files [list '
$sourceBlockEnd = 'set sv_files [list]'
$baselineSourceBlock = Get-LiteralRegion $baselineText $sourceBlockStart $sourceBlockEnd
$correctedSourceBlock = Get-LiteralRegion $correctedText $sourceBlockStart $sourceBlockEnd
Assert-Equal $correctedSourceBlock $baselineSourceBlock 'Source/XDC/XCI list block'
$svEntryCount = [regex]::Matches(
    (Get-LiteralRegion $correctedText 'set sv_rel_files [list ' 'set vhdl_rel_files [list '),
    '(?m)^\s+[^\s]+\.sv(?:\s+\\|\])\s*$').Count
Assert-Equal $svEntryCount 17 'Executable SystemVerilog source count'

$resourceStart = '  # Mandatory R1h post-synthesis resource gate.'
$resourceEnd = '  set build_stage OPT_DESIGN'
$baselineResource = Get-LiteralRegion $baselineText $resourceStart $resourceEnd
$correctedResource = Get-LiteralRegion $correctedText $resourceStart $resourceEnd
Assert-Equal $correctedResource $baselineResource 'Post-synthesis BRAM/resource gate'

$buildCommandPattern = '(?m)^\s*(synth_design|opt_design|place_design|phys_opt_design|route_design|write_checkpoint|write_bitstream)\b.*$'
$baselineBuildCommands = [regex]::Matches($baselineText, $buildCommandPattern) | ForEach-Object { $_.Value.Trim() }
$correctedBuildCommands = [regex]::Matches($correctedText, $buildCommandPattern) | ForEach-Object { $_.Value.Trim() }
Assert-Equal ($correctedBuildCommands -join "`n") ($baselineBuildCommands -join "`n") 'Synthesis/implementation command sequence'

$projectCommandPattern = '(?m)^\s*(create_project|config_ip_cache|add_files|import_ip|generate_target|update_compile_order)\b.*$'
$baselineProjectCommands = [regex]::Matches($baselineText, $projectCommandPattern) | ForEach-Object { $_.Value.Trim() }
$correctedProjectCommands = [regex]::Matches($correctedText, $projectCommandPattern) | ForEach-Object { $_.Value.Trim() }
Assert-Equal ($correctedProjectCommands -join "`n") ($baselineProjectCommands -join "`n") 'Full-build project-setup command sequence'

foreach ($forbidden in @(
    'R1h probe-index BRAM wrapper is not before its probe consumer',
    'R1h SystemVerilog dependency is not before the queried top compile unit',
    'top_compile_index',
    'index_store_compile_index',
    'probe_compile_index',
    'reorder_files'
)) {
    if ($correctedText.Contains($forbidden)) {
        throw "Corrected harness retains forbidden relative-order gate token: $forbidden"
    }
}

foreach ($requiredSemanticToken in @(
    'report_compile_order -fileset sources_1 -used_in synthesis',
    'RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO',
    'DUPLICATE_DEFINITIONS=0',
    'UNRESOLVED_INCLUDE_OR_PACKAGE_DEPENDENCIES=0',
    'FAILED_RECORD_BRAM_BANK_COUNT=$failed_record_bram_bank_count',
    'PROBE_INDEX_BRAM_INSTANCE_COUNT=$probe_index_bram_instance_count',
    'R1H_RECORD_PAYLOAD_RAM',
    'INDEX_PAYLOAD_RAM'
)) {
    if (-not $correctedText.Contains($requiredSemanticToken)) {
        throw "Corrected harness lacks required semantic-gate token: $requiredSemanticToken"
    }
}
Assert-Equal ([regex]::Matches($correctedText, '(?m)^\s*report_compile_order\b').Count) 1 'Full-build report_compile_order invocation count'

$forbiddenDryRunPattern = '(?m)^\s*(synth_design|opt_design|place_design|phys_opt_design|route_design|write_checkpoint|write_bitstream)\b'
Assert-Equal ([regex]::Matches($dryRunText, $forbiddenDryRunPattern).Count) 0 'Dry-run forbidden build-command count'
Assert-Equal ([regex]::Matches($dryRunText, '(?m)^\s*report_compile_order\b').Count) 1 'Dry-run report_compile_order invocation count'
Assert-Equal ([regex]::Matches($dryRunText, '(?m)^\s+rtl/.+\.sv(?:\s+\\|\])\s*$').Count) 17 'Dry-run executable SystemVerilog source count'
if ($dryRunText.Contains('reorder_files') -or
    $dryRunText.Contains('R1h probe-index BRAM wrapper is not before its probe consumer')) {
    throw 'Dry-run contains a forbidden manual/relative-order workaround.'
}
$dryRunCloseIndex = $dryRunText.IndexOf('  close_project', [StringComparison]::Ordinal)
$dryRunPassReceiptIndex = $dryRunText.IndexOf(
    '    R1H_R2_PROJECT_SETUP_DRY_RUN_RESULT.txt] $gate_lines',
    [StringComparison]::Ordinal)
if ($dryRunCloseIndex -lt 0 -or $dryRunPassReceiptIndex -lt 0 -or
    $dryRunCloseIndex -ge $dryRunPassReceiptIndex) {
    throw 'Dry-run PASS receipt is not fail-closed after close_project.'
}

$forbiddenElaborationPattern = '(?m)^\s*(synth_design|opt_design|place_design|phys_opt_design|route_design|write_checkpoint|write_bitstream)\b'
Assert-Equal ([regex]::Matches($elaborationText, $forbiddenElaborationPattern).Count) 0 'Semantic preflight forbidden build-command count'
foreach ($toolName in @('Xvhdl', 'Xvlog', 'Xelab')) {
    $toolVariablePattern = [regex]::Escape('$' + $toolName)
    Assert-Equal ([regex]::Matches(
        $elaborationText,
        "(?m)^\s*Invoke-CapturedTool\s+-Tool\s+$toolVariablePattern\b").Count) 1 "$toolName invocation count"
}

$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $ElaborationRunner, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
    throw ('PowerShell parser rejected semantic runner: ' + (($parseErrors | ForEach-Object Message) -join '; '))
}
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $PSCommandPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -ne 0) {
    throw ('PowerShell parser rejected static audit: ' + (($parseErrors | ForEach-Object Message) -join '; '))
}

$gitPatch = @(& git diff --no-index --no-color --src-prefix='R1h/' --dst-prefix='R1h-R2/' -- $Baseline $Corrected 2>&1)
$diffExit = $LASTEXITCODE
if ($diffExit -ne 1) {
    throw "git diff --no-index returned $diffExit; expected 1 for the one harness delta"
}
$cleanPatch = @($gitPatch | ForEach-Object { $_.ToString() } | Where-Object {
    $_ -notmatch '^warning: in the working copy of '
})
if ($cleanPatch.Count -eq 0 -or $cleanPatch[0] -notmatch '^diff --git ') {
    throw 'clean harness patch does not begin with diff --git'
}
Write-Utf8Lines -Path $PatchPath -Lines $cleanPatch

$rows = @(
    'contract,baseline,r1h_r2,delta,result,evidence',
    'FULL_HARNESS_OUTSIDE_SEMANTIC_GATE,exact R1h,byte-identical,0,PASS,whole-file region substitution comparison',
    'SYNTHESIS_IMPLEMENTATION_COMMAND_DELTA,exact R1h,exact R1h,0,PASS,ordered invocation comparison',
    'SOURCE_LIST_DELTA,17 SV + 4 VHDL,17 SV + 4 VHDL,0,PASS,exact source block comparison',
    'CONSTRAINT_DELTA,7 XDC,7 XDC,0,PASS,exact source block comparison',
    'XCI_DELTA,ip/v41/xdma_v41_m1.xci,ip/v41/xdma_v41_m1.xci,0,PASS,exact source block comparison',
    'PART_TOP_DELTA,xc7a35tcsg325-2 / ahd_capture_top_xdma,same,0,PASS,full harness outside gate byte-identical',
    'RESOURCE_GATE_DELTA,exact R1h,byte-identical,0,PASS,exact resource block comparison',
    'SCIENTIFIC_PARAMETER_DELTA,exact R1h,byte-identical,0,PASS,full harness outside gate byte-identical',
    'RELATIVE_SYSTEMVERILOG_POSITION_GATE,present,removed,removed,PASS,old SV-relative tokens absent',
    'VHDL_DEPENDENCY_ORDER_GATE,present,preserved,0,PASS,exact VHDL gate comparison',
    'REPORT_COMPILE_ORDER_EVIDENCE,absent,present,+1 evidence command,PASS,one invocation; never an SV relative-order gate',
    'PROJECT_SETUP_DRY_RUN_FORBIDDEN_BUILD_COMMANDS,not applicable,0,0,PASS,anchored command scan',
    'PROJECT_SETUP_DRY_RUN_CLOSE_BEFORE_PASS,not applicable,close_project precedes PASS receipt,0,PASS,ordinal source-position audit',
    'SEMANTIC_PREFLIGHT_FORBIDDEN_BUILD_COMMANDS,not applicable,0,0,PASS,anchored command scan'
)
Write-Utf8Lines -Path $CsvPath -Lines $rows

$correctedSha = (Get-FileHash -LiteralPath $Corrected -Algorithm SHA256).Hash
$dryRunSha = (Get-FileHash -LiteralPath $DryRun -Algorithm SHA256).Hash
$elaborationSha = (Get-FileHash -LiteralPath $ElaborationRunner -Algorithm SHA256).Hash
$patchSha = (Get-FileHash -LiteralPath $PatchPath -Algorithm SHA256).Hash
$csvSha = (Get-FileHash -LiteralPath $CsvPath -Algorithm SHA256).Hash
Write-Utf8Lines -Path $HashPath -Lines @(
    "$baselineSha  R1H_BASELINE_BUILD_TCL",
    "$correctedSha  R1H_R2_CORRECTED_BUILD_TCL",
    "$dryRunSha  R1H_R2_PROJECT_SETUP_DRY_RUN_TCL",
    "$elaborationSha  R1H_R2_SEMANTIC_ELABORATION_RUNNER",
    "$patchSha  R1H_TO_R1H_R2_HARNESS_PATCH",
    "$csvSha  BUILD_COMMAND_RECONCILIATION"
)

Write-Utf8Lines -Path $AuditPath -Lines @(
    'TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION',
    'R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c',
    'R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b',
    "R1H_BASELINE_BUILD_TCL_SHA256=$baselineSha",
    "R1H_R2_CORRECTED_BUILD_TCL_SHA256=$correctedSha",
    "R1H_R2_PROJECT_SETUP_DRY_RUN_TCL_SHA256=$dryRunSha",
    "R1H_R2_SEMANTIC_ELABORATION_RUNNER_SHA256=$elaborationSha",
    'R1H_R2_BUILD_HARNESS_CORRECTION_MODE=TASK_LOCAL_ZERO_REPOSITORY_MUTATION',
    'FPGA_RTL_SOURCE_CHANGES=0',
    'TRACKED_BUILD_HARNESS_COMMITS=0',
    'EXECUTABLE_SYSTEMVERILOG_SOURCE_COUNT=17',
    'VHDL_SOURCE_COUNT=4',
    'XDC_SOURCE_COUNT=7',
    'XCI_SOURCE_COUNT=1',
    'RELATIVE_SOURCE_POSITION_ASSERTION=REMOVED_OR_DISABLED',
    'RELATIVE_SOURCE_POSITION_USED_AS_GATE=NO',
    'VHDL_DEPENDENCY_ORDER_GATE=PRESERVED',
    'REPORT_COMPILE_ORDER_RECORDED=YES',
    'BUILD_COMMAND_SEMANTICS_CHANGED=NO',
    'SYNTHESIS_IMPLEMENTATION_COMMAND_DELTA=0',
    'SOURCE_LIST_DELTA=0',
    'CONSTRAINT_DELTA=0',
    'XCI_DELTA=0',
    'PART_TOP_DELTA=0',
    'RESOURCE_GATE_DELTA=0',
    'SCIENTIFIC_PARAMETER_DELTA=0',
    'PROJECT_SETUP_DRY_RUN_FORBIDDEN_BUILD_COMMAND_INVOCATIONS=0',
    'PROJECT_SETUP_DRY_RUN_CLOSE_BEFORE_PASS_RECEIPT=YES',
    'SEMANTIC_PREFLIGHT_FORBIDDEN_BUILD_COMMAND_INVOCATIONS=0',
    'POWERSHELL_PARSER=PASS',
    'STATIC_HARNESS_AUDIT=PASS',
    'VIVADO_INVOKED_BY_STATIC_AUDIT=NO'
)

Write-Output 'R1H_R2_HARNESS_STATIC_AUDIT=PASS'
