[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.IO.Compression

$sourceSealer = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot 'Seal-R1CEvidence.ps1')).Path
$engine = (Get-Process -Id $PID).Path
$tempPrefix = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
$testParent = [IO.Path]::GetFullPath((Join-Path $tempPrefix ('r1c-seal-tests-' + [Guid]::NewGuid().ToString('N'))))
if (-not $testParent.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'test parent escaped the operating-system temporary directory'
}
[IO.Directory]::CreateDirectory($testParent) | Out-Null
$credentialPath = Join-Path $testParent 'synthetic-credential-baseline.txt'
$secretDirectory = Join-Path $testParent 'synthetic-secret-channel'
[IO.Directory]::CreateDirectory($secretDirectory) | Out-Null

function Write-Utf8([string]$Path,[string]$Content) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllText($Path,$Content,[Text.UTF8Encoding]::new($false))
}

function Write-Bytes([string]$Path,[byte[]]$Content) {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path)) | Out-Null
    [IO.File]::WriteAllBytes($Path,$Content)
}

function Assert-True([bool]$Condition,[string]$Message) {
    if (-not $Condition) { throw "TEST_FAILURE: $Message" }
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Get-StreamSha256([IO.Stream]$Stream) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Stream))).Replace('-','') }
    finally { $sha.Dispose() }
}

$requiredEvidence = @(
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

function Get-SyntheticFinalReport {
    $fixed = [ordered]@{
        TASK = 'V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C'
        R1_EVIDENCE_COMMIT = '5a81f5b115dddcdddd809a655fced115e113585e'
        R1B_EVIDENCE_COMMIT = 'b773cf667fc6f3277e518535a3e070f3f8a59303'
        DIAGNOSTIC_SOURCE_COMMIT = 'f007dc172d43d30b02729755e60382f8ce3dbff4'
        DIAGNOSTIC_SOURCE_TREE = 'b8f87966c8021396acb6341bd2d7d86a10fd7f13'
        DIAGNOSTIC_BIT_SHA256 = 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191'
        DIAGNOSTIC_BUILD_PACKAGE_SHA256 = '918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A'
        FULL_BUILDS = '0'; SYNTHESIS_RUNS = '0'; IMPLEMENTATION_RUNS = '0'; BITSTREAMS_GENERATED = '0'; FPGA_SOURCE_CHANGES = '0'
        BAR_PARSER_LANGUAGE = 'PYTHON3'; BAR_PARSER_USES_INT_BASE_ZERO = 'YES'; BAR_PARSER_BASH_16_HASH_0X_USED = 'NO'
        FORMAL_BIT_SHA256 = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
        ARM_B_ROLE = 'FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE'; FINAL_ACTIVE_IMAGE = 'FORMAL_PHASE2'
        FPGA_PROGRAM_INVOCATIONS = '2'; WARM_REBOOTS = '2'; PROGRAM_RETRIES = '0'; COLD_STARTS = '0'; PHYSICAL_ACTIONS = '0'
        KERNEL_CHANGES_DURING_TASK = '0'; GRUB_WRITES = '0'; PCI_REMOVE_RESCAN_RESETS = '0'; AXI_LITE_WRITES = '0'
        C2H_TRANSFERS = '0'; H2C_TRANSFERS = '0'; PHASE3_RESUMED = 'NO'; XDMA_DEVELOPMENT_CONTINUED = 'NO'
        TAGS = '0'; RELEASES = '0'; FORMAL_REPOSITORY_MUTATIONS = '0'
        OWNER_PROMPT_SHA256 = 'D8F258D95F5543E6AEF592B5A9A5DBDE8F982F4AC87A971D3A7FB38F2259CBB1'
    }
    $dynamic = @(
        'CURRENT_KERNEL_PRE_ARM_A','NEXT_REBOOT_KERNEL_PROVEN','PINNED_MODULE_VERMAGIC','KERNEL_MODULE_COMPATIBILITY_PRE_ARM_A',
        'PROGRAM_OBSERVER_SHA256','PROGRAM_OBSERVER_PARSER_SHA256','PROGRAM_OBSERVER_STATIC_AUDIT','PROGRAM_OBSERVER_FIXTURES',
        'PROGRAM_OBSERVER_PRIOR_REPLAYS','PROGRAM_OBSERVER_POSTPROCESS_APPEND_FIXTURE','BAR_PARSER_FIXTURES','R1B_BAR_ERROR_REPLAY',
        'PRE_ARM_A_BAR0_BYTES','PRE_ARM_A_BAR1_BYTES','PRE_ARM_A_DRIVER_LOAD_REQUIRED','PRE_ARM_A_DRIVER_LOADER_RESULT',
        'ARM_A_PROGRAM','ARM_A_VENDOR_STARTUP_STATUS','ARM_A_DONE','ARM_A_PROGRAM_RESULT','ARM_A_WAIT_SECONDS','ARM_A_BOOT_ID_CHANGED',
        'ARM_A_KERNEL','ARM_A_BAR0_BYTES','ARM_A_BAR1_BYTES','ARM_A_LOADER_COMMAND_PATH_GATE','ARM_A_DRIVER','ARM_A_RUNTIME_GIT_SHA',
        'ARM_A_RUNTIME_BUILD_FLAGS','ARM_A_FORMAL_COMMON_IDENTITY','ARM_A_INIT_DONE','ARM_A_INIT_ERROR','ARM_A_NACK_COUNT',
        'ARM_A_TIMEOUT_COUNT','ARM_A_FIRST_ERROR','ARM_A_VCLK_HZ','ARM_A_SAV_RATE','ARM_A_FRAME_RATE','ARM_A_RESULT',
        'ARM_B_PROGRAM','ARM_B_VENDOR_STARTUP_STATUS','ARM_B_DONE','ARM_B_PROGRAM_RESULT','ARM_B_WAIT_SECONDS','ARM_B_BOOT_ID_CHANGED',
        'ARM_B_KERNEL','ARM_B_BAR0_BYTES','ARM_B_BAR1_BYTES','ARM_B_LOADER_COMMAND_PATH_GATE','ARM_B_DRIVER','ARM_B_FORMAL_IDENTITY',
        'ARM_B_DIAGNOSTIC_MAGIC','ARM_B_INIT_DONE','ARM_B_INIT_ERROR','ARM_B_NACK_COUNT','ARM_B_TIMEOUT_COUNT','ARM_B_FIRST_ERROR',
        'ARM_B_VCLK_HZ','ARM_B_SAV_RATE','ARM_B_FRAME_RATE','ARM_B_RESULT','ARM_B_PAIRED_CONTROL_VALID','PAIRED_AB_RESULT',
        'I2C_25KHZ_DIAGNOSTIC','SLOWER_COMPLETE_I2C_TIMING_PROFILE','SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE',
        'ROOT_CAUSE_SOLELY_PROVEN','READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW','READY_TO_RETURN_TO_XDMA','NEXT_ACTION',
        'FINAL_FORMAL_IDENTITY','FINAL_DIAGNOSTIC_MAGIC','FINAL_PINNED_DRIVER_LOADED','FINAL_DONE',
        'OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS','POST_REBOOT_DRIVER_LOADER_INVOCATIONS','TOTAL_DRIVER_LOADER_INVOCATIONS'
    )
    $lines = [Collections.Generic.List[string]]::new()
    $lines.Add('# Synthetic final report')
    foreach ($pair in $fixed.GetEnumerator()) { $lines.Add(('{0}={1}' -f $pair.Key,$pair.Value)) }
    foreach ($key in $dynamic) { $lines.Add(($key + '=SYNTHETIC_PASS')) }
    $lines.Add('EVIDENCE_PACKAGE_SHA256=NOT_SELF_EMBEDDABLE_SEE_EXTERNAL_SHA256_SIDECAR')
    $lines.Add('EVIDENCE_REPOSITORY_COMMIT=NOT_AVAILABLE_BEFORE_PUBLICATION')
    $lines.Add('PUBLIC_REMOTE_VERIFICATION=NOT_RUN_BEFORE_PUBLICATION')
    $lines.Add('POST_PUBLICATION_RECEIPT=06_FINAL/EVIDENCE_PUBLICATION_RECEIPT.md')
    return ($lines -join "`n") + "`n"
}

function New-Case([string]$Name) {
    $root = Join-Path $testParent ('r1c-seal-test-' + $Name)
    [IO.Directory]::CreateDirectory((Join-Path $root 'scripts')) | Out-Null
    Write-Utf8 (Join-Path $root '.R1C_SEAL_SYNTHETIC_TEST_ROOT') "SYNTHETIC=YES`n"
    [IO.File]::Copy($sourceSealer,(Join-Path $root 'scripts\Seal-R1CEvidence.ps1'),$false)
    foreach ($relative in $requiredEvidence) {
        $path = Join-Path $root ($relative.Replace('/',[IO.Path]::DirectorySeparatorChar))
        if (Test-Path -LiteralPath $path) { continue }
        Write-Utf8 $path "SYNTHETIC_EVIDENCE=PASS`n"
    }
    Write-Utf8 (Join-Path $root '01_ARTIFACT_IDENTITY\NO_BUILD_NO_SOURCE_CHANGE_PROOF.md') @'
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
'@
    Write-Utf8 (Join-Path $root 'OPERATION_LEDGER.md') @'
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FPGA_PROGRAM_INVOCATIONS=2
WARM_REBOOTS=2
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
COLD_STARTS=0
PHYSICAL_ACTIONS=0
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_DONE=1
'@
    Write-Utf8 (Join-Path $root '02_INFRASTRUCTURE_PREFLIGHT\BAR_PARSER_FIXTURE_GATE.md') @'
BAR_PARSER_FIXTURES=PASS_ALL
R1B_BAD_TOKEN_REPLAY=PASS_NO_16_HASH_0X_ERROR
'@
    Write-Utf8 (Join-Path $root '06_FINAL\V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md') (Get-SyntheticFinalReport)
    Write-Utf8 (Join-Path $root '.Xil\transient.txt') "EXCLUDE=YES`n"
    Write-Utf8 (Join-Path $root 'dfx_runtime.txt') "EXCLUDE=YES`n"
    Write-Bytes (Join-Path $root 'external\image.bit') ([byte[]](1,2,3))
    Write-Bytes (Join-Path $root 'external\image.dcp') ([byte[]](4,5,6))
    Write-Bytes (Join-Path $root 'external\unrelated.zip') ([byte[]](80,75,3,4))
    Write-Utf8 (Join-Path $root 'scripts\Invoke-R1CSecretChannel.ps1') (('Invoke-' + 'ContextualPlink') + "`n")
    return $root
}

function Invoke-Seal([string]$Root,[switch]$Mutate) {
    $script = Join-Path $Root 'scripts\Seal-R1CEvidence.ps1'
    $arguments = @('-NoProfile','-NonInteractive','-ExecutionPolicy','Bypass','-File',$script,'-SyntheticTestMode')
    if ($Mutate) { $arguments += '-SyntheticMutateAfterSnapshot' }
    $output = @(& $engine @arguments 2>&1 | ForEach-Object { $_.ToString() })
    return [pscustomobject]@{ ExitCode=$LASTEXITCODE; Output=($output -join [Environment]::NewLine) }
}

function Assert-ZipAndManifest([string]$Root) {
    $zipName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip'
    $archiveRoot = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C'
    $zipPath = Join-Path $Root $zipName
    $manifestPath = Join-Path $Root 'SHA256_MANIFEST.txt'
    $securityPath = Join-Path $Root '06_FINAL\SECURITY_SCAN.txt'
    $integrityPath = Join-Path $Root '06_FINAL\EVIDENCE_ZIP_INTEGRITY.txt'
    foreach ($path in @($zipPath,$manifestPath,$securityPath,$integrityPath,(Join-Path $Root 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE_SHA256.txt'))) {
        Assert-True (Test-Path -LiteralPath $path -PathType Leaf) "missing output $path"
    }
    $archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
    try {
        $entries = @($archive.Entries)
        $names = @($entries | ForEach-Object { $_.FullName })
        Assert-True (($names | Sort-Object -Unique).Count -eq $names.Count) 'duplicate ZIP names'
        foreach ($forbidden in @('.Xil/','dfx_runtime.txt','.bit','.dcp','.zip','Invoke-R1CSecretChannel.ps1')) {
            Assert-True (-not ($names | Where-Object { $_ -like ('*' + $forbidden + '*') })) "excluded artifact leaked: $forbidden"
        }
        foreach ($entry in $entries) {
            Assert-True ($entry.LastWriteTime.DateTime -eq [DateTime]::new(2000,1,1,0,0,0,[DateTimeKind]::Unspecified)) "timestamp not deterministic: $($entry.FullName)"
        }
        $manifestLines = @(Get-Content -LiteralPath $manifestPath)
        foreach ($line in $manifestLines) {
            Assert-True ($line -match '^([0-9A-F]{64})  ([0-9]+)  (.+)$') "malformed manifest: $line"
            $expectedHash = $Matches[1]
            $expectedLength = [Int64]$Matches[2]
            $entryName = $archiveRoot + '/' + $Matches[3]
            $matched = @($entries | Where-Object { $_.FullName -ceq $entryName })
            Assert-True ($matched.Count -eq 1) "manifest entry missing/not unique: $entryName"
            Assert-True ($matched[0].Length -eq $expectedLength) "manifest length mismatch: $entryName"
            $stream = $matched[0].Open()
            try { $actual = Get-StreamSha256 $stream } finally { $stream.Dispose() }
            Assert-True ($actual -ceq $expectedHash) "manifest hash mismatch: $entryName"
        }
        Assert-True ($entries.Count -eq ($manifestLines.Count + 1)) 'ZIP must contain every manifest row plus the manifest itself'
    } finally {
        $archive.Dispose()
    }
    $security = [IO.File]::ReadAllText($securityPath)
    $integrity = [IO.File]::ReadAllText($integrityPath)
    foreach ($token in @('SECRET_SCAN=PASS','TEMP_PASSWORD_FILES_REMAINING=0','ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO','R1C_BUILD_PACKAGE_DUPLICATED=NO','CREDENTIAL_HELPER_SOURCE_INCLUDED=NO')) {
        Assert-True $security.Contains($token,[StringComparison]::Ordinal) "security token absent: $token"
    }
    foreach ($token in @('ZIP_INTEGRITY=PASS','TOCTOU_SOURCE_SET_RECHECK=PASS','DETERMINISTIC_ENTRY_ORDER=ORDINAL')) {
        Assert-True $integrity.Contains($token,[StringComparison]::Ordinal) "integrity token absent: $token"
    }
    return Get-Sha256 $zipPath
}

try {
    Write-Utf8 $credentialPath "SYNTHETIC_OPAQUE_CREDENTIAL_BASELINE`n"
    (Get-Item -LiteralPath $credentialPath).LastWriteTimeUtc = [DateTime]::new(2020,1,1,0,0,0,[DateTimeKind]::Utc)

    $source = [IO.File]::ReadAllText($sourceSealer)
    foreach ($token in @(
        'MEASUREMENT_EVIDENCE.zip','MEASUREMENT_EVIDENCE_SHA256.txt','PREHASH_COPY_POSTHASH_AND_FINAL_SOURCE_SET_REHASH',
        'Write-DeterministicZip','2000-01-01T00:00:00Z','TOCTOU_SOURCE_SET_RECHECK=PASS',
        'R1C_BUILD_PACKAGE_DUPLICATED=NO','EVIDENCE_PUBLICATION_RECEIPT.md',
        'CREDENTIAL_HELPER_SOURCE','TEMP_PASSWORD_FILES_REMAINING=0','ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO'
    )) {
        Assert-True $source.Contains($token,[StringComparison]::Ordinal) "static hardening token absent: $token"
    }
    foreach ($forbiddenCommand in @('git push','git commit','Invoke-WebRequest','Start-Process vivado','program_hw_devices','Compress-Archive')) {
        Assert-True (-not $source.Contains($forbiddenCommand,[StringComparison]::OrdinalIgnoreCase)) "forbidden command present: $forbiddenCommand"
    }
    'STATIC_SEAL_HARDENING_AUDIT=PASS'

    $baselineA = New-Case 'baseline-a'
    $resultA = Invoke-Seal $baselineA
    Assert-True ($resultA.ExitCode -eq 0) "baseline A failed: $($resultA.Output)"
    Assert-True ($resultA.Output -match 'EVIDENCE_SEAL=PASS') 'baseline PASS marker absent'
    $hashA = Assert-ZipAndManifest $baselineA
    'SYNTHETIC_BASELINE=PASS'

    $baselineB = New-Case 'baseline-b'
    $resultB = Invoke-Seal $baselineB
    Assert-True ($resultB.ExitCode -eq 0) "baseline B failed: $($resultB.Output)"
    $hashB = Assert-ZipAndManifest $baselineB
    Assert-True ($hashA -ceq $hashB) "deterministic ZIP hashes differ: $hashA $hashB"
    'SYNTHETIC_DETERMINISTIC_ZIP=PASS'

    $secret = New-Case 'secret-content'
    Write-Utf8 (Join-Path $secret 'raw\payload.txt') (('pass' + 'word=') + 'SyntheticSecretValue!')
    $secretResult = Invoke-Seal $secret
    Assert-True ($secretResult.ExitCode -ne 0 -and $secretResult.Output -match 'security content scan failed') 'secret content was not rejected'
    'SYNTHETIC_SECRET_CONTENT_REJECTION=PASS'

    $private = New-Case 'private-key'
    Write-Utf8 (Join-Path $private 'raw\key.txt') ('-----BEGIN ' + 'OPENSSH PRIVATE KEY-----')
    $privateResult = Invoke-Seal $private
    Assert-True ($privateResult.ExitCode -ne 0 -and $privateResult.Output -match 'security content scan failed') 'private key was not rejected'
    'SYNTHETIC_PRIVATE_KEY_REJECTION=PASS'

    $putty = New-Case 'putty-password'
    Write-Utf8 (Join-Path $putty 'raw\command.txt') ('plink.exe -' + 'pw SecretArgument host')
    $puttyResult = Invoke-Seal $putty
    Assert-True ($puttyResult.ExitCode -ne 0 -and $puttyResult.Output -match 'security content scan failed') 'PuTTY password was not rejected'
    'SYNTHETIC_PUTTY_PASSWORD_REJECTION=PASS'

    $tempPassword = New-Case 'temp-password'
    Write-Utf8 (Join-Path $secretDirectory 'pw-00000000000000000000000000000000.tmp') 'synthetic'
    $tempResult = Invoke-Seal $tempPassword
    Assert-True ($tempResult.ExitCode -ne 0 -and $tempResult.Output -match 'temporary password files remain') 'temporary password file was not rejected'
    [IO.File]::Delete((Join-Path $secretDirectory 'pw-00000000000000000000000000000000.tmp'))
    'SYNTHETIC_TEMP_PASSWORD_REJECTION=PASS'

    $buildZip = New-Case 'build-package'
    Write-Bytes (Join-Path $buildZip 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip') ([byte[]](80,75,3,4))
    $buildResult = Invoke-Seal $buildZip
    Assert-True ($buildResult.ExitCode -ne 0 -and $buildResult.Output -match 'build-package duplicate candidate') 'R1 build package candidate was not rejected'
    'SYNTHETIC_BUILD_PACKAGE_REJECTION=PASS'

    $missing = New-Case 'missing-required'
    [IO.File]::Delete((Join-Path $missing '02_INFRASTRUCTURE_PREFLIGHT\EXACT_LOADER_COMMAND_MANIFEST.md'))
    $missingResult = Invoke-Seal $missing
    Assert-True ($missingResult.ExitCode -ne 0 -and $missingResult.Output -match 'required evidence missing or empty') 'missing evidence was not rejected'
    'SYNTHETIC_REQUIRED_EVIDENCE_REJECTION=PASS'

    $badReport = New-Case 'bad-report'
    $badReportPath = Join-Path $badReport '06_FINAL\V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md'
    $badText = [IO.File]::ReadAllText($badReportPath).Replace('FINAL_DONE=SYNTHETIC_PASS','FINAL_DONE=')
    Write-Utf8 $badReportPath $badText
    $badReportResult = Invoke-Seal $badReport
    Assert-True ($badReportResult.ExitCode -ne 0 -and $badReportResult.Output -match 'required field is empty') 'blank report field was not rejected'
    'SYNTHETIC_REPORT_CONTRACT_REJECTION=PASS'

    $wrongReceipt = New-Case 'wrong-receipt'
    $wrongReportPath = Join-Path $wrongReceipt '06_FINAL\V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md'
    $wrongText = [IO.File]::ReadAllText($wrongReportPath).Replace('EVIDENCE_PUBLICATION_RECEIPT.md','LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md')
    Write-Utf8 $wrongReportPath $wrongText
    $wrongResult = Invoke-Seal $wrongReceipt
    Assert-True ($wrongResult.ExitCode -ne 0 -and $wrongResult.Output -match 'owner-required basename') 'wrong receipt basename was not rejected'
    'SYNTHETIC_RECEIPT_NAME_REJECTION=PASS'

    $toctou = New-Case 'toctou'
    $toctouResult = Invoke-Seal $toctou -Mutate
    Assert-True ($toctouResult.ExitCode -ne 0 -and $toctouResult.Output -match 'eligible source changed after snapshot') 'TOCTOU mutation was not rejected'
    Assert-True (-not (Test-Path -LiteralPath (Join-Path $toctou 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip'))) 'TOCTOU case published ZIP'
    'SYNTHETIC_TOCTOU_REJECTION=PASS'

    $freshness = New-Case 'freshness'
    Write-Bytes (Join-Path $freshness 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip') ([byte[]](1))
    $freshResult = Invoke-Seal $freshness
    Assert-True ($freshResult.ExitCode -ne 0 -and $freshResult.Output -match 'seal output must be fresh') 'stale seal output was not rejected'
    'SYNTHETIC_FRESHNESS_REJECTION=PASS'

    'TEST_SEAL_R1C_EVIDENCE=PASS'
} finally {
    if ((Test-Path -LiteralPath $testParent) -and
        $testParent.StartsWith($tempPrefix,[StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $testParent).StartsWith('r1c-seal-tests-',[StringComparison]::Ordinal)) {
        [IO.Directory]::Delete($testParent,$true)
    }
}
