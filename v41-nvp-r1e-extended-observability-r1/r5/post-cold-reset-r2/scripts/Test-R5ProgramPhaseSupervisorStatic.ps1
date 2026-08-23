[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$programTclPath = Join-Path $TaskRoot 'scripts\program_once_startup_high_done.tcl'
$parserPath = Join-Path $TaskRoot 'scripts\ProgramObserverCommon.ps1'
$supervisorPath = Join-Path $TaskRoot 'scripts\Invoke-R5ProgramPhaseOnce.ps1'
$expectedProgramTclSha = '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653'
$expectedParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'

$programTcl = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $programTclPath -ErrorAction Stop))
$supervisor = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $supervisorPath -ErrorAction Stop))
$failures = [Collections.Generic.List[string]]::new()

$tokens = $null
$parseErrors = $null
[Management.Automation.Language.Parser]::ParseFile($supervisorPath, [ref]$tokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count -ne 0) {
    foreach ($parseError in $parseErrors) { $failures.Add("PowerShell parse error: $parseError") }
}

$programTclSha = (Get-FileHash -LiteralPath $programTclPath -Algorithm SHA256).Hash
$parserSha = (Get-FileHash -LiteralPath $parserPath -Algorithm SHA256).Hash
$programCallCount = [regex]::Matches($programTcl, '(?m)^\s*program_hw_devices\s+\$dev\s*$').Count
$programFileAssignmentCount = [regex]::Matches($programTcl, '(?m)^\s*set_property\s+PROGRAM\.FILE\s+\$bitfile\s+\$dev\s*$').Count
$bit4QueryCount = [regex]::Matches($programTcl, '(?m)^\s*get_property\s+\$bit4_property\b').Count
$supervisorProcessStartCount = [regex]::Matches($supervisor, '\$process\.Start\(\)').Count
$supervisorProgramCommandCount = [regex]::Matches($supervisor, '(?im)^\s*program_hw_devices\b').Count

$oldR1Bindings = @(
    'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191',
    '0af44dee3bc091eaff805704dd5c687eeaa01bbd',
    'ahd_capture_v41_i2c_25khz_r1.bit'
)
$oldR1BindingCount = 0
foreach ($oldBinding in $oldR1Bindings) {
    $oldR1BindingCount += [regex]::Matches($supervisor, [regex]::Escape($oldBinding), [Text.RegularExpressions.RegexOptions]::IgnoreCase).Count
}

$checks = [ordered]@{
    PROGRAM_TCL_HASH_EXACT = $programTclSha -ceq $expectedProgramTclSha
    OBSERVER_PARSER_HASH_EXACT = $parserSha -ceq $expectedParserSha
    PROGRAM_CALL_COUNT_ONE = $programCallCount -eq 1
    PROGRAM_FILE_ASSIGNMENT_COUNT_ONE = $programFileAssignmentCount -eq 1
    BIT4_EOS_QUERY_COUNT_ZERO = $bit4QueryCount -eq 0
    SUPERVISOR_POWERSHELL_PARSE = $parseErrors.Count -eq 0
    SUPERVISOR_PHASE_SET_EXACT = $supervisor -match "ValidateSet\('FormalBootstrap','ArmA','ArmB'\)"
    SUPERVISOR_PROCESS_START_COUNT_ONE = $supervisorProcessStartCount -eq 1
    SUPERVISOR_PROGRAM_COMMAND_COUNT_ZERO = $supervisorProgramCommandCount -eq 0
    SUPERVISOR_NO_CALLER_BIT_PARAMETERS = $supervisor -notmatch '(?m)^\s*\[Parameter\(Mandatory\)\]\[string\]\$BitPath'
    FORMAL_FILENAME_BOUND = $supervisor -match [regex]::Escape('ahd_capture_v41_phase2_p1.bit')
    FORMAL_SIZE_BOUND = $supervisor -match '\$formalSize = 2192144L'
    FORMAL_SHA_BOUND = $supervisor -match '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
    R1E_FILENAME_BOUND = $supervisor -match [regex]::Escape('ahd_capture_v41_i2c_25khz_r1e_observability.bit')
    R1E_SIZE_BOUND = $supervisor -match '\$r1eSize = 2192144L'
    R1E_SHA_BOUND = $supervisor -match '0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9'
    OLD_R1_BIT_BINDING_COUNT_ZERO = $oldR1BindingCount -eq 0
    FORMAL_BOOTSTRAP_WAIT_FIXED_5 = $supervisor -match "'FormalBootstrap'[\s\S]*?RequiredWaitSeconds = 5\.0"
    ARM_A_WAIT_FIXED_10 = $supervisor -match "'ArmA'[\s\S]*?RequiredWaitSeconds = 10\.0"
    ARM_B_WAIT_FIXED_5 = $supervisor -match "'ArmB'[\s\S]*?RequiredWaitSeconds = 5\.0"
    ISOLATED_VIVADO_LOG_FLAG = $supervisor -match '''-log'', \(Assert-CmdToken \$vivadoLog\)'
    ISOLATED_VIVADO_JOURNAL_FLAG = $supervisor -match '''-journal'', \(Assert-CmdToken \$vivadoJournal\)'
    FRESH_OUTPUT_GATE = $supervisor -match 'phase output path must be fresh'
    QPC_FREQUENCY_RECORDED = $supervisor -match 'Diagnostics\.Stopwatch\]::Frequency'
    QPC_RETURN_AND_DONE_REFERENCE = $supervisor -match 'Math\]::Max\(\[long\]\$result\.PROGRAM_RETURN_MARKER_TICKS, \[long\]\$result\.FRESH_DONE_MARKER_TICKS\)'
    WAIT_RECEIPT_WRITTEN = $supervisor -match "PROGRAM_WAIT_RECEIPT\.txt"
    FAIL_CLASSIFICATION_NO_RETRY = $supervisor -match 'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    VIVADO_WRAPPER_USED = $supervisor -match [regex]::Escape('C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat')
    RAW_VIVADO_EXE_ABSENT = $supervisor -notmatch 'vivado\.exe'
}

foreach ($entry in $checks.GetEnumerator()) {
    if (-not $entry.Value) { $failures.Add("static check failed: $($entry.Key)") }
}

foreach ($entry in $checks.GetEnumerator()) {
    '{0}={1}' -f $entry.Key, $(if ($entry.Value) {'PASS'} else {'FAIL'})
}
"PROGRAM_TCL_SHA256=$programTclSha"
"OBSERVER_PARSER_SHA256=$parserSha"
"PROGRAM_HW_DEVICES_EXECUTABLE_COUNT=$programCallCount"
"SUPERVISOR_PROCESS_START_SYNTACTIC_COUNT=$supervisorProcessStartCount"
"OLD_R1_BIT_BINDING_COUNT=$oldR1BindingCount"
"SUPERVISOR_SHA256=$((Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash)"
"STATIC_AUDIT=$(if ($failures.Count -eq 0) {'PASS'} else {'FAIL'})"

if ($failures.Count -ne 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}
