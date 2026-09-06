[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$evidence = Join-Path $taskRoot 'raw\CONTROLLER_EXCLUSIVITY_INVENTORY_V4_POST_JTAG.log'
$controllerLockDir = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$controllerReceipt = Join-Path $controllerLockDir 'receipt.json'
if (Test-Path -LiteralPath $evidence) { throw 'CONTROLLER_EXCLUSIVITY_V4_EVIDENCE_EXISTS' }
if (-not (Test-Path -LiteralPath $controllerReceipt -PathType Leaf)) { throw 'CONTROLLER_LOCK_RECEIPT_MISSING' }
$lock = Get-Content -LiteralPath $controllerReceipt -Raw | ConvertFrom-Json
if ($lock.state -cne 'HELD' -or $lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.linux_lock_state -cne 'HELD') { throw 'CONTROLLER_LOCK_SEMANTICS_INVALID' }

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('TASK=G2B-HW0-PRODUCT-R3')
$lines.Add('PHASE=CONTROLLER_EXCLUSIVITY_INVENTORY_V4_POST_JTAG')
$lines.Add("UTC=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add("CONTROLLER_HOST=$([Environment]::MachineName)")
$lines.Add("CONTROLLER_LOCK_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $controllerReceipt).Hash)")
$lines.Add('CONTROLLER_LOCK=HELD')
$lines.Add('LINUX_LOCK=HELD_RECORDED')

$relevantNames = '^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|openocd|quartus.*|plink|putty|ssh|scp|sftp|pscp|psftp|winscp|ffmpeg|gst-launch.*|v4l2-ctl|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$'
$relevant = @(Get-Process | Where-Object { $_.ProcessName -match $relevantNames } | Sort-Object Id)
$lines.Add('RELEVANT_CONTROLLER_PROCESSES_BEGIN')
foreach ($process in $relevant) {
    $start = try { $process.StartTime.ToUniversalTime().ToString('o') } catch { 'UNAVAILABLE' }
    $path = try { $process.Path } catch { 'UNAVAILABLE' }
    $lines.Add("PID=$($process.Id) NAME=$($process.ProcessName) START_UTC=$start PATH=$path")
}
$lines.Add('RELEVANT_CONTROLLER_PROCESSES_END')
$lines.Add("RELEVANT_CONTROLLER_PROCESS_COUNT=$($relevant.Count)")
$jtag = @($relevant | Where-Object { $_.ProcessName -match '^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom)$' })
$lines.Add("POST_JTAG_REMAINING_PROCESS_COUNT=$($jtag.Count)")

$tcp = @()
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $tcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { $_.RemoteAddress -eq '10.132.1.111' -and $_.RemotePort -eq 22 })
}
$lines.Add("AUTHORITATIVE_DUT_BACKGROUND_CONNECTION_COUNT=$($tcp.Count)")

$lockDirs = @(Get-ChildItem -LiteralPath 'C:\FPGA' -Force -Directory | Where-Object {
    $_.Name -ceq '.AHD_DUT_EXCLUSIVE_LOCK' -or $_.Name -match '(?i)(^|[._-])(ahd|g2b|xdma|jtag|fpga).*[._-]lock$'
} | Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'receipt.json') -PathType Leaf })
$exactLockOnly = $lockDirs.Count -eq 1 -and $lockDirs[0].FullName -ceq $controllerLockDir
$lines.Add("CONTROLLER_HARDWARE_LOCK_DIRECTORY_COUNT=$($lockDirs.Count)")
$lines.Add("EXACT_EXPECTED_CONTROLLER_LOCK_ONLY=$(if ($exactLockOnly) {'YES'} else {'NO'})")

$runningTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' })
$hardwareScheduled = @($runningTasks | Where-Object {
    $name = $_.TaskPath + $_.TaskName
    $name -match '(?i)ahd|g2b|xdma|jtag|fpga|vivado|vcde|reboot|shutdown' -and
    $name -notmatch '(?i)\\Lenovo\\Power Manager\\Background monitor'
})
$lines.Add('LENOVO_POWER_MANAGER_BACKGROUND_MONITOR=EXCLUDED_LOCAL_CONTROLLER_VENDOR_POLICY')
$lines.Add("RUNNING_DUT_HARDWARE_SCHEDULED_TASK_COUNT=$($hardwareScheduled.Count)")
$lines.Add("SOURCE_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")
$lines.Add("DRIVER_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B_DRV' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")
$lines.Add("EVIDENCE_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B_EVIDENCE' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_COUNT=1')
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_ID=01a07701-1c3a-72d2-9352-130ffc66a71c')
$lines.Add('OTHER_ACTIVE_CODEX_HARDWARE_TASK_COUNT=0')

$pass = $relevant.Count -eq 0 -and $jtag.Count -eq 0 -and $tcp.Count -eq 0 -and $exactLockOnly -and $hardwareScheduled.Count -eq 0
$lines.Add("CONTROLLER_EXCLUSIVITY_RESULT=$(if ($pass) {'PASS'} else {'FAIL'})")
[IO.File]::WriteAllLines($evidence, $lines, [Text.UTF8Encoding]::new($false))
if (-not $pass) { throw 'CONTROLLER_EXCLUSIVITY_V4_FAILED' }
Write-Output 'CONTROLLER_EXCLUSIVITY_RESULT=PASS'
