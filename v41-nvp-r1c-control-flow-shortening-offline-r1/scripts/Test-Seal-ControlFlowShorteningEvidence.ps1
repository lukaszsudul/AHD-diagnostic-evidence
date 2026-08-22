[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.IO.Compression

$taskName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1'
$zipName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE_SHA256.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$sealer = Join-Path $PSScriptRoot 'Seal-ControlFlowShorteningEvidence.ps1'
$testScript = $PSCommandPath
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar

function Assert-True([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Write-Utf8([string]$Path,[string]$Text) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText($Path,$Text,$utf8NoBom)
}

function New-SyntheticRoot([string]$Suffix) {
    $path = [IO.Path]::GetFullPath((Join-Path ([IO.Path]::GetTempPath()) ('control-flow-seal-test-' + $Suffix + '-' + [Guid]::NewGuid().ToString('N'))))
    if (-not $path.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $path).StartsWith('control-flow-seal-test-',[StringComparison]::Ordinal)) {
        throw 'refusing to create synthetic root outside the operating-system temporary directory'
    }
    [IO.Directory]::CreateDirectory($path) | Out-Null
    Write-Utf8 (Join-Path $path '.CONTROL_FLOW_SEAL_TEST_ROOT') "SYNTHETIC_TEST_ROOT=YES`n"
    return $path
}

function Remove-SyntheticRoot([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    if (-not $full.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $full).StartsWith('control-flow-seal-test-',[StringComparison]::Ordinal)) {
        throw "refusing recursive deletion outside validated synthetic root: $full"
    }
    if (Test-Path -LiteralPath $full) { [IO.Directory]::Delete($full,$true) }
}

function Get-FixtureReport {
    return @'
TASK=
    V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1
TASK_MODE=
    OFFLINE_EXISTING_EVIDENCE_FORENSIC
R1_EVIDENCE_COMMIT=
    cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c
R1C_EVIDENCE_COMMIT=
    2c86f792bb439279d2eca69d87c21125f99bf63f
R1C_EVIDENCE_ZIP_SHA256=
    9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19
R1_METHOD_VALIDATION=PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL
R1_EXPECTED_CNT_AT_INIT_DONE=113182679
R1_ACTUAL_CNT_AT_INIT_DONE=113144494
R1_SIGNED_COUNT_ERROR_CYCLES=-38185
R1_SHORTENING_CYCLES=38185
R1_TICK_CYCLES=626
R1_SHORTENING_TICKS_EXACT=60.9984025559
R1_SHORTENING_TICKS_NEAREST=61
R1_RESIDUAL_CYCLES=-1
R1_OMITTED_TRANSACTION_INTERPRETATION=R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS
ARM_A_SOURCE_COUNTER_PRESENT=NO
ARM_A_MMIO_COUNTER_FIELDS_READ=NO
ARM_A_CNT_AT_INIT_DONE_AVAILABLE=NO
ARM_A_EXPECTED_CNT_AVAILABLE=NO
ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE=NO
ARM_A_RESULT_MODE=AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_A_RAW_NACK_COUNT=8
ARM_A_CONTROL_FLOW_SHORTENING_RESULT=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SOURCE_COUNTER_PRESENT=NO
ARM_B_MMIO_COUNTER_FIELDS_READ=NO
ARM_B_CNT_AT_INIT_DONE_AVAILABLE=NO
ARM_B_EXPECTED_CNT_AVAILABLE=NO
ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE=NO
ARM_B_RESULT_MODE=AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_B_RAW_NACK_COUNT=15
ARM_B_CONTROL_FLOW_SHORTENING_RESULT=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
R1C_EFFECTIVE_METRIC_CLASSIFICATION=R1C_EFFECTIVE_METRIC_NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
RAW_NACK_REDUCTION=7
RAW_NACK_REDUCTION_INTERPRETED_AS_EFFECTIVE_OPERATION_REDUCTION=NO_UNLESS_PROVEN
NEW_BUILD_REQUIRED_FOR_COUNTER_MEASUREMENT=YES
NEW_HARDWARE_REQUIRED_FOR_COUNTER_MEASUREMENT=YES
FULL_BUILDS=0
FPGA_SOURCE_CHANGES=0
HARDWARE_ACTIONS=0
MMIO_OPERATIONS=0
DMA_TRANSFERS=0
FORMAL_REPOSITORY_MUTATIONS=0
EVIDENCE_PACKAGE_SHA256=NOT_SELF_EMBEDDABLE_SEE_EXTERNAL_SHA256_SIDECAR
EVIDENCE_REPOSITORY_COMMIT=PENDING_PUBLICATION
NEXT_ACTION=OWNER_AND_AUDITOR_REVIEW_OF_EFFECTIVE_METRIC_AVAILABILITY
'@
}

function Initialize-Fixture([string]$Root) {
    $required = @(
        '00_SCOPE/OWNER_PROMPT_VERBATIM.md',
        '01_INPUT_IDENTITY/INPUT_IDENTITY.md',
        '01_INPUT_IDENTITY/INPUT_SHA256.txt',
        '01_INPUT_IDENTITY/SOURCE_COMMIT_DIFF_MATRIX.csv',
        '02_FIELD_AVAILABILITY/FIELD_AVAILABILITY_MATRIX.csv',
        '02_FIELD_AVAILABILITY/MMIO_ADDRESS_INVENTORY_A.csv',
        '02_FIELD_AVAILABILITY/MMIO_ADDRESS_INVENTORY_B.csv',
        '02_FIELD_AVAILABILITY/PARSED_FIELD_INVENTORY_A.txt',
        '02_FIELD_AVAILABILITY/PARSED_FIELD_INVENTORY_B.txt',
        '02_FIELD_AVAILABILITY/FIELD_AVAILABILITY_REPORT.md',
        '03_R1_VALIDATION/R1_COUNTER_RECALCULATION.csv',
        '03_R1_VALIDATION/R1_FAILURE_PATH_TRACE.md',
        '03_R1_VALIDATION/R1_METHOD_VALIDATION.md',
        '04_FSM_COST_MODEL/FSM_STATE_COSTS.csv',
        '04_FSM_COST_MODEL/TRANSACTION_COSTS.csv',
        '04_FSM_COST_MODEL/ALL_ACK_EXPECTED_COUNTS.csv',
        '04_FSM_COST_MODEL/FAILURE_PATH_RULES.csv',
        '04_FSM_COST_MODEL/MODEL_VALIDATION.md',
        '05_R1C_ARM_A/ARM_A_SHORTENING_RESULT.md',
        '05_R1C_ARM_A/ARM_A_SHORTENING_CALCULATION.csv',
        '05_R1C_ARM_A/ARM_A_FAILURE_PATH_REPLAY.csv',
        '06_R1C_ARM_B/ARM_B_SHORTENING_RESULT.md',
        '06_R1C_ARM_B/ARM_B_SHORTENING_CALCULATION.csv',
        '06_R1C_ARM_B/ARM_B_FAILURE_PATH_REPLAY.csv',
        '07_COMPARISON/R1_R1C_SHORTENING_MATRIX.csv',
        '07_COMPARISON/RAW_NACK_VS_EFFECTIVE_PATH_METRIC.md',
        '07_COMPARISON/R1C_A_B_COMPARISON.md'
    )
    foreach ($relative in $required) {
        $content = "FIXTURE_FILE=$relative`nOFFLINE_ONLY=YES`n"
        Write-Utf8 (Join-Path $Root ($relative.Replace('/',[IO.Path]::DirectorySeparatorChar))) $content
    }
    Write-Utf8 (Join-Path $Root '08_FINAL\V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1_REPORT.md') (Get-FixtureReport)
    Write-Utf8 (Join-Path $Root 'scripts\derive_control_flow_shortening.py') "print('fixture')`n"
    [IO.File]::Copy($sealer,(Join-Path $Root 'scripts\Seal-ControlFlowShorteningEvidence.ps1'),$false)
    [IO.File]::Copy($testScript,(Join-Path $Root 'scripts\Test-SealControlFlowShorteningEvidence.ps1'),$false)
    $operationLedger = @'
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
HARDWARE_ACTIONS=0
MMIO_OPERATIONS=0
DMA_TRANSFERS=0
FORMAL_REPOSITORY_MUTATIONS=0
'@
    $toolLedger = @'
TASK_MODE=OFFLINE_EXISTING_EVIDENCE_FORENSIC
FULL_BUILDS=0
SYNTHESIS_COMMANDS=0
IMPLEMENTATION_COMMANDS=0
BITSTREAM_COMMANDS=0
FPGA_SOURCE_EDITS=0
SSH_COMMANDS=0
JTAG_COMMANDS=0
FPGA_PROGRAM_COMMANDS=0
UBUNTU_REBOOT_COMMANDS=0
MMIO_COMMANDS=0
DMA_COMMANDS=0
PHYSICAL_ACTIONS=0
FORMAL_REPOSITORY_MUTATIONS=0
'@
    Write-Utf8 (Join-Path $Root 'OPERATION_LEDGER.md') $operationLedger
    Write-Utf8 (Join-Path $Root 'TOOL_COMMAND_LEDGER.md') $toolLedger
    Write-Utf8 (Join-Path $Root 'EVIDENCE_PUBLICATION_RECEIPT.md') "PUBLICATION_STATUS=POST_SEAL_ONLY`n"
}

function Invoke-SealSuccess([string]$Root) {
    $output = @(& $sealer -SyntheticTestMode -SyntheticRoot $Root 2>&1 | ForEach-Object { $_.ToString() })
    Assert-True (($output -join "`n").Contains('EVIDENCE_SEAL=PASS',[StringComparison]::Ordinal)) 'synthetic seal did not report PASS'
    return $output
}

function Invoke-SealExpectedFailure([string]$Root,[string]$ExpectedText,[switch]$Mutate) {
    $failed = $false
    $message = ''
    try {
        if ($Mutate) {
            & $sealer -SyntheticTestMode -SyntheticRoot $Root -SyntheticMutateAfterSnapshot 2>&1 | Out-Null
        } else {
            & $sealer -SyntheticTestMode -SyntheticRoot $Root 2>&1 | Out-Null
        }
    } catch {
        $failed = $true
        $message = $_.Exception.Message
    }
    Assert-True $failed 'negative fixture unexpectedly passed'
    Assert-True ($message.Contains($ExpectedText,[StringComparison]::OrdinalIgnoreCase)) "negative fixture failed for unexpected reason: $message"
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $Root $zipName))) 'negative fixture published a ZIP'
}

function Assert-SealedFixture([string]$Root) {
    $zipPath = Join-Path $Root $zipName
    $sidecarPath = Join-Path $Root $sidecarName
    $manifestPath = Join-Path $Root $manifestName
    $securityPath = Join-Path $Root '08_FINAL\SECURITY_SCAN.txt'
    $integrityPath = Join-Path $Root '08_FINAL\EVIDENCE_ZIP_INTEGRITY.txt'
    foreach ($path in @($zipPath,$sidecarPath,$manifestPath,$securityPath,$integrityPath)) {
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "expected seal output missing: $path"
    }

    $zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
    $sidecar = [IO.File]::ReadAllText($sidecarPath)
    Assert-True ($sidecar.Contains(('SHA256=' + $zipHash),[StringComparison]::Ordinal)) 'sidecar ZIP hash mismatch'
    Assert-True ($sidecar.Contains(('FILENAME=' + $zipName),[StringComparison]::Ordinal)) 'sidecar filename mismatch'
    $integrity = [IO.File]::ReadAllText($integrityPath)
    foreach ($token in @(
        'ZIP_INTEGRITY=PASS',
        'SOURCE_TO_SNAPSHOT_HASH_CORRESPONDENCE=PASS',
        'SNAPSHOT_TO_ZIP_HASH_CORRESPONDENCE=PASS',
        'MANIFEST_TO_ZIP_HASH_CORRESPONDENCE=PASS',
        ('ZIP_SHA256=' + $zipHash)
    )) {
        Assert-True ($integrity.Contains($token,[StringComparison]::Ordinal)) "integrity token missing: $token"
    }

    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        foreach ($entry in $archive.Entries) {
            Assert-True ($seen.Add($entry.FullName)) "duplicate entry in sealed fixture: $($entry.FullName)"
            Assert-True ($entry.FullName.StartsWith(($taskName + '/'),[StringComparison]::Ordinal)) "wrong ZIP root prefix: $($entry.FullName)"
            Assert-True (-not $entry.FullName.Contains('\')) "backslash in ZIP entry: $($entry.FullName)"
            Assert-True (-not ($entry.FullName -match '(^|/)\.\.?(/|$)')) "unsafe ZIP entry: $($entry.FullName)"
            Assert-True (-not ($entry.FullName -match '(?i)\.(?:bit|dcp|zip|7z|rar|tar|tgz|gz|bz2|xz)$')) "forbidden artifact in ZIP: $($entry.FullName)"
            Assert-True (-not $entry.FullName.EndsWith('/EVIDENCE_PUBLICATION_RECEIPT.md',[StringComparison]::Ordinal)) 'publication receipt included in ZIP'
            Assert-True (-not $entry.FullName.EndsWith('/' + $sidecarName,[StringComparison]::Ordinal)) 'sidecar included in ZIP'
            Assert-True (-not $entry.FullName.EndsWith('/EVIDENCE_ZIP_INTEGRITY.txt',[StringComparison]::Ordinal)) 'integrity receipt included in ZIP'
        }
        Assert-True ($seen.Contains($taskName + '/' + $manifestName)) 'manifest absent from ZIP'
        Assert-True ($seen.Contains($taskName + '/08_FINAL/SECURITY_SCAN.txt')) 'security report absent from ZIP'
    } finally {
        $archive.Dispose()
    }
    return $zipHash
}

if (-not (Test-Path -LiteralPath $sealer -PathType Leaf)) { throw 'sealer is missing' }
$tokens = $null
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($sealer,[ref]$tokens,[ref]$parseErrors) | Out-Null
Assert-True ($parseErrors.Count -eq 0) ('sealer parse errors: ' + (($parseErrors | ForEach-Object { $_.ToString() }) -join '; '))
[Management.Automation.Language.Parser]::ParseFile($testScript,[ref]$tokens,[ref]$parseErrors) | Out-Null
Assert-True ($parseErrors.Count -eq 0) ('test parse errors: ' + (($parseErrors | ForEach-Object { $_.ToString() }) -join '; '))

$sealerText = [IO.File]::ReadAllText($sealer)
foreach ($requiredToken in @(
    $zipName,$sidecarName,$manifestName,
    'SOURCE_TO_SNAPSHOT_HASH_CORRESPONDENCE=PASS',
    'SNAPSHOT_TO_ZIP_HASH_CORRESPONDENCE=PASS',
    'MANIFEST_TO_ZIP_HASH_CORRESPONDENCE=PASS',
    'StringComparer]::OrdinalIgnoreCase',
    'fixedZipTimestamp'
)) {
    Assert-True ($sealerText.Contains($requiredToken,[StringComparison]::Ordinal)) "static-audit token absent: $requiredToken"
}

$roots = [Collections.Generic.List[string]]::new()
try {
    $rootA = New-SyntheticRoot 'determinism-a'; $roots.Add($rootA); Initialize-Fixture $rootA
    $rootB = New-SyntheticRoot 'determinism-b'; $roots.Add($rootB); Initialize-Fixture $rootB
    Invoke-SealSuccess $rootA | Out-Null
    Invoke-SealSuccess $rootB | Out-Null
    $hashA = Assert-SealedFixture $rootA
    $hashB = Assert-SealedFixture $rootB
    Assert-True ($hashA -ceq $hashB) "deterministic ZIP mismatch: A=$hashA B=$hashB"

    $secretRoot = New-SyntheticRoot 'secret'; $roots.Add($secretRoot); Initialize-Fixture $secretRoot
    $syntheticToken = 'gh' + 'p_' + ('A' * 24)
    Write-Utf8 (Join-Path $secretRoot 'raw\synthetic_leak.txt') ($syntheticToken + "`n")
    Invoke-SealExpectedFailure $secretRoot 'secret-content scan failed'

    $bitRoot = New-SyntheticRoot 'bit'; $roots.Add($bitRoot); Initialize-Fixture $bitRoot
    Write-Utf8 (Join-Path $bitRoot 'raw\forbidden.bit') "SYNTHETIC_ONLY`n"
    Invoke-SealExpectedFailure $bitRoot 'FPGA_BIT_OR_DCP'

    $archiveRoot = New-SyntheticRoot 'archive'; $roots.Add($archiveRoot); Initialize-Fixture $archiveRoot
    Write-Utf8 (Join-Path $archiveRoot 'raw\nested.zip') "SYNTHETIC_ONLY`n"
    Invoke-SealExpectedFailure $archiveRoot 'NESTED_ARCHIVE'

    $tempRoot = New-SyntheticRoot 'temp'; $roots.Add($tempRoot); Initialize-Fixture $tempRoot
    Write-Utf8 (Join-Path $tempRoot 'raw\leftover.tmp') "SYNTHETIC_ONLY`n"
    Invoke-SealExpectedFailure $tempRoot 'TEMPORARY_FILE'

    $toctouRoot = New-SyntheticRoot 'toctou'; $roots.Add($toctouRoot); Initialize-Fixture $toctouRoot
    Invoke-SealExpectedFailure $toctouRoot 'eligible source changed after snapshot' -Mutate

    'STATIC_AUDIT=PASS'
    'POWERSHELL_PARSE=PASS'
    'SYNTHETIC_SUCCESS_FIXTURE=PASS'
    'DETERMINISTIC_TWO_ROOT_ZIP_HASH=PASS'
    'INDEPENDENT_ZIP_ENTRY_AUDIT=PASS'
    'SIDECAR_HASH_CORRESPONDENCE=PASS'
    'MANIFEST_AND_SECURITY_INCLUDED=PASS'
    'OUTPUTS_AND_RECEIPTS_EXCLUDED=PASS'
    'SECRET_NEGATIVE_FIXTURE=PASS'
    'BIT_DCP_NEGATIVE_FIXTURE=PASS'
    'NESTED_ARCHIVE_NEGATIVE_FIXTURE=PASS'
    'TEMP_FILE_NEGATIVE_FIXTURE=PASS'
    'TOCTOU_NEGATIVE_FIXTURE=PASS'
    'SEAL_TESTS=PASS_ALL'
    'DETERMINISTIC_FIXTURE_ZIP_SHA256=' + $hashA
} finally {
    foreach ($root in $roots) { Remove-SyntheticRoot $root }
}
