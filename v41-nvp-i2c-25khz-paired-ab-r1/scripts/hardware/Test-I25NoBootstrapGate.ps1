[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath
)

$ErrorActionPreference = 'Stop'
$expected = [ordered]@{
    FORMAL_BOOTSTRAP_AUTHORIZED = 'NO'
    FPGA_PROGRAMS_BEFORE_FORMAL_START_PROOF = '0'
    RETAINED_LAST_CONTROLLED_IMAGE = 'FORMAL_PHASE2'
    RETAINED_FORMAL_BIT_SHA256 = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
    RETAINED_FINAL_BOOT_ID = '7f8db2e5-12aa-4421-b44a-28e72fff483f'
    RETAINED_FINAL_DONE = '1'
    RETAINED_CLOSURE_EVIDENCE_HASHES_VERIFIED = 'YES'
    CONTROLLED_HARDWARE_MUTATION_AFTER_RETAINED_CLOSURE = 'NO'
    REMOTE_USER = 'vcdeagent1'
    REMOTE_EFFECTIVE_USER = 'root'
    HOSTNAME_STABLE = 'PASS'
    CURRENT_KERNEL = '7.0.0-29-generic'
    GLOBAL_HW_TARGET_COUNT = '1'
    JTAG_TARGET_MATCH_COUNT = '1'
    JTAG_DEVICE_COUNT = '1'
    JTAG_HS2_SERIAL = '210241768436'
    FPGA_PART = 'xc7a35t'
    FPGA_IDCODE = '0362D093'
    FPGA_DONE = '1'
    ENDPOINT_COUNT = '1'
    ENDPOINT_BDF = '0000:01:00.0'
    ENDPOINT_VENDOR_DEVICE = '10ee:7011'
    ENDPOINT_SUBSYSTEM = '10ee:0007'
    ENDPOINT_CLASS = '058000'
    ENDPOINT_LINK = 'GEN1_X1'
    BAR0_BYTES = '131072'
    BAR1_BYTES = '65536'
    WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND = 'NO'
    ENDPOINT_BOUND_DRIVER = 'xdma'
    XDMA_USER_NODE = 'CHARACTER_DEVICE'
    XDMA_CONTROL_NODE = 'CHARACTER_DEVICE'
    XDMA_ALL_NODE_COUNT = '21'
    XDMA_EXPECTED_NODE_COUNT = '21'
    XDMA_ALL_NODES_CLASSIFICATION = 'PASS_EXACT_ACCEPTED_21_NODE_SET'
    PINNED_XDMA_ARTIFACT_SHA256 = '1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A'
    ACCEPTED_XDMA_LOADER_SHA256 = '7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F'
    LOADED_XDMA_PROVENANCE = 'PASS_EXACT_PINNED_ARTIFACT_AND_ACCEPTED_LOAD_CHAIN'
    XDMA_OPEN_PROCESS_COUNT = '0'
    DMA_ACTIVITY = '0'
    BLOCK_ID = '0xA40A0C07'
    PROTOCOL = '0x0000400B'
    CAPABILITIES = '0x00031002'
    DIAGNOSTIC_MAGIC = '0x00000000'
    KERNEL_AER_XDMA_HEALTH = 'PASS'
    FORMAL_BIT_REHASH = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
    TEMP_PASSWORD_FILES_REMAINING = '0'
    PLINK_PW_OPTION_USED = 'NO'
    PLINK_PWFILE_OPTION_USED = 'YES'
}

$values = @{}
foreach ($line in Get-Content -LiteralPath (Resolve-Path -LiteralPath $InputPath)) {
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^([A-Z0-9_]+)=(.*)$') {
        $values[$Matches[1]] = $Matches[2].Trim()
    }
}

$missing = @()
$mismatch = @()
foreach ($item in $expected.GetEnumerator()) {
    if (-not $values.ContainsKey($item.Key)) {
        $missing += $item.Key
    } elseif ($values[$item.Key] -cne $item.Value) {
        $mismatch += ('{0}: expected {1}, observed {2}' -f $item.Key,$item.Value,$values[$item.Key])
    }
}

$bootContinuity = $false
if ($values.ContainsKey('CURRENT_BOOT_ID') -and $values.ContainsKey('RETAINED_FINAL_BOOT_ID')) {
    $bootContinuity = ($values.CURRENT_BOOT_ID -ceq $values.RETAINED_FINAL_BOOT_ID)
} else {
    $missing += 'CURRENT_BOOT_ID'
}

$unsafeKeys = @(
    'GLOBAL_HW_TARGET_COUNT','JTAG_TARGET_MATCH_COUNT','JTAG_DEVICE_COUNT','JTAG_HS2_SERIAL','FPGA_PART','FPGA_IDCODE',
    'ENDPOINT_COUNT','ENDPOINT_BDF','ENDPOINT_VENDOR_DEVICE','ENDPOINT_SUBSYSTEM','ENDPOINT_CLASS',
    'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND','KERNEL_AER_XDMA_HEALTH'
)
$unsafeMismatch = $false
foreach ($entry in $mismatch) {
    foreach ($key in $unsafeKeys) {
        if ($entry.StartsWith("${key}:")) { $unsafeMismatch = $true }
    }
}

$gatePass = $false
if ($missing.Count -gt 0) {
    $classification = 'HARD_STOP_FORMAL_START_NOT_PROVEN_MISSING_LIVE_EVIDENCE'
} elseif ($unsafeMismatch) {
    $classification = 'HARD_STOP_CONTRADICTORY_OR_UNSAFE_STATE'
} elseif (-not $bootContinuity) {
    $classification = 'HARD_STOP_FORMAL_START_NOT_PROVEN_BOOT_ID_CHANGED'
} elseif ($mismatch.Count -gt 0) {
    # Any remaining identity/state contradiction blocks the formal start proof.
    # No bootstrap, diagnostic program, or formal program is authorized here.
    $classification = 'HARD_STOP_FORMAL_START_NOT_PROVEN_STATE_CONTRADICTION'
} else {
    $classification = 'PASS_EXACT_FORMAL_PHASE2_START_NO_BOOTSTRAP'
    $gatePass = $true
}

'NO_BOOTSTRAP_GATE_INPUT={0}' -f (Resolve-Path -LiteralPath $InputPath).Path
'CURRENT_BOOT_ID={0}' -f $values.CURRENT_BOOT_ID
'RETAINED_FINAL_BOOT_ID={0}' -f $values.RETAINED_FINAL_BOOT_ID
'BOOT_ID_CONTINUITY={0}' -f $(if ($bootContinuity) { 'PASS' } else { 'FAIL' })
'MISSING_FIELDS={0}' -f $(if ($missing.Count) { ($missing | Sort-Object -Unique) -join ',' } else { 'NONE' })
'MISMATCHES={0}' -f $(if ($mismatch.Count) { $mismatch -join ' | ' } else { 'NONE' })
'FORMAL_PHASE2_START_PROOF={0}' -f $classification
'FORMAL_BOOTSTRAP_AUTHORIZED=NO'
'HARDWARE_SEQUENCE_ENTRY_ELIGIBLE={0}' -f $(if ($gatePass) { 'YES_SUBJECT_TO_ALL_REMAINING_GATES' } else { 'NO' })
'FPGA_PROGRAMS_RECORDED_BY_THIS_GATE=0'
'FPGA_PROGRAMS_REQUIRED_AT_HARD_STOP={0}' -f $(if ($gatePass) { 'NOT_APPLICABLE' } else { '0' })

if (-not $gatePass) {
    'HARD_STOP=YES'
    exit 1
}
'HARD_STOP=NO'
