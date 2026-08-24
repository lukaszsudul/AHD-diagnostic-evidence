[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:R1gTaskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
$script:R1gToolRoot = Join-Path $script:R1gTaskRoot '09_HOST_TOOLS'
$script:R1gPrecheckRoot = Join-Path $script:R1gTaskRoot '10_HARDWARE_PRECHECK'
$script:R7TaskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$script:R6TaskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$script:R1gCanonicalTarget = 'Xilinx/80802026a98b01'
$script:R1gCanonicalSuffix = '/Xilinx/80802026a98b01'
$script:R1gExpectedPart = 'xc7a35t'
$script:R1gExpectedIdcode = '0362D093'
$script:R1gMaximumPrograms = 7
$script:R1gMaximumWarmReboots = 7
$script:R1gMaximumDriverLoads = 7

$script:R1gAcceptedTools = [ordered]@{
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
        Path = Join-Path $script:R1gTaskRoot 'scripts\r1g_runtime_provenance_readonly.sh'
        Bytes = 3247L
        Sha256 = '8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5'
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

$script:R1gPhaseTable = [ordered]@{
    Bootstrap = [pscustomobject]@{
        Sequence = 0; Directory = '11_BOOTSTRAP\FORMAL_BOOTSTRAP'; Image = 'FORMAL'
        ProgramRole = 'FORMAL_BOOTSTRAP'; ObserverMode = 'BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM'
        ReceiptType = 'NO_RECEIPT_REQUIRED'; RequiredWaitFloorSeconds = 5.0
        RemoteDriverDirectory = 'bootstrap_driver'; Kind = 'BOOTSTRAP'
    }
    A1 = [pscustomobject]@{
        Sequence = 1; Directory = '12_PAIR_1\A1_R1G'; Image = 'R1G'
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
        Sequence = 3; Directory = '13_PAIR_2\A2_R1G'; Image = 'R1G'
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
        Sequence = 5; Directory = '14_PAIR_3\A3_R1G'; Image = 'R1G'
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

function Assert-R1gExactFile {
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

function Assert-R1gAcceptedToolSet {
    foreach ($entry in $script:R1gAcceptedTools.GetEnumerator()) {
        [void](Assert-R1gExactFile -Path $entry.Value.Path -Bytes $entry.Value.Bytes -Sha256 $entry.Value.Sha256)
    }
}

function Get-R1gPhaseSpec {
    param([Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken)
    $base = $script:R1gPhaseTable[$PhaseToken]
    [pscustomobject]@{
        Token = $PhaseToken
        Sequence = $base.Sequence
        Directory = Join-Path $script:R1gTaskRoot $base.Directory
        Image = $base.Image
        ProgramRole = $base.ProgramRole
        ObserverMode = $base.ObserverMode
        ReceiptType = $base.ReceiptType
        RequiredWaitFloorSeconds = $base.RequiredWaitFloorSeconds
        RemoteDriverDirectory = $base.RemoteDriverDirectory
        RemoteDriverAbsolutePath = "/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1g/$($base.RemoteDriverDirectory)"
        Kind = $base.Kind
    }
}

function Get-R1gBindingDocument {
    param([Parameter(Mandatory)][string]$BindingPath)
    $resolved = (Resolve-Path -LiteralPath $BindingPath -ErrorAction Stop).Path
    $document = Get-Content -Raw -LiteralPath $resolved | ConvertFrom-Json -Depth 20
    if ($document.schemaVersion -ne 1 -or $document.status -cne 'FROZEN_FOR_HARDWARE') {
        throw 'R1g binding document is not schemaVersion=1/status=FROZEN_FOR_HARDWARE'
    }
    if ($document.selectedJtagCanonicalId -cne $script:R1gCanonicalTarget -or
        [string]::IsNullOrWhiteSpace([string]$document.selectedFullJtagTargetPath) -or
        (-not ([string]$document.selectedFullJtagTargetPath).EndsWith($script:R1gCanonicalSuffix, [StringComparison]::Ordinal) -and
         [string]$document.selectedFullJtagTargetPath -cne $script:R1gCanonicalTarget)) {
        throw 'selected JTAG binding is not the exact R1g canonical target'
    }
    if ($document.fpgaPart -cne $script:R1gExpectedPart -or $document.fpgaIdcode -cne $script:R1gExpectedIdcode) {
        throw 'selected JTAG part/IDCODE binding mismatch'
    }
    foreach ($name in @('formalBit','r1gBit','r1gReader')) {
        if ($null -eq $document.$name) { throw "binding document lacks $name" }
    }
    foreach ($image in @($document.formalBit,$document.r1gBit)) {
        if ([string]$image.sha256 -notmatch '^[0-9A-F]{64}$' -or [long]$image.bytes -le 0) {
            throw 'bit binding has malformed SHA-256 or byte count'
        }
        [void](Assert-R1gExactFile -Path ([string]$image.path) -Bytes ([long]$image.bytes) -Sha256 ([string]$image.sha256))
        if ((Split-Path -Leaf ([string]$image.path)) -cne [string]$image.filename) {
            throw 'bit binding filename/path mismatch'
        }
    }
    if ([string]$document.formalBit.sha256 -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2' -or
        [long]$document.formalBit.bytes -ne 2192144L) {
        throw 'formal Phase-2 bit identity binding mismatch'
    }
    if ([string]$document.r1gReader.sha256 -notmatch '^[0-9A-F]{64}$' -or [long]$document.r1gReader.bytes -le 0) {
        throw 'R1g reader binding is unresolved'
    }
    [void](Assert-R1gExactFile -Path ([string]$document.r1gReader.path) -Bytes ([long]$document.r1gReader.bytes) -Sha256 ([string]$document.r1gReader.sha256))
    if ([string]$document.r1gSourceCommit -notmatch '^[0-9a-f]{40}$' -or
        [string]$document.r1gSourceTree -notmatch '^[0-9a-f]{40}$') {
        throw 'R1g source commit/tree binding is unresolved'
    }
    if ([string]$document.r1gBit.sourceCommit -cne [string]$document.r1gSourceCommit -or
        [string]$document.r1gBit.sourceTree -cne [string]$document.r1gSourceTree) {
        throw 'R1g bit/source provenance fields disagree'
    }
    if ([string]$document.r1gBit.filename -cne 'ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit' -or
        [long]$document.r1gBit.bytes -ne 2192144L) {
        throw 'R1g bit filename/byte-count binding mismatch'
    }
    if ([string]$document.r1gReader.sha256 -cne '5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C' -or
        [long]$document.r1gReader.bytes -ne 46868L) {
        throw 'exact inherited R1f reader identity mismatch'
    }
    [double]$wait = [double]$document.r1gBit.requiredWaitSeconds
    if ([Math]::Abs($wait - 33.536673744) -gt 0.000000000001) {
        throw 'frozen R1g Arm-A wait is not exactly 33.536673744 seconds'
    }
    return $document
}

function Get-R1gImageBinding {
    param([Parameter(Mandatory)][object]$Document,[Parameter(Mandatory)][object]$PhaseSpec)
    if ($PhaseSpec.Image -ceq 'FORMAL') { return $Document.formalBit }
    return $Document.r1gBit
}

function Assert-R1gPhaseDirectory {
    param([Parameter(Mandatory)][object]$PhaseSpec)
    $resolved = (Resolve-Path -LiteralPath $PhaseSpec.Directory -ErrorAction Stop).Path
    if ($resolved -cne $PhaseSpec.Directory) { throw "unexpected phase-directory resolution: $resolved" }
    $taskPrefix = $script:R1gTaskRoot + [IO.Path]::DirectorySeparatorChar
    if (-not $resolved.StartsWith($taskPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'phase directory escaped the exact R1g task root'
    }
    return $resolved
}

function Read-R1gReceipt {
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
    foreach ($key in @('RECEIPT_TYPE','RECEIPT_STATUS','R1G_FULL_JTAG_TARGET_PATH')) {
        if (-not $map.ContainsKey($key)) { throw "receipt lacks $key" }
    }
    if ($map.RECEIPT_STATUS -cne 'PASS') { throw 'configured-image receipt status is not PASS' }
    return [pscustomobject]@{ Path=$resolved; Sha256=$actual; Fields=$map }
}

function Get-R1gExpectedReceiptPath {
    param([Parameter(Mandatory)][ValidateSet('A1','B1','A2','B2','A3','B3')][string]$PhaseToken)
    switch ($PhaseToken) {
        'A1' { return Join-Path $script:R1gPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt' }
        'B1' { return Join-Path (Get-R1gPhaseSpec A1).Directory 'VALID_ARM_A_RECEIPT.txt' }
        'A2' { return Join-Path (Get-R1gPhaseSpec B1).Directory 'FORMAL_READY_RECEIPT.txt' }
        'B2' { return Join-Path (Get-R1gPhaseSpec A2).Directory 'VALID_ARM_A_RECEIPT.txt' }
        'A3' { return Join-Path (Get-R1gPhaseSpec B2).Directory 'FORMAL_READY_RECEIPT.txt' }
        'B3' { return Join-Path (Get-R1gPhaseSpec A3).Directory 'VALID_ARM_A_RECEIPT.txt' }
    }
}

function Assert-R1gProgramBudget {
    param([Parameter(Mandatory)][object]$PhaseSpec)
    $reservations = @(Get-ChildItem -LiteralPath $script:R1gTaskRoot -Filter PROGRAM_ATTEMPT_RESERVATION.txt -File -Recurse -ErrorAction SilentlyContinue)
    if ($reservations.Count -ge $script:R1gMaximumPrograms) {
        throw "FPGA program reservation limit already reached: $($reservations.Count)/$script:R1gMaximumPrograms"
    }
    $own = Join-Path $PhaseSpec.Directory 'PROGRAM_ATTEMPT_RESERVATION.txt'
    if (Test-Path -LiteralPath $own) { throw "phase already has an immutable program reservation: $own" }
}

function Write-R1gUtf8NoBom {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)][string[]]$Lines)
    [IO.File]::WriteAllLines($Path,$Lines,[Text.UTF8Encoding]::new($false))
}
