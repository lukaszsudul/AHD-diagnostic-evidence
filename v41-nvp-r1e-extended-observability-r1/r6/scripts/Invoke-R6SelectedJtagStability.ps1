[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6',
    [ValidateRange(60,900)][int]$SessionTimeoutSeconds = 300
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$expectedTaskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$selectorPath = Join-Path $PSScriptRoot 'select_r6_jtag_target.tcl'
$sessionTclPath = Join-Path $PSScriptRoot 'r6_jtag_stability_session.tcl'
$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedSelectorSha = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
$expectedSessionTclSha = '7CDA6928B3480802E8C47C156641B4BA3C5488D32702ED95A2EDAF281383D62E'
$expectedCanonicalId = 'Xilinx/80802026a98b01'
$expectedFullTargetPath = 'localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'
$expectedPart = 'xc7a35t'
$expectedIdcode = '0362D093'
$evidenceDir = Join-Path $TaskRoot '05_JTAG_STABILITY'
$combinedMatrixPath = Join-Path $evidenceDir 'JTAG_STABILITY_MATRIX.csv'
$gatePath = Join-Path $evidenceDir 'JTAG_STABILITY_GATE.md'

function Resolve-CheckedFile([string]$Path) {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') {
        throw "unsafe cmd.exe token: $Text"
    }
    return $Text
}

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

function Invoke-OneReadOnlySession(
    [int]$SessionIndex,
    [string]$Settings,
    [string]$Vivado,
    [string]$SessionTcl,
    [string]$EvidenceDirectory,
    [int]$TimeoutSeconds
) {
    $sessionCsv = Join-Path $EvidenceDirectory ("SESSION_{0}_MATRIX.csv" -f $SessionIndex)
    $targetProperties = Join-Path $EvidenceDirectory ("SESSION_{0}_TARGET_PROPERTIES.tsv" -f $SessionIndex)
    $deviceProperties = Join-Path $EvidenceDirectory ("SESSION_{0}_DEVICE_PROPERTIES.tsv" -f $SessionIndex)
    $rawLog = Join-Path $EvidenceDirectory ("SESSION_{0}_RAW.log" -f $SessionIndex)
    $vivadoLog = Join-Path $EvidenceDirectory ("SESSION_{0}_VIVADO.log" -f $SessionIndex)
    $vivadoJournal = Join-Path $EvidenceDirectory ("SESSION_{0}_VIVADO.jou" -f $SessionIndex)

    foreach ($freshPath in @($sessionCsv, $targetProperties, $deviceProperties, $rawLog, $vivadoLog, $vivadoJournal)) {
        if (Test-Path -LiteralPath $freshPath) {
            throw "session evidence path must be fresh: $freshPath"
        }
    }

    $tokens = @(
        'call', (Assert-CmdToken $Settings), '&&', (Assert-CmdToken $Vivado),
        '-mode', 'batch', '-notrace',
        '-log', (Assert-CmdToken $vivadoLog),
        '-journal', (Assert-CmdToken $vivadoJournal),
        '-source', (Assert-CmdToken $SessionTcl), '-tclargs',
        ([string]$SessionIndex),
        (Assert-CmdToken $sessionCsv),
        (Assert-CmdToken $targetProperties),
        (Assert-CmdToken $deviceProperties)
    )
    $command = $tokens -join ' '

    $psi = [Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "$env:SystemRoot\System32\cmd.exe"
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.WorkingDirectory = $EvidenceDirectory
    $psi.Arguments = '/d /s /c "' + $command + '"'

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $psi
    $startUtc = [DateTime]::UtcNow.ToString('o')
    $startTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $started = $false
    $timedOut = $false
    $exitCode = $null
    $stdout = ''
    $stderr = ''
    $launchError = ''

    try {
        $started = $process.Start()
        if (-not $started) { throw 'failed to start Vivado process' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
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

    $rawLines = [Collections.Generic.List[string]]::new()
    $rawLines.Add("SESSION_INDEX=$SessionIndex")
    $rawLines.Add("PROCESS_START_UTC=$startUtc")
    $rawLines.Add("PROCESS_END_UTC=$endUtc")
    $rawLines.Add("PROCESS_START_MONOTONIC_TICKS=$startTicks")
    $rawLines.Add("PROCESS_END_MONOTONIC_TICKS=$endTicks")
    $rawLines.Add("PROCESS_STARTED=$(if ($started) {'YES'} else {'NO'})")
    $rawLines.Add("PROCESS_TIMED_OUT=$(if ($timedOut) {'YES'} else {'NO'})")
    $rawLines.Add("PROCESS_EXIT_CODE=$(if ($null -eq $exitCode) {'NOT_AVAILABLE'} else {$exitCode})")
    $rawLines.Add("LAUNCH_ERROR=$(if ($launchError) {$launchError} else {'NONE'})")
    $rawLines.Add('----- STDOUT BEGIN -----')
    $rawLines.Add($stdout)
    $rawLines.Add('----- STDOUT END -----')
    $rawLines.Add('----- STDERR BEGIN -----')
    $rawLines.Add($stderr)
    $rawLines.Add('----- STDERR END -----')
    Write-Utf8NoBom -Path $rawLog -Lines $rawLines.ToArray()

    return [pscustomobject]@{
        SessionIndex = $SessionIndex
        Started = $started
        TimedOut = $timedOut
        ExitCode = $exitCode
        LaunchError = $launchError
        CsvPath = $sessionCsv
        TargetPropertiesPath = $targetProperties
        DevicePropertiesPath = $deviceProperties
        RawLogPath = $rawLog
        VivadoLogPath = $vivadoLog
        VivadoJournalPath = $vivadoJournal
    }
}

$resolvedTaskRoot = (Resolve-Path -LiteralPath $TaskRoot -ErrorAction Stop).Path
if ($resolvedTaskRoot -cne $expectedTaskRoot) {
    throw "unexpected task root: $resolvedTaskRoot"
}
if (-not (Test-Path -LiteralPath $evidenceDir -PathType Container)) {
    throw "missing evidence directory: $evidenceDir"
}
foreach ($freshPath in @($combinedMatrixPath, $gatePath)) {
    if (Test-Path -LiteralPath $freshPath) {
        throw "aggregate evidence path must be fresh: $freshPath"
    }
}

$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
$selector = Resolve-CheckedFile $selectorPath
$sessionTcl = Resolve-CheckedFile $sessionTclPath
if ((Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -cne $expectedSettingsSha) {
    throw 'accepted Vivado settings wrapper hash mismatch'
}
if ((Get-FileHash -LiteralPath $vivado -Algorithm SHA256).Hash -cne $expectedVivadoSha) {
    throw 'supported Vivado launcher hash mismatch'
}
if ((Get-FileHash -LiteralPath $selector -Algorithm SHA256).Hash -cne $expectedSelectorSha) {
    throw 'R6 target selector hash mismatch'
}
if ((Get-FileHash -LiteralPath $sessionTcl -Algorithm SHA256).Hash -cne $expectedSessionTclSha) {
    throw 'R6 read-only stability Tcl hash mismatch'
}

$selectorText = [IO.File]::ReadAllText($selector)
$sessionText = [IO.File]::ReadAllText($sessionTcl)
$forbiddenMutationPatterns = @(
    '(?im)^\s*program_hw_devices\b',
    '(?im)^\s*set_property\b',
    '(?im)^\s*write_(?:bitstream|cfgmem|checkpoint)\b',
    '(?im)^\s*create_hw_(?:bitstream|cfgmem)\b',
    '(?im)^\s*commit_hw_\w+\b',
    '(?im)^\s*(?:synth_design|opt_design|place_design|phys_opt_design|route_design)\b'
)
foreach ($pattern in $forbiddenMutationPatterns) {
    if ([regex]::IsMatch($selectorText, $pattern) -or [regex]::IsMatch($sessionText, $pattern)) {
        throw "read-only Tcl static gate failed: $pattern"
    }
}

$sessionResults = [Collections.Generic.List[object]]::new()
for ($sessionIndex = 1; $sessionIndex -le 2; $sessionIndex++) {
    $sessionResults.Add((Invoke-OneReadOnlySession -SessionIndex $sessionIndex -Settings $settings -Vivado $vivado -SessionTcl $sessionTcl -EvidenceDirectory $evidenceDir -TimeoutSeconds $SessionTimeoutSeconds))
}

$failures = [Collections.Generic.List[string]]::new()
$allRows = [Collections.Generic.List[object]]::new()
foreach ($result in $sessionResults) {
    if (-not $result.Started) { $failures.Add("session $($result.SessionIndex) did not start") }
    if ($result.TimedOut) { $failures.Add("session $($result.SessionIndex) timed out") }
    if ($null -eq $result.ExitCode -or $result.ExitCode -ne 0) {
        $failures.Add("session $($result.SessionIndex) exit code was not zero")
    }
    if (-not (Test-Path -LiteralPath $result.CsvPath -PathType Leaf)) {
        $failures.Add("session $($result.SessionIndex) matrix is missing")
        continue
    }
    $sessionRows = @(Import-Csv -LiteralPath $result.CsvPath)
    if ($sessionRows.Count -ne 5) {
        $failures.Add("session $($result.SessionIndex) has $($sessionRows.Count) samples, expected 5")
    }
    foreach ($row in $sessionRows) { $allRows.Add($row) }

    $expectedIndices = @('1','2','3','4','5')
    $actualIndices = @($sessionRows | ForEach-Object sample_index)
    if (($actualIndices -join ',') -cne ($expectedIndices -join ',')) {
        $failures.Add("session $($result.SessionIndex) sample indices are not 1..5")
    }
    [long]$previousMonotonic = -1
    foreach ($row in $sessionRows) {
        [long]$currentMonotonic = 0
        if (-not [long]::TryParse($row.monotonic_ms, [ref]$currentMonotonic) -or
            ($previousMonotonic -ge 0 -and $currentMonotonic -le $previousMonotonic)) {
            $failures.Add("session $($result.SessionIndex) monotonic timestamps are invalid")
            break
        }
        $previousMonotonic = $currentMonotonic
    }
    foreach ($propertyPath in @($result.TargetPropertiesPath, $result.DevicePropertiesPath)) {
        if (-not (Test-Path -LiteralPath $propertyPath -PathType Leaf)) {
            $failures.Add("session $($result.SessionIndex) property evidence is missing: $propertyPath")
        } elseif ((Get-Item -LiteralPath $propertyPath).Length -eq 0) {
            $failures.Add("session $($result.SessionIndex) property evidence is empty: $propertyPath")
        }
    }
}

if ($allRows.Count -ne 10) {
    $failures.Add("aggregate sample count is $($allRows.Count), expected 10")
}

foreach ($row in $allRows) {
    if ([string]$row.target_count -cne '1' -or [string]$row.device_count -cne '1') {
        $failures.Add("session $($row.session_index) sample $($row.sample_index) target/device count mismatch")
    }
    if ([string]$row.canonical_id -cne $expectedCanonicalId -or
        [string]$row.target_path -cne $expectedFullTargetPath -or
        [string]$row.part -cne $expectedPart -or
        ([string]$row.idcode).ToUpperInvariant() -cne $expectedIdcode) {
        $failures.Add("session $($row.session_index) sample $($row.sample_index) identity mismatch")
    }
    if ([string]$row.refresh_result -cne 'PASS') {
        $failures.Add("session $($row.session_index) sample $($row.sample_index) refresh failed")
    }
    if ([string]$row.done -notin @('0','1')) {
        $failures.Add("session $($row.session_index) sample $($row.sample_index) DONE unreadable")
    }
}

$targetPaths = @($allRows | ForEach-Object target_path | Sort-Object -Unique)
$canonicalIds = @($allRows | ForEach-Object canonical_id | Sort-Object -Unique)
$serverEndpoints = @($allRows | ForEach-Object server_endpoint | Sort-Object -Unique)
$transportClasses = @($allRows | ForEach-Object transport_class | Sort-Object -Unique)
$doneValues = @($allRows | ForEach-Object done | Sort-Object -Unique)
if ($targetPaths.Count -ne 1 -or $targetPaths[0] -cne $expectedFullTargetPath) {
    $failures.Add('full selected target path is not stable and exact across all samples')
}
if ($canonicalIds.Count -ne 1 -or $canonicalIds[0] -cne $expectedCanonicalId) { $failures.Add('canonical target ID is not stable and exact') }
if ($serverEndpoints.Count -ne 1) { $failures.Add('JTAG server endpoint is not stable') }
if ($transportClasses.Count -ne 1 -or $transportClasses[0] -cne 'xilinx_tcf') { $failures.Add('JTAG transport class is not stable and exact') }
if ($doneValues.Count -ne 1 -or $doneValues[0] -notin @('0','1')) { $failures.Add('DONE is not stable and readable across all samples') }

$frequencyRows = [Collections.Generic.List[string]]::new()
foreach ($result in $sessionResults) {
    if (Test-Path -LiteralPath $result.TargetPropertiesPath -PathType Leaf) {
        foreach ($line in [IO.File]::ReadAllLines($result.TargetPropertiesPath)) {
            if ($line -match '(?i)FREQUENCY') { $frequencyRows.Add($line) }
        }
    }
}
$frequencyReported = if ($frequencyRows.Count -eq 0) {'NOT_EXPOSED'} else {($frequencyRows | Sort-Object -Unique) -join ';'}

if ($allRows.Count -gt 0) {
    $allRows.ToArray() | Export-Csv -LiteralPath $combinedMatrixPath -NoTypeInformation -Encoding utf8NoBOM
} else {
    Write-Utf8NoBom -Path $combinedMatrixPath -Lines @('session_index,sample_index,monotonic_ms,utc,target_count,device_count,target_path,canonical_id,server_endpoint,transport_class,part,idcode,done,refresh_result')
}

$uniqueFailures = @($failures | Sort-Object -Unique)
$gatePassed = $uniqueFailures.Count -eq 0
$gateLines = [string[]]@(
    '# R6 selected-JTAG transport-stability gate',
    '',
    ('READ_ONLY_JTAG_STABILITY_SESSIONS={0}' -f $sessionResults.Count),
    'JTAG_REFRESH_SAMPLES_PER_SESSION=5',
    ('JTAG_STABILITY_SAMPLES={0}' -f $allRows.Count),
    ('R6_SELECTED_JTAG_CANONICAL_ID={0}' -f $(if ($canonicalIds.Count -eq 1) {$canonicalIds[0]} else {'UNSTABLE_OR_UNAVAILABLE'})),
    ('R6_FULL_JTAG_TARGET_PATH={0}' -f $(if ($targetPaths.Count -eq 1) {$targetPaths[0]} else {'UNSTABLE_OR_UNAVAILABLE'})),
    ('R6_JTAG_SERVER_ENDPOINT={0}' -f $(if ($serverEndpoints.Count -eq 1) {$serverEndpoints[0]} else {'UNSTABLE_OR_UNAVAILABLE'})),
    ('R6_JTAG_TRANSPORT_CLASS={0}' -f $(if ($transportClasses.Count -eq 1) {$transportClasses[0]} else {'UNSTABLE_OR_UNAVAILABLE'})),
    ('R6_JTAG_FREQUENCY_REPORTED={0}' -f $frequencyReported),
    'R6_JTAG_FREQUENCY_CHANGED=NO',
    'LEGACY_HS2_REQUIRED=NO',
    ('JTAG_PRECHECK_DONE_VALUE={0}' -f $(if ($doneValues.Count -eq 1) {$doneValues[0]} else {'UNSTABLE_OR_UNREADABLE'})),
    'FPGA_PROGRAM_OPERATIONS=0',
    ('JTAG_TRANSPORT_STABILITY_GATE={0}' -f $(if ($gatePassed) {'PASS_10_OF_10'} else {'FAIL'})),
    '',
    'FAILURES:',
    $(if ($gatePassed) {'NONE'} else {($uniqueFailures -join [Environment]::NewLine)})
)
Write-Utf8NoBom -Path $gatePath -Lines $gateLines
$gateLines | Where-Object { $_ -match '^[A-Z0-9_]+=' }
if (-not $gatePassed) { exit 1 }
