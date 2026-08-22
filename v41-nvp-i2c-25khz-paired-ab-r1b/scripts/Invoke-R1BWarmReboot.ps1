[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RebootEvidencePath,
    [Parameter(Mandatory)][string]$MonitorEvidencePath,
    [ValidateRange(60,600)][int]$ReturnTimeoutSeconds = 240
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$plink = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$helper = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\R1B_SECRET_CHANNEL\Invoke-ContextualPlink.ps1'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$ip = '10.132.1.111'
$user = 'vcdeagent1'
$expectedPlinkSha = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$expectedHelperSha = '8DB31E3C7FFF642EC4B2643A9C44317B5BC711558F0692C97335248BF154378D'

if ((Get-FileHash -LiteralPath $plink -Algorithm SHA256).Hash -cne $expectedPlinkSha) {
    throw 'Plink identity mismatch'
}
if ((Get-FileHash -LiteralPath $helper -Algorithm SHA256).Hash -cne $expectedHelperSha) {
    throw 'credential helper identity mismatch'
}
foreach ($fresh in @($RebootEvidencePath,$MonitorEvidencePath)) {
    if (Test-Path -LiteralPath $fresh) { throw "evidence path must be fresh: $fresh" }
}

function Test-SshReachable {
    param([string]$Address)
    $client = [Net.Sockets.TcpClient]::new()
    try {
        $async = $client.BeginConnect($Address,22,$null,$null)
        if (-not $async.AsyncWaitHandle.WaitOne(750)) { return $false }
        $client.EndConnect($async)
        return $true
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

$submitTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$submitUtc = [DateTime]::UtcNow.ToString('o')
& $helper -PlinkPath $plink -HostKey $hostKey `
    -RemoteCommand "sudo -S -p '' /usr/sbin/reboot" `
    -EvidencePath $RebootEvidencePath -ExpectedIp $ip -ExpectedUser $user `
    -EvidenceKind 'R1B_WARM_REBOOT' -SendPasswordToStdin -SudoPasswordCopies 1 `
    -TimeoutSeconds 30
$helperExit = $LASTEXITCODE

$records = [Collections.Generic.List[string]]::new()
$records.Add(('REBOOT_SUBMISSION_UTC={0}' -f $submitUtc))
$records.Add(('REBOOT_SUBMISSION_TICKS={0}' -f $submitTicks))
$records.Add('WARM_REBOOT_INVOCATION_CONSUMED=1')
$records.Add(('REBOOT_HELPER_EXIT_CODE={0}' -f $helperExit))
$records.Add(('STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency))

$deadline = [DateTime]::UtcNow.AddSeconds($ReturnTimeoutSeconds)
$downSeen = $false
$upAfterDown = $false
$downTicks = -1L
$upTicks = -1L
while ([DateTime]::UtcNow -lt $deadline) {
    $nowTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $reachable = Test-SshReachable -Address $ip
    $records.Add(('POLL_TICKS={0} SSH_PORT_22={1}' -f $nowTicks,$(if ($reachable) {'UP'} else {'DOWN'})))
    if (-not $reachable -and -not $downSeen) {
        $downSeen = $true
        $downTicks = $nowTicks
    }
    if ($downSeen -and $reachable) {
        $upAfterDown = $true
        $upTicks = $nowTicks
        break
    }
    Start-Sleep -Milliseconds 500
}

$records.Add(('HOST_DISAPPEARANCE_OBSERVED={0}' -f $(if ($downSeen) {'YES'} else {'NO'})))
$records.Add(('HOST_RETURN_AFTER_DISAPPEARANCE={0}' -f $(if ($upAfterDown) {'YES'} else {'NO'})))
$records.Add(('HOST_DISAPPEARANCE_TICKS={0}' -f $downTicks))
$records.Add(('HOST_RETURN_TICKS={0}' -f $upTicks))
$records.Add(('REBOOT_MONITOR_RESULT={0}' -f $(if ($downSeen -and $upAfterDown) {'PASS'} else {'FAIL'})))
[IO.File]::WriteAllLines([IO.Path]::GetFullPath($MonitorEvidencePath),[string[]]$records,[Text.UTF8Encoding]::new($false))
$records

if (-not ($downSeen -and $upAfterDown)) { exit 2 }
exit 0
