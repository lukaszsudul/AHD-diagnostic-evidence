# R2 Review — Frame-Rate Measurement Chain

## Verdict

- Primary result: `MEASUREMENT_ARTIFACT_PROBABLE`
- Confidence: `HIGH`
- Integer/event-window quantization: `CONFIRMED`
- Explicit software `+1`: `NOT PRESENT`
- Torn counter read: `REJECTED BY SOURCE-LEVEL CDC STRUCTURE`
- Real approximately 4% video-rate change: `NOT SUPPORTED`, but not absolutely excluded without an independent external timing instrument

The frozen chain is a valid video-progress indicator. Its approximately one-second window is not a valid `±0.10 Hz` discriminator: one event changes the result by about `0.992 Hz`.

## Frozen source identity inspected

The frame path was inspected read-only in the clean exact-C3/R1i source:

- commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- C3 bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`

C1/C2 build manifests bind the same frame-path files; their synthesizable delta is confined to `rtl/nvp/nvp6134c_i2c_bringup.vhd`.

| Source | SHA-256 |
|---|---|
| `rtl/top/ahd_capture_top_xdma.sv` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| `rtl/video/physical_frontend.sv` | `7CEAA64771A8484CF5608559A0B4A51FDA4D0A9761D80B48FFD806BBFB23B6AE` |
| `rtl/video/video_capture.sv` | `7DFB7253C6649885665DB8449E33CE2F31D584811586DAEAA746DE04DF4AFFC9` |
| `rtl/record/bt656_record_producer.sv` | `96ECA58AC2FE6D9A2E0A390076FA02370B85409F1F1353CB9F41784D2ED363EE` |
| `rtl/record/capture_mailbox.sv` | `91A55EC1DEE546F026E3DC92F04A788A779F8A3F8D9D3D8DABEF08F089CA3FF5` |
| `rtl/v41/control_status_regs.sv` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |
| `xdc/common/cdc.xdc` | `E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62` |
| `scripts/v41/r1i_build.tcl` | `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F` |
| `scripts/v41/read_nvp_r1i.py` | `E217F3BE39CFF3A04178487EF8C4B2780DB8421CAFDB47A347DE31A65F080934` |
| `scripts/v41/read_nvp_r1f.py` | `5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C` |
| `r1i_telemetry_stdout_payload.py` | `6FF653FF6E1184FD143F99E99F9EBF491AFE1381DE35C406AF95CBDB83DA8636` |
| runtime telemetry payload | `74D89D5D285F3F786F5BAF7852049199D1B6764855AB00CE097624633391299F` |
| `R1iTelemetryTransport.ps1` | `62AD2DD6F0CEB0B3AEEB3D89FF9C2276D06663668EF388647CBD5ACA9308B11E` |
| `Invoke-R2CandidateTelemetryCapture.ps1` | `AF446AFB19704DBB6454BCCA5EF367AD52898F288E325F5B9411426126DFFA1D` |
| `R2PrimaryCampaignOrchestratorCommon.ps1` | `7D63BFD9CC1BBE3BFF5ED8819470380EB5E5910E3B2C816D643CA61B2336B49E` |

## End-to-end chain

### 1. Physical video event

`physical_frontend.sv:40-44,125-185` captures VDO1 through IBUF/IDELAY/IDDR and transfers it into the `nvp_clk` domain driven by the NVP VCLK input.

`bt656_record_producer.sv:192-211` recognizes a valid `FF 00 00 XY` TRS marker. It derives `H` from `XY[4]` and `V` from `XY[5]`.

### 2. What the counter actually counts

In steady state, the 32-bit `frame_seq_v` counter increments at `bt656_record_producer.sv:276-295` only when all of these are true:

- video is enabled;
- the producer is idle;
- the marker is SAV (`H=0`);
- the marker is active video (`V=0`);
- the preceding SAV had `V=1`.

It therefore counts the vertical-blank-to-active transition: a start-of-active-frame event for progressive video. It does **not** count completed frames, frame ends, every SAV, EAV, record commits, or video-valid transitions. Because the field bit is not part of this qualification, interlaced input would make it a field-start surrogate.

There is one reset exception: `prev_sav_v` initializes to `1` at line 173, so the first valid post-reset `H=0,V=0` SAV increments the counter even if no `V=1` SAV has yet been observed. That synthetic initial event is already in the absolute pre-T0 count for these runs and cancels from T1−T0; it could matter only if reset occurred inside a measurement window, which the monotonic raw captures do not show.

The separate counter named `active_sav_candidate_count` increments at lines 192-193 on every valid `H=0` SAV, regardless of the marker's `V` bit. It is therefore an all-SAV counter, including vertical-blank and active-video lines, despite its internal name. The record-commit counter is separate again.

### 3. Reset, epoch, and wrap behavior

- width: 32 bits;
- increment clock domain: `nvp_clk`;
- reset: NVP/PCIe application reset and FPGA reconfiguration;
- no video-lock-specific clear;
- no MMIO command clears `frame_seq_v`;
- absolute events before T0 cancel in the T1−T0 delta;
- wrap handling: host arithmetic applies modulo `2^32`.

At 25 events/s the frame counter wraps after about 5.45 years. A single wrap inside the short window is handled correctly. Candidate programming and Formal restoration reconfigure/reset the counter rather than preserving an epoch across images.

### 4. CDC and MMIO

`capture_mailbox.sv:63-82,97-128,172-178,182-228` places `frame_seq_v` in bits `[131:100]` of a held 324-bit bundled-data request/ack mailbox. The source holds the full bundle, toggles a request, the request crosses two synchronizer stages, the destination captures the full held bundle, and an acknowledgement returns. The destination exposes one registered 32-bit word; there is no split low/high read.

MMIO offsets are:

| Counter | Offset |
|---|---:|
| frame start sequence | `0x0060` |
| VCLK edges | `0x0080` |
| all valid SAV (`H=0`) events | `0x0084` |
| record commits | `0x0088` |

`video_capture.sv:143-200` and `ahd_capture_top_xdma.sv:429-448` implement the VCLK/SAV Gray crossings. `video_capture.sv:210-306`, `ahd_capture_top_xdma.sv:912-990`, and `control_status_regs.sv:116-157,205-227` carry and register the MMIO words. See `R2_REVIEW_COUNTER_CDC_AUDIT.md`.

### 5. Host read and sampling window

`read_nvp_r1f.py:129-158` and the remote payload open `/dev/xdma0_user` with `O_RDONLY|O_CLOEXEC` and read each counter with one four-byte little-endian `pread`. There is no mmap, ioctl, MMIO write, or DMA.

`r1i_telemetry_stdout_payload.py:28-59` records `time.monotonic()` immediately before and after each relevant `pread` and uses the midpoint. Lines 93-113 take the two inventories around `time.sleep(1.0)`; lines 150-160 compute the modulo delta and rate. It then:

1. collects a complete 1,532-read T0 inventory;
2. calls `time.sleep(1.0)`;
3. collects a complete 1,532-read T1 inventory.

For a counter `c`:

```text
t0_mid = (t0_before + t0_after) / 2
t1_mid = (t1_before + t1_after) / 2
elapsed = t1_mid - t0_mid
delta = (t1_uint32 - t0_uint32) & 0xFFFFFFFF
rate = delta / elapsed
```

SSH latency, process startup, and the wall-clock capture timestamp are outside the denominator. Scheduler delay, sleep overshoot, inventory traversal, and MMIO-read latency are included through the actual counter-specific monotonic midpoints.

Each snapshot took about 6.9–8.5 ms. The frame-specific interval includes the remaining T0 inventory, the requested sleep, and the short T1 prefix, giving `1.007711409–1.008668054 s`.

### 6. Formatting and frozen classification

`Invoke-R2CandidateTelemetryCapture.ps1:329-335` consumes the unrounded JSON double and applies:

```text
abs(frame_rate - 24.803727) <= 0.10
```

Lines 367-408 apply classification; lines 508-515 round the receipt to six decimal places only after classification. An otherwise-clean video run outside that band becomes `INCONCLUSIVE`; `R2PrimaryCampaignOrchestratorCommon.ps1:1604-1615` invokes `C3_NON_CLEAN_SUSPEND_BLOCK` for a non-clean C3.

## Exact independent recalculation

All ten aggregate raw captures survive locally. Each aggregate file's SHA-256 exactly equals `RAW_CAPTURE_SHA256` in its capture receipt at evidence commit `a9461192e887db154bef911e2bcbae679cf7dd51`. The linked copies in `audit/linked_raw_captures/` therefore retain a cryptographic binding to the immutable historical package.

| Seq. | Cell | Frame delta | Actual midpoint interval (s) | Recalculated Hz | Published Hz |
|---:|---|---:|---:|---:|---:|
| 1 | C0 | 0 | 1.0079256505 | 0 | 0.000000 |
| 2 | C1 | 26 | 1.0079279000 | 25.7954958881 | 25.795496 |
| 3 | C3 | 25 | 1.0080975955 | 24.7991862213 | 24.799186 |
| 4 | C2 | 25 | 1.0077114090 | 24.8086900443 | 24.808690 |
| 5 | C1 | 26 | 1.0079537005 | 25.7948356032 | 25.794836 |
| 6 | C2 | 26 | 1.0078361605 | 25.7978439542 | 25.797844 |
| 7 | C0 | 0 | 1.0079740525 | 0 | 0.000000 |
| 8 | C3 | 25 | 1.0078723225 | 24.8047291724 | 24.804729 |
| 9 | C2 | 25 | 1.0078171540 | 24.8060869978 | 24.806087 |
| 10 | C3 | 26 | 1.0086680540 | 25.7765673225 | 25.776567 |

Every six-decimal publication value matches independent raw-data recalculation after ordinary rounding. Full details and hashes are in `R2_REVIEW_FRAME_RATE_RECALCULATION.csv`.

## Quantization result

For a periodic approximately 25 Hz event stream and the observed windows:

```text
25 × T = 25.192785…25.216701 events
```

Unknown sample phase therefore yields exactly 25 or 26 events. The corresponding predicted ranges are:

```text
N=25: 24.785161…24.808690 Hz
N=26: 25.776567…25.801038 Hz
```

They completely contain both observed populations. There is no software `+1`; the extra count is legitimate endpoint inclusion caused by sample phase. A coherent boundary read may return the old or new whole counter value, which is the same one-event endpoint effect, not corruption.

## Independent cadence corroboration

Across the eight video-positive runs:

- VCLK remains approximately `148.500 MHz`;
- all-SAV cadence remains approximately `28,125 events/s`;
- `SAV/1125` spans `24.999682481–25.001494250 Hz`, mean `25.000153245 Hz`.

The division by 1,125 is justified only under the independently qualified 1,125-total-line video mode; the counter itself does not infer or prove that mode.

The frame populations differ by `3.9771%`; their mean SAV and VCLK rates differ by only about `25.9 ppm` and `7.76 ppm`. This strongly opposes a real approximately 4% source-rate transition.

## Chain conclusion

The displayed 24.8/25.8 split is numerically explained by confirmed one-count quantization of a short host window that is not phase-locked to frame events. The primary physical interpretation remains `MEASUREMENT_ARTIFACT_PROBABLE`, not absolute confirmation, because the evidence has no external source log, direct VSYNC timestamp stream, or independent video-frequency instrument.
