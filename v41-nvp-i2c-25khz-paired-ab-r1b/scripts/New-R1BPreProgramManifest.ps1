[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1B',
    [string]$OutputPath = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1B\03_PRECHECK\PRE_PROGRAM_SHA256_MANIFEST.txt'
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $TaskRoot).Path
$files = [Collections.Generic.List[IO.FileInfo]]::new()
foreach ($name in @('00_PRIOR_EVIDENCE','01_ARTIFACT_IDENTITY','02_PROGRAM_OBSERVER_FIX','03_PRECHECK','scripts','fixtures')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $root $name) -Recurse -File) {
        if ($file.FullName -cne [IO.Path]::GetFullPath($OutputPath)) { $files.Add($file) }
    }
}
foreach ($name in @('OPERATION_LEDGER.md','TIME_LEDGER.md')) {
    $files.Add((Get-Item -LiteralPath (Join-Path $root $name)))
}
$rows = @($files | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($root.Length).TrimStart('\').Replace('\','/')
    '{0}  {1}' -f (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash,$relative
})
$rows += 'FILE_COUNT=' + $files.Count
[IO.File]::WriteAllLines($OutputPath,$rows,[Text.UTF8Encoding]::new($false))
$rows

