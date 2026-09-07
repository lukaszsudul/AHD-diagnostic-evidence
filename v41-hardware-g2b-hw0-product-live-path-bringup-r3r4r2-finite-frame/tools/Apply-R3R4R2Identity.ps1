[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$run = 'C:\FPGA\G2B_HW0_PRODUCT_R3R4R2_20260907T071912Z'
$files = @(
  'capture_r3r4.py',
  'capture_r3r4_selftest.py',
  'frame_reconstruct_r3r4.py',
  'Invoke-R3R4R2DutConnection.ps1'
)
$replacements = @(
  [ordered]@{ old = 'R3R4R1'; new = 'R3R4R2' },
  [ordered]@{ old = 'r3r4r1'; new = 'r3r4r2' },
  [ordered]@{ old = '20260907T050126Z'; new = '20260907T071912Z' },
  [ordered]@{ old = 'T34'; new = 'T3T4' },
  [ordered]@{ old = 'r3r4-c2h-reader'; new = 'r3r4r2-c2h-reader' }
)
$rows = [Collections.Generic.List[object]]::new()
$utf8 = [Text.UTF8Encoding]::new($false)

foreach ($name in $files) {
  $path = Join-Path $run ('scripts\' + $name)
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "R3R4R2_IDENTITY_SOURCE_MISSING:$name"
  }
  $before = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  $text = [IO.File]::ReadAllText($path)
  foreach ($replacement in $replacements) {
    $text = $text.Replace($replacement.old, $replacement.new)
  }
  [IO.File]::WriteAllText($path, $text, $utf8)
  $afterText = [IO.File]::ReadAllText($path)
  if ($afterText.Contains('R3R4R1') -or
      $afterText.Contains('r3r4r1') -or
      $afterText.Contains('20260907T050126Z') -or
      $afterText.Contains('T34')) {
    throw "R3R4R2_IDENTITY_REPLACEMENT_INCOMPLETE:$name"
  }
  $rows.Add([ordered]@{
    file = $name
    before_sha256 = $before
    after_sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
  })
}

[ordered]@{
  schema = 'R3R4R2_RUN_IDENTITY_UPDATE_V1'
  result = 'PASS'
  replacements = $replacements
  files = @($rows)
} | ConvertTo-Json -Depth 5
