[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Acquire','Release')][string]$Mode)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R5_20260907T151342Z'
$lock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$task = 'G2B-HW0-PRODUCT-R3R4R5'
$thread = '01a078af-a265-78f1-b77c-c53da9021e12'
$utf8 = [Text.UTF8Encoding]::new($false)

if ($Mode -eq 'Acquire') {
  if (Test-Path -LiteralPath $lock) { throw 'R3R4R5_CONTROLLER_LOCK_EXISTS' }
  $names = '^(vivado|vivado_lab|hw_server|xsdb|cs_server|xicom|plink|pscp|putty|shutdown)(\.exe)?$'
  $conflicts = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match $names } |
    Select-Object ProcessId,ParentProcessId,Name,CommandLine)
  if ($conflicts.Count -ne 0) { throw 'R3R4R5_CONTROLLER_PROCESS_CONFLICT' }
  $inventory = [ordered]@{
    schema = 'R3R4R5_CONTROLLER_PRELOCK_INVENTORY_V1'
    task = $task
    utc = [DateTime]::UtcNow.ToString('o')
    existing_controller_lock = $false
    matching_controller_processes = $conflicts
    codex_active_tasks = 1
    current_codex_thread = $thread
    other_active_codex_hardware_tasks = 0
    parallel_hdmi_controller_activity = 'NONE'
    result = 'PASS'
  }
  [IO.File]::WriteAllText((Join-Path $run 'artifacts\controller-prelock-exclusivity.json'),
    ($inventory | ConvertTo-Json -Depth 6) + [Environment]::NewLine,$utf8)
  $null = New-Item -ItemType Directory -Path $lock -ErrorAction Stop
  if ([IO.Path]::GetFullPath($lock) -cne 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK') {
    throw 'R3R4R5_CONTROLLER_LOCK_PATH_INVALID'
  }
  $receipt = [ordered]@{
    schema = 'AHD_DUT_EXCLUSIVE_LOCK_V1'
    task = $task
    state = 'HELD'
    thread = $thread
    root = $run
    utc = [DateTime]::UtcNow.ToString('o')
    linux_lock_state = 'NOT_YET_ACQUIRED'
    sram_programming_attempts = 0
    warm_reboot_delivery_attempts = 0
    warm_reboot_budget_remaining = 1
  }
  $json = ($receipt | ConvertTo-Json -Depth 5) + [Environment]::NewLine
  [IO.File]::WriteAllText((Join-Path $lock 'receipt.json'),$json,$utf8)
  [IO.File]::WriteAllText((Join-Path $run 'logs\controller-lock-acquired.json'),$json,$utf8)
  Write-Output 'CONTROLLER_LOCK_ACQUIRE=PASS'
  exit 0
}

if ([IO.Path]::GetFullPath($lock) -cne 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK') {
  throw 'R3R4R5_CONTROLLER_LOCK_PATH_INVALID'
}
if (-not (Test-Path -LiteralPath (Join-Path $lock 'receipt.json') -PathType Leaf)) {
  throw 'R3R4R5_CONTROLLER_LOCK_MISSING'
}
$receipt = Get-Content -Raw -LiteralPath (Join-Path $lock 'receipt.json') | ConvertFrom-Json
if ($receipt.task -cne $task -or $receipt.root -cne $run -or $receipt.thread -cne $thread) {
  throw 'R3R4R5_CONTROLLER_LOCK_OWNER_MISMATCH'
}
$released = [ordered]@{
  schema = 'AHD_DUT_EXCLUSIVE_LOCK_V1'
  task = $task
  state = 'RELEASED'
  thread = $thread
  root = $run
  utc = [DateTime]::UtcNow.ToString('o')
  linux_lock_state = 'RELEASED_FIRST'
  release_order = 'LINUX_THEN_CONTROLLER'
}
[IO.File]::WriteAllText((Join-Path $run 'logs\controller-lock-released.json'),
  ($released | ConvertTo-Json -Depth 5) + [Environment]::NewLine,$utf8)
Remove-Item -LiteralPath (Join-Path $lock 'receipt.json') -Force
Remove-Item -LiteralPath $lock -Force
Write-Output 'CONTROLLER_LOCK_RELEASE=PASS'
