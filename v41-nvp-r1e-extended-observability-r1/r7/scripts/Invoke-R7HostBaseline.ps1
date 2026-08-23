[CmdletBinding()]
param(
    [string]$PlinkPath = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe',
    [ValidateRange(3.0, 30.0)]
    [double]$MinimumSpanSeconds = 3.0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$scriptRoot = Join-Path $taskRoot 'scripts'
$outputRoot = Join-Path $taskRoot '04_HOST_BASELINE'
$helperPath = Join-Path $scriptRoot 'Invoke-ContextualPlink.ps1'
$samplePath = Join-Path $scriptRoot 'r7_host_baseline_sample_readonly.sh'
$matrixPath = Join-Path $outputRoot 'R7_HOST_BASELINE_MATRIX.csv'
$gatePath = Join-Path $outputRoot 'R7_HOST_BASELINE_GATE.md'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
$expectedSampleSha = '0C49C3FB9192E40F53285844343BAA7AC6EE1801798C62627A6C45EAC718D730'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$expectedUser = 'vcdeagent1'
$expectedKernel = '7.0.0-29-generic'

function Assert-ExactFileHash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "required file missing: $Path" }
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) { throw "SHA-256 mismatch for $Path`: $actual" }
}

function ConvertTo-GzipBase64([byte[]]$Bytes) {
    $output = [IO.MemoryStream]::new()
    try {
        $gzip = [IO.Compression.GzipStream]::new($output, [IO.Compression.CompressionLevel]::Optimal, $true)
        try { $gzip.Write($Bytes, 0, $Bytes.Length) } finally { $gzip.Dispose() }
        return [Convert]::ToBase64String($output.ToArray())
    } finally { $output.Dispose() }
}

function Get-ExactValue([string]$Text, [string]$Key) {
    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

function Wait-UntilTick([long]$TargetTick) {
    while ([Diagnostics.Stopwatch]::GetTimestamp() -lt $TargetTick) { Start-Sleep -Milliseconds 25 }
}

Assert-ExactFileHash $PlinkPath $expectedPlinkSha
Assert-ExactFileHash $helperPath $expectedHelperSha
Assert-ExactFileHash $samplePath $expectedSampleSha
if (-not (Test-Path -LiteralPath $outputRoot -PathType Container)) { throw '04_HOST_BASELINE evidence directory missing' }

$sessionPaths = 1..2 | ForEach-Object { Join-Path $outputRoot ("HOST_BASELINE_SESSION_{0}.log" -f $_) }
foreach ($path in @($sessionPaths + @($matrixPath, $gatePath))) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite R7 host-baseline evidence: $path" }
}

$sampleSha = $expectedSampleSha
$samplePayload = ConvertTo-GzipBase64 ([IO.File]::ReadAllBytes($samplePath))
$remoteTemplate = 'sudo -S -k -p '''' /usr/bin/bash -c ''printf %s "$1" | /usr/bin/base64 -d | /usr/bin/gzip -dc | /usr/bin/bash -s -- "$2"'' _ ''{0}'' ''{1}'''
$frequency = [Diagnostics.Stopwatch]::Frequency
$records = [Collections.Generic.List[object]]::new()
$failures = [Collections.Generic.List[string]]::new()
$firstCompletionTick = 0L

for ($session = 1; $session -le 2; $session++) {
    if ($session -eq 2) {
        Wait-UntilTick ($firstCompletionTick + [long][Math]::Ceiling(($MinimumSpanSeconds + 0.250) * $frequency))
    }
    $remoteCommand = $remoteTemplate -f $samplePayload, $session
    $startTick = [Diagnostics.Stopwatch]::GetTimestamp()
    & $helperPath `
        -PlinkPath $PlinkPath `
        -HostKey $hostKey `
        -RemoteCommand $remoteCommand `
        -EvidencePath $sessionPaths[$session - 1] `
        -ExpectedIp '10.132.1.111' `
        -ExpectedUser $expectedUser `
        -EvidenceKind ("R7_HOST_BASELINE_SESSION_{0}" -f $session) `
        -SendPasswordToStdin `
        -SudoPasswordCopies 1 `
        -TimeoutSeconds 90
    $helperExit = $LASTEXITCODE
    $endTick = [Diagnostics.Stopwatch]::GetTimestamp()
    if ($session -eq 1) { $firstCompletionTick = $endTick }

    $evidence = [IO.File]::ReadAllText($sessionPaths[$session - 1])
    try {
        $result = Get-ExactValue $evidence 'RESULT'
        $remoteExit = Get-ExactValue $evidence 'EXIT_CODE'
        $sampleIndex = Get-ExactValue $evidence 'HOST_BASELINE_SAMPLE_INDEX'
        $hostname = Get-ExactValue $evidence 'HOSTNAME'
        $user = Get-ExactValue $evidence 'REMOTE_USER'
        $effectiveUser = Get-ExactValue $evidence 'REMOTE_EFFECTIVE_USER'
        $kernel = Get-ExactValue $evidence 'CURRENT_KERNEL'
        $bootId = Get-ExactValue $evidence 'CURRENT_BOOT_ID'
        $uptimeText = Get-ExactValue $evidence 'UPTIME_SECONDS'
        $remoteUtc = Get-ExactValue $evidence 'REMOTE_UTC'
        $nextKernel = Get-ExactValue $evidence 'NEXT_REBOOT_KERNEL_PROVEN'
        $sampleGate = Get-ExactValue $evidence 'HOST_BASELINE_SAMPLE_GATE'
        $readOnly = Get-ExactValue $evidence 'HOST_BASELINE_SAMPLE_READ_ONLY'
        $uptime = [double]::Parse($uptimeText, [Globalization.CultureInfo]::InvariantCulture)
    } catch {
        $failures.Add("SESSION_${session}_PARSE=$($_.Exception.Message)")
        $result = 'PARSE_FAIL'; $remoteExit = 'UNKNOWN'; $sampleIndex = 'UNKNOWN'
        $hostname = 'UNKNOWN'; $user = 'UNKNOWN'; $effectiveUser = 'UNKNOWN'; $kernel = 'UNKNOWN'
        $bootId = 'UNKNOWN'; $uptimeText = 'NaN'; $uptime = [double]::NaN
        $remoteUtc = 'UNKNOWN'; $nextKernel = 'UNKNOWN'; $sampleGate = 'PARSE_FAIL'; $readOnly = 'UNKNOWN'
    }
    if ($helperExit -ne 0 -or $result -cne 'PASS' -or $remoteExit -cne '0' -or
        $sampleIndex -cne [string]$session -or $sampleGate -cne 'PASS' -or $readOnly -cne 'YES') {
        $failures.Add("SESSION_${session}_EXECUTION_OR_GATE")
    }
    $records.Add([pscustomobject]@{
        Session = $session; LocalStartTick = $startTick; LocalEndTick = $endTick
        RemoteUtc = $remoteUtc; Hostname = $hostname; User = $user; EffectiveUser = $effectiveUser
        Kernel = $kernel; BootId = $bootId; UptimeText = $uptimeText; Uptime = $uptime
        NextKernel = $nextKernel; HelperExit = $helperExit; Result = $result
    })
}

$first = $records[0]; $second = $records[1]
if ($records.Count -ne 2) { $failures.Add("SESSION_COUNT=$($records.Count)") }
if ($first.Hostname -eq 'UNKNOWN' -or $first.Hostname -cne $second.Hostname) { $failures.Add('HOSTNAME_STABILITY') }
if ($first.User -cne $expectedUser -or $second.User -cne $expectedUser) { $failures.Add('USER_STABILITY') }
if ($first.EffectiveUser -cne 'root' -or $second.EffectiveUser -cne 'root') { $failures.Add('PRIVILEGED_READ_ONLY_CONTEXT') }
if ($first.Kernel -cne $expectedKernel -or $second.Kernel -cne $expectedKernel) { $failures.Add('KERNEL_STABILITY') }
if ($first.NextKernel -cne $expectedKernel -or $second.NextKernel -cne $expectedKernel) { $failures.Add('NEXT_REBOOT_KERNEL_GATE') }
if ($first.BootId -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' -or
    $first.BootId -cne $second.BootId) { $failures.Add('BOOT_ID_STABILITY') }
if (-not ($second.Uptime -gt $first.Uptime)) { $failures.Add('UPTIME_NOT_STRICTLY_MONOTONIC') }
$remoteSpan = $second.Uptime - $first.Uptime
$localSpan = [double]($second.LocalEndTick - $first.LocalStartTick) / $frequency
if ($remoteSpan -lt $MinimumSpanSeconds) { $failures.Add("REMOTE_UPTIME_SPAN=$remoteSpan") }
if ($localSpan -lt $MinimumSpanSeconds) { $failures.Add("LOCAL_MONOTONIC_SPAN=$localSpan") }

$csv = [Collections.Generic.List[string]]::new()
$csv.Add('session_index,local_start_tick,local_end_tick,remote_utc,hostname,user,effective_user,kernel,boot_id,uptime_seconds,next_reboot_kernel,helper_exit,result')
foreach ($record in $records) {
    $csv.Add(('{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12}' -f
        $record.Session,$record.LocalStartTick,$record.LocalEndTick,$record.RemoteUtc,$record.Hostname,
        $record.User,$record.EffectiveUser,$record.Kernel,$record.BootId,$record.UptimeText,
        $record.NextKernel,$record.HelperExit,$record.Result))
}
[IO.File]::WriteAllLines($matrixPath, $csv, [Text.UTF8Encoding]::new($false))

$gate = if ($failures.Count -eq 0) { 'PASS_2_OF_2' } else { 'FAIL' }
$gateLines = [Collections.Generic.List[string]]::new()
$gateLines.Add('# R7 fresh Ubuntu baseline gate')
$gateLines.Add('')
$gateLines.Add("HOST_SAMPLE_PAYLOAD_SHA256=$sampleSha")
$gateLines.Add('READ_ONLY_SSH_SESSIONS=2')
$gateLines.Add("R7_BOOT_ID_BASELINE=$($first.BootId)")
$gateLines.Add("REMOTE_UPTIME_SPAN_SECONDS=$($remoteSpan.ToString('F6',[Globalization.CultureInfo]::InvariantCulture))")
$gateLines.Add("LOCAL_MONOTONIC_SPAN_SECONDS=$($localSpan.ToString('F6',[Globalization.CultureInfo]::InvariantCulture))")
$gateLines.Add("NEXT_REBOOT_KERNEL_PROVEN=$($first.NextKernel)")
$gateLines.Add("R7_HOST_BASELINE=$gate")
$gateLines.Add('NO_OBSERVED_REBOOT_OR_SHUTDOWN=' + $(if ($gate -eq 'PASS_2_OF_2') {'YES'} else {'NOT_PROVEN'}))
foreach ($failure in $failures) { $gateLines.Add("FAILURE=$failure") }
[IO.File]::WriteAllLines($gatePath, $gateLines, [Text.UTF8Encoding]::new($false))
$gateLines | Select-Object -Skip 2
if ($gate -cne 'PASS_2_OF_2') { exit 1 }
exit 0
