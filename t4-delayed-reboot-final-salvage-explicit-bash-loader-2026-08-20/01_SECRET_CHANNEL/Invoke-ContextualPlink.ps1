[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PlinkPath,
    [Parameter(Mandatory = $true)]
    [string]$HostKey,
    [Parameter(Mandatory = $true)]
    [string]$RemoteCommand,
    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedIp,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedUser,
    [Parameter(Mandatory = $true)]
    [string]$EvidenceKind,
    [switch]$SendPasswordToStdin,
    [ValidateRange(1, 32)]
    [int]$SudoPasswordCopies = 1,
    [ValidateRange(5, 600)]
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
$credentialPath = 'C:\FPGA\VCDE-DUT-1.txt'
$secretDirectory = 'C:\FPGA\T4_DELAYED_REBOOT_FINAL_SALVAGE_20260820\01_SECRET_CHANNEL'
$password = $null
$credentialText = $null
$passwordFile = $null
$process = $null
$stdout = ''
$stderr = ''
$safeResult = 'NOT_STARTED'
$exitCode = 99
$pwfileCreated = 'NO'
$pwfileDeleted = 'YES'
$argumentAudit = 'NOT_RUN'
$environmentAudit = 'NOT_RUN'
$utcStart = [DateTime]::UtcNow.ToString('o')

function Get-CanonicalCredential {
    param([string]$Text)
    $fields = @{}
    foreach ($rawLine in ($Text -split "\r?\n")) {
        $line = $rawLine.Trim()
        if (-not $line -or $line.StartsWith('#')) {
            continue
        }
        $match = [regex]::Match($line, '^\s*([^:=]+?)\s*[:=]\s*(.*)\s*$')
        if (-not $match.Success) {
            throw 'SANITIZED_CREDENTIAL_FORMAT'
        }
        $label = ($match.Groups[1].Value -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
        $value = $match.Groups[2].Value
        switch ($label) {
            'ip' { $canonical = 'ip' }
            'adresip' { $canonical = 'ip' }
            'user' { $canonical = 'user' }
            'username' { $canonical = 'user' }
            'uzytkownik' { $canonical = 'user' }
            'sudouser' { $canonical = 'user' }
            'password' { $canonical = 'password' }
            'haslo' { $canonical = 'password' }
            default { throw 'SANITIZED_CREDENTIAL_FORMAT' }
        }
        if ($fields.ContainsKey($canonical)) {
            throw 'SANITIZED_CREDENTIAL_AMBIGUOUS'
        }
        $fields[$canonical] = $value
    }
    if ($fields.Count -ne 3) {
        throw 'SANITIZED_CREDENTIAL_FORMAT'
    }
    return $fields
}

function Test-ArgumentStructure {
    param(
        [Collections.Generic.List[string]]$Arguments,
        [string]$SharedLiteral,
        [string]$PwfilePath,
        [string]$Command
    )
    $pwIndexes = [Collections.Generic.List[int]]::new()
    $pwfileIndexes = [Collections.Generic.List[int]]::new()
    $loginIndexes = [Collections.Generic.List[int]]::new()
    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        if ($Arguments[$index] -ceq '-pw') {
            $pwIndexes.Add($index)
        }
        if ($Arguments[$index] -ceq '-pwfile') {
            $pwfileIndexes.Add($index)
        }
        if ($Arguments[$index] -ceq '-l') {
            $loginIndexes.Add($index)
        }
    }
    if ($pwIndexes.Count -ne 0) {
        return $false
    }
    if ($pwfileIndexes.Count -ne 1 -or $pwfileIndexes[0] + 1 -ge $Arguments.Count) {
        return $false
    }
    if ($Arguments[$pwfileIndexes[0] + 1] -cne $PwfilePath) {
        return $false
    }
    $pwfileFull = [IO.Path]::GetFullPath($PwfilePath)
    $secretFull = [IO.Path]::GetFullPath($secretDirectory)
    if (-not $pwfileFull.StartsWith(
        $secretFull + [IO.Path]::DirectorySeparatorChar,
        [StringComparison]::OrdinalIgnoreCase
    )) {
        return $false
    }
    if ($loginIndexes.Count -ne 1 -or $loginIndexes[0] + 1 -ge $Arguments.Count) {
        return $false
    }
    if ($Arguments[$loginIndexes[0] + 1] -cne $SharedLiteral) {
        return $false
    }
    if ($Command.Contains($SharedLiteral, [StringComparison]::Ordinal)) {
        return $false
    }
    $allowedIndex = $loginIndexes[0] + 1
    for ($index = 0; $index -lt $Arguments.Count; $index++) {
        if ($index -eq $allowedIndex) {
            continue
        }
        if ($Arguments[$index].Contains($SharedLiteral, [StringComparison]::Ordinal)) {
            return $false
        }
    }
    return $true
}

try {
    $credentialText = [IO.File]::ReadAllText(
        $credentialPath,
        [Text.UTF8Encoding]::new($false, $true)
    )
    $fields = Get-CanonicalCredential -Text $credentialText
    $credentialText = $null
    if ($fields.ip -cne $ExpectedIp -or $fields.user -cne $ExpectedUser) {
        throw 'SANITIZED_CREDENTIAL_IDENTITY'
    }
    $password = [string]$fields.password
    if ([string]::IsNullOrEmpty($password)) {
        throw 'SANITIZED_CREDENTIAL_EMPTY'
    }
    if ($fields.user -cne $password) {
        throw 'SANITIZED_CONTEXTUAL_EQUALITY'
    }
    $fields.Clear()
    $fields = $null

    $passwordFile = Join-Path $secretDirectory ("pw-{0}.tmp" -f [Guid]::NewGuid().ToString('N'))
    $arguments = [Collections.Generic.List[string]]::new()
    foreach ($argument in @(
        '-batch',
        '-ssh',
        '-4',
        '-P',
        '22',
        '-l',
        $ExpectedUser,
        '-pwfile',
        $passwordFile,
        '-noagent',
        '-noshare',
        '-hostkey',
        $HostKey,
        '-T',
        $ExpectedIp,
        $RemoteCommand
    )) {
        $arguments.Add($argument)
    }

    if (-not (Test-ArgumentStructure -Arguments $arguments -SharedLiteral $password -PwfilePath $passwordFile -Command $RemoteCommand)) {
        throw 'SANITIZED_ARGUMENT_STRUCTURE'
    }
    $argumentAudit = 'PASS'

    $currentSid = [Security.Principal.WindowsIdentity]::GetCurrent().User
    $systemSid = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
    $fileSecurity = [Security.AccessControl.FileSecurity]::new()
    $fileSecurity.SetOwner($currentSid)
    $fileSecurity.SetAccessRuleProtection($true, $false)
    $fullControl = [Security.AccessControl.FileSystemRights]::FullControl
    $allow = [Security.AccessControl.AccessControlType]::Allow
    $fileSecurity.AddAccessRule(
        [Security.AccessControl.FileSystemAccessRule]::new($currentSid, $fullControl, $allow)
    )
    $fileSecurity.AddAccessRule(
        [Security.AccessControl.FileSystemAccessRule]::new($systemSid, $fullControl, $allow)
    )
    $stream = [IO.File]::Open(
        $passwordFile,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    $stream.Dispose()
    Set-Acl -LiteralPath $passwordFile -AclObject $fileSecurity
    [IO.File]::WriteAllText(
        $passwordFile,
        $password + [Environment]::NewLine,
        [Text.UTF8Encoding]::new($false)
    )
    $pwfileCreated = 'YES'

    $actualAcl = Get-Acl -LiteralPath $passwordFile
    if (-not $actualAcl.AreAccessRulesProtected) {
        throw 'SANITIZED_ACL_INHERITANCE'
    }
    $allowedSids = @($currentSid.Value, $systemSid.Value)
    $rules = $actualAcl.GetAccessRules(
        $true,
        $true,
        [Security.Principal.SecurityIdentifier]
    )
    foreach ($rule in $rules) {
        if ($rule.AccessControlType -ne $allow -or
            $allowedSids -notcontains $rule.IdentityReference.Value) {
            throw 'SANITIZED_ACL_RULE'
        }
    }

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $PlinkPath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.RedirectStandardInput = $true
    foreach ($argument in $arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $removedEnvironmentKeys = [Collections.Generic.List[string]]::new()
    foreach ($entry in @($startInfo.Environment.GetEnumerator())) {
        if ($null -ne $entry.Value -and
            ([string]$entry.Value).Contains($password, [StringComparison]::Ordinal)) {
            $removedEnvironmentKeys.Add([string]$entry.Key)
        }
    }
    foreach ($key in $removedEnvironmentKeys) {
        [void]$startInfo.Environment.Remove($key)
    }
    foreach ($entry in @($startInfo.Environment.GetEnumerator())) {
        if ($null -ne $entry.Value -and
            ([string]$entry.Value).Contains($password, [StringComparison]::Ordinal)) {
            throw 'SANITIZED_ENVIRONMENT_STRUCTURE'
        }
    }
    $environmentAudit = 'PASS'

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'SANITIZED_PROCESS_START'
    }
    if ($SendPasswordToStdin) {
        for ($copy = 0; $copy -lt $SudoPasswordCopies; $copy++) {
            $process.StandardInput.WriteLine($password)
        }
    }
    $process.StandardInput.Close()
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        $process.WaitForExit()
        throw 'SANITIZED_PROCESS_TIMEOUT'
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
    $safeResult = if ($exitCode -eq 0) { 'PASS' } else { 'FAIL' }
}
catch {
    $safeResult = 'SANITIZED_EXCEPTION'
    if ($_.Exception.Message -like 'SANITIZED_*') {
        $safeResult = $_.Exception.Message
    }
    if ($exitCode -eq 99) {
        $exitCode = 99
    }
}
finally {
    if ($null -ne $process) {
        try {
            if (-not $process.HasExited) {
                $process.Kill($true)
            }
        }
        catch {
        }
        $process.Dispose()
    }
    if ($passwordFile -and (Test-Path -LiteralPath $passwordFile)) {
        Remove-Item -LiteralPath $passwordFile -Force
    }
    $pwfileDeleted = if ($passwordFile -and (Test-Path -LiteralPath $passwordFile)) { 'NO' } else { 'YES' }
}

$lines = @(
    "UTC_START=$utcStart",
    "UTC_END=$([DateTime]::UtcNow.ToString('o'))",
    "EVIDENCE_KIND=$EvidenceKind",
    "RESULT=$safeResult",
    "EXIT_CODE=$exitCode",
    "ARGUMENT_TOKEN_AUDIT=$argumentAudit",
    "PLINK_PW_OPTION_USED=NO",
    "PLINK_PWFILE_OPTION_USED=YES",
    "USERNAME_ROLE_OCCURRENCE=YES_AUTHORIZED",
    "PASSWORD_ROLE_ARGUMENT_OCCURRENCE=NO",
    "REMOTE_COMMAND_SHARED_LITERAL=NO",
    "INHERITED_ENVIRONMENT_AUDIT=$environmentAudit",
    "PWFILE_CREATED=$pwfileCreated",
    "PWFILE_DELETED=$pwfileDeleted",
    'STDOUT_BEGIN',
    $stdout.TrimEnd(),
    'STDOUT_END',
    'STDERR_BEGIN',
    $stderr.TrimEnd(),
    'STDERR_END'
)
[IO.File]::WriteAllLines($EvidencePath, $lines, [Text.UTF8Encoding]::new($false))

$password = $null
$credentialText = $null
$stdout = ''
$stderr = ''
[GC]::Collect()

Write-Output "RESULT=$safeResult"
Write-Output "EXIT_CODE=$exitCode"
Write-Output "ARGUMENT_TOKEN_AUDIT=$argumentAudit"
Write-Output "PWFILE_DELETED=$pwfileDeleted"
exit $exitCode

