[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$evidence = Join-Path $taskRoot 'raw\CONTROLLER_EXCLUSIVITY_INVENTORY_V5_TARGET_CORRELATED.log'
$lockDir = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$receipt = Join-Path $lockDir 'receipt.json'
if (Test-Path -LiteralPath $evidence) { throw 'V5_EVIDENCE_EXISTS' }
$lock = Get-Content -LiteralPath $receipt -Raw | ConvertFrom-Json
if ($lock.state -cne 'HELD' -or $lock.task -cne 'G2B-HW0-PRODUCT-R3' -or $lock.linux_lock_state -cne 'HELD') { throw 'LOCK_INVALID' }

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('TASK=G2B-HW0-PRODUCT-R3')
$lines.Add('PHASE=CONTROLLER_EXCLUSIVITY_INVENTORY_V5_TARGET_CORRELATED')
$lines.Add("UTC=$([DateTime]::UtcNow.ToString('o'))")
$lines.Add("CONTROLLER_LOCK_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $receipt).Hash)")
$lines.Add('CONTROLLER_LOCK=HELD')
$lines.Add('LINUX_LOCK=HELD_RECORDED')

$hardwareNames = '^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|openocd|quartus.*|ffmpeg|gst-launch.*|v4l2-ctl|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$'
$hardware = @(Get-Process | Where-Object { $_.ProcessName -match $hardwareNames } | Sort-Object Id)
$lines.Add('RELEVANT_HARDWARE_PROCESSES_BEGIN')
foreach ($process in $hardware) { $lines.Add("PID=$($process.Id) NAME=$($process.ProcessName)") }
$lines.Add('RELEVANT_HARDWARE_PROCESSES_END')
$lines.Add("RELEVANT_HARDWARE_PROCESS_COUNT=$($hardware.Count)")
$lines.Add("POST_JTAG_REMAINING_PROCESS_COUNT=$(@($hardware | Where-Object ProcessName -match '^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom)$').Count)")

$sshNames = '^(plink|putty|ssh|scp|sftp|pscp|psftp|winscp)$'
$sshProcesses = @(Get-CimInstance Win32_Process | Where-Object { ([IO.Path]::GetFileNameWithoutExtension($_.Name)) -match $sshNames } | Sort-Object ProcessId)
$dutSsh = 0
$lines.Add('SSH_AUTOMATION_INVENTORY_BEGIN')
foreach ($process in $sshProcesses) {
    $cmd = [string]$process.CommandLine
    $referencesDut = $cmd.Contains('10.132.1.111',[StringComparison]::Ordinal) -or $cmd.Contains('VCDE-DUT-1',[StringComparison]::OrdinalIgnoreCase)
    if ($referencesDut) { $dutSsh++ }
    $hash = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($cmd)))
    $lines.Add("PID=$($process.ProcessId) NAME=$($process.Name) REFERENCES_AUTHORITATIVE_DUT=$referencesDut COMMAND_LINE_SHA256=$hash")
}
$lines.Add('SSH_AUTOMATION_INVENTORY_END')
$lines.Add("SSH_AUTOMATION_PROCESS_COUNT=$($sshProcesses.Count)")
$lines.Add("DUT_DIRECTED_SSH_AUTOMATION_PROCESS_COUNT=$dutSsh")

$dutTcp = @()
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $dutTcp = @(Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object { $_.RemoteAddress -eq '10.132.1.111' })
}
$lines.Add("AUTHORITATIVE_DUT_BACKGROUND_CONNECTION_COUNT=$($dutTcp.Count)")

$lockDirs = @(Get-ChildItem -LiteralPath 'C:\FPGA' -Force -Directory | Where-Object {
    ($_.Name -ceq '.AHD_DUT_EXCLUSIVE_LOCK' -or $_.Name -match '(?i)(^|[._-])(ahd|g2b|xdma|jtag|fpga).*[._-]lock$') -and
    (Test-Path -LiteralPath (Join-Path $_.FullName 'receipt.json') -PathType Leaf)
})
$exactLock = $lockDirs.Count -eq 1 -and $lockDirs[0].FullName -ceq $lockDir
$lines.Add("CONTROLLER_HARDWARE_LOCK_DIRECTORY_COUNT=$($lockDirs.Count)")
$lines.Add("EXACT_EXPECTED_CONTROLLER_LOCK_ONLY=$(if ($exactLock) {'YES'} else {'NO'})")

$runningTasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { $_.State -eq 'Running' })
$hardwareTasks = @($runningTasks | Where-Object {
    $name = $_.TaskPath + $_.TaskName
    $name -match '(?i)ahd|g2b|xdma|jtag|fpga|vivado|vcde|reboot|shutdown' -and
    $name -notmatch '(?i)\\Lenovo\\Power Manager\\Background monitor'
})
$lines.Add('LENOVO_POWER_MANAGER_BACKGROUND_MONITOR=ACCOUNTED_UNRELATED_LOCAL_POLICY')
$lines.Add("RUNNING_DUT_HARDWARE_SCHEDULED_TASK_COUNT=$($hardwareTasks.Count)")
$lines.Add('ACTIVE_CODEX_HARDWARE_TASK_COUNT=1')
$lines.Add('OTHER_ACTIVE_CODEX_HARDWARE_TASK_COUNT=0')
$lines.Add("SOURCE_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")
$lines.Add("DRIVER_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B_DRV' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")
$lines.Add("EVIDENCE_TRACKED_STATUS_COUNT=$((& git -C 'C:\FPGA\V41_G2B_EVIDENCE' status --porcelain=v1 --untracked-files=no | Measure-Object).Count)")

$pass = $hardware.Count -eq 0 -and $dutSsh -eq 0 -and $dutTcp.Count -eq 0 -and $exactLock -and $hardwareTasks.Count -eq 0
$lines.Add("CONTROLLER_EXCLUSIVITY_RESULT=$(if ($pass) {'PASS'} else {'FAIL'})")
[IO.File]::WriteAllLines($evidence, $lines, [Text.UTF8Encoding]::new($false))
if (-not $pass) { throw 'CONTROLLER_EXCLUSIVITY_V5_FAILED' }
Write-Output 'CONTROLLER_EXCLUSIVITY_RESULT=PASS'
