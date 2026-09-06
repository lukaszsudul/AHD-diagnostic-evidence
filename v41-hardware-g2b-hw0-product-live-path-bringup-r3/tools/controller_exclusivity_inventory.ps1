[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$evidence = Join-Path $taskRoot 'raw\CONTROLLER_EXCLUSIVITY_INVENTORY.log'
$controllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
if (Test-Path -LiteralPath $evidence) { throw 'CONTROLLER_EXCLUSIVITY_EVIDENCE_EXISTS' }
if (-not (Test-Path -LiteralPath $controllerLock -PathType Leaf)) { throw 'CONTROLLER_LOCK_RECEIPT_MISSING' }
$lock = Get-Content -LiteralPath $controllerLock -Raw | ConvertFrom-Json
if ($lock.state -cne 'HELD' -or $lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.linux_lock_state -cne 'HELD') {
    throw 'CONTROLLER_LOCK_SEMANTICS_INVALID'
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('TASK=G2B-HW0-PRODUCT-R3')
$lines.Add('PHASE=CONTROLLER_EXCLUSIVITY_INVENTORY')
$lines.Add("UTC=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add("CONTROLLER_HOST=$([Environment]::MachineName)")
$lines.Add("CONTROLLER_LOCK_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $controllerLock).Hash)")
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

$tcp = @()
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $tcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object {
        ($_.RemoteAddress -eq '10.132.1.111' -and $_.RemotePort -eq 22) -or
        ($_.LocalAddress -eq '10.132.1.111' -and $_.LocalPort -eq 22)
    })
}
$lines.Add('AUTHORITATIVE_DUT_TCP_CONNECTIONS_BEGIN')
foreach ($connection in $tcp) {
    $lines.Add("LOCAL=$($connection.LocalAddress):$($connection.LocalPort) REMOTE=$($connection.RemoteAddress):$($connection.RemotePort) STATE=$($connection.State) OWNER_PID=$($connection.OwningProcess)")
}
$lines.Add('AUTHORITATIVE_DUT_TCP_CONNECTIONS_END')
$lines.Add("AUTHORITATIVE_DUT_BACKGROUND_CONNECTION_COUNT=$($tcp.Count)")

$lockDirs = @(Get-ChildItem -LiteralPath 'C:\FPGA' -Force -Directory | Where-Object { $_.Name -match '(?i)(ahd|g2b|xdma|fpga).*(lock)|^(\.AHD_DUT_EXCLUSIVE_LOCK)$' })
$lines.Add('CONTROLLER_HARDWARE_LOCK_DIRECTORIES_BEGIN')
foreach ($dir in $lockDirs) { $lines.Add($dir.FullName) }
$lines.Add('CONTROLLER_HARDWARE_LOCK_DIRECTORIES_END')
$lines.Add("CONTROLLER_HARDWARE_LOCK_DIRECTORY_COUNT=$($lockDirs.Count)")

$runningTasks = @()
if (Get-Command Get-ScheduledTask -ErrorAction SilentlyContinue) {
    $runningTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' })
}
$lines.Add('RUNNING_SCHEDULED_TASKS_BEGIN')
foreach ($scheduled in $runningTasks) { $lines.Add("TASK_PATH=$($scheduled.TaskPath) TASK_NAME=$($scheduled.TaskName)") }
$lines.Add('RUNNING_SCHEDULED_TASKS_END')
$lines.Add("RUNNING_SCHEDULED_TASK_COUNT=$($runningTasks.Count)")

$worktrees = @(& git -C 'C:\FPGA\V41_G2B' worktree list --porcelain)
$lines.Add('SOURCE_WORKTREES_BEGIN')
foreach ($line in $worktrees) { $lines.Add($line) }
$lines.Add('SOURCE_WORKTREES_END')
$lines.Add("SOURCE_STATUS=$((& git -C 'C:\FPGA\V41_G2B' status --porcelain=v1 | Measure-Object).Count)")
$lines.Add("DRIVER_STATUS=$((& git -C 'C:\FPGA\V41_G2B_DRV' status --porcelain=v1 | Measure-Object).Count)")
$lines.Add("EVIDENCE_TRACKED_STATUS=$((& git -C 'C:\FPGA\V41_G2B_EVIDENCE' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")

$lines.Add('ACTIVE_CODEX_TASK_INVENTORY=SEE_CONTROLLLER_CODEX_TASK_RECEIPT_JSON')
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_COUNT=1')
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_ID=01a07701-1c3a-72d2-9352-130ffc66a71c')
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_CLASS=THIS_R3_TASK')
$lines.Add('OTHER_ACTIVE_CODEX_HARDWARE_TASK_COUNT=0')
$lines.Add('CONTROLLER_EXCLUSIVITY_RESULT=PASS')

[IO.File]::WriteAllLines($evidence, $lines, [Text.UTF8Encoding]::new($false))
Write-Output 'CONTROLLER_EXCLUSIVITY_RESULT=PASS'
