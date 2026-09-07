[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidateSet('BEFORE','AFTER')][string]$Phase,
  [Parameter(Mandatory)][string]$OutputPath,
  [string]$BeforePath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE'
$sourceRoot = 'C:\FPGA\V41_G2B'
$fixedRoots = @(
  'C:\FPGA\G2B_HW0_PRODUCT_R3R1_20260906T172600Z',
  'C:\FPGA\G2B_HW0_PRODUCT_R3R2_20260906T182010Z',
  'C:\FPGA\G2B_HW0_PRODUCT_R3R3_20260906T200624Z',
  'C:\FPGA\G2B_HW0_PRODUCT_R3R4_20260906T215021Z',
  'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316',
  'C:\FPGA\G2B_HW0_DRV1_HDMI_EVIDENCE_20260906',
  'C:\FPGA\G2B_HW0_DRV1_HDMI_SOURCE_20260906',
  'C:\FPGA\G2B_HW0_DRV1_PREFLIGHT_20260906',
  'C:\FPGA\G2B_HW0_DRV1_REMOTE_READBACK_20260906_A',
  'C:\FPGA\G2B_HW0_DRV1_REMOTE_READBACK_20260906_B',
  'C:\FPGA\G2B_HW0_DRV1_UPSTREAM_20260906',
  'C:\FPGA\V41_G2B_DRIVER_ARTIFACTS',
  'C:\FPGA\V41_G2B_DRV',
  $sourceRoot,
  (Join-Path $evidenceRoot 'project-current-state')
)

$evidenceRoots = @(Get-ChildItem -LiteralPath $evidenceRoot -Directory -Force |
  Where-Object { $_.Name -match '^v41-hardware-g2b-hw0-product-live-path-bringup-r3($|r[1-4]|r3-cold|r4-finite)' } |
  Sort-Object FullName |
  Select-Object -ExpandProperty FullName)

$legacyR3Roots = @(Get-ChildItem -LiteralPath 'C:\FPGA' -Directory -Force |
  Where-Object { $_.Name -match '^G2B_HW0_PRODUCT_R3_[0-9]' } |
  Sort-Object FullName |
  Select-Object -ExpandProperty FullName)

$roots = @($fixedRoots + $evidenceRoots + $legacyR3Roots | Sort-Object -Unique)
$items = [Collections.Generic.List[object]]::new()
$rootRows = [Collections.Generic.List[object]]::new()

foreach ($root in $roots) {
  $exists = Test-Path -LiteralPath $root -PathType Container
  $rootRows.Add([ordered]@{ path=$root; exists=$exists })
  if (-not $exists) { continue }
  foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force |
      Where-Object { $_.FullName -notmatch '[\\/]\.git([\\/]|$)' } |
      Sort-Object FullName) {
    $relative = $file.FullName.Substring($root.Length).TrimStart('\','/')
    $items.Add([ordered]@{
      root = $root
      relative_path = $relative
      bytes = [int64]$file.Length
      last_write_utc_ticks = $file.LastWriteTimeUtc.Ticks
      sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    })
  }
}

function Get-GitState([string]$Path) {
  $head = (& git -C $Path rev-parse HEAD 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { throw "git HEAD failed for $Path" }
  $tree = (& git -C $Path rev-parse 'HEAD^{tree}' 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { throw "git tree failed for $Path" }
  $branch = (& git -C $Path branch --show-current 2>&1 | Out-String).Trim()
  if ($LASTEXITCODE -ne 0) { throw "git branch failed for $Path" }
  $status = @(& git -C $Path status --porcelain=v2 --untracked-files=all)
  if ($LASTEXITCODE -ne 0) { throw "git status failed for $Path" }
  return [ordered]@{ path=$Path; head=$head; tree=$tree; branch=$branch; status=@($status) }
}

$snapshot = [ordered]@{
  schema = 'R3R4R1_IMMUTABLE_BOUNDARY_V1'
  phase = $Phase
  collected_utc = [DateTime]::UtcNow.ToString('o')
  roots = @($rootRows)
  files = @($items)
  git = @(
    (Get-GitState $sourceRoot),
    (Get-GitState $evidenceRoot)
  )
  categories = [ordered]@{
    prior_r3_family_evidence_directories = @($evidenceRoots)
    legacy_r3_execution_roots = @($legacyR3Roots)
    recovery4 = 'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316'
    driver_artifact_roots = @($fixedRoots | Where-Object { $_ -match 'DRV|DRIVER' })
    product_source_worktree = $sourceRoot
    project_current_state = (Join-Path $evidenceRoot 'project-current-state')
  }
}

$json = $snapshot | ConvertTo-Json -Depth 8
[IO.File]::WriteAllText($OutputPath,$json + [Environment]::NewLine,[Text.UTF8Encoding]::new($false))

$comparison = $null
if ($Phase -eq 'AFTER') {
  if (-not $BeforePath) { throw 'BEFORE_PATH_REQUIRED' }
  $before = Get-Content -LiteralPath $BeforePath -Raw | ConvertFrom-Json -Depth 10
  $beforeMap = @{}
  foreach ($row in $before.files) { $beforeMap[$row.root + '|' + $row.relative_path] = $row }
  $afterMap = @{}
  foreach ($row in $snapshot.files) { $afterMap[$row.root + '|' + $row.relative_path] = $row }
  $new = @($afterMap.Keys | Where-Object { -not $beforeMap.ContainsKey($_) } | Sort-Object)
  $removed = @($beforeMap.Keys | Where-Object { -not $afterMap.ContainsKey($_) } | Sort-Object)
  $changed = @($afterMap.Keys | Where-Object {
    $beforeMap.ContainsKey($_) -and (
      [int64]$afterMap[$_].bytes -ne [int64]$beforeMap[$_].bytes -or
      [string]$afterMap[$_].sha256 -cne [string]$beforeMap[$_].sha256 -or
      [int64]$afterMap[$_].last_write_utc_ticks -ne [int64]$beforeMap[$_].last_write_utc_ticks
    )
  } | Sort-Object)
  $beforeSource = @($before.git | Where-Object path -eq $sourceRoot)[0]
  $afterSource = @($snapshot.git | Where-Object path -eq $sourceRoot)[0]
  $comparison = [ordered]@{
    result = if (($new.Count + $removed.Count + $changed.Count) -eq 0 -and
      $beforeSource.head -ceq $afterSource.head -and
      $beforeSource.tree -ceq $afterSource.tree -and
      (@($beforeSource.status) -join [char]10) -ceq (@($afterSource.status) -join [char]10)) {'PASS'} else {'FAIL'}
    prior_immutable_artifact_new_writes = $new.Count
    removed_files = $removed.Count
    changed_files = $changed.Count
    new = $new
    removed = $removed
    changed = $changed
    product_source_head_unchanged = ($beforeSource.head -ceq $afterSource.head)
    product_source_tree_unchanged = ($beforeSource.tree -ceq $afterSource.tree)
    product_source_status_unchanged = ((@($beforeSource.status) -join [char]10) -ceq (@($afterSource.status) -join [char]10))
  }
  $comparisonPath = [IO.Path]::ChangeExtension($OutputPath,'.comparison.json')
  [IO.File]::WriteAllText($comparisonPath,($comparison | ConvertTo-Json -Depth 6) + [Environment]::NewLine,[Text.UTF8Encoding]::new($false))
}

[ordered]@{
  phase=$Phase
  output=$OutputPath
  root_count=$rootRows.Count
  file_count=$items.Count
  comparison=$comparison
} | ConvertTo-Json -Depth 6
