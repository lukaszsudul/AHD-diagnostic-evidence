[CmdletBinding()]
param(
    [switch]$SyntheticTestMode,
    [string]$SyntheticRoot,
    [switch]$SyntheticMutateAfterSnapshot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$taskName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1'
$reportTaskName = 'V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1'
$expectedProductionRoot = 'C:\FPGA\V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1'
$archiveRoot = $taskName
$zipName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE_SHA256.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$securityRelative = '08_FINAL/SECURITY_SCAN.txt'
$integrityRelative = '08_FINAL/EVIDENCE_ZIP_INTEGRITY.txt'
$publicationReceiptNames = @(
    'EVIDENCE_PUBLICATION_RECEIPT.md',
    'PUBLICATION_RECEIPT.md',
    'POST_SEAL_CLOSURE_RECEIPT.md'
)
$fixedZipTimestamp = [DateTimeOffset]::new(2000,1,1,0,0,0,[TimeSpan]::Zero)
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$maximumContentScanBytes = 67108864

function Get-FullPath([string]$Path) {
    return [IO.Path]::GetFullPath($Path)
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-StreamSha256([IO.Stream]$Stream) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($Stream))).Replace('-','')
    } finally {
        $sha.Dispose()
    }
}

function Get-OrdinalSortedStrings([string[]]$Values) {
    $copy = [string[]]@($Values)
    [Array]::Sort($copy,[StringComparer]::Ordinal)
    return $copy
}

$temporaryRootPrefix = (Get-FullPath ([IO.Path]::GetTempPath())).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
if ($SyntheticMutateAfterSnapshot -and -not $SyntheticTestMode) {
    throw 'SyntheticMutateAfterSnapshot is forbidden outside SyntheticTestMode'
}

if ($SyntheticTestMode) {
    if ([string]::IsNullOrWhiteSpace($SyntheticRoot)) { throw 'SyntheticRoot is required in SyntheticTestMode' }
    $root = Get-FullPath $SyntheticRoot
    $testMarker = Join-Path $root '.CONTROL_FLOW_SEAL_TEST_ROOT'
    if (-not $root.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $root).StartsWith('control-flow-seal-test-',[StringComparison]::Ordinal) -or
        -not (Test-Path -LiteralPath $testMarker -PathType Leaf)) {
        throw 'synthetic-test root boundary is invalid'
    }
} else {
    if (-not [string]::IsNullOrWhiteSpace($SyntheticRoot)) { throw 'SyntheticRoot is forbidden in production mode' }
    $root = Get-FullPath (Split-Path -Parent $PSScriptRoot)
    if ($root -cne $expectedProductionRoot) {
        throw "production sealer must run only from $expectedProductionRoot\scripts"
    }
}

$rootPrefix = $root.TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar

function Get-Relative([string]$Path) {
    $full = Get-FullPath $Path
    if (-not $full.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)) {
        throw "path escapes evidence root: $Path"
    }
    $relative = $full.Substring($rootPrefix.Length).Replace('\','/')
    if ([string]::IsNullOrWhiteSpace($relative) -or
        $relative.StartsWith('/') -or
        $relative.Contains('\') -or
        $relative -match '(^|/)\.\.?(/|$)' -or
        $relative.IndexOf([char]0) -ge 0) {
        throw "unsafe relative path: $relative"
    }
    return $relative
}

$zipPath = Join-Path $root $zipName
$sidecarPath = Join-Path $root $sidecarName
$manifestPath = Join-Path $root $manifestName
$securityPath = Join-Path $root ($securityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
$integrityPath = Join-Path $root ($integrityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
$freshOutputPaths = @($zipPath,$sidecarPath,$manifestPath,$securityPath,$integrityPath)

foreach ($path in $freshOutputPaths) {
    if (Test-Path -LiteralPath $path) { throw "seal output must be fresh: $path" }
}

function Assert-NoReparsePoints {
    $hits = @(Get-ChildItem -LiteralPath $root -Force -Recurse | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    })
    if ($hits.Count -ne 0) { throw "reparse point present under evidence root; count=$($hits.Count)" }
}

function Test-ForbiddenArtifact([IO.FileInfo]$File) {
    $relative = Get-Relative $File.FullName
    $segments = @($relative -split '/')
    $leaf = $segments[-1]
    $extension = $File.Extension.ToLowerInvariant()

    if ($segments | Where-Object { $_ -in @('.git','.hg','.svn','.Xil','__pycache__') }) {
        return 'VCS_OR_TRANSIENT_DIRECTORY'
    }
    if ($extension -in @('.bit','.dcp')) { return 'FPGA_BIT_OR_DCP' }
    if ($extension -in @('.zip','.7z','.rar','.tar','.tgz','.gz','.bz2','.xz')) {
        if ($leaf -ceq $zipName) { return $null }
        return 'NESTED_ARCHIVE'
    }
    if ($extension -in @('.tmp','.temp','.swp','.swo','.pyc','.pyo')) { return 'TEMPORARY_FILE' }
    if ($leaf -match '(?i)(?:~$|^~\$|\.bak$|\.orig$|\.rej$)') { return 'TEMPORARY_OR_BACKUP_FILE' }
    if ($leaf -in @('Thumbs.db','desktop.ini','.DS_Store')) { return 'TRANSIENT_METADATA_FILE' }
    return $null
}

function Test-ForbiddenSecurityFilename([IO.FileInfo]$File) {
    $name = $File.Name
    if ($name -ieq 'VCDE-DUT-1.txt') { return $true }
    if ($name -match '(?i)^pw-[0-9a-f-]+\.tmp$') { return $true }
    if ($name -match '(?i)^(?:\.env(?:\..+)?|credentials?(?:\..+)?|secrets?(?:\..+)?|passwords?(?:\..+)?|passwd|shadow)$') { return $true }
    if ($name -match '(?i)^(?:id_rsa|id_ed25519)(?:\.pub)?$') { return $true }
    if ($name -match '(?i)^(?:\.netrc|\.npmrc|cookies?\.txt)$') { return $true }
    if ($name -match '(?i)\.(?:pem|p12|pfx|key|kdbx|token|secret|credentials)$') { return $true }
    return $false
}

function Get-SecretContentFinding([IO.FileInfo]$File) {
    if ($File.Length -gt $maximumContentScanBytes) {
        throw "eligible file exceeds conservative content-scan limit: $(Get-Relative $File.FullName)"
    }
    $bytes = [IO.File]::ReadAllBytes($File.FullName)
    $views = [Collections.Generic.List[string]]::new()
    $views.Add([Text.Encoding]::ASCII.GetString($bytes))
    $views.Add([Text.Encoding]::UTF8.GetString($bytes))
    if (($bytes.Length % 2) -eq 0) {
        $views.Add([Text.Encoding]::Unicode.GetString($bytes))
        $views.Add([Text.Encoding]::BigEndianUnicode.GetString($bytes))
    }

    # Signatures are assembled so the scanner does not match its own source.
    $privateKey = '-----BEGIN ' + '(?:(?:RSA|OPENSSH|EC|DSA) )?PRIVATE KEY-----'
    $passwordAssignment = '(?im)^\s*(?:password|passwd|passphrase|haslo|hasło|pwd)\s*[:=]\s*' +
        '(?!NO(?:\b|_)|YES(?:\b|_)|0\b|NOT_|NONE\b|REDACTED\b|REMOVED\b|<[^>]+>|\$null\b|\$[A-Za-z_])\S+'
    $genericSecretAssignment = '(?im)^\s*(?:export\s+|\$env:)?(?:_authToken|npm_auth_token|token|api[_-]?key|' +
        'client[_-]?secret|access[_-]?key|secret[_-]?key)\s*[:=]\s*' +
        '(?!NO(?:\b|_)|YES(?:\b|_)|0\b|NOT_|NONE\b|REDACTED\b|REMOVED\b|<[^>]+>|\$null\b|\$[A-Za-z_])\S+'
    $puttyPassword = '(?i)(?<!\S)-' + 'pw(?!file)(?:[ \t]+|=)["'']?[^\s"'']+'
    $authorization = '(?im)^\s*authorization\s*:\s*(?:basic|bearer)\s+[A-Za-z0-9+/_=.-]{8,}'
    $credentialUri = '(?i)\b[a-z][a-z0-9+.-]*://[^\s/:@]+:[^\s/@]+@'
    $githubToken = '\bgh' + '[pousr]_[A-Za-z0-9]{20,}\b'
    $gitlabToken = '\bgl' + 'pat-[A-Za-z0-9_-]{20,}\b'
    $awsKey = '\bA' + 'KIA[0-9A-Z]{16}\b'
    $apiKey = '\bsk' + '-[A-Za-z0-9_-]{20,}\b'

    $patterns = [ordered]@{
        PRIVATE_KEY_HEADER = $privateKey
        PASSWORD_ASSIGNMENT = $passwordAssignment
        GENERIC_SECRET_ASSIGNMENT = $genericSecretAssignment
        PUTTY_PW_ARGUMENT = $puttyPassword
        AUTHORIZATION_SECRET = $authorization
        CREDENTIAL_IN_URI = $credentialUri
        GITHUB_TOKEN = $githubToken
        GITLAB_TOKEN = $gitlabToken
        AWS_ACCESS_KEY = $awsKey
        API_SECRET_KEY = $apiKey
    }
    foreach ($view in $views) {
        foreach ($pair in $patterns.GetEnumerator()) {
            if ([regex]::IsMatch($view,[string]$pair.Value)) { return [string]$pair.Key }
        }
    }
    return $null
}

function Get-AllTaskFilesOrdinal {
    $map = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in @(Get-ChildItem -LiteralPath $root -Force -Recurse -File)) {
        $relative = Get-Relative $file.FullName
        if ($map.ContainsKey($relative)) { throw "case-insensitive duplicate task path: $relative" }
        $map.Add($relative,$file)
    }
    foreach ($relative in (Get-OrdinalSortedStrings ([string[]]@($map.Keys)))) { $map[$relative] }
}

function Get-ExclusionReason([IO.FileInfo]$File) {
    $relative = Get-Relative $File.FullName
    $leaf = $File.Name
    if ($leaf -ceq '.CONTROL_FLOW_SEAL_TEST_ROOT') { return 'SYNTHETIC_TEST_MARKER' }
    if ($relative -ceq $manifestName) { return 'SEAL_OUTPUT' }
    if ($relative -ceq $zipName) { return 'SEAL_OUTPUT' }
    if ($relative -ceq $sidecarName) { return 'SEAL_OUTPUT' }
    if ($relative -ceq $securityRelative) { return 'SEAL_OUTPUT' }
    if ($relative -ceq $integrityRelative) { return 'SEAL_OUTPUT' }
    if ($publicationReceiptNames -contains $leaf) { return 'POST_SEAL_OR_PUBLICATION_RECEIPT' }
    return $null
}

function Assert-RequiredEvidence {
    $required = @(
        '00_SCOPE/OWNER_PROMPT_VERBATIM.md',
        '01_INPUT_IDENTITY/INPUT_IDENTITY.md',
        '01_INPUT_IDENTITY/INPUT_SHA256.txt',
        '01_INPUT_IDENTITY/SOURCE_COMMIT_DIFF_MATRIX.csv',
        '02_FIELD_AVAILABILITY/FIELD_AVAILABILITY_MATRIX.csv',
        '02_FIELD_AVAILABILITY/MMIO_ADDRESS_INVENTORY_A.csv',
        '02_FIELD_AVAILABILITY/MMIO_ADDRESS_INVENTORY_B.csv',
        '02_FIELD_AVAILABILITY/PARSED_FIELD_INVENTORY_A.txt',
        '02_FIELD_AVAILABILITY/PARSED_FIELD_INVENTORY_B.txt',
        '02_FIELD_AVAILABILITY/FIELD_AVAILABILITY_REPORT.md',
        '03_R1_VALIDATION/R1_COUNTER_RECALCULATION.csv',
        '03_R1_VALIDATION/R1_FAILURE_PATH_TRACE.md',
        '03_R1_VALIDATION/R1_METHOD_VALIDATION.md',
        '04_FSM_COST_MODEL/FSM_STATE_COSTS.csv',
        '04_FSM_COST_MODEL/TRANSACTION_COSTS.csv',
        '04_FSM_COST_MODEL/ALL_ACK_EXPECTED_COUNTS.csv',
        '04_FSM_COST_MODEL/FAILURE_PATH_RULES.csv',
        '04_FSM_COST_MODEL/MODEL_VALIDATION.md',
        '05_R1C_ARM_A/ARM_A_SHORTENING_RESULT.md',
        '05_R1C_ARM_A/ARM_A_SHORTENING_CALCULATION.csv',
        '05_R1C_ARM_A/ARM_A_FAILURE_PATH_REPLAY.csv',
        '06_R1C_ARM_B/ARM_B_SHORTENING_RESULT.md',
        '06_R1C_ARM_B/ARM_B_SHORTENING_CALCULATION.csv',
        '06_R1C_ARM_B/ARM_B_FAILURE_PATH_REPLAY.csv',
        '07_COMPARISON/R1_R1C_SHORTENING_MATRIX.csv',
        '07_COMPARISON/RAW_NACK_VS_EFFECTIVE_PATH_METRIC.md',
        '07_COMPARISON/R1C_A_B_COMPARISON.md',
        '08_FINAL/V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1_REPORT.md',
        'scripts/derive_control_flow_shortening.py',
        'OPERATION_LEDGER.md',
        'TOOL_COMMAND_LEDGER.md'
    )
    $missing = [Collections.Generic.List[string]]::new()
    foreach ($relative in $required) {
        $path = Join-Path $root ($relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
        if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -eq 0) {
            $missing.Add($relative)
        }
    }
    if ($missing.Count -ne 0) {
        throw ('required evidence missing or empty: ' + (($missing | Sort-Object) -join ', '))
    }
}

function Get-ReportField([string[]]$Lines,[string]$Key) {
    $values = [Collections.Generic.List[string]]::new()
    for ($index = 0; $index -lt $Lines.Count; $index++) {
        $match = [regex]::Match($Lines[$index],('^\s*' + [regex]::Escape($Key) + '=\s*(.*)\s*$'))
        if (-not $match.Success) { continue }
        $value = $match.Groups[1].Value.Trim()
        if ([string]::IsNullOrWhiteSpace($value)) {
            for ($next = $index + 1; $next -lt $Lines.Count; $next++) {
                $candidate = $Lines[$next].Trim()
                if ($candidate -eq '' -or $candidate -eq '```' -or $candidate -eq '```text') { continue }
                if ($candidate -match '^[A-Z0-9_]+=') { break }
                $value = $candidate
                break
            }
        }
        if (-not [string]::IsNullOrWhiteSpace($value)) { $values.Add($value) }
    }
    $unique = @($values | Sort-Object -Unique)
    if ($unique.Count -gt 1) { throw "contradictory report field $Key" }
    if ($unique.Count -eq 0) { return $null }
    return [string]$unique[0]
}

function Assert-FinalReportContract {
    $reportPath = Join-Path $root '08_FINAL\V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1_REPORT.md'
    $lines = [IO.File]::ReadAllLines($reportPath)
    $fixed = [ordered]@{
        TASK = $reportTaskName
        TASK_MODE = 'OFFLINE_EXISTING_EVIDENCE_FORENSIC'
        R1_EVIDENCE_COMMIT = 'cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c'
        R1C_EVIDENCE_COMMIT = '2c86f792bb439279d2eca69d87c21125f99bf63f'
        R1C_EVIDENCE_ZIP_SHA256 = '9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19'
        RAW_NACK_REDUCTION = '7'
        RAW_NACK_REDUCTION_INTERPRETED_AS_EFFECTIVE_OPERATION_REDUCTION = 'NO_UNLESS_PROVEN'
        FULL_BUILDS = '0'
        FPGA_SOURCE_CHANGES = '0'
        HARDWARE_ACTIONS = '0'
        MMIO_OPERATIONS = '0'
        DMA_TRANSFERS = '0'
        FORMAL_REPOSITORY_MUTATIONS = '0'
        NEXT_ACTION = 'OWNER_AND_AUDITOR_REVIEW_OF_EFFECTIVE_METRIC_AVAILABILITY'
    }
    foreach ($pair in $fixed.GetEnumerator()) {
        $actual = Get-ReportField $lines ([string]$pair.Key)
        if ($actual -cne [string]$pair.Value) {
            throw "final-report fixed field mismatch: $($pair.Key) expected=$($pair.Value) actual=$actual"
        }
    }
    $requiredNonempty = @(
        'R1_METHOD_VALIDATION','R1_EXPECTED_CNT_AT_INIT_DONE','R1_ACTUAL_CNT_AT_INIT_DONE',
        'R1_SIGNED_COUNT_ERROR_CYCLES','R1_SHORTENING_CYCLES','R1_TICK_CYCLES',
        'R1_SHORTENING_TICKS_EXACT','R1_SHORTENING_TICKS_NEAREST','R1_RESIDUAL_CYCLES',
        'R1_OMITTED_TRANSACTION_INTERPRETATION','ARM_A_SOURCE_COUNTER_PRESENT',
        'ARM_A_MMIO_COUNTER_FIELDS_READ','ARM_A_CNT_AT_INIT_DONE_AVAILABLE','ARM_A_EXPECTED_CNT_AVAILABLE',
        'ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE','ARM_A_RESULT_MODE','ARM_A_RAW_NACK_COUNT',
        'ARM_A_CONTROL_FLOW_SHORTENING_RESULT','ARM_B_SOURCE_COUNTER_PRESENT',
        'ARM_B_MMIO_COUNTER_FIELDS_READ','ARM_B_CNT_AT_INIT_DONE_AVAILABLE','ARM_B_EXPECTED_CNT_AVAILABLE',
        'ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE','ARM_B_RESULT_MODE','ARM_B_RAW_NACK_COUNT',
        'ARM_B_CONTROL_FLOW_SHORTENING_RESULT','R1C_EFFECTIVE_METRIC_CLASSIFICATION',
        'NEW_BUILD_REQUIRED_FOR_COUNTER_MEASUREMENT','NEW_HARDWARE_REQUIRED_FOR_COUNTER_MEASUREMENT',
        'EVIDENCE_PACKAGE_SHA256','EVIDENCE_REPOSITORY_COMMIT'
    )
    foreach ($key in $requiredNonempty) {
        if ([string]::IsNullOrWhiteSpace((Get-ReportField $lines $key))) {
            throw "final-report required field absent or blank: $key"
        }
    }
}

function Assert-LedgerZeroes {
    $contracts = [ordered]@{
        'OPERATION_LEDGER.md' = @(
            'FULL_BUILDS=0','SYNTHESIS_RUNS=0','IMPLEMENTATION_RUNS=0','BITSTREAMS_GENERATED=0',
            'FPGA_SOURCE_CHANGES=0','HARDWARE_ACTIONS=0','MMIO_OPERATIONS=0','DMA_TRANSFERS=0',
            'FORMAL_REPOSITORY_MUTATIONS=0'
        )
        'TOOL_COMMAND_LEDGER.md' = @(
            'TASK_MODE=OFFLINE_EXISTING_EVIDENCE_FORENSIC','FULL_BUILDS=0','SYNTHESIS_COMMANDS=0',
            'IMPLEMENTATION_COMMANDS=0','BITSTREAM_COMMANDS=0','FPGA_SOURCE_EDITS=0','SSH_COMMANDS=0',
            'JTAG_COMMANDS=0','FPGA_PROGRAM_COMMANDS=0','UBUNTU_REBOOT_COMMANDS=0','MMIO_COMMANDS=0',
            'DMA_COMMANDS=0','PHYSICAL_ACTIONS=0','FORMAL_REPOSITORY_MUTATIONS=0'
        )
    }
    foreach ($contract in $contracts.GetEnumerator()) {
        $relative = [string]$contract.Key
        $text = [IO.File]::ReadAllText((Join-Path $root $relative))
        foreach ($token in @($contract.Value)) {
            if (-not $text.Contains($token,[StringComparison]::Ordinal)) {
                throw "required zero-operation token absent: $relative :: $token"
            }
        }
    }
}

function Copy-StableSnapshotFile([IO.FileInfo]$Source,[string]$Destination) {
    $before = Get-Item -LiteralPath $Source.FullName
    $beforeLength = [Int64]$before.Length
    $beforeWriteTicks = [Int64]$before.LastWriteTimeUtc.Ticks
    $beforeHash = Get-Sha256 $before.FullName
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Destination)) | Out-Null
    [IO.File]::Copy($before.FullName,$Destination,$false)
    $snapshotHash = Get-Sha256 $Destination
    $after = Get-Item -LiteralPath $Source.FullName
    $afterHash = Get-Sha256 $after.FullName
    if ($beforeLength -ne $after.Length -or
        $beforeWriteTicks -ne $after.LastWriteTimeUtc.Ticks -or
        $beforeHash -cne $afterHash -or
        $beforeHash -cne $snapshotHash) {
        throw "source changed while snapshotting: $(Get-Relative $Source.FullName)"
    }
    return [pscustomobject]@{
        Relative = Get-Relative $Source.FullName
        Hash = $snapshotHash
        Length = [Int64]$after.Length
        LastWriteTicks = [Int64]$after.LastWriteTimeUtc.Ticks
        StagePath = $Destination
    }
}

function Write-DeterministicZip([string]$Destination,[Collections.Generic.Dictionary[string,object]]$Expected) {
    $zip = [IO.Compression.ZipFile]::Open($Destination,[IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($entryName in (Get-OrdinalSortedStrings ([string[]]@($Expected.Keys)))) {
            $record = $Expected[$entryName]
            $entry = $zip.CreateEntry($entryName,[IO.Compression.CompressionLevel]::Optimal)
            $entry.LastWriteTime = $fixedZipTimestamp
            $entry.ExternalAttributes = 0
            $input = [IO.File]::Open($record.StagePath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
            $output = $entry.Open()
            try { $input.CopyTo($output) } finally { $output.Dispose(); $input.Dispose() }
        }
    } finally {
        $zip.Dispose()
    }
}

function Assert-ZipAndManifest(
    [string]$Path,
    [Collections.Generic.Dictionary[string,object]]$Expected,
    [string]$ManifestEntryName
) {
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $actualHashes = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    $actualLengths = [Collections.Generic.Dictionary[string,Int64]]::new([StringComparer]::Ordinal)
    $manifestText = $null
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        if ($archive.Entries.Count -ne $Expected.Count) { throw 'ZIP entry-count mismatch' }
        foreach ($entry in $archive.Entries) {
            if (-not $seen.Add($entry.FullName)) { throw "duplicate ZIP entry: $($entry.FullName)" }
            if (-not $entry.FullName.StartsWith(($archiveRoot + '/'),[StringComparison]::Ordinal) -or
                $entry.FullName.EndsWith('/') -or
                $entry.FullName.StartsWith('/') -or
                $entry.FullName.Contains('\') -or
                $entry.FullName -match '(^|/)\.\.?(/|$)') {
                throw "unsafe or wrongly rooted ZIP entry: $($entry.FullName)"
            }
            if (-not $Expected.ContainsKey($entry.FullName)) { throw "unexpected ZIP entry: $($entry.FullName)" }
            if ($entry.LastWriteTime.DateTime -ne $fixedZipTimestamp.DateTime) {
                throw "non-deterministic ZIP timestamp: $($entry.FullName)"
            }
            $record = $Expected[$entry.FullName]
            if ($entry.Length -ne $record.Length) { throw "ZIP length mismatch: $($entry.FullName)" }
            $stream = $entry.Open()
            try { $actualHash = Get-StreamSha256 $stream } finally { $stream.Dispose() }
            if ($actualHash -cne $record.Hash) { throw "ZIP hash mismatch: $($entry.FullName)" }
            $actualHashes.Add($entry.FullName,$actualHash)
            $actualLengths.Add($entry.FullName,[Int64]$entry.Length)
            if ($entry.FullName -ceq $ManifestEntryName) {
                $reader = [IO.StreamReader]::new($entry.Open(),[Text.Encoding]::UTF8,$true)
                try { $manifestText = $reader.ReadToEnd() } finally { $reader.Dispose() }
            }
            if ($entry.FullName -match '(?i)\.(?:bit|dcp|zip|7z|rar|tar|tgz|gz|bz2|xz)$') {
                throw "forbidden build/archive ZIP entry: $($entry.FullName)"
            }
        }
    } finally {
        $archive.Dispose()
    }
    if ($seen.Count -ne $Expected.Count) { throw 'ZIP verification-count mismatch' }
    if ($null -eq $manifestText) { throw 'manifest entry absent from ZIP' }

    $manifestSeen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($line in @($manifestText -split "`r?`n" | Where-Object { $_ -ne '' })) {
        $match = [regex]::Match($line,'^([0-9A-F]{64})  ([0-9]+)  (.+)$')
        if (-not $match.Success) { throw "invalid manifest line: $line" }
        $relative = $match.Groups[3].Value
        $entryName = $archiveRoot + '/' + $relative
        if ($entryName -ceq $ManifestEntryName) { throw 'manifest must not self-reference' }
        if (-not $manifestSeen.Add($entryName)) { throw "duplicate manifest entry: $relative" }
        if (-not $actualHashes.ContainsKey($entryName)) { throw "manifest names absent ZIP entry: $relative" }
        if ($actualHashes[$entryName] -cne $match.Groups[1].Value -or
            $actualLengths[$entryName] -ne [Int64]::Parse($match.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)) {
            throw "manifest-to-ZIP mismatch: $relative"
        }
    }
    if ($manifestSeen.Count -ne ($Expected.Count - 1)) { throw 'manifest coverage mismatch' }
    return $seen.Count
}

Assert-NoReparsePoints
Assert-RequiredEvidence
Assert-FinalReportContract
Assert-LedgerZeroes

$allFiles = @(Get-AllTaskFilesOrdinal)
$includedFiles = [Collections.Generic.List[IO.FileInfo]]::new()
$excludedFiles = [Collections.Generic.List[object]]::new()
foreach ($file in $allFiles) {
    $relative = Get-Relative $file.FullName
    $forbiddenArtifact = Test-ForbiddenArtifact $file
    if ($null -ne $forbiddenArtifact) { throw "forbidden artifact under evidence root: $relative :: $forbiddenArtifact" }
    if (Test-ForbiddenSecurityFilename $file) { throw "forbidden security filename under evidence root: $relative" }
    $exclusionReason = Get-ExclusionReason $file
    if ($null -ne $exclusionReason) {
        $excludedFiles.Add([pscustomobject]@{ Relative=$relative; Reason=$exclusionReason })
    } else {
        $finding = Get-SecretContentFinding $file
        if ($null -ne $finding) { throw "secret-content scan failed: $relative :: $finding" }
        $includedFiles.Add($file)
    }
}
if ($includedFiles.Count -eq 0) { throw 'no eligible evidence files found' }

$stageParent = Get-FullPath (Join-Path $temporaryRootPrefix ('control-flow-evidence-stage-' + [Guid]::NewGuid().ToString('N')))
if (-not $stageParent.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase) -or
    -not (Split-Path -Leaf $stageParent).StartsWith('control-flow-evidence-stage-',[StringComparison]::Ordinal)) {
    throw 'temporary staging boundary is invalid'
}
$stageRoot = Join-Path $stageParent 'snapshot'
$workZip = Join-Path $stageParent $zipName
$workSidecar = Join-Path $stageParent $sidecarName
$workIntegrity = Join-Path $stageParent 'EVIDENCE_ZIP_INTEGRITY.txt'
[IO.Directory]::CreateDirectory($stageRoot) | Out-Null
$published = [Collections.Generic.List[string]]::new()

try {
    $snapshotRecords = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $includedFiles) {
        $relative = Get-Relative $file.FullName
        $destination = Join-Path $stageRoot ($relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
        $record = Copy-StableSnapshotFile $file $destination
        if ($snapshotRecords.ContainsKey($relative)) { throw "duplicate snapshot path: $relative" }
        $snapshotRecords.Add($relative,$record)
    }

    if ($SyntheticMutateAfterSnapshot) {
        [IO.File]::AppendAllText((Join-Path $root '08_FINAL\V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1_REPORT.md'),"`nSYNTHETIC_TOCTOU_MUTATION=YES`n",$utf8NoBom)
    }

    foreach ($record in $snapshotRecords.Values) {
        $finding = Get-SecretContentFinding (Get-Item -LiteralPath $record.StagePath)
        if ($null -ne $finding) { throw "snapshot secret-content scan failed: $($record.Relative) :: $finding" }
    }

    $securityLines = [Collections.Generic.List[string]]::new()
    foreach ($line in @(
        'SECRET_SCAN=PASS',
        'FORBIDDEN_SECURITY_FILENAMES=0',
        'SECRET_CONTENT_PATTERN_HITS=0',
        'REPARSE_POINT_COUNT=0',
        'CREDENTIAL_FILES_INCLUDED=0',
        'TEMPORARY_FILES_INCLUDED=0',
        'BITSTREAMS_INCLUDED=0',
        'DCPS_INCLUDED=0',
        'NESTED_ARCHIVES_INCLUDED=0',
        'VCS_METADATA_INCLUDED=0',
        'PAYLOAD_ROOT_PREFIX=V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1/',
        'SNAPSHOT_METHOD=SOURCE_PREHASH_COPY_POSTHASH_PLUS_FINAL_SOURCE_REHASH',
        'SNAPSHOT_LOCATION=OPERATING_SYSTEM_TEMP_DIRECTORY',
        'ZIP_ENTRY_ORDER=ORDINAL',
        'ZIP_ENTRY_TIMESTAMP=2000-01-01T00:00:00Z',
        'MANIFEST_SELF_INCLUDED=NO_SELF_REFERENCE',
        ('FILES_DISCOVERED={0}' -f $allFiles.Count),
        ('FILES_INCLUDED_BEFORE_GENERATED_SECURITY_AND_MANIFEST={0}' -f $includedFiles.Count),
        ('FILES_EXCLUDED={0}' -f $excludedFiles.Count)
    )) { $securityLines.Add($line) }
    foreach ($item in ($excludedFiles | Sort-Object Relative)) {
        $securityLines.Add(('EXCLUDED_FILE={0}|REASON={1}' -f $item.Relative,$item.Reason))
    }

    $stageSecurity = Join-Path $stageRoot ($securityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
    [IO.Directory]::CreateDirectory((Split-Path -Parent $stageSecurity)) | Out-Null
    [IO.File]::WriteAllLines($stageSecurity,[string[]]$securityLines,$utf8NoBom)

    $stageManifest = Join-Path $stageRoot $manifestName
    $manifestMap = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in @(Get-ChildItem -LiteralPath $stageRoot -Force -Recurse -File)) {
        $full = Get-FullPath $file.FullName
        if ($full -ceq (Get-FullPath $stageManifest)) { continue }
        $relative = $full.Substring($stageRoot.Length).TrimStart('\','/').Replace('\','/')
        if ($manifestMap.ContainsKey($relative)) { throw "duplicate manifest path: $relative" }
        $manifestMap.Add($relative,$file)
    }
    $manifestLines = [Collections.Generic.List[string]]::new()
    foreach ($relative in (Get-OrdinalSortedStrings ([string[]]@($manifestMap.Keys)))) {
        $file = $manifestMap[$relative]
        $manifestLines.Add(('{0}  {1}  {2}' -f (Get-Sha256 $file.FullName),$file.Length,$relative))
    }
    [IO.File]::WriteAllLines($stageManifest,[string[]]$manifestLines,$utf8NoBom)

    $expected = [Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)
    foreach ($file in @(Get-ChildItem -LiteralPath $stageRoot -Force -Recurse -File)) {
        $relative = $file.FullName.Substring($stageRoot.Length).TrimStart('\','/').Replace('\','/')
        $entryName = $archiveRoot + '/' + $relative
        if (-not $entryName.StartsWith(($archiveRoot + '/'),[StringComparison]::Ordinal) -or
            $entryName.Contains('\') -or $entryName -match '(^|/)\.\.?(/|$)') {
            throw "unsafe staged ZIP entry: $entryName"
        }
        if ($expected.ContainsKey($entryName)) { throw "duplicate staged ZIP entry: $entryName" }
        $expected.Add($entryName,[pscustomobject]@{
            Hash = Get-Sha256 $file.FullName
            Length = [Int64]$file.Length
            StagePath = $file.FullName
        })
    }

    Write-DeterministicZip $workZip $expected
    $manifestEntryName = $archiveRoot + '/' + $manifestName
    $verifiedEntryCount = Assert-ZipAndManifest $workZip $expected $manifestEntryName

    Assert-NoReparsePoints
    $currentFiles = @(Get-AllTaskFilesOrdinal)
    $currentEligible = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $currentFiles) {
        $relative = Get-Relative $file.FullName
        $forbiddenArtifact = Test-ForbiddenArtifact $file
        if ($null -ne $forbiddenArtifact) { throw "forbidden artifact appeared during seal: $relative :: $forbiddenArtifact" }
        if (Test-ForbiddenSecurityFilename $file) { throw "forbidden security filename appeared during seal: $relative" }
        if ($null -eq (Get-ExclusionReason $file)) {
            if ($currentEligible.ContainsKey($relative)) { throw "duplicate final eligible path: $relative" }
            $currentEligible.Add($relative,$file)
        }
    }
    if ($currentEligible.Count -ne $snapshotRecords.Count) { throw 'eligible source-set count changed after snapshot' }
    foreach ($relative in (Get-OrdinalSortedStrings ([string[]]@($snapshotRecords.Keys)))) {
        if (-not $currentEligible.ContainsKey($relative)) { throw "eligible source disappeared after snapshot: $relative" }
        $record = $snapshotRecords[$relative]
        $current = Get-Item -LiteralPath $currentEligible[$relative].FullName
        if ($current.Length -ne $record.Length -or
            $current.LastWriteTimeUtc.Ticks -ne $record.LastWriteTicks -or
            (Get-Sha256 $current.FullName) -cne $record.Hash) {
            throw "eligible source changed after snapshot: $relative"
        }
    }

    foreach ($entryName in (Get-OrdinalSortedStrings ([string[]]@($expected.Keys)))) {
        $record = $expected[$entryName]
        if ((Get-Sha256 $record.StagePath) -cne $record.Hash -or
            (Get-Item -LiteralPath $record.StagePath).Length -ne $record.Length) {
            throw "staged snapshot changed after ZIP creation: $entryName"
        }
    }

    $zipHash = Get-Sha256 $workZip
    $zipLength = (Get-Item -LiteralPath $workZip).Length
    [IO.File]::WriteAllLines($workSidecar,[string[]]@(
        ('SHA256={0}' -f $zipHash),
        ('SIZE_BYTES={0}' -f $zipLength),
        ('FILENAME={0}' -f $zipName)
    ),$utf8NoBom)
    [IO.File]::WriteAllLines($workIntegrity,[string[]]@(
        'ZIP_INTEGRITY=PASS',
        'SOURCE_TO_SNAPSHOT_HASH_CORRESPONDENCE=PASS',
        'SNAPSHOT_TO_ZIP_HASH_CORRESPONDENCE=PASS',
        'MANIFEST_TO_ZIP_HASH_CORRESPONDENCE=PASS',
        'ZIP_DECOMPRESSION_HASH_VERIFICATION=PASS',
        'TOCTOU_SOURCE_SET_RECHECK=PASS',
        'DETERMINISTIC_ENTRY_ORDER=ORDINAL',
        'DETERMINISTIC_ENTRY_TIMESTAMP=2000-01-01T00:00:00Z',
        ('ZIP_ENTRY_COUNT={0}' -f $expected.Count),
        ('ZIP_ENTRIES_HASH_VERIFIED={0}' -f $verifiedEntryCount),
        ('ZIP_SHA256={0}' -f $zipHash),
        ('ZIP_SIZE_BYTES={0}' -f $zipLength),
        'DUPLICATE_ENTRY_NAMES=0',
        'UNSAFE_ENTRY_NAMES=0',
        'BITSTREAMS_INCLUDED=0',
        'DCPS_INCLUDED=0',
        'NESTED_ARCHIVES_INCLUDED=0'
    ),$utf8NoBom)

    foreach ($path in $freshOutputPaths) {
        if (Test-Path -LiteralPath $path) { throw "seal output appeared before publication: $path" }
    }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $securityPath)) | Out-Null
    [IO.File]::Copy($stageManifest,$manifestPath,$false); $published.Add($manifestPath)
    [IO.File]::Copy($stageSecurity,$securityPath,$false); $published.Add($securityPath)
    [IO.File]::Copy($workIntegrity,$integrityPath,$false); $published.Add($integrityPath)
    [IO.File]::Copy($workSidecar,$sidecarPath,$false); $published.Add($sidecarPath)
    [IO.File]::Copy($workZip,$zipPath,$false); $published.Add($zipPath)

    if ((Get-Sha256 $zipPath) -cne $zipHash) { throw 'published ZIP hash mismatch' }
    if ((Get-Sha256 $manifestPath) -cne (Get-Sha256 $stageManifest)) { throw 'published manifest hash mismatch' }
    if ((Get-Sha256 $securityPath) -cne (Get-Sha256 $stageSecurity)) { throw 'published security-report hash mismatch' }
    if ((Get-Sha256 $integrityPath) -cne (Get-Sha256 $workIntegrity)) { throw 'published integrity-report hash mismatch' }
    if ((Get-Sha256 $sidecarPath) -cne (Get-Sha256 $workSidecar)) { throw 'published sidecar hash mismatch' }
    $publishedVerified = Assert-ZipAndManifest $zipPath $expected $manifestEntryName
    if ($publishedVerified -ne $verifiedEntryCount) { throw 'published ZIP verification-count mismatch' }

    'EVIDENCE_SEAL=PASS'
    'SECRET_SCAN=PASS'
    'ZIP_INTEGRITY=PASS'
    'SOURCE_TO_ZIP_HASH_CORRESPONDENCE=PASS'
    'EVIDENCE_PACKAGE_SHA256=' + $zipHash
    'EVIDENCE_PACKAGE_SIZE_BYTES=' + $zipLength
    'EVIDENCE_ENTRY_COUNT=' + $expected.Count
} catch {
    foreach ($path in $published) {
        if (Test-Path -LiteralPath $path -PathType Leaf) {
            [IO.File]::Delete((Get-FullPath $path))
        }
    }
    throw
} finally {
    $stageFull = Get-FullPath $stageParent
    if ($stageFull.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $stageFull).StartsWith('control-flow-evidence-stage-',[StringComparison]::Ordinal) -and
        (Test-Path -LiteralPath $stageFull)) {
        [IO.Directory]::Delete($stageFull,$true)
    }
}
