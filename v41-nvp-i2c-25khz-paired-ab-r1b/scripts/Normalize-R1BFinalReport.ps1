[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ReportPath,
    [Parameter(Mandatory)][string]$SupplementalOutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$report = (Resolve-Path -LiteralPath $ReportPath -ErrorAction Stop).Path
$supplemental = [IO.Path]::GetFullPath($SupplementalOutputPath)
if (Test-Path -LiteralPath $supplemental) { throw 'supplemental output must be fresh' }

$text = [IO.File]::ReadAllText($report)
$firstMarker = '## Required final block'
$canonicalMarker = '## Required R1b owner block'
$firstIndex = $text.IndexOf($firstMarker,[StringComparison]::Ordinal)
$canonicalIndex = $text.IndexOf($canonicalMarker,[StringComparison]::Ordinal)
if ($firstIndex -lt 0 -or $canonicalIndex -le $firstIndex) {
    throw 'expected supplemental/canonical block markers were not found in order'
}
if ($text.IndexOf($firstMarker,$firstIndex + $firstMarker.Length,[StringComparison]::Ordinal) -ge 0 -or
    $text.IndexOf($canonicalMarker,$canonicalIndex + $canonicalMarker.Length,[StringComparison]::Ordinal) -ge 0) {
    throw 'block marker count is not exactly one each'
}

$supplementalText = $text.Substring($firstIndex,$canonicalIndex - $firstIndex).TrimEnd() + "`r`n"
$normalized = $text.Substring(0,$firstIndex).TrimEnd() + "`r`n`r`n" + $text.Substring($canonicalIndex)
[IO.File]::WriteAllText($supplemental,$supplementalText,[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllText($report,$normalized,[Text.UTF8Encoding]::new($false))

'REPORT_NORMALIZATION=PASS'
'SUPPLEMENTAL_BLOCK_PRESERVED=' + $supplemental
'CANONICAL_TERMINAL_BLOCK_COUNT=' + ([regex]::Matches($normalized,[regex]::Escape($canonicalMarker))).Count
'SUPPLEMENTAL_BLOCK_COUNT_IN_REPORT=' + ([regex]::Matches($normalized,[regex]::Escape($firstMarker))).Count
