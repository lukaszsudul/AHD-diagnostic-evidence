param(
    [ValidateRange(1, 895)]
    [int]$MaximumSeconds = 895,
    [int]$PollIntervalSeconds = 2
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Ip = '10.132.1.111'
$Port = 22
$Output = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906\raw\EXACT_IP_RECONNECT_MONITOR.csv'
$Summary = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906\raw\EXACT_IP_RECONNECT_SUMMARY.json'
$ControllerReceipt = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'

if (Test-Path -LiteralPath $Output) { throw 'RECONNECT_MONITOR_OUTPUT_EXISTS' }
if (Test-Path -LiteralPath $Summary) { throw 'RECONNECT_MONITOR_SUMMARY_EXISTS' }

function Test-ExactTcpPort {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $pending = $client.BeginConnect($Ip, $Port, $null, $null)
        if (-not $pending.AsyncWaitHandle.WaitOne(1000)) { return $false }
        $client.EndConnect($pending)
        return $true
    }
    catch { return $false }
    finally { $client.Dispose() }
}

'sample,utc,elapsed_seconds,ssh_tcp_22,controller_lock' | Set-Content -LiteralPath $Output -Encoding utf8
$watch = [System.Diagnostics.Stopwatch]::StartNew()
$sample = 0
$sawDown = $false
$sawUpAfterDown = $false
$firstDownUtc = $null
$firstUpAfterDownUtc = $null
$lastState = $null

while ($watch.Elapsed.TotalSeconds -le $MaximumSeconds) {
    $sample++
    $utc = (Get-Date).ToUniversalTime().ToString('o')
    if (-not (Test-Path -LiteralPath $ControllerReceipt -PathType Leaf)) {
        throw 'CONTROLLER_LOCK_LOST_DURING_REBOOT'
    }
    $lock = Get-Content -LiteralPath $ControllerReceipt -Raw | ConvertFrom-Json
    if ($lock.task -ne 'G2B-HW0-PRODUCT-R2' -or
        $lock.state -ne 'HELD' -or
        -not [bool]$lock.reboot_budget_consumed -or
        [int]$lock.remote_reboot_command_delivery_attempts -ne 1 -or
        [int]$lock.remote_reboot_command_deliveries -ne 1 -or
        [int]$lock.warm_reboots_executed -ne 0 -or
        $lock.remote_reboot_command_status -ne 'SCHEDULE_ACKNOWLEDGED_NO_RETRY') {
        throw 'CONTROLLER_LOCK_STATE_INVALID_DURING_REBOOT'
    }
    $up = Test-ExactTcpPort
    $state = if ($up) { 'UP' } else { 'DOWN' }
    "$sample,$utc,$([Math]::Round($watch.Elapsed.TotalSeconds,3)),$state,HELD" | Add-Content -LiteralPath $Output -Encoding utf8

    if (-not $up -and -not $sawDown) {
        $sawDown = $true
        $firstDownUtc = $utc
        Write-Output "SSH_DISCONNECT_OBSERVED_UTC=$utc"
    }
    if ($up -and $sawDown) {
        $sawUpAfterDown = $true
        $firstUpAfterDownUtc = $utc
        Write-Output "SSH_TCP_RECONNECT_OBSERVED_UTC=$utc"
        break
    }
    if ($state -ne $lastState -or ($sample % 5) -eq 0) {
        Write-Output "RECONNECT_MONITOR elapsed=$([Math]::Round($watch.Elapsed.TotalSeconds,1)) state=$state lock=HELD"
    }
    $lastState = $state
    Start-Sleep -Seconds $PollIntervalSeconds
}
$watch.Stop()

$result = if ($sawDown -and $sawUpAfterDown) { 'PASS' } else { 'TIMEOUT' }
$summaryData = [ordered]@{
    task = 'G2B-HW0-PRODUCT-R2'
    result = $result
    exact_ip = $Ip
    port = $Port
    maximum_seconds = $MaximumSeconds
    elapsed_seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 3)
    samples = $sample
    ssh_disconnect_observed = $sawDown
    first_down_utc = $firstDownUtc
    tcp_reconnect_observed = $sawUpAfterDown
    first_up_after_down_utc = $firstUpAfterDownUtc
    controller_lock_held_through_monitor = $true
    remote_reboot_command_delivery_attempts = 1
    remote_reboot_command_deliveries = 1
    warm_reboots_executed = 0
    warm_reboot_execution_confirmation = 'PENDING_AUTHENTICATED_BOOT_ID_CHANGE'
    second_reboot_attempted = $false
}
$summaryData | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $Summary -Encoding utf8
Write-Output "RECONNECT_MONITOR_RESULT=$result"
Write-Output "RECONNECT_MONITOR_ELAPSED_SECONDS=$($summaryData.elapsed_seconds)"
if ($result -ne 'PASS') { exit 2 }
