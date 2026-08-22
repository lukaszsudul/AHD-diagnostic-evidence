[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LogPath,
    [Parameter(Mandatory)][string]$ExpectedClassification,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1')
$resolved = (Resolve-Path -LiteralPath $LogPath).Path
$records = ConvertTo-I25ObserverRecords -Lines ([IO.File]::ReadAllLines($resolved))
$result = Test-I25ProgramObserver -Records $records
$rendered = @($result.PSObject.Properties | ForEach-Object { '{0}={1}' -f $_.Name,$_.Value })
$rendered
if ($result.CLASSIFICATION -cne $ExpectedClassification) {
    throw "classification mismatch: expected=$ExpectedClassification actual=$($result.CLASSIFICATION)"
}
'EXPECTED_CLASSIFICATION_MATCH=PASS'
if ($OutputPath) {
    [IO.File]::WriteAllLines($OutputPath,@(
        'LOG_PATH=' + $resolved,
        'LOG_SHA256=' + (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash,
        $rendered,
        'EXPECTED_CLASSIFICATION=' + $ExpectedClassification,
        'EXPECTED_CLASSIFICATION_MATCH=PASS'
    ),[Text.UTF8Encoding]::new($false))
}
