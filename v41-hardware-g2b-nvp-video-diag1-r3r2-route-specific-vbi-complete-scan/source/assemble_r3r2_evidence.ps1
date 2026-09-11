[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$TaskRoot,

  [Parameter(Mandatory)]
  [string]$EvidenceDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$remote = Join-Path $TaskRoot 'evidence-staging\remote-text'
$generated = Join-Path $TaskRoot 'evidence-staging\generated'
$scripts = Join-Path $TaskRoot 'scripts'
$contracts = Join-Path $TaskRoot 'contracts'

if (Test-Path -LiteralPath $EvidenceDirectory) {
  throw "R3R2_EVIDENCE_DESTINATION_ALREADY_EXISTS:$EvidenceDirectory"
}
foreach ($required in @($remote,$generated,$scripts,$contracts)) {
  if (-not (Test-Path -LiteralPath $required -PathType Container)) {
    throw "R3R2_EVIDENCE_INPUT_DIRECTORY_MISSING:$required"
  }
}

New-Item -ItemType Directory -Path $EvidenceDirectory | Out-Null
New-Item -ItemType Directory -Path (Join-Path $EvidenceDirectory 'source') | Out-Null
New-Item -ItemType Directory -Path (Join-Path $EvidenceDirectory 'raw-text-evidence') | Out-Null

$utf8 = [Text.UTF8Encoding]::new($false)
function Write-Text {
  param([string]$Name,[string]$Text)
  [IO.File]::WriteAllText((Join-Path $EvidenceDirectory $Name),($Text.TrimEnd()+"`n"),$utf8)
}
function Copy-Exact {
  param([string]$Source,[string]$Destination)
  if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "R3R2_EVIDENCE_SOURCE_MISSING:$Source"
  }
  Copy-Item -LiteralPath $Source -Destination (Join-Path $EvidenceDirectory $Destination)
}

$validation = Get-Content -LiteralPath (Join-Path $remote 'logs\session-01-r1-ch1\validation-result.json') -Raw | ConvertFrom-Json
$pixel = Get-Content -LiteralPath (Join-Path $remote 'images\session-01-r1-ch1\pixel-statistics.json') -Raw | ConvertFrom-Json
$capture = Get-Content -LiteralPath (Join-Path $remote 'logs\session-01-r1-ch1\controller-result.json') -Raw | ConvertFrom-Json
$baseline = Get-Content -LiteralPath (Join-Path $remote 'baseline\baseline-comparison.json') -Raw | ConvertFrom-Json
$identity = Get-Content -LiteralPath (Join-Path $remote 'logs\mmio-sanity\runtime-identity.json') -Raw | ConvertFrom-Json
$mmio = Get-Content -LiteralPath (Join-Path $remote 'logs\mmio-sanity\r3r2-mmio-sanity-result.json') -Raw | ConvertFrom-Json
$cleanup = Get-Content -LiteralPath (Join-Path $remote 'logs\final-cleanup.json') -Raw | ConvertFrom-Json

if ($validation.result -cne 'PASS' -or $validation.bounded_route_specific_vbi_tail -cne 'PASS') {
  throw 'R3R2_SESSION1_POST_FAILURE_VALIDATION_NOT_PASS'
}
if ($pixel.result -cne 'PASS' -or $pixel.classification -cne 'UNIFORM_BGDCOL_RED') {
  throw 'R3R2_SESSION1_PIXEL_ANALYSIS_NOT_PASS'
}
if ($baseline.double_prepare_baseline_gate -cne 'PASS' -or $cleanup.result -cne 'PASS') {
  throw 'R3R2_BASELINE_OR_CLEANUP_NOT_PASS'
}
if ($identity.result -cne 'PASS' -or $mmio.result -cne 'PASS') {
  throw 'R3R2_IDENTITY_OR_MMIO_NOT_PASS'
}

$firstBlocker = 'R3R2_DUT_VALIDATOR_DEPLOYMENT_MISSING_ABI_V1'
$taskTitle = 'AHD v41 G2B-NVP-VIDEO-DIAG1-R3R2 Retained CH3 Frame Content Analysis, Bounded Route-Specific VBI-Tail Contract, Validator Regression and Complete Non-Aborting Four-Channel 4x4 Scan'

Write-Text 'V41_G2B_NVP_VIDEO_DIAG1_R3R2_MAIN_REPORT.md' @"
# $taskTitle

Engineering gate: **FAIL**

The route-specific VBI correction itself passed. The validator regression was 16/16, the host-controller gate was 10/10, exact R3 runtime identity passed, MMIO sanity passed, and Double-PREPARE passed with equal 26-transaction deltas and PRODUCT baseline '0x88/0x88/0x00'.

The one authorized fresh scan stopped after session 1. The session-1 CH1/RED DMA acquisition itself completed 2500/2500 records and 10,240,000 bytes with an 82.262 us disable latency and zero pending AIO. The validator subprocess then failed before validation because its deployed module set omitted the unchanged transitive dependency 'abi_v1.py', imported by 'frame_reconstruct_nvp_capture.py'. The exact blocker is '$firstBlocker'.

After safe restore, the missing immutable dependency was deployed only to analyze the already retained session-1 bytes. No second scan and no recapture occurred. That retained analysis passed active-frame/transport integrity, the bounded VBI-tail contract, complete 1920x1080 reconstruction, and RED BGDCOL pixel matching. Its two frame-boundary deltas were 22, with tail intervals 21 and 21.

Because sessions 2-16 were not executed and a second 4x4 scan was prohibited, the requested complete matrix was not achieved. No multi-channel, CH2, CH3, CH4, or camera-image conclusion is claimed from this R3R2 run.

The exact R3R1 retained CH3 primary/frame/PNG byte artifacts were not present under the authorized R3R1 root, so retained CH3 content analysis is 'NOT_AVAILABLE_EXACT_ARTIFACT_MISSING'. Accepted immutable R3R1 metadata still supports the validator regression: CH3 boundary delta 2 means one legal tail interval and is not an active-frame failure.

Final safety state passed: firmware restored PRODUCT BGDCOL '0x88/0x88', full route '0x00', and its private bank context; stream was disabled; physical quiescence passed; pending AIO was zero; the driver and XDMA nodes were removed; both fresh locks were released. The R3 diagnostic image remains in volatile SRAM.

Raw captures, UYVY frames, PNGs, thumbnails, native binaries, driver binaries, bitstreams, DCPs, credentials, and camera pixels are excluded from this publication.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_OWNER_AUTHORIZATION.md' @"
# Owner Authorization

Owner continuity is accepted at PROJECT_STATE_REV 8 without broad requalification. Authorized actions were task-local host correction, one driver load, one fresh Double-PREPARE, one fresh 4x4 scan, conditional captures, safe restore, cleanup, and append-only evidence publication. FPGA source edits, Vivado work, FPGA programming, reboot, power-cycle, a second complete scan, arbitrary NVP writes, 60-second capture, two-channel capture, and V4L2 work were not authorized and were not performed.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_SCOPE.md' @"
# Scope

This was a host-only correction and hardware diagnostic continuation. The engineering goals were retained CH3 content analysis when exact bytes existed, a bounded route-specific VBI-tail validator, validator and controller regression, and one complete non-aborting 4x4 scan. The validator and controller corrections passed offline; the hardware matrix stopped at the first deployment blocker and was not retried.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_R3R1_INHERITANCE.md' @"
# R3R1 Inheritance

R3R1 evidence commit 'ec52cf581441c756efdad0cec012d4f18be5d17a' is inherited without rewriting it. R3 source commit 'fc37d815b5d64ef90dfbd99c57ae4cc09567b56f', diagnostic version '0x00010002', capabilities '0x00000BFF', and the R3 hardware MMIO repair remain authoritative. R3R1 established CH1 RED BGDCOL PASS, CH2 VCLK-present/no-SAV, and CH3 active-frame transport integrity with boundary deltas 2 and 2.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_R3R1_ERRATUM.md' @"
# R3R1 Append-Only Erratum

~~~text
SESSION 3 TRANSPORT:
PASS

SESSION 3 ACTIVE FRAME:
PASS

SESSION 3 BOUNDED VBI-TAIL:
PASS_UNDER_R3R2_CONTRACT

SESSION 3 LEGACY CH1 EXACT-TAIL FINGERPRINT:
FAIL_EXPECTED_NOT_UNIVERSAL

SESSION 3 FIRMWARE RESPONSE:
0x0003000A FAILURE_RESPONSE_IN_R3R1

R3R2 DISPOSITION:
HOST VALIDATOR SCOPE CORRECTED
~~~

This erratum does not rewrite the immutable R3R1 evidence.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_RETAINED_CH3_ARTIFACTS.md' @"
# Retained CH3 Artifacts

Search scope was restricted to 'C:\FPGA\G2B_NVP_VIDEO_DIAG1_R3R1_20260911T055202Z'. No file in that exact root matched the authoritative primary SHA-256 'BFA986D1...D7A6A', raw-frame SHA-256 'F7DC0211...7285', or PNG SHA-256 'C15C5B25...6A79'. No similarly named artifact was substituted. Retained artifact result: 'NOT_AVAILABLE_EXACT_ARTIFACT_MISSING'.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_RETAINED_CH3_CONTENT_ANALYSIS.md' @"
# Retained CH3 Content Analysis

Result: 'NOT_AVAILABLE_EXACT_ARTIFACT_MISSING'.

Pixel content was not reanalyzed because neither the exact qualified UYVY frame nor the exact primary bytes existed under the authorized root. The accepted R3R1 transport/frame metadata was used only for bounded-validator regression; it is not substituted for pixel bytes and does not support a fresh color claim.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_RETAINED_CH3_PIXEL_STATISTICS.csv' "Availability,Reason`nNOT_AVAILABLE,EXACT_ARTIFACT_MISSING"
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_RETAINED_CH3_FRAME_HASHES.csv' @"
Artifact,ExpectedSHA256,Found,ObservedSHA256
primary,BFA986D1BAC2E6C57342AC6F6D08C087A811FC72E97C9F1F8A383E53B78D7A6A,NO,NONE
qualified_frame,F7DC021138D6A4996DC07554629D1CA38417BF3237672BDC6949F710ADA77285,NO,NONE
qualified_png,C15C5B255951664F619C2F1E02FC18BB4E56BEC635E466AAB951C9612BEF6A79,NO,NONE
"@

Copy-Exact (Join-Path $contracts 'V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.md') 'G2B_NVP_VIDEO_DIAG1_R3R2_VBI_CONTRACT.md'
Copy-Exact (Join-Path $contracts 'V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json') 'G2B_NVP_VIDEO_DIAG1_R3R2_VBI_CONTRACT.json'

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_VALIDATOR_SOURCE_DIFF.md' @"
# Validator Source Delta

Immutable R3R1 validator SHA-256: '0417F9FFF336112AD452DD6E006610ED25A5C302952675F7FADA84CC4C54444C'.

R3R2 validator SHA-256: 'CBAEFF14DACA8237F52683743FA1BD4389E359EBD26B4034243310CE067B2D3D'.

The R3R2 validator makes active-frame/transport integrity, bounded route-specific VBI-tail validity, and legacy CH1 exact-tail fingerprint three independent decisions. Non-boundary capture deltas remain exactly 1. A valid line-1079 to next-frame line-0 boundary accepts capture delta 1..22 and records tail intervals as delta minus one. Attempt/global deltas remain exactly 1, malformed/drop deltas remain zero, and line-0/line-1 flags remain strict.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_VALIDATOR_REGRESSION.md' @"
# Validator Regression

Result: **16/16 PASS**.

The suite covers retained CH1 exact-tail control, accepted immutable CH3 delta-2 metadata, legal minimum/maximum boundaries, invalid zero/above-maximum deltas, invalid non-boundary delta, frame/flag/sequence/counter failures, event flags, variable-but-bounded tails, and incomplete/duplicate active frames. A full synthetic 2500-record delta-2 integration also passed active-frame integrity, bounded VBI, and complete-frame reconstruction while the independent legacy exact-22 fingerprint failed as expected.
"@
Copy-Exact (Join-Path $TaskRoot 'validator-regression\validator-regression.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_VALIDATOR_REGRESSION.csv'

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_HOST_SOURCE_REUSE.md' @"
# Host Source Reuse

R3R1 capture controller SHA-256: 'E92189885F0FE5927604DEF4160536E2FB489017F4761DD2887F110992025F57'.

R3R1 scan controller SHA-256: '2E3409E6E50A64F3D2C8745B5035BFE458DAAF42B3AFC9F40E23BFEF81226F99'.

The sources were copied into the fresh R3R2 root and modified only for the bounded VBI result schema and safe continuation semantics. Original copies were not modified.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_HOST_SOURCE_DIFF.md' @"
# Host Source Delta

R3R2 capture controller SHA-256: '7AC6B0028DBC0B0BC89E464897994531CDB3E188D7C300170B0577C57DF33D88'.

R3R2 scan controller SHA-256: '1FBB936167F23CC161DB7CB9C2CE54E11FDCC5FF197F7D6015A15DAD0FB52163'.

The host now accepts 'ACTIVE_FRAME_AND_TRANSPORT_INTEGRITY=PASS' plus 'BOUNDED_ROUTE_SPECIFIC_VBI_TAIL=PASS'; it stores the legacy exact-tail result as a route fingerprint and stops only for actual integrity or out-of-range VBI failures. The hardware deployment manifest accidentally omitted unchanged transitive module 'abi_v1.py'; this operational packaging defect, not the validator logic, stopped the one authorized scan.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_HOST_CONTROLLER_GATE.md' @"
# Host Controller Gate

Result: **10/10 PASS**. Python syntax/import, PowerShell parsing, zero embedded credentials, and no raw payload through controller IPC also passed. The deterministic cases cover retained CH3 acceptance, independent legacy mismatch, safe no-SAV advance, legal variable-tail continuation, out-of-range stop, actual-integrity stop, pixel-analysis ordering, ledger-driven projections, sixteen unique mixed sessions, and unchanged restore behavior.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_DRIVER_LOAD.md' @"
# Driver Load

Exact existing driver load passed. Endpoint '0000:01:00.0' matched '10ee:7011', subsystem '10ee:0007', with 5.0 GT/s Gen2 x1. '/dev/xdma0_user' and '/dev/xdma0_c2h_0' appeared. Final unload and node removal passed.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_RUNTIME_IDENTITY.md' @"
# Runtime Identity

PASS: source commit 'fc37d815b5d64ef90dfbd99c57ae4cc09567b56f', DIAG magic '0x4E565034', version '0x00010002', capabilities '0x00000BFF', build flags '0x00000402', transport ABI V1, and autoinit with zero error/NACK.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_MMIO_SANITY.md' @"
# MMIO Sanity

One bounded READ / CLEAR / READ sanity sequence passed. Post-write reads: 5; '0xFFFFFFFF' reads: 0; timeouts: 0; I2C transaction count unchanged; boot identity unchanged.
"@

Copy-Exact (Join-Path $remote 'baseline\BASELINE_A.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_BASELINE_A.csv'
Copy-Exact (Join-Path $remote 'baseline\BASELINE_A.json') 'G2B_NVP_VIDEO_DIAG1_R3R2_BASELINE_A.json'
Copy-Exact (Join-Path $remote 'baseline\BASELINE_B.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_BASELINE_B.csv'
Copy-Exact (Join-Path $remote 'baseline\BASELINE_B.json') 'G2B_NVP_VIDEO_DIAG1_R3R2_BASELINE_B.json'
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_BASELINE_COMPARISON.md' @"
# Baseline Comparison

Double-PREPARE: **PASS**. PREPARE_A and PREPARE_B transaction deltas were 26 and 26. Full visible values agreed: BG78 '0x88', BG79 '0x88', route '0x00'. NACK, timeout, and recovery counts were zero. PREPARE_B became restore authority; the original bank remained firmware-private and its final physical verification passed.
"@

Copy-Exact (Join-Path $remote 'logs\snapshot_coherence.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_SNAPSHOT_COHERENCE.csv'
Copy-Exact (Join-Path $remote 'logs\session_status_history.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_HOST_SESSION_HISTORY.csv'
Copy-Exact (Join-Path $remote 'logs\session_status_history.jsonl') 'G2B_NVP_VIDEO_DIAG1_R3R2_HOST_SESSION_HISTORY.jsonl'

foreach ($name in @(
  'G2B_NVP_VIDEO_DIAG1_R3R2_AVAILABILITY_WINDOWS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_RESET_ISOLATION.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_4X4_AVAILABILITY_MATRIX.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_PER_CHANNEL_SUMMARY.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_ROUTE_READBACKS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_BGDCOL_READBACKS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_SESSION_OUTCOMES.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_FIRMWARE_ACK_LEDGER.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_CAPTURE_INDEX.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_CAPTURE_RESULTS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_AIO_SUMMARY.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_ROUTE_VBI_FINGERPRINTS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_VBI_REPEATABILITY.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_FRAME_HASHES.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_PIXEL_STATISTICS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_BGDCOL_MATCH_RESULTS.csv',
  'G2B_NVP_VIDEO_DIAG1_R3R2_CHANNEL_REPEATABILITY.csv'
)) { Copy-Exact (Join-Path $generated $name) $name }

Copy-Exact (Join-Path $remote 'logs\status-samples.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_STATUS_SAMPLES.csv'
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_I2C_TIMELINE.csv' @"
Checkpoint,I2CTransactionCount,I2CNACKCount,I2CTimeoutCount,I2CRecoveryCount,Result
AFTER_CLEAR,0,0,0,0,PASS
PREPARE_A,26,0,0,0,PASS
PREPARE_B,52,0,0,0,PASS
SESSION_1_SNAPSHOT,87,0,0,0,PASS
FINAL_RESTORE,NOT_EXPOSED_IN_RECEIPT,0,0,0,PASS
"@

Copy-Exact (Join-Path $remote 'logs\session-01-r1-ch1\frame-boundary-analysis.csv') 'G2B_NVP_VIDEO_DIAG1_R3R2_FRAME_BOUNDARY_ANALYSIS.csv'

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_BT656_AVAILABILITY_DECISION.md' @"
# BT.656 Availability Decision

Only fresh session 1 was observed. CH1 was 'BT656_READY_PRE_RESET_AND_POST_RESET'; CH2-CH4 were not reached. Each channel therefore has 'NOT_ENOUGH_VALID_OBSERVATIONS' across the requested four rounds. No complete availability-matrix claim is made.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_VBI_TAIL_DECISION.md' @"
# VBI-Tail Decision

The bounded host contract is correct and passed all 16 regression cases. Fresh session 1 passed with deltas 22/22 and route fingerprint 'STABLE_ROUTE_TAIL_21'. Accepted R3R1 CH3 metadata passes with deltas 2/2 (tail interval 1) while its legacy CH1 exact-tail fingerprint fails as expected and independently. The full route repeatability matrix was not reached.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_DIGITAL_PATH_DECISION.md' @"
# Digital Path Decision

Fresh R3R2 evidence proves one CH1 RED end-to-end BGDCOL capture. It does not prove a multi-channel multi-color path because sessions 2-16 did not run. Result: 'NOT_PROVEN' for the requested multi-channel matrix; inherited R3/R3R1 results are supporting evidence only.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_CAMERA_CONTENT_DECISION.md' @"
# Camera Content Decision

No live-camera content was proven. Fresh session 1 was 'NO_VIDEO_STABLE' and its complete frame was uniform RED BGDCOL. CH2-CH4 were not freshly observed. Logical active camera channel: 'NONE'; end-to-end camera image: 'UNRESOLVED'.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_NEXT_ROOT_CAUSE_SCOPE.md' @"
# Next Root-Cause Scope

First correct only the host deployment bundle so the unchanged 'abi_v1.py' transitive dependency is present before hardware start, add a mocked import-closure/deployment-manifest gate, and authorize a new single scan in a new task. Only a completed matrix may justify channel-private Bank 5/6/7/8 or VDO1 re-arm investigation.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_PRODUCT_RESTORE_RECEIPT.md' @"
# PRODUCT Restore Receipt

PASS after the session-1 failure response. Restored BG78 '0x88', BG79 '0x88', route '0x00'; restore status '0x00000003'; I2C NACK/timeout/recovery all zero; diagnostic ownership released; I2C bus idle; firmware-private bank physical readback PASS.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_CLEANUP_RECEIPT.md' @"
# Cleanup Receipt

PASS: stream disabled, physical quiescence PASS, pending AIO 0, native helper absent, PRODUCT baseline restored, exact driver unloaded, XDMA nodes removed, Linux lock released, controller lock released last. A separate read-only post-cleanup check confirmed the module, nodes, and Linux lock remained absent.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_FINAL_STATE.md' @"
# Final State

Engineering gate: 'FAIL' at '$firstBlocker'. Evidence is safely publishable. FPGA runtime remains 'G2B_NVP_VIDEO_DIAG1_R3_VOLATILE_SRAM'. NVP persistent state is unchanged and restored to PRODUCT baseline. FPGA source, SSOT, and META were unchanged. No raw pixels are public.
"@

Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_GATE_MATRIX.csv' @"
Gate,Result,Detail
Retained_CH3_exact_artifact,NOT_AVAILABLE,Nonblocking exact artifact missing
VBI_contract,PASS,NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_V1
Validator_regression,PASS,16/16
Host_controller_gate,PASS,10/10
Runtime_identity,PASS,R3 exact identity
Driver_load,PASS,0000:01:00.0 Gen2 x1
MMIO_sanity,PASS,No FFFFFFFF or timeout
Double_PREPARE,PASS,26/26 and 0x88/0x88/0x00
Scan_start,PASS,Fresh scan session 1
Session_1_capture,PASS_POST_FAILURE_ANALYSIS,2500/2500 bounded VBI complete RED frame
Session_1_firmware_success_ack,FAIL,Failure response 0x0001000A triggered safe restore
Complete_4x4_matrix,FAIL,1/16 sessions observed
PRODUCT_baseline_restore,PASS,0x88/0x88/0x00 and bank verify
Cleanup,PASS,Driver nodes AIO locks clean
Engineering_gate,FAIL,$firstBlocker
Evidence_publication,PENDING,Containing commit and pinned remote readback
"@

$state = [ordered]@{
  task='G2B-NVP-VIDEO-DIAG1-R3R2'
  project_state_rev='8 — OWNER_ATTESTED_NOT_REVERIFIED'
  engineering_gate='FAIL'
  evidence_publication='PENDING_CONTAINING_COMMIT_REMOTE_READBACK'
  overall_result='FAIL'
  first_blocker=$firstBlocker
  r3_runtime_reused=$true
  fpga_programming=$false
  warm_reboot=$false
  sessions_requested=16
  sessions_observed=1
  coherent_snapshots=1
  unique_sessions=1
  duplicate_sessions=0
  missing_sessions=15
  bg_rounds_verified=1
  route_readbacks=1
  availability_classifications=1
  firmware_success_acknowledgements=0
  capture_eligible_sessions=1
  captures_attempted=1
  captures_completed=1
  captures_passed_after_retained_analysis=1
  out_of_range_vbi_captures=0
  variable_but_bounded_vbi_captures=0
  retained_ch3_content='NOT_AVAILABLE_EXACT_ARTIFACT_MISSING'
  product_baseline_restore='PASS'
  final_pending_aio=0
  driver_unloaded=$true
  xdma_nodes_removed=$true
  locks_released=$true
  raw_captures_published=$false
  camera_images_published=$false
}
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_STATE.json' ($state | ConvertTo-Json -Depth 5)

# Publish task-local source and the small raw text receipts needed to audit the
# distinction between the controller deployment failure and retained-byte PASS.
$sourceNames = @(
  'validate_nvp_capture_r3r2.py',
  'vbi_tail_contract_r3r2.py',
  'abi_v1_r3r2.py',
  'abi_v1.py',
  'analyze_nvp_video_diag1.py',
  'frame_reconstruct_nvp_capture.py',
  'availability_classifier_r3r2.py',
  'controller_nvp_capture_r3r2.py',
  'controller_nvp_video_diag1_r3r2.py',
  'generate_r3r2_matrix.ps1',
  'assemble_r3r2_evidence.ps1',
  'test_r3r2_validator.py',
  'test_r3r2_host_controllers.py',
  'V41_C2H_TRANSPORT_ABI_V1.json'
)
foreach ($name in $sourceNames) {
  Copy-Item -LiteralPath (Join-Path $scripts $name) -Destination (Join-Path $EvidenceDirectory ('source\'+$name))
}
Copy-Item -LiteralPath (Join-Path $contracts 'V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json') -Destination (Join-Path $EvidenceDirectory 'source\V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.json')
Copy-Item -LiteralPath (Join-Path $contracts 'V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.md') -Destination (Join-Path $EvidenceDirectory 'source\V41_NVP_DIAG_ROUTE_SPECIFIC_VBI_TAIL_CONTRACT_V1.md')

$rawCopies = @{
  'session-01-controller-result.json'=(Join-Path $remote 'logs\session-01-r1-ch1\controller-result.json')
  'session-01-validation-result.json'=(Join-Path $remote 'logs\session-01-r1-ch1\validation-result.json')
  'session-01-pixel-statistics.json'=(Join-Path $remote 'images\session-01-r1-ch1\pixel-statistics.json')
  'scan-controller-result.json'=(Join-Path $remote 'logs\scan-controller-result.json')
  'runtime-identity.json'=(Join-Path $remote 'logs\mmio-sanity\runtime-identity.json')
  'mmio-sanity-result.json'=(Join-Path $remote 'logs\mmio-sanity\r3r2-mmio-sanity-result.json')
  'final-cleanup.json'=(Join-Path $remote 'logs\final-cleanup.json')
  'capture-sequence-analysis.csv'=(Join-Path $remote 'logs\session-01-r1-ch1\capture-sequence-analysis.csv')
  'stream-continuity-metrics.csv'=(Join-Path $remote 'logs\session-01-r1-ch1\stream-continuity-metrics.csv')
  'quiescence-samples.csv'=(Join-Path $remote 'logs\session-01-r1-ch1\quiescence-samples.csv')
}
foreach ($entry in $rawCopies.GetEnumerator()) {
  Copy-Item -LiteralPath $entry.Value -Destination (Join-Path $EvidenceDirectory ('raw-text-evidence\'+$entry.Key))
}

$allFiles = @(Get-ChildItem -LiteralPath $EvidenceDirectory -Recurse -File | Sort-Object FullName)
$indexLines = [Collections.Generic.List[string]]::new()
$indexLines.Add('# Evidence Index')
$indexLines.Add('')
$indexLines.Add('Engineering gate: **FAIL**. Publication scope is sanitized and append-only.')
$indexLines.Add('')
foreach ($file in $allFiles) {
  $relative = [IO.Path]::GetRelativePath($EvidenceDirectory,$file.FullName).Replace('\','/')
  $indexLines.Add("- ``$relative``")
}
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_EVIDENCE_INDEX.md' ($indexLines -join "`n")

$manifestLines = [Collections.Generic.List[string]]::new()
foreach ($file in @(Get-ChildItem -LiteralPath $EvidenceDirectory -Recurse -File | Where-Object {$_.Name -ne 'G2B_NVP_VIDEO_DIAG1_R3R2_SHA256_MANIFEST.txt'} | Sort-Object FullName)) {
  $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
  $relative = [IO.Path]::GetRelativePath($EvidenceDirectory,$file.FullName).Replace('\','/')
  $manifestLines.Add("$hash  $relative")
}
Write-Text 'G2B_NVP_VIDEO_DIAG1_R3R2_SHA256_MANIFEST.txt' ($manifestLines -join "`n")

Write-Output "R3R2_EVIDENCE_ASSEMBLED=$EvidenceDirectory"
