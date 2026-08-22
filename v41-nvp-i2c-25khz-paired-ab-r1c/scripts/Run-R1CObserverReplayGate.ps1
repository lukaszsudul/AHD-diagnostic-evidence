[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LogPath,
    [Parameter(Mandatory)][string]$ExpectedClassification,
    [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$parserPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'
$expectedParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
if ((Get-FileHash -LiteralPath $parserPath -Algorithm SHA256).Hash -cne $expectedParserSha) {
    throw 'accepted R1b parser identity mismatch'
}

. $parserPath
$resolvedLog = (Resolve-Path -LiteralPath $LogPath -ErrorAction Stop).Path
$outputFull = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $outputFull) { throw "output path must be fresh: $outputFull" }

$records = ConvertTo-I25ObserverRecords -Lines ([IO.File]::ReadAllLines($resolvedLog))
$result = Test-I25ProgramObserver -Records $records
if ($result.CLASSIFICATION -cne $ExpectedClassification) {
    throw "classification mismatch: expected=$ExpectedClassification actual=$($result.CLASSIFICATION)"
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('LOG_PATH=' + $resolvedLog)
$lines.Add('LOG_SHA256=' + (Get-FileHash -LiteralPath $resolvedLog -Algorithm SHA256).Hash)
$lines.Add('OBSERVER_PARSER_SHA256=' + $expectedParserSha)
foreach ($property in $result.PSObject.Properties) {
    $lines.Add(('{0}={1}' -f $property.Name,$property.Value))
}
$lines.Add('EXPECTED_CLASSIFICATION=' + $ExpectedClassification)
$lines.Add('EXPECTED_CLASSIFICATION_MATCH=PASS')
[IO.File]::WriteAllLines($outputFull,[string[]]$lines,[Text.UTF8Encoding]::new($false))
$lines
