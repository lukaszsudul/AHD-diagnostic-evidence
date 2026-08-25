[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$safetyRoot = Join-Path $taskRoot 'hardware\00_MINIMAL_SAFETY'
$csvPath = Join-Path $safetyRoot 'START_JTAG_RECONFIRMATION_MATRIX.csv'
$logPath = Join-Path $safetyRoot 'START_JTAG_RECONFIRMATION_VIVADO.log'
$jouPath = Join-Path $safetyRoot 'START_JTAG_RECONFIRMATION_VIVADO.jou'
$targetPropertiesPath = Join-Path $safetyRoot 'START_JTAG_TARGET_PROPERTIES.tsv'
$devicePropertiesPath = Join-Path $safetyRoot 'START_JTAG_DEVICE_PROPERTIES.tsv'
$rawPath = Join-Path $safetyRoot 'START_JTAG_RECONFIRMATION_RAW.log'
$gatePath = Join-Path $safetyRoot 'R1H_R4_JTAG_SAFETY_GATE.txt'
$acceptedTcl = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts\r7_jtag_reconfirmation_session.tcl'

if (Test-Path -LiteralPath $gatePath) { throw "refusing to overwrite JTAG safety gate: $gatePath" }
if (Test-Path -LiteralPath $rawPath) {
    throw 'unexpected raw wrapper receipt exists; recovery is only for the completed-session empty-STDERR serialization defect'
}
foreach ($path in @($csvPath,$logPath,$jouPath,$targetPropertiesPath,$devicePropertiesPath,$acceptedTcl)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "completed-session evidence absent: $path" }
}

$expectedTclSha = '6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73'
$tclSha = (Get-FileHash -LiteralPath $acceptedTcl -Algorithm SHA256).Hash
if ($tclSha -cne $expectedTclSha) { throw "accepted JTAG Tcl SHA mismatch: $tclSha" }
$tclText = [IO.File]::ReadAllText($acceptedTcl)
if ([regex]::IsMatch($tclText,'(?m)^\s*program_hw_devices\b') -or
    [regex]::IsMatch($tclText,'(?m)^\s*set_property\b')) {
    throw 'accepted JTAG Tcl no longer passes the read-only static gate'
}

$rows = @(Import-Csv -LiteralPath $csvPath)
if ($rows.Count -ne 5) { throw "JTAG sample count is $($rows.Count), expected 5" }
$expectedPath = 'localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'
foreach ($row in $rows) {
    if ([string]$row.target_count -cne '1' -or [string]$row.device_count -cne '1' -or
        [string]$row.target_path -cne $expectedPath -or
        [string]$row.canonical_id -cne 'Xilinx/80802026a98b01' -or
        [string]$row.part -cne 'xc7a35t' -or [string]$row.idcode -cne '0362D093' -or
        [string]$row.done -cnotin @('0','1') -or [string]$row.refresh_result -cne 'PASS') {
        throw "JTAG sample $($row.sample_index) violates the exact selected-target contract"
    }
}
$doneValues = @($rows | ForEach-Object { [string]$_.done } | Select-Object -Unique)
if ($doneValues.Count -ne 1) { throw 'DONE was not stable across the five read-only samples' }

$logText = [IO.File]::ReadAllText($logPath)
foreach ($required in @(
    'R7_SELECTED_JTAG_CANONICAL_ID=Xilinx/80802026a98b01',
    "R7_FULL_JTAG_TARGET_PATH=$expectedPath",
    'R7_JTAG_RECONFIRMATION_SAMPLES=5',
    'R7_JTAG_RECONFIRMATION_SESSION_GATE=PASS',
    'JTAG_FREQUENCY_CHANGED=NO',
    'FPGA_PROGRAM_INVOCATIONS_THIS_SESSION=0',
    'INFO: [Common 17-206] Exiting Vivado at '
)) {
    if (-not $logText.Contains($required,[StringComparison]::Ordinal)) {
        throw "completed Vivado log lacks required evidence: $required"
    }
}
if ([regex]::IsMatch($logText,'(?m)^\s*program_hw_devices\b')) {
    throw 'completed Vivado session log contains an FPGA programming command'
}

$lines = @(
    'R1H_R4_JTAG_SAFETY_GATE=PASS',
    'SELECTED_JTAG=Xilinx/80802026a98b01',
    "R1H_FULL_JTAG_TARGET_PATH=$expectedPath",
    'FPGA_PART=xc7a35t', 'FPGA_IDCODE=0362D093',
    "CURRENT_DONE_INFORMATIONAL=$($doneValues[0])", 'JTAG_STABILITY_SAMPLES=5',
    'FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT=0', 'JTAG_FREQUENCY_CHANGED=NO',
    'READ_ONLY_GATE=YES', 'JTAG_SESSION_COUNT=1',
    'JTAG_GATE_RECOVERED_WITHOUT_SECOND_SESSION=YES',
    'WRAPPER_PROCESS_EXIT_CODE=1',
    'WRAPPER_FAILURE_CLASS=TASK_LOCAL_EMPTY_STDERR_SERIALIZATION_AFTER_COMPLETED_VIVADO_SESSION',
    'VIVADO_SESSION_COMPLETION=PASS_BY_SESSION_GATE_AND_NORMAL_EXIT_LOG',
    "READ_ONLY_JTAG_TCL_SHA256=$tclSha",
    "VIVADO_LOG_SHA256=$((Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash)",
    "VIVADO_JOURNAL_SHA256=$((Get-FileHash -LiteralPath $jouPath -Algorithm SHA256).Hash)",
    "MATRIX_SHA256=$((Get-FileHash -LiteralPath $csvPath -Algorithm SHA256).Hash)",
    "TARGET_PROPERTIES_SHA256=$((Get-FileHash -LiteralPath $targetPropertiesPath -Algorithm SHA256).Hash)",
    "DEVICE_PROPERTIES_SHA256=$((Get-FileHash -LiteralPath $devicePropertiesPath -Algorithm SHA256).Hash)",
    'RAW_WRAPPER_RECEIPT=NOT_CREATED_EMPTY_STDERR_SERIALIZATION_DEFECT',
    'SECOND_JTAG_SESSION_RUN=NO', 'MMIO_READS=0', 'MMIO_WRITES=0', 'DMA_TRANSFERS=0'
)
[IO.File]::WriteAllLines($gatePath,$lines,[Text.UTF8Encoding]::new($false))
$lines
