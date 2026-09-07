[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$R3R3Root,
  [Parameter(Mandatory)][string]$R3R4Root,
  [Parameter(Mandatory)][string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Test-Manifest([string]$Root,[string]$ManifestName) {
  $manifestPath = Join-Path $Root $ManifestName
  if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "MANIFEST_MISSING:$manifestPath"
  }
  $failures = [Collections.Generic.List[object]]::new()
  $entries = 0
  foreach ($line in [IO.File]::ReadAllLines($manifestPath)) {
    if (-not $line.Trim()) { continue }
    if ($line -notmatch '^([0-9A-Fa-f]{64})  (.+)$') {
      $failures.Add([ordered]@{path=$null;reason='MALFORMED_LINE';line=$line})
      continue
    }
    $entries++
    $expected = $Matches[1].ToUpperInvariant()
    $relative = $Matches[2].Replace('/','\')
    $candidate = [IO.Path]::GetFullPath((Join-Path $Root $relative))
    $prefix = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
    if (-not $candidate.StartsWith($prefix,[StringComparison]::OrdinalIgnoreCase)) {
      $failures.Add([ordered]@{path=$relative;reason='PATH_ESCAPE'})
      continue
    }
    if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      $failures.Add([ordered]@{path=$relative;reason='MISSING'})
      continue
    }
    $actual = (Get-FileHash -LiteralPath $candidate -Algorithm SHA256).Hash
    if ($actual -cne $expected) {
      $failures.Add([ordered]@{path=$relative;reason='HASH_MISMATCH';expected=$expected;actual=$actual})
    }
  }
  [ordered]@{
    root=$Root
    manifest=$ManifestName
    entries=$entries
    failures=@($failures)
    result=if($failures.Count -eq 0){'PASS'}else{'FAIL'}
  }
}

$result = [ordered]@{
  schema='R3R4R1_PREDECESSOR_MANIFEST_VERIFICATION_V1'
  collected_utc=[DateTime]::UtcNow.ToString('o')
  r3r3=Test-Manifest $R3R3Root 'G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt'
  r3r4=Test-Manifest $R3R4Root 'G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt'
}
$result.overall = if($result.r3r3.result -eq 'PASS' -and $result.r3r4.result -eq 'PASS'){'PASS'}else{'FAIL'}
[IO.File]::WriteAllText($OutputPath,($result | ConvertTo-Json -Depth 8) + [Environment]::NewLine,[Text.UTF8Encoding]::new($false))
$result | ConvertTo-Json -Depth 8
if($result.overall -ne 'PASS'){exit 1}
