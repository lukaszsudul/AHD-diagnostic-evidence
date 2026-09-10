[CmdletBinding(DefaultParameterSetName='Command')]
param(
  [Parameter(Mandatory,ParameterSetName='Command')]
  [ValidateNotNullOrEmpty()]
  [string]$RemoteCommand,

  [Parameter(Mandatory,ParameterSetName='Upload')]
  [ValidateNotNullOrEmpty()]
  [string]$UploadFile,

  [Parameter(Mandatory,ParameterSetName='Upload')]
  [ValidateNotNullOrEmpty()]
  [string]$RemotePath,

  [Parameter(Mandatory)]
  [ValidatePattern('^[A-Za-z0-9][A-Za-z0-9_-]{0,63}$')]
  [string]$ReceiptName,

  [Parameter(Mandatory)]
  [ValidateSet(
    'REMOTE_ROOT_PREP',
    'UPLOAD',
    'LINUX_LOCK',
    'DRIVER_LOAD',
    'RUNTIME_PREFLIGHT',
    'RUNTIME_CONTROLLER',
    'DRIVER_UNLOAD',
    'CLEANUP',
    'WARM_REBOOT',
    'RECONNECT',
    'READ_ONLY_EVIDENCE'
  )]
  [string]$Operation,

  [Parameter(ParameterSetName='Command')]
  [switch]$Sudo,

  [ValidateRange(5,600)]
  [int]$TimeoutSeconds=60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$task = 'G2B-NVP-VIDEO-DIAG1-R1'
$run = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z'
$linuxRun = '/home/vcdeagent1/vcde_artifacts/g2b_nvp_video_diag1_r1/20260909T203832Z'
$scriptRoot = Join-Path $run 'scripts'
$logRoot = Join-Path $run 'logs'
$privateRoot = Join-Path $run 'private'
$credentialTemp = Join-Path $privateRoot 'credential-temp'
$credentialSource = 'C:\FPGA\VCDE-DUT-1.txt'
$receipt = Join-Path $logRoot ('connection-' + $ReceiptName + '.json')
$hardwareGateReceiptPath = Join-Path $run 'reports\vivado_full\G2B_BUILD_RESULT.txt'
$eligibleBitstreamPath = Join-Path $run 'artifacts\G2B_NVP_VIDEO_DIAG1_R1_FOUR_CHANNEL_SCAN.bit'
$lockPath = 'C:\FPGA\.AHD_G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z.lock'
$lockReceiptPath = Join-Path $lockPath 'receipt.json'
$plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$login = 'vcdeagent1'
$ip = '10.132.1.111'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User

function Assert-PrivateAcl {
  param([Parameter(Mandatory)][string]$Path)
  $acl = Get-Acl -LiteralPath $Path
  $rules = @($acl.GetAccessRules(
      $true,
      $true,
      [Security.Principal.SecurityIdentifier]
    ))
  if (
    -not $acl.AreAccessRulesProtected -or
    $rules.Count -ne 1 -or
    $rules[0].IdentityReference.Value -cne $sid.Value -or
    $rules[0].AccessControlType -ne 'Allow'
  ) {
    throw 'NVP_DIAG1_R1_PRIVATE_ACL_INVALID'
  }
}

function Get-TextSha256 {
  param([Parameter(Mandatory)][string]$Text)
  $bytes = [Text.Encoding]::UTF8.GetBytes($Text)
  try {
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
      return [BitConverter]::ToString($hasher.ComputeHash($bytes)).Replace('-','')
    } finally {
      $hasher.Dispose()
    }
  } finally {
    if ($bytes.Length -gt 0) {
      [Array]::Clear($bytes,0,$bytes.Length)
    }
  }
}

function Write-NewUtf8File {
  param(
    [Parameter(Mandatory)][string]$Path,
    [Parameter(Mandatory)][string]$Text
  )
  $encoding = [Text.UTF8Encoding]::new($false)
  $stream = [IO.File]::Open(
    $Path,
    [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write,
    [IO.FileShare]::None
  )
  try {
    $writer = [IO.StreamWriter]::new($stream,$encoding)
    try {
      $writer.Write($Text)
    } finally {
      $writer.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne $scriptRoot) {
  throw 'NVP_DIAG1_R1_HELPER_LOCATION_INVALID'
}
foreach ($requiredDirectory in @($run,$scriptRoot,$logRoot,$privateRoot)) {
  if (-not (Test-Path -LiteralPath $requiredDirectory -PathType Container)) {
    throw 'NVP_DIAG1_R1_TASK_DIRECTORY_MISSING'
  }
}
foreach ($eligibilityInput in @($hardwareGateReceiptPath,$eligibleBitstreamPath)) {
  if (-not (Test-Path -LiteralPath $eligibilityInput -PathType Leaf)) {
    throw 'NVP_DIAG1_R1_OFFLINE_HARDWARE_ELIGIBILITY_INPUT_MISSING'
  }
}
$hardwareGate = @{}
foreach ($gateLine in [IO.File]::ReadAllLines($hardwareGateReceiptPath)) {
  if ([string]::IsNullOrWhiteSpace($gateLine)) {
    continue
  }
  if ($gateLine -notmatch '^([^=]+)=(.*)$') {
    throw 'NVP_DIAG1_R1_OFFLINE_HARDWARE_ELIGIBILITY_FORMAT_INVALID'
  }
  if ($hardwareGate.ContainsKey($Matches[1])) {
    throw 'NVP_DIAG1_R1_OFFLINE_HARDWARE_ELIGIBILITY_DUPLICATE_KEY'
  }
  $hardwareGate[$Matches[1]] = $Matches[2]
}
$requiredEligibility = [ordered]@{
  TASK = 'AHD_V41_G2B_NVP_VIDEO_DIAG1_R1'
  BUILD = 'PASS'
  G2B_OFFLINE_BUILD_QUALIFICATION = 'PASS'
  BITSTREAM_PRODUCED = 'YES'
  HARDWARE_ACCESSED = 'NO'
}
foreach ($eligibilityEntry in $requiredEligibility.GetEnumerator()) {
  if (
    -not $hardwareGate.ContainsKey($eligibilityEntry.Key) -or
    $hardwareGate[$eligibilityEntry.Key] -cne $eligibilityEntry.Value
  ) {
    throw "NVP_DIAG1_R1_OFFLINE_HARDWARE_NOT_ELIGIBLE:$($eligibilityEntry.Key)"
  }
}
if (
  $hardwareGate.BITSTREAM_SHA256 -cnotmatch '^[0-9A-F]{64}$' -or
  (Get-FileHash -LiteralPath $eligibleBitstreamPath -Algorithm SHA256).Hash -cne
    $hardwareGate.BITSTREAM_SHA256
) {
  throw 'NVP_DIAG1_R1_ELIGIBLE_BITSTREAM_HASH_MISMATCH'
}
if (-not (Test-Path -LiteralPath $plink -PathType Leaf)) {
  throw 'NVP_DIAG1_R1_PINNED_PLINK_MISSING'
}
if (-not (Test-Path -LiteralPath $credentialSource -PathType Leaf)) {
  throw 'NVP_DIAG1_R1_CREDENTIAL_SOURCE_MISSING'
}
if (Test-Path -LiteralPath $receipt) {
  throw 'NVP_DIAG1_R1_RECEIPT_EXISTS'
}
if (-not (Test-Path -LiteralPath $lockReceiptPath -PathType Leaf)) {
  throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_NOT_HELD'
}
$lock = Get-Content -LiteralPath $lockReceiptPath -Raw | ConvertFrom-Json
if (
  $lock.task -cne $task -or
  $lock.run_root -cne $run -or
  $lock.state -cne 'HELD'
) {
  throw 'NVP_DIAG1_R1_CONTROLLER_LOCK_OWNER_MISMATCH'
}

$mode = $PSCmdlet.ParameterSetName.ToUpperInvariant()
if (
  ($mode -eq 'UPLOAD' -and $Operation -cne 'UPLOAD') -or
  ($mode -eq 'COMMAND' -and $Operation -ceq 'UPLOAD')
) {
  throw 'NVP_DIAG1_R1_OPERATION_MODE_MISMATCH'
}
if ($mode -eq 'COMMAND' -and [string]::IsNullOrWhiteSpace($RemoteCommand)) {
  throw 'NVP_DIAG1_R1_EMPTY_REMOTE_COMMAND'
}

if (-not (Test-Path -LiteralPath $credentialTemp -PathType Container)) {
  New-Item -ItemType Directory -Path $credentialTemp | Out-Null
  $directoryAcl = [Security.AccessControl.DirectorySecurity]::new()
  $directoryAcl.SetOwner($sid)
  $directoryAcl.SetAccessRuleProtection($true,$false)
  $directoryAcl.AddAccessRule(
    [Security.AccessControl.FileSystemAccessRule]::new(
      $sid,
      'FullControl',
      'ContainerInherit,ObjectInherit',
      'None',
      'Allow'
    )
  )
  Set-Acl -LiteralPath $credentialTemp -AclObject $directoryAcl
}
Assert-PrivateAcl -Path $credentialTemp
if (@(Get-ChildItem -LiteralPath $credentialTemp -Force).Count -ne 0) {
  throw 'NVP_DIAG1_R1_CREDENTIAL_TEMP_NOT_EMPTY'
}

$pw = $null
$temp = $null
$proc = $null
$outTask = $null
$errTask = $null
$stdout = ''
$stderr = ''
$exitCode = 125
$start = [DateTime]::UtcNow.ToString('o')
$created = $false
$deleted = $false
$started = $false
$problem = $null
$uploadBytes = 0
$uploadSha256 = $null
$remoteCommandBytes = 0
$remoteCommandSha256 = $null
$outputTruncated = $false

try {
  $fields = @{}
  foreach ($credentialLine in [IO.File]::ReadAllLines($credentialSource)) {
    if (-not $credentialLine.Trim() -or $credentialLine.Trim().StartsWith('#')) {
      continue
    }
    if ($credentialLine -notmatch '^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$') {
      throw 'NVP_DIAG1_R1_CREDENTIAL_FORMAT'
    }
    $label = ($Matches[1] -replace '[^A-Za-z0-9]','').ToLowerInvariant()
    $value = $Matches[2]
    $key = switch ($label) {
      {$_ -in @('ip','adresip')} { 'ip' }
      {$_ -in @('user','username','uzytkownik','sudouser')} { 'user' }
      {$_ -in @('password','haslo')} { 'password' }
      default { throw 'NVP_DIAG1_R1_CREDENTIAL_FIELD' }
    }
    if ($fields.ContainsKey($key)) {
      throw 'NVP_DIAG1_R1_DUPLICATE_CREDENTIAL_FIELD'
    }
    $fields[$key] = $value
  }
  if (
    $fields.Count -ne 3 -or
    $fields.ip -cne $ip -or
    $fields.user -cne $login
  ) {
    throw 'NVP_DIAG1_R1_CREDENTIAL_IDENTITY'
  }
  $pw = [string]$fields.password
  $fields.Clear()
  $value = $null
  $credentialLine = $null
  if ([string]::IsNullOrWhiteSpace($pw)) {
    throw 'NVP_DIAG1_R1_EMPTY_CREDENTIAL'
  }

  if ($mode -eq 'UPLOAD') {
    $resolvedUpload = [IO.Path]::GetFullPath($UploadFile)
    if (-not $resolvedUpload.StartsWith(
        $scriptRoot + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
      )) {
      throw 'NVP_DIAG1_R1_UPLOAD_SOURCE_BOUNDARY'
    }
    if (-not (Test-Path -LiteralPath $resolvedUpload -PathType Leaf)) {
      throw 'NVP_DIAG1_R1_UPLOAD_SOURCE_MISSING'
    }
    $escapedRun = [Regex]::Escape($linuxRun)
    if ($RemotePath -notmatch ('^' + $escapedRun + '/scripts/[A-Za-z0-9._-]+$')) {
      throw 'NVP_DIAG1_R1_UPLOAD_DESTINATION_BOUNDARY'
    }
    $uploadBytes = (Get-Item -LiteralPath $resolvedUpload).Length
    $uploadSha256 = (Get-FileHash -LiteralPath $resolvedUpload -Algorithm SHA256).Hash
    $remotePlain = "umask 077; base64 -d > '$RemotePath'; chmod 600 '$RemotePath'"
  } else {
    $crlf = [string][char]13 + [char]10
    $remotePlain = $RemoteCommand.Replace($crlf,[string][char]10)
  }

  $remoteCommandBytes = [Text.Encoding]::UTF8.GetByteCount($remotePlain)
  $remoteCommandSha256 = Get-TextSha256 -Text $remotePlain
  $scriptBytes = [Text.Encoding]::UTF8.GetBytes($remotePlain)
  try {
    $base64 = [Convert]::ToBase64String($scriptBytes)
  } finally {
    if ($scriptBytes.Length -gt 0) {
      [Array]::Clear($scriptBytes,0,$scriptBytes.Length)
    }
  }
  $decoded = 'eval "$(printf %s ' + $base64 + ' | base64 -d)"'
  if ($Sudo) {
    $remote = "sudo -S -p '' -- bash -c '" + $decoded + "'"
  } else {
    $remote = "bash -c '" + $decoded + "'"
  }
  $remotePlain = $null
  $base64 = $null
  $decoded = $null

  $temp = Join-Path $credentialTemp (
    [Guid]::NewGuid().ToString('N') + '.credential.tmp'
  )
  if (-not [IO.Path]::GetFullPath($temp).StartsWith(
      $credentialTemp + [IO.Path]::DirectorySeparatorChar,
      [StringComparison]::OrdinalIgnoreCase
    )) {
    throw 'NVP_DIAG1_R1_TEMP_BOUNDARY'
  }
  $tempStream = [IO.File]::Open(
    $temp,
    [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write,
    [IO.FileShare]::None
  )
  $tempStream.Dispose()
  $fileAcl = [Security.AccessControl.FileSecurity]::new()
  $fileAcl.SetOwner($sid)
  $fileAcl.SetAccessRuleProtection($true,$false)
  $fileAcl.AddAccessRule(
    [Security.AccessControl.FileSystemAccessRule]::new(
      $sid,
      'FullControl',
      'Allow'
    )
  )
  Set-Acl -LiteralPath $temp -AclObject $fileAcl
  [IO.File]::WriteAllText(
    $temp,
    $pw + [char]10,
    [Text.UTF8Encoding]::new($false)
  )
  $created = $true

  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $plink
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $argsList = @(
    '-batch',
    '-ssh',
    '-4',
    '-P',
    '22',
    '-l',
    $login,
    '-pwfile',
    $temp,
    '-noagent',
    '-noshare',
    '-hostkey',
    $hostKey,
    '-T',
    $ip,
    $remote
  )
  foreach ($argument in $argsList) {
    if ($argument -ceq '-pw') {
      throw 'NVP_DIAG1_R1_SECRET_ARGUMENT'
    }
    if (
      -not [string]::IsNullOrEmpty($pw) -and
      ([string]$argument).Contains($pw,[StringComparison]::Ordinal)
    ) {
      throw 'NVP_DIAG1_R1_SECRET_ARGUMENT'
    }
    [void]$psi.ArgumentList.Add($argument)
  }
  foreach ($environmentKey in @($psi.Environment.Keys)) {
    $environmentValue = [string]$psi.Environment[$environmentKey]
    if (
      $environmentValue -and
      $environmentValue.Contains($pw,[StringComparison]::Ordinal)
    ) {
      [void]$psi.Environment.Remove($environmentKey)
    }
  }

  $proc = [Diagnostics.Process]::new()
  $proc.StartInfo = $psi
  $started = $proc.Start()
  if (-not $started) {
    throw 'NVP_DIAG1_R1_PROCESS_START'
  }
  $outTask = $proc.StandardOutput.ReadToEndAsync()
  $errTask = $proc.StandardError.ReadToEndAsync()
  if ($Sudo) {
    $proc.StandardInput.WriteLine($pw)
  } elseif ($mode -eq 'UPLOAD') {
    $uploadContent = [IO.File]::ReadAllBytes($resolvedUpload)
    try {
      $proc.StandardInput.Write([Convert]::ToBase64String($uploadContent))
    } finally {
      if ($uploadContent.Length -gt 0) {
        [Array]::Clear($uploadContent,0,$uploadContent.Length)
      }
    }
  }
  $proc.StandardInput.Close()
  if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
    $proc.Kill($true)
    $proc.WaitForExit()
    $exitCode = 124
    throw 'NVP_DIAG1_R1_CONNECTION_TIMEOUT'
  }
  $stdout = $outTask.GetAwaiter().GetResult()
  $stderr = $errTask.GetAwaiter().GetResult()
  $exitCode = $proc.ExitCode
} catch {
  $problem = if ($_.Exception.Message -like 'NVP_DIAG1_R1_*') {
    $_.Exception.Message
  } else {
    'NVP_DIAG1_R1_SANITIZED_LOCAL_EXCEPTION'
  }
} finally {
  if ($proc) {
    if ($started) {
      try {
        if (-not $proc.HasExited) {
          $proc.Kill($true)
          $proc.WaitForExit()
        }
      } catch {
        $exitCode = 128
        $problem = 'NVP_DIAG1_R1_LOCAL_PROCESS_CLEANUP_FAILED'
      }
    }
    if ($outTask) {
      try { $stdout = $outTask.GetAwaiter().GetResult() } catch {}
    }
    if ($errTask) {
      try { $stderr = $errTask.GetAwaiter().GetResult() } catch {}
    }
    $proc.Dispose()
  }
  if ($temp -and (Test-Path -LiteralPath $temp)) {
    try {
      Remove-Item -LiteralPath $temp -Force
    } catch {
      $exitCode = 126
      $problem = 'NVP_DIAG1_R1_CREDENTIAL_DELETE_FAILED'
    }
  }
  $deleted = (-not $temp -or -not (Test-Path -LiteralPath $temp))
  if ($pw) {
    $stdout = $stdout.Replace($pw,'<CREDENTIAL_REDACTED>')
    $stderr = $stderr.Replace($pw,'<CREDENTIAL_REDACTED>')
  }
  $maximumCapturedCharacters = 1048576
  if ($stdout.Length -gt $maximumCapturedCharacters) {
    $stdout = $stdout.Substring(0,$maximumCapturedCharacters)
    $outputTruncated = $true
  }
  if ($stderr.Length -gt $maximumCapturedCharacters) {
    $stderr = $stderr.Substring(0,$maximumCapturedCharacters)
    $outputTruncated = $true
  }
}

if (-not $deleted) {
  $exitCode = 126
  $problem = 'NVP_DIAG1_R1_CREDENTIAL_DELETE_FAILED'
}
$remaining = if (Test-Path -LiteralPath $credentialTemp -PathType Container) {
  @(Get-ChildItem -LiteralPath $credentialTemp -Force).Count
} else {
  0
}
if ($remaining -ne 0) {
  $exitCode = 127
  $problem = 'NVP_DIAG1_R1_CREDENTIAL_REMNANT'
}

$result = [ordered]@{
  task = $task
  operation = $Operation
  mode = $mode
  helper = $PSCommandPath
  helper_sha256 = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
  hardware_eligibility_receipt = $hardwareGateReceiptPath
  hardware_eligibility_receipt_sha256 = (
    Get-FileHash -LiteralPath $hardwareGateReceiptPath -Algorithm SHA256
  ).Hash
  eligible_bitstream_sha256 = [string]$hardwareGate.BITSTREAM_SHA256
  start_utc = $start
  end_utc = [DateTime]::UtcNow.ToString('o')
  ip = $ip
  login = $login
  host_key = $hostKey
  host_key_pinned = $true
  ipv4_only = $true
  batch_mode = $true
  agent_forwarding = $false
  connection_sharing = $false
  timeout_seconds = $TimeoutSeconds
  sudo = [bool]$Sudo
  remote_plaintext_persisted = $false
  remote_command_bytes = $remoteCommandBytes
  remote_command_sha256 = $remoteCommandSha256
  credential_in_process_arguments = $false
  temporary_path_class = 'NVP_DIAG1_R1_PRIVATE_CREDENTIAL_TEMP'
  temporary_created = $created
  temporary_deleted = $deleted
  credential_temp_remaining = $remaining
  process_started = $started
  upload_bytes = $uploadBytes
  upload_sha256 = $uploadSha256
  output_truncated = $outputTruncated
  exit_code = $exitCode
  problem = $problem
  stdout = $stdout
  stderr = $stderr
}
$json = $result | ConvertTo-Json -Depth 6
Write-NewUtf8File -Path $receipt -Text ($json + [char]10)
$pw = $null
Write-Output $json
if ($exitCode -ne 0 -or $problem) {
  throw 'NVP_DIAG1_R1_CONNECTION_FAILED_SEE_RECEIPT'
}
