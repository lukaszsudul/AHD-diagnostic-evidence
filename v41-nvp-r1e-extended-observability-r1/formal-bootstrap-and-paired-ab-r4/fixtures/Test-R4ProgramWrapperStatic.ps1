[CmdletBinding()]
param(
    [string]$OutputPath = 'C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4\02_HOST_TOOL_PREFLIGHT\PROGRAM_OBSERVER\R4_WRAPPER_STATIC_AUDIT.txt'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$wrapperPath = Join-Path $root 'scripts\Run-R4ProgramOnceStartupHighDone.ps1'
$tclPath = Join-Path $root 'scripts\program_once_startup_high_done.tcl'
$parserPath = Join-Path $root 'scripts\ProgramObserverCommon.ps1'
$wrapper = [IO.File]::ReadAllText($wrapperPath)
$tcl = [IO.File]::ReadAllText($tclPath)

$tokens = $null
$errors = $null
[Management.Automation.Language.Parser]::ParseFile($wrapperPath,[ref]$tokens,[ref]$errors) | Out-Null

$checks = [ordered]@{
    POWERSHELL_PARSE_ERRORS = $errors.Count
    PROGRAM_HW_DEVICES_COMMAND_COUNT = ([regex]::Matches($tcl,'(?m)^\s*program_hw_devices\s+\$dev\s*$')).Count
    ACCEPTED_TCL_SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $tclPath).Hash
    ACCEPTED_PARSER_SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $parserPath).Hash
    R4_WRAPPER_SHA256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $wrapperPath).Hash
    R4_ROLE_SET_PRESENT = [int]$wrapper.Contains("ValidateSet('FORMAL_BOOTSTRAP','ARM_A_R1E','ARM_B_FORMAL')")
    R1E_FILENAME_PRESENT = [int]$wrapper.Contains('ahd_capture_v41_i2c_25khz_r1e_observability.bit')
    R1E_SHA_PRESENT = [int]$wrapper.Contains('0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9')
    R1E_COMMIT_PRESENT = [int]$wrapper.Contains('f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd')
    FORMAL_SHA_PRESENT = [int]$wrapper.Contains('7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2')
    ARM_A_TCL_ROLE_MAPPING_PRESENT = [int]$wrapper.Contains("if (`$Role -eq 'ARM_A_R1E') {'ARM_A_25KHZ'} else {'ARM_B_FORMAL_50KHZ'}")
    WRAPPER_PROGRAM_COMMAND_COUNT = ([regex]::Matches($wrapper,'(?m)^\s*program_hw_devices\b')).Count
    RAW_VIVADO_EXE_COUNT = ([regex]::Matches($wrapper,'unwrapped\\win64\.o\\vivado\.exe',[Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count
}

$pass = (
    $checks.POWERSHELL_PARSE_ERRORS -eq 0 -and
    $checks.PROGRAM_HW_DEVICES_COMMAND_COUNT -eq 1 -and
    $checks.ACCEPTED_TCL_SHA256 -ceq '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653' -and
    $checks.ACCEPTED_PARSER_SHA256 -ceq '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66' -and
    $checks.R4_ROLE_SET_PRESENT -eq 1 -and
    $checks.R1E_FILENAME_PRESENT -eq 1 -and
    $checks.R1E_SHA_PRESENT -eq 1 -and
    $checks.R1E_COMMIT_PRESENT -eq 1 -and
    $checks.FORMAL_SHA_PRESENT -eq 1 -and
    $checks.ARM_A_TCL_ROLE_MAPPING_PRESENT -eq 1 -and
    $checks.WRAPPER_PROGRAM_COMMAND_COUNT -eq 0 -and
    $checks.RAW_VIVADO_EXE_COUNT -eq 0
)

$lines = @($checks.GetEnumerator() | ForEach-Object { '{0}={1}' -f $_.Key,$_.Value })
$lines += 'NO_RETRY_LOOP=PASS_ONE_PROCESS_LAUNCH_PER_WRAPPER_INVOCATION'
$lines += 'PROGRAM_INVOCATION_MARKER_PRECEDES_COMMAND=INHERITED_EXACT_ACCEPTED_TCL'
$lines += 'R4_PROGRAM_WRAPPER_STATIC_AUDIT=' + $(if($pass){'PASS'}else{'FAIL'})
[IO.File]::WriteAllLines($OutputPath,$lines,[Text.UTF8Encoding]::new($false))
$lines
if(-not $pass){throw 'R4 program wrapper static audit failed'}
