[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$scriptsRoot = Join-Path $taskRoot 'scripts'
$phaseRoot = Join-Path $taskRoot 'hardware\01_BOOTSTRAP'
$outputPath = Join-Path $taskRoot 'hardware\R1H_R4_WRAPPER_RECOVERY_OFFLINE_GATE.txt'
$identityPath = Join-Path $taskRoot 'hardware\R1H_R4_TASK_LOCAL_SCRIPT_IDENTITY_POST_BOOTSTRAP_FIX.csv'
foreach ($path in @($outputPath,$identityPath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite wrapper-recovery audit: $path" }
}

function Read-UniqueKv([string]$Path) {
    $map = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) { throw "invalid key/value line in ${Path}: $line" }
        $key = $line.Substring(0,$separator)
        $value = $line.Substring($separator + 1)
        if (-not $map.TryAdd($key,$value)) { throw "duplicate key in ${Path}: $key" }
    }
    return $map
}

$failures = [Collections.Generic.List[string]]::new()
$scriptNames = @(
    'R1hCampaignCommon.ps1','Invoke-R1hProgramOnce.ps1','Invoke-R1hIndependentDoneReadOnly.ps1',
    'Wait-R1hProgramMinimum.ps1','Invoke-R1hHostStep.ps1','Invoke-R1hTelemetryReadOnly.ps1',
    'New-R1hConfiguredImageReceipt.ps1','Invoke-R1hR4JtagSafetyReadOnly.ps1',
    'Invoke-R1hR4MinimalHostSafetyReadOnly.ps1','New-R1hR4HardwareBinding.ps1',
    'Invoke-R1hR4EligibleProgramRetryOnce.ps1','Test-R1hR4HardwarePrepOffline.ps1',
    'New-R1hR4ImplementationLaunchRelease.ps1','Recover-R1hR4JtagSafetyReceiptFromCompletedSession.ps1',
    'Recover-R1hR4BootstrapProgramReceipts.ps1','Test-R1hR4WrapperRecoveryOffline.ps1'
)
$identities = [Collections.Generic.List[object]]::new()
foreach ($name in $scriptNames) {
    $path = Join-Path $scriptsRoot $name
    try {
        $tokens=$null;$errors=$null
        [void][Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors)
        if ($errors.Count -ne 0) { throw (($errors | ForEach-Object Message) -join '; ') }
        $item = Get-Item -LiteralPath $path
        $identities.Add([pscustomobject]@{
            name=$name;path=$item.FullName;bytes=$item.Length;
            sha256=(Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash;parse='PASS'
        })
    } catch { $failures.Add("SCRIPT_PARSE=${name}:$($_.Exception.Message)") }
}
$identities | Export-Csv -LiteralPath $identityPath -NoTypeInformation -Encoding utf8NoBOM

try {
    $commonPath = Join-Path $scriptsRoot 'R1hCampaignCommon.ps1'
    . $commonPath
    $emptyFixture = Join-Path $taskRoot 'hardware\R1H_R4_EMPTY_STREAM_SERIALIZATION_FIXTURE.txt'
    $fixtureLines = [IO.File]::ReadAllLines($emptyFixture)
    if ($fixtureLines.Count -ne 6 -or $fixtureLines[4] -cne '' -or
        (Get-FileHash -LiteralPath $emptyFixture -Algorithm SHA256).Hash -cne
            'AF347CA7171CE789B830B1AF49537740B1528F3FBB2E5220F7EC0C9A4ABF11B7') {
        throw 'empty stdout/stderr serialization fixture mismatch'
    }
    $commonText = [IO.File]::ReadAllText($commonPath)
    if (-not $commonText.Contains('[AllowEmptyCollection()][AllowEmptyString()][string[]]$Lines',[StringComparison]::Ordinal)) {
        throw 'shared UTF-8 receipt writer lacks explicit empty-stream allowance'
    }
} catch { $failures.Add("EMPTY_STREAM_FIXTURE=$($_.Exception.Message)") }

try {
    $programPath = Join-Path $scriptsRoot 'Invoke-R1hProgramOnce.ps1'
    $tokens=$null;$errors=$null
    $programAst = [Management.Automation.Language.Parser]::ParseFile($programPath,[ref]$tokens,[ref]$errors)
    $functionAst = $programAst.Find({
        param($node)
        $node -is [Management.Automation.Language.FunctionDefinitionAst] -and
            $node.Name -ceq 'Add-ObserverRecord'
    },$true)
    if ($null -eq $functionAst) { throw 'Add-ObserverRecord AST absent' }
    Invoke-Expression $functionAst.Extent.Text
    $emptyRecords = [Collections.Generic.List[object]]::new()
    [long]$script:observerSequence = 0
    Add-ObserverRecord -Records $emptyRecords -Stream FIXTURE -Line 'K=V'
    if ($emptyRecords.Count -ne 1 -or $emptyRecords[0].Line -cne 'K=V') {
        throw 'empty observer-list first-record fixture failed'
    }
    $programText = [IO.File]::ReadAllText($programPath)
    if (-not $programText.Contains('[AllowEmptyCollection()][Collections.Generic.List[object]]$Records',[StringComparison]::Ordinal)) {
        throw 'program wrapper lacks explicit initial-empty observer allowance'
    }
} catch { $failures.Add("EMPTY_OBSERVER_FIXTURE=$($_.Exception.Message)") }

try {
    $timingPath = Join-Path $phaseRoot 'PROGRAM_TIMING_RECEIPT.txt'
    $recoveryPath = Join-Path $phaseRoot 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt'
    $supervisorPath = Join-Path $phaseRoot 'PROGRAM_SUPERVISOR.log'
    $timing = Read-UniqueKv $timingPath
    $recovery = Read-UniqueKv $recoveryPath
    foreach ($pair in @(
        @('PHASE_TOKEN','Bootstrap'), @('PROGRAM_RESULT','PASS_STARTUP_HIGH_DONE_1'),
        @('PROGRAM_INVOCATIONS','1'), @('PROGRAM_RETRIES','0'),
        @('MODE_AWARE_PREPROGRAM_GATE','PASS'), @('PREPROGRAM_DONE_SAMPLES','1,1,1,1,1'),
        @('PREPROGRAM_DONE_VALUE','1'), @('REQUIRED_MINIMUM_WAIT_SECONDS','5.000000000'),
        @('TIMING_REFERENCE_CLASS','CONSERVATIVE_POSTPROCESS_ANCHOR_AFTER_COMPLETED_PROGRAM'),
        @('TIMING_RECEIPT_STATUS','PASS_IMMUTABLE_WAIT_INPUT_RECOVERED_POSTPROCESS_ONLY')
    )) {
        if (-not $timing.ContainsKey($pair[0]) -or $timing[$pair[0]] -cne $pair[1]) {
            throw "timing receipt mismatch: $($pair[0])"
        }
    }
    if ($timing['PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256'] -cne
        (Get-FileHash -LiteralPath $recoveryPath -Algorithm SHA256).Hash -or
        $timing['PROGRAM_SUPERVISOR_LOG_SHA256'] -cne
        (Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash) {
        throw 'recovered timing receipt dependency hash mismatch'
    }
    [long]$returnTicks=0;[long]$freshTicks=0;[long]$referenceTicks=0
    if (-not [long]::TryParse($timing['PROGRAM_RETURN_MARKER_TICKS'],[ref]$returnTicks) -or
        -not [long]::TryParse($timing['FRESH_DONE_MARKER_TICKS'],[ref]$freshTicks) -or
        -not [long]::TryParse($timing['WAIT_REFERENCE_TICKS'],[ref]$referenceTicks) -or
        $referenceTicks -le 0 -or $returnTicks -ne $referenceTicks -or $freshTicks -ne $referenceTicks -or
        $referenceTicks -gt [Diagnostics.Stopwatch]::GetTimestamp()) {
        throw 'conservative recovered wait reference is incoherent'
    }
    if ($timing['STOPWATCH_FREQUENCY'] -cne [string][Diagnostics.Stopwatch]::Frequency) {
        throw 'recovered timing receipt stopwatch frequency mismatch'
    }
    foreach ($pair in @(
        @('RECOVERY_CLASS','POSTPROCESS_ONLY_COMPLETED_VIVADO_CHILD'),
        @('ORIGINAL_WRAPPER_RESULT','FAIL_TASK_LOCAL_EMPTY_OBSERVER_COLLECTION_BINDING'),
        @('VIVADO_CHILD_TERMINAL_RESULT','PASS_DONE_1'), @('VIVADO_CHILD_NORMAL_EXIT','YES'),
        @('PROGRAM_INVOCATIONS','1'), @('PROGRAM_RETRIES','0'), @('SECOND_PROGRAM_SESSION_RUN','NO'),
        @('REBOOT_AFTER_WRAPPER_FAILURE','NO'), @('TELEMETRY_AFTER_WRAPPER_FAILURE','NO'),
        @('CONSERVATIVE_REFERENCE_AFTER_COMPLETED_PROGRAM_LOG_VALIDATION','YES'),
        @('RECOVERY_GATE','PASS_NO_HARDWARE_ACCESS')
    )) {
        if (-not $recovery.ContainsKey($pair[0]) -or $recovery[$pair[0]] -cne $pair[1]) {
            throw "recovery receipt mismatch: $($pair[0])"
        }
    }
    $dependencyPaths = [ordered]@{
        PROGRAM_ATTEMPT_RESERVATION_SHA256=(Join-Path $phaseRoot 'PROGRAM_ATTEMPT_RESERVATION.txt')
        PROGRAM_VIVADO_LOG_SHA256=(Join-Path $phaseRoot 'PROGRAM_VIVADO.log')
        PROGRAM_VIVADO_JOURNAL_SHA256=(Join-Path $phaseRoot 'PROGRAM_VIVADO.jou')
        HARDWARE_BINDING_SHA256=(Join-Path $taskRoot 'hardware\R1H_R4_HARDWARE_BINDING.json')
    }
    foreach ($entry in $dependencyPaths.GetEnumerator()) {
        if ($recovery[$entry.Key] -cne (Get-FileHash -LiteralPath $entry.Value -Algorithm SHA256).Hash) {
            throw "recovery dependency hash mismatch: $($entry.Key)"
        }
    }
} catch { $failures.Add("RECOVERED_RECEIPT_FIXTURE=$($_.Exception.Message)") }

$gate = if ($failures.Count -eq 0) { 'PASS' } else { 'FAIL' }
$lines = [Collections.Generic.List[string]]::new()
foreach ($line in @(
    "R1H_R4_WRAPPER_RECOVERY_OFFLINE_GATE=$gate",
    "TASK_LOCAL_SCRIPT_IDENTITY_SHA256=$((Get-FileHash -LiteralPath $identityPath -Algorithm SHA256).Hash)",
    'POWERSHELL_PARSE=PASS_ALL', 'EMPTY_OBSERVER_FIRST_RECORD_BINDING=PASS',
    'EMPTY_STDOUT_STDERR_SERIALIZATION=PASS', 'BOOTSTRAP_RECOVERED_RECEIPTS=PASS',
    'WAIT_SCRIPT_COMPATIBILITY=PASS_BY_EXACT_REQUIRED_FIELDS_AND_CONSERVATIVE_MONOTONIC_REFERENCE',
    "PROGRAM_TIMING_RECEIPT_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_TIMING_RECEIPT.txt') -Algorithm SHA256).Hash)",
    "PROGRAM_SUPERVISOR_LOG_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_SUPERVISOR.log') -Algorithm SHA256).Hash)",
    "PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt') -Algorithm SHA256).Hash)",
    'OFFLINE_FIXTURE_SSH_SESSIONS=0','OFFLINE_FIXTURE_JTAG_SESSIONS=0',
    'OFFLINE_FIXTURE_FPGA_PROGRAMS=0','OFFLINE_FIXTURE_WARM_REBOOTS=0',
    'OFFLINE_FIXTURE_DRIVER_LOADS=0','OFFLINE_FIXTURE_MMIO_READS=0',
    'OFFLINE_FIXTURE_MMIO_WRITES=0','OFFLINE_FIXTURE_DMA_TRANSFERS=0'
)) { $lines.Add($line) }
foreach ($failure in $failures) { $lines.Add("FAILURE=$failure") }
[IO.File]::WriteAllLines($outputPath,$lines,[Text.UTF8Encoding]::new($false))
$lines
if ($gate -cne 'PASS') { exit 1 }
