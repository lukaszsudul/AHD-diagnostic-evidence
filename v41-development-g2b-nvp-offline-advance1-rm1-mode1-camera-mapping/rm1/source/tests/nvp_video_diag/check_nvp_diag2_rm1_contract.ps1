[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = [IO.Path]::GetFullPath($RepoRoot)
$monitorPath = Join-Path $repo 'rtl\diagnostic\g2b_nvp_raw_marker_monitor.sv'
$routePath = Join-Path $repo 'rtl\diagnostic\g2b_nvp_rm1_route_controller.sv'
$parserPath = Join-Path $repo 'rtl\g2b\v41_g2b_onech_c2h.sv'
$wrapperPath = Join-Path $repo 'rtl\g2b\g2b_nvp_video_diag2_rm1.sv'
$topPath = Join-Path $repo 'rtl\top\ahd_capture_top_xdma.sv'
$xdcPath = Join-Path $repo 'xdc\common\g2b_nvp_diag2_rm1_cdc.xdc'

$required = @($monitorPath, $routePath, $parserPath, $wrapperPath, $topPath, $xdcPath)
foreach ($path in $required) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "RM1_CONTRACT_MISSING:$path"
  }
}

$monitor = Get-Content -LiteralPath $monitorPath -Raw
$route = Get-Content -LiteralPath $routePath -Raw
$parser = Get-Content -LiteralPath $parserPath -Raw
$wrapper = Get-Content -LiteralPath $wrapperPath -Raw
$top = Get-Content -LiteralPath $topPath -Raw
$xdc = Get-Content -LiteralPath $xdcPath -Raw

function Require-Literal([string]$Text, [string]$Literal, [string]$Name) {
  if (-not $Text.Contains($Literal)) { throw "RM1_CONTRACT_MISSING_$Name" }
}

function Forbid-Literal([string]$Text, [string]$Literal, [string]$Name) {
  if ($Text.Contains($Literal)) { throw "RM1_CONTRACT_FORBIDDEN_$Name" }
}

function Require-Count([string]$Text, [string]$Pattern, [int]$Expected,
                       [string]$Name) {
  $actual = ([regex]::Matches($Text, $Pattern)).Count
  if ($actual -ne $Expected) {
    throw "RM1_CONTRACT_COUNT_${Name}:$actual/$Expected"
  }
}

Require-Literal $monitor 'localparam integer TRACE_ENTRIES = 64;' 'TRACE_64'
Require-Literal $monitor 'xpm_memory_sdpram' 'DUAL_CLOCK_BRAM'
Require-Literal $monitor '.CLOCKING_MODE("independent_clock")' 'INDEPENDENT_CLOCK_RAM'
Require-Literal $monitor 'SM_META_WRITE' 'META_WRITE_STATE'
Require-Literal $monitor 'SM_DONE_PUBLISH' 'DONE_PUBLISH_STATE'
Require-Literal $monitor 'done_toggle_source <= ~done_toggle_source;' 'DONE_TOGGLE'
Require-Literal $monitor 'snapshot_valid_source <= 1''b0;' 'INVALID_SNAPSHOT_PATH'
Require-Literal $monitor 'arm_rejected_count_axi' 'ARM_REJECT_COUNTER'
Require-Literal $monitor 'configured_window_axi <= 2''d1;' 'DEFAULT_500MS'
Require-Literal $monitor 'window_cycles = AXI_CYCLES_PER_MS * 100;' 'WINDOW_100'
Require-Literal $monitor 'window_cycles = AXI_CYCLES_PER_MS * 500;' 'WINDOW_500'
Require-Literal $monitor 'window_cycles = AXI_CYCLES_PER_MS * 1000;' 'WINDOW_1000'
Require-Literal $monitor 'done_sync3_axi == done_seen_axi' 'DONE_WINS_TIMEOUT_RACE'
Require-Literal $monitor '!ack_pending_axi' 'SINGLE_ACK_ACCEPTANCE'
Require-Literal $monitor 'public_done_axi && public_valid_axi' 'VALID_FROZEN_READ_GATE'
Require-Literal $monitor 'STOP_MANUAL : STOP_WINDOW' 'MANUAL_FREEZE_REASON'
Require-Literal $monitor 'freeze_manual_toggle_axi <= ~freeze_manual_toggle_axi;' 'ENCODED_MANUAL_FREEZE'
Forbid-Literal $monitor 'freeze_manual_hold_axi' 'UNSAFE_MANUAL_FREEZE_PAYLOAD'
Require-Literal $monitor 'localparam integer ABORT_DRAIN_CYCLES = 4;' 'ABORT_QUARANTINE_DEPTH'
Require-Literal $monitor 'SM_ABORT_DRAIN' 'ABORT_QUARANTINE_STATE'
Require-Literal $monitor 'abort_ack_toggle_source <= abort_epoch_seen_source;' 'ABORT_ECHO_AFTER_DRAIN'
Require-Literal $monitor 'abort_drain_ack_pending_source' 'ABORT_DRAIN_ACK_COMPLETION'
Require-Literal $monitor 'localparam integer SOURCE_RESET_DRAIN_CYCLES = 4;' 'SOURCE_RESET_QUARANTINE_DEPTH'
Require-Literal $monitor 'SM_SOURCE_RESET_DRAIN' 'SOURCE_RESET_QUARANTINE_STATE'
Require-Literal $monitor 'source_reset_drain_ack_pending_source' 'SOURCE_RESET_DRAIN_ACK_COMPLETION'
Require-Literal $monitor 'stop_reason_source == STOP_SOURCE_RESET' 'SOURCE_RESET_INVALID_ACK_REDRAIN'
Require-Literal $monitor 'source_reset_ack_requires_drain_source' 'SOURCE_RESET_IDLE_COLLISION_ACK_DRAIN'
Require-Literal $monitor 'arm_sync2_source != arm_seen_source' 'SOURCE_RESET_DISCARDED_ARM_DETECT'
Require-Literal $monitor 'abort_outstanding_axi' 'PERSISTENT_ABORT_OUTSTANDING'
Require-Literal $monitor '!axi_recovery_pending && !abort_outstanding_axi' 'ARM_BLOCKED_UNTIL_ABORT_ECHO'
Require-Literal $monitor '!awaiting_ack_axi && !route_busy && route_restored &&' 'CONFIG_REQUIRES_RESTORE'
$axiResetStart = $monitor.IndexOf('if (!axi_aresetn) begin',
    [StringComparison]::Ordinal)
$axiResetEnd = $monitor.IndexOf('end else begin', $axiResetStart,
    [StringComparison]::Ordinal)
if ($axiResetStart -lt 0 -or $axiResetEnd -lt 0) {
  throw 'RM1_CONTRACT_MISSING_AXI_RESET_BLOCK'
}
$axiResetBlock = $monitor.Substring($axiResetStart,
    $axiResetEnd - $axiResetStart)
foreach ($commandToggle in @(
  'clear_toggle_axi', 'arm_toggle_axi', 'freeze_toggle_axi',
  'freeze_manual_toggle_axi', 'ack_toggle_axi')) {
  if ($axiResetBlock -match ("(?m)^\s*" + [regex]::Escape($commandToggle) +
      "\s*<=")) {
    throw "RM1_AXI_RESET_MUTATES_COMMAND_TOGGLE:$commandToggle"
  }
}
$abortStart = $monitor.IndexOf('if (abort_epoch_command) begin',
    [StringComparison]::Ordinal)
$resetStart = $monitor.IndexOf('end else if (source_reset) begin', $abortStart,
    [StringComparison]::Ordinal)
if ($abortStart -lt 0 -or $resetStart -lt 0) {
  throw 'RM1_CONTRACT_MISSING_ABORT_BLOCK'
}
$abortBlock = $monitor.Substring($abortStart, $resetStart - $abortStart)
if ($abortBlock -match 'abort_ack_toggle_source\s*<=') {
  throw 'RM1_ABORT_ECHOES_BEFORE_COMMAND_QUARANTINE'
}
Require-Literal $monitor 'ram_read_inflight_axi' 'RAM_RESPONSE_REVALIDATION'
Require-Literal $monitor '!route_error_pulse ?' 'RAM_RESPONSE_ROUTE_REVOKE'
Require-Literal $monitor 'measurement_started_axi <= 1''b0;' 'INVALID_DONE_TIMER_CANCEL'
Require-Literal $monitor 'done_sync3_axi != done_seen_axi)) begin' 'DONE_EVENT_FREEZE_GATE'

Require-Literal $parser 'source_byte[3] == (source_byte[5] ^ source_byte[4])' 'BT656_P3'
Require-Literal $parser 'source_byte[2] == (source_byte[6] ^ source_byte[4])' 'BT656_P2'
Require-Literal $parser 'source_byte[1] == (source_byte[6] ^ source_byte[5])' 'BT656_P1'
Require-Literal $parser 'source_byte[0] == (source_byte[6] ^ source_byte[5] ^ source_byte[4])' 'BT656_P0'
Require-Literal $parser 'source_byte[3:0] == 4''b0000' 'LITERAL_PARSER_PREDICATE'
Require-Literal $parser 'diag_rm1_parser_qualified' 'PARSER_OBSERVATION'
Require-Literal $parser 'diag_rm1_parser_state <= source_state;' 'ATOMIC_PARSER_STATE'

# Every RM1 identifier in the functional parser must be either an output port
# declaration or the left-hand side of a registered assignment.  Any future
# use in a condition or functional RHS is a hard noninterference failure.
$parserLines = $parser -split "`r?`n"
foreach ($line in $parserLines) {
  $trimmed = $line.Trim()
  if ($trimmed.StartsWith('//') -or -not $line.Contains('diag_rm1_')) {
    continue
  }
  if ($line -notmatch '^\s*output\s+logic\b' -and
      $line -notmatch '^\s*diag_rm1_[A-Za-z0-9_]+\s*<=') {
    throw "RM1_FUNCTIONAL_FANIN_DETECTED:$trimmed"
  }
}

Require-Literal $route 'localparam logic [7:0] BANK_SELECT = 8''hff;' 'BANK_SELECT'
Require-Literal $route 'localparam logic [7:0] REG_VDO1_ROUTE = 8''hc2;' 'ROUTE_C2'
Require-Literal $route 'SETTLE_TIME_MS = 200' 'SETTLE_200MS'
Require-Literal $route 'R_RESET_RECOVERY' 'RESET_RECOVERY'
Require-Literal $route 'mutation_dirty' 'RETAINED_DIRTY_STATE'
Require-Literal $route 'R_RESTORE_VERIFY_BANK' 'FINAL_BANK_VERIFY'
Require-Literal $route 'restore_route_verified' 'ROUTE_RESTORE_PROOF'
Require-Literal $route 'i2c_read_data != original_bank' 'EXACT_BANK_READBACK'
Require-Literal $route 'ERR_QUIESCENCE_LOST' 'HELD_QUIESCENCE_INTERLOCK'
Require-Literal $route 'forward_route_owned' 'WHOLE_ROUTE_QUIESCENCE_INTERLOCK'
Require-Literal $route 'quiescence_lost_latched' 'LATCHED_QUIESCENCE_LOSS'
Require-Literal $route 'ERR_RUNTIME_ENV_LOST' 'RUNTIME_ENVIRONMENT_INTERLOCK'
Require-Literal $route 'runtime_environment_ok' 'LIVE_RUNTIME_ENVIRONMENT'
Require-Literal $route 'restore_route_owned' 'RESTORE_ENVIRONMENT_INTERLOCK'
Require-Literal $route 'R_WAIT_RESTORE_SAFE' 'SAFE_DEFERRED_RESTORE'
Require-Literal $route 'baseline_unproven' 'PERSISTENT_FAIL_CLOSED_BASELINE'
Forbid-Literal $route 'BGDCOL' 'BGDCOL'
Forbid-Literal $route 'host_reg' 'GENERIC_HOST_I2C'

Require-Literal $top 'ENABLE_NVP_VIDEO_DIAG2_RM1' 'TOP_PROFILE'
Require-Literal $top 'GEN_INVALID_NVP_DIAG_PROFILE' 'MUTUAL_EXCLUSION'
Require-Literal $top 'ENABLE_RTRACK_DIAGNOSTICS != 0))' 'RTRACK_EXCLUSION'
Require-Literal $top 'GEN_NVP_DIAG2_RM1_CORE' 'RM1_ELABORATION'
Require-Literal $top 'legacy_host_req_addr >= 17''h03c00' 'MMIO_START'
Require-Literal $top 'legacy_host_req_addr <= 17''h03fff' 'MMIO_END'
Require-Literal $wrapper 'transport_quiescent' 'TRANSPORT_QUIESCENCE'

Require-Literal $xdc 'clear_sync1_source' 'CLEAR_SYNC'
Require-Literal $xdc 'arm_sync1_source' 'ARM_SYNC'
Require-Literal $xdc 'freeze_sync1_source' 'FREEZE_SYNC'
Require-Literal $xdc 'ack_sync1_source' 'ACK_SYNC'
Require-Literal $xdc 'abort_epoch_sync1_source' 'AXI_RESET_EPOCH_SYNC'
Require-Literal $xdc 'abort_ack_sync1_axi' 'AXI_RESET_EPOCH_ACK_SYNC'
Require-Literal $xdc 'done_sync1_axi' 'DONE_SYNC'
Require-Literal $xdc 'ack_done_sync1_axi' 'ACK_DONE_SYNC'
Require-Literal $xdc 'rm1_arm_mailbox_d' 'STABLE_MAILBOX'
foreach ($guard in @(
    'RM1_CDC_XDC_SYNC1_CELL_COUNT=', 'RM1_CDC_XDC_SYNC1_D_PIN_COUNT=',
    'RM1_CDC_XDC_SESSION_CELL_COUNT=', 'RM1_CDC_XDC_ROUTE_CELL_COUNT=',
    'RM1_CDC_XDC_WINDOW_CELL_COUNT=', 'RM1_CDC_XDC_MAILBOX_CELL_COUNT=',
    'RM1_CDC_XDC_MAILBOX_D_PIN_COUNT=')) {
  Require-Literal $xdc $guard "XDC_GUARD_$guard"
}
Require-Literal $xdc 'foreach {rm1_vector_leaf rm1_vector_width}' 'XDC_PAIRED_VECTOR_LOOP'
Require-Literal $xdc 'session_source 16' 'XDC_SESSION_16'
Require-Literal $xdc 'route_source 3' 'XDC_ROUTE_3'
Require-Literal $xdc 'window_source 2' 'XDC_WINDOW_2'
Require-Literal $xdc 'set rm1_arm_mailbox_cells [concat' 'XDC_COLLECTION_CONCAT'
Require-Count $xdc '(?m)^\s*set_false_path\s+-to\s+\$rm1_sync1_d\s*$' 1 `
    'XDC_SYNC1_FALSE_PATH_EXACT'
Require-Count $xdc '(?m)^\s*set_false_path\s+-to\s+\$rm1_arm_mailbox_d\s*$' 1 `
    'XDC_MAILBOX_FALSE_PATH_EXACT'
Require-Count $xdc '(?m)^\s*set_false_path\s+-to\s+' 2 'XDC_FALSE_PATH_TOTAL'
if ($xdc -match '(?m)^\s*(set_input_delay|set_output_delay|create_clock)\b') {
  throw 'RM1_CONTRACT_FORBIDDEN_XDC_TIMING_CREATION'
}
if ($xdc -match '(?im)^\s*set_false_path.*\b(nvp_scl|nvp_sda|nvp_rst|sys_rst_n)\b') {
  throw 'RM1_CONTRACT_FORBIDDEN_XDC_CONTROL_PORT_FALSE_PATH'
}

$axiMarker = 'always_ff @(posedge axi_clk) begin : AXI_CONTROL_AND_MMIO'
$axiOffset = $monitor.IndexOf($axiMarker, [StringComparison]::Ordinal)
if ($axiOffset -lt 0) { throw 'RM1_CONTRACT_MISSING_AXI_BLOCK' }
$axiBlock = $monitor.Substring($axiOffset)
foreach ($sourceCounter in @(
  'raw_sample_count', 'byte_change_count', 'candidate_count',
  'parity_pass_count', 'parity_fail_count', 'legal_sav_count',
  'legal_eav_count', 'parser_reject_count', 'min_sav_gap',
  'max_sav_gap', 'last_sav_gap')) {
  if ($axiBlock.Contains($sourceCounter)) {
    throw "RM1_RAW_WIDE_CDC_REFERENCE_IN_AXI:$sourceCounter"
  }
}
Require-Literal $axiBlock 'ram_read_data_axi' 'AXI_RAM_READ_ONLY'

Write-Output 'RM1_T17_PASS no_raw_wide_combinational_cdc'
Write-Output 'RM1_FUNCTIONAL_FANOUT_CONTRACT_PASS'
Write-Output 'RM1_STATIC_CONTRACT_PASS'
