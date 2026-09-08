[CmdletBinding()]
param(
  [Parameter(Mandatory)][string]$Receipt,
  [Parameter(Mandatory)][string]$Archive,
  [Parameter(Mandatory)][string]$Destination
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$payload = Get-Content -Raw -LiteralPath $Receipt | ConvertFrom-Json
if ([int]$payload.exit_code -ne 0 -or $payload.problem) {
  throw 'R3R4R6R2R3_METADATA_TRANSFER_RECEIPT_FAILED'
}
$encoded = ([string]$payload.stdout).Trim()
if (-not $encoded -or $encoded -notmatch '^[A-Za-z0-9+/]+={0,2}$') {
  throw 'R3R4R6R2R3_METADATA_TRANSFER_BASE64_INVALID'
}
$bytes = [Convert]::FromBase64String($encoded)
$stream = [IO.File]::Open($Archive,'CreateNew','Write','None')
try {
  $stream.Write($bytes,0,$bytes.Length)
  $stream.Flush($true)
} finally {
  $stream.Dispose()
  [Array]::Clear($bytes,0,$bytes.Length)
}
if (Test-Path -LiteralPath $Destination) {
  throw 'R3R4R6R2R3_METADATA_DESTINATION_EXISTS'
}
[void](New-Item -ItemType Directory -Path $Destination)
& tar.exe -xzf $Archive -C $Destination
if ($LASTEXITCODE -ne 0) {
  throw 'R3R4R6R2R3_METADATA_ARCHIVE_EXTRACTION_FAILED'
}
[ordered]@{
  archive=$Archive
  archive_bytes=(Get-Item -LiteralPath $Archive).Length
  archive_sha256=(Get-FileHash -Algorithm SHA256 -LiteralPath $Archive).Hash
  destination=$Destination
  extracted_files=@(Get-ChildItem -LiteralPath $Destination -Recurse -File).Count
} | ConvertTo-Json -Depth 4
