[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][switch]$FinalizeAfterP4Pass
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TaskRoot = 'C:\FPGA\V41_NVP_R1H_R2_BUILD_HARNESS_CONTINUATION'
$Repo = 'C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$Out = Join-Path $TaskRoot '06_BUILD\PREBUILD'
$OldTaskRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$OldManifest = Join-Path $OldTaskRoot '07_BUILD\R1H_PREBUILD_MANIFEST.txt'
$CorrectedHarness = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\r1h_r2_build.tcl'
$P3Result = Join-Path $TaskRoot '04_PROJECT_SETUP_DRY_RUN\R1H_R2_PROJECT_SETUP_DRY_RUN_RESULT.txt'
$P3IndependentAudit = Join-Path $TaskRoot '04_PROJECT_SETUP_DRY_RUN\R1H_R2_PROJECT_SETUP_DRY_RUN_INDEPENDENT_AUDIT.md'
$HarnessIndependentAudit = Join-Path $TaskRoot '03_CORRECTED_BUILD_HARNESS\R1H_R2_INDEPENDENT_HARNESS_AND_DRY_RUN_AUDIT.md'
$P4StaticIndependentAudit = Join-Path $TaskRoot '05_SEMANTIC_ELABORATION\INDEPENDENT_SEMANTIC_PREFLIGHT_STATIC_AUDIT.md'
$P4Result = Join-Path $TaskRoot '05_SEMANTIC_ELABORATION\run_01\R1H_R2_SEMANTIC_ELABORATION_RESULT.txt'
$P4IndependentAudit = Join-Path $TaskRoot '05_SEMANTIC_ELABORATION\R1H_R2_SEMANTIC_ELABORATION_INDEPENDENT_AUDIT.txt'
$P4RunRoot = Join-Path $TaskRoot '05_SEMANTIC_ELABORATION\run_01'
$GeneratorPath = $MyInvocation.MyCommand.Path

$OutputManifest = Join-Path $Out 'R1H_R2_PREBUILD_MANIFEST.txt'
$OutputHash = Join-Path $Out 'R1H_R2_PREBUILD_MANIFEST_SHA256.txt'
$OutputVerification = Join-Path $Out 'R1H_R2_PREBUILD_MANIFEST_VERIFICATION.txt'

$ExpectedCommit = 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
$ExpectedTree = '161e561f007912d73dba93c5ecd78e3cc3a6955b'
$ExpectedBranch = 'diag/v41-nvp-r1h-bram-backed-large-sample'
$ExpectedOldManifestSha256 = '192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79'
$ExpectedOldBuildTclSha256 = '2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18'
$ExpectedCorrectedHarnessSha256 = '5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F'
$ExpectedP3ResultSha256 = 'F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6'
$ExpectedP3IndependentAuditSha256 = '3232F2FA10C6036C3D8D7F3F8E9A3CBC45BAEA4821B8F7A2739F14806F3C60AD'
$ExpectedHarnessIndependentAuditSha256 = 'EA965F065BD35EEE281A8FD47446C4BB8BA6DC87A5CB84DABA06C9487E7A14C3'
$ExpectedP4RunnerSha256 = '265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546'
$ExpectedP4StaticIndependentAuditSha256 = '0A35C816A7B82C50B267D60F9AEA54F1517493E00783380C9867D0BFABC726C1'
$ExpectedDuplicateNormalizationSha256 = '3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F'

function Get-Sha256 {
  param([Parameter(Mandatory=$true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "required file missing: $Path"
  }
  return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Write-Utf8NoBom {
  param([Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text)
  [System.IO.File]::WriteAllText($Path, $Text, [System.Text.UTF8Encoding]::new($false))
}

function Invoke-ReadOnlyGitLines {
  param([Parameter(Mandatory=$true)][string[]]$Arguments)
  $allowed = @('rev-parse','symbolic-ref','status','ls-files')
  if ($Arguments.Count -eq 0 -or $allowed -cnotcontains $Arguments[0]) {
    throw "Git subcommand is not in the P5 read-only allowlist: $($Arguments -join ' ')"
  }
  $output = @(& git -C $Repo @Arguments 2>&1 | ForEach-Object { $_.ToString() })
  if ($LASTEXITCODE -ne 0) {
    throw "read-only Git failed: git -C '$Repo' $($Arguments -join ' ')`n$($output -join "`n")"
  }
  return $output
}

function Read-UniqueKeyValueReceipt {
  param([Parameter(Mandatory=$true)][string]$Path)
  $values = [ordered]@{}
  $lineNumber = 0
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    $lineNumber++
    if ([string]::IsNullOrWhiteSpace($line)) { throw "blank receipt line ${lineNumber}: $Path" }
    $match = [regex]::Match($line, '\A([A-Z][A-Z0-9_]*)=(.*)\z')
    if (-not $match.Success) { throw "malformed receipt line ${lineNumber}: $Path" }
    $key = $match.Groups[1].Value
    if ($values.Contains($key)) { throw "duplicate receipt key '$key': $Path" }
    $values.Add($key, $match.Groups[2].Value)
  }
  return ,$values
}

function Assert-ExactReceiptValues {
  param([Parameter(Mandatory=$true)][System.Collections.IDictionary]$Receipt,
        [Parameter(Mandatory=$true)][System.Collections.IDictionary]$Required,
        [Parameter(Mandatory=$true)][string]$Label)
  foreach ($key in $Required.Keys) {
    if (-not $Receipt.Contains($key)) { throw "$Label lacks exact key: $key" }
    $actual = [string]$Receipt[$key]
    $expected = [string]$Required[$key]
    if ($actual -cne $expected) {
      throw "$Label value mismatch for ${key}: expected '$expected', got '$actual'"
    }
  }
}

function Parse-ExactR1hManifest {
  param([Parameter(Mandatory=$true)][string]$Path)
  $metadata = [ordered]@{}
  $sources = [ordered]@{}
  $accepted = [ordered]@{}
  $sourceRows = [System.Collections.Generic.List[string]]::new()
  foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
    $fields = $line -split '\|'
    switch ($fields[0]) {
      'META' {
        if ($fields.Count -ne 3 -or $metadata.Contains($fields[1])) { throw "invalid/duplicate META row: $line" }
        $metadata.Add($fields[1], $fields[2])
      }
      'SOURCE_SHA256' {
        if ($fields.Count -ne 3 -or $sources.Contains($fields[1]) -or $fields[2] -notmatch '\A[0-9A-F]{64}\z') {
          throw "invalid/duplicate SOURCE_SHA256 row: $line"
        }
        $sources.Add($fields[1], $fields[2])
        $sourceRows.Add($line)
      }
      'ACCEPTED_LOG_SHA256' {
        if ($fields.Count -ne 4 -or $accepted.Contains($fields[1]) -or $fields[3] -notmatch '\A[0-9A-F]{64}\z') {
          throw "invalid/duplicate ACCEPTED_LOG_SHA256 row: $line"
        }
        $accepted.Add($fields[1], [pscustomobject]@{ Path=$fields[2]; Sha256=$fields[3] })
      }
      default { throw "unknown exact R1h manifest row: $line" }
    }
  }
  return [pscustomobject]@{
    Metadata=$metadata; Sources=$sources; Accepted=$accepted; SourceRows=$sourceRows
  }
}

if (-not $FinalizeAfterP4Pass.IsPresent) {
  throw 'Fail closed: -FinalizeAfterP4Pass is required after P4 and its independent audit pass.'
}
foreach ($path in @($OutputManifest,$OutputHash,$OutputVerification)) {
  if (Test-Path -LiteralPath $path) { throw "refusing to overwrite finalized P5 output: $path" }
}

if ((Get-Sha256 $OldManifest) -cne $ExpectedOldManifestSha256) { throw 'exact R1h prebuild manifest SHA-256 mismatch' }
if ((Get-Sha256 $CorrectedHarness) -cne $ExpectedCorrectedHarnessSha256) { throw 'corrected R1h-R2 harness SHA-256 mismatch' }
if ((Get-Sha256 $P3Result) -cne $ExpectedP3ResultSha256) { throw 'P3 raw PASS result SHA-256 mismatch' }
if ((Get-Sha256 $P3IndependentAudit) -cne $ExpectedP3IndependentAuditSha256) { throw 'P3 independent audit SHA-256 mismatch' }
if ((Get-Sha256 $HarnessIndependentAudit) -cne $ExpectedHarnessIndependentAuditSha256) { throw 'harness independent audit SHA-256 mismatch' }
if ((Get-Sha256 $P4StaticIndependentAudit) -cne $ExpectedP4StaticIndependentAuditSha256) { throw 'P4 pre-execution independent audit SHA-256 mismatch' }

$p4 = Read-UniqueKeyValueReceipt $P4Result
Assert-ExactReceiptValues $p4 ([ordered]@{
  R1H_SOURCE_COMMIT=$ExpectedCommit
  R1H_SOURCE_TREE=$ExpectedTree
  TOP='ahd_capture_top_xdma'
  PART_CONTEXT='xc7a35tcsg325-2'
  UNRESOLVED_MODULES='0'
  UNRESOLVED_BLACKBOXES='0'
  FAILED_RECORD_WRAPPER_BINDING='PASS'
  PROBE_INDEX_WRAPPER_BINDING='PASS'
  MMIO_READ_SERVICE_BINDING='PASS'
  R1H_TEST_ELABORATION='PASS'
  SEMANTIC_ELABORATION_PREFLIGHTS='1'
  SEMANTIC_ELABORATION='PASS'
  PROCESS_EXIT_CODE='0'
  DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256=$ExpectedDuplicateNormalizationSha256
}) 'P4 result'

foreach ($binding in @(
  @('XVHDL_LOG_SHA256',(Join-Path $P4RunRoot 'xvhdl.log')),
  @('XVLOG_LOG_SHA256',(Join-Path $P4RunRoot 'xvlog.log')),
  @('XELAB_LOG_SHA256',(Join-Path $P4RunRoot 'xelab.log')),
  @('INPUT_MANIFEST_SHA256',(Join-Path $P4RunRoot 'SEMANTIC_INPUT_SHA256.csv')),
  @('DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT_SHA256',(Join-Path $P4RunRoot 'DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT.txt'))
)) {
  if (-not $p4.Contains($binding[0])) { throw "P4 result lacks file hash: $($binding[0])" }
  if ((Get-Sha256 $binding[1]) -cne [string]$p4[$binding[0]]) { throw "P4 bound-file hash mismatch: $($binding[0])" }
}

$p4ResultSha = Get-Sha256 $P4Result
$p4Independent = Read-UniqueKeyValueReceipt $P4IndependentAudit
Assert-ExactReceiptValues $p4Independent ([ordered]@{
  INDEPENDENT_SEMANTIC_ELABORATION_AUDIT='PASS'
  R1H_SOURCE_COMMIT=$ExpectedCommit
  R1H_SOURCE_TREE=$ExpectedTree
  SEMANTIC_ELABORATION_PREFLIGHTS='1'
  SEMANTIC_ELABORATION='PASS'
  R1H_TEST_ELABORATION='PASS'
  UNRESOLVED_MODULES='0'
  UNRESOLVED_BLACKBOXES='0'
  FAILED_RECORD_WRAPPER_BINDING='PASS'
  PROBE_INDEX_WRAPPER_BINDING='PASS'
  PROCESS_EXIT_CODE='0'
  CANONICAL_RUNNER_SHA256=$ExpectedP4RunnerSha256
  SEMANTIC_RESULT_SHA256=$p4ResultSha
  BLOCKERS='NONE'
}) 'P4 independent audit'

$old = Parse-ExactR1hManifest $OldManifest
if ($old.Metadata.Count -ne 43 -or $old.Sources.Count -ne 224 -or $old.Accepted.Count -ne 32) {
  throw "exact R1h manifest shape mismatch: META=$($old.Metadata.Count) SOURCE=$($old.Sources.Count) ACCEPTED=$($old.Accepted.Count)"
}
if ([string]$old.Metadata['SOURCE_GIT_COMMIT'] -cne $ExpectedCommit -or
    [string]$old.Metadata['SOURCE_GIT_TREE'] -cne $ExpectedTree -or
    [string]$old.Metadata['R1H_BUILD_TCL_SHA256'] -cne $ExpectedOldBuildTclSha256) {
  throw 'exact R1h manifest identity/build-Tcl metadata mismatch'
}

$head = ((Invoke-ReadOnlyGitLines @('rev-parse','HEAD')) -join '').Trim().ToLowerInvariant()
$tree = ((Invoke-ReadOnlyGitLines @('rev-parse','HEAD^{tree}')) -join '').Trim().ToLowerInvariant()
$branch = ((Invoke-ReadOnlyGitLines @('symbolic-ref','--short','HEAD')) -join '').Trim()
$status = @(Invoke-ReadOnlyGitLines @('status','--porcelain=v1','--untracked-files=all'))
if ($head -cne $ExpectedCommit -or $tree -cne $ExpectedTree -or $branch -cne $ExpectedBranch) {
  throw "exact R1h Git identity mismatch: head=$head tree=$tree branch=$branch"
}
if (@($status | Where-Object { $_ -ne '' }).Count -ne 0) { throw 'exact R1h worktree is not clean' }

$tracked = @(Invoke-ReadOnlyGitLines @('ls-files') | Where-Object { $_ -ne '' })
if ($tracked.Count -ne 224 -or @($tracked | Sort-Object -Unique).Count -ne 224) {
  throw "tracked source count is not exact 224: $($tracked.Count)"
}
$trackedSorted = @($tracked | Sort-Object)
$manifestSorted = @($old.Sources.Keys | Sort-Object)
if (($trackedSorted -join "`n") -cne ($manifestSorted -join "`n")) {
  throw 'tracked source path set differs from exact R1h 224-row manifest'
}
foreach ($relative in $trackedSorted) {
  $actual = Get-Sha256 (Join-Path $Repo ($relative.Replace('/','\')))
  if ($actual -cne [string]$old.Sources[$relative]) { throw "R1h source hash changed: $relative" }
}
foreach ($label in $old.Accepted.Keys) {
  $record = $old.Accepted[$label]
  if ((Get-Sha256 $record.Path) -cne $record.Sha256) { throw "inherited accepted-log hash changed: $label" }
}

$metadata = [ordered]@{}
foreach ($key in $old.Metadata.Keys) { $metadata.Add($key,[string]$old.Metadata[$key]) }
$metadata['R1H_BUILD_TCL_SHA256'] = $ExpectedCorrectedHarnessSha256
foreach ($entry in ([ordered]@{
  R1H_R2_BUILD_HARNESS_CORRECTION_MODE='TASK_LOCAL_ZERO_REPOSITORY_MUTATION'
  R1H_R2_PROJECT_SETUP_DRY_RUN='PASS'
  R1H_R2_SEMANTIC_ELABORATION='PASS'
  R1H_R2_INDEPENDENT_AUDITS='PASS_P3_AND_P4'
  R1H_ORIGINAL_PREBUILD_MANIFEST_SHA256=$ExpectedOldManifestSha256
  R1H_SOURCE_MANIFEST_ROWS='224'
  R1H_SOURCE_MANIFEST_EQUAL_TO_C4F4BFCF='YES'
  R1H_RTL_BLOBS_UNCHANGED='YES'
  R1H_XDC_UNCHANGED='YES'
  R1H_XDMA_XCI_UNCHANGED='YES'
  R1H_REGISTER_MAP_UNCHANGED='YES'
  R1H_HOST_DECODERS_UNCHANGED='YES'
  R1H_STATISTICAL_PLAN_UNCHANGED='YES'
  FPGA_RTL_SOURCE_CHANGES='0'
  TRACKED_BUILD_HARNESS_COMMITS='0'
}).GetEnumerator()) { $metadata.Add($entry.Key,$entry.Value) }

$accepted = [ordered]@{}
foreach ($label in $old.Accepted.Keys) { $accepted.Add($label,$old.Accepted[$label].Path) }
$accepted.Add('R1H_R2_CORRECTED_BUILD_HARNESS',$CorrectedHarness)
$accepted.Add('R1H_R2_HARNESS_AND_DRY_RUN_INDEPENDENT_AUDIT',$HarnessIndependentAudit)
$accepted.Add('R1H_R2_PROJECT_SETUP_DRY_RUN',$P3Result)
$accepted.Add('R1H_R2_PROJECT_SETUP_DRY_RUN_INDEPENDENT_AUDIT',$P3IndependentAudit)
$accepted.Add('R1H_R2_SEMANTIC_PREFLIGHT_STATIC_INDEPENDENT_AUDIT',$P4StaticIndependentAudit)
$accepted.Add('R1H_R2_SEMANTIC_ELABORATION',$P4Result)
$accepted.Add('R1H_R2_SEMANTIC_ELABORATION_INDEPENDENT_AUDIT',$P4IndependentAudit)
$accepted.Add('R1H_R2_PREBUILD_GENERATOR',$GeneratorPath)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Exact external R1h-R2 prebuild manifest; generated once after P4 and independent audit PASS.')
foreach ($key in $metadata.Keys) { $lines.Add("META|$key|$($metadata[$key])") }
$lines.Add('')
foreach ($row in $old.SourceRows) { $lines.Add($row) }
$lines.Add('')
foreach ($label in $accepted.Keys) {
  $path = [System.IO.Path]::GetFullPath([string]$accepted[$label])
  if ($path.Contains('|')) { throw "manifest delimiter in accepted-log path: $path" }
  $lines.Add("ACCEPTED_LOG_SHA256|$label|$path|$(Get-Sha256 $path)")
}

$manifestText = ($lines -join "`n") + "`n"
$tmpSuffix = [guid]::NewGuid().ToString('N')
$tmpManifest = "$OutputManifest.$tmpSuffix.tmp"
$tmpHash = "$OutputHash.$tmpSuffix.tmp"
$tmpVerification = "$OutputVerification.$tmpSuffix.tmp"
try {
  Write-Utf8NoBom $tmpManifest $manifestText
  $manifestSha = Get-Sha256 $tmpManifest
  Write-Utf8NoBom $tmpHash "$manifestSha  R1H_R2_PREBUILD_MANIFEST.txt`n"
  $verification = @(
    'R1H_R2_PREBUILD_MANIFEST_VERIFICATION=PASS',
    "R1H_R2_PREBUILD_MANIFEST_SHA256=$manifestSha",
    "R1H_SOURCE_COMMIT=$ExpectedCommit",
    "R1H_SOURCE_TREE=$ExpectedTree",
    'R1H_SOURCE_WORKTREE_CLEAN=YES',
    'SOURCE_RECORDS=224',
    'SOURCE_ROWS_BYTE_IDENTICAL_TO_R1H=YES',
    "ACCEPTED_LOG_RECORDS=$($accepted.Count)",
    "CORRECTED_BUILD_HARNESS_SHA256=$ExpectedCorrectedHarnessSha256",
    "P4_RESULT_SHA256=$p4ResultSha",
    "P4_INDEPENDENT_AUDIT_SHA256=$(Get-Sha256 $P4IndependentAudit)",
    'R1H_RTL_BLOBS_UNCHANGED=YES',
    'R1H_XDC_UNCHANGED=YES',
    'R1H_XDMA_XCI_UNCHANGED=YES',
    'R1H_HOST_DECODERS_UNCHANGED=YES',
    'R1H_STATISTICAL_PLAN_UNCHANGED=YES',
    'FULL_CLEAN_BUILDS_CONSUMED=0',
    'NEXT_ACTION=INDEPENDENT_R1H_R2_PREBUILD_AUDIT_THEN_ONE_CLEAN_BUILD'
  )
  Write-Utf8NoBom $tmpVerification (($verification -join "`n") + "`n")
  [System.IO.File]::Move($tmpManifest,$OutputManifest)
  [System.IO.File]::Move($tmpHash,$OutputHash)
  [System.IO.File]::Move($tmpVerification,$OutputVerification)
} finally {
  foreach ($tmp in @($tmpManifest,$tmpHash,$tmpVerification)) {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
  }
}

Write-Output 'R1H_R2_PREBUILD_MANIFEST_VERIFICATION=PASS'
Write-Output "R1H_R2_PREBUILD_MANIFEST_SHA256=$(Get-Sha256 $OutputManifest)"
