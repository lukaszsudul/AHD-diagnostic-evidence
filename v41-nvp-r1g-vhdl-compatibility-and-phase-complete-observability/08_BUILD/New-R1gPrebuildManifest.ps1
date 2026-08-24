[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryRoot,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$R1gCommit,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9a-f]{40}$')]
    [string]$R1gTree,

    [Parameter(Mandatory = $true)]
    [string]$SourceIdentityReceipt,

    [Parameter(Mandatory = $true)]
    [string]$CrossStandardEquivalenceReceipt,

    [Parameter(Mandatory = $true)]
    [string]$FinalPreflightEvidenceRoot,

    [Parameter(Mandatory = $true)]
    [string]$FinalPreflightPassLog,

    [Parameter(Mandatory = $true)]
    [switch]$FinalizeAfterCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
$BuildRoot = Join-Path $TaskRoot '08_BUILD'
$OutputManifest = Join-Path $BuildRoot 'R1G_PREBUILD_MANIFEST.txt'
$OutputHash = Join-Path $BuildRoot 'R1G_PREBUILD_MANIFEST_SHA256.txt'
$OutputVerification = Join-Path $BuildRoot 'R1G_PREBUILD_MANIFEST_VERIFICATION.txt'

$ExactR1eCommit = 'f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd'
$ExactR1fCommit = '225544084dbfcaadb8592fcecc947aa1cec4970e'
$ExactR1fTree = 'cfde8769af95cf20586391c411fab3ddfa2c87b6'
$ExpectedBranch = 'diag/v41-nvp-r1g-vhdl-compatibility'
$ExactR1fManifest = Join-Path $TaskRoot '00_R1F_INPUT\R1F_PREBUILD_MANIFEST.txt'
$ExactR1fManifestSha256 = '34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04'
$ExpectedR1gBringupSha256 = '66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024'
$ExpectedR1gBuildTclSha256 = 'C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A'
$ExpectedFinalPreflightTclSha256 = '98EB91E4F39ECF41E47A62CC626514F6E1B091A6F99DD0127FDA7F51E514E26F'

$LanguageContractReceipt = Join-Path $TaskRoot '02_LANGUAGE_CONTRACT\PRODUCTION_LANGUAGE_CONTRACT.md'
$StaticAuditReceipt = Join-Path $TaskRoot '03_STATIC_COMPATIBILITY_AUDIT\STATIC_AUDIT_REPORT.md'
$SourceScopeReceipt = Join-Path $TaskRoot '04_MECHANICAL_REWRITE\SOURCE_CHANGE_SCOPE.md'
$CompilerReceipt = Join-Path $TaskRoot '04_MECHANICAL_REWRITE\NON_SYNTHESIS_COMPILER_ITERATIONS\iteration_02_r1g_candidate_production_mode\ITERATION_RECEIPT.md'
$CompilerLog = Join-Path $TaskRoot '04_MECHANICAL_REWRITE\NON_SYNTHESIS_COMPILER_ITERATIONS\iteration_02_r1g_candidate_production_mode\xvhdl.log'
$FinalPreflightStaticAudit = Join-Path $TaskRoot '06_FINAL_FRONTEND_PREFLIGHT\R1G_INDEPENDENT_FINAL_PREFLIGHT_SCRIPT_AUDIT.md'
$BuildStaticAudit = Join-Path $TaskRoot '08_BUILD\R1G_INDEPENDENT_BUILD_SCRIPT_AUDIT.md'
$BuildTcl = Join-Path $TaskRoot 'scripts\r1g_build.tcl'
$FinalPreflightTcl = Join-Path $TaskRoot 'scripts\r1g_final_rtl_elaboration_preflight.tcl'
$HostToolGate = Join-Path $TaskRoot '09_HOST_TOOLS\R1G_HOST_TOOL_GATE.md'
$HostInheritedFixtures = Join-Path $TaskRoot '09_HOST_TOOLS\R1G_INHERITED_R1F_HOST_FIXTURES.log'
$HostAdditionalFixtures = Join-Path $TaskRoot '09_HOST_TOOLS\R1G_ADDITIONAL_HOST_FIXTURES.log'
$HostToolingManifest = Join-Path $TaskRoot '09_HOST_TOOLS\R1G_HOST_AND_CAMPAIGN_TOOLING_SHA256.txt'

function Get-CanonicalPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
}

function Assert-PathWithin {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Parent
    )
    $canonicalPath = Get-CanonicalPath -Path $Path
    $canonicalParent = Get-CanonicalPath -Path $Parent
    $prefix = $canonicalParent + [System.IO.Path]::DirectorySeparatorChar
    if (-not $canonicalPath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Path '$canonicalPath' is outside required evidence root '$canonicalParent'"
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file is missing: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Assert-ExactSha256 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Expected
    )
    $actual = Get-Sha256 -Path $Path
    if ($actual -cne $Expected) {
        throw "SHA-256 mismatch for ${Path}: expected $Expected, got $actual"
    }
}

function Assert-LiteralLine {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Line
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required receipt is missing: $Path"
    }
    $text = [System.IO.File]::ReadAllText((Get-CanonicalPath -Path $Path))
    $pattern = '(?m)^\s*' + [regex]::Escape($Line) + '\s*$'
    if (-not [regex]::IsMatch($text, $pattern)) {
        throw "Receipt '$Path' does not contain the exact required line '$Line'"
    }
}

function Assert-LiteralLines {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Lines
    )
    foreach ($line in $Lines) {
        Assert-LiteralLine -Path $Path -Line $line
    }
}

function Invoke-GitText {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $output = & git -C $RepositoryRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed: git -C '$RepositoryRoot' $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return (($output -join "`n").Trim())
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Text
    )
    $encoding = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Path, $Text, $encoding)
}

if (-not $FinalizeAfterCommit.IsPresent) {
    throw 'Fail closed: -FinalizeAfterCommit must be supplied explicitly after the exact R1g commit and the sole final-preflight PASS exist.'
}

$RepositoryRoot = Get-CanonicalPath -Path $RepositoryRoot
$SourceIdentityReceipt = Get-CanonicalPath -Path $SourceIdentityReceipt
$CrossStandardEquivalenceReceipt = Get-CanonicalPath -Path $CrossStandardEquivalenceReceipt
$FinalPreflightEvidenceRoot = Get-CanonicalPath -Path $FinalPreflightEvidenceRoot
$FinalPreflightPassLog = Get-CanonicalPath -Path $FinalPreflightPassLog

Assert-PathWithin -Path $SourceIdentityReceipt -Parent (Join-Path $TaskRoot '07_R1G_SOURCE_IDENTITY')
Assert-PathWithin -Path $CrossStandardEquivalenceReceipt -Parent (Join-Path $TaskRoot '05_CROSS_STANDARD_EQUIVALENCE')
Assert-PathWithin -Path $FinalPreflightEvidenceRoot -Parent (Join-Path $TaskRoot '06_FINAL_FRONTEND_PREFLIGHT')
Assert-PathWithin -Path $FinalPreflightPassLog -Parent $FinalPreflightEvidenceRoot

if (-not (Test-Path -LiteralPath $RepositoryRoot -PathType Container)) {
    throw "Repository root is missing: $RepositoryRoot"
}
if (-not (Test-Path -LiteralPath $FinalPreflightEvidenceRoot -PathType Container)) {
    throw "Final-preflight evidence root is missing: $FinalPreflightEvidenceRoot"
}
foreach ($reservedOutput in @($OutputManifest, $OutputHash, $OutputVerification)) {
    if (Test-Path -LiteralPath $reservedOutput) {
        throw "Refusing to overwrite an existing finalized prebuild output: $reservedOutput"
    }
}

Assert-ExactSha256 -Path $ExactR1fManifest -Expected $ExactR1fManifestSha256
Assert-ExactSha256 -Path $BuildTcl -Expected $ExpectedR1gBuildTclSha256
Assert-ExactSha256 -Path $FinalPreflightTcl -Expected $ExpectedFinalPreflightTclSha256

$gitTop = Get-CanonicalPath -Path (Invoke-GitText -Arguments @('rev-parse', '--show-toplevel'))
if (-not [string]::Equals($gitTop, $RepositoryRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "RepositoryRoot must be the exact Git top: expected '$RepositoryRoot', got '$gitTop'"
}
$actualCommit = (Invoke-GitText -Arguments @('rev-parse', 'HEAD')).ToLowerInvariant()
$actualTree = (Invoke-GitText -Arguments @('rev-parse', 'HEAD^{tree}')).ToLowerInvariant()
$actualBranch = Invoke-GitText -Arguments @('symbolic-ref', '--short', 'HEAD')
$actualParent = (Invoke-GitText -Arguments @('rev-parse', 'HEAD^')).ToLowerInvariant()
$r1fTree = (Invoke-GitText -Arguments @('rev-parse', "$ExactR1fCommit^{tree}")).ToLowerInvariant()
$commitsAboveR1f = Invoke-GitText -Arguments @('rev-list', '--count', "$ExactR1fCommit..$R1gCommit")
$status = Invoke-GitText -Arguments @('status', '--porcelain=v1', '--untracked-files=all')

if ($actualCommit -cne $R1gCommit) { throw "HEAD mismatch: expected $R1gCommit, got $actualCommit" }
if ($actualTree -cne $R1gTree) { throw "tree mismatch: expected $R1gTree, got $actualTree" }
if ($actualBranch -cne $ExpectedBranch) { throw "branch mismatch: expected $ExpectedBranch, got $actualBranch" }
if ($actualParent -cne $ExactR1fCommit) { throw "R1g is not a direct child of exact R1f: parent is $actualParent" }
if ($r1fTree -cne $ExactR1fTree) { throw "exact R1f parent tree mismatch: $r1fTree" }
if ($commitsAboveR1f -cne '1') { throw "R1g commits above exact R1f must equal 1, got $commitsAboveR1f" }
if ($status -ne '') { throw "R1g source worktree must be fully clean before manifest generation:`n$status" }

$changedFromR1f = @(
    (Invoke-GitText -Arguments @('diff', '--name-only', '--diff-filter=ACMRTUXB', $ExactR1fCommit, $R1gCommit)) -split "`r?`n" |
        Where-Object { $_ -ne '' }
)
if ($changedFromR1f.Count -ne 1 -or $changedFromR1f[0] -cne 'rtl/nvp/nvp6134c_i2c_bringup.vhd') {
    throw "R1f-to-R1g tracked diff must contain only rtl/nvp/nvp6134c_i2c_bringup.vhd; got: $($changedFromR1f -join ',')"
}

Assert-LiteralLines -Path $LanguageContractReceipt -Lines @(
    'PRODUCTION_LANGUAGE_CONTRACT_GATE=PASS',
    'R1G_PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008',
    'R1G_PRODUCTION_VHDL_STANDARD_EXACTLY_EQUAL_TO_R1F=YES',
    'GLOBAL_VHDL_STANDARD_CHANGE=NO',
    'FILE_TYPE_VHDL2008_CHANGES=0',
    'READ_VHDL_VHDL2008_OPTION_ADDED=NO',
    'PRODUCTION_LANGUAGE_CONTRACT_AMBIGUOUS=NO'
)
Assert-LiteralLines -Path $StaticAuditReceipt -Lines @(
    'VHDL2008_PRODUCTION_OCCURRENCES=1',
    'R1G_COMPATIBILITY_REWRITE_COUNT=1',
    'R1G_COMPATIBILITY_REWRITE_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd',
    'UNCLASSIFIED_CHANGED_VHDL_CONSTRUCTS=0',
    'UNCERTAIN_PRODUCTION_COMPATIBILITY_CANDIDATES=0',
    'GLOBAL_VHDL_STANDARD_CHANGE_REQUIRED=NO',
    'FILE_TYPE_VHDL2008_CHANGE_REQUIRED=NO',
    'R1G_STATIC_COMPATIBILITY_AUDIT=PASS'
)
Assert-LiteralLines -Path $SourceScopeReceipt -Lines @(
    'R1G_COMPATIBILITY_REWRITE_COUNT=1',
    'R1G_COMPATIBILITY_REWRITE_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd',
    'R1G_SOURCE_CHANGE_CLASS=VHDL_LANGUAGE_COMPATIBILITY_ONLY',
    'R1G_FUNCTIONAL_RTL_CHANGE=NO',
    'R1G_DIAGNOSTIC_SEMANTICS_CHANGE=NO',
    'R1G_SCIENTIFIC_PARAMETER_CHANGE=NO',
    'GLOBAL_VHDL_STANDARD_CHANGE=NO',
    'FILE_TYPE_VHDL2008_CHANGES=0',
    'READ_VHDL_VHDL2008_OPTION_ADDED=NO',
    "R1G_CANDIDATE_BRINGUP_SHA256=$ExpectedR1gBringupSha256",
    'CHANGED_FILES=1'
)
Assert-LiteralLines -Path $CompilerReceipt -Lines @(
    'ITERATION=2',
    'SOURCE_ROLE=R1G_MECHANICAL_REWRITE_CANDIDATE',
    "SOURCE_PARENT_COMMIT=$ExactR1fCommit",
    "SOURCE_PARENT_TREE=$ExactR1fTree",
    "BRINGUP_SHA256=$ExpectedR1gBringupSha256",
    'PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008',
    'VHDL2008_OPTION_USED=NO',
    'RELAX_OPTION_USED=NO',
    'SYNTH_DESIGN_INVOKED=NO',
    'PROCESS_EXIT_CODE=0',
    'RESULT=PASS_ALL_FILES',
    'UNRESOLVED_VHDL2008_CONSTRUCTS=0',
    'SOURCE_MUTATIONS_DURING_ITERATION=0'
)
Assert-LiteralLines -Path $CrossStandardEquivalenceReceipt -Lines @(
    'R1F_VHDL2008_REFERENCE_SIMULATION=PASS',
    'R1G_PRODUCTION_STANDARD_SIMULATION=PASS',
    'CYCLE_BY_CYCLE_ALL_OUTPUT_EQUIVALENCE=PASS',
    'R1F_TO_R1G_SEMANTIC_DIFFERENCES=0',
    'LEGACY_FIRST8_RECONCILIATION=PASS',
    'PRE_INIT_DONE_CYCLE_EQUIVALENCE_TO_R1E=PASS',
    'AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES',
    'AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES',
    'R1G_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0',
    'EFFECTIVE_PRE_INIT_ARBITRATION=PASS',
    'PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD=PASS',
    'FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS',
    'BANK_BEFORE_AFTER_SEMANTICS=PASS',
    'TRANSACTION_INDEX_16_UNIQUE=PASS',
    'TRI_PHASE_PROBE_SCOREBOARD=PASS',
    'SAFE_TARGET_RESTORATION=PASS',
    'R1F_LOG_64_EXACT_OVERFLOW_65=PASS',
    'INHERITED_POWER_TIMING=PASS',
    'INHERITED_D2B_SEQUENCE=PASS',
    'R1F_PRODUCTION_TIMING_MODEL=PASS'
)
Assert-LiteralLines -Path $HostToolGate -Lines @(
    'INHERITED_R1F_HOST_TOOL_FIXTURES=PASS_24_OF_24',
    'R1G_ADDITIONAL_HOST_FIXTURES=PASS_3_OF_3',
    'HOST_TOOL_HASH_GATE=PASS',
    'R1F_REGISTER_MAP=UNCHANGED',
    'R1F_RECORD_VERSION=1'
)
Assert-LiteralLines -Path $FinalPreflightStaticAudit -Lines @(
    'AUDIT_RESULT=PASS_PREPARED_SCRIPT_NOT_EXECUTED',
    "SCRIPT_SHA256=$ExpectedFinalPreflightTclSha256",
    'FINAL_PREFLIGHT_STATIC_CONTRACT=PASS',
    'EXACTLY_ONE_SYNTH_DESIGN_RTL=YES',
    'IMPLEMENTATION_OR_BITSTREAM_COMMANDS=0',
    'NO_RETRY_CONTRACT=PASS'
)
Assert-LiteralLines -Path $BuildStaticAudit -Lines @(
    'AUDIT_RESULT=PASS_PREPARED_SCRIPT_NOT_EXECUTED',
    "R1G_BUILD_TCL_SHA256=$ExpectedR1gBuildTclSha256",
    'R1F_TO_R1G_BUILD_COMMAND_DELTA=PROVEN_PROVENANCE_AND_OUTPUT_NAMING_ONLY',
    'SCIENTIFIC_OR_FUNCTIONAL_BUILD_DELTA=NONE',
    'VHDL_LANGUAGE_STANDARD_DELTA=NONE',
    'R1G_BUILD_SCRIPT_STATIC_CONTRACT=PASS',
    'EXACT_ONE_BUILD_SENTINEL=PASS',
    'NO_RETRY_CONTRACT=PASS'
)
Assert-LiteralLines -Path $SourceIdentityReceipt -Lines @(
    "R1G_PARENT_COMMIT=$ExactR1fCommit",
    'R1G_COMMITS_ABOVE_R1F=1',
    "R1G_SOURCE_COMMIT=$R1gCommit",
    "R1G_SOURCE_TREE=$R1gTree",
    'SOURCE_TREE_CLEAN=YES'
)

$FinalPreflightResult = Join-Path $FinalPreflightEvidenceRoot 'R1G_FINAL_RTL_ELABORATION_RESULT.txt'
$FinalPreflightConsumed = Join-Path $FinalPreflightEvidenceRoot 'R1G_FINAL_RTL_ELABORATION_PREFLIGHT_CONSUMED.marker'
$FinalPreflightFailure = Join-Path $FinalPreflightEvidenceRoot 'R1G_FINAL_RTL_ELABORATION_FAILURE.txt'
if (Test-Path -LiteralPath $FinalPreflightFailure) {
    throw "Fail closed: terminal final-preflight failure receipt exists: $FinalPreflightFailure"
}
Assert-LiteralLines -Path $FinalPreflightConsumed -Lines @(
    'FINAL_RTL_ELABORATION_PREFLIGHTS=1',
    "SOURCE_GIT_COMMIT=$R1gCommit",
    "SOURCE_GIT_TREE=$R1gTree",
    "SOURCE_PARENT_COMMIT=$ExactR1fCommit",
    'CONSUMED_BEFORE_CREATE_PROJECT=YES'
)
Assert-LiteralLines -Path $FinalPreflightResult -Lines @(
    'FINAL_RTL_ELABORATION_PREFLIGHTS=1',
    'FINAL_RTL_ELABORATION=PASS',
    "SOURCE_GIT_COMMIT=$R1gCommit",
    "SOURCE_GIT_TREE=$R1gTree",
    "R1G_PARENT_COMMIT=$ExactR1fCommit",
    'R1G_COMMITS_ABOVE_R1F=1',
    'PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008',
    'GLOBAL_VHDL_STANDARD_CHANGE=NO',
    'FILE_TYPE_VHDL2008_CHANGES=0',
    'READ_VHDL_VHDL2008_OPTION_ADDED=NO',
    'SYNTH_DESIGN_MODE=RTL_ELABORATION_ONLY',
    'SYNTH_8_2757_COUNT=0',
    'UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS=0',
    'TOP_ELABORATED=ahd_capture_top_xdma',
    'PART=xc7a35tcsg325-2',
    'VIVADO_VERSION=2025.2',
    'VIVADO_SW_BUILD=6299465',
    'OPT_DESIGN_INVOCATIONS=0',
    'PLACE_DESIGN_INVOCATIONS=0',
    'PHYS_OPT_DESIGN_INVOCATIONS=0',
    'ROUTE_DESIGN_INVOCATIONS=0',
    'WRITE_CHECKPOINT_INVOCATIONS=0',
    'WRITE_BITSTREAM_INVOCATIONS=0',
    'PROCESS_EXIT_CODE=0'
)
Assert-LiteralLines -Path $FinalPreflightPassLog -Lines @(
    'R1G_FINAL_RTL_ELABORATION=PASS',
    'R1G_FINAL_RTL_ELABORATION_PREFLIGHTS=1'
)

$r1fLines = [System.IO.File]::ReadAllLines($ExactR1fManifest)
$metaOrder = [System.Collections.Generic.List[string]]::new()
$sourceOrder = [System.Collections.Generic.List[string]]::new()
$r1fMeta = @{}
$r1fSourceSha = @{}
foreach ($rawLine in $r1fLines) {
    $line = $rawLine.Trim()
    if ($line -eq '' -or $line.StartsWith('#')) { continue }
    $fields = $line.Split('|')
    switch ($fields[0]) {
        'META' {
            if ($fields.Count -ne 3 -or $r1fMeta.ContainsKey($fields[1])) { throw "Invalid exact R1f META record: $line" }
            $metaOrder.Add($fields[1])
            $r1fMeta[$fields[1]] = $fields[2]
        }
        'SOURCE_SHA256' {
            if ($fields.Count -ne 3 -or $r1fSourceSha.ContainsKey($fields[1])) { throw "Invalid exact R1f source record: $line" }
            $sourceOrder.Add($fields[1])
            $r1fSourceSha[$fields[1]] = $fields[2]
        }
        'ACCEPTED_LOG_SHA256' {
            if ($fields.Count -ne 4) { throw "Invalid exact R1f accepted-log record: $line" }
        }
        default { throw "Unknown exact R1f manifest record: $line" }
    }
}
if ($metaOrder.Count -ne 28 -or $sourceOrder.Count -ne 51) {
    throw "Exact R1f manifest cardinality mismatch: META=$($metaOrder.Count), SOURCE=$($sourceOrder.Count)"
}

$requiredR1fMeta = @{
    PREBUILD_AUDIT = 'PASS'
    PRE_INIT_DONE_CYCLE_EQUIVALENCE = 'PASS'
    AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL = 'YES'
    AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL = 'YES'
    R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT = '0'
    NVP_TABLE_UNCHANGED = 'YES'
    FUNCTIONAL_FSM_UNCHANGED = 'YES'
    POR_START_WATCHDOG_UNCHANGED = 'YES'
    SDA_SCL_FILTERS_UNCHANGED = 'YES'
    NVP_XDC_UNCHANGED = 'YES'
    XDMA_XCI_UNCHANGED = 'YES'
    SAFE_DATA_PROBE_TARGET = 'PASS'
    RECORD_MAP_COLLISION = 'NONE_PROVEN'
    PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD = 'PASS'
    FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD = 'PASS'
    BANK_BEFORE_AFTER_SEMANTICS = 'PASS'
    TRANSACTION_INDEX_16_UNIQUE = 'PASS'
    LEGACY_FIRST8_RECONCILIATION = 'PASS'
    TRI_PHASE_PROBE_SCOREBOARD = 'PASS'
    SAFE_TARGET_RESTORATION = 'PASS'
    EFFECTIVE_PRE_INIT_ARBITRATION = 'PASS'
    R1F_LOG_64_EXACT_OVERFLOW_65 = 'PASS'
    INHERITED_POWER_TIMING = 'PASS'
    INHERITED_D2B_SEQUENCE = 'PASS'
    R1F_PRODUCTION_TIMING_MODEL = 'PASS'
    HOST_TOOL_FIXTURES = 'PASS_ALL'
}
foreach ($entry in $requiredR1fMeta.GetEnumerator()) {
    if (-not $r1fMeta.ContainsKey($entry.Key) -or $r1fMeta[$entry.Key] -cne $entry.Value) {
        throw "Exact R1f META baseline mismatch for $($entry.Key)"
    }
}

$manifestLines = [System.Collections.Generic.List[string]]::new()
$manifestLines.Add('# R1g exact external prebuild manifest. Generated only after the direct-child')
$manifestLines.Add('# source commit, all compatibility/equivalence/host gates, and the sole final')
$manifestLines.Add('# production-front-end RTL-elaboration preflight were frozen and hash-bound.')
foreach ($key in $metaOrder) {
    $value = $r1fMeta[$key]
    if ($key -ceq 'SOURCE_GIT_COMMIT') { $value = $R1gCommit }
    if ($key -ceq 'SOURCE_GIT_TREE') { $value = $R1gTree }
    $manifestLines.Add("META|$key|$value")
}

$r1gMeta = [ordered]@{
    R1G_PARENT_COMMIT = $ExactR1fCommit
    R1G_PARENT_TREE = $ExactR1fTree
    R1G_COMMITS_ABOVE_R1F = '1'
    R1G_SOURCE_CHANGE_CLASS = 'VHDL_LANGUAGE_COMPATIBILITY_ONLY'
    R1G_FUNCTIONAL_RTL_CHANGE = 'NO'
    R1G_DIAGNOSTIC_SEMANTICS_CHANGE = 'NO'
    R1G_SCIENTIFIC_PARAMETER_CHANGE = 'NO'
    PRODUCTION_VHDL_STANDARD = 'VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008'
    GLOBAL_VHDL_STANDARD_CHANGE = 'NO'
    FILE_TYPE_VHDL2008_CHANGES = '0'
    READ_VHDL_VHDL2008_OPTION_ADDED = 'NO'
    VHDL2008_CONSTRUCTS_FOUND = '6'
    VHDL2008_CONSTRUCTS_REWRITTEN = '1'
    R1G_COMPATIBILITY_REWRITE_FILES = 'rtl/nvp/nvp6134c_i2c_bringup.vhd'
    R1G_COMPATIBILITY_REWRITE_COUNT = '1'
    NON_SYNTHESIS_LANGUAGE_COMPILE_ITERATIONS = '2'
    EXACT_PRODUCTION_MODE_VHDL_COMPILE = 'PASS_ALL_FILES'
    UNRESOLVED_VHDL2008_CONSTRUCTS = '0'
    R1F_VHDL2008_REFERENCE_SIMULATION = 'PASS'
    R1G_PRODUCTION_STANDARD_SIMULATION = 'PASS'
    CYCLE_BY_CYCLE_ALL_OUTPUT_EQUIVALENCE = 'PASS'
    R1F_TO_R1G_SEMANTIC_DIFFERENCES = '0'
    R1G_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT = '0'
    FINAL_RTL_ELABORATION_PREFLIGHTS = '1'
    FINAL_RTL_ELABORATION = 'PASS'
    SYNTH_8_2757_COUNT = '0'
    UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS = '0'
    HOST_TOOL_HASH_GATE = 'PASS'
    R1F_REGISTER_MAP = 'UNCHANGED'
    R1F_RECORD_VERSION = '1'
    R1F_TO_R1G_BUILD_COMMAND_DELTA = 'PROVEN_PROVENANCE_AND_OUTPUT_NAMING_ONLY'
    R1G_BUILD_TCL_SHA256 = $ExpectedR1gBuildTclSha256
    R1G_PREBUILD_RELEASE = 'PASS'
}
foreach ($entry in $r1gMeta.GetEnumerator()) {
    $manifestLines.Add("META|$($entry.Key)|$($entry.Value)")
}
$manifestLines.Add('')

foreach ($relativePath in $sourceOrder) {
    $absolutePath = Join-Path $RepositoryRoot ($relativePath.Replace('/', '\'))
    $actualSha = Get-Sha256 -Path $absolutePath
    if ($relativePath -ceq 'rtl/nvp/nvp6134c_i2c_bringup.vhd') {
        if ($actualSha -cne $ExpectedR1gBringupSha256) {
            throw "R1g committed bringup SHA-256 mismatch: expected $ExpectedR1gBringupSha256, got $actualSha"
        }
    }
    elseif ($actualSha -cne $r1fSourceSha[$relativePath]) {
        throw "Source outside the sole mechanical rewrite differs from exact R1f: $relativePath"
    }
    $manifestLines.Add("SOURCE_SHA256|$relativePath|$actualSha")
}
$manifestLines.Add('')

$equivalenceLabels = @(
    'PRE_INIT_EQUIVALENCE',
    'EFFECTIVE_PRE_INIT_ARBITRATION',
    'AUTOINIT_PHASE_AND_FAILED_TXN_SCOREBOARD',
    'LEGACY_FIRST8_RECONCILIATION',
    'TRANSACTION_INDEX_16',
    'FAILED_TXN_LOGGER_64_65',
    'TRI_PHASE_PROBE_SUCCESS',
    'TRI_PHASE_PROBE_ABORT_RESTORE',
    'TRI_PHASE_PROBE_SCL_TIMEOUT',
    'TRI_PHASE_PROBE_ATTEMPT_LIMIT',
    'TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE',
    'TRI_PHASE_PROBE_INDEX_OVERFLOW',
    'TRI_PHASE_PROBE_IDLE_TIMEOUT',
    'R1F_REGISTER_MAP',
    'INHERITED_POWER_TIMING',
    'INHERITED_D2B_SEQUENCE',
    'R1F_PRODUCTION_TIMING_MODEL'
)
$acceptedLogs = [ordered]@{}
foreach ($label in $equivalenceLabels) { $acceptedLogs[$label] = $CrossStandardEquivalenceReceipt }
$acceptedLogs['TOP_INTEGRATION'] = $FinalPreflightResult
$acceptedLogs['HOST_TOOL_FIXTURES'] = $HostToolGate
$acceptedLogs['R1G_SOURCE_IDENTITY'] = $SourceIdentityReceipt
$acceptedLogs['R1G_PRODUCTION_LANGUAGE_CONTRACT'] = $LanguageContractReceipt
$acceptedLogs['R1G_STATIC_COMPATIBILITY_AUDIT'] = $StaticAuditReceipt
$acceptedLogs['R1G_MECHANICAL_REWRITE_SCOPE'] = $SourceScopeReceipt
$acceptedLogs['R1G_PRODUCTION_MODE_VHDL_COMPILE'] = $CompilerReceipt
$acceptedLogs['R1G_PRODUCTION_MODE_VHDL_COMPILE_LOG'] = $CompilerLog
$acceptedLogs['R1G_CROSS_STANDARD_EQUIVALENCE'] = $CrossStandardEquivalenceReceipt
$acceptedLogs['R1G_FINAL_PREFLIGHT_STATIC_AUDIT'] = $FinalPreflightStaticAudit
$acceptedLogs['R1G_FINAL_PREFLIGHT_RESULT'] = $FinalPreflightResult
$acceptedLogs['R1G_FINAL_PREFLIGHT_CONSUMED'] = $FinalPreflightConsumed
$acceptedLogs['R1G_FINAL_PREFLIGHT_PASS_LOG'] = $FinalPreflightPassLog
$acceptedLogs['R1G_BUILD_SCRIPT_STATIC_AUDIT'] = $BuildStaticAudit
$acceptedLogs['R1G_BUILD_TCL'] = $BuildTcl
$acceptedLogs['R1G_FINAL_PREFLIGHT_TCL'] = $FinalPreflightTcl
$acceptedLogs['R1G_HOST_TOOL_GATE'] = $HostToolGate
$acceptedLogs['R1G_HOST_INHERITED_FIXTURES'] = $HostInheritedFixtures
$acceptedLogs['R1G_HOST_ADDITIONAL_FIXTURES'] = $HostAdditionalFixtures
$acceptedLogs['R1G_HOST_TOOLING_HASH_MANIFEST'] = $HostToolingManifest

foreach ($entry in $acceptedLogs.GetEnumerator()) {
    $path = Get-CanonicalPath -Path ([string]$entry.Value)
    $sha = Get-Sha256 -Path $path
    if ($path.Contains('|')) { throw "Accepted-log path contains forbidden manifest delimiter: $path" }
    $manifestLines.Add("ACCEPTED_LOG_SHA256|$($entry.Key)|$path|$sha")
}

$manifestText = ($manifestLines -join "`n") + "`n"
$temporaryManifest = Join-Path $BuildRoot ('.R1G_PREBUILD_MANIFEST.' + [guid]::NewGuid().ToString('N') + '.tmp')
$temporaryHash = Join-Path $BuildRoot ('.R1G_PREBUILD_MANIFEST_SHA256.' + [guid]::NewGuid().ToString('N') + '.tmp')
$temporaryVerification = Join-Path $BuildRoot ('.R1G_PREBUILD_MANIFEST_VERIFICATION.' + [guid]::NewGuid().ToString('N') + '.tmp')
$publishedOutputs = [System.Collections.Generic.List[string]]::new()
try {
    Write-Utf8NoBom -Path $temporaryManifest -Text $manifestText
    $manifestSha = Get-Sha256 -Path $temporaryManifest
    Write-Utf8NoBom -Path $temporaryHash -Text ("$manifestSha  R1G_PREBUILD_MANIFEST.txt`n")
    $verification = @(
        'R1G_PREBUILD_MANIFEST_VERIFICATION=PASS',
        "R1G_PREBUILD_MANIFEST=$OutputManifest",
        "R1G_PREBUILD_MANIFEST_SHA256=$manifestSha",
        "SOURCE_GIT_COMMIT=$R1gCommit",
        "SOURCE_GIT_TREE=$R1gTree",
        "R1G_PARENT_COMMIT=$ExactR1fCommit",
        'R1G_COMMITS_ABOVE_R1F=1',
        "SOURCE_RECORDS=$($sourceOrder.Count)",
        "ACCEPTED_LOG_RECORDS=$($acceptedLogs.Count)",
        'FINAL_RTL_ELABORATION_PREFLIGHTS=1',
        'FINAL_RTL_ELABORATION=PASS',
        "FINAL_PREFLIGHT_RESULT_SHA256=$(Get-Sha256 -Path $FinalPreflightResult)",
        "FINAL_PREFLIGHT_PASS_LOG_SHA256=$(Get-Sha256 -Path $FinalPreflightPassLog)",
        'FULL_CLEAN_BUILDS_CONSUMED=0',
        'NEXT_ACTION=INDEPENDENT_MANIFEST_AUDIT_THEN_ONE_CLEAN_BUILD'
    ) -join "`n"
    Write-Utf8NoBom -Path $temporaryVerification -Text ($verification + "`n")

    [System.IO.File]::Move($temporaryHash, $OutputHash)
    $publishedOutputs.Add($OutputHash)
    [System.IO.File]::Move($temporaryVerification, $OutputVerification)
    $publishedOutputs.Add($OutputVerification)
    [System.IO.File]::Move($temporaryManifest, $OutputManifest)
    $publishedOutputs.Add($OutputManifest)
}
catch {
    foreach ($publishedOutput in $publishedOutputs) {
        if (Test-Path -LiteralPath $publishedOutput) {
            Remove-Item -LiteralPath $publishedOutput -Force
        }
    }
    throw
}
finally {
    foreach ($temporaryOutput in @($temporaryManifest, $temporaryHash, $temporaryVerification)) {
        if (Test-Path -LiteralPath $temporaryOutput) {
            Remove-Item -LiteralPath $temporaryOutput -Force
        }
    }
}

Write-Output "R1G_PREBUILD_MANIFEST_VERIFICATION=PASS"
Write-Output "R1G_PREBUILD_MANIFEST=$OutputManifest"
Write-Output "R1G_PREBUILD_MANIFEST_SHA256=$(Get-Sha256 -Path $OutputManifest)"
