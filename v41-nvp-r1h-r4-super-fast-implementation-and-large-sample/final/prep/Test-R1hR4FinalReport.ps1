[CmdletBinding()]
param(
    [string]$ReportPath = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\final\V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

Require (Test-Path -LiteralPath $ReportPath -PathType Leaf) 'Authoritative report is absent'
$text = Get-Content -LiteralPath $ReportPath -Raw
$taskMarker = "TASK=`r?`n\s+V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE"
$matches = [regex]::Matches($text, $taskMarker)
Require ($matches.Count -ge 1) 'Required terminal TASK marker is absent'
$blockStart = $matches[$matches.Count - 1].Index
$blockAndTail = $text.Substring($blockStart)
Require ($blockAndTail -match '(?s)NEXT_ACTION=\s*\r?\n\s*OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT\s*(?:```)?\s*\z') 'Required block is not terminal'
$block = [regex]::Match($blockAndTail, '(?s)\ATASK=.*?OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT').Value

$requiredKeys = @(
    'TASK','EXPERIMENT_NAME','CONTINUATION_REVISION','SUPER_FAST_OWNER_RISK_ACCEPTED',
    'SOURCE_FILE_MUTATIONS','SOURCE_COMMITS','SYNTH_DESIGN_INVOCATIONS_THIS_TASK',
    'R1H_SOURCE_COMMIT','R1H_SOURCE_TREE','R1H_SYNTH_DCP_SHA256',
    'RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE','OPT_DESIGN_INVOCATIONS',
    'POST_OPT_SLICE_LUTS','POST_OPT_SLICE_REGISTERS','POST_OPT_RESOURCE_CLASS',
    'PLACE','ROUTE','ROUTE_ERRORS','UNROUTED_NETS','WNS','WHS',
    'FINAL_SLICE_LUTS','FINAL_SLICE_REGISTERS','FINAL_RESOURCE_CLASS',
    'R1H_BIT_SHA256','R1H_ROUTED_DCP_SHA256','SOURCE_COMMIT_TO_BIT_PROVENANCE',
    'DIAGNOSTIC_ONLY_IMAGE','PRODUCTION_ACCEPTANCE_CLAIM','PAIR_COUNT_VALID',
    'A1_PROBE_WADDR_NACKS','A1_PROBE_REGADDR_NACKS','A1_PROBE_DATA_NACKS',
    'A1_AUTOINIT_WADDR_NACKS','A1_AUTOINIT_REGADDR_NACKS','A1_AUTOINIT_DATA_NACKS',
    'A1_FAILED_TXN_TOTAL','A1_NVP_RESULT','B1_NACK_COUNT','B1_NVP_RESULT',
    'A2_PROBE_WADDR_NACKS','A2_PROBE_REGADDR_NACKS','A2_PROBE_DATA_NACKS',
    'A2_AUTOINIT_WADDR_NACKS','A2_AUTOINIT_REGADDR_NACKS','A2_AUTOINIT_DATA_NACKS',
    'A2_FAILED_TXN_TOTAL','A2_NVP_RESULT','B2_NACK_COUNT','B2_NVP_RESULT',
    'A3_PROBE_WADDR_NACKS','A3_PROBE_REGADDR_NACKS','A3_PROBE_DATA_NACKS',
    'A3_AUTOINIT_WADDR_NACKS','A3_AUTOINIT_REGADDR_NACKS','A3_AUTOINIT_DATA_NACKS',
    'A3_FAILED_TXN_TOTAL','A3_NVP_RESULT','B3_NACK_COUNT','B3_NVP_RESULT',
    'POSTINIT_WADDR_PROCESS','POSTINIT_REGADDR_PROCESS','POSTINIT_DATA_PROCESS',
    'AUTOINIT_PHASE_RATE_HETEROGENEITY','AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR',
    'AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR','AUTOINIT_CONTEXT_RATE_ELEVATION_DATA',
    'R1H_REPLICATE_HOMOGENEITY','BANK_TRACKER_COHERENCE',
    'FAILED_TRANSACTION_DISTRIBUTION','PAIRED_AB_RESULT','GLOBAL_PROGRAM_RETRY_BUDGET',
    'GLOBAL_PROGRAM_RETRIES_USED','HOST_ONLY_CORRECTION_CYCLES_USED',
    'FPGA_PROGRAM_INVOCATIONS','WARM_REBOOTS','DRIVER_LOADS','AXI_LITE_WRITES',
    'DMA_TRANSFERS','PHYSICAL_ACTIONS','FINAL_ACTIVE_IMAGE','FINAL_FORMAL_IDENTITY',
    'FINAL_DIAGNOSTIC_MAGIC','FINAL_PINNED_DRIVER_LOADED','FINAL_DONE',
    'ROOT_CAUSE_SOLELY_PROVEN','EVIDENCE_PACKAGE_SHA256','EVIDENCE_REPOSITORY_COMMIT',
    'PUBLICATION_RESULT','NEXT_ACTION'
)

$values = @{}
$observedKeys = @([regex]::Matches($block, '(?m)^([A-Z][A-Z0-9_]+)=\s*$') | ForEach-Object { $_.Groups[1].Value })
Require ($observedKeys.Count -eq $requiredKeys.Count) "Terminal key count is $($observedKeys.Count), expected $($requiredKeys.Count)"
for ($keyIndex = 0; $keyIndex -lt $requiredKeys.Count; $keyIndex++) {
    Require ($observedKeys[$keyIndex] -ceq $requiredKeys[$keyIndex]) "Terminal key sequence mismatch at index ${keyIndex}: $($observedKeys[$keyIndex]) != $($requiredKeys[$keyIndex])"
}
foreach ($key in $requiredKeys) {
    $keyMatches = [regex]::Matches($block, "(?m)^$([regex]::Escape($key))=\s*\r?`n[ \t]+([^\r\n]+)\s*$")
    Require ($keyMatches.Count -eq 1) "Terminal field $key count/value format failure: $($keyMatches.Count)"
    $value = $keyMatches[0].Groups[1].Value.Trim()
    Require (-not [string]::IsNullOrWhiteSpace($value)) "Terminal field $key is empty"
    Require ($value -cne '<REQUIRED_VALUE>') "Terminal field $key still contains a schema placeholder"
    $values[$key] = $value
}

$constants = @{
    TASK = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE'
    EXPERIMENT_NAME = 'R1h'
    CONTINUATION_REVISION = 'R4'
    SUPER_FAST_OWNER_RISK_ACCEPTED = 'YES'
    SOURCE_FILE_MUTATIONS = '0'
    SOURCE_COMMITS = '0'
    SYNTH_DESIGN_INVOCATIONS_THIS_TASK = '0'
    R1H_SOURCE_COMMIT = 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
    R1H_SOURCE_TREE = '161e561f007912d73dba93c5ecd78e3cc3a6955b'
    R1H_SYNTH_DCP_SHA256 = '807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E'
    RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE = 'NO'
    OPT_DESIGN_INVOCATIONS = '1'
    PLACE = 'PASS'
    ROUTE = 'PASS'
    ROUTE_ERRORS = '0'
    UNROUTED_NETS = '0'
    DIAGNOSTIC_ONLY_IMAGE = 'YES'
    PRODUCTION_ACCEPTANCE_CLAIM = 'NO'
    GLOBAL_PROGRAM_RETRY_BUDGET = '1'
    AXI_LITE_WRITES = '0'
    DMA_TRANSFERS = '0'
    PHYSICAL_ACTIONS = '0'
    FINAL_ACTIVE_IMAGE = 'FORMAL_PHASE2'
    FINAL_FORMAL_IDENTITY = 'A40A0C07 / 0000400B / 00031002'
    FINAL_DIAGNOSTIC_MAGIC = '0'
    FINAL_PINNED_DRIVER_LOADED = 'YES'
    FINAL_DONE = '1'
    ROOT_CAUSE_SOLELY_PROVEN = 'NO'
    NEXT_ACTION = 'OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT'
}
foreach ($key in $constants.Keys) {
    Require ($values[$key] -ceq $constants[$key]) "$key mismatch: '$($values[$key])'"
}

foreach ($key in @('POST_OPT_SLICE_LUTS','POST_OPT_SLICE_REGISTERS','FINAL_SLICE_LUTS','FINAL_SLICE_REGISTERS','PAIR_COUNT_VALID','GLOBAL_PROGRAM_RETRIES_USED','HOST_ONLY_CORRECTION_CYCLES_USED','FPGA_PROGRAM_INVOCATIONS','WARM_REBOOTS','DRIVER_LOADS')) {
    Require ($values[$key] -match '^\d+$') "$key is not a nonnegative integer"
}
Require ([int]$values['POST_OPT_SLICE_LUTS'] -le 19760) 'POST_OPT_SLICE_LUTS exceeds R4 limit'
Require ([int]$values['POST_OPT_SLICE_REGISTERS'] -le 37440) 'POST_OPT_SLICE_REGISTERS exceeds R4 limit'
Require ([int]$values['FINAL_SLICE_LUTS'] -le 19760) 'FINAL_SLICE_LUTS exceeds R4 limit'
Require ([int]$values['FINAL_SLICE_REGISTERS'] -le 37440) 'FINAL_SLICE_REGISTERS exceeds R4 limit'
Require ([int]$values['PAIR_COUNT_VALID'] -eq 3) 'PAIR_COUNT_VALID is not three'
$parsedWns = 0.0
$parsedWhs = 0.0
Require ([double]::TryParse($values.WNS, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsedWns)) 'WNS is not numeric'
Require ([double]::TryParse($values.WHS, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$parsedWhs)) 'WHS is not numeric'
Require ($parsedWns -ge 0.0) 'WNS is negative'
Require ($parsedWhs -gt 0.0) 'WHS is not positive'
foreach ($key in @('R1H_BIT_SHA256','R1H_ROUTED_DCP_SHA256')) {
    Require ($values[$key] -match '^[0-9A-F]{64}$') "$key is not an uppercase SHA-256"
}
Require ($values['SOURCE_COMMIT_TO_BIT_PROVENANCE'] -ceq 'PASS_BY_EXACT_SHA_BOUND_DCP') 'SOURCE_COMMIT_TO_BIT_PROVENANCE mismatch'
Require ($values['POST_OPT_RESOURCE_CLASS'] -match '^PASS_(STANDARD_MARGIN|DIAGNOSTIC_ONLY_5_TO_10_PERCENT_MARGIN)$') 'POST_OPT_RESOURCE_CLASS is invalid'
Require ($values['FINAL_RESOURCE_CLASS'] -match '^PASS_(STANDARD_MARGIN|DIAGNOSTIC_ONLY_5_TO_10_PERCENT_MARGIN)$') 'FINAL_RESOURCE_CLASS is invalid'
Require ($values['EVIDENCE_PACKAGE_SHA256'] -match '^[0-9A-F]{64}$|^SEE_EXTERNAL_PACKAGE_SHA256_SIDECAR_NONCIRCULAR$') 'EVIDENCE_PACKAGE_SHA256 is neither a digest nor the approved noncircular sentinel'
Require ($values['EVIDENCE_REPOSITORY_COMMIT'] -match '^[0-9a-f]{40}$|^SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR$') 'EVIDENCE_REPOSITORY_COMMIT is neither a commit nor the approved noncircular sentinel'
Require ($values['PUBLICATION_RESULT'] -match '^(PASS|BLOCKED_[A-Z0-9_]+|SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR)$') 'PUBLICATION_RESULT classification is invalid'

Write-Output 'FINAL_REPORT_AUDIT=PASS'
Write-Output "FINAL_REPORT_SHA256=$((Get-FileHash -LiteralPath $ReportPath -Algorithm SHA256).Hash.ToUpperInvariant())"
Write-Output "REQUIRED_TERMINAL_FIELDS=$($requiredKeys.Count)"
Write-Output 'TERMINAL_BLOCK_IS_LAST=YES'
Write-Output 'EMPTY_REQUIRED_VALUES=0'
Write-Output 'SCHEMA_PLACEHOLDERS=0'
