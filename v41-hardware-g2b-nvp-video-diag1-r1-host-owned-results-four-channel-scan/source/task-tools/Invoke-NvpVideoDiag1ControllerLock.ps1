[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [ValidateSet('Acquire','Status','Release')]
  [string]$Action,

  [switch]$ConfirmHardwareSafe
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-NVP-VIDEO-DIAG1-R1'
$run = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z'
$scriptRoot = Join-Path $run 'scripts'
$logRoot = Join-Path $run 'logs'
$lockPath = 'C:\FPGA\.AHD_G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z.lock'
$lockReceiptPath = Join-Path $lockPath 'receipt.json'
$acquireReceiptPath = Join-Path $logRoot 'controller-lock-acquire.json'
$releaseReceiptPath = Join-Path $logRoot 'controller-lock-release.json'
$releasedReceiptDirectory = Join-Path $logRoot 'released-controller-lock'
$releasedLockReceiptPath = Join-Path $releasedReceiptDirectory 'receipt.json'

function Write-NewUtf8File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Text
  )
  $stream = [IO.File]::Open(
    $Path,
    [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write,
    [IO.FileShare]::None
  )
  try {
    $writer = [IO.StreamWriter]::new(
      $stream,
      [Text.UTF8Encoding]::new($false)
    )
    try {
      $writer.Write($Text)
    } finally {
      $writer.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Read-OwnedLock {
  if (-not (Test-Path -LiteralPath $lockReceiptPath -PathType Leaf)) {
    throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_RECEIPT_MISSING'
  }
  $receipt = Get-Content -LiteralPath $lockReceiptPath -Raw | ConvertFrom-Json
  if (
    $receipt.task -cne $task -or
    $receipt.run_root -cne $run -or
    $receipt.state -cne 'HELD'
  ) {
    throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_OWNER_MISMATCH'
  }
  return $receipt
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne $scriptRoot) {
  throw 'NVP_DIAG1_R1_LOCK_HELPER_LOCATION_INVALID'
}
foreach ($requiredDirectory in @($run,$scriptRoot,$logRoot)) {
  if (-not (Test-Path -LiteralPath $requiredDirectory -PathType Container)) {
    throw 'NVP_DIAG1_R1_TASK_DIRECTORY_MISSING'
  }
}

if ($Action -ceq 'Status') {
  if (-not (Test-Path -LiteralPath $lockPath -PathType Container)) {
    [ordered]@{
      task = $task
      run_root = $run
      lock_path = $lockPath
      state = 'NOT_HELD'
    } | ConvertTo-Json -Depth 4
    return
  }
  $statusReceipt = Read-OwnedLock
  $statusReceipt | ConvertTo-Json -Depth 6
  return
}

if ($Action -ceq 'Acquire') {
  if ($ConfirmHardwareSafe) {
    throw 'NVP_DIAG1_R1_CONFIRM_HARDWARE_SAFE_ONLY_VALID_FOR_RELEASE'
  }
  if (
    (Test-Path -LiteralPath $lockPath) -or
    (Test-Path -LiteralPath $acquireReceiptPath) -or
    (Test-Path -LiteralPath $releaseReceiptPath) -or
    (Test-Path -LiteralPath $releasedLockReceiptPath)
  ) {
    throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_OR_RECEIPT_ALREADY_EXISTS'
  }

  $otherLockDirectories = @(
    Get-ChildItem -LiteralPath 'C:\FPGA' -Directory -Force |
      Where-Object {
        $_.Name -like '.AHD_*.lock' -and
        $_.FullName -cne $lockPath
      }
  )
  if ($otherLockDirectories.Count -ne 0) {
    $otherNames = @($otherLockDirectories | ForEach-Object Name) -join ','
    throw "NVP_DIAG1_R1_OTHER_HARDWARE_LOCK_PRESENT:$otherNames"
  }

  New-Item -ItemType Directory -Path $lockPath -ErrorAction Stop | Out-Null
  $acquiredUtc = [DateTime]::UtcNow.ToString('o')
  $receipt = [ordered]@{
    task = $task
    run_root = $run
    state = 'HELD'
    acquired_utc = $acquiredUtc
    owner = 'CURRENT_CODEX_WINDOW'
    controller_user_sid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    lock_path = $lockPath
    acquisition_method = 'ATOMIC_TASK_LOCK_DIRECTORY'
    competing_ahd_lock_count_at_acquire = 0
  }
  $json = $receipt | ConvertTo-Json -Depth 6
  Write-NewUtf8File -Path $lockReceiptPath -Text ($json + [char]10)
  Write-NewUtf8File -Path $acquireReceiptPath -Text ($json + [char]10)
  Write-Output $json
  return
}

if ($Action -ceq 'Release') {
  if (-not $ConfirmHardwareSafe) {
    throw 'NVP_DIAG1_R1_RELEASE_REQUIRES_CONFIRM_HARDWARE_SAFE'
  }
  if (
    (Test-Path -LiteralPath $releaseReceiptPath) -or
    (Test-Path -LiteralPath $releasedLockReceiptPath)
  ) {
    throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_RELEASE_RECEIPT_EXISTS'
  }
  $heldReceipt = Read-OwnedLock

  $programReceiptPath = Join-Path $run 'artifacts\programming-receipt.json'
  if (Test-Path -LiteralPath $programReceiptPath -PathType Leaf) {
    $programReceipt = Get-Content -LiteralPath $programReceiptPath -Raw |
      ConvertFrom-Json
    if (
      [string]$programReceipt.result -in @(
        'DELIVERY_IN_PROGRESS_NO_RETRY',
        'DELIVERY_PENDING'
      )
    ) {
      throw 'NVP_DIAG1_R1_PROGRAMMING_STATE_PENDING_LOCK_PRESERVED'
    }
  }
  $rebootReceiptPath = Join-Path $run 'artifacts\warm-reboot-receipt.json'
  if (Test-Path -LiteralPath $rebootReceiptPath -PathType Leaf) {
    $rebootReceipt = Get-Content -LiteralPath $rebootReceiptPath -Raw |
      ConvertFrom-Json
    if ([string]$rebootReceipt.result -like '*PENDING*') {
      throw 'NVP_DIAG1_R1_REBOOT_STATE_PENDING_LOCK_PRESERVED'
    }
  }

  New-Item -ItemType Directory -Path $releasedReceiptDirectory |
    Out-Null
  Move-Item -LiteralPath $lockReceiptPath -Destination $releasedLockReceiptPath
  Remove-Item -LiteralPath $lockPath
  if (Test-Path -LiteralPath $lockPath) {
    throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_DIRECTORY_RELEASE_FAILED'
  }

  $releaseReceipt = [ordered]@{
    task = $task
    run_root = $run
    prior_state = [string]$heldReceipt.state
    state = 'RELEASED'
    acquired_utc = [string]$heldReceipt.acquired_utc
    released_utc = [DateTime]::UtcNow.ToString('o')
    owner = [string]$heldReceipt.owner
    hardware_safe_confirmed_by_caller = $true
    released_lock_receipt = $releasedLockReceiptPath
  }
  $releaseJson = $releaseReceipt | ConvertTo-Json -Depth 6
  Write-NewUtf8File -Path $releaseReceiptPath -Text (
    $releaseJson + [char]10
  )
  Write-Output $releaseJson
  return
}

throw 'NVP_DIAG1_R1_UNREACHABLE_LOCK_ACTION'
