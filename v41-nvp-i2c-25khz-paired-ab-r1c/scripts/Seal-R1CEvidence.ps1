[CmdletBinding()]
param(
    [switch]$SyntheticTestMode,
    [switch]$SyntheticMutateAfterSnapshot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$taskName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C'
$expectedProductionRoot = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1C'
$archiveRoot = $taskName
$zipName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip'
$sidecarName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE_SHA256.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$securityRelative = '06_FINAL/SECURITY_SCAN.txt'
$integrityRelative = '06_FINAL/EVIDENCE_ZIP_INTEGRITY.txt'
$publicationReceiptName = 'EVIDENCE_PUBLICATION_RECEIPT.md'
$postSealReceiptName = 'POST_SEAL_CLOSURE_RECEIPT.md'
$expectedPromptSha256 = 'D8F258D95F5543E6AEF592B5A9A5DBDE8F982F4AC87A971D3A7FB38F2259CBB1'
$reusedBuildPackageSha256 = '918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A'
$maximumContentScanBytes = 268435456
$fixedZipTimestamp = [DateTimeOffset]::new(2000,1,1,0,0,0,[TimeSpan]::Zero)
$utf8NoBom = [Text.UTF8Encoding]::new($false)

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

$root = Get-FullPath (Split-Path -Parent $PSScriptRoot)
$temporaryRootPrefix = (Get-FullPath ([IO.Path]::GetTempPath())).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar

if ($SyntheticMutateAfterSnapshot -and -not $SyntheticTestMode) {
    throw 'SyntheticMutateAfterSnapshot is forbidden outside SyntheticTestMode'
}

if ($SyntheticTestMode) {
    $testMarker = Join-Path $root '.R1C_SEAL_SYNTHETIC_TEST_ROOT'
    if (-not $root.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase) -or
        -not (Split-Path -Leaf $root).StartsWith('r1c-seal-test-',[StringComparison]::Ordinal) -or
        -not (Test-Path -LiteralPath $testMarker -PathType Leaf)) {
        throw 'synthetic-test root boundary is invalid'
    }
    $credentialPath = Join-Path (Split-Path -Parent $root) 'synthetic-credential-baseline.txt'
    $secretDirectory = Join-Path (Split-Path -Parent $root) 'synthetic-secret-channel'
} else {
    if ($root -cne $expectedProductionRoot) {
        throw "production sealer must run only from $expectedProductionRoot\scripts"
    }
    $credentialPath = 'C:\FPGA\VCDE-DUT-1.txt'
    $secretDirectory = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\R1B_SECRET_CHANNEL'
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
        $relative -match '(^|/)\.\.(/|$)') {
        throw "unsafe relative path: $relative"
    }
    return $relative
}

$zipPath = Join-Path $root $zipName
$sidecarPath = Join-Path $root $sidecarName
$manifestPath = Join-Path $root $manifestName
$securityPath = Join-Path $root ($securityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
$integrityPath = Join-Path $root ($integrityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
$outputPaths = @($manifestPath,$securityPath,$integrityPath,$sidecarPath,$zipPath)

foreach ($fresh in $outputPaths) {
    if (Test-Path -LiteralPath $fresh) {
        throw "seal output must be fresh: $fresh"
    }
}

function Test-ForbiddenSecurityFilename([IO.FileInfo]$File) {
    $name = $File.Name
    if ($name -ieq 'VCDE-DUT-1.txt') { return $true }
    if ($name -match '(?i)^pw-[0-9a-f-]+\.tmp$') { return $true }
    if ($name -match '(?i)^(?:\.env(?:\..+)?|credentials?(?:\..+)?|secrets?(?:\..+)?|passwords?(?:\..+)?|passwd|shadow)$') { return $true }
    if ($name -match '(?i)^(?:id_rsa|id_ed25519)(?:\.pub)?$') { return $true }
    if ($name -match '(?i)^(?:\.netrc|\.npmrc|cookies?\.txt)$') { return $true }
    if ($name -match '(?i)\.(?:pem|p12|pfx|key|kdbx|token|secret|credentials)$') { return $true }
    if ($name -match '(?i)(?:password|passwd|passphrase|token|secret|api[_-]?key)[=:].+') { return $true }
    return $false
}

function Test-CredentialHelperSource([IO.FileInfo]$File) {
    if ($File.Extension -ine '.ps1') { return $false }
    if ($File.Length -gt 4194304) { throw "PowerShell source too large for helper audit: $($File.FullName)" }
    $text = [IO.File]::ReadAllText($File.FullName)
    $tokens = @(
        ('Invoke-' + 'ContextualPlink'),
        ('Send' + 'PasswordToStdin'),
        ('Sudo' + 'PasswordCopies')
    )
    foreach ($token in $tokens) {
        if ($text.Contains($token,[StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
    return $false
}

function Get-ExclusionReason([IO.FileInfo]$File) {
    $relative = Get-Relative $File.FullName
    $segments = @($relative -split '/')
    $leaf = $segments[-1]
    $extension = $File.Extension.ToLowerInvariant()

    if ($leaf -ceq '.R1C_SEAL_SYNTHETIC_TEST_ROOT') { return 'SYNTHETIC_TEST_MARKER' }
    if ($segments | Where-Object { $_ -ieq '.Xil' }) { return 'TRANSIENT_XIL' }
    if ($segments | Where-Object { $_ -in @('.git','.hg','.svn','.worktree','worktrees') }) { return 'VCS_OR_WORKTREE' }
    if ($segments | Where-Object { $_ -in @('FULL_BUILD_EVIDENCE','BUILD_PACKAGE','packages','artifacts') }) { return 'NESTED_BUILD_ARTIFACT_TREE' }
    if ($extension -in @('.bit','.dcp')) { return 'FPGA_BIT_OR_DCP' }
    if ($extension -in @('.zip','.7z','.rar','.tar','.tgz','.gz','.bz2','.xz')) { return 'NESTED_ARCHIVE' }
    if ($leaf -match '(?i)(?:build[_-]?package|full[_-]?build[_-]?evidence)') { return 'NESTED_BUILD_PACKAGE' }
    if ($leaf -ieq 'dfx_runtime.txt') { return 'TRANSIENT_VIVADO_STATE' }
    if ($leaf -ieq $publicationReceiptName) { return 'POST_PUBLICATION_RECEIPT' }
    if ($leaf -ieq $postSealReceiptName) { return 'POST_SEAL_RECEIPT' }
    if ($leaf -in @($zipName,$sidecarName,$manifestName,(Split-Path -Leaf $securityPath),(Split-Path -Leaf $integrityPath))) {
        return 'SEAL_OUTPUT'
    }
    if (Test-CredentialHelperSource $File) { return 'CREDENTIAL_HELPER_SOURCE' }
    return $null
}

function Get-SecretContentFinding([IO.FileInfo]$File) {
    if ($File.Length -gt $maximumContentScanBytes) {
        throw "eligible file exceeds conservative content-scan limit: $($File.FullName)"
    }
    $bytes = [IO.File]::ReadAllBytes($File.FullName)
    $views = [Collections.Generic.List[string]]::new()
    $views.Add([Text.Encoding]::ASCII.GetString($bytes))
    $views.Add([Text.Encoding]::UTF8.GetString($bytes))
    if (($bytes.Length % 2) -eq 0) {
        $views.Add([Text.Encoding]::Unicode.GetString($bytes))
        $views.Add([Text.Encoding]::BigEndianUnicode.GetString($bytes))
    }

    # Assemble signatures so this scanner does not flag its own source.
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

function Get-TaskFilesOrdinal {
    $map = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in @(Get-ChildItem -LiteralPath $root -Force -Recurse -File)) {
        $relative = Get-Relative $file.FullName
        if ($map.ContainsKey($relative)) { throw "case-insensitive duplicate task path: $relative" }
        $map.Add($relative,$file)
    }
    $keys = Get-OrdinalSortedStrings ([string[]]@($map.Keys))
    foreach ($key in $keys) { $map[$key] }
}

function Assert-NoReparsePoints {
    $hits = @(Get-ChildItem -LiteralPath $root -Force -Recurse | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    })
    if ($hits.Count -ne 0) { throw "reparse point present under evidence root; count=$($hits.Count)" }
}

function Get-TemporaryPasswordFileHits {
    $hits = [Collections.Generic.List[string]]::new()
    foreach ($file in @(Get-ChildItem -LiteralPath $root -Force -Recurse -File -Filter 'pw-*.tmp' -ErrorAction SilentlyContinue)) {
        $hits.Add(('TASK_ROOT:' + (Get-Relative $file.FullName)))
    }
    if (Test-Path -LiteralPath $secretDirectory -PathType Container) {
        foreach ($file in @(Get-ChildItem -LiteralPath $secretDirectory -Force -File -Filter 'pw-*.tmp' -ErrorAction SilentlyContinue)) {
            $hits.Add(('SECRET_CHANNEL:' + $file.Name))
        }
    }
    return @($hits)
}

function Assert-RequiredEvidence {
    $required = @(
        '00_SCOPE_AND_PRIOR_EVIDENCE/OWNER_PROMPT_R1C_VERBATIM.md',
        '00_SCOPE_AND_PRIOR_EVIDENCE/PRIOR_EVIDENCE_IDENTITIES.txt',
        '00_SCOPE_AND_PRIOR_EVIDENCE/R1_R1B_IMMUTABLE_CONTEXT.md',
        '00_SCOPE_AND_PRIOR_EVIDENCE/R1B_ACCEPTED_OBSERVER_EVIDENCE/PRIOR_LOG_REPLAY_POSTFIX.txt',
        '00_SCOPE_AND_PRIOR_EVIDENCE/R1B_ACCEPTED_OBSERVER_EVIDENCE/PROGRAM_OBSERVER_FIXTURE_RESULTS_POSTFIX.csv',
        '00_SCOPE_AND_PRIOR_EVIDENCE/R1B_ACCEPTED_OBSERVER_EVIDENCE/PROGRAM_OBSERVER_STATIC_AUDIT_POSTFIX.txt',
        '01_ARTIFACT_IDENTITY/ARTIFACT_IDENTITY.md',
        '01_ARTIFACT_IDENTITY/ARTIFACT_SHA256.txt',
        '01_ARTIFACT_IDENTITY/NO_BUILD_NO_SOURCE_CHANGE_PROOF.md',
        '02_INFRASTRUCTURE_PREFLIGHT/PROGRAM_OBSERVER/PROGRAM_OBSERVER_OFFLINE_GATE.md',
        '02_INFRASTRUCTURE_PREFLIGHT/PROGRAM_OBSERVER/PROGRAM_OBSERVER_FIXTURE_RESULTS.csv',
        '02_INFRASTRUCTURE_PREFLIGHT/PROGRAM_OBSERVER/PROGRAM_OBSERVER_STATIC_AUDIT.txt',
        '02_INFRASTRUCTURE_PREFLIGHT/PROGRAM_OBSERVER/PRIOR_R1_PROGRAM_REPLAY.txt',
        '02_INFRASTRUCTURE_PREFLIGHT/PROGRAM_OBSERVER/PRIOR_R1B_PROGRAM_REPLAY.txt',
        '02_INFRASTRUCTURE_PREFLIGHT/BAR_PARSER_FIXTURE_GATE.md',
        '02_INFRASTRUCTURE_PREFLIGHT/BAR_PARSER_FIXTURE_RESULTS.csv',
        '02_INFRASTRUCTURE_PREFLIGHT/KERNEL_AND_BOOT_SELECTION_GATE.md',
        '02_INFRASTRUCTURE_PREFLIGHT/KERNEL_AND_BOOT_RAW.log',
        '02_INFRASTRUCTURE_PREFLIGHT/EXACT_LOADER_COMMAND_MANIFEST.md',
        '02_INFRASTRUCTURE_PREFLIGHT/FORMAL_START_STATE_GATE.md',
        '02_INFRASTRUCTURE_PREFLIGHT/FORMAL_START_TELEMETRY_RAW.log',
        '02_INFRASTRUCTURE_PREFLIGHT/PRE_ARM_A_FINAL_JTAG_DONE.log',
        '03_ARM_A_25KHZ/ARM_A_PROGRAM_SUPERVISOR.log',
        '03_ARM_A_25KHZ/ARM_A_REBOOT_SUBMISSION.log',
        '03_ARM_A_25KHZ/ARM_A_REBOOT_MONITOR.log',
        '03_ARM_A_25KHZ/ARM_A_POST_REBOOT_PRELOADER_RAW.log',
        '03_ARM_A_25KHZ/ARM_A_DRIVER_LOADER_RAW.log',
        '03_ARM_A_25KHZ/ARM_A_TELEMETRY_RAW.log',
        '03_ARM_A_25KHZ/ARM_A_TELEMETRY_PARSED.txt',
        '03_ARM_A_25KHZ/ARM_A_FINAL_JTAG_DONE.log',
        '03_ARM_A_25KHZ/ARM_A_CLASSIFICATION.md',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_PROGRAM_SUPERVISOR.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_REBOOT_SUBMISSION.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_REBOOT_MONITOR.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_POST_REBOOT_PRELOADER_RAW.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_DRIVER_LOADER_RAW.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_TELEMETRY_RAW.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_TELEMETRY_PARSED.txt',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_FINAL_JTAG_DONE.log',
        '04_ARM_B_FORMAL_50KHZ/ARM_B_CLASSIFICATION.md',
        '05_COMPARISON/PAIRED_AB_SUMMARY.csv',
        '05_COMPARISON/PAIRED_AB_CLASSIFICATION.md',
        '06_FINAL/FINAL_LOCAL_PROCESS_ZERO_GATE.txt',
        '06_FINAL/V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md',
        'fixtures/r1b_bad_token_replay.resource',
        'scripts/parse_pci_bars.py',
        'scripts/test_parse_pci_bars.py',
        'scripts/program_once_startup_high_done.tcl',
        'scripts/Run-ProgramOnceStartupHighDone.ps1',
        'scripts/ProgramObserverCommon.ps1',
        'scripts/Test-ProgramObserverFixtures.ps1',
        'scripts/Test-ProgramObserverLog.ps1',
        'scripts/Test-ProgramObserverStatic.ps1',
        'OPERATION_LEDGER.md',
        'TIME_LEDGER.md'
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
    $reportPath = Join-Path $root '06_FINAL\V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md'
    $lines = [IO.File]::ReadAllLines($reportPath)
    $fixed = [ordered]@{
        TASK = 'V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C'
        R1_EVIDENCE_COMMIT = '5a81f5b115dddcdddd809a655fced115e113585e'
        R1B_EVIDENCE_COMMIT = 'b773cf667fc6f3277e518535a3e070f3f8a59303'
        DIAGNOSTIC_SOURCE_COMMIT = 'f007dc172d43d30b02729755e60382f8ce3dbff4'
        DIAGNOSTIC_SOURCE_TREE = 'b8f87966c8021396acb6341bd2d7d86a10fd7f13'
        DIAGNOSTIC_BIT_SHA256 = 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191'
        DIAGNOSTIC_BUILD_PACKAGE_SHA256 = $reusedBuildPackageSha256
        FULL_BUILDS = '0'
        SYNTHESIS_RUNS = '0'
        IMPLEMENTATION_RUNS = '0'
        BITSTREAMS_GENERATED = '0'
        FPGA_SOURCE_CHANGES = '0'
        BAR_PARSER_LANGUAGE = 'PYTHON3'
        BAR_PARSER_USES_INT_BASE_ZERO = 'YES'
        BAR_PARSER_BASH_16_HASH_0X_USED = 'NO'
        FORMAL_BIT_SHA256 = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
        ARM_B_ROLE = 'FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE'
        FINAL_ACTIVE_IMAGE = 'FORMAL_PHASE2'
        FPGA_PROGRAM_INVOCATIONS = '2'
        WARM_REBOOTS = '2'
        PROGRAM_RETRIES = '0'
        COLD_STARTS = '0'
        PHYSICAL_ACTIONS = '0'
        KERNEL_CHANGES_DURING_TASK = '0'
        GRUB_WRITES = '0'
        PCI_REMOVE_RESCAN_RESETS = '0'
        AXI_LITE_WRITES = '0'
        C2H_TRANSFERS = '0'
        H2C_TRANSFERS = '0'
        PHASE3_RESUMED = 'NO'
        XDMA_DEVELOPMENT_CONTINUED = 'NO'
        TAGS = '0'
        RELEASES = '0'
        FORMAL_REPOSITORY_MUTATIONS = '0'
        OWNER_PROMPT_SHA256 = $expectedPromptSha256
    }
    foreach ($pair in $fixed.GetEnumerator()) {
        $actual = Get-ReportField $lines ([string]$pair.Key)
        if ($actual -cne [string]$pair.Value) {
            throw "final-report fixed field mismatch: $($pair.Key) expected=$($pair.Value) actual=$actual"
        }
    }
    $requiredNonempty = @(
        'CURRENT_KERNEL_PRE_ARM_A','NEXT_REBOOT_KERNEL_PROVEN','PINNED_MODULE_VERMAGIC',
        'KERNEL_MODULE_COMPATIBILITY_PRE_ARM_A','PROGRAM_OBSERVER_SHA256','PROGRAM_OBSERVER_PARSER_SHA256',
        'PROGRAM_OBSERVER_STATIC_AUDIT','PROGRAM_OBSERVER_FIXTURES','PROGRAM_OBSERVER_PRIOR_REPLAYS',
        'PROGRAM_OBSERVER_POSTPROCESS_APPEND_FIXTURE','BAR_PARSER_FIXTURES','R1B_BAR_ERROR_REPLAY',
        'PRE_ARM_A_BAR0_BYTES','PRE_ARM_A_BAR1_BYTES','PRE_ARM_A_DRIVER_LOAD_REQUIRED',
        'PRE_ARM_A_DRIVER_LOADER_RESULT','ARM_A_PROGRAM','ARM_A_VENDOR_STARTUP_STATUS','ARM_A_DONE',
        'ARM_A_PROGRAM_RESULT','ARM_A_WAIT_SECONDS','ARM_A_BOOT_ID_CHANGED','ARM_A_KERNEL',
        'ARM_A_BAR0_BYTES','ARM_A_BAR1_BYTES','ARM_A_LOADER_COMMAND_PATH_GATE','ARM_A_DRIVER',
        'ARM_A_RUNTIME_GIT_SHA','ARM_A_RUNTIME_BUILD_FLAGS','ARM_A_FORMAL_COMMON_IDENTITY',
        'ARM_A_INIT_DONE','ARM_A_INIT_ERROR','ARM_A_NACK_COUNT','ARM_A_TIMEOUT_COUNT','ARM_A_FIRST_ERROR',
        'ARM_A_VCLK_HZ','ARM_A_SAV_RATE','ARM_A_FRAME_RATE','ARM_A_RESULT','ARM_B_PROGRAM',
        'ARM_B_VENDOR_STARTUP_STATUS','ARM_B_DONE','ARM_B_PROGRAM_RESULT','ARM_B_WAIT_SECONDS',
        'ARM_B_BOOT_ID_CHANGED','ARM_B_KERNEL','ARM_B_BAR0_BYTES','ARM_B_BAR1_BYTES',
        'ARM_B_LOADER_COMMAND_PATH_GATE','ARM_B_DRIVER','ARM_B_FORMAL_IDENTITY','ARM_B_DIAGNOSTIC_MAGIC',
        'ARM_B_INIT_DONE','ARM_B_INIT_ERROR','ARM_B_NACK_COUNT','ARM_B_TIMEOUT_COUNT','ARM_B_FIRST_ERROR',
        'ARM_B_VCLK_HZ','ARM_B_SAV_RATE','ARM_B_FRAME_RATE','ARM_B_RESULT','ARM_B_PAIRED_CONTROL_VALID',
        'PAIRED_AB_RESULT','I2C_25KHZ_DIAGNOSTIC','SLOWER_COMPLETE_I2C_TIMING_PROFILE',
        'SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE','ROOT_CAUSE_SOLELY_PROVEN',
        'READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW','READY_TO_RETURN_TO_XDMA','NEXT_ACTION',
        'FINAL_FORMAL_IDENTITY','FINAL_DIAGNOSTIC_MAGIC','FINAL_PINNED_DRIVER_LOADED','FINAL_DONE',
        'OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS','POST_REBOOT_DRIVER_LOADER_INVOCATIONS',
        'TOTAL_DRIVER_LOADER_INVOCATIONS','EVIDENCE_REPOSITORY_COMMIT','PUBLIC_REMOTE_VERIFICATION'
    )
    foreach ($key in $requiredNonempty) {
        if ([string]::IsNullOrWhiteSpace((Get-ReportField $lines $key))) {
            throw "final-report required field is empty: $key"
        }
    }
    $packageValue = Get-ReportField $lines 'EVIDENCE_PACKAGE_SHA256'
    if ($packageValue -notmatch '^NOT_SELF_EMBEDDABLE.*SHA256_SIDECAR$') {
        throw 'final report must record the ZIP-hash self-reference limitation and point to the SHA256 sidecar'
    }
    $reportText = [IO.File]::ReadAllText($reportPath)
    if ($reportText.Contains('LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md',[StringComparison]::Ordinal)) {
        throw 'final report names LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md, but the owner-required basename is EVIDENCE_PUBLICATION_RECEIPT.md'
    }
    if (-not $reportText.Contains('EVIDENCE_PUBLICATION_RECEIPT.md',[StringComparison]::Ordinal)) {
        throw 'final report does not name the owner-required post-publication receipt'
    }
}

function Assert-ExactText([string]$Relative,[string[]]$Tokens) {
    $path = Join-Path $root ($Relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
    $text = [IO.File]::ReadAllText($path)
    foreach ($token in $Tokens) {
        if (-not $text.Contains($token,[StringComparison]::Ordinal)) {
            throw "required evidence token absent: $Relative :: $token"
        }
    }
}

function Copy-StableSnapshotFile([IO.FileInfo]$Source,[string]$Destination) {
    $before = Get-Item -LiteralPath $Source.FullName
    $beforeLength = $before.Length
    $beforeWriteTicks = $before.LastWriteTimeUtc.Ticks
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
        $names = Get-OrdinalSortedStrings ([string[]]@($Expected.Keys))
        foreach ($entryName in $names) {
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

function Assert-Zip([string]$Path,[Collections.Generic.Dictionary[string,object]]$Expected) {
    $verified = 0
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $archive = [IO.Compression.ZipFile]::OpenRead($Path)
    try {
        if ($archive.Entries.Count -ne $Expected.Count) { throw 'ZIP entry-count mismatch' }
        foreach ($entry in $archive.Entries) {
            if (-not $seen.Add($entry.FullName)) { throw "duplicate ZIP entry: $($entry.FullName)" }
            if ($entry.FullName.EndsWith('/') -or $entry.FullName.StartsWith('/') -or $entry.FullName -match '(^|/)\.\.(/|$)') {
                throw "unsafe ZIP entry: $($entry.FullName)"
            }
            if (-not $Expected.ContainsKey($entry.FullName)) { throw "unexpected ZIP entry: $($entry.FullName)" }
            # ZIP stores a DOS local wall-clock timestamp without a timezone.
            # Compare the encoded wall-clock fields, not the workstation UTC offset.
            if ($entry.LastWriteTime.DateTime -ne $fixedZipTimestamp.DateTime) {
                throw "non-deterministic ZIP entry timestamp: $($entry.FullName)"
            }
            $record = $Expected[$entry.FullName]
            if ($entry.Length -ne $record.Length) { throw "ZIP length mismatch: $($entry.FullName)" }
            $stream = $entry.Open()
            try { $actualHash = Get-StreamSha256 $stream } finally { $stream.Dispose() }
            if ($actualHash -cne $record.Hash) { throw "ZIP hash mismatch: $($entry.FullName)" }
            if ($actualHash -ceq $reusedBuildPackageSha256) { throw 'R1 build package duplicated inside measurement ZIP' }
            if ($entry.FullName -match '(?i)\.(?:bit|dcp|zip|7z|rar|tar|tgz|gz|bz2|xz)$') {
                throw "forbidden binary/build/archive entry: $($entry.FullName)"
            }
            $verified++
        }
    } finally {
        $archive.Dispose()
    }
    if ($verified -ne $Expected.Count -or $seen.Count -ne $Expected.Count) { throw 'ZIP verification-count mismatch' }
    return $verified
}

Assert-NoReparsePoints
Assert-RequiredEvidence
Assert-FinalReportContract

$promptPath = Join-Path $root '00_SCOPE_AND_PRIOR_EVIDENCE\OWNER_PROMPT_R1C_VERBATIM.md'
if (-not $SyntheticTestMode -and (Get-Sha256 $promptPath) -cne $expectedPromptSha256) {
    throw 'owner prompt SHA256 mismatch'
}

Assert-ExactText '01_ARTIFACT_IDENTITY/NO_BUILD_NO_SOURCE_CHANGE_PROOF.md' @(
    'FULL_BUILDS=0','SYNTHESIS_RUNS=0','IMPLEMENTATION_RUNS=0','BITSTREAMS_GENERATED=0',
    'FPGA_SOURCE_CHANGES=0','FORMAL_REPOSITORY_MUTATIONS=0'
)
Assert-ExactText 'OPERATION_LEDGER.md' @(
    'FULL_BUILDS=0','SYNTHESIS_RUNS=0','IMPLEMENTATION_RUNS=0','BITSTREAMS_GENERATED=0',
    'FPGA_SOURCE_CHANGES=0','FPGA_PROGRAM_INVOCATIONS=2','WARM_REBOOTS=2','PROGRAM_RETRIES=0',
    'AXI_LITE_WRITES=0','C2H_TRANSFERS=0','H2C_TRANSFERS=0','COLD_STARTS=0','PHYSICAL_ACTIONS=0',
    'FINAL_ACTIVE_IMAGE=FORMAL_PHASE2','FINAL_DONE=1'
)
Assert-ExactText '02_INFRASTRUCTURE_PREFLIGHT/BAR_PARSER_FIXTURE_GATE.md' @(
    'BAR_PARSER_FIXTURES=PASS_ALL','R1B_BAD_TOKEN_REPLAY=PASS_NO_16_HASH_0X_ERROR'
)

if (-not (Test-Path -LiteralPath $credentialPath -PathType Leaf)) { throw 'original credential file unavailable for integrity proof' }
$credentialBefore = Get-Item -LiteralPath $credentialPath
$credentialBeforeHash = Get-Sha256 $credentialPath
$promptItem = Get-Item -LiteralPath $promptPath
$promptBoundaryTicks = [Math]::Min($promptItem.CreationTimeUtc.Ticks,$promptItem.LastWriteTimeUtc.Ticks)
if ($credentialBefore.LastWriteTimeUtc.Ticks -ge $promptBoundaryTicks) {
    throw 'credential last-write time does not predate the preserved owner prompt'
}

$initialPasswordHits = @(Get-TemporaryPasswordFileHits)
if ($initialPasswordHits.Count -ne 0) { throw "temporary password files remain; count=$($initialPasswordHits.Count)" }

$allFiles = @(Get-TaskFilesOrdinal)
$forbiddenNameHits = @($allFiles | Where-Object { Test-ForbiddenSecurityFilename $_ })
if ($forbiddenNameHits.Count -ne 0) { throw "forbidden credential/secret filename under evidence root; count=$($forbiddenNameHits.Count)" }

$includedFiles = [Collections.Generic.List[IO.FileInfo]]::new()
$excluded = [Collections.Generic.List[object]]::new()
foreach ($file in $allFiles) {
    $relative = Get-Relative $file.FullName
    $isBuildPackageNamed = $file.Name -match '(?i)(?:V41_NVP_I2C_25KHZ.*BUILD.*PACKAGE|R1.*BUILD.*PACKAGE)'
    if ($isBuildPackageNamed) { throw "R1 build-package duplicate candidate present: $relative" }
    $reason = Get-ExclusionReason $file
    if ($null -ne $reason) {
        $excluded.Add([pscustomobject]@{ Relative = $relative; Reason = $reason })
    } else {
        $includedFiles.Add($file)
    }
}
if ($includedFiles.Count -eq 0) { throw 'no eligible evidence files found' }

$secretContentHits = [Collections.Generic.List[object]]::new()
foreach ($file in $includedFiles) {
    $finding = Get-SecretContentFinding $file
    if ($null -ne $finding) {
        $secretContentHits.Add([pscustomobject]@{ Relative = Get-Relative $file.FullName; Finding = $finding })
    }
}
if ($secretContentHits.Count -ne 0) {
    $findingText = @($secretContentHits | ForEach-Object { '{0}:{1}' -f $_.Relative,$_.Finding }) -join ', '
    throw "security content scan failed: $findingText"
}

$stageParent = Get-FullPath (Join-Path $temporaryRootPrefix ('r1c-evidence-stage-' + [Guid]::NewGuid().ToString('N')))
if (-not $stageParent.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'temporary staging escaped the operating-system temporary root'
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
        if ($record.Hash -ceq $reusedBuildPackageSha256) { throw "R1 build package duplicated as eligible evidence: $relative" }
        if ($snapshotRecords.ContainsKey($relative)) { throw "duplicate snapshot path: $relative" }
        $snapshotRecords.Add($relative,$record)
    }

    if ($SyntheticMutateAfterSnapshot) {
        [IO.File]::AppendAllText(
            (Join-Path $root '06_FINAL\V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md'),
            "`nSYNTHETIC_TOCTOU_MUTATION=YES`n",
            $utf8NoBom
        )
    }

    Assert-NoReparsePoints
    $snapshotSecretHits = [Collections.Generic.List[object]]::new()
    foreach ($relative in (Get-OrdinalSortedStrings ([string[]]@($snapshotRecords.Keys)))) {
        $record = $snapshotRecords[$relative]
        $stageFile = Get-Item -LiteralPath $record.StagePath
        $finding = Get-SecretContentFinding $stageFile
        if ($null -ne $finding) { $snapshotSecretHits.Add([pscustomobject]@{ Relative=$relative; Finding=$finding }) }
    }
    if ($snapshotSecretHits.Count -ne 0) { throw "staged snapshot security scan failed; count=$($snapshotSecretHits.Count)" }

    $excludedByReason = @($excluded | Group-Object Reason | Sort-Object Name)
    $securityLines = [Collections.Generic.List[string]]::new()
    foreach ($line in @(
        'SECRET_SCAN=PASS',
        'TEMP_PASSWORD_FILES_REMAINING=0',
        'ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO',
        'ORIGINAL_CREDENTIAL_PROOF=LASTWRITE_PREDATES_OWNER_PROMPT_AND_HASH_LENGTH_LASTWRITE_STABLE_DURING_SEAL',
        'ORIGINAL_CREDENTIAL_CONTENT_OR_HASH_PUBLISHED=NO',
        'SNAPSHOT_METHOD=PREHASH_COPY_POSTHASH_AND_FINAL_SOURCE_SET_REHASH',
        'ZIP_SOURCE=IMMUTABLE_OS_TEMP_STAGED_SNAPSHOT',
        'ZIP_ENTRY_ORDER=ORDINAL',
        'ZIP_ENTRY_TIMESTAMP=2000-01-01T00:00:00Z',
        'MANIFEST_SOURCE=EXACT_STAGED_SNAPSHOT_BYTES',
        'MANIFEST_SELF_INCLUDED=NO_SELF_REFERENCE',
        ('FILES_DISCOVERED={0}' -f $allFiles.Count),
        ('FILES_INCLUDED={0}' -f $includedFiles.Count),
        ('FILES_EXCLUDED={0}' -f $excluded.Count),
        ('SOURCE_FILES_CONTENT_SCANNED={0}' -f $includedFiles.Count),
        ('SNAPSHOT_FILES_CONTENT_SCANNED={0}' -f $snapshotRecords.Count),
        'FORBIDDEN_FILENAME_HITS=0',
        'SECRET_CONTENT_PATTERN_HITS=0',
        'SNAPSHOT_SECRET_CONTENT_PATTERN_HITS=0',
        'REPARSE_POINT_COUNT=0',
        'CREDENTIAL_FILE_INCLUDED=NO',
        'CREDENTIAL_HELPER_SOURCE_INCLUDED=NO',
        'TEMPORARY_PWFILE_INCLUDED=NO',
        'PRIVATE_KEY_INCLUDED=NO',
        'STANDALONE_BITSTREAM_INCLUDED=NO',
        'STANDALONE_DCP_INCLUDED=NO',
        'NESTED_ARCHIVE_INCLUDED=NO',
        'GIT_OR_WORKTREE_INCLUDED=NO',
        'R1C_BUILD_PACKAGE_DUPLICATED=NO',
        ('R1C_REUSES_R1_BUILD_PACKAGE_SHA256={0}' -f $reusedBuildPackageSha256)
    )) { $securityLines.Add($line) }
    foreach ($group in $excludedByReason) { $securityLines.Add(('EXCLUDED_{0}_COUNT={1}' -f $group.Name,$group.Count)) }
    foreach ($item in ($excluded | Sort-Object Relative)) {
        $securityLines.Add(('EXCLUDED_FILE={0}|REASON={1}' -f $item.Relative,$item.Reason))
    }

    $stageSecurity = Join-Path $stageRoot ($securityRelative.Replace('/',[IO.Path]::DirectorySeparatorChar))
    [IO.Directory]::CreateDirectory((Split-Path -Parent $stageSecurity)) | Out-Null
    [IO.File]::WriteAllLines($stageSecurity,[string[]]$securityLines,$utf8NoBom)

    $stageManifest = Join-Path $stageRoot $manifestName
    $manifestFiles = @(Get-ChildItem -LiteralPath $stageRoot -Force -Recurse -File | Where-Object {
        (Get-FullPath $_.FullName) -cne (Get-FullPath $stageManifest)
    })
    $manifestMap = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $manifestFiles) {
        $relative = $file.FullName.Substring($stageRoot.Length).TrimStart('\','/').Replace('\','/')
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
        if ($entryName.StartsWith('/') -or $entryName -match '(^|/)\.\.(/|$)') { throw "unsafe staged entry: $entryName" }
        if ($expected.ContainsKey($entryName)) { throw "duplicate staged entry: $entryName" }
        $hash = Get-Sha256 $file.FullName
        if ($hash -ceq $reusedBuildPackageSha256) { throw "R1 build package duplicated in staged snapshot: $relative" }
        $expected.Add($entryName,[pscustomobject]@{ Hash=$hash; Length=[Int64]$file.Length; StagePath=$file.FullName })
    }

    Write-DeterministicZip $workZip $expected
    $verified = Assert-Zip $workZip $expected

    # Fail closed if the evidence root changed after the immutable snapshot.
    Assert-NoReparsePoints
    $currentPasswordHits = @(Get-TemporaryPasswordFileHits)
    if ($currentPasswordHits.Count -ne 0) { throw "temporary password file appeared during seal; count=$($currentPasswordHits.Count)" }
    $currentFiles = @(Get-TaskFilesOrdinal)
    $currentEligible = [Collections.Generic.Dictionary[string,IO.FileInfo]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($file in $currentFiles) {
        if (Test-ForbiddenSecurityFilename $file) { throw "forbidden filename appeared during seal: $(Get-Relative $file.FullName)" }
        if ($null -eq (Get-ExclusionReason $file)) {
            $relative = Get-Relative $file.FullName
            if ($currentEligible.ContainsKey($relative)) { throw "duplicate final eligible path: $relative" }
            $currentEligible.Add($relative,$file)
        }
    }
    if ($currentEligible.Count -ne $snapshotRecords.Count) { throw 'eligible source-set count changed after snapshot' }
    foreach ($relative in (Get-OrdinalSortedStrings ([string[]]@($snapshotRecords.Keys)))) {
        if (-not $currentEligible.ContainsKey($relative)) { throw "eligible source path disappeared after snapshot: $relative" }
        $current = Get-Item -LiteralPath $currentEligible[$relative].FullName
        $record = $snapshotRecords[$relative]
        if ($current.Length -ne $record.Length -or
            $current.LastWriteTimeUtc.Ticks -ne $record.LastWriteTicks -or
            (Get-Sha256 $current.FullName) -cne $record.Hash) {
            throw "eligible source changed after snapshot: $relative"
        }
    }

    $credentialAfter = Get-Item -LiteralPath $credentialPath
    if ($credentialAfter.Length -ne $credentialBefore.Length -or
        $credentialAfter.LastWriteTimeUtc.Ticks -ne $credentialBefore.LastWriteTimeUtc.Ticks -or
        (Get-Sha256 $credentialPath) -cne $credentialBeforeHash) {
        throw 'original credential file changed during seal'
    }

    foreach ($entryName in (Get-OrdinalSortedStrings ([string[]]@($expected.Keys)))) {
        $record = $expected[$entryName]
        if ((Get-Sha256 $record.StagePath) -cne $record.Hash -or
            (Get-Item -LiteralPath $record.StagePath).Length -ne $record.Length) {
            throw "staged snapshot changed after ZIP verification: $entryName"
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
        'ZIP_SOURCE=EXACT_IMMUTABLE_STAGED_SNAPSHOT',
        'ZIP_DECOMPRESSION_HASH_VERIFICATION=PASS',
        'TOCTOU_SOURCE_SET_RECHECK=PASS',
        'SOURCE_AND_SNAPSHOT_HASH_STABILITY=PASS',
        'DETERMINISTIC_ENTRY_ORDER=ORDINAL',
        'DETERMINISTIC_ENTRY_TIMESTAMP=2000-01-01T00:00:00Z',
        ('ZIP_ENTRY_COUNT={0}' -f $expected.Count),
        ('ZIP_ENTRIES_HASH_VERIFIED={0}' -f $verified),
        ('ZIP_SHA256={0}' -f $zipHash),
        ('ZIP_SIZE_BYTES={0}' -f $zipLength),
        'DUPLICATE_ENTRY_NAMES=0',
        'UNEXPECTED_ENTRY_NAMES=0',
        'UNSAFE_ENTRY_NAMES=0',
        'R1C_BUILD_PACKAGE_DUPLICATED=NO',
        ('R1C_REUSES_R1_BUILD_PACKAGE_SHA256={0}' -f $reusedBuildPackageSha256)
    ),$utf8NoBom)

    foreach ($fresh in $outputPaths) {
        if (Test-Path -LiteralPath $fresh) { throw "seal output appeared before atomic publication: $fresh" }
    }
    [IO.Directory]::CreateDirectory((Split-Path -Parent $securityPath)) | Out-Null
    [IO.File]::Copy($stageManifest,$manifestPath,$false); $published.Add($manifestPath)
    [IO.File]::Copy($stageSecurity,$securityPath,$false); $published.Add($securityPath)
    [IO.File]::Copy($workIntegrity,$integrityPath,$false); $published.Add($integrityPath)
    [IO.File]::Copy($workSidecar,$sidecarPath,$false); $published.Add($sidecarPath)
    [IO.File]::Copy($workZip,$zipPath,$false); $published.Add($zipPath)

    if ((Get-Sha256 $zipPath) -cne $zipHash) { throw 'published ZIP hash mismatch' }
    if ((Get-Sha256 $manifestPath) -cne (Get-Sha256 $stageManifest)) { throw 'published manifest hash mismatch' }
    if ((Get-Sha256 $securityPath) -cne (Get-Sha256 $stageSecurity)) { throw 'published security report hash mismatch' }
    if ((Get-Sha256 $integrityPath) -cne (Get-Sha256 $workIntegrity)) { throw 'published integrity report hash mismatch' }
    if ((Get-Sha256 $sidecarPath) -cne (Get-Sha256 $workSidecar)) { throw 'published sidecar hash mismatch' }
    $finalVerified = Assert-Zip $zipPath $expected
    if ($finalVerified -ne $verified) { throw 'published ZIP verification-count mismatch' }

    'EVIDENCE_SEAL=PASS'
    'SECRET_SCAN=PASS'
    'ZIP_INTEGRITY=PASS'
    'TEMP_PASSWORD_FILES_REMAINING=0'
    'ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO'
    'R1C_BUILD_PACKAGE_DUPLICATED=NO'
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
    $stageParentFull = Get-FullPath $stageParent
    if ($stageParentFull.StartsWith($temporaryRootPrefix,[StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $stageParentFull).StartsWith('r1c-evidence-stage-',[StringComparison]::Ordinal) -and
        (Test-Path -LiteralPath $stageParentFull)) {
        [IO.Directory]::Delete($stageParentFull,$true)
    }
}
