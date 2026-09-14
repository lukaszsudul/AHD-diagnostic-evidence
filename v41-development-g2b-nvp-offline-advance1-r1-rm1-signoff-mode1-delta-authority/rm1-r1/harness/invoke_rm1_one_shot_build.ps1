[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$RepoRoot,
  [Parameter(Mandatory = $true)][string]$RunRoot,
  [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceCommit,
  [Parameter(Mandatory = $true)][ValidatePattern('^[0-9a-f]{40}$')][string]$SourceTree,
  [Parameter(Mandatory = $true)][string]$FocusedReceipt,
  [Parameter(Mandatory = $true)][string]$AffectedR3Receipt,
  [Parameter(Mandatory = $true)][string]$PublicationReadbackReceipt,
  [string]$Vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat',
  [string]$R3DonorBuildTcl = 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z\scripts\g2b_nvp_video_diag1_r3_build.tcl'
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

function Assert-AuthorizedChangedSet {
  param([string]$Repository, [string]$Commit)

  $parentLine = (& git --no-optional-locks -C $Repository rev-list `
      --parents -n 1 $Commit)
  $parentWords = @(([string]$parentLine).Trim() -split '\s+')
  if ($LASTEXITCODE -ne 0 -or $parentWords.Count -ne 2 -or
      $parentWords[0].ToLowerInvariant() -ne $Commit -or
      $parentWords[1].ToLowerInvariant() -ne $expectedParent) {
    throw 'RM1_ONESHOT_DIRECT_PARENT_MISMATCH'
  }
  $diffRows = @(& git --no-optional-locks -C $Repository diff-tree `
      --no-commit-id --name-status -r --find-renames --find-copies `
      --find-copies-harder `
      $expectedParent $Commit)
  if ($LASTEXITCODE -ne 0) { throw 'RM1_ONESHOT_DIFF_TREE_FAILED' }
  $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
  foreach ($row in $diffRows) {
    $columns = @($row -split "`t")
    if ($columns.Count -ne 2) { throw "RM1_ONESHOT_RENAME_COPY_OR_MALFORMED_DIFF:$row" }
    $changeStatus = $columns[0]
    $relative = $columns[1]
    if ($relative.Contains('\') -or [IO.Path]::IsPathRooted($relative) -or
        $relative -match '(^|/)\.\.(/|$)' -or -not $seen.Add($relative)) {
      throw "RM1_ONESHOT_NONCANONICAL_OR_DUPLICATE_CHANGED_PATH:$relative"
    }
    if (-not ($authorizedChanges.Keys -ccontains $relative) -or
        [string]$authorizedChanges[$relative] -ne $changeStatus) {
      throw "RM1_ONESHOT_UNAUTHORIZED_CHANGED_PATH:$changeStatus`:$relative"
    }
  }
  $missing = @($authorizedChanges.Keys | Where-Object { -not $seen.Contains($_) })
  if ($diffRows.Count -ne 11 -or $seen.Count -ne 11 -or $missing.Count -ne 0) {
    throw "RM1_ONESHOT_AUTHORIZED_CHANGED_SET_MISMATCH:MISSING=$($missing -join ','):COUNT=$($seen.Count)/11"
  }
}

function Assert-PreVivadoSealCurrent {
  param(
    [Collections.Specialized.OrderedDictionary]$Inputs,
    [Collections.Specialized.OrderedDictionary]$Hashes,
    [string]$SealPath,
    [string]$SealSHA256
  )
  if ($Inputs.Count -ne 14 -or $Hashes.Count -ne 14 -or
      -not (Test-Path -LiteralPath $SealPath -PathType Leaf) -or
      (Get-FileHash -LiteralPath $SealPath -Algorithm SHA256).Hash -ne $SealSHA256) {
    throw 'RM1_ONESHOT_PRE_VIVADO_SEAL_IDENTITY_MISMATCH'
  }
  foreach ($entry in $Inputs.GetEnumerator()) {
    if (-not $Hashes.Contains($entry.Key) -or
        -not (Test-Path -LiteralPath $entry.Value -PathType Leaf) -or
        (Get-FileHash -LiteralPath $entry.Value -Algorithm SHA256).Hash -ne
            [string]$Hashes[$entry.Key]) {
      throw "RM1_ONESHOT_PRE_VIVADO_INPUT_DRIFT:$($entry.Key)"
    }
  }
}

$repo = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$run = [IO.Path]::GetFullPath($RunRoot).TrimEnd('\', '/')
$focused = [IO.Path]::GetFullPath($FocusedReceipt)
$affected = [IO.Path]::GetFullPath($AffectedR3Receipt)
$publication = [IO.Path]::GetFullPath($PublicationReadbackReceipt)
$vivadoExe = [IO.Path]::GetFullPath($Vivado)
$donor = [IO.Path]::GetFullPath($R3DonorBuildTcl)
$harnessRoot = Split-Path -Parent $PSCommandPath
$buildTcl = Join-Path $harnessRoot 'g2b_nvp_diag2_rm1_build.tcl'
$finalizeTcl = Join-Path $harnessRoot 'g2b_nvp_diag2_rm1_finalize.tcl'
$binder = Join-Path $harnessRoot 'bind_rm1_receipts_to_source.ps1'
$affectedRunner = Join-Path $harnessRoot 'run_rm1_affected_regressions.ps1'
$staticChecker = Join-Path $harnessRoot 'check_rm1_build_harness.ps1'
$tclSyntaxChecker = Join-Path $harnessRoot 'check_rm1_harness_syntax.tcl'
$publicationSchema = Join-Path $harnessRoot 'RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json'
$readme = Join-Path $harnessRoot 'RM1_BUILD_HARNESS_README.md'
$bindingReceipt = Join-Path $run 'G2B_NVP_DIAG2_RM1_RECEIPT_BINDING.json'
$preVivadoSeal = Join-Path $run 'G2B_NVP_DIAG2_RM1_PRE_VIVADO_INPUT_SEAL.txt'
$buildRoot = Join-Path $run 'build'
$evidenceRoot = Join-Path $run 'reports\vivado_full'
$artifactRoot = Join-Path $run 'artifacts'
$tempRoot = Join-Path $run 'temp'

foreach ($path in @($repo, $focused, $affected, $publication, $vivadoExe,
                     $donor, $buildTcl, $finalizeTcl, $binder, $affectedRunner,
                     $staticChecker, $tclSyntaxChecker, $publicationSchema,
                     $readme, $PSCommandPath)) {
  if (-not (Test-Path -LiteralPath $path)) {
    throw "RM1_ONESHOT_REQUIRED_INPUT_MISSING:$path"
  }
}
if (Test-Path -LiteralPath $run) {
  throw "RM1_ONESHOT_RUN_ROOT_NOT_FRESH:$run"
}
if ($run.StartsWith($repo + '\', [StringComparison]::OrdinalIgnoreCase)) {
  throw 'RM1_ONESHOT_RUN_ROOT_INSIDE_REPOSITORY'
}

$branch = (& git --no-optional-locks -C $repo symbolic-ref --short HEAD).Trim()
$head = (& git --no-optional-locks -C $repo rev-parse HEAD).Trim()
$tree = (& git --no-optional-locks -C $repo rev-parse 'HEAD^{tree}').Trim()
$status = @(& git --no-optional-locks -C $repo status --porcelain=v1 --untracked-files=all)
if ($branch -ne 'diag/v41-g2b-nvp-video-diag2-rm1' -or
    $head -ne $SourceCommit -or $tree -ne $SourceTree -or $status.Count -ne 0) {
  throw 'RM1_ONESHOT_SOURCE_AUTHORITY_MISMATCH'
}
Assert-AuthorizedChangedSet -Repository $repo -Commit $SourceCommit

$remoteRef = @(& git --no-optional-locks -C $repo ls-remote --exit-code `
    --heads origin 'refs/heads/diag/v41-g2b-nvp-video-diag2-rm1')
if ($LASTEXITCODE -ne 0 -or $remoteRef.Count -ne 1 -or
    (($remoteRef[0] -split '\s+')[0]).ToLowerInvariant() -ne $SourceCommit) {
  throw 'RM1_ONESHOT_REMOTE_BRANCH_NOT_EXACTLY_PUBLISHED'
}

$donorHash = (Get-FileHash -LiteralPath $donor -Algorithm SHA256).Hash
if ($donorHash -ne '74CA15C2FCEADBC59876249E8EEB08D71D7FD787A0F7B422DC69BE737FB57D59') {
  throw 'RM1_ONESHOT_R3_DONOR_HASH_MISMATCH'
}

[void][IO.Directory]::CreateDirectory($run)
[void][IO.Directory]::CreateDirectory($tempRoot)

# This is the final pre-Vivado authority gate. It binds every focused
# HashAfter and affected-regression InputHashes entry to the current clean
# commit, validates the commit-pinned publication/blob-readback receipt, and
# independently repeats the exact origin branch readback.
& $binder -RepoRoot $repo -SourceCommit $SourceCommit -SourceTree $SourceTree `
    -FocusedReceipt $focused -AffectedR3Receipt $affected `
    -PublicationReadbackReceipt $publication -OutputReceipt $bindingReceipt
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $bindingReceipt)) {
  throw 'RM1_ONESHOT_RECEIPT_BINDING_FAILED'
}
$preVivadoInputs = [ordered]@{
  FOCUSED_RECEIPT = $focused
  AFFECTED_R3_RECEIPT = $affected
  RECEIPT_BINDING = $bindingReceipt
  PUBLICATION_READBACK_RECEIPT = $publication
  R3_DONOR_BUILD_TCL = $donor
  BUILD_HARNESS = $buildTcl
  FINALIZER = $finalizeTcl
  LAUNCHER = [IO.Path]::GetFullPath($PSCommandPath)
  BINDER = $binder
  AFFECTED_RUNNER = $affectedRunner
  STATIC_CHECKER = $staticChecker
  TCL_SYNTAX_CHECKER = $tclSyntaxChecker
  PUBLICATION_SCHEMA = $publicationSchema
  README = $readme
}
$preVivadoHashes = [ordered]@{}
$preVivadoRows = [Collections.Generic.List[string]]::new()
$sealedPaths = [Collections.Generic.HashSet[string]]::new(
    [StringComparer]::OrdinalIgnoreCase)
foreach ($entry in $preVivadoInputs.GetEnumerator()) {
  $sealedPath = [IO.Path]::GetFullPath([string]$entry.Value)
  if ($sealedPath.Contains('|') -or -not $sealedPaths.Add($sealedPath)) {
    throw "RM1_ONESHOT_PRE_VIVADO_NONCANONICAL_OR_DUPLICATE_PATH:$sealedPath"
  }
  $sealedSHA = (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash
  $preVivadoHashes[$entry.Key] = $sealedSHA
  $preVivadoRows.Add("$($entry.Key)|$sealedPath|$sealedSHA")
}
if (($preVivadoInputs.Count -ne 14) -or
    ($preVivadoRows.Count -ne 14) -or
    (Test-Path -LiteralPath $preVivadoSeal)) {
  throw 'RM1_ONESHOT_PRE_VIVADO_SEAL_SET_OR_FRESHNESS_MISMATCH'
}
$preVivadoRows | Set-Content -LiteralPath $preVivadoSeal -Encoding utf8NoBOM
$preVivadoSealSHA = (Get-FileHash -LiteralPath $preVivadoSeal -Algorithm SHA256).Hash
Assert-PreVivadoSealCurrent -Inputs $preVivadoInputs -Hashes $preVivadoHashes `
    -SealPath $preVivadoSeal -SealSHA256 $preVivadoSealSHA
$oldTemp = $env:TEMP
$oldTmp = $env:TMP
$oldLocal = $env:XILINX_LOCAL_USER_DATA
$oldTclStore = $env:XILINX_TCLAPP_REPO
$result = [ordered]@{
  Task = 'AHD_V41_G2B_NVP_DIAG2_RM1_ONE_SHOT_BUILD_AND_FINALIZE'
  SourceCommit = $SourceCommit
  SourceTree = $SourceTree
  ExpectedParent = $expectedParent
  DirectParentBinding = 'PASS'
  AuthorizedChangedSet = '11/11 PASS'
  Profile = 'ENABLE_NVP_VIDEO_DIAG2_RM1=1;ENABLE_NVP_VIDEO_DIAGNOSTIC=0;ENABLE_RTRACK_DIAGNOSTICS=0'
  FreshNonincrementalBuild = 'REQUESTED'
  HardwareAccessed = 'NO'
  Build = 'NOT_RUN'
  Finalizer = 'NOT_RUN'
  PreVivadoSealSHA256 = $preVivadoSealSHA
}

try {
  $env:TEMP = $tempRoot
  $env:TMP = $tempRoot
  $env:XILINX_LOCAL_USER_DATA = 'NO'
  $env:XILINX_TCLAPP_REPO = 'C:\AMDDesignTools\2025.2\Vivado\data\XilinxTclStore'

  Assert-PreVivadoSealCurrent -Inputs $preVivadoInputs -Hashes $preVivadoHashes `
      -SealPath $preVivadoSeal -SealSHA256 $preVivadoSealSHA
  & $vivadoExe '-mode' 'batch' '-nojournal' '-nolog' '-notrace' `
      '-source' $buildTcl '-tclargs' $repo $buildRoot $evidenceRoot `
      $SourceCommit $SourceTree $focused $affected $bindingReceipt `
      $publication $donor $preVivadoSeal $preVivadoSealSHA `
      $preVivadoHashes.FOCUSED_RECEIPT $preVivadoHashes.AFFECTED_R3_RECEIPT `
      $preVivadoHashes.RECEIPT_BINDING `
      $preVivadoHashes.PUBLICATION_READBACK_RECEIPT `
      *> (Join-Path $run 'rm1-build.console.log')
  if ($LASTEXITCODE -ne 0) {
    $result.Build = "FAIL_EXIT_$LASTEXITCODE"
    throw 'RM1_ONESHOT_ROUTED_BUILD_FAILED'
  }
  $handoff = Join-Path $evidenceRoot 'G2B_NVP_DIAG2_RM1_ROUTED_BUILD_HANDOFF.txt'
  if (-not (Test-Path -LiteralPath $handoff) -or
      -not ((Get-Content -LiteralPath $handoff -Raw).Contains('RESULT=PASS'))) {
    $result.Build = 'FAIL_HANDOFF'
    throw 'RM1_ONESHOT_ROUTED_HANDOFF_INVALID'
  }
  $result.Build = 'PASS_ROUTED_HANDOFF'
  $handoffSHA = (Get-FileHash -LiteralPath $handoff -Algorithm SHA256).Hash

  Assert-PreVivadoSealCurrent -Inputs $preVivadoInputs -Hashes $preVivadoHashes `
      -SealPath $preVivadoSeal -SealSHA256 $preVivadoSealSHA
  & $vivadoExe '-mode' 'batch' '-nojournal' '-nolog' '-notrace' `
      '-source' $finalizeTcl '-tclargs' $repo $evidenceRoot $artifactRoot `
      $SourceCommit $SourceTree $buildTcl $handoffSHA `
      *> (Join-Path $run 'rm1-finalize.console.log')
  if ($LASTEXITCODE -ne 0) {
    $result.Finalizer = "FAIL_EXIT_$LASTEXITCODE"
    throw 'RM1_ONESHOT_FINALIZER_FAILED'
  }
  $signoff = Join-Path $artifactRoot 'G2B_NVP_DIAG2_RM1_SIGNOFF_RESULT.txt'
  if (-not (Test-Path -LiteralPath $signoff) -or
      -not ((Get-Content -LiteralPath $signoff -Raw).Contains('RESULT=PASS'))) {
    $result.Finalizer = 'FAIL_SIGNOFF_RECEIPT'
    throw 'RM1_ONESHOT_SIGNOFF_RECEIPT_INVALID'
  }
  $result.Finalizer = 'PASS_ONE_DCP_ONE_BITSTREAM'
  $result.Result = 'PASS'
} catch {
  $result.Result = 'FAIL'
  $result.Error = $_.Exception.Message
  throw
} finally {
  $env:TEMP = $oldTemp
  $env:TMP = $oldTmp
  $env:XILINX_LOCAL_USER_DATA = $oldLocal
  $env:XILINX_TCLAPP_REPO = $oldTclStore
  $result | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath `
      (Join-Path $run 'G2B_NVP_DIAG2_RM1_ONE_SHOT_RESULT.json') -Encoding utf8NoBOM
}

Write-Output 'RM1_ONE_SHOT_BUILD_AND_FINALIZE=PASS'
Write-Output 'FRESH_NONINCREMENTAL_BUILD=ONE'
Write-Output 'SIGNED_OFF_DCP=ONE'
Write-Output 'BITSTREAM=ONE'
Write-Output 'HARDWARE_ACCESSED=NO'
