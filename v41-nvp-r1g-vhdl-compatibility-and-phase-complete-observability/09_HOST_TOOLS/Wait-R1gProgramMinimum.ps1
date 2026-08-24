[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][string]$BindingPath,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$ProgramTimingSha256,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$IndependentDoneSha256
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
. (Join-Path $PSScriptRoot 'R1gCampaignCommon.ps1')

function Read-Map([string]$Path,[string]$ExpectedSha) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing timing input: $Path" }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash -cne $ExpectedSha.ToUpperInvariant()) {
        throw "timing input hash mismatch: $Path"
    }
    $map=@{}
    foreach($line in [IO.File]::ReadAllLines($Path)) {
        if($line -match '^([A-Z0-9_]+)=(.*)$') {
            if($map.ContainsKey($Matches[1])) { throw "duplicate key $($Matches[1]): $Path" }
            $map[$Matches[1]]=$Matches[2]
        }
    }
    return $map
}
function Require([hashtable]$Map,[string]$Key,[string]$Expected) {
    if(-not $Map.ContainsKey($Key) -or [string]$Map[$Key] -cne $Expected) { throw "$Key mismatch" }
}
function Int64([hashtable]$Map,[string]$Key) {
    [long]$value=0
    if(-not $Map.ContainsKey($Key) -or -not [long]::TryParse([string]$Map[$Key],[ref]$value) -or $value -lt 0) {
        throw "$Key is not a nonnegative Int64"
    }
    return $value
}

$binding = Get-R1gBindingDocument -BindingPath $BindingPath
$phase = Get-R1gPhaseSpec $PhaseToken
$directory = Assert-R1gPhaseDirectory $phase
$timingPath = Join-Path $directory 'PROGRAM_TIMING_RECEIPT.txt'
$donePath = Join-Path $directory 'INDEPENDENT_DONE_RECEIPT.txt'
$outputPath = Join-Path $directory 'PROGRAM_WAIT_RECEIPT.txt'
if (Test-Path -LiteralPath $outputPath) { throw 'refusing to overwrite wait receipt' }
$timing=Read-Map $timingPath $ProgramTimingSha256
$done=Read-Map $donePath $IndependentDoneSha256
$required = if($phase.Image -ceq 'R1G') {[Math]::Max(10.0,[double]$binding.r1gBit.requiredWaitSeconds)} else {5.0}
$requiredText=$required.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)
$frequency=[Diagnostics.Stopwatch]::Frequency
Require $timing PHASE_TOKEN $PhaseToken
Require $timing R1G_FULL_JTAG_TARGET_PATH ([string]$binding.selectedFullJtagTargetPath)
Require $timing PROGRAM_RESULT PASS_STARTUP_HIGH_DONE_1
Require $timing PROGRAM_RETRIES 0
Require $timing REQUIRED_MINIMUM_WAIT_SECONDS $requiredText
Require $done PHASE_TOKEN $PhaseToken
Require $done DONE_STAGE IMMEDIATE_POST_PROGRAM
Require $done INDEPENDENT_DONE_GATE PASS_SELECTED_TARGET_DONE_1
Require $done FPGA_DONE 1
Require $done FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT 0
Require $done STOPWATCH_FREQUENCY ([string]$frequency)
$returnTicks=Int64 $timing PROGRAM_RETURN_MARKER_TICKS
$freshTicks=Int64 $timing FRESH_DONE_MARKER_TICKS
$referenceTicks=Int64 $timing WAIT_REFERENCE_TICKS
$doneStart=Int64 $done SESSION_START_TICKS
$doneEnd=Int64 $done SESSION_END_TICKS
if($referenceTicks -ne [Math]::Max($returnTicks,$freshTicks) -or $doneStart -lt $referenceTicks -or $doneEnd -lt $doneStart) {
    throw 'program/independent-DONE temporal ordering mismatch'
}
$requiredTicks=[long][Math]::Ceiling($required*$frequency)
$waitStart=[Diagnostics.Stopwatch]::GetTimestamp()
while(([Diagnostics.Stopwatch]::GetTimestamp()-$referenceTicks)-lt$requiredTicks) { Start-Sleep -Milliseconds 5 }
$waitEnd=[Diagnostics.Stopwatch]::GetTimestamp()
$actualTicks=$waitEnd-$referenceTicks
if($actualTicks-lt$requiredTicks){throw 'minimum-wait gate failed'}
Write-R1gUtf8NoBom -Path $outputPath -Lines @(
    "PHASE_TOKEN=$PhaseToken",
    "R1G_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "PROGRAM_TIMING_RECEIPT_SHA256=$($ProgramTimingSha256.ToUpperInvariant())",
    "INDEPENDENT_DONE_RECEIPT_SHA256=$($IndependentDoneSha256.ToUpperInvariant())",
    "STOPWATCH_FREQUENCY=$frequency",
    "WAIT_REFERENCE_TICKS=$referenceTicks",
    "INDEPENDENT_DONE_SESSION_START_TICKS=$doneStart",
    "INDEPENDENT_DONE_SESSION_END_TICKS=$doneEnd",
    'INDEPENDENT_DONE_BEFORE_WAIT_COMPLETION=YES',
    "WAIT_GATE_START_TICKS=$waitStart","WAIT_END_TICKS=$waitEnd",
    "REQUIRED_MINIMUM_WAIT_SECONDS=$requiredText",
    "ACTUAL_MONOTONIC_WAIT_TICKS=$actualTicks",
    ('ACTUAL_MONOTONIC_WAIT_SECONDS={0}' -f ([double]$actualTicks/$frequency).ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    'WAIT_GATE=PASS'
)
Get-Content -LiteralPath $outputPath
"PROGRAM_WAIT_RECEIPT_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $outputPath).Hash)"

