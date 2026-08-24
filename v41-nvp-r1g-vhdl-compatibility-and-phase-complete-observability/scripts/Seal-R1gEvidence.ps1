[CmdletBinding()]
param(
    [Parameter()]
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$manifestName = 'SHA256_MANIFEST.txt'
$zipName = 'V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE_SHA256.txt'
$manifestPath = Join-Path $TaskRoot $manifestName
$zipPath = Join-Path $TaskRoot $zipName
$sidecarPath = Join-Path $TaskRoot $sidecarName
$excluded = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
foreach ($path in @($manifestPath, $zipPath, $sidecarPath)) {
    [void]$excluded.Add([System.IO.Path]::GetFullPath($path))
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to overwrite sealed output: $path"
    }
}

$rootFull = [System.IO.Path]::GetFullPath($TaskRoot).TrimEnd('\')
$files = @(
    Get-ChildItem -LiteralPath $rootFull -Recurse -Force -File |
        Where-Object { -not $excluded.Contains($_.FullName) } |
        ForEach-Object {
            $relative = [System.IO.Path]::GetRelativePath($rootFull, $_.FullName).Replace('\', '/')
            if ([string]::IsNullOrWhiteSpace($relative) -or
                $relative.StartsWith('../', [System.StringComparison]::Ordinal) -or
                $relative.Contains('|') -or $relative.Contains("`r") -or $relative.Contains("`n")) {
                throw "Unsafe manifest path: $relative"
            }
            [pscustomobject]@{ File = $_; Relative = $relative }
        } |
        Sort-Object -Property Relative -CaseSensitive
)

$caseFold = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
$manifestLines = [System.Collections.Generic.List[string]]::new()
$manifestLines.Add('FORMAT=SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH')
foreach ($item in $files) {
    if (-not $caseFold.Add($item.Relative)) {
        throw "Case-fold duplicate path: $($item.Relative)"
    }
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $item.File.FullName).Hash
    $manifestLines.Add("$hash|$($item.File.Length)|$($item.Relative)")
}

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText(
    $manifestPath,
    (($manifestLines -join "`r`n") + "`r`n"),
    $utf8NoBom)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipStream = [System.IO.File]::Open(
    $zipPath,
    [System.IO.FileMode]::CreateNew,
    [System.IO.FileAccess]::ReadWrite,
    [System.IO.FileShare]::None)
try {
    $archive = [System.IO.Compression.ZipArchive]::new(
        $zipStream,
        [System.IO.Compression.ZipArchiveMode]::Create,
        $true)
    try {
        $packageFiles = @($files) + @(
            [pscustomobject]@{
                File = Get-Item -LiteralPath $manifestPath
                Relative = $manifestName
            })
        foreach ($item in $packageFiles) {
            $entry = $archive.CreateEntry(
                $item.Relative,
                [System.IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = [System.DateTimeOffset]::new($item.File.LastWriteTimeUtc)
            $input = [System.IO.File]::OpenRead($item.File.FullName)
            try {
                $output = $entry.Open()
                try { $input.CopyTo($output) } finally { $output.Dispose() }
            } finally {
                $input.Dispose()
            }
        }

        $emptyDirectories = @(
            Get-ChildItem -LiteralPath $rootFull -Recurse -Force -Directory |
                Where-Object { @(Get-ChildItem -LiteralPath $_.FullName -Force).Count -eq 0 } |
                ForEach-Object {
                    [System.IO.Path]::GetRelativePath($rootFull, $_.FullName).Replace('\', '/').TrimEnd('/') + '/'
                } |
                Sort-Object -Unique -CaseSensitive
        )
        foreach ($relative in $emptyDirectories) {
            [void]$archive.CreateEntry($relative)
        }
    } finally {
        $archive.Dispose()
    }
} finally {
    $zipStream.Dispose()
}

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
[System.IO.File]::WriteAllText(
    $sidecarPath,
    "$zipHash  $zipName`r`n",
    $utf8NoBom)

Write-Output "MANIFEST_ROWS=$($files.Count)"
Write-Output "MANIFEST_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash)"
Write-Output "ZIP_BYTES=$((Get-Item -LiteralPath $zipPath).Length)"
Write-Output "EVIDENCE_PACKAGE_SHA256=$zipHash"
Write-Output "SIDECAR_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $sidecarPath).Hash)"
