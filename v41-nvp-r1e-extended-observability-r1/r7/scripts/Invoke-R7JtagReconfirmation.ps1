[CmdletBinding()]
param([ValidateRange(60,900)][int]$SessionTimeoutSeconds = 300)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$r6Root = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$selectorPath = Join-Path $r6Root 'scripts\select_r6_jtag_target.tcl'
$sessionTclPath = Join-Path $PSScriptRoot 'r7_jtag_reconfirmation_session.tcl'
$evidenceDir = Join-Path $taskRoot '05_JTAG_RECONFIRMATION'

$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedSelectorSha = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
$expectedSessionTclSha = '6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73'
$expectedCanonicalId = 'Xilinx/80802026a98b01'
$canonicalSuffix = '/Xilinx/80802026a98b01'
$expectedPart = 'xc7a35t'
$expectedIdcode = '0362D093'

$sessionCsv = Join-Path $evidenceDir 'R7_JTAG_RECONFIRMATION_MATRIX.csv'
$targetProperties = Join-Path $evidenceDir 'R7_TARGET_PROPERTIES.tsv'
$deviceProperties = Join-Path $evidenceDir 'R7_DEVICE_PROPERTIES.tsv'
$rawLog = Join-Path $evidenceDir 'R7_JTAG_RECONFIRMATION_RAW.log'
$vivadoLog = Join-Path $evidenceDir 'R7_JTAG_RECONFIRMATION_VIVADO.log'
$vivadoJournal = Join-Path $evidenceDir 'R7_JTAG_RECONFIRMATION_VIVADO.jou'
$gatePath = Join-Path $evidenceDir 'R7_JTAG_RECONFIRMATION_GATE.md'

function Resolve-CheckedFile([string]$Path) { return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path }
function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') { throw "unsafe cmd.exe token: $Text" }
    return $Text
}
function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

foreach ($path in @($sessionCsv,$targetProperties,$deviceProperties,$rawLog,$vivadoLog,$vivadoJournal,$gatePath)) {
    if (Test-Path -LiteralPath $path) { throw "R7 reconfirmation evidence path must be fresh: $path" }
}
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
$selector = Resolve-CheckedFile $selectorPath
$sessionTcl = Resolve-CheckedFile $sessionTclPath
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $settings).Hash -cne $expectedSettingsSha) { throw 'Vivado settings hash mismatch' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $vivado).Hash -cne $expectedVivadoSha) { throw 'Vivado launcher hash mismatch' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $selector).Hash -cne $expectedSelectorSha) { throw 'frozen R6 selector hash mismatch' }
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $sessionTcl).Hash -cne $expectedSessionTclSha) { throw 'R7 reconfirmation Tcl hash mismatch' }

$tokens = @(
    'call',(Assert-CmdToken $settings),'&&',(Assert-CmdToken $vivado),
    '-mode','batch','-notrace','-log',(Assert-CmdToken $vivadoLog),
    '-journal',(Assert-CmdToken $vivadoJournal),'-source',(Assert-CmdToken $sessionTcl),'-tclargs',
    (Assert-CmdToken $sessionCsv),(Assert-CmdToken $targetProperties),(Assert-CmdToken $deviceProperties)
)
$command = $tokens -join ' '
$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = "$env:SystemRoot\System32\cmd.exe"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.WorkingDirectory = $evidenceDir
$psi.Arguments = '/d /s /c "' + $command + '"'

$process = [Diagnostics.Process]::new()
$process.StartInfo = $psi
$started = $false
$timedOut = $false
$stdout = ''
$stderr = ''
$exitCode = $null
$launchError = ''
$startUtc = [DateTime]::UtcNow.ToString('o')
$startTicks = [Diagnostics.Stopwatch]::GetTimestamp()
try {
    $started = $process.Start()
    if (-not $started) { throw 'failed to start the one R7 reconfirmation session' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($SessionTimeoutSeconds * 1000)) {
        $timedOut = $true
        try { $process.Kill($true) } catch { $process.Kill() }
        $process.WaitForExit()
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
} catch {
    $launchError = $_.Exception.Message
    if ($started -and -not $process.HasExited) {
        try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
        try { $process.WaitForExit() } catch {}
    }
} finally {
    $endTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $endUtc = [DateTime]::UtcNow.ToString('o')
    $process.Dispose()
}

$rawLines = [string[]]@(
    ('PROCESS_START_UTC={0}' -f $startUtc),
    ('PROCESS_END_UTC={0}' -f $endUtc),
    ('PROCESS_START_MONOTONIC_TICKS={0}' -f $startTicks),
    ('PROCESS_END_MONOTONIC_TICKS={0}' -f $endTicks),
    ('PROCESS_STARTED={0}' -f $(if ($started) {'YES'} else {'NO'})),
    ('PROCESS_TIMED_OUT={0}' -f $(if ($timedOut) {'YES'} else {'NO'})),
    ('PROCESS_EXIT_CODE={0}' -f $(if ($null -eq $exitCode) {'NOT_AVAILABLE'} else {$exitCode})),
    ('LAUNCH_ERROR={0}' -f $(if ($launchError) {$launchError} else {'NONE'})),
    '----- STDOUT BEGIN -----',$stdout,'----- STDOUT END -----',
    '----- STDERR BEGIN -----',$stderr,'----- STDERR END -----'
)
Write-Utf8NoBom -Path $rawLog -Lines $rawLines

$failures = [Collections.Generic.List[string]]::new()
if (-not $started) { $failures.Add('Vivado session did not start') }
if ($timedOut) { $failures.Add('Vivado session timed out') }
if ($null -eq $exitCode -or $exitCode -ne 0) { $failures.Add('Vivado session exit code was not zero') }
if (-not (Test-Path -LiteralPath $sessionCsv -PathType Leaf)) {
    $failures.Add('reconfirmation matrix is missing')
    $rows = @()
} else { $rows = @(Import-Csv -LiteralPath $sessionCsv) }
if ($rows.Count -ne 5) { $failures.Add("sample count is $($rows.Count), expected 5") }
if (($rows.sample_index -join ',') -cne '1,2,3,4,5') { $failures.Add('sample indices are not exactly 1..5') }
[long]$lastMonotonic = -1
foreach ($row in $rows) {
    [long]$current = 0
    if (-not [long]::TryParse($row.monotonic_ms,[ref]$current) -or ($lastMonotonic -ge 0 -and $current -le $lastMonotonic)) {
        $failures.Add('sample monotonic timestamps are invalid'); break
    }
    $lastMonotonic = $current
    if ($row.target_count -cne '1' -or $row.device_count -cne '1' -or
        $row.canonical_id -cne $expectedCanonicalId -or $row.part -cne $expectedPart -or
        $row.idcode.ToUpperInvariant() -cne $expectedIdcode -or $row.refresh_result -cne 'PASS' -or
        $row.done -cnotin @('0','1')) {
        $failures.Add("sample $($row.sample_index) identity/DONE/refresh mismatch")
    }
}
$targetPaths = @($rows.target_path | Sort-Object -Unique)
$doneValues = @($rows.done | Sort-Object -Unique)
if ($targetPaths.Count -ne 1 -or -not $targetPaths[0].EndsWith($canonicalSuffix,[StringComparison]::Ordinal)) {
    $failures.Add('full target path is not stable with the exact canonical suffix')
}
if ($doneValues.Count -ne 1 -or $doneValues[0] -cnotin @('0','1')) { $failures.Add('DONE is not stable/readable') }
foreach ($path in @($targetProperties,$deviceProperties)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
        $failures.Add("property inventory missing or empty: $path")
    }
}
$frequencyLines = @()
if (Test-Path -LiteralPath $targetProperties -PathType Leaf) {
    $frequencyLines = @([IO.File]::ReadAllLines($targetProperties) | Where-Object { $_ -match '(?i)FREQUENCY' })
}
$frequencyReported = $(if ($frequencyLines.Count -eq 0) {'NOT_EXPOSED'} else {($frequencyLines | Sort-Object -Unique) -join ';'})
$uniqueFailures = @($failures | Sort-Object -Unique)
$passed = $uniqueFailures.Count -eq 0
$gateLines = [string[]]@(
    '# R7 selected-JTAG reconfirmation gate','',
    'READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=1',
    ('R7_JTAG_RECONFIRMATION_SAMPLES={0}' -f $rows.Count),
    ('R7_SELECTED_JTAG_CANONICAL_ID={0}' -f $(if ($rows.Count -gt 0) {$rows[0].canonical_id} else {'UNAVAILABLE'})),
    ('R7_FULL_JTAG_TARGET_PATH={0}' -f $(if ($targetPaths.Count -eq 1) {$targetPaths[0]} else {'UNSTABLE_OR_UNAVAILABLE'})),
    ('R7_PREPROGRAM_DONE_VALUE={0}' -f $(if ($doneValues.Count -eq 1) {$doneValues[0]} else {'UNSTABLE_OR_UNREADABLE'})),
    ('R7_JTAG_FREQUENCY_REPORTED={0}' -f $frequencyReported),
    'R7_JTAG_FREQUENCY_CHANGED=NO',
    'FPGA_PROGRAM_INVOCATIONS=0',
    ('R7_JTAG_RECONFIRMATION_GATE={0}' -f $(if ($passed) {'PASS_5_OF_5'} else {'FAIL'})),
    '', 'FAILURES:', $(if ($passed) {'NONE'} else {$uniqueFailures -join [Environment]::NewLine})
)
Write-Utf8NoBom -Path $gatePath -Lines $gateLines
$gateLines | Where-Object { $_ -match '^[A-Z0-9_]+=' }
if (-not $passed) { exit 1 }
