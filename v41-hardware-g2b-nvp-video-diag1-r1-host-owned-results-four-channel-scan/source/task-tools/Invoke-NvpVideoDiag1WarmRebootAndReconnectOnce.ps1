[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-NVP-VIDEO-DIAG1-R1'
$root = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z'
$scriptRoot = Join-Path $root 'scripts'
$connectionHelper = Join-Path $scriptRoot 'Invoke-NvpVideoDiag1DutConnection.ps1'
$lockReceiptPath = 'C:\FPGA\.AHD_G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z.lock\receipt.json'
$programReceiptPath = Join-Path $root 'artifacts\programming-receipt.json'
$rebootReceiptPath = Join-Path $root 'artifacts\warm-reboot-receipt.json'
$deliveryConnectionReceipt = Join-Path $root 'logs\connection-warm-reboot-delivery.json'
$reconnectAttemptLimit = 2
$initialReconnectDelaySeconds = 15
$betweenReconnectDelaySeconds = 15
$reconnectTimeoutSeconds = 20

function Save-RebootReceipt {
  param([Parameter(Mandatory)][System.Collections.IDictionary]$Receipt)
  [IO.File]::WriteAllText(
    $rebootReceiptPath,
    ($Receipt | ConvertTo-Json -Depth 7) + [char]10,
    [Text.UTF8Encoding]::new($false)
  )
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne $scriptRoot) {
  throw 'NVP_DIAG1_R1_REBOOT_HELPER_LOCATION_INVALID'
}
foreach ($requiredFile in @(
    $connectionHelper,
    $lockReceiptPath,
    $programReceiptPath
  )) {
  if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
    throw "NVP_DIAG1_R1_REBOOT_REQUIRED_INPUT_MISSING:$requiredFile"
  }
}
if (
  (Test-Path -LiteralPath $rebootReceiptPath) -or
  (Test-Path -LiteralPath $deliveryConnectionReceipt)
) {
  throw 'NVP_DIAG1_R1_REBOOT_RECEIPT_EXISTS_NO_RETRY'
}

$lock = Get-Content -LiteralPath $lockReceiptPath -Raw | ConvertFrom-Json
if (
  $lock.task -cne $task -or
  $lock.run_root -cne $root -or
  $lock.state -cne 'HELD'
) {
  throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_OWNER_MISMATCH'
}
$programReceipt = Get-Content -LiteralPath $programReceiptPath -Raw |
  ConvertFrom-Json
if (
  $programReceipt.task -cne $task -or
  $programReceipt.result -cne 'PASS' -or
  -not [bool]$programReceipt.program_tcl_pass -or
  $programReceipt.delivery_attempt -ne 1 -or
  $programReceipt.programmed_storage -cne 'FPGA_SRAM_VOLATILE_ONLY'
) {
  throw 'NVP_DIAG1_R1_PROGRAMMING_NOT_PASS_REBOOT_DENIED'
}

$receipt = [ordered]@{
  task = $task
  start_utc = [DateTime]::UtcNow.ToString('o')
  programming_receipt_sha256 = (
    Get-FileHash -LiteralPath $programReceiptPath -Algorithm SHA256
  ).Hash
  graceful_warm_reboot_authorized = $true
  reboot_delivery_attempts = 1
  second_reboot_allowed = $false
  power_cycle_allowed = $false
  boot_id_read_or_compared = $false
  reconnect_attempt_limit = $reconnectAttemptLimit
  reconnect_timeout_seconds = $reconnectTimeoutSeconds
  reconnect_attempts = @()
  result = 'DELIVERY_PENDING_NO_RETRY'
}
Save-RebootReceipt -Receipt $receipt

$rebootCommand = @'
set -euo pipefail
test "$(id -u)" = "0"
test -x /usr/bin/systemd-run
test -x /usr/bin/systemctl
/usr/bin/systemd-run --unit=g2b-nvp-video-diag1-r1-warm-reboot --on-active=4s --timer-property=AccuracySec=1s --no-block /usr/bin/systemctl reboot
printf '%s\n' 'WARM_REBOOT_SCHEDULE_ACKNOWLEDGED=YES'
'@
$deliveryArguments = @{
  RemoteCommand = $rebootCommand
  ReceiptName = 'warm-reboot-delivery'
  Operation = 'WARM_REBOOT'
  Sudo = $true
  TimeoutSeconds = 30
}
try {
  & $connectionHelper @deliveryArguments | Out-Null
} catch {
  $receipt.result = 'DELIVERY_FAILED_OR_UNCERTAIN_NO_RETRY'
  $receipt.end_utc = [DateTime]::UtcNow.ToString('o')
  Save-RebootReceipt -Receipt $receipt
  throw 'NVP_DIAG1_R1_WARM_REBOOT_DELIVERY_FAILED_NO_RETRY'
}

$delivery = Get-Content -LiteralPath $deliveryConnectionReceipt -Raw |
  ConvertFrom-Json
if (
  $delivery.task -cne $task -or
  $delivery.operation -cne 'WARM_REBOOT' -or
  $delivery.exit_code -ne 0 -or
  $delivery.stdout -notmatch '(?m)^WARM_REBOOT_SCHEDULE_ACKNOWLEDGED=YES$'
) {
  $receipt.result = 'DELIVERY_ACK_INVALID_NO_RETRY'
  $receipt.end_utc = [DateTime]::UtcNow.ToString('o')
  Save-RebootReceipt -Receipt $receipt
  throw 'NVP_DIAG1_R1_WARM_REBOOT_ACK_INVALID_NO_RETRY'
}

$receipt.result = 'DELIVERY_ACKNOWLEDGED_RECONNECT_PENDING'
Save-RebootReceipt -Receipt $receipt
Start-Sleep -Seconds $initialReconnectDelaySeconds

$reconnected = $false
for ($attempt = 1; $attempt -le $reconnectAttemptLimit; $attempt++) {
  $receiptName = 'post-reboot-reconnect-{0:D2}' -f $attempt
  $attemptResult = [ordered]@{
    attempt = $attempt
    receipt_name = $receiptName
    start_utc = [DateTime]::UtcNow.ToString('o')
    result = 'PENDING'
  }
  try {
    $reconnectArguments = @{
      RemoteCommand = "printf '%s\n' 'DIAG1_R1_RECONNECTED=YES'"
      ReceiptName = $receiptName
      Operation = 'RECONNECT'
      TimeoutSeconds = $reconnectTimeoutSeconds
    }
    & $connectionHelper @reconnectArguments | Out-Null
    $connectionReceiptPath = Join-Path $root (
      'logs\connection-' + $receiptName + '.json'
    )
    $connectionReceipt = Get-Content -LiteralPath $connectionReceiptPath -Raw |
      ConvertFrom-Json
    if (
      $connectionReceipt.exit_code -ne 0 -or
      $connectionReceipt.stdout -notmatch '(?m)^DIAG1_R1_RECONNECTED=YES$'
    ) {
      throw 'NVP_DIAG1_R1_RECONNECT_ACK_INVALID'
    }
    $attemptResult.result = 'PASS'
    $attemptResult.end_utc = [DateTime]::UtcNow.ToString('o')
    $receipt.reconnect_attempts += $attemptResult
    $reconnected = $true
    break
  } catch {
    $attemptResult.result = 'FAIL_OR_TIMEOUT'
    $attemptResult.end_utc = [DateTime]::UtcNow.ToString('o')
    $receipt.reconnect_attempts += $attemptResult
    if ($attempt -lt $reconnectAttemptLimit) {
      Start-Sleep -Seconds $betweenReconnectDelaySeconds
    }
  }
}

$receipt.result = if ($reconnected) {
  'PASS_RECONNECTED_WITHOUT_BOOT_ID_COMPARISON'
} else {
  'RECONNECT_TIMEOUT_NO_SECOND_REBOOT'
}
$receipt.end_utc = [DateTime]::UtcNow.ToString('o')
Save-RebootReceipt -Receipt $receipt
if (-not $reconnected) {
  throw 'NVP_DIAG1_R1_RECONNECT_FAILED_NO_SECOND_REBOOT'
}
'NVP_DIAG1_R1_WARM_REBOOT_AND_RECONNECT=PASS'
