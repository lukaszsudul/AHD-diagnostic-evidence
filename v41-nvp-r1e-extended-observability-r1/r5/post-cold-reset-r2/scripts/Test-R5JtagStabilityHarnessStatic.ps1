[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$tclPath = Join-Path $TaskRoot 'scripts\r5_jtag_stability_session.tcl'
$supervisorPath = Join-Path $TaskRoot 'scripts\Invoke-R5JtagTransportStability.ps1'
$tcl = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $tclPath))
$supervisor = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $supervisorPath))
$failures = [Collections.Generic.List[string]]::new()

$tokens = $null
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($supervisorPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count -ne 0) {
    foreach ($parseError in $parseErrors) { $failures.Add("PowerShell parse error: $parseError") }
}

$forbiddenPatterns = @(
    '(?im)^\s*program_hw_devices\b',
    '(?im)^\s*set_property\b',
    '(?im)^\s*write_(?:bitstream|cfgmem|checkpoint)\b',
    '(?im)^\s*create_hw_(?:bitstream|cfgmem)\b',
    '(?im)^\s*commit_hw_\w+\b',
    '(?im)^\s*(?:synth_design|opt_design|place_design|phys_opt_design|route_design)\b'
)
foreach ($pattern in $forbiddenPatterns) {
    if ([regex]::IsMatch($tcl, $pattern)) { $failures.Add("forbidden Tcl command pattern: $pattern") }
}

$checks = [ordered]@{
    TCL_SESSION_INDEX_DOMAIN = $tcl -match 'session_index ni \{1 2\}'
    TCL_SAMPLE_COUNT_FIVE = $tcl -match 'set sample_count 5'
    TCL_DELAY_500_MS = $tcl -match 'set inter_sample_delay_ms 500'
    TCL_REFRESH_IN_FIXED_LOOP = ([regex]::Matches($tcl, '(?m)^\s*refresh_hw_device\s+\$dev\s*$').Count -eq 1) -and ($tcl -match '\$sample_index <= \$sample_count')
    TCL_EXACT_TARGET = $tcl -match [regex]::Escape('localhost:3121/xilinx_tcf/Digilent/210241768436')
    TCL_EXACT_PART = $tcl -match 'set expected_part \{xc7a35t\}'
    TCL_EXACT_IDCODE = $tcl -match 'set expected_idcode \{0362D093\}'
    TCL_DONE_READ_EACH_SAMPLE = $tcl -match 'get_property REGISTER\.IR\.BIT5_DONE \$sample_dev'
    TCL_MONOTONIC_TIMESTAMP = $tcl -match 'clock clicks -milliseconds'
    TCL_LIST_PROPERTY_CAPTURE = $tcl -match 'set sorted_properties \[lsort -dictionary \[list_property \$dev\]\]'
    TCL_CLEAN_CLOSE = ($tcl -match 'close_hw_target') -and ($tcl -match 'disconnect_hw_server') -and ($tcl -match 'close_hw_manager')
    SUPERVISOR_EXACT_TWO_SESSIONS = $supervisor -match 'for \(\$sessionIndex = 1; \$sessionIndex -le 2; \$sessionIndex\+\+\)'
    SUPERVISOR_SEQUENTIAL_WAIT = $supervisor -match '\$process\.WaitForExit\(\$TimeoutSeconds \* 1000\)'
    SUPERVISOR_EXACT_SAMPLE_GATE = $supervisor -match '\$allRows\.Count -ne 10'
    SUPERVISOR_STABLE_DONE_GATE = $supervisor -match '\$doneValues\.Count -ne 1'
    SUPERVISOR_SUPPORTED_SETTINGS = $supervisor -match [regex]::Escape('C:\AMDDesignTools\2025.2\Vivado\settings64.bat')
    SUPERVISOR_SUPPORTED_LAUNCHER = $supervisor -match [regex]::Escape('C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat')
    SUPERVISOR_PER_SESSION_RAW_LOGS = $supervisor -match 'SESSION_\{0\}_RAW\.log'
    SUPERVISOR_COMBINED_MATRIX = $supervisor -match 'JTAG_STABILITY_MATRIX\.csv'
}

foreach ($entry in $checks.GetEnumerator()) {
    if (-not $entry.Value) { $failures.Add("static check failed: $($entry.Key)") }
}

$tclForbiddenCount = 0
foreach ($pattern in $forbiddenPatterns) {
    $tclForbiddenCount += [regex]::Matches($tcl, $pattern).Count
}

$resultLines = [Collections.Generic.List[string]]::new()
foreach ($entry in $checks.GetEnumerator()) {
    $resultLines.Add(('{0}={1}' -f $entry.Key, $(if ($entry.Value) {'PASS'} else {'FAIL'})))
}
$resultLines.Add("TCL_FORBIDDEN_HARDWARE_MUTATION_COMMAND_COUNT=$tclForbiddenCount")
$resultLines.Add("TCL_SHA256=$((Get-FileHash -LiteralPath $tclPath -Algorithm SHA256).Hash)")
$resultLines.Add("SUPERVISOR_SHA256=$((Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash)")
$resultLines.Add("STATIC_AUDIT=$(if ($failures.Count -eq 0) {'PASS'} else {'FAIL'})")
$resultLines

if ($failures.Count -ne 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}


