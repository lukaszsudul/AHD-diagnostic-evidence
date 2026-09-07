[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R5_20260907T151342Z'
$helper = Join-Path $run 'scripts\Invoke-R3R4R5DutConnection.ps1'
$baseline = Join-Path $run 'artifacts\tool-baseline\Invoke-R3R4R4DutConnection.ps1'
$jsonPath = Join-Path $run 'artifacts\G2B_HW0_PRODUCT_R3R4R5_CREDENTIAL_HELPER_HARD_GATE.json'
$mdPath = Join-Path $run 'artifacts\G2B_HW0_PRODUCT_R3R4R5_CREDENTIAL_HELPER_AUDIT.md'
$private = Join-Path $run 'private'
$expectedIp = '10.132.1.111'
$expectedHostKey = 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
$expectedPlinkHash = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'

if ((Test-Path -LiteralPath $jsonPath) -or (Test-Path -LiteralPath $mdPath)) {
  throw 'R3R4R5_CREDENTIAL_AUDIT_OUTPUT_EXISTS'
}

$source = [IO.File]::ReadAllText($helper)
$baseSource = [IO.File]::ReadAllText($baseline)
$normalized = $source.Replace('R3R4R5','R3R4R4').Replace('r3r4r5','r3r4r4').Replace('20260907T151342Z','20260907T135724Z')
$tokens = $null
$parseErrors = $null
[void][Management.Automation.Language.Parser]::ParseFile($helper,[ref]$tokens,[ref]$parseErrors)
$ipValues = @([regex]::Matches($source,'(?<![0-9])(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?![0-9])') | ForEach-Object Value | Sort-Object -Unique)
$privateAcl = Get-Acl -LiteralPath $private
$sid = [Security.Principal.WindowsIdentity]::GetCurrent().User
$privateRules = @($privateAcl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
$plinkMatch = [regex]::Match($source,'\$plink = ''([^'']+)''')
$plinkPath = if ($plinkMatch.Success) { $plinkMatch.Groups[1].Value } else { '' }
$plinkHash = if ($plinkPath -and (Test-Path -LiteralPath $plinkPath -PathType Leaf)) {
  (Get-FileHash -Algorithm SHA256 -LiteralPath $plinkPath).Hash
} else { '' }
$credentialRemnants = @(Get-ChildItem -LiteralPath $private -Recurse -Force -File -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -like '*.credential.tmp' })

$checks = [ordered]@{
  POWERSHELL_SYNTAX = (@($parseErrors).Count -eq 0)
  HELPER_EXACT_LOCATION = ([IO.Path]::GetFullPath($helper) -ceq (Join-Path $run 'scripts\Invoke-R3R4R5DutConnection.ps1'))
  IDENTITY_ONLY_DELTA = ($normalized -ceq $baseSource)
  EXACT_IP_ONLY = ($ipValues.Count -eq 1 -and $ipValues[0] -ceq $expectedIp -and $source.Contains("`$ip = '$expectedIp'"))
  GOVERNED_USER = $source.Contains("`$login = 'vcdeagent1'")
  PINNED_HOST_KEY = ($source.Contains("`$hostKey = '$expectedHostKey'") -and $source.Contains("'-hostkey',`$hostKey"))
  AGENT_AND_SHARING_DISABLED = ($source.Contains("'-noagent','-noshare'"))
  PASSWORD_FILE_ARGUMENT = ($source.Contains("'-pwfile',`$temp") -and -not $source.Contains("'-pw',`$pw"))
  SECRET_ARGUMENT_GUARD = ($source.Contains("throw 'R3R4R5_SECRET_ARGUMENT'") -and $source.Contains("Contains(`$pw,[StringComparison]::Ordinal)"))
  PRIVATE_ACL_RESTRICTED = ($privateAcl.AreAccessRulesProtected -and $privateRules.Count -eq 1 -and $privateRules[0].IdentityReference.Value -ceq $sid.Value)
  TEMP_FILE_CREATE_NEW = $source.Contains("[IO.File]::Open(`$temp,'CreateNew','Write','None')")
  TEMP_FILE_ACL_RESTRICTED = ($source.Contains('[Security.AccessControl.FileSecurity]::new()') -and $source.Contains('Assert-PrivateAcl $temp'))
  TEMP_DELETE_IN_FINALLY = ($source.Contains('} finally {') -and $source.Contains('Remove-Item -LiteralPath $temp -Force'))
  TEMP_REMNANT_ENFORCEMENT = ($source.Contains("R3R4R5_CREDENTIAL_REMNANT") -and $source.Contains('credential_temp_remaining=$remaining'))
  CREDENTIAL_REDACTION = ($source.Contains("Replace(`$pw,'<CREDENTIAL_REDACTED>')"))
  BOUNDED_TIMEOUT = ($source.Contains('[ValidateRange(5,600)]') -and $source.Contains('WaitForExit($TimeoutSeconds * 1000)'))
  REMOTE_EXIT_CODE_PRESERVED = ($source.Contains('$exitCode = $proc.ExitCode') -and $source.Contains('exit_code=$exitCode'))
  PLINK_BINARY_HASH = ($plinkHash -ceq $expectedPlinkHash)
  CREDENTIAL_REMNANTS_ZERO = ($credentialRemnants.Count -eq 0)
}

$failed = @($checks.GetEnumerator() | Where-Object { -not $_.Value } | ForEach-Object Key)
$result = [ordered]@{
  schema = 'R3R4R5_CREDENTIAL_HELPER_HARD_GATE_V1'
  task = 'G2B-HW0-PRODUCT-R3R4R5'
  result = if ($failed.Count -eq 0) { 'PASS' } else { 'FAIL' }
  blocker = if ($failed.Count -eq 0) { 'NONE' } else { 'R3R4R5_CREDENTIAL_HELPER_HARD_GATE_FAILED:' + $failed[0] }
  helper = $helper
  helper_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $helper).Hash
  helper_executed = $false
  dut_connections = 0
  credential_remnants = $credentialRemnants.Count
  exact_ip = $expectedIp
  pinned_host_key = $expectedHostKey
  checks = $checks
  failed_checks = $failed
}
$json = $result | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($jsonPath,$json + [Environment]::NewLine,[Text.UTF8Encoding]::new($false))
$lines = [Collections.Generic.List[string]]::new()
$lines.Add('# G2B-HW0-PRODUCT-R3R4R5 Credential Helper Audit')
$lines.Add('')
$lines.Add("- Result: ``$($result.result)``")
$lines.Add("- Blocker: ``$($result.blocker)``")
$lines.Add("- Helper: ``$helper``")
$lines.Add("- Helper SHA-256: ``$($result.helper_sha256)``")
$lines.Add('- Helper executed during audit: `NO`')
$lines.Add('- DUT connections during audit: `0`')
$lines.Add("- Credential remnants: ``$($credentialRemnants.Count)``")
$lines.Add('')
$lines.Add('| Check | Result |')
$lines.Add('|---|---|')
foreach ($entry in $checks.GetEnumerator()) {
  $lines.Add("| ``$($entry.Key)`` | ``$(if ($entry.Value) {'PASS'} else {'FAIL'})`` |")
}
$lines.Add('')
[IO.File]::WriteAllText($mdPath,($lines -join [Environment]::NewLine),[Text.UTF8Encoding]::new($false))
Write-Output $json
if ($failed.Count -ne 0) { exit 2 }
