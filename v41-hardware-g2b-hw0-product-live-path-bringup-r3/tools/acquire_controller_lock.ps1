[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$taskRoot = 'C:\FPGA\V41_G2B_HW_EVIDENCE\G2B_HW0_PRODUCT_R3_20260906T140148Z'
$lockDirectory = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK'
$lockReceipt = Join-Path $lockDirectory 'receipt.json'
$evidenceReceipt = Join-Path $taskRoot 'locks\CONTROLLER_LOCK_ACQUIRE.json'
$utc = [DateTime]::UtcNow.ToString('o')

if (Test-Path -LiteralPath $lockDirectory) {
    throw 'CONTROLLER_LOCK_ALREADY_EXISTS'
}

# Directory creation is the atomic controller-side exclusion operation.
New-Item -ItemType Directory -Path $lockDirectory -ErrorAction Stop | Out-Null
try {
    $receipt = [ordered]@{
        schema = 'AHD_DUT_EXCLUSIVE_LOCK_V1'
        state = 'HELD'
        task = 'G2B-HW0-PRODUCT-R3'
        controller_task_thread_id = '01a07701-1c3a-72d2-9352-130ffc66a71c'
        acquired_utc = $utc
        controller_host = [Environment]::MachineName
        controller_user = [Environment]::UserName
        acquiring_process_id = $PID
        authoritative_dut = 'VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111'
        expected_pci_bdf = '0000:01:00.0'
        expected_jtag_chain_index = 0
        controller_artifact_root = $taskRoot
        linux_lock_state = 'NOT_YET_ACQUIRED'
        release_state = 'NOT_READY'
    }
    $json = $receipt | ConvertTo-Json -Depth 5
    [IO.File]::WriteAllText($lockReceipt, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText($evidenceReceipt, $json + [Environment]::NewLine, [Text.UTF8Encoding]::new($false))
}
catch {
    if (Test-Path -LiteralPath $lockReceipt) {
        Remove-Item -LiteralPath $lockReceipt -Force
    }
    if (Test-Path -LiteralPath $lockDirectory) {
        Remove-Item -LiteralPath $lockDirectory -Force
    }
    throw
}

$roundTrip = Get-Content -LiteralPath $lockReceipt -Raw | ConvertFrom-Json
if ($roundTrip.state -cne 'HELD' -or $roundTrip.task -cne 'G2B-HW0-PRODUCT-R3') {
    throw 'CONTROLLER_LOCK_RECEIPT_ROUNDTRIP_FAILED'
}

Write-Output 'CONTROLLER_LOCK=HELD'
Write-Output "CONTROLLER_LOCK_ACQUIRED_UTC=$utc"
Write-Output "CONTROLLER_LOCK_PATH=$lockDirectory"
