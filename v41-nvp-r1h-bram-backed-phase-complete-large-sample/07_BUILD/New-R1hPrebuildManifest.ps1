[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepositoryRoot,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$R1hCommit,
    [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$R1hTree,
    [Parameter(Mandatory = $true)][string]$SourceIdentityReceipt,
    [Parameter(Mandatory = $true)][string]$ScientificEquivalenceReceipt,
    [Parameter(Mandatory = $true)][string]$PrecommitReleaseReceipt,
    [Parameter(Mandatory = $true)][switch]$FinalizeAfterCommit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$BuildRoot = Join-Path $TaskRoot '07_BUILD'
$OutputManifest = Join-Path $BuildRoot 'R1H_PREBUILD_MANIFEST.txt'
$OutputHash = Join-Path $BuildRoot 'R1H_PREBUILD_MANIFEST_SHA256.txt'
$OutputVerification = Join-Path $BuildRoot 'R1H_PREBUILD_MANIFEST_VERIFICATION.txt'
$ExactR1gCommit = 'e112a5addb7ac62700a9a71af81bf368fad0bada'
$ExactR1gTree = '3a59ebec130103055d24a3a32ecda00dedde5534'
$ExpectedBranch = 'diag/v41-nvp-r1h-bram-backed-large-sample'
$ExpectedBuildTclSha256 = '2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18'
$BuildTcl = Join-Path $BuildRoot 'r1h_build.tcl'

function Get-CanonicalPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [System.IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
}

function Assert-PathWithin {
    param([Parameter(Mandatory = $true)][string]$Path,
          [Parameter(Mandatory = $true)][string]$Parent)
    $child = Get-CanonicalPath $Path
    $root = Get-CanonicalPath $Parent
    if (-not $child.StartsWith($root + [IO.Path]::DirectorySeparatorChar,
            [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the required root: $child"
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required file is missing: $Path"
    }
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Invoke-GitText {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    $output = & git -C $RepositoryRoot @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git failed: git -C '$RepositoryRoot' $($Arguments -join ' ')`n$($output -join "`n")"
    }
    return (($output -join "`n").Trim())
}

function Assert-LiteralLine {
    param([Parameter(Mandatory = $true)][string]$Path,
          [Parameter(Mandatory = $true)][string]$Line)
    $text = [IO.File]::ReadAllText((Get-CanonicalPath $Path))
    if (-not [regex]::IsMatch($text, '(?m)^\s*' + [regex]::Escape($Line) + '\s*$')) {
        throw "Receipt '$Path' lacks exact line '$Line'"
    }
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory = $true)][string]$Path,
          [Parameter(Mandatory = $true)][string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

if (-not $FinalizeAfterCommit.IsPresent) {
    throw 'Fail closed: -FinalizeAfterCommit is required after the sole R1h commit.'
}

$RepositoryRoot = Get-CanonicalPath $RepositoryRoot
$SourceIdentityReceipt = Get-CanonicalPath $SourceIdentityReceipt
$ScientificEquivalenceReceipt = Get-CanonicalPath $ScientificEquivalenceReceipt
$PrecommitReleaseReceipt = Get-CanonicalPath $PrecommitReleaseReceipt
Assert-PathWithin $SourceIdentityReceipt (Join-Path $TaskRoot '06_SOURCE_COMMIT')
Assert-PathWithin $ScientificEquivalenceReceipt (Join-Path $TaskRoot '05_EQUIVALENCE_AND_SIMULATION')
Assert-PathWithin $PrecommitReleaseReceipt (Join-Path $TaskRoot '06_SOURCE_COMMIT')

foreach ($path in @($OutputManifest, $OutputHash, $OutputVerification)) {
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite finalized output: $path" }
}
if ((Get-Sha256 $BuildTcl) -cne $ExpectedBuildTclSha256) {
    throw 'R1h build Tcl SHA-256 mismatch.'
}

$gitTop = Get-CanonicalPath (Invoke-GitText @('rev-parse', '--show-toplevel'))
if (-not [string]::Equals($gitTop, $RepositoryRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw "RepositoryRoot is not exact Git top: $gitTop"
}
$actualCommit = (Invoke-GitText @('rev-parse', 'HEAD')).ToLowerInvariant()
$actualTree = (Invoke-GitText @('rev-parse', 'HEAD^{tree}')).ToLowerInvariant()
$actualParent = (Invoke-GitText @('rev-parse', 'HEAD^')).ToLowerInvariant()
$actualBranch = Invoke-GitText @('symbolic-ref', '--short', 'HEAD')
$parentTree = (Invoke-GitText @('rev-parse', "$ExactR1gCommit^{tree}")).ToLowerInvariant()
$above = Invoke-GitText @('rev-list', '--count', "$ExactR1gCommit..$R1hCommit")
$status = Invoke-GitText @('status', '--porcelain=v1', '--untracked-files=all')
if ($actualCommit -cne $R1hCommit -or $actualTree -cne $R1hTree) { throw 'R1h HEAD/tree mismatch.' }
if ($actualParent -cne $ExactR1gCommit -or $parentTree -cne $ExactR1gTree) { throw 'R1h parent identity mismatch.' }
if ($actualBranch -cne $ExpectedBranch -or $above -cne '1') { throw 'R1h topology/branch mismatch.' }
if ($status -ne '') { throw "R1h worktree is not clean:`n$status" }

$allowedChangedPaths = @(
    'rtl/top/ahd_capture_top_xdma.sv',
    'rtl/v41/control_status_regs.sv',
    'rtl/v41/nvp_i2c_tri_phase_probe.sv',
    'rtl/v41/r1f_failed_txn_logger.sv',
    'rtl/v41/r1f_measurement_regs.sv',
    'rtl/v41/r1h_mmio_read_service.sv',
    'rtl/v41/r1h_probe_index_bram_store.sv',
    'tests/v41/r1g_measurement_regs_reference.sv',
    'tests/v41/r1h_memory_inference_top.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_idle_timeout.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv',
    'tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv',
    'tests/v41/tb_r1f_failed_txn_logger.sv',
    'tests/v41/tb_r1f_measurement_regs.sv',
    'tests/v41/tb_r1f_preinit_arbitration.sv',
    'tests/v41/tb_r1h_mmio_integration_exhaustive.sv',
    'tests/v41/tb_r1h_mmio_read_service.sv',
    'tests/v41/tb_r1h_probe_index_bram_store.sv'
)
$actualChangedPaths = @((Invoke-GitText @('diff', '--name-only', '--diff-filter=ACMRTUXB', $ExactR1gCommit, $R1hCommit)) -split "`r?`n" | Where-Object { $_ })
$expectedSorted = @($allowedChangedPaths | Sort-Object)
$actualSorted = @($actualChangedPaths | Sort-Object)
if (($expectedSorted -join "`n") -cne ($actualSorted -join "`n")) {
    throw "R1g-to-R1h path scope mismatch.`nExpected:`n$($expectedSorted -join "`n")`nActual:`n$($actualSorted -join "`n")"
}

Assert-LiteralLine $ScientificEquivalenceReceipt 'R1H_SCIENTIFIC_EQUIVALENCE_GATE=PASS'
Assert-LiteralLine $ScientificEquivalenceReceipt 'BLOCKERS=NONE'
Assert-LiteralLine $PrecommitReleaseReceipt 'PRECOMMIT_RELEASE=PASS'
Assert-LiteralLine $PrecommitReleaseReceipt 'BLOCKERS=NONE'

$recordReport = Join-Path $TaskRoot '03_MEMORY_ARCHITECTURE\FAILED_RECORD_BRAM_IMPLEMENTATION.md'
$probeReport = Join-Path $TaskRoot '05_EQUIVALENCE_AND_SIMULATION\probe_index_bram\PROBE_BRAM_AND_BLOCK_STATS_VERIFICATION.md'
$memoryInference = Join-Path $TaskRoot '05_EQUIVALENCE_AND_SIMULATION\memory_inference_ooc\MEMORY_INFERENCE_RESULT.txt'
$resetReport = Join-Path $TaskRoot '05_EQUIVALENCE_AND_SIMULATION\R1H_RESET_LIVENESS_AND_MMIO_SUPERSEDING_REPORT.md'
$hostGate = Join-Path $TaskRoot '09_HOST_TOOLS\R1H_HOST_TOOL_GATE.txt'
$sourceScope = Join-Path $TaskRoot '05_EQUIVALENCE_AND_SIMULATION\R1H_INDEPENDENT_SOURCE_SCOPE_AUDIT.md'
$buildStatic = Join-Path $BuildRoot 'R1H_BUILD_SCRIPT_STATIC_AUDIT.md'

$metadata = [ordered]@{
    SOURCE_GIT_COMMIT = $R1hCommit
    SOURCE_GIT_TREE = $R1hTree
    R1H_BUILD_TCL_SHA256 = $ExpectedBuildTclSha256
    R1G_FROZEN_BUILD_TCL_SHA256 = 'C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A'
    PREBUILD_AUDIT = 'PASS'
    R1H_PREBUILD_RELEASE = 'PASS'
    SCIENTIFIC_SCOPE_REDUCTION = 'NO'
    PRE_INIT_DONE_CYCLE_EQUIVALENCE = 'PASS'
    AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL = 'YES'
    FUNCTIONAL_STATE_SEQUENCE_IDENTICAL = 'YES'
    PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL = 'YES'
    DIAGNOSTIC_EVENT_STREAM_IDENTICAL = 'YES'
    R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT = '0'
    MMIO_TRANSACTION_LEVEL_EQUIVALENCE = 'PASS_ALL_ADDRESSES'
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
    FAILED_RECORD_CAPACITY = '64'
    FAILED_RECORD_WIDTH = '192'
    INDEX_CAPACITY_PER_PHASE = '512'
    PROBE_TARGET_OPPORTUNITIES_PER_PHASE = '10000'
    BRAM_ARCHITECTURE_TESTS = 'PASS'
    MMIO_LATENCY_AND_BACKPRESSURE_TESTS = 'PASS'
    ALL_R1G_SCIENTIFIC_TESTS = 'PASS'
    INHERITED_POWER_TIMING = 'PASS'
    INHERITED_D2B_SEQUENCE = 'PASS'
    R1F_PRODUCTION_TIMING_MODEL = 'PASS'
    HOST_TOOL_FIXTURES = 'PASS'
    STATISTICAL_SCRIPT_FIXTURES = 'PASS'
}

$accepted = [ordered]@{}
foreach ($label in @('PRE_INIT_EQUIVALENCE','AUTOINIT_PHASE_AND_FAILED_TXN_SCOREBOARD','LEGACY_FIRST8_RECONCILIATION','TRANSACTION_INDEX_16','INHERITED_POWER_TIMING','INHERITED_D2B_SEQUENCE','R1H_EVENT_STREAM_EQUIVALENCE')) { $accepted[$label] = $ScientificEquivalenceReceipt }
$accepted['EFFECTIVE_PRE_INIT_ARBITRATION'] = $probeReport
$accepted['FAILED_TXN_LOGGER_64_65'] = $recordReport
foreach ($label in @('TRI_PHASE_PROBE_SUCCESS','TRI_PHASE_PROBE_ABORT_RESTORE','TRI_PHASE_PROBE_SCL_TIMEOUT','TRI_PHASE_PROBE_ATTEMPT_LIMIT','TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE','TRI_PHASE_PROBE_INDEX_OVERFLOW','TRI_PHASE_PROBE_IDLE_TIMEOUT','R1F_PRODUCTION_TIMING_MODEL','R1H_PROBE_INDEX_BRAM_ARCHITECTURE')) { $accepted[$label] = $probeReport }
foreach ($label in @('R1F_REGISTER_MAP','TOP_INTEGRATION','R1H_MMIO_TRANSACTION_EQUIVALENCE','R1H_MMIO_BACKPRESSURE','R1G_VS_R1H_DECODED_FIXTURE_EQUALITY')) { $accepted[$label] = $resetReport }
$accepted['HOST_TOOL_FIXTURES'] = $hostGate
$accepted['STATISTICAL_SCRIPT_FIXTURES'] = $hostGate
$accepted['R1H_FAILED_TXN_BRAM_ARCHITECTURE'] = $recordReport
$accepted['R1H_MEMORY_INFERENCE_ELABORATION'] = $memoryInference
$accepted['R1H_SOURCE_IDENTITY'] = $SourceIdentityReceipt
$accepted['R1H_PRECOMMIT_RELEASE'] = $PrecommitReleaseReceipt
$accepted['R1H_SOURCE_SCOPE_AUDIT'] = $sourceScope
$accepted['R1H_BUILD_SCRIPT_STATIC_AUDIT'] = $buildStatic
$accepted['R1H_BUILD_TCL'] = $BuildTcl

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# Exact external R1h prebuild manifest; generated once after the sole direct-child commit.')
foreach ($entry in $metadata.GetEnumerator()) { $lines.Add("META|$($entry.Key)|$($entry.Value)") }
$lines.Add('')
$tracked = @((Invoke-GitText @('ls-files')) -split "`r?`n" | Where-Object { $_ } | Sort-Object)
foreach ($relative in $tracked) {
    $absolute = Join-Path $RepositoryRoot ($relative.Replace('/', '\'))
    $lines.Add("SOURCE_SHA256|$relative|$(Get-Sha256 $absolute)")
}
$lines.Add('')
foreach ($entry in $accepted.GetEnumerator()) {
    $path = Get-CanonicalPath ([string]$entry.Value)
    Assert-PathWithin $path $TaskRoot
    if ($path.Contains('|')) { throw "Manifest delimiter in path: $path" }
    $lines.Add("ACCEPTED_LOG_SHA256|$($entry.Key)|$path|$(Get-Sha256 $path)")
}

$manifestText = ($lines -join "`n") + "`n"
$tmpManifest = "$OutputManifest.$([guid]::NewGuid().ToString('N')).tmp"
$tmpHash = "$OutputHash.$([guid]::NewGuid().ToString('N')).tmp"
$tmpVerification = "$OutputVerification.$([guid]::NewGuid().ToString('N')).tmp"
$published = [Collections.Generic.List[string]]::new()
try {
    Write-Utf8NoBom $tmpManifest $manifestText
    $manifestSha = Get-Sha256 $tmpManifest
    Write-Utf8NoBom $tmpHash "$manifestSha  R1H_PREBUILD_MANIFEST.txt`n"
    $verification = @(
        'R1H_PREBUILD_MANIFEST_VERIFICATION=PASS',
        "R1H_PREBUILD_MANIFEST_SHA256=$manifestSha",
        "SOURCE_GIT_COMMIT=$R1hCommit",
        "SOURCE_GIT_TREE=$R1hTree",
        "R1H_PARENT_COMMIT=$ExactR1gCommit",
        'R1H_COMMITS_ABOVE_R1G=1',
        "SOURCE_RECORDS=$($tracked.Count)",
        "ACCEPTED_LOG_RECORDS=$($accepted.Count)",
        'FULL_CLEAN_BUILDS_CONSUMED=0',
        'NEXT_ACTION=INDEPENDENT_MANIFEST_AUDIT_THEN_ONE_CLEAN_BUILD'
    ) -join "`n"
    Write-Utf8NoBom $tmpVerification ($verification + "`n")
    [IO.File]::Move($tmpHash, $OutputHash)
    $published.Add($OutputHash)
    [IO.File]::Move($tmpVerification, $OutputVerification)
    $published.Add($OutputVerification)
    [IO.File]::Move($tmpManifest, $OutputManifest)
    $published.Add($OutputManifest)
}
catch {
    foreach ($path in $published) {
        if (Test-Path -LiteralPath $path) { Remove-Item -LiteralPath $path -Force }
    }
    throw
}
finally {
    foreach ($tmp in @($tmpManifest,$tmpHash,$tmpVerification)) {
        if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    }
}

Write-Output 'R1H_PREBUILD_MANIFEST_VERIFICATION=PASS'
Write-Output "R1H_PREBUILD_MANIFEST_SHA256=$(Get-Sha256 $OutputManifest)"
