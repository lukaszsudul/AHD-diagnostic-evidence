[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ValidationDirectory,

    [Parameter(Mandatory)]
    [string]$ReceiptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$referenceRoot = 'C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\sets'
$expected = @(
    [pscustomobject]@{ Actual = 'G2B_BS3_SLOT_SOURCES.txt'; Reference = 'S_AXIS_SLOT.txt'; Count = 2; Hash = 'EEC952FD391CBDE81D7BA5918BB293C1C309C8D3A5E511A86884B3F2FDBC7668' }
    [pscustomobject]@{ Actual = 'G2B_BS3_GENERATION_SOURCES.txt'; Reference = 'S_AXIS_GENERATION.txt'; Count = 24; Hash = 'FEBDD92ABC37EBCF3E24F77A5F25F95A46C4724506EAC97ABCB5D417693EF133' }
    [pscustomobject]@{ Actual = 'G2B_BS3_EPOCH_SOURCES.txt'; Reference = 'S_AXIS_EPOCH.txt'; Count = 32; Hash = '3764639B5C1F5D32DD6719B678DACC3E2AB92DD2F05ABDE6F87AF52B62029067' }
    [pscustomobject]@{ Actual = 'G2B_BS3_DESTINATION_CELLS.txt'; Reference = 'K_PAYLOAD_DEPENDENT.txt'; Count = 17; Hash = 'F203E7D345FD6B707963F6A27D87508A0480C2249A3E209E15BB023791C12846' }
)

function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    $map = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        $parts = $line -split '=', 2
        if ($parts.Count -eq 2) { $map[$parts[0]] = $parts[1] }
    }
    return $map
}

function Get-CanonicalLineHash {
    param([Parameter(Mandatory)][string[]]$Lines)
    $text = (($Lines | Sort-Object) -join "`n") + "`n"
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($text)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([Convert]::ToHexString($sha.ComputeHash($bytes))) }
    finally { $sha.Dispose() }
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('CHECK=G2B_BS3_EXACT_IDENTITY_AND_CLOCK_GATE')
$lines.Add("VALIDATION_DIRECTORY=$ValidationDirectory")

foreach ($entry in $expected) {
    $actualPath = Join-Path $ValidationDirectory $entry.Actual
    $referencePath = Join-Path $referenceRoot $entry.Reference
    foreach ($path in @($actualPath, $referencePath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing identity list: $path" }
    }
    $actualLines = @(Get-Content -LiteralPath $actualPath | Where-Object { $_ -ne '' })
    $referenceLines = @(Get-Content -LiteralPath $referencePath | Where-Object { $_ -ne '' })
    if ($actualLines.Count -ne $entry.Count -or $referenceLines.Count -ne $entry.Count) {
        throw "Count mismatch for $($entry.Actual): actual=$($actualLines.Count) reference=$($referenceLines.Count) expected=$($entry.Count)"
    }
    $difference = @(Compare-Object -ReferenceObject $referenceLines -DifferenceObject $actualLines)
    if ($difference.Count -ne 0) { throw "Exact identity mismatch for $($entry.Actual)" }
    $referenceHash = (Get-FileHash -LiteralPath $referencePath -Algorithm SHA256).Hash.ToUpperInvariant()
    $actualHash = (Get-FileHash -LiteralPath $actualPath -Algorithm SHA256).Hash.ToUpperInvariant()
    if ($referenceHash -ne $entry.Hash) {
        throw "Qualified reference SHA-256 mismatch for $($entry.Reference): reference=$referenceHash expected=$($entry.Hash)"
    }
    $actualCanonicalHash = Get-CanonicalLineHash -Lines $actualLines
    $referenceCanonicalHash = Get-CanonicalLineHash -Lines $referenceLines
    if ($actualCanonicalHash -ne $referenceCanonicalHash) {
        throw "Canonical exact-identity hash mismatch for $($entry.Actual)"
    }
    $lines.Add("IDENTITY|$($entry.Actual)|COUNT=$($entry.Count)|REFERENCE_SHA256=$referenceHash|ACTUAL_RAW_SHA256=$actualHash|CANONICAL_SHA256=$actualCanonicalHash|RESULT=PASS")
}

$inventoryPath = Join-Path $ValidationDirectory 'G2B_BS3_OBJECT_INVENTORY.txt'
if (-not (Test-Path -LiteralPath $inventoryPath -PathType Leaf)) { throw "Missing inventory: $inventoryPath" }
$inventory = Read-KeyValueFile -Path $inventoryPath
$requiredInventory = @{
    PART = 'xc7a35tcsg325-2'
    SLOT_SOURCE_COUNT = '2'
    GENERATION_SOURCE_COUNT = '24'
    EPOCH_SOURCE_COUNT = '32'
    TOTAL_SOURCE_COUNT = '58'
    DESTINATION_CELL_COUNT = '17'
    DESTINATION_D_PIN_COUNT = '17'
    REQUEST_SYNC_COUNT = '2'
    ACK_SYNC_COUNT = '2'
    USERCLK1_PERIOD_NS = '16.000'
    NVP_VCLK1_PERIOD_NS = '6.734'
    CANDIDATE_BOUND_NS = '6.000'
}
foreach ($key in $requiredInventory.Keys) {
    if (-not $inventory.ContainsKey($key) -or $inventory[$key] -ne $requiredInventory[$key]) {
        throw "Inventory gate mismatch: $key actual=$($inventory[$key]) expected=$($requiredInventory[$key])"
    }
    $lines.Add("INVENTORY|$key=$($inventory[$key])|RESULT=PASS")
}

$syncPath = Join-Path $ValidationDirectory 'G2B_BS3_SYNCHRONIZER_INVENTORY.txt'
$expectedSync = @(
    'REQUEST|G2B_ONECH_C2H/own_req_sync1_source_reg|ASYNC_REG=TRUE'
    'REQUEST|G2B_ONECH_C2H/own_req_sync2_source_reg|ASYNC_REG=TRUE'
    'ACK|G2B_ONECH_C2H/own_ack_sync1_axi_reg|ASYNC_REG=TRUE'
    'ACK|G2B_ONECH_C2H/own_ack_sync2_axi_reg|ASYNC_REG=TRUE'
)
$actualSync = @(Get-Content -LiteralPath $syncPath | Where-Object { $_ -ne '' })
if (@(Compare-Object -ReferenceObject $expectedSync -DifferenceObject $actualSync).Count -ne 0) {
    throw 'Synchronizer identity/attribute mismatch'
}
$lines.Add('SYNCHRONIZERS=2_REQUEST_PLUS_2_ACK_ASYNC_REG_TRUE')
$lines.Add('RESULT=PASS')

[IO.File]::WriteAllText($ReceiptPath, (($lines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
