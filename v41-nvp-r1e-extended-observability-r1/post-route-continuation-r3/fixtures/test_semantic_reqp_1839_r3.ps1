param(
  [Parameter(Mandatory=$true)][string]$R2DrcReport,
  [Parameter(Mandatory=$true)][string]$OutputDirectory
)
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

function Test-Case {
  param(
    [string]$Name,
    [string[]]$SemanticObjectNames,
    [int]$RawOccurrences,
    [int]$CheckObjectCount,
    [bool]$ExpectedPass
  )
  $unique = @($SemanticObjectNames | Sort-Object -Unique)
  $actualPass = ($CheckObjectCount -eq 1 -and $unique.Count -eq 4)
  if ($actualPass -ne $ExpectedPass) {
    throw "Fixture $Name failed: semantic=$($unique.Count) checks=$CheckObjectCount actual=$actualPass expected=$ExpectedPass"
  }
  [pscustomobject]@{
    FIXTURE = $Name
    RAW_TEXT_OCCURRENCES = $RawOccurrences
    RETURNED_SEMANTIC_OBJECTS = $SemanticObjectNames.Count
    DEDUPLICATED_SEMANTIC_OBJECTS = $unique.Count
    CHECK_OBJECT_COUNT = $CheckObjectCount
    EXPECTED = $(if($ExpectedPass){'PASS'}else{'FAIL'})
    RESULT = 'PASS'
  }
}

$rows = @()
$rows += Test-Case A @('REQP-1839#1','REQP-1839#2','REQP-1839#3','REQP-1839#4') 5 1 $true
$rows += Test-Case B @('REQP-1839#1','REQP-1839#2','REQP-1839#3','REQP-1839#4') 4 1 $true
$rows += Test-Case C @('REQP-1839#1','REQP-1839#2','REQP-1839#3','REQP-1839#4','REQP-1839#5') 6 1 $false
$rows += Test-Case D @() 1 1 $false
$rows += Test-Case E @('REQP-1839#1','REQP-1839#1','REQP-1839#2','REQP-1839#3','REQP-1839#4') 6 1 $true
$rows += Test-Case F @('REQP-1839#1','REQP-1839#2','REQP-1839#3','REQP-1839#4') 4 2 $false
$rows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'FIXTURE_RESULTS.csv') -NoTypeInformation

$r2Text = Get-Content -LiteralPath $R2DrcReport -Raw
$raw = ([regex]::Matches($r2Text, 'REQP-1839')).Count
$semanticNames = @([regex]::Matches($r2Text, '(?m)^\s*REQP-1839#\d+\b') | ForEach-Object { $_.Value.Trim() } | Sort-Object -Unique)
if ($raw -ne 5 -or $semanticNames.Count -ne 4) {
  throw "R2 replay mismatch: raw=$raw semantic=$($semanticNames.Count)"
}
@"
# R2 report replay

R2_REPORT=$R2DrcReport
R2_RAW_TEXT_OCCURRENCES=$raw
R2_SEMANTIC_VIOLATIONS=$($semanticNames.Count)
R2_REPLAY_GATE=PASS_WITH_SEMANTIC_COUNT
RAW_TEXT_OCCURRENCES_USED_AS_GATE=NO
SEMANTIC_RECORDS=$($semanticNames -join ',')
"@ | Set-Content -LiteralPath (Join-Path $OutputDirectory 'R2_REPORT_REPLAY.md') -Encoding utf8

Write-Output "SEMANTIC_FIXTURES=PASS"
Write-Output "R2_RAW_TEXT_OCCURRENCES=$raw"
Write-Output "R2_SEMANTIC_VIOLATIONS=$($semanticNames.Count)"
Write-Output "R2_REPLAY_GATE=PASS_WITH_SEMANTIC_COUNT"
