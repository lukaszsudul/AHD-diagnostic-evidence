[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('Command', 'Upload', 'Download')]
    [string]$Mode,

    [Parameter(Mandatory = $true)]
    [string]$CredentialPath,

    [Parameter(Mandatory = $true)]
    [string]$ReceiptPath,

    [string]$RemoteCommand,
    [string]$LocalPath,
    [string]$RemotePath,

    [ValidateRange(0, 4)]
    [int]$SudoPasswordCopies = 0,

    [ValidateRange(5, 600)]
    [int]$TimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RunRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z'
$PrivateRoot = Join-Path $RunRoot 'private'
$ReceiptRoot = Join-Path $RunRoot 'local_evidence'
$ArtifactRoot = Join-Path $RunRoot 'local_artifacts'
$RemoteRunRoot = '/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r1/20260906T172600Z'
$PinnedCredentialPath = 'C:\FPGA\VCDE-DUT-1.txt'
$PlinkPath = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$PlinkSha256 = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
$ExpectedIp = '10.132.1.111'
$ExpectedUser = 'vcdeagent1'
$PinnedHostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$PredecessorPattern = '(?i)G2B_HW0_(?:PRODUCT_R(?:1|2|3)(?:_|[\\/]|$)|DRV1(?:_|[\\/]|$))|G2B_LUT1_SIGNOFF_RECOVERY4(?:_|[\\/]|$)'

function Get-FullPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd(
        [IO.Path]::DirectorySeparatorChar,
        [IO.Path]::AltDirectorySeparatorChar
    )
}

function Test-Descendant {
    param(
        [Parameter(Mandatory = $true)][string]$Candidate,
        [Parameter(Mandatory = $true)][string]$Parent
    )
    $candidateFull = Get-FullPath $Candidate
    $parentFull = Get-FullPath $Parent
    return $candidateFull.StartsWith(
        $parentFull + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )
}

function Assert-NoPredecessorPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ($Path -match $PredecessorPattern) {
        throw 'R3R1_PREDECESSOR_PATH_REJECTED'
    }
}

function Get-CredentialFields {
    param([Parameter(Mandatory = $true)][string]$Text)
    $fields = @{}
    foreach ($rawLine in ($Text -split "\r?\n")) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) {
            continue
        }
        $match = [regex]::Match($line, '^\s*([^:=]+?)\s*[:=]\s*(.*)\s*$')
        if (-not $match.Success) {
            throw 'R3R1_CREDENTIAL_FORMAT_REJECTED'
        }
        $label = ($match.Groups[1].Value -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
        $value = $match.Groups[2].Value
        switch ($label) {
            'ip' { $name = 'ip' }
            'adresip' { $name = 'ip' }
            'user' { $name = 'user' }
            'username' { $name = 'user' }
            'uzytkownik' { $name = 'user' }
            'sudouser' { $name = 'user' }
            'password' { $name = 'password' }
            'haslo' { $name = 'password' }
            default { throw 'R3R1_CREDENTIAL_FIELD_REJECTED' }
        }
        if ($fields.ContainsKey($name)) {
            throw 'R3R1_CREDENTIAL_DUPLICATE_FIELD'
        }
        $fields[$name] = $value
    }
    if ($fields.Count -ne 3) {
        throw 'R3R1_CREDENTIAL_FIELD_COUNT_REJECTED'
    }
    return $fields
}

function New-PrivateFileAcl {
    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $security = [Security.AccessControl.FileSecurity]::new()
    $security.SetOwner($currentSid)
    $security.SetAccessRuleProtection($true, $false)
    $rule = [Security.AccessControl.FileSystemAccessRule]::new(
        $currentSid,
        [Security.AccessControl.FileSystemRights]::FullControl,
        [Security.AccessControl.AccessControlType]::Allow
    )
    $security.AddAccessRule($rule)
    return $security
}

function Assert-PrivateFileAcl {
    param([Parameter(Mandatory = $true)][string]$Path)
    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $actual = Get-Acl -LiteralPath $Path
    $rules = @($actual.GetAccessRules(
        $true,
        $true,
        [Security.Principal.SecurityIdentifier]
    ))
    if (-not $actual.AreAccessRulesProtected -or
        $rules.Count -ne 1 -or
        $rules[0].IdentityReference.Value -cne $currentSid.Value -or
        $rules[0].AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow) {
        throw 'R3R1_PRIVATE_FILE_ACL_REJECTED'
    }
}

function Assert-RemotePath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if ($Path -notmatch '^/[A-Za-z0-9._/-]+$') {
        throw 'R3R1_REMOTE_PATH_CHARACTERS_REJECTED'
    }
    if (-not $Path.StartsWith($RemoteRunRoot + '/', [StringComparison]::Ordinal)) {
        throw 'R3R1_REMOTE_PATH_BOUNDARY_REJECTED'
    }
}

$startedUtc = [DateTime]::UtcNow.ToString('o')
$credentialText = $null
$password = $null
$passwordFile = $null
$process = $null
$stdout = ''
$stderr = ''
$exitCode = 125
$result = 'NOT_STARTED'
$credentialFileCreated = 'NO'
$credentialFileDeleted = 'YES'
$argumentAudit = 'NOT_RUN'
$environmentAudit = 'NOT_RUN'
$transferBytes = 0
$transferSha256 = 'NONE'
$receiptPathValidated = 'NO'

try {
    if (-not (Test-Path -LiteralPath $RunRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $PrivateRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $ReceiptRoot -PathType Container) -or
        -not (Test-Path -LiteralPath $ArtifactRoot -PathType Container)) {
        throw 'R3R1_LOCAL_ROOT_PRECONDITION_FAILED'
    }
    Assert-NoPredecessorPath $RunRoot
    Assert-NoPredecessorPath $ReceiptPath
    if (-not (Test-Descendant -Candidate $ReceiptPath -Parent $ReceiptRoot)) {
        throw 'R3R1_RECEIPT_PATH_OUTSIDE_ALLOWLIST'
    }
    if (Test-Path -LiteralPath $ReceiptPath) {
        throw 'R3R1_RECEIPT_ALREADY_EXISTS'
    }
    $receiptParent = Split-Path -Parent (Get-FullPath $ReceiptPath)
    if (-not (Test-Path -LiteralPath $receiptParent -PathType Container)) {
        throw 'R3R1_RECEIPT_PARENT_MISSING'
    }
    $receiptPathValidated = 'YES'
    if ((Get-FullPath $CredentialPath) -cne (Get-FullPath $PinnedCredentialPath)) {
        throw 'R3R1_CREDENTIAL_SOURCE_NOT_PINNED'
    }
    Assert-NoPredecessorPath $CredentialPath
    if (-not (Test-Path -LiteralPath $CredentialPath -PathType Leaf)) {
        throw 'R3R1_CREDENTIAL_SOURCE_MISSING'
    }
    if (-not (Test-Path -LiteralPath $PlinkPath -PathType Leaf)) {
        throw 'R3R1_PLINK_MISSING'
    }
    if ((Get-FileHash -LiteralPath $PlinkPath -Algorithm SHA256).Hash -cne $PlinkSha256) {
        throw 'R3R1_PLINK_HASH_MISMATCH'
    }

    switch ($Mode) {
        'Command' {
            if ([string]::IsNullOrWhiteSpace($RemoteCommand) -or $LocalPath -or $RemotePath) {
                throw 'R3R1_COMMAND_MODE_ARGUMENT_REJECTED'
            }
        }
        'Upload' {
            if ($RemoteCommand -or -not $LocalPath -or -not $RemotePath -or $SudoPasswordCopies -ne 0) {
                throw 'R3R1_UPLOAD_MODE_ARGUMENT_REJECTED'
            }
            Assert-NoPredecessorPath $LocalPath
            if (-not (Test-Descendant -Candidate $LocalPath -Parent $RunRoot) -or
                (Test-Descendant -Candidate $LocalPath -Parent $PrivateRoot) -or
                -not (Test-Path -LiteralPath $LocalPath -PathType Leaf)) {
                throw 'R3R1_UPLOAD_SOURCE_REJECTED'
            }
            Assert-RemotePath $RemotePath
            $RemoteCommand = "umask 077; base64 -d > '$RemotePath'"
        }
        'Download' {
            if ($RemoteCommand -or -not $LocalPath -or -not $RemotePath -or $SudoPasswordCopies -ne 0) {
                throw 'R3R1_DOWNLOAD_MODE_ARGUMENT_REJECTED'
            }
            Assert-NoPredecessorPath $LocalPath
            if (-not (Test-Descendant -Candidate $LocalPath -Parent $ArtifactRoot) -or
                (Test-Path -LiteralPath $LocalPath)) {
                throw 'R3R1_DOWNLOAD_DESTINATION_REJECTED'
            }
            Assert-RemotePath $RemotePath
            $RemoteCommand = "base64 -w 0 -- '$RemotePath'"
        }
    }

    $credentialText = [IO.File]::ReadAllText(
        $CredentialPath,
        [Text.UTF8Encoding]::new($false, $true)
    )
    $fields = Get-CredentialFields $credentialText
    $credentialText = $null
    if ($fields.ip -cne $ExpectedIp -or $fields.user -cne $ExpectedUser) {
        throw 'R3R1_CREDENTIAL_IDENTITY_MISMATCH'
    }
    $password = [string]$fields.password
    $fields.Clear()
    $fields = $null
    if ([string]::IsNullOrEmpty($password)) {
        throw 'R3R1_CREDENTIAL_EMPTY'
    }
    if ($RemoteCommand.Contains($password, [StringComparison]::Ordinal)) {
        throw 'R3R1_PASSWORD_IN_REMOTE_COMMAND'
    }

    $passwordFile = Join-Path $PrivateRoot ("credential-{0}.tmp" -f [Guid]::NewGuid().ToString('N'))
    Assert-NoPredecessorPath $passwordFile
    if (-not (Test-Descendant -Candidate $passwordFile -Parent $PrivateRoot)) {
        throw 'R3R1_TEMP_CREDENTIAL_BOUNDARY_REJECTED'
    }
    $stream = [IO.File]::Open(
        $passwordFile,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    $stream.Dispose()
    Set-Acl -LiteralPath $passwordFile -AclObject (New-PrivateFileAcl)
    [IO.File]::WriteAllText(
        $passwordFile,
        $password + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )
    $credentialFileCreated = 'YES'
    Assert-PrivateFileAcl $passwordFile

    $arguments = [Collections.Generic.List[string]]::new()
    foreach ($argument in @(
        '-batch', '-ssh', '-4', '-P', '22', '-l', $ExpectedUser,
        '-pwfile', $passwordFile, '-noagent', '-noshare',
        '-hostkey', $PinnedHostKey, '-T', $ExpectedIp, $RemoteCommand
    )) {
        [void]$arguments.Add($argument)
    }
    if ($arguments.Contains('-pw')) {
        throw 'R3R1_PASSWORD_ARGUMENT_REJECTED'
    }
    $loginIndex = $arguments.IndexOf('-l')
    $pwfileIndex = $arguments.IndexOf('-pwfile')
    if ($loginIndex -lt 0 -or $arguments[$loginIndex + 1] -cne $ExpectedUser -or
        $pwfileIndex -lt 0 -or $arguments[$pwfileIndex + 1] -cne $passwordFile) {
        throw 'R3R1_PWFILE_ARGUMENT_REJECTED'
    }
    for ($index = 0; $index -lt $arguments.Count; $index++) {
        if ($index -eq ($loginIndex + 1)) {
            continue
        }
        if ($arguments[$index].Contains($password, [StringComparison]::Ordinal)) {
            throw 'R3R1_PASSWORD_ARGUMENT_REJECTED'
        }
    }
    $argumentAudit = 'PASS'

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $PlinkPath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardInput = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    foreach ($entry in @($startInfo.Environment.GetEnumerator())) {
        if ($null -ne $entry.Value -and
            ([string]$entry.Value).Contains($password, [StringComparison]::Ordinal)) {
            [void]$startInfo.Environment.Remove([string]$entry.Key)
        }
    }
    foreach ($entry in @($startInfo.Environment.GetEnumerator())) {
        if ($null -ne $entry.Value -and
            ([string]$entry.Value).Contains($password, [StringComparison]::Ordinal)) {
            throw 'R3R1_PASSWORD_ENVIRONMENT_REJECTED'
        }
    }
    $environmentAudit = 'PASS'

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'R3R1_PROCESS_START_FAILED'
    }
    if ($Mode -eq 'Command') {
        for ($copy = 0; $copy -lt $SudoPasswordCopies; $copy++) {
            $process.StandardInput.WriteLine($password)
        }
    }
    elseif ($Mode -eq 'Upload') {
        $sourceBytes = [IO.File]::ReadAllBytes($LocalPath)
        $transferBytes = $sourceBytes.Length
        $transferSha256 = (Get-FileHash -LiteralPath $LocalPath -Algorithm SHA256).Hash
        $process.StandardInput.WriteLine([Convert]::ToBase64String($sourceBytes))
        [Array]::Clear($sourceBytes, 0, $sourceBytes.Length)
    }
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        $exitCode = 124
        throw 'R3R1_PROCESS_TIMEOUT'
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
    $result = if ($exitCode -eq 0) { 'PASS' } else { 'REMOTE_OR_TRANSPORT_FAILURE' }

    if ($exitCode -eq 0 -and $Mode -eq 'Download') {
        try {
            $downloadBytes = [Convert]::FromBase64String($stdout.Trim())
        }
        catch {
            throw 'R3R1_DOWNLOAD_BASE64_REJECTED'
        }
        $downloadParent = Split-Path -Parent (Get-FullPath $LocalPath)
        if (-not (Test-Path -LiteralPath $downloadParent -PathType Container)) {
            throw 'R3R1_DOWNLOAD_PARENT_MISSING'
        }
        $handle = [IO.File]::Open(
            $LocalPath,
            [IO.FileMode]::CreateNew,
            [IO.FileAccess]::Write,
            [IO.FileShare]::None
        )
        try {
            $handle.Write($downloadBytes, 0, $downloadBytes.Length)
        }
        finally {
            $handle.Dispose()
        }
        $transferBytes = $downloadBytes.Length
        $transferSha256 = (Get-FileHash -LiteralPath $LocalPath -Algorithm SHA256).Hash
        [Array]::Clear($downloadBytes, 0, $downloadBytes.Length)
        $stdout = '<DOWNLOADED_PAYLOAD_NOT_LOGGED>'
    }
}
catch {
    $localFailure = if ($_.Exception.Message -like 'R3R1_*') {
        $_.Exception.Message
    } else {
        'R3R1_SANITIZED_EXCEPTION'
    }
    if ($result -eq 'NOT_STARTED' -or $result -eq 'PASS') {
        $result = $localFailure
        if ($exitCode -eq 0) {
            $exitCode = 125
        }
    }
}
finally {
    if ($null -ne $process) {
        try {
            if (-not $process.HasExited) {
                $process.Kill($true)
                $process.WaitForExit()
            }
        }
        catch {
        }
        $process.Dispose()
    }
    if ($passwordFile -and (Test-Path -LiteralPath $passwordFile)) {
        Remove-Item -LiteralPath $passwordFile -Force
    }
    $credentialFileDeleted = if ($passwordFile -and (Test-Path -LiteralPath $passwordFile)) { 'NO' } else { 'YES' }
}

if ($password) {
    $stdout = $stdout.Replace($password, '<CREDENTIAL_REDACTED>')
    $stderr = $stderr.Replace($password, '<CREDENTIAL_REDACTED>')
}
if ($credentialFileDeleted -ne 'YES') {
    $result = 'R3R1_TEMP_CREDENTIAL_DELETE_FAILED'
    $exitCode = 126
}
$outputAudit = if ($password -and
    ($stdout.Contains($password, [StringComparison]::Ordinal) -or
     $stderr.Contains($password, [StringComparison]::Ordinal))) { 'FAIL' } else { 'PASS' }

$receipt = @(
    "TASK=G2B-HW0-PRODUCT-R3R1",
    "UTC_START=$startedUtc",
    "UTC_END=$([DateTime]::UtcNow.ToString('o'))",
    "MODE=$Mode",
    "RESULT=$result",
    "EXIT_CODE=$exitCode",
    "TARGET_IP=$ExpectedIp",
    "HOST_KEY_PINNED=YES",
    "PLINK_SHA256=$PlinkSha256",
    "ARGUMENT_TOKEN_AUDIT=$argumentAudit",
    "PASSWORD_IN_PROCESS_ARGUMENTS=NO",
    "INHERITED_ENVIRONMENT_AUDIT=$environmentAudit",
    "TEMP_CREDENTIAL_PATH_CLASS=R3R1_PRIVATE_DESCENDANT",
    "TEMP_CREDENTIAL_FILE_CREATED=$credentialFileCreated",
    "TEMP_CREDENTIAL_FILE_DELETED=$credentialFileDeleted",
    "OUTPUT_CREDENTIAL_REDACTION_AUDIT=$outputAudit",
    "TRANSFER_BYTES=$transferBytes",
    "TRANSFER_SHA256=$transferSha256",
    'STDOUT_BEGIN',
    $stdout.TrimEnd(),
    'STDOUT_END',
    'STDERR_BEGIN',
    $stderr.TrimEnd(),
    'STDERR_END'
)
if ($receiptPathValidated -eq 'YES') {
    [IO.File]::WriteAllLines($ReceiptPath, $receipt, [Text.UTF8Encoding]::new($false))
}

$password = $null
$credentialText = $null
$stdout = ''
$stderr = ''
[GC]::Collect()

Write-Output "RESULT=$result"
Write-Output "EXIT_CODE=$exitCode"
Write-Output "TEMP_CREDENTIAL_FILE_DELETED=$credentialFileDeleted"
Write-Output "OUTPUT_CREDENTIAL_REDACTION_AUDIT=$outputAudit"
exit $exitCode
