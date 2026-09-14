[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
  [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceTree,
  [Parameter(Mandatory = $true)][string]$FocusedReceipt,
  [Parameter(Mandatory = $true)][string]$AffectedR3Receipt,
  [Parameter(Mandatory = $true)][string]$PublicationReadbackReceipt,
  [Parameter(Mandatory = $true)][string]$OutputReceipt
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedParent = 'fc37d815b5d64ef90dfbd99c57ae4cc09567b56f'
$authorizedChanges = [ordered]@{
  'rtl/g2b/v41_g2b_onech_c2h.sv' = 'M'
  'rtl/top/ahd_capture_top_xdma.sv' = 'M'
  'rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv' = 'A'
  'rtl/diagnostic/g2b_nvp_rm1_route_controller.sv' = 'A'
  'rtl/g2b/g2b_nvp_video_diag2_rm1.sv' = 'A'
  'xdc/common/g2b_nvp_diag2_rm1_cdc.xdc' = 'A'
  'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv' = 'A'
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv' = 'A'
  'tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1' = 'A'
}

function Get-AuthorizedChangedSet {
  param([string]$Repository, [string]$Commit)

  $parentWords = @((& git --no-optional-locks -C $Repository rev-list `
      --parents -n 1 $Commit).Trim() -split '\s+')
  if ($LASTEXITCODE -ne 0 -or $parentWords.Count -ne 2 -or
      $parentWords[0].ToLowerInvariant() -ne $Commit -or
      $parentWords[1].ToLowerInvariant() -ne $expectedParent) {
    throw 'RM1_BIND_DIRECT_PARENT_MISMATCH'
  }

  $diffRows = @(& git --no-optional-locks -C $Repository diff-tree `
      --no-commit-id --name-status -r --find-renames --find-copies `
      --find-copies-harder `
      $expectedParent $Commit)
  if ($LASTEXITCODE -ne 0) { throw 'RM1_BIND_DIFF_TREE_FAILED' }
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $bound = [Collections.Generic.List[string]]::new()
  foreach ($row in $diffRows) {
    $columns = @($row -split "`t")
    if ($columns.Count -ne 2) { throw "RM1_BIND_RENAME_COPY_OR_MALFORMED_DIFF:$row" }
    $changeStatus = $columns[0]
    $relative = $columns[1]
    if ($relative.Contains('\') -or [IO.Path]::IsPathRooted($relative) -or
        $relative -match '(^|/)\.\.(/|$)' -or -not $seen.Add($relative)) {
      throw "RM1_BIND_NONCANONICAL_OR_DUPLICATE_CHANGED_PATH:$relative"
    }
    if (-not ($authorizedChanges.Keys -ccontains $relative) -or
        [string]$authorizedChanges[$relative] -ne $changeStatus) {
      throw "RM1_BIND_UNAUTHORIZED_CHANGED_PATH:$changeStatus`:$relative"
    }
    $bound.Add("$changeStatus|$relative")
  }
  $missing = @($authorizedChanges.Keys | Where-Object { -not $seen.Contains($_) })
  if ($diffRows.Count -ne 11 -or $seen.Count -ne 11 -or $missing.Count -ne 0) {
    throw "RM1_BIND_AUTHORIZED_CHANGED_SET_MISMATCH:MISSING=$($missing -join ','):COUNT=$($seen.Count)/11"
  }
  return @($bound | Sort-Object -CaseSensitive)
}

function Get-ValidatedReceiptSnapshot {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][ValidateSet('FOCUSED', 'AFFECTED_R3', 'PUBLICATION')]
    [string]$Label
  )

  $normalized = [IO.Path]::GetFullPath($Path)
  if (-not (Test-Path -LiteralPath $normalized -PathType Leaf)) {
    throw "RM1_BIND_SNAPSHOT_INPUT_MISSING:$Label`:$normalized"
  }
  try {
    [byte[]]$bytes = [IO.File]::ReadAllBytes($normalized)
  } catch {
    throw "RM1_BIND_SNAPSHOT_READ_FAILED:$Label`:$normalized`:$($_.Exception.Message)"
  }
  if ($bytes.Length -eq 0) { throw "RM1_BIND_SNAPSHOT_EMPTY:$Label" }
  $sha256 = [Convert]::ToHexString(
      [Security.Cryptography.SHA256]::HashData($bytes))
  try {
    $decoder = [Text.UTF8Encoding]::new($false, $true)
    $text = $decoder.GetString($bytes)
  } catch {
    throw "RM1_BIND_SNAPSHOT_UTF8_INVALID:$Label"
  }
  if ($text.Length -eq 0 -or $text[0] -eq [char]0xFEFF) {
    throw "RM1_BIND_SNAPSHOT_NONCANONICAL_UTF8:$Label"
  }
  try {
    $json = ConvertFrom-Json -InputObject $text -ErrorAction Stop
  } catch {
    throw "RM1_BIND_SNAPSHOT_JSON_INVALID:$Label`:$($_.Exception.Message)"
  }
  return [pscustomobject]@{
    Label = $Label
    Path = $normalized
    Bytes = $bytes
    SHA256 = $sha256
    Text = $text
    Json = $json
  }
}

function Assert-ReceiptSnapshotsCurrent {
  param([Parameter(Mandatory = $true)][object[]]$Snapshots)

  $requiredLabels = @('FOCUSED', 'AFFECTED_R3', 'PUBLICATION')
  $seenLabels = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  $seenPaths = [Collections.Generic.HashSet[string]]::new(
      [StringComparer]::OrdinalIgnoreCase)
  foreach ($snapshot in $Snapshots) {
    $label = [string]$snapshot.Label
    $path = [IO.Path]::GetFullPath([string]$snapshot.Path)
    $expectedSha = [string]$snapshot.SHA256
    if (-not ($requiredLabels -ccontains $label) -or -not $seenLabels.Add($label) -or
        -not $seenPaths.Add($path) -or $expectedSha -notmatch '^[0-9A-F]{64}$' -or
        -not (Test-Path -LiteralPath $path -PathType Leaf)) {
      throw "RM1_BIND_SNAPSHOT_SET_OR_IDENTITY_INVALID:$label`:$path"
    }
    try {
      $currentSha = [Convert]::ToHexString(
          [Security.Cryptography.SHA256]::HashData([IO.File]::ReadAllBytes($path)))
    } catch {
      throw "RM1_BIND_SNAPSHOT_FINAL_REHASH_FAILED:$label`:$path"
    }
    if ($currentSha -cne $expectedSha) {
      throw "RM1_BIND_RECEIPT_CHANGED_AFTER_VALIDATION:$label`:$path"
    }
  }
  if ($Snapshots.Count -ne 3 -or $seenLabels.Count -ne 3 -or $seenPaths.Count -ne 3) {
    throw 'RM1_BIND_SNAPSHOT_EXACT_THREE_REQUIRED'
  }
}

$repo = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$focusedPath = [IO.Path]::GetFullPath($FocusedReceipt)
$affectedPath = [IO.Path]::GetFullPath($AffectedR3Receipt)
$publicationPath = [IO.Path]::GetFullPath($PublicationReadbackReceipt)
$outputPath = [IO.Path]::GetFullPath($OutputReceipt)
foreach ($path in @($repo, $focusedPath, $affectedPath, $publicationPath)) {
  if (-not (Test-Path -LiteralPath $path)) { throw "RM1_BIND_INPUT_MISSING:$path" }
}
if (Test-Path -LiteralPath $outputPath) { throw 'RM1_BIND_OUTPUT_NOT_FRESH' }

$branch = (& git --no-optional-locks -C $repo symbolic-ref --short HEAD).Trim()
$head = (& git --no-optional-locks -C $repo rev-parse HEAD).Trim()
$tree = (& git --no-optional-locks -C $repo rev-parse 'HEAD^{tree}').Trim()
$status = @(& git --no-optional-locks -C $repo status --porcelain=v1 --untracked-files=all)
if ($branch -ne 'diag/v41-g2b-nvp-video-diag2-rm1' -or
    $head -ne $SourceCommit -or $tree -ne $SourceTree -or $status.Count -ne 0) {
  throw 'RM1_BIND_SOURCE_IDENTITY_MISMATCH'
}
$authorizedChangedSet = @(Get-AuthorizedChangedSet -Repository $repo -Commit $SourceCommit)

$focusedSnapshot = Get-ValidatedReceiptSnapshot -Path $focusedPath -Label FOCUSED
$affectedSnapshot = Get-ValidatedReceiptSnapshot -Path $affectedPath -Label AFFECTED_R3
$publicationSnapshot = Get-ValidatedReceiptSnapshot -Path $publicationPath -Label PUBLICATION
$receiptSnapshots = @($focusedSnapshot, $affectedSnapshot, $publicationSnapshot)
$focused = $focusedSnapshot.Json
$affected = $affectedSnapshot.Json
$publication = $publicationSnapshot.Json
if ($focused.Result -ne 'PASS' -or $focused.TestsPassed -ne 18 -or
    $focused.TestsRequired -ne 18 -or $focused.RouteControllerIntegration -ne 'PASS' -or
    $focused.ParserTapIntegration -ne 'PASS' -or $focused.SourceChangedDuringGate) {
  throw 'RM1_BIND_FOCUSED_RECEIPT_INVALID'
}
if ($affected.Result -ne 'PASS' -or
    $affected.R3ProtectedInputsVsParent -ne 'BYTE_IDENTICAL' -or
    $affected.CompleteR3Regression -ne '25/25 PASS' -or
    $affected.HardwareAccessed -ne 'NO') {
  throw 'RM1_BIND_AFFECTED_RECEIPT_INVALID'
}
foreach ($pair in @(
    @('Result', 'PASS'), @('SourceCommit', $SourceCommit),
    @('SourceTree', $SourceTree),
    @('Branch', 'diag/v41-g2b-nvp-video-diag2-rm1'),
    @('RemoteRefReadback', 'PASS'), @('CommitPinnedBlobReadback', 'PASS'),
    @('HardwareAccessed', 'NO'))) {
  $property = $publication.PSObject.Properties[$pair[0]]
  if ($null -eq $property -or [string]$property.Value -ne $pair[1]) {
    throw "RM1_BIND_PUBLICATION_RECEIPT_INVALID:$($pair[0])"
  }
}

$requiredFocused = @(
  'rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv',
  'rtl/diagnostic/g2b_nvp_rm1_route_controller.sv',
  'rtl/g2b/g2b_nvp_video_diag2_rm1.sv',
  'rtl/g2b/v41_g2b_onech_c2h.sv',
  'rtl/top/ahd_capture_top_xdma.sv',
  'xdc/common/g2b_nvp_diag2_rm1_cdc.xdc',
  'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1',
  'tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv',
  'tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1'
)
$focusedBound = [Collections.Generic.List[string]]::new()
$seenFocused = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase)
foreach ($property in $focused.HashAfter.PSObject.Properties) {
  $path = [IO.Path]::GetFullPath($property.Name)
  if (-not $path.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "RM1_BIND_FOCUSED_PATH_OUTSIDE_REPO:$path"
  }
  $relative = $path.Substring($repo.Length + 1).Replace('\', '/')
  if (-not $seenFocused.Add($relative)) { throw "RM1_BIND_DUPLICATE_FOCUSED_PATH:$relative" }
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "RM1_BIND_FOCUSED_FILE_MISSING:$relative"
  }
  $actualSha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if ($actualSha -ne [string]$property.Value) {
    throw "RM1_BIND_FOCUSED_HASH_MISMATCH:$relative"
  }
  & git --no-optional-locks -C $repo diff --quiet $SourceCommit -- $relative
  if ($LASTEXITCODE -ne 0) { throw "RM1_BIND_FOCUSED_NOT_IN_COMMIT:$relative" }
  $commitObject = (& git --no-optional-locks -C $repo rev-parse "$SourceCommit`:$relative").Trim()
  if ($LASTEXITCODE -ne 0 -or -not $commitObject) {
    throw "RM1_BIND_FOCUSED_COMMIT_OBJECT_MISSING:$relative"
  }
  $focusedBound.Add("$relative|SHA256=$actualSha|GIT_OBJECT=$commitObject")
}
$missingFocused = @($requiredFocused | Where-Object { -not $seenFocused.Contains($_) })
$extraFocused = @($seenFocused | Where-Object { $_ -notin $requiredFocused })
if ($missingFocused.Count -ne 0 -or $extraFocused.Count -ne 0) {
  throw "RM1_BIND_FOCUSED_SET_MISMATCH:MISSING=$($missingFocused -join ','):EXTRA=$($extraFocused -join ',')"
}

$requiredAffected = @(
  'tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1',
  'tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1',
  'rtl/g2b/g2b_nvp_video_diag.sv',
  'rtl/v41/axi_lite_host_bridge.sv',
  'rtl/g2b/v41_g2b_mmio_router.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv',
  'tests/nvp_video_diag/tb_nvp_i2c_fixed_master.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag_mmio_protocol.sv',
  'tests/nvp_video_diag/tb_g2b_nvp_video_diag_axi_integration.sv',
  'tests/nvp_video_diag/run_nvp_video_diag_r3_sim.ps1',
  'tests/nvp_video_diag/check_nvp_video_diag_r3_contract.ps1'
)
$affectedBound = [Collections.Generic.List[string]]::new()
$seenAffected = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase)
foreach ($property in $affected.InputHashes.PSObject.Properties) {
  $path = [IO.Path]::GetFullPath($property.Name)
  if (-not $path.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw "RM1_BIND_AFFECTED_PATH_OUTSIDE_REPO:$path"
  }
  $relative = $path.Substring($repo.Length + 1).Replace('\', '/')
  if (-not $seenAffected.Add($relative)) {
    throw "RM1_BIND_DUPLICATE_AFFECTED_PATH:$relative"
  }
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "RM1_BIND_AFFECTED_FILE_MISSING:$relative"
  }
  $actualSha = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  if ($actualSha -ne [string]$property.Value) {
    throw "RM1_BIND_AFFECTED_HASH_MISMATCH:$relative"
  }
  & git --no-optional-locks -C $repo diff --quiet $SourceCommit -- $relative
  if ($LASTEXITCODE -ne 0) { throw "RM1_BIND_AFFECTED_NOT_IN_COMMIT:$relative" }
  $commitObject = (& git --no-optional-locks -C $repo rev-parse "$SourceCommit`:$relative").Trim()
  if ($LASTEXITCODE -ne 0 -or -not $commitObject) {
    throw "RM1_BIND_AFFECTED_COMMIT_OBJECT_MISSING:$relative"
  }
  $affectedBound.Add("$relative|SHA256=$actualSha|GIT_OBJECT=$commitObject")
}
$missingAffected = @($requiredAffected | Where-Object {
    -not $seenAffected.Contains($_) })
$extraAffected = @($seenAffected | Where-Object { $_ -notin $requiredAffected })
if ($missingAffected.Count -ne 0 -or $extraAffected.Count -ne 0 -or
    $affectedBound.Count -ne 11) {
  throw "RM1_BIND_AFFECTED_SET_MISMATCH:MISSING=$($missingAffected -join ','):EXTRA=$($extraAffected -join ',')"
}

$remote = @(& git --no-optional-locks -C $repo ls-remote --exit-code --heads `
    origin 'refs/heads/diag/v41-g2b-nvp-video-diag2-rm1')
if ($LASTEXITCODE -ne 0 -or $remote.Count -ne 1) {
  throw 'RM1_BIND_REMOTE_REF_READBACK_FAILED'
}
$remoteCommit = (($remote[0] -split '\s+')[0]).ToLowerInvariant()
if ($remoteCommit -ne $SourceCommit) { throw 'RM1_BIND_REMOTE_REF_COMMIT_MISMATCH' }

$receipt = [ordered]@{
  Task = 'AHD_V41_G2B_NVP_DIAG2_RM1_PRE_VIVADO_RECEIPT_BINDING'
  Result = 'PASS'
  SourceCommit = $SourceCommit
  SourceTree = $SourceTree
  Branch = $branch
  ExpectedParent = $expectedParent
  DirectParentBinding = 'PASS'
  AuthorizedChangedSetBinding = 'PASS'
  AuthorizedChangedSetFiles = $authorizedChangedSet.Count
  AuthorizedChangedSet = $authorizedChangedSet
  FocusedReceipt = $focusedPath
  FocusedReceiptSHA256 = $focusedSnapshot.SHA256
  FocusedHashAfterBinding = 'PASS'
  FocusedHashAfterFiles = $focusedBound.Count
  FocusedBoundFiles = $focusedBound
  AffectedR3Receipt = $affectedPath
  AffectedR3ReceiptSHA256 = $affectedSnapshot.SHA256
  AffectedInputHashBinding = 'PASS'
  AffectedInputHashFiles = $affectedBound.Count
  AffectedBoundFiles = $affectedBound
  PublicationReadbackReceipt = $publicationPath
  PublicationReadbackReceiptSHA256 = $publicationSnapshot.SHA256
  RemoteRefCommit = $remoteCommit
  RemoteRefReadback = 'PASS'
  CommitPinnedBlobReadback = 'PASS'
  FullVivadoBuildStarted = 'NO'
  HardwareAccessed = 'NO'
}
$parent = Split-Path -Parent $outputPath
if (-not (Test-Path -LiteralPath $parent)) {
  [void][IO.Directory]::CreateDirectory($parent)
}
$receiptJson = $receipt | ConvertTo-Json -Depth 7
$encoding = [Text.UTF8Encoding]::new($false)
Assert-ReceiptSnapshotsCurrent -Snapshots $receiptSnapshots
$stream = [IO.File]::Open($outputPath, [IO.FileMode]::CreateNew,
    [IO.FileAccess]::Write, [IO.FileShare]::None)
try {
  $writer = [IO.StreamWriter]::new($stream, $encoding)
  try {
    $writer.WriteLine($receiptJson)
    $writer.Flush()
  } finally {
    $writer.Dispose()
  }
} finally {
  $stream.Dispose()
}
Write-Output 'RM1_PRE_VIVADO_RECEIPT_BINDING=PASS'
Write-Output 'DIRECT_PARENT_BINDING=PASS'
Write-Output "AUTHORIZED_CHANGED_SET_FILES=$($authorizedChangedSet.Count)/11"
Write-Output "FOCUSED_HASH_AFTER_FILES=$($focusedBound.Count)"
Write-Output "AFFECTED_INPUT_HASH_FILES=$($affectedBound.Count)"
Write-Output 'REMOTE_REF_READBACK=PASS'
Write-Output 'COMMIT_PINNED_BLOB_READBACK=PASS'
