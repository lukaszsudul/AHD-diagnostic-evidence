[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('FormalReady','ValidArmA','ArmATerminalSafeDone1')]
    [string]$ReceiptKind,

    [Parameter(Mandatory)]
    [ValidatePattern('^.+/Xilinx/80802026a98b01$')]
    [string]$ExpectedFullTargetPath,

    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$ProgramTimingSha256,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$ImmediateDoneSha256,
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$ProgramWaitSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$WarmRebootSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$HostCycleSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$PreLoaderSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$LoaderSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$PostLoaderSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$FinalDoneSha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$TelemetrySha256 = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$OperationLedgerSha256 = '',
    [ValidatePattern('^[A-Z0-9_]+$')][string]$ArmATerminalClassification = 'ARM_A_INFRASTRUCTURE_INVALID'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$phase = if ($ReceiptKind -eq 'FormalReady') { 'FormalBootstrap' } else { 'ArmA' }
$phaseDirectory = if ($phase -eq 'FormalBootstrap') {
    Join-Path $taskRoot '07_FORMAL_BOOTSTRAP'
} else {
    Join-Path $taskRoot '08_ARM_A_R1E'
}
$phaseDirectory = (Resolve-Path -LiteralPath $phaseDirectory -ErrorAction Stop).Path

$spec = [ordered]@{
    ProgramTiming = [pscustomobject]@{ Name='PROGRAM_TIMING_RECEIPT.txt'; Sha=$ProgramTimingSha256 }
    ImmediateDone = [pscustomobject]@{ Name='INDEPENDENT_DONE_RECEIPT.txt'; Sha=$ImmediateDoneSha256 }
}
if ($ReceiptKind -ne 'ArmATerminalSafeDone1') {
    foreach ($required in @(
        'ProgramWaitSha256','WarmRebootSha256','HostCycleSha256','PreLoaderSha256',
        'LoaderSha256','PostLoaderSha256','FinalDoneSha256','OperationLedgerSha256'
    )) {
        if (-not (Get-Variable -Name $required -ValueOnly)) { throw "$ReceiptKind requires $required" }
    }
    $spec.ProgramWait = [pscustomobject]@{ Name='PROGRAM_WAIT_RECEIPT.txt'; Sha=$ProgramWaitSha256 }
    $spec.WarmReboot = [pscustomobject]@{ Name='WARM_REBOOT_EVIDENCE.log'; Sha=$WarmRebootSha256 }
    $spec.HostCycle = [pscustomobject]@{ Name='HOST_CYCLE_RECEIPT.txt'; Sha=$HostCycleSha256 }
    $spec.PreLoader = [pscustomobject]@{ Name='PRELOADER_EVIDENCE.log'; Sha=$PreLoaderSha256 }
    $spec.Loader = [pscustomobject]@{ Name='LOADER_EVIDENCE.log'; Sha=$LoaderSha256 }
    $spec.PostLoader = [pscustomobject]@{ Name='POSTLOADER_EVIDENCE.log'; Sha=$PostLoaderSha256 }
    $spec.FinalDone = [pscustomobject]@{ Name='FINAL_DONE_RECEIPT.txt'; Sha=$FinalDoneSha256 }
}
if ($ReceiptKind -eq 'ValidArmA') {
    if (-not $TelemetrySha256) { throw 'ValidArmA requires TelemetrySha256' }
    $spec.Telemetry = [pscustomobject]@{ Name='TELEMETRY_EVIDENCE.log'; Sha=$TelemetrySha256 }
}

function Get-CheckedText([string]$Path, [string]$ExpectedSha) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "missing receipt input: $Path" }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $ExpectedSha.ToUpperInvariant()) { throw "receipt input hash mismatch: $Path" }
    return [IO.File]::ReadAllText($Path)
}

function Require-ExactLine([string]$Text, [string]$Key, [string]$Expected) {
    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Key) + '=' + [regex]::Escape($Expected) + '\r?$')
    if ($matches.Count -ne 1) { throw "$Key=$Expected exact-line count is $($matches.Count), expected 1" }
}

function Get-ExactValue([string]$Text, [string]$Key) {
    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -lt 1) { throw "$Key exact-line count is 0, expected at least 1" }
    $values = @($matches | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
    if ($values.Count -ne 1) {
        throw "$Key has conflicting repeated values: $($values -join ',')"
    }
    return $values[0]
}

$text = @{}
$hashRows = [Collections.Generic.List[string]]::new()
foreach ($entry in $spec.GetEnumerator()) {
    $path = Join-Path $phaseDirectory $entry.Value.Name
    $text[$entry.Key] = Get-CheckedText $path $entry.Value.Sha
    $hashRows.Add("INPUT_$($entry.Key.ToUpperInvariant())_SHA256=$($entry.Value.Sha.ToUpperInvariant())")
}

Require-ExactLine $text.ProgramTiming 'PHASE' $phase
Require-ExactLine $text.ProgramTiming 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
Require-ExactLine $text.ProgramTiming 'PROGRAM_RESULT' 'PASS_STARTUP_HIGH_DONE_1'
Require-ExactLine $text.ProgramTiming 'PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT' '1'
Require-ExactLine $text.ProgramTiming 'TIMING_RECEIPT_STATUS' 'PASS_IMMUTABLE_WAIT_INPUT'
Require-ExactLine $text.ImmediateDone 'PHASE' $phase
Require-ExactLine $text.ImmediateDone 'DONE_STAGE' 'IMMEDIATE_POST_PROGRAM'
Require-ExactLine $text.ImmediateDone 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
Require-ExactLine $text.ImmediateDone 'FPGA_DONE' '1'
Require-ExactLine $text.ImmediateDone 'INDEPENDENT_DONE_GATE' 'PASS_SELECTED_TARGET_DONE_1'
$programTranscriptSha = Get-ExactValue $text.ProgramTiming 'PROGRAM_SUPERVISOR_LOG_SHA256'
if ($programTranscriptSha -notmatch '^[0-9A-F]{64}$') { throw 'program transcript SHA-256 is malformed' }
if ($ReceiptKind -ne 'ArmATerminalSafeDone1') {
    Require-ExactLine $text.ProgramWait 'PHASE' $phase
    Require-ExactLine $text.ProgramWait 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
    Require-ExactLine $text.ProgramWait 'WAIT_GATE' 'PASS'
    Require-ExactLine $text.WarmReboot 'RESULT' 'PASS'
    Require-ExactLine $text.WarmReboot 'EXIT_CODE' '0'
    Require-ExactLine $text.HostCycle 'ROLE' $phase
    Require-ExactLine $text.HostCycle 'HOST_CYCLE_GATE' 'PASS_HOST_DISAPPEARED_AND_RETURNED'
    Require-ExactLine $text.PreLoader 'RESULT' 'PASS'
    Require-ExactLine $text.PreLoader 'EXIT_CODE' '0'
    Require-ExactLine $text.PreLoader 'PRELOADER_GATE' 'PASS'
    Require-ExactLine $text.Loader 'RESULT' 'PASS'
    Require-ExactLine $text.Loader 'EXIT_CODE' '0'
    Require-ExactLine $text.PostLoader 'RESULT' 'PASS'
    Require-ExactLine $text.PostLoader 'EXIT_CODE' '0'
    Require-ExactLine $text.FinalDone 'PHASE' $phase
    Require-ExactLine $text.FinalDone 'DONE_STAGE' 'FINAL_POST_PHASE'
    Require-ExactLine $text.FinalDone 'R7_FULL_JTAG_TARGET_PATH' $ExpectedFullTargetPath
    Require-ExactLine $text.FinalDone 'FPGA_DONE' '1'
    Require-ExactLine $text.FinalDone 'INDEPENDENT_DONE_GATE' 'PASS_SELECTED_TARGET_DONE_1'
    if ($phase -eq 'FormalBootstrap') {
        Require-ExactLine $text.PostLoader 'RUNTIME_IMAGE' 'FORMAL_PHASE2_EXACT_IDENTITY_PAGE_ZERO'
        Require-ExactLine $text.PostLoader 'POST_LOADER_GATE' 'PASS_FORMAL_BOOTSTRAP'
    } else {
        Require-ExactLine $text.PostLoader 'RUNTIME_IMAGE' 'R1E_EXACT_PROVENANCE'
        Require-ExactLine $text.PostLoader 'POST_LOADER_GATE' 'PASS_ARM_A_R1E'
        Require-ExactLine $text.Telemetry 'RESULT' 'PASS'
        Require-ExactLine $text.Telemetry 'EXIT_CODE' '0'
        Require-ExactLine $text.Telemetry 'READ_ONLY' 'YES'
        Require-ExactLine $text.Telemetry 'STATIC_SNAPSHOTS_MATCH' 'YES'
    }
}

$receiptName = switch ($ReceiptKind) {
    'FormalReady' { 'FORMAL_READY_RECEIPT.txt' }
    'ValidArmA' { 'VALID_ARM_A_RECEIPT.txt' }
    'ArmATerminalSafeDone1' { 'ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt' }
}
$receiptType = switch ($ReceiptKind) {
    'FormalReady' { 'FORMAL_READY_RECEIPT' }
    'ValidArmA' { 'VALID_ARM_A_RECEIPT' }
    'ArmATerminalSafeDone1' { 'ARM_A_TERMINAL_SAFE_DONE1_RECEIPT' }
}
$receiptPath = Join-Path $phaseDirectory $receiptName
if (Test-Path -LiteralPath $receiptPath) { throw "refusing to overwrite configured-image receipt: $receiptPath" }
$lines = [Collections.Generic.List[string]]::new()
$lines.Add("RECEIPT_TYPE=$receiptType")
$lines.Add('RECEIPT_STATUS=PASS')
$lines.Add("PHASE=$phase")
$lines.Add("R7_FULL_JTAG_TARGET_PATH=$ExpectedFullTargetPath")
$lines.Add('FPGA_DONE=1')
$lines.Add('PROGRAM_RETRIES=0')
$lines.Add('RECEIPT_CREATION_LIVE_ACTIONS=0')
$lines.Add("RECEIPT_UTC=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add("PROGRAM_TRANSCRIPT_SHA256=$programTranscriptSha")
$lines.Add('SAME_SESSION_DONE=1')
$lines.Add('INDEPENDENT_IMMEDIATE_DONE=1')
foreach ($row in $hashRows) { $lines.Add($row) }
if ($ReceiptKind -eq 'FormalReady') {
    $lines.Add('FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2')
    $lines.Add("OPERATION_LEDGER_SHA256=$($OperationLedgerSha256.ToUpperInvariant())")
    $lines.Add("BOOT_ID=$(Get-ExactValue $text.PostLoader 'CURRENT_BOOT_ID')")
    $lines.Add("KERNEL=$(Get-ExactValue $text.PostLoader 'CURRENT_KERNEL')")
    $lines.Add("BAR0_BYTES=$(Get-ExactValue $text.PostLoader 'BAR0_BYTES')")
    $lines.Add("BAR1_BYTES=$(Get-ExactValue $text.PostLoader 'BAR1_BYTES')")
    $lines.Add("PINNED_MODULE_SHA256=$(Get-ExactValue $text.PostLoader 'PINNED_MODULE_SHA256')")
    $lines.Add("BLOCK_ID=$(Get-ExactValue $text.PostLoader 'RAW_BLOCK_ID')")
    $lines.Add("PROTOCOL=$(Get-ExactValue $text.PostLoader 'RAW_PROTOCOL')")
    $lines.Add("CAPABILITIES=$(Get-ExactValue $text.PostLoader 'RAW_CAPABILITIES')")
    $lines.Add('DIAGNOSTIC_MAGIC=0x00000000')
    $lines.Add('FINAL_POST_PHASE_DONE=1')
    $lines.Add('FORMAL_READY=YES')
    $lines.Add('FORMAL_READY_SOURCE=R7_EXACT_FORMAL_BOOTSTRAP')
} elseif ($ReceiptKind -eq 'ValidArmA') {
    $lines.Add("OPERATION_LEDGER_SHA256=$($OperationLedgerSha256.ToUpperInvariant())")
    $lines.Add('ARM_A_SAMPLE_VALID=YES')
    $lines.Add('ARM_A_TERMINAL_SAFE_DONE1=YES')
} else {
    $lines.Add('ARM_A_SAMPLE_VALID=NO')
    $lines.Add('ARM_A_TERMINAL_SAFE_DONE1=YES')
    $lines.Add("ARM_A_TERMINAL_CLASSIFICATION=$ArmATerminalClassification")
}
[IO.File]::WriteAllLines($receiptPath, $lines, [Text.UTF8Encoding]::new($false))
$lines
('CONFIGURED_IMAGE_RECEIPT_SHA256={0}' -f (Get-FileHash -LiteralPath $receiptPath -Algorithm SHA256).Hash)
