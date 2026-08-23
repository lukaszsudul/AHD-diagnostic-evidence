[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('FormalBootstrap','ArmA','ArmB')]
    [string]$Phase,

    [Parameter(Mandatory)]
    [string]$ExpectedFullTargetPath,

    [Parameter(Mandatory)]
    [string]$ProgramTimingReceiptPath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedProgramTimingReceiptSha256,

    [Parameter(Mandatory)]
    [string]$IndependentDoneReceiptPath,

    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedIndependentDoneReceiptSha256
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$expectedIndependentDoneTclSha = '122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B'

$phaseSpec = switch ($Phase) {
    'FormalBootstrap' { [pscustomobject]@{ Directory = Join-Path $taskRoot '07_FORMAL_BOOTSTRAP'; RequiredSeconds = 5.0 } }
    'ArmA' { [pscustomobject]@{ Directory = Join-Path $taskRoot '08_ARM_A_R1E'; RequiredSeconds = 10.0 } }
    'ArmB' { [pscustomobject]@{ Directory = Join-Path $taskRoot '09_ARM_B_FORMAL'; RequiredSeconds = 5.0 } }
}

function Resolve-CheckedFile([string]$Path) {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

function Read-KeyValueReceipt([string]$Path) {
    $map = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^([A-Z0-9_]+)=(.*)$') {
            if ($map.ContainsKey($Matches[1])) { throw "duplicate receipt key $($Matches[1]): $Path" }
            $map[$Matches[1]] = $Matches[2]
        }
    }
    return $map
}

function Require-Value([hashtable]$Map, [string]$Key, [string]$Expected) {
    if (-not $Map.ContainsKey($Key) -or [string]$Map[$Key] -cne $Expected) {
        throw "receipt key $Key mismatch; expected '$Expected'"
    }
}

function Get-Int64Value([hashtable]$Map, [string]$Key) {
    if (-not $Map.ContainsKey($Key)) { throw "receipt lacks $Key" }
    [long]$value = 0
    if (-not [long]::TryParse([string]$Map[$Key], [ref]$value) -or $value -lt 0) {
        throw "receipt key $Key is not a nonnegative Int64"
    }
    return $value
}

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

$resolvedTaskRoot = (Resolve-Path -LiteralPath $taskRoot -ErrorAction Stop).Path
if ($resolvedTaskRoot -cne $taskRoot) { throw "unexpected R7 task-root resolution: $resolvedTaskRoot" }
$phaseDirectory = (Resolve-Path -LiteralPath $phaseSpec.Directory -ErrorAction Stop).Path
if ($phaseDirectory -cne $phaseSpec.Directory) { throw "unexpected phase directory: $phaseDirectory" }

$expectedProgramTimingPath = Join-Path $phaseDirectory 'PROGRAM_TIMING_RECEIPT.txt'
$expectedIndependentPath = Join-Path $phaseDirectory 'INDEPENDENT_DONE_RECEIPT.txt'
$programReceiptPath = Resolve-CheckedFile $ProgramTimingReceiptPath
$independentReceiptPath = Resolve-CheckedFile $IndependentDoneReceiptPath
if ($programReceiptPath -cne $expectedProgramTimingPath) { throw 'unexpected program timing receipt path' }
if ($independentReceiptPath -cne $expectedIndependentPath) { throw 'unexpected independent-DONE receipt path' }

$programReceiptSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $programReceiptPath).Hash
$independentReceiptSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $independentReceiptPath).Hash
if ($programReceiptSha -cne $ExpectedProgramTimingReceiptSha256.ToUpperInvariant()) { throw 'program timing receipt SHA-256 mismatch' }
if ($independentReceiptSha -cne $ExpectedIndependentDoneReceiptSha256.ToUpperInvariant()) { throw 'independent-DONE receipt SHA-256 mismatch' }

$program = Read-KeyValueReceipt $programReceiptPath
$independent = Read-KeyValueReceipt $independentReceiptPath
$frequency = [Diagnostics.Stopwatch]::Frequency
$requiredSecondsText = ([double]$phaseSpec.RequiredSeconds).ToString('F9', [Globalization.CultureInfo]::InvariantCulture)

Require-Value $program 'PHASE' $Phase
Require-Value $program 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
Require-Value $program 'PROGRAM_RESULT' 'PASS_STARTUP_HIGH_DONE_1'
Require-Value $program 'MODE_AWARE_PREPROGRAM_GATE' 'PASS'
Require-Value $program 'PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT' '1'
Require-Value $program 'STOPWATCH_FREQUENCY' ([string]$frequency)
Require-Value $program 'REQUIRED_MINIMUM_WAIT_SECONDS' $requiredSecondsText
Require-Value $program 'TIMING_RECEIPT_STATUS' 'PASS_IMMUTABLE_WAIT_INPUT'
$returnTicks = Get-Int64Value $program 'PROGRAM_RETURN_MARKER_TICKS'
$freshDoneTicks = Get-Int64Value $program 'FRESH_DONE_MARKER_TICKS'
$referenceTicks = Get-Int64Value $program 'WAIT_REFERENCE_TICKS'
if ($referenceTicks -ne [Math]::Max($returnTicks, $freshDoneTicks)) {
    throw 'program timing receipt later-of-return/fresh-DONE reference mismatch'
}

Require-Value $independent 'PHASE' $Phase
Require-Value $independent 'DONE_STAGE' 'IMMEDIATE_POST_PROGRAM'
Require-Value $independent 'INDEPENDENT_READ_ONLY_SESSION' 'YES'
Require-Value $independent 'READ_ONLY_JTAG_TCL_SHA256' $expectedIndependentDoneTclSha
Require-Value $independent 'R7_SELECTED_JTAG_CANONICAL_ID' 'Xilinx/80802026a98b01'
Require-Value $independent 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
Require-Value $independent 'FPGA_PART' 'xc7a35t'
Require-Value $independent 'FPGA_IDCODE' '0362D093'
Require-Value $independent 'FPGA_DONE' '1'
Require-Value $independent 'FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT' '0'
Require-Value $independent 'PROCESS_EXIT_CODE' '0'
Require-Value $independent 'TIMED_OUT' 'NO'
Require-Value $independent 'STOPWATCH_FREQUENCY' ([string]$frequency)
Require-Value $independent 'INDEPENDENT_DONE_GATE' 'PASS_SELECTED_TARGET_DONE_1'
if (-not $independent.ContainsKey('RAW_TRANSCRIPT_SHA256') -or
    [string]$independent.RAW_TRANSCRIPT_SHA256 -notmatch '^[0-9A-F]{64}$') {
    throw 'independent-DONE raw transcript SHA-256 is absent or malformed'
}
$independentStartTicks = Get-Int64Value $independent 'SESSION_START_TICKS'
$independentEndTicks = Get-Int64Value $independent 'SESSION_END_TICKS'
if ($independentStartTicks -lt $referenceTicks -or $independentEndTicks -lt $independentStartTicks) {
    throw 'independent-DONE session was not ordered after the accepted program marker'
}

$waitReceiptPath = Join-Path $phaseDirectory 'PROGRAM_WAIT_RECEIPT.txt'
if (Test-Path -LiteralPath $waitReceiptPath) { throw "wait receipt path must be fresh: $waitReceiptPath" }
$waitGateStartTicks = [Diagnostics.Stopwatch]::GetTimestamp()
if ($waitGateStartTicks -lt $independentEndTicks) { throw 'wait gate began before independent-DONE session ended' }
$requiredWaitTicks = [long][Math]::Ceiling([double]$phaseSpec.RequiredSeconds * $frequency)
while (([Diagnostics.Stopwatch]::GetTimestamp() - $referenceTicks) -lt $requiredWaitTicks) {
    Start-Sleep -Milliseconds 5
}
$waitEndTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$actualWaitTicks = $waitEndTicks - $referenceTicks
$actualWaitSeconds = [double]$actualWaitTicks / $frequency
if ($actualWaitTicks -lt $requiredWaitTicks) { throw 'monotonic minimum-wait gate failed' }

$lines = [string[]]@(
    ('PHASE={0}' -f $Phase),
    ('R7_FULL_JTAG_TARGET_PATH={0}' -f $ExpectedFullTargetPath),
    ('PROGRAM_TIMING_RECEIPT_PATH={0}' -f $programReceiptPath),
    ('PROGRAM_TIMING_RECEIPT_SHA256={0}' -f $programReceiptSha),
    ('INDEPENDENT_DONE_RECEIPT_PATH={0}' -f $independentReceiptPath),
    ('INDEPENDENT_DONE_RECEIPT_SHA256={0}' -f $independentReceiptSha),
    ('STOPWATCH_FREQUENCY={0}' -f $frequency),
    ('PROGRAM_RETURN_MARKER_TICKS={0}' -f $returnTicks),
    ('FRESH_DONE_MARKER_TICKS={0}' -f $freshDoneTicks),
    ('WAIT_REFERENCE_TICKS={0}' -f $referenceTicks),
    ('INDEPENDENT_DONE_SESSION_START_TICKS={0}' -f $independentStartTicks),
    ('INDEPENDENT_DONE_SESSION_END_TICKS={0}' -f $independentEndTicks),
    'INDEPENDENT_DONE_BEFORE_WAIT_COMPLETION=YES',
    ('WAIT_GATE_START_TICKS={0}' -f $waitGateStartTicks),
    ('WAIT_END_TICKS={0}' -f $waitEndTicks),
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f $requiredSecondsText),
    ('ACTUAL_MONOTONIC_WAIT_TICKS={0}' -f $actualWaitTicks),
    ('ACTUAL_MONOTONIC_WAIT_SECONDS={0}' -f $actualWaitSeconds.ToString('F9', [Globalization.CultureInfo]::InvariantCulture)),
    'WAIT_GATE=PASS'
)
Write-Utf8NoBom -Path $waitReceiptPath -Lines $lines
$lines
('PROGRAM_WAIT_RECEIPT_SHA256={0}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $waitReceiptPath).Hash)
