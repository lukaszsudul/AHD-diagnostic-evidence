[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path (Split-Path -Parent $PSScriptRoot) '02_PROGRAM_OBSERVER_FIX\PROGRAM_OBSERVER_STATIC_AUDIT_RAW.txt')
)

$ErrorActionPreference = 'Stop'
$tclPath = Join-Path $PSScriptRoot 'program_once_startup_high_done.tcl'
$supervisorPath = Join-Path $PSScriptRoot 'Run-ProgramOnceStartupHighDone.ps1'
$parserPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'
$fixturePath = Join-Path $PSScriptRoot 'Test-ProgramObserverFixtures.ps1'
$logTestPath = Join-Path $PSScriptRoot 'Test-ProgramObserverLog.ps1'
$preflightPath = Join-Path $PSScriptRoot 'read_only_property_preflight.tcl'
$tcl = [IO.File]::ReadAllText($tclPath)
$supervisor = [IO.File]::ReadAllText($supervisorPath)

$programCommandCount = ([regex]::Matches($tcl,'(?m)^\s*program_hw_devices\s+\$dev\s*$')).Count
$bit4QueryCount = ([regex]::Matches($tcl,'(?m)^\s*.*get_property\s+(?:\$bit4_property|REGISTER\.IR\.BIT4_EOS)\b')).Count
$bit5QueryCount = ([regex]::Matches($tcl,'(?m)^\s*set\s+\w+\s+\[get_property\s+\$bit5_property\s+\$dev\]\s*$')).Count
$allowedRoleGate = $tcl.Contains('set allowed_roles {ARM_A_25KHZ ARM_B_FORMAL_50KHZ}')
$bit4AttemptMarker = $tcl.Contains('emit BIT4_EOS_PROPERTY_QUERY_ATTEMPTED NO')
$vendorPatternGate = $supervisor.Contains('End of startup status: HIGH') -or
    ([IO.File]::ReadAllText($parserPath)).Contains('End of startup status:')
$rawLauncherCount = ([regex]::Matches($supervisor,'unwrapped\\win64\.o\\vivado\.exe',[Text.RegularExpressions.RegexOptions]::IgnoreCase)).Count

$parseRows = [Collections.Generic.List[string]]::new()
foreach ($path in @($supervisorPath,$parserPath,$fixturePath,$logTestPath)) {
    $tokens = $null
    $errors = $null
    [Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors) | Out-Null
    $parseRows.Add(('POWERSHELL_PARSE_ERRORS {0} {1}' -f $errors.Count,$path))
    if ($errors.Count -ne 0) { throw "PowerShell parse failure: $path" }
}

$rows = @(
    'PROGRAM_HW_DEVICES_COMMAND_COUNT=' + $programCommandCount,
    'BIT4_EOS_PROPERTY_QUERY_COUNT=' + $bit4QueryCount,
    'BIT5_DONE_PROPERTY_QUERY_COUNT=' + $bit5QueryCount,
    'ALLOWED_ROLES=' + $(if ($allowedRoleGate) {'2'} else {'FAIL'}),
    'BIT4_EOS_PROPERTY_QUERY_ATTEMPTED_MARKER=' + $(if ($bit4AttemptMarker) {'PASS'} else {'FAIL'}),
    'VENDOR_STARTUP_HIGH_PATTERN_GATE=' + $(if ($vendorPatternGate) {'PASS'} else {'FAIL'}),
    'FORBIDDEN_RAW_VIVADO_LAUNCHER_COUNT=' + $rawLauncherCount,
    'NO_RETRY_LOOP=PASS_STATIC_SINGLE_COMMAND_NO_PROGRAM_LOOP',
    'PROGRAM_TCL_SHA256=' + (Get-FileHash -LiteralPath $tclPath -Algorithm SHA256).Hash,
    'PROGRAM_SUPERVISOR_SHA256=' + (Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash,
    'OBSERVER_PARSER_SHA256=' + (Get-FileHash -LiteralPath $parserPath -Algorithm SHA256).Hash,
    'READ_ONLY_PREFLIGHT_SHA256=' + (Get-FileHash -LiteralPath $preflightPath -Algorithm SHA256).Hash
) + $parseRows

if ($programCommandCount -ne 1 -or $bit4QueryCount -ne 0 -or $bit5QueryCount -ne 2 -or
    -not $allowedRoleGate -or -not $bit4AttemptMarker -or -not $vendorPatternGate -or $rawLauncherCount -ne 0) {
    $rows += 'PROGRAM_OBSERVER_STATIC_AUDIT=FAIL'
    [IO.File]::WriteAllLines($OutputPath,$rows,[Text.UTF8Encoding]::new($false))
    throw 'program observer static audit failed'
}
$rows += 'PROGRAM_OBSERVER_STATIC_AUDIT=PASS'
[IO.File]::WriteAllLines($OutputPath,$rows,[Text.UTF8Encoding]::new($false))
$rows

