[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$EvidenceRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $EvidenceRoot).Path
$manifest = Join-Path $root 'SHA256_MANIFEST.txt'

if (-not (Test-Path -LiteralPath $manifest)) {
    throw "Manifest not found: $manifest"
}

$checked = 0
foreach ($line in Get-Content -LiteralPath $manifest) {
    if ([string]::IsNullOrWhiteSpace($line) -or $line.StartsWith('#')) { continue }
    $parts = $line -split '  ', 3
    if ($parts.Count -ne 3) { throw "Malformed manifest line: $line" }
    $expected = $parts[0]
    $expectedSize = [int64]$parts[1]
    $relative = $parts[2].Replace('/', [IO.Path]::DirectorySeparatorChar)
    $path = Join-Path $root $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing: $relative" }
    $item = Get-Item -LiteralPath $path
    if ($item.Length -ne $expectedSize) { throw "Size mismatch: $relative" }
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
    if ($actual -ne $expected) { throw "SHA-256 mismatch: $relative" }
    $checked++
}

"PUBLIC_EVIDENCE_MANIFEST=PASS"
"FILES_VERIFIED=$checked"
