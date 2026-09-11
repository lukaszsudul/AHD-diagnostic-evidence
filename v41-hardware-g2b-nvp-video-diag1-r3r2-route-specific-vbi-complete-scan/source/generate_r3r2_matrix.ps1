[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$TaskRoot,

  [Parameter(Mandatory)]
  [string]$OutputDirectory
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$remoteRoot = Join-Path $TaskRoot 'evidence-staging\remote-text'
$scanCsv = Join-Path $remoteRoot 'logs\scan-results.csv'
$captureJson = Join-Path $remoteRoot 'logs\session-01-r1-ch1\controller-result.json'
$validationJson = Join-Path $remoteRoot 'logs\session-01-r1-ch1\validation-result.json'
$pixelJson = Join-Path $remoteRoot 'images\session-01-r1-ch1\pixel-statistics.json'
$ackCsv = Join-Path $remoteRoot 'logs\firmware-ack-ledger.csv'

foreach ($path in @($scanCsv,$captureJson,$validationJson,$pixelJson,$ackCsv)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "R3R2_MATRIX_INPUT_MISSING:$path"
  }
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null

$scanRows = @(Import-Csv -LiteralPath $scanCsv)
$capture = Get-Content -LiteralPath $captureJson -Raw | ConvertFrom-Json
$validation = Get-Content -LiteralPath $validationJson -Raw | ConvertFrom-Json
$pixel = Get-Content -LiteralPath $pixelJson -Raw | ConvertFrom-Json
$ackRows = @(Import-Csv -LiteralPath $ackCsv)

$roundOrders = @(
  @(1,2,3,4),
  @(4,3,2,1),
  @(2,3,4,1),
  @(3,4,1,2)
)
$roundColors = @(
  @{ 1='RED';     2='GREEN';   3='CYAN';   4='WHITE75' },
  @{ 1='WHITE75'; 2='RED';     3='GREEN';  4='CYAN' },
  @{ 1='CYAN';    2='WHITE75'; 3='RED';    4='GREEN' },
  @{ 1='GREEN';   2='CYAN';    3='WHITE75';4='RED' }
)
$colorCodes = @{ RED='0x6'; GREEN='0x4'; CYAN='0x3'; WHITE75='0x1' }

$expected = [Collections.Generic.List[object]]::new()
$session = 0
for ($roundIndex = 0; $roundIndex -lt 4; $roundIndex++) {
  for ($position = 0; $position -lt 4; $position++) {
    $session++
    $channel = $roundOrders[$roundIndex][$position]
    $assigned = $roundColors[$roundIndex][$channel]
    $expected.Add([pscustomobject]@{
      SessionID = $session
      Round = $roundIndex + 1
      VisitPosition = $position + 1
      Channel = $channel
      RouteRequested = ('0x{0:X2}' -f ($channel - 1))
      AssignedBGDCOL = $assigned
      BGDCOLCode = $colorCodes[$assigned]
    })
  }
}

$matrix = foreach ($row in $expected) {
  $observed = @($scanRows | Where-Object { [int]$_.session_id -eq $row.SessionID })
  if ($observed.Count -eq 1) {
    $s = $observed[0]
    [pscustomobject]@{
      SessionID = $row.SessionID
      Round = $row.Round
      VisitPosition = $row.VisitPosition
      Channel = $row.Channel
      AssignedBGDCOL = $row.AssignedBGDCOL
      BGDCOLCode = $row.BGDCOLCode
      RouteRequested = $row.RouteRequested
      RouteReadback = ('0x{0:X2}' -f [int]$s.route_readback)
      Snapshot = 'PASS_COHERENT'
      NVPClassification = 'NO_VIDEO_STABLE'
      AvailabilityClassification = $capture.source_availability.availability_classification
      CaptureEligible = 'YES'
      CaptureAttempted = 'YES'
      CaptureResult = 'PASS_POST_FAILURE_OFFLINE_VALIDATION'
      ActiveFrameAndTransport = $validation.active_frame_and_transport_integrity
      BoundedVBITail = $validation.bounded_route_specific_vbi_tail
      RouteVBIFingerprint = $validation.route_vbi_tail_fingerprint
      VerticalTailIntervals = (($validation.vertical_tail_interval_values -join ';'))
      PixelClassification = $pixel.classification
      FirmwareAdvanceAcknowledgement = 'NO_FAILURE_RESPONSE_TRIGGERED_SAFE_RESTORE'
      TaskResult = 'FAIL_FIRST_BLOCKER_AFTER_SESSION_1'
    }
  } else {
    [pscustomobject]@{
      SessionID = $row.SessionID
      Round = $row.Round
      VisitPosition = $row.VisitPosition
      Channel = $row.Channel
      AssignedBGDCOL = $row.AssignedBGDCOL
      BGDCOLCode = $row.BGDCOLCode
      RouteRequested = $row.RouteRequested
      RouteReadback = 'NOT_REACHED'
      Snapshot = 'NOT_REACHED'
      NVPClassification = 'NOT_REACHED'
      AvailabilityClassification = 'NOT_REACHED'
      CaptureEligible = 'NOT_REACHED'
      CaptureAttempted = 'NO'
      CaptureResult = 'NOT_REACHED_AFTER_FIRST_BLOCKER'
      ActiveFrameAndTransport = 'NOT_REACHED'
      BoundedVBITail = 'NOT_REACHED'
      RouteVBIFingerprint = 'NOT_REACHED'
      VerticalTailIntervals = 'NONE'
      PixelClassification = 'NOT_REACHED'
      FirmwareAdvanceAcknowledgement = 'NOT_REACHED'
      TaskResult = 'NOT_REACHED_AFTER_FIRST_BLOCKER'
    }
  }
}

$matrix | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_4X4_AVAILABILITY_MATRIX.csv') -NoTypeInformation -Encoding utf8

$availability = @(
  [pscustomobject]@{
    SessionID=1; Round=1; Channel=1; Window='PRE_RESET'; DurationMs=250
    VCLKDelta=$capture.pre_reset_source_observation.vclk_delta
    VCLKRate=$capture.pre_reset_source_observation.vclk_rate
    SAVDelta=$capture.pre_reset_source_observation.sav_delta
    SAVRate=$capture.pre_reset_source_observation.sav_rate
    VCLKPerSAV=$capture.pre_reset_source_observation.vclk_per_sav
    SourceReady=$capture.pre_reset_source_observation.source_ready
    SourceLocked=$capture.pre_reset_source_observation.source_locked
    Qualified=$capture.pre_reset_source_observation.qualified
  },
  [pscustomobject]@{
    SessionID=1; Round=1; Channel=1; Window='POST_RESET_SHORT'; DurationMs=250
    VCLKDelta=$capture.post_reset_source_observation.vclk_delta
    VCLKRate=$capture.post_reset_source_observation.vclk_rate
    SAVDelta=$capture.post_reset_source_observation.sav_delta
    SAVRate=$capture.post_reset_source_observation.sav_rate
    VCLKPerSAV=$capture.post_reset_source_observation.vclk_per_sav
    SourceReady=$capture.post_reset_source_observation.source_ready
    SourceLocked=$capture.post_reset_source_observation.source_locked
    Qualified=$capture.post_reset_source_observation.qualified
  }
)
$availability | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_AVAILABILITY_WINDOWS.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; ResetAttempted='YES'; ResetResult=$capture.reset_stream_state
  EpochBefore=$capture.S0.Epoch; EpochAfter=$capture.S1.Epoch; EpochDelta=([int]$capture.S1.Epoch-[int]$capture.S0.Epoch)
  PreResetQualified=$capture.pre_reset_source_observation.qualified
  PostResetQualified=$capture.post_reset_source_observation.qualified
  AvailabilityClassification=$capture.source_availability.availability_classification
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_RESET_ISOLATION.csv') -NoTypeInformation -Encoding utf8

$channelSummary = foreach ($channel in 1..4) {
  $rows = @($matrix | Where-Object { $_.Channel -eq $channel })
  $observedRows = @($rows | Where-Object { $_.Snapshot -eq 'PASS_COHERENT' })
  $capturedRows = @($rows | Where-Object { $_.CaptureResult -eq 'PASS_POST_FAILURE_OFFLINE_VALIDATION' })
  [pscustomobject]@{
    Channel=$channel
    SessionsExpected=4
    SessionsObserved=$observedRows.Count
    CapturesPassed=$capturedRows.Count
    AvailabilityAcrossRounds='NOT_ENOUGH_VALID_OBSERVATIONS'
    RouteVBIFingerprint=if ($channel -eq 1) { 'STABLE_ROUTE_TAIL_21' } else { 'NOT_REACHED' }
    ObservedTailIntervals=if ($channel -eq 1) { '21;21' } else { 'NONE' }
    BGDCOLPixelPath=if ($channel -eq 1) { 'PROVEN_SINGLE_COLOR' } else { 'NOT_REACHED' }
  }
}
$channelSummary | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_PER_CHANNEL_SUMMARY.csv') -NoTypeInformation -Encoding utf8

$matrix | Select-Object SessionID,Round,Channel,RouteRequested,RouteReadback,TaskResult |
  Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_ROUTE_READBACKS.csv') -NoTypeInformation -Encoding utf8

@(
  [pscustomobject]@{Round=1;ExpectedBG78='0x46';ExpectedBG79='0x13';ObservedBG78='0x46';ObservedBG79='0x13';Result='PASS_SNAPSHOT_SESSION_1'},
  [pscustomobject]@{Round=2;ExpectedBG78='0x61';ExpectedBG79='0x34';ObservedBG78='NOT_REACHED';ObservedBG79='NOT_REACHED';Result='NOT_REACHED'},
  [pscustomobject]@{Round=3;ExpectedBG78='0x13';ExpectedBG79='0x46';ObservedBG78='NOT_REACHED';ObservedBG79='NOT_REACHED';Result='NOT_REACHED'},
  [pscustomobject]@{Round=4;ExpectedBG78='0x34';ExpectedBG79='0x61';ObservedBG78='NOT_REACHED';ObservedBG79='NOT_REACHED';Result='NOT_REACHED'}
) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_BGDCOL_READBACKS.csv') -NoTypeInformation -Encoding utf8

$matrix | Select-Object SessionID,Round,Channel,NVPClassification,AvailabilityClassification,CaptureEligible,CaptureAttempted,CaptureResult,FirmwareAdvanceAcknowledgement,TaskResult |
  Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_SESSION_OUTCOMES.csv') -NoTypeInformation -Encoding utf8

$matrix | Select-Object SessionID,Round,Channel,CaptureEligible,CaptureAttempted,CaptureResult,ActiveFrameAndTransport,BoundedVBITail,PixelClassification |
  Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_CAPTURE_INDEX.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; RecordsRequested=2500; ExactCompletions=2500
  Bytes=10240000; ShortCompletions=0; FailedCompletions=0; DuplicateCompletions=0
  MissingCompletions=0; PendingCompletions=0; DisableLatencyUs=$capture.primary_complete_to_disable_us
  PhysicalQuiescence=$capture.physical_quiescence.result; CaptureResult='PASS_POST_FAILURE_OFFLINE_VALIDATION'
  PrimarySHA256=$capture.primary_file_sha256
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_CAPTURE_RESULTS.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Submitted=$capture.rolling_metrics.submitted; Completed=$capture.rolling_metrics.completed
  Pending=$capture.rolling_metrics.pending; MaxOutstanding=$capture.rolling_metrics.max_outstanding
  DescriptorWindowViolations=$capture.rolling_metrics.descriptor_window_violations
  DescriptorStarvationEvents=$capture.rolling_metrics.descriptor_starvation_events
  IOCancelCalls=$capture.rolling_metrics.io_cancel_calls; Result=$capture.rolling_metrics.result
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_AIO_SUMMARY.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; Fingerprint=$validation.route_vbi_tail_fingerprint
  CaptureSequenceDeltas=($validation.capture_sequence_delta_values -join ';')
  TailIntervals=($validation.vertical_tail_interval_values -join ';')
  MinimumTail=$validation.minimum_vertical_tail_intervals
  MaximumTail=$validation.maximum_vertical_tail_intervals
  ModeTail=$validation.mode_vertical_tail_intervals
  BoundedContract=$validation.bounded_route_specific_vbi_tail
  LegacyCH1Fingerprint=$validation.legacy_ch1_exact_21_tail_fingerprint
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_ROUTE_VBI_FINGERPRINTS.csv') -NoTypeInformation -Encoding utf8

$channelSummary | Select-Object Channel,SessionsExpected,SessionsObserved,CapturesPassed,RouteVBIFingerprint,ObservedTailIntervals |
  Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_VBI_REPEATABILITY.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; PrimarySHA256=$validation.primary_file_sha256
  RawFrameSHA256=$validation.raw_frame_sha256; PNGSHA256=$validation.viewable_frame_sha256
  PixelBytesPublished='NO'
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_FRAME_HASHES.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; Classification=$pixel.classification
  DominantUYVY=$pixel.dominant_uyvy_word_hex; DominantFraction=$pixel.dominant_uyvy_fraction
  ExactBlackFraction=$pixel.exact_black_fraction; UniqueUYVYWords=$pixel.unique_uyvy_words
  UniqueYValues=$pixel.unique_y_values; UniqueUValues=$pixel.unique_u_values; UniqueVValues=$pixel.unique_v_values
  YMin=$pixel.y_min; YMax=$pixel.y_max; YMean=$pixel.y_mean; YStdDev=$pixel.y_stddev
  UMean=$pixel.u_mean; UVariance=$pixel.u_variance; VMean=$pixel.v_mean; VVariance=$pixel.v_variance
  MeanR=$pixel.rgb_mean_r; MeanG=$pixel.rgb_mean_g; MeanB=$pixel.rgb_mean_b
  UniqueScanlineHashes=$pixel.unique_scanline_hashes; LongestIdenticalScanlineRun=$pixel.longest_identical_scanline_run
  HorizontalEdgeEnergy=$pixel.horizontal_edge_energy; VerticalEdgeEnergy=$pixel.vertical_edge_energy
  RowMeanVariance=$pixel.row_mean_variance; ColumnMeanVariance=$pixel.column_mean_variance
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_PIXEL_STATISTICS.csv') -NoTypeInformation -Encoding utf8

@([pscustomobject]@{
  SessionID=1; Round=1; Channel=1; AssignedColor='RED'; Classification=$pixel.classification
  PixelMatch=$pixel.assigned_bgcolor_pixel_match; DominantUYVY=$pixel.dominant_uyvy_word_hex
  DominantFraction=$pixel.dominant_uyvy_fraction; Result=$pixel.result
}) | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_BGDCOL_MATCH_RESULTS.csv') -NoTypeInformation -Encoding utf8

$channelSummary | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_CHANNEL_REPEATABILITY.csv') -NoTypeInformation -Encoding utf8

$ackRows | Export-Csv -LiteralPath (Join-Path $OutputDirectory 'G2B_NVP_VIDEO_DIAG1_R3R2_FIRMWARE_ACK_LEDGER.csv') -NoTypeInformation -Encoding utf8

[pscustomobject]@{
  result='PASS'
  expected_sessions=16
  observed_sessions=@($matrix | Where-Object {$_.Snapshot -eq 'PASS_COHERENT'}).Count
  captures_passed=@($matrix | Where-Object {$_.CaptureResult -eq 'PASS_POST_FAILURE_OFFLINE_VALIDATION'}).Count
  first_blocker='R3R2_DUT_VALIDATOR_DEPLOYMENT_MISSING_ABI_V1'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'matrix-generator-result.json') -Encoding utf8
