[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:R1hTaskRoot = 'C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE'
$script:R1hToolRoot = Join-Path $script:R1hTaskRoot '09_HOST_TOOLS'
$script:R1hPrecheckRoot = Join-Path $script:R1hTaskRoot '10_HARDWARE_PRECHECK'
$script:R7TaskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$script:R6TaskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$script:R1hCanonicalTarget = 'Xilinx/80802026a98b01'
$script:R1hCanonicalSuffix = '/Xilinx/80802026a98b01'
$script:R1hExpectedPart = 'xc7a35t'
$script:R1hExpectedIdcode = '0362D093'
$script:R1hMaximumPrograms = 7
$script:R1hMaximumWarmReboots = 7
$script:R1hMaximumDriverLoads = 7

$script:R1hAcceptedTools = [ordered]@{
    ModeAwareObserverTcl = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\program_once_mode_aware.tcl'
        Bytes = 11334L
        Sha256 = '55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7'
    }
    ProgramObserverParser = [pscustomobject]@{
        Path = Join-Path $script:R6TaskRoot 'scripts\ProgramObserverCommon.ps1'
        Bytes = 5102L
        Sha256 = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
    }
    SelectedTargetSelector = [pscustomobject]@{
        Path = Join-Path $script:R6TaskRoot 'scripts\select_r6_jtag_target.tcl'
        Bytes = 5676L
        Sha256 = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
    }
    IndependentDoneTcl = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\read_jtag_identity_done_r7_selected.tcl'
        Bytes = 3527L
        Sha256 = '122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B'
    }
    JtagReconfirmationTcl = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\r7_jtag_reconfirmation_session.tcl'
        Bytes = 6368L
        Sha256 = '6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73'
    }
    ContextualPlink = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\Invoke-ContextualPlink.ps1'
        Bytes = 10952L
        Sha256 = '5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9'
    }
    BarParser = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\parse_pci_bars.py'
        Bytes = 3380L
        Sha256 = '5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922'
    }
    PreLoaderValidator = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\r7_post_reboot_preloader_readonly.sh'
        Bytes = 7419L
        Sha256 = '21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D'
    }
    PreBootstrapSafetyPayload = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\r7_prebootstrap_safety_readonly.sh'
        Bytes = 13540L
        Sha256 = 'FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45'
    }
    HostBaselinePayload = [pscustomobject]@{
        Path = Join-Path $script:R7TaskRoot 'scripts\r7_host_baseline_sample_readonly.sh'
        Bytes = 3717L
        Sha256 = '0C49C3FB9192E40F53285844343BAA7AC6EE1801798C62627A6C45EAC718D730'
    }
    RuntimeProvenancePayload = [pscustomobject]@{
        Path = Join-Path $script:R1hToolRoot 'r1h_runtime_provenance_readonly.sh'
        Bytes = 3266L
        Sha256 = 'C2D5FB76AEA33E78056107E9BF75DA64691E977EF4B44CC172829AAD684DDED1'
    }
    Plink084 = [pscustomobject]@{
        Path = 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
        Bytes = 1043072L
        Sha256 = 'E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915'
    }
    VivadoLauncher = [pscustomobject]@{
        Path = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
        Bytes = 1263L
        Sha256 = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
    }
    VivadoSettings = [pscustomobject]@{
        Path = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
        Bytes = 779L
        Sha256 = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
    }
}

$script:R1hPhaseTable = [ordered]@{
    Bootstrap = [pscustomobject]@{
        Sequence = 0; Directory = '11_BOOTSTRAP\FORMAL_BOOTSTRAP'; Image = 'FORMAL'
        ProgramRole = 'FORMAL_BOOTSTRAP'; ObserverMode = 'BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM'
        ReceiptType = 'NO_RECEIPT_REQUIRED'; RequiredWaitFloorSeconds = 5.0
        RemoteDriverDirectory = 'bootstrap_driver'; Kind = 'BOOTSTRAP'
    }
    A1 = [pscustomobject]@{
        Sequence = 1; Directory = '12_PAIR_1\A1_R1H'; Image = 'R1H'
        ProgramRole = 'ARM_A_R1E'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'FORMAL_READY_RECEIPT'; RequiredWaitFloorSeconds = 33.536673744
        RemoteDriverDirectory = 'a1_driver'; Kind = 'ARM_A'
    }
    B1 = [pscustomobject]@{
        Sequence = 2; Directory = '12_PAIR_1\B1_FORMAL'; Image = 'FORMAL'
        ProgramRole = 'ARM_B_FORMAL'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'VALID_ARM_A_RECEIPT'; RequiredWaitFloorSeconds = 5.0
        RemoteDriverDirectory = 'b1_driver'; Kind = 'ARM_B'
    }
    A2 = [pscustomobject]@{
        Sequence = 3; Directory = '13_PAIR_2\A2_R1H'; Image = 'R1H'
        ProgramRole = 'ARM_A_R1E'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'FORMAL_READY_RECEIPT'; RequiredWaitFloorSeconds = 33.536673744
        RemoteDriverDirectory = 'a2_driver'; Kind = 'ARM_A'
    }
    B2 = [pscustomobject]@{
        Sequence = 4; Directory = '13_PAIR_2\B2_FORMAL'; Image = 'FORMAL'
        ProgramRole = 'ARM_B_FORMAL'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'VALID_ARM_A_RECEIPT'; RequiredWaitFloorSeconds = 5.0
        RemoteDriverDirectory = 'b2_driver'; Kind = 'ARM_B'
    }
    A3 = [pscustomobject]@{
        Sequence = 5; Directory = '14_PAIR_3\A3_R1H'; Image = 'R1H'
        ProgramRole = 'ARM_A_R1E'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'FORMAL_READY_RECEIPT'; RequiredWaitFloorSeconds = 33.536673744
        RemoteDriverDirectory = 'a3_driver'; Kind = 'ARM_A'
    }
    B3 = [pscustomobject]@{
        Sequence = 6; Directory = '14_PAIR_3\B3_FORMAL'; Image = 'FORMAL'
        ProgramRole = 'ARM_B_FORMAL'; ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
        ReceiptType = 'VALID_ARM_A_RECEIPT'; RequiredWaitFloorSeconds = 5.0
        RemoteDriverDirectory = 'b3_driver'; Kind = 'ARM_B'
    }
}

function Assert-R1hExactFile {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][long]$Bytes,
        [Parameter(Mandatory)][ValidatePattern('^[0-9A-F]{64}$')][string]$Sha256
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "required exact file is absent: $Path"
    }
    $item = Get-Item -LiteralPath $Path
    if ($item.Length -ne $Bytes) {
        throw "byte-count mismatch for $Path`: $($item.Length), expected $Bytes"
    }
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash
    if ($actual -cne $Sha256) {
        throw "SHA-256 mismatch for $Path`: $actual"
    }
    return $item.FullName
}

function Assert-R1hAcceptedToolSet {
    foreach ($entry in $script:R1hAcceptedTools.GetEnumerator()) {
        [void](Assert-R1hExactFile -Path $entry.Value.Path -Bytes $entry.Value.Bytes -Sha256 $entry.Value.Sha256)
    }
}

function Get-R1hPhaseSpec {
    param([Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken)
    $base = $script:R1hPhaseTable[$PhaseToken]
    [pscustomobject]@{
        Token = $PhaseToken
        Sequence = $base.Sequence
        Directory = Join-Path $script:R1hTaskRoot $base.Directory
        Image = $base.Image
        ProgramRole = $base.ProgramRole
        ObserverMode = $base.ObserverMode
        ReceiptType = $base.ReceiptType
        RequiredWaitFloorSeconds = $base.RequiredWaitFloorSeconds
        RemoteDriverDirectory = $base.RemoteDriverDirectory
        RemoteDriverAbsolutePath = "/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1h/$($base.RemoteDriverDirectory)"
        Kind = $base.Kind
    }
}

function Get-R1hBindingDocument {
    param([Parameter(Mandatory)][string]$BindingPath)
    $resolved = (Resolve-Path -LiteralPath $BindingPath -ErrorAction Stop).Path
    $document = Get-Content -Raw -LiteralPath $resolved | ConvertFrom-Json -Depth 20
    if ($document.schemaVersion -ne 1 -or $document.status -cne 'FROZEN_FOR_HARDWARE') {
        throw 'R1h binding document is not schemaVersion=1/status=FROZEN_FOR_HARDWARE'
    }
    if ($document.selectedJtagCanonicalId -cne $script:R1hCanonicalTarget -or
        [string]::IsNullOrWhiteSpace([string]$document.selectedFullJtagTargetPath) -or
        (-not ([string]$document.selectedFullJtagTargetPath).EndsWith($script:R1hCanonicalSuffix, [StringComparison]::Ordinal) -and
         [string]$document.selectedFullJtagTargetPath -cne $script:R1hCanonicalTarget)) {
        throw 'selected JTAG binding is not the exact R1h canonical target'
    }
    if ($document.fpgaPart -cne $script:R1hExpectedPart -or $document.fpgaIdcode -cne $script:R1hExpectedIdcode) {
        throw 'selected JTAG part/IDCODE binding mismatch'
    }
    foreach ($name in @('formalBit','r1hBit','r1hReader','host','driver','r1hBuildRelease')) {
        if ($null -eq $document.$name) { throw "binding document lacks $name" }
    }
    if ([string]$document.host.ip -cne '10.132.1.111' -or
        [string]$document.host.user -cne 'vcdeagent1' -or
        [string]$document.host.kernel -cne '7.0.0-29-generic') {
        throw 'exact R1h host identity binding mismatch'
    }
    if ([string]$document.driver.modulePath -cne '/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko' -or
        [string]$document.driver.moduleSha256 -cne '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A' -or
        [string]$document.driver.loaderPath -cne '/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh' -or
        [string]$document.driver.loaderSha256 -cne '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F') {
        throw 'exact pinned XDMA module/loader binding mismatch'
    }
    foreach ($image in @($document.formalBit,$document.r1hBit)) {
        if ([string]$image.sha256 -notmatch '^[0-9A-F]{64}$' -or [long]$image.bytes -le 0) {
            throw 'bit binding has malformed SHA-256 or byte count'
        }
        [void](Assert-R1hExactFile -Path ([string]$image.path) -Bytes ([long]$image.bytes) -Sha256 ([string]$image.sha256))
        if ((Split-Path -Leaf ([string]$image.path)) -cne [string]$image.filename) {
            throw 'bit binding filename/path mismatch'
        }
    }
    if ([string]$document.formalBit.sha256 -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2' -or
        [long]$document.formalBit.bytes -ne 2192144L) {
        throw 'formal Phase-2 bit identity binding mismatch'
    }
    if ([string]$document.r1hReader.sha256 -notmatch '^[0-9A-F]{64}$' -or [long]$document.r1hReader.bytes -le 0) {
        throw 'R1h reader binding is unresolved'
    }
    [void](Assert-R1hExactFile -Path ([string]$document.r1hReader.path) -Bytes ([long]$document.r1hReader.bytes) -Sha256 ([string]$document.r1hReader.sha256))
    if ([string]$document.r1hSourceCommit -notmatch '^[0-9a-f]{40}$' -or
        [string]$document.r1hSourceTree -notmatch '^[0-9a-f]{40}$') {
        throw 'R1h source commit/tree binding is unresolved'
    }
    if ([string]$document.r1hBit.sourceCommit -cne [string]$document.r1hSourceCommit -or
        [string]$document.r1hBit.sourceTree -cne [string]$document.r1hSourceTree) {
        throw 'R1h bit/source provenance fields disagree'
    }
    if ([string]$document.r1hBit.filename -cne 'ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit' -or
        [long]$document.r1hBit.bytes -ne 2192144L) {
        throw 'R1h bit filename/byte-count binding mismatch'
    }
    if ([string]$document.r1hReader.sha256 -cne '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C' -or
        [long]$document.r1hReader.bytes -ne 46868L) {
        throw 'exact inherited R1f reader identity mismatch'
    }
    if ([string]$document.r1hReader.responseLatencyContract -cne 'BLOCKING_PREAD_VARIABLE_LATENCY') {
        throw 'R1h reader is not explicitly bound to blocking variable-latency pread semantics'
    }
    $releasePath = (Resolve-Path -LiteralPath ([string]$document.r1hBuildRelease.path) -ErrorAction Stop).Path
    $releasePrefixA = (Join-Path $script:R1hTaskRoot '07_BUILD') + [IO.Path]::DirectorySeparatorChar
    $releasePrefixB = (Join-Path $script:R1hTaskRoot '08_RESOURCE_GATES') + [IO.Path]::DirectorySeparatorChar
    if (-not $releasePath.StartsWith($releasePrefixA,[StringComparison]::OrdinalIgnoreCase) -and
        -not $releasePath.StartsWith($releasePrefixB,[StringComparison]::OrdinalIgnoreCase)) {
        throw 'R1h hardware-release receipt escaped the build/resource evidence roots'
    }
    [void](Assert-R1hExactFile -Path $releasePath -Bytes ([long]$document.r1hBuildRelease.bytes) -Sha256 ([string]$document.r1hBuildRelease.sha256))
    $releaseText = [IO.File]::ReadAllText($releasePath)
    foreach ($required in @(
        'POST_SYNTH_RESOURCE_MARGIN_GATE=PASS','SYNTHESIS=PASS','OPT_DESIGN=PASS',
        'PLACE=PASS','ROUTE=PASS','DRC_ERRORS=0','CDC_CRITICAL=0','CDC_UNKNOWN=0',
        'SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS','BITSTREAM=PASS','HOST_TOOL_FIXTURES=PASS')) {
        if ([regex]::Matches($releaseText,'(?m)^'+[regex]::Escape($required)+'\r?$').Count -ne 1) {
            throw "R1h hardware-release receipt lacks exact gate: $required"
        }
    }
    if ([string]$document.formalBit.filename -cne 'ahd_capture_v41_phase2_p1.bit' -or
        [long]$document.formalBit.bytes -ne 2192144L -or
        [string]$document.formalBit.sha256 -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2' -or
        [string]$document.formalBit.sourceCommit -cne 'c89e88bcdf389614c884fb129e8b2d42a585bccb' -or
        [string]$document.formalBit.sourceTree -cne '417820c69c134161fcafae0947dc5976919814d1') {
        throw 'exact formal Phase-2 identity binding mismatch'
    }
    [double]$modeled = [double]$document.r1hBit.modeledProbeCompleteSeconds
    [double]$wait = [double]$document.r1hBit.requiredWaitSeconds
    if ($modeled -lt 0.0 -or $modeled + 2.0 -gt 33.536673744) {
        throw 'modeled R1h probe completion plus two seconds exceeds the frozen Arm-A wait'
    }
    if ([Math]::Abs($wait - 33.536673744) -gt 0.000000000001) {
        throw 'frozen R1h Arm-A wait is not exactly 33.536673744 seconds'
    }
    return $document
}

function Get-R1hImageBinding {
    param([Parameter(Mandatory)][object]$Document,[Parameter(Mandatory)][object]$PhaseSpec)
    if ($PhaseSpec.Image -ceq 'FORMAL') { return $Document.formalBit }
    return $Document.r1hBit
}

function Assert-R1hPhaseDirectory {
    param([Parameter(Mandatory)][object]$PhaseSpec)
    $resolved = (Resolve-Path -LiteralPath $PhaseSpec.Directory -ErrorAction Stop).Path
    if ($resolved -cne $PhaseSpec.Directory) { throw "unexpected phase-directory resolution: $resolved" }
    $taskPrefix = $script:R1hTaskRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($taskPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'phase directory escaped the exact R1h task root'
    }
    return $resolved
}

function Read-R1hReceipt {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string]$ExpectedSha256)
    if ($ExpectedSha256 -notmatch '^[0-9A-Fa-f]{64}$') { throw 'receipt SHA-256 is malformed' }
    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolved).Hash
    if ($actual -cne $ExpectedSha256.ToUpperInvariant()) { throw 'configured-image receipt SHA-256 mismatch' }
    $map = @{}
    foreach ($line in [IO.File]::ReadAllLines($resolved)) {
        if ($line -match '^([A-Z0-9_]+)=(.*)$') {
            if ($map.ContainsKey($Matches[1])) { throw "duplicate receipt key $($Matches[1])" }
            $map[$Matches[1]] = $Matches[2]
        }
    }
    foreach ($key in @('RECEIPT_TYPE','RECEIPT_STATUS','R1H_FULL_JTAG_TARGET_PATH')) {
        if (-not $map.ContainsKey($key)) { throw "receipt lacks $key" }
    }
    if ($map.RECEIPT_STATUS -cne 'PASS') { throw 'configured-image receipt status is not PASS' }
    return [pscustomobject]@{ Path=$resolved; Sha256=$actual; Fields=$map }
}

function Get-R1hExpectedReceiptPath {
    param([Parameter(Mandatory)][ValidateSet('A1','B1','A2','B2','A3','B3')][string]$PhaseToken)
    switch ($PhaseToken) {
        'A1' { return Join-Path $script:R1hPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt' }
        'B1' { return Join-Path (Get-R1hPhaseSpec A1).Directory 'VALID_ARM_A_RECEIPT.txt' }
        'A2' { return Join-Path (Get-R1hPhaseSpec B1).Directory 'FORMAL_READY_RECEIPT.txt' }
        'B2' { return Join-Path (Get-R1hPhaseSpec A2).Directory 'VALID_ARM_A_RECEIPT.txt' }
        'A3' { return Join-Path (Get-R1hPhaseSpec B2).Directory 'FORMAL_READY_RECEIPT.txt' }
        'B3' { return Join-Path (Get-R1hPhaseSpec A3).Directory 'VALID_ARM_A_RECEIPT.txt' }
    }
}

function Assert-R1hProgramBudget {
    param([Parameter(Mandatory)][object]$PhaseSpec)
    $reservations = @(Get-ChildItem -LiteralPath $script:R1hTaskRoot -Filter PROGRAM_ATTEMPT_RESERVATION.txt -File -Recurse -ErrorAction SilentlyContinue)
    if ($reservations.Count -ge $script:R1hMaximumPrograms) {
        throw "FPGA program reservation limit already reached: $($reservations.Count)/$script:R1hMaximumPrograms"
    }
    $own = Join-Path $PhaseSpec.Directory 'PROGRAM_ATTEMPT_RESERVATION.txt'
    if (Test-Path -LiteralPath $own) { throw "phase already has an immutable program reservation: $own" }
}

function Write-R1hUtf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string[]]$Lines)
    [IO.File]::WriteAllLines($Path,$Lines,[Text.UTF8Encoding]::new($false))
}
