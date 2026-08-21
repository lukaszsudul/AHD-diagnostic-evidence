[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,
    [Parameter(Mandatory = $true)]
    [ValidateSet('ARM_A_25KHZ','ARM_B_FORMAL_50KHZ')]
    [string]$Role
)

$ErrorActionPreference = 'Stop'
[System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture
[System.Globalization.CultureInfo]::CurrentUICulture = [System.Globalization.CultureInfo]::InvariantCulture

function Convert-Hex32([string]$Text) {
    if ($Text -notmatch '^0x[0-9A-Fa-f]{8}$') {
        throw "invalid 32-bit hex value: $Text"
    }
    return [Convert]::ToUInt32($Text.Substring(2), 16)
}

function Normalize-Hex32([string]$Text) {
    [void](Convert-Hex32 $Text)
    return '0x' + $Text.Substring(2).ToUpperInvariant()
}

function Get-Delta32([uint32]$First, [uint32]$Second) {
    if ([uint64]$Second -ge [uint64]$First) {
        return [uint64]$Second - [uint64]$First
    }
    return ([uint64]1 -shl 32) - [uint64]$First + [uint64]$Second
}

function Emit([string]$Name, $Value) {
    '{0}={1}' -f $Name, $Value
}

$resolved = (Resolve-Path -LiteralPath $InputPath).Path
$lines = Get-Content -LiteralPath $resolved
$snapshots = @{ T0 = @{}; T1 = @{} }
$bootBefore = $null
$bootAfter = $null
$identity = @{}
$identityRc = @{}
$provenance = @{}
$provenanceRc = @{}
$accounting = @{}

foreach ($line in $lines) {
    if ($line -match '^BOOT_ID_BEFORE=(.+)$') { $bootBefore = $Matches[1].Trim(); continue }
    if ($line -match '^BOOT_ID_AFTER=(.+)$')  { $bootAfter = $Matches[1].Trim(); continue }
    if ($line -match '^IDENTITY_FIELD=([^ ]+) OFFSET=([^ ]+) VALUE=(0x[0-9A-Fa-f]{8}) EXPECTED=(0x[0-9A-Fa-f]{8}) READER_RC=([0-9]+)$') {
        $identity[$Matches[1]] = Normalize-Hex32 $Matches[3]
        $identityRc[$Matches[1]] = [int]$Matches[5]
        continue
    }
    if ($line -match '^PROVENANCE_FIELD=([^ ]+) OFFSET=([^ ]+) VALUE=(0x[0-9A-Fa-f]{8}) READER_RC=([0-9]+)$') {
        $provenance[$Matches[1]] = Normalize-Hex32 $Matches[3]
        $provenanceRc[$Matches[1]] = [int]$Matches[4]
        continue
    }
    if ($line -match '^(MMIO_READS_THIS_TRANSACTION|AXI_LITE_WRITES_THIS_TRANSACTION|C2H_TRANSFERS_THIS_TRANSACTION|H2C_TRANSFERS_THIS_TRANSACTION)=([0-9]+)$') {
        $accounting[$Matches[1]] = [uint64]$Matches[2]
        continue
    }
    if ($line -match '^SNAPSHOT=(T[01]) FIELD=([^ ]+) OFFSET=([^ ]+) VALUE=(0x[0-9A-Fa-f]{8}) READER_RC=([0-9]+) READ_START_NS=([0-9]+) READ_END_NS=([0-9]+)$') {
        $snapshots[$Matches[1]][$Matches[2]] = [pscustomobject]@{
            Offset  = $Matches[3]
            Text    = Normalize-Hex32 $Matches[4]
            Value   = Convert-Hex32 $Matches[4]
            ReaderRc = [int]$Matches[5]
            StartNs = [uint64]$Matches[6]
            EndNs   = [uint64]$Matches[7]
        }
    }
}

$required = @(
    'FRAME','VCLK','SAV','RECORD_COMMIT','STATUS','NACK','TIMEOUT',
    'SUMMARY','FIRST_ERROR','DETAIL0','DETAIL1','DETAIL2','DETAIL3','DETAIL4','DETAIL5'
)
foreach ($s in 'T0','T1') {
    foreach ($field in $required) {
        if (-not $snapshots[$s].ContainsKey($field)) {
            throw "missing $s field $field"
        }
        $expectedReaderRc = if ($snapshots[$s][$field].Value -eq 0) { 0 } else { 3 }
        if ($snapshots[$s][$field].ReaderRc -ne $expectedReaderRc) {
            throw "unexpected accepted-reader exit for ${s}/${field}: observed value $($snapshots[$s][$field].Text), rc $($snapshots[$s][$field].ReaderRc), expected rc $expectedReaderRc"
        }
    }
}


if ([string]::IsNullOrWhiteSpace($bootBefore) -or [string]::IsNullOrWhiteSpace($bootAfter)) {
    throw 'boot-ID bracket is incomplete'
}
$requiredIdentity = [ordered]@{
    BLOCK_ID='0xA40A0C07'; PROTOCOL='0x0000400B';
    CAPABILITIES='0x00031002'; DIAGNOSTIC_MAGIC='0x00000000'
}
foreach ($entry in $requiredIdentity.GetEnumerator()) {
    if (-not $identity.ContainsKey($entry.Key) -or $identity[$entry.Key] -cne $entry.Value -or
        -not $identityRc.ContainsKey($entry.Key) -or $identityRc[$entry.Key] -ne 0) {
        throw "identity mismatch for $($entry.Key)"
    }
}

$requiredProvenance = @('GIT_SHA_W0','GIT_SHA_W1','GIT_SHA_W2','GIT_SHA_W3','GIT_SHA_W4','BUILD_FLAGS')
foreach ($name in $requiredProvenance) {
    if (-not $provenance.ContainsKey($name) -or -not $provenanceRc.ContainsKey($name)) {
        throw "missing provenance field $name"
    }
    $expectedReaderRc = if ((Convert-Hex32 $provenance[$name]) -eq 0) { 0 } else { 3 }
    if ($provenanceRc[$name] -ne $expectedReaderRc) {
        throw "unexpected accepted-reader exit for provenance $name"
    }
}

$runtimeCommit = (($provenance.GIT_SHA_W0,$provenance.GIT_SHA_W1,$provenance.GIT_SHA_W2,
    $provenance.GIT_SHA_W3,$provenance.GIT_SHA_W4) | ForEach-Object { $_.Substring(2) }) -join ''
$runtimeCommit = $runtimeCommit.ToLowerInvariant()
$expectedDiagnosticCommit = 'f007dc172d43d30b02729755e60382f8ce3dbff4'
$provenanceGate = if ($Role -eq 'ARM_A_25KHZ') {
    $runtimeCommit -ceq $expectedDiagnosticCommit -and $provenance.BUILD_FLAGS -ceq '0x00000002'
} else {
    # Accepted formal Phase-2 closure evidence exposes zero in every
    # provenance word and BUILD_FLAGS. Require that exact runtime signature;
    # the separately rehashed formal bit remains the image-transition anchor.
    $runtimeCommit -ceq ('0' * 40) -and $provenance.BUILD_FLAGS -ceq '0x00000000'
}
if (-not $provenanceGate) {
    throw "runtime provenance mismatch for $Role"
}

$requiredAccounting = [ordered]@{
    MMIO_READS_THIS_TRANSACTION = 40
    AXI_LITE_WRITES_THIS_TRANSACTION = 0
    C2H_TRANSFERS_THIS_TRANSACTION = 0
    H2C_TRANSFERS_THIS_TRANSACTION = 0
}
foreach ($entry in $requiredAccounting.GetEnumerator()) {
    if (-not $accounting.ContainsKey($entry.Key) -or $accounting[$entry.Key] -ne $entry.Value) {
        throw "operation accounting mismatch for $($entry.Key)"
    }
}

$staticFields = @('STATUS','NACK','TIMEOUT','SUMMARY','FIRST_ERROR','DETAIL0','DETAIL1','DETAIL2','DETAIL3','DETAIL4','DETAIL5')
$staticMismatch = @()
foreach ($field in $staticFields) {
    if ($snapshots.T0[$field].Value -ne $snapshots.T1[$field].Value) {
        $staticMismatch += $field
    }
}

$rates = @{}
foreach ($field in 'VCLK','SAV','FRAME','RECORD_COMMIT') {
    $t0 = $snapshots.T0[$field]
    $t1 = $snapshots.T1[$field]
    $delta = Get-Delta32 $t0.Value $t1.Value
    $intervalMin = ([double]($t1.StartNs - $t0.EndNs)) / 1.0e9
    $intervalMax = ([double]($t1.EndNs - $t0.StartNs)) / 1.0e9
    if ($intervalMin -le 0 -or $intervalMax -le 0 -or $intervalMax -lt $intervalMin) {
        throw "invalid timestamp bracket for $field"
    }
    $rates[$field] = [pscustomobject]@{
        Delta = $delta
        IntervalMin = $intervalMin
        IntervalMax = $intervalMax
        RateMin = [double]$delta / $intervalMax
        RateMax = [double]$delta / $intervalMin
    }
}

[uint64]$status = $snapshots.T0.STATUS.Value
[uint64]$first = $snapshots.T0.FIRST_ERROR.Value
[uint64]$detail3 = $snapshots.T0.DETAIL3.Value
[uint64]$detail5 = $snapshots.T0.DETAIL5.Value

$initDone = $status -band 1
$initError = ($status -shr 1) -band 1
$initBusy = ($status -shr 2) -band 1
$resetReleased = ($status -shr 3) -band 1
$vdd1x = ($status -shr 4) -band 1
$vdd3x = ($status -shr 5) -band 1
$scl = ($status -shr 6) -band 1
$sda = ($status -shr 7) -band 1

$firstValid = ($first -shr 31) -band 1
$firstCode = ($first -shr 16) -band 0xFF
$firstStep = ($first -shr 8) -band 0xFF
$detailStep = $detail3 -band 0xFF
$firstMetaBank = ($detail3 -shr 8) -band 0xFF
$firstRegister = ($detail3 -shr 16) -band 0xFF
$firstValue = ($detail3 -shr 24) -band 0xFF
$originalFf = ($detail5 -shr 8) -band 0xFF
$restoredFf = ($detail5 -shr 16) -band 0xFF
$firstPhysicalBank = ($detail5 -shr 24) -band 0xFF

$firstTupleConsistent = ($firstValid -eq 0 -or $firstStep -eq $detailStep)
$firstErrorText = if ($firstValid -eq 0) {
    'NONE'
} else {
    'CODE_0x{0:X2}_STEP_0x{1:X2}_META_0x{2:X2}_PHYS_0x{3:X2}_REG_0x{4:X2}_VALUE_0x{5:X2}' -f $firstCode,$firstStep,$firstMetaBank,$firstPhysicalBank,$firstRegister,$firstValue
}

$basicFunctionalPass = (
    $bootBefore -eq $bootAfter -and
    $provenanceGate -and
    $staticMismatch.Count -eq 0 -and
    $firstTupleConsistent -and
    $initDone -eq 1 -and
    $initError -eq 0 -and
    $snapshots.T0.NACK.Value -eq 0 -and
    $snapshots.T0.TIMEOUT.Value -eq 0 -and
    $firstValid -eq 0 -and
    $rates.VCLK.Delta -gt 0 -and
    $rates.SAV.Delta -gt 0 -and
    $rates.FRAME.Delta -gt 0
)

Emit INPUT_PATH $resolved
Emit ROLE $Role
Emit BOOT_ID_BEFORE $bootBefore
Emit BOOT_ID_AFTER $bootAfter
Emit BOOT_ID_STABLE ($(if ($bootBefore -eq $bootAfter) { 'PASS' } else { 'FAIL' }))
foreach ($name in 'BLOCK_ID','PROTOCOL','CAPABILITIES','DIAGNOSTIC_MAGIC') {
    Emit $name $identity[$name]
}
foreach ($name in 'GIT_SHA_W0','GIT_SHA_W1','GIT_SHA_W2','GIT_SHA_W3','GIT_SHA_W4','BUILD_FLAGS') {
    Emit $name $provenance[$name]
}
Emit RUNTIME_GIT_SHA $runtimeCommit
Emit EXPECTED_DIAGNOSTIC_GIT_SHA $expectedDiagnosticCommit
Emit PROVENANCE_GATE ($(if ($Role -eq 'ARM_A_25KHZ') { 'PASS_EXACT_DIAGNOSTIC_COMMIT_AND_BUILD_FLAGS' } else { 'PASS_ACCEPTED_FORMAL_ZERO_GIT_WORDS_AND_BUILD_FLAGS' }))
Emit STATIC_FIELDS_MATCH ($(if ($staticMismatch.Count -eq 0) { 'PASS' } else { 'FAIL' }))
Emit STATIC_FIELD_MISMATCHES ($(if ($staticMismatch.Count) { $staticMismatch -join ',' } else { 'NONE' }))
Emit INIT_DONE $initDone
Emit INIT_ERROR $initError
Emit INIT_BUSY $initBusy
Emit NVP_RESET_RELEASED_STATUS $resetReleased
Emit NVP_VDD1X_ACTIVE $vdd1x
Emit NVP_VDD3X_ACTIVE $vdd3x
Emit NVP_SCL_SAMPLE $scl
Emit NVP_SDA_SAMPLE $sda
Emit NACK_COUNT $snapshots.T0.NACK.Value
Emit TIMEOUT_COUNT $snapshots.T0.TIMEOUT.Value
Emit FIRST_ERROR_VALID $firstValid
Emit FIRST_ERROR_TUPLE_CONSISTENT ($(if ($firstTupleConsistent) { 'PASS' } else { 'FAIL' }))
Emit FIRST_ERROR $firstErrorText
Emit ORIGINAL_FF ('0x{0:X2}' -f $originalFf)
Emit RESTORED_FF ('0x{0:X2}' -f $restoredFf)

foreach ($field in 'VCLK','SAV','FRAME','RECORD_COMMIT') {
    $prefix = $field.ToUpperInvariant()
    Emit "${prefix}_T0" $snapshots.T0[$field].Value
    Emit "${prefix}_T1" $snapshots.T1[$field].Value
    Emit "${prefix}_DELTA" $rates[$field].Delta
    Emit "${prefix}_INTERVAL_MIN_SECONDS" ('{0:F9}' -f $rates[$field].IntervalMin)
    Emit "${prefix}_INTERVAL_MAX_SECONDS" ('{0:F9}' -f $rates[$field].IntervalMax)
    Emit "${prefix}_RATE_MIN" ('{0:F6}' -f $rates[$field].RateMin)
    Emit "${prefix}_RATE_MAX" ('{0:F6}' -f $rates[$field].RateMax)
}

Emit BASIC_FUNCTIONAL_GATE ($(if ($basicFunctionalPass) { 'PASS' } else { 'FAIL' }))
Emit PRELIMINARY_OBSERVER_GATE ($(if ($basicFunctionalPass) { 'PASS' } else { 'FAIL' }))
foreach ($name in $requiredAccounting.Keys) {
    Emit $name $accounting[$name]
}
Emit RATE_RANGE_POLICY_APPLIED NO_PARENT_CAMPAIGN_MUST_APPLY_PREDECLARED_NORMAL_RANGES
Emit PARENT_FROZEN_RATE_RANGE_GATE_REQUIRED YES
Emit PARENT_RESET_VDD_GATE_REQUIRED YES
Emit FINAL_ARM_CLASSIFICATION_DEFERRED_TO_PARENT YES
Emit HOST_VISIBLE_DIAGNOSTIC_DETAIL_WORDS DETAIL0_THROUGH_DETAIL5
Emit HOST_VISIBLE_DIAGNOSTIC_BITS 192
Emit FULL_INTERNAL_NACK_LOG_BAR_VISIBLE NO
Emit NVP_TELEMETRY_PARSE PASS
