[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-NVP-VIDEO-DIAG1-R1'
$root = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z'
$scriptRoot = Join-Path $root 'scripts'
$logRoot = Join-Path $root 'logs'
$outputPath = Join-Path $logRoot 'sanitized-command-ledger.csv'
$expectedIp = '10.132.1.111'
$expectedHostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne $scriptRoot) {
  throw 'NVP_DIAG1_R1_LEDGER_HELPER_LOCATION_INVALID'
}
if (Test-Path -LiteralPath $outputPath) {
  throw 'NVP_DIAG1_R1_SANITIZED_COMMAND_LEDGER_EXISTS'
}
$connectionReceipts = @(
  Get-ChildItem -LiteralPath $logRoot -File -Filter 'connection-*.json' |
    Sort-Object Name
)
if ($connectionReceipts.Count -eq 0) {
  throw 'NVP_DIAG1_R1_NO_CONNECTION_RECEIPTS'
}

$rows = foreach ($receiptFile in $connectionReceipts) {
  $receipt = Get-Content -LiteralPath $receiptFile.FullName -Raw |
    ConvertFrom-Json
  if (
    $receipt.task -cne $task -or
    $receipt.ip -cne $expectedIp -or
    $receipt.host_key -cne $expectedHostKey -or
    -not [bool]$receipt.host_key_pinned -or
    [bool]$receipt.remote_plaintext_persisted -or
    $receipt.remote_command_sha256 -cnotmatch '^[0-9A-F]{64}$'
  ) {
    throw "NVP_DIAG1_R1_CONNECTION_RECEIPT_INVALID:$($receiptFile.Name)"
  }
  [pscustomobject][ordered]@{
    Receipt = $receiptFile.Name
    ReceiptSha256 = (
      Get-FileHash -LiteralPath $receiptFile.FullName -Algorithm SHA256
    ).Hash
    StartUtc = [string]$receipt.start_utc
    EndUtc = [string]$receipt.end_utc
    Operation = [string]$receipt.operation
    Mode = [string]$receipt.mode
    RemoteCommandSha256 = [string]$receipt.remote_command_sha256
    RemoteCommandBytes = [int64]$receipt.remote_command_bytes
    Sudo = [bool]$receipt.sudo
    TimeoutSeconds = [int]$receipt.timeout_seconds
    Ip = [string]$receipt.ip
    HostKeyPinned = [bool]$receipt.host_key_pinned
    BatchMode = [bool]$receipt.batch_mode
    CredentialInProcessArguments = [bool]$receipt.credential_in_process_arguments
    TemporaryCredentialDeleted = [bool]$receipt.temporary_deleted
    CredentialTempRemaining = [int]$receipt.credential_temp_remaining
    UploadBytes = [int64]$receipt.upload_bytes
    UploadSha256 = [string]$receipt.upload_sha256
    ExitCode = [int]$receipt.exit_code
    Problem = [string]$receipt.problem
    OutputTruncated = [bool]$receipt.output_truncated
  }
}

$csv = $rows | Sort-Object StartUtc,Receipt | ConvertTo-Csv -NoTypeInformation
[IO.File]::WriteAllLines(
  $outputPath,
  $csv,
  [Text.UTF8Encoding]::new($false)
)
[ordered]@{
  task = $task
  result = 'PASS'
  receipt_count = $rows.Count
  ledger_path = $outputPath
  ledger_sha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
  excludes_remote_command_plaintext = $true
  excludes_stdout = $true
  excludes_stderr = $true
  excludes_credentials = $true
} | ConvertTo-Json -Depth 5
