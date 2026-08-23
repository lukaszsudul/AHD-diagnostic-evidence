[CmdletBinding()]
param(
    [string]$ResultPath = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\09_FINAL\R5_SECRET_SCAN_GUIDANCE_AND_RESULT.md'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$selfPath = $PSCommandPath
$resultPath = [IO.Path]::GetFullPath($ResultPath)
$allowedResultRoot = [IO.Path]::GetFullPath((Join-Path $taskRoot '09_FINAL'))
if (-not $resultPath.StartsWith(
    $allowedResultRoot + [IO.Path]::DirectorySeparatorChar,
    [StringComparison]::OrdinalIgnoreCase
)) {
    throw 'secret-scan result must stay inside the R5 09_FINAL directory'
}
$textExtensions = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase
)
foreach ($extension in @('.md','.txt','.csv','.log','.ps1','.py','.sh','.tcl','.json','.jou')) {
    [void]$textExtensions.Add($extension)
}

if (Test-Path -LiteralPath $resultPath) {
    throw 'refusing to overwrite existing R5 secret-scan result'
}

$patterns = [ordered]@{
    PRIVATE_KEY_HEADER = '-----BEGIN (?:RSA |OPENSSH |EC |DSA )?PRIVATE KEY-----'
    GITHUB_TOKEN = '\bgh[pousr]_[A-Za-z0-9]{20,}\b'
    AWS_ACCESS_KEY = '\b(?:AKIA|ASIA)[A-Z0-9]{16}\b'
    JWT = '\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b'
    AUTHORIZATION_BEARER = '(?i)Authorization\s*:\s*Bearer\s+[A-Za-z0-9._~+/-]{12,}'
    QUOTED_PASSWORD_LITERAL = '(?i)\b(?:password|passwd|pwd)\s*[:=]\s*["''][^"''\r\n]{1,}["'']'
    EXECUTABLE_PUTTY_INLINE_PW = '(?i)(?:^|[\s"''])-pw\s+(?!(?:file|form|option|used|forbidden|and)\b)[^\s`"'']+'
}

$files = @(Get-ChildItem -LiteralPath $taskRoot -Recurse -File -Force |
    Where-Object {
        $textExtensions.Contains($_.Extension) -and
        $_.FullName -cne $selfPath -and
        $_.FullName -cne $resultPath -and
        -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint)
    } | Sort-Object FullName)

$secretFindings = [Collections.Generic.List[object]]::new()
foreach ($file in $files) {
    $text = [IO.File]::ReadAllText($file.FullName)
    foreach ($entry in $patterns.GetEnumerator()) {
        foreach ($match in [regex]::Matches($text, $entry.Value)) {
            $lineNumber = 1 + [regex]::Matches($text.Substring(0, $match.Index), "`n").Count
            $secretFindings.Add([pscustomobject]@{
                Pattern = $entry.Key
                RelativePath = [IO.Path]::GetRelativePath($taskRoot, $file.FullName)
                Line = $lineNumber
            })
        }
    }
}

$credentialCopies = @(Get-ChildItem -LiteralPath $taskRoot -Recurse -File -Force |
    Where-Object { $_.Name -ieq 'VCDE-DUT-1.txt' })
$sessionLogs = @(Get-ChildItem -LiteralPath (Join-Path $taskRoot '04_HOST_SAFETY_DISCOVERY') -File |
    Where-Object Name -Match '^HOST_STABILITY_SESSION_[123]\.log$' |
    Sort-Object Name)
$receiptFailures = [Collections.Generic.List[string]]::new()
foreach ($log in $sessionLogs) {
    $text = [IO.File]::ReadAllText($log.FullName)
    foreach ($required in @(
        'RESULT=PASS',
        'PLINK_PW_OPTION_USED=NO',
        'PLINK_PWFILE_OPTION_USED=YES',
        'PASSWORD_ROLE_ARGUMENT_OCCURRENCE=NO',
        'REMOTE_COMMAND_SHARED_LITERAL=NO',
        'INHERITED_ENVIRONMENT_AUDIT=PASS',
        'PWFILE_DELETED=YES'
    )) {
        if ([regex]::Matches($text, '(?m)^' + [regex]::Escape($required) + '\r?$').Count -ne 1) {
            $receiptFailures.Add("$($log.Name):$required")
        }
    }
}

$gate = if (
    $secretFindings.Count -eq 0 -and
    $credentialCopies.Count -eq 0 -and
    $sessionLogs.Count -eq 3 -and
    $receiptFailures.Count -eq 0
) { 'PASS' } else { 'FAIL' }

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# R5 evidence secret-scan guidance and result')
$lines.Add('')
$lines.Add('The scan was local and read-only. It did not open the external credential file, start a network process, or invoke Vivado/JTAG/MMIO/reboot/driver tooling.')
$lines.Add('')
$lines.Add('## Result')
$lines.Add('')
$lines.Add("TEXT_FILES_SCANNED=$($files.Count)")
$lines.Add("HIGH_CONFIDENCE_SECRET_MATCHES=$($secretFindings.Count)")
$lines.Add("CREDENTIAL_FILE_COPIES_INSIDE_TASK_ROOT=$($credentialCopies.Count)")
$lines.Add("CONTEXTUAL_PLINK_SESSION_RECEIPTS=$($sessionLogs.Count)")
$lines.Add("CONTEXTUAL_PLINK_RECEIPT_FAILURES=$($receiptFailures.Count)")
$lines.Add('EXTERNAL_CREDENTIAL_FILE_OPENED_BY_SCAN=NO')
$lines.Add('NETWORK_OR_HARDWARE_ACTIONS_BY_SCAN=0')
$lines.Add("SECRET_SCAN_GATE=$gate")
if ($secretFindings.Count -gt 0) {
    $lines.Add('')
    $lines.Add('## High-confidence matches requiring review')
    $lines.Add('')
    foreach ($item in $secretFindings) {
        $lines.Add("- $($item.Pattern): $($item.RelativePath):$($item.Line)")
    }
}
if ($receiptFailures.Count -gt 0) {
    $lines.Add('')
    $lines.Add('## Credential-safe transport receipt failures')
    $lines.Add('')
    foreach ($failure in $receiptFailures) { $lines.Add("- $failure") }
}
$lines.Add('')
$lines.Add('## Packaging guidance')
$lines.Add('')
$lines.Add('- Never package `C:\FPGA\VCDE-DUT-1.txt` or any temporary pwfile.')
$lines.Add('- Preserve the contextual transport receipts proving `-pwfile`, pinned host key, `-batch`, `-noagent`, `-noshare`, no inline `-pw`, and pwfile deletion.')
$lines.Add('- After all final text evidence is staged, re-run this scanner with `-ResultPath` set to a fresh file under `09_FINAL`; do not overwrite an earlier result.')
$lines.Add('- Hash the sealed package after the final scan. Do not include an evidence ZIP inside itself.')
$lines.Add('- Treat any later private-key header, bearer/JWT/API token, quoted password literal, inline PuTTY password, or credential-file copy as a publication blocker.')

[IO.File]::WriteAllLines($resultPath, $lines, [Text.UTF8Encoding]::new($false))
$lines | Select-Object -Skip 5 -First 9
if ($gate -cne 'PASS') { exit 1 }
exit 0
