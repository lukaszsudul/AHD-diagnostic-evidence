[CmdletBinding(DefaultParameterSetName='Command')]
param(
  [Parameter(Mandatory,ParameterSetName='Command')][string]$RemoteCommand,
  [Parameter(Mandatory,ParameterSetName='Upload')][string]$UploadFile,
  [Parameter(Mandatory,ParameterSetName='Upload')][string]$RemotePath,
  [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9_-]+$')][string]$ReceiptName,
  [Parameter(ParameterSetName='Command')][switch]$Sudo,
  [ValidateRange(5,600)][int]$TimeoutSeconds=60
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R1_20260907T050126Z'
$linuxRun = '/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r1/20260907T050126Z'
$private = Join-Path $run 'private'
$credentialTemp = Join-Path $private 'credential-temp'
$receipt = Join-Path $run ('logs\connection-' + $ReceiptName + '.json')
$plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$plinkHash = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$hostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$login = 'vcdeagent1'
$ip = '10.132.1.111'
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User

function Assert-PrivateAcl([string]$Path) {
  $acl = Get-Acl -LiteralPath $Path
  $rules = @($acl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
  if (-not $acl.AreAccessRulesProtected -or $rules.Count -ne 1 -or
      $rules[0].IdentityReference.Value -cne $sid.Value -or
      $rules[0].AccessControlType -ne 'Allow') {
    throw 'R3R4R1_PRIVATE_ACL_INVALID'
  }
}

if ([IO.Path]::GetFullPath($PSScriptRoot) -cne (Join-Path $run 'scripts')) {
  throw 'R3R4R1_HELPER_LOCATION_INVALID'
}
if (Test-Path -LiteralPath $receipt) { throw 'R3R4R1_RECEIPT_EXISTS' }
if (-not (Test-Path -LiteralPath $credentialTemp -PathType Container)) {
  New-Item -ItemType Directory -Path $credentialTemp | Out-Null
  $acl = [Security.AccessControl.DirectorySecurity]::new()
  $acl.SetOwner($sid)
  $acl.SetAccessRuleProtection($true,$false)
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new(
    $sid,'FullControl','ContainerInherit,ObjectInherit','None','Allow'))
  Set-Acl -LiteralPath $credentialTemp -AclObject $acl
}
Assert-PrivateAcl $private
Assert-PrivateAcl $credentialTemp
if (@(Get-ChildItem -LiteralPath $credentialTemp -Force).Count) {
  throw 'R3R4R1_CREDENTIAL_TEMP_NOT_EMPTY'
}
if ((Get-FileHash -LiteralPath $plink).Hash -cne $plinkHash) {
  throw 'R3R4R1_PLINK_HASH_MISMATCH'
}

$pw = $null
$temp = $null
$proc = $null
$stdout = ''
$stderr = ''
$exitCode = 125
$start = [DateTime]::UtcNow.ToString('o')
$created = $false
$deleted = $false
$started = $false
$problem = $null
$mode = $PSCmdlet.ParameterSetName.ToUpperInvariant()
$uploadBytes = 0
$uploadSha256 = $null

try {
  $fields = @{}
  foreach ($line in [IO.File]::ReadAllLines('C:\FPGA\VCDE-DUT-1.txt')) {
    if (-not $line.Trim() -or $line.Trim().StartsWith('#')) { continue }
    if ($line -notmatch '^\s*([^:=]+?)\s*[:=]\s*(.*?)\s*$') {
      throw 'R3R4R1_CREDENTIAL_FORMAT'
    }
    $label = ($Matches[1] -replace '[^A-Za-z0-9]','').ToLowerInvariant()
    $val = $Matches[2]
    $key = switch ($label) {
      {$_ -in @('ip','adresip')} {'ip'}
      {$_ -in @('user','username','uzytkownik','sudouser')} {'user'}
      {$_ -in @('password','haslo')} {'password'}
      default { throw 'R3R4R1_CREDENTIAL_FIELD' }
    }
    if ($fields.ContainsKey($key)) { throw 'R3R4R1_DUPLICATE_CREDENTIAL_FIELD' }
    $fields[$key] = $val
  }
  if ($fields.Count -ne 3 -or $fields.ip -cne $ip -or $fields.user -cne $login) {
    throw 'R3R4R1_CREDENTIAL_IDENTITY'
  }
  $pw = [string]$fields.password
  $fields.Clear()
  $val = $null
  $line = $null
  if ([string]::IsNullOrWhiteSpace($pw)) { throw 'R3R4R1_EMPTY_CREDENTIAL' }

  if ($mode -eq 'UPLOAD') {
    $resolvedUpload = [IO.Path]::GetFullPath($UploadFile)
    if (-not $resolvedUpload.StartsWith((Join-Path $run 'scripts') + '\',[StringComparison]::OrdinalIgnoreCase)) {
      throw 'R3R4R1_UPLOAD_SOURCE_BOUNDARY'
    }
    if (-not (Test-Path -LiteralPath $resolvedUpload -PathType Leaf)) {
      throw 'R3R4R1_UPLOAD_SOURCE_MISSING'
    }
    $escapedRun = [Regex]::Escape($linuxRun)
    if ($RemotePath -notmatch ('^' + $escapedRun + '/scripts/[A-Za-z0-9._-]+$')) {
      throw 'R3R4R1_UPLOAD_DESTINATION_BOUNDARY'
    }
    $uploadBytes = (Get-Item -LiteralPath $resolvedUpload).Length
    $uploadSha256 = (Get-FileHash -LiteralPath $resolvedUpload).Hash
    $remotePlain = "umask 077; base64 -d > '$RemotePath'; chmod 600 '$RemotePath'"
  } else {
    $remotePlain = $RemoteCommand.Replace("`r`n","`n")
  }

  $scriptBytes = [Text.Encoding]::UTF8.GetBytes($remotePlain)
  $b64 = [Convert]::ToBase64String($scriptBytes)
  $decoded = 'eval "$(printf %s ' + $b64 + ' | base64 -d)"'
  $remote = if ($Sudo) { "sudo -S -p '' -- bash -c '" + $decoded + "'" } else { "bash -c '" + $decoded + "'" }

  $temp = Join-Path $credentialTemp ([Guid]::NewGuid().ToString('N') + '.credential.tmp')
  if (-not [IO.Path]::GetFullPath($temp).StartsWith($credentialTemp + '\',[StringComparison]::OrdinalIgnoreCase)) {
    throw 'R3R4R1_TEMP_BOUNDARY'
  }
  $stream = [IO.File]::Open($temp,'CreateNew','Write','None')
  $stream.Dispose()
  $acl = [Security.AccessControl.FileSecurity]::new()
  $acl.SetOwner($sid)
  $acl.SetAccessRuleProtection($true,$false)
  $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($sid,'FullControl','Allow'))
  Set-Acl -LiteralPath $temp -AclObject $acl
  Assert-PrivateAcl $temp
  [IO.File]::WriteAllText($temp,$pw + "`n",[Text.UTF8Encoding]::new($false))
  $created = $true

  $psi = [Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $plink
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $argsList = @('-batch','-ssh','-4','-P','22','-l',$login,'-pwfile',$temp,
                '-noagent','-noshare','-hostkey',$hostKey,'-T',$ip,$remote)
  for ($i=0; $i -lt $argsList.Count; $i++) {
    if ($argsList[$i] -ceq '-pw') { throw 'R3R4R1_SECRET_ARGUMENT' }
    if ($i -ne 6 -and $argsList[$i].Contains($pw,[StringComparison]::Ordinal)) {
      throw 'R3R4R1_SECRET_ARGUMENT'
    }
    [void]$psi.ArgumentList.Add($argsList[$i])
  }
  foreach ($entry in @($psi.Environment.GetEnumerator())) {
    if ($entry.Value -and ([string]$entry.Value).Contains($pw,[StringComparison]::Ordinal)) {
      [void]$psi.Environment.Remove($entry.Key)
    }
  }

  $proc = [Diagnostics.Process]::new()
  $proc.StartInfo = $psi
  $started = $proc.Start()
  if (-not $started) { throw 'R3R4R1_PROCESS_START' }
  $outTask = $proc.StandardOutput.ReadToEndAsync()
  $errTask = $proc.StandardError.ReadToEndAsync()
  if ($Sudo) {
    $proc.StandardInput.WriteLine($pw)
  } elseif ($mode -eq 'UPLOAD') {
    $bytes = [IO.File]::ReadAllBytes($resolvedUpload)
    $proc.StandardInput.Write([Convert]::ToBase64String($bytes))
    [Array]::Clear($bytes,0,$bytes.Length)
  }
  $proc.StandardInput.Close()
  if (-not $proc.WaitForExit($TimeoutSeconds * 1000)) {
    $proc.Kill($true)
    $proc.WaitForExit()
    $exitCode = 124
    throw 'R3R4R1_CONNECTION_TIMEOUT'
  }
  $stdout = $outTask.GetAwaiter().GetResult()
  $stderr = $errTask.GetAwaiter().GetResult()
  $exitCode = $proc.ExitCode
} catch {
  $problem = if ($_.Exception.Message -like 'R3R4R1_*') {
    $_.Exception.Message
  } else {
    'R3R4R1_SANITIZED_LOCAL_EXCEPTION'
  }
} finally {
  if ($proc) {
    if (-not $proc.HasExited) { $proc.Kill($true); $proc.WaitForExit() }
    $proc.Dispose()
  }
  if ($temp -and (Test-Path -LiteralPath $temp)) {
    Remove-Item -LiteralPath $temp -Force
  }
  $deleted = (-not $temp -or -not (Test-Path -LiteralPath $temp))
  if ($pw) {
    $stdout = $stdout.Replace($pw,'<CREDENTIAL_REDACTED>')
    $stderr = $stderr.Replace($pw,'<CREDENTIAL_REDACTED>')
  }
}

if (-not $deleted) { $exitCode=126; $problem='R3R4R1_CREDENTIAL_DELETE_FAILED' }
$remaining = @(Get-ChildItem -LiteralPath $credentialTemp -Force).Count
if ($remaining -ne 0) { $exitCode=127; $problem='R3R4R1_CREDENTIAL_REMNANT' }
$result = [ordered]@{
  task='G2B-HW0-PRODUCT-R3R4R1'
  mode=$mode
  helper=$PSCommandPath
  helper_sha256=(Get-FileHash -LiteralPath $PSCommandPath).Hash
  start_utc=$start
  end_utc=[DateTime]::UtcNow.ToString('o')
  ip=$ip
  host_key_pinned=$true
  credential_in_process_arguments=$false
  temporary_path_class='R3R4R1_PRIVATE_CREDENTIAL_TEMP'
  temporary_created=$created
  temporary_deleted=$deleted
  credential_temp_remaining=$remaining
  process_started=$started
  upload_bytes=$uploadBytes
  upload_sha256=$uploadSha256
  exit_code=$exitCode
  problem=$problem
  stdout=$stdout
  stderr=$stderr
}
$json = $result | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText($receipt,$json + "`n",[Text.UTF8Encoding]::new($false))
$pw = $null
Write-Output $json
if ($exitCode -ne 0 -or $problem) { throw 'R3R4R1_CONNECTION_FAILED_SEE_RECEIPT' }
