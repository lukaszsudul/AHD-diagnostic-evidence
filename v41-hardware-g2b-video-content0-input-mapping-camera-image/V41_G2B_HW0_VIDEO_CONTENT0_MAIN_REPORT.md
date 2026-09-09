
# AHD v41 G2B-HW0 VIDEO-CONTENT0 main report

Engineering gate: PASS

Overall result: PASS_DIAGNOSIS_COMPLETE_NVP_STATUS_OR_ROUTING_ACCESS_UNAVAILABLE

The exact FIX1-R1 PRODUCT image and qualified rolling capture path were reused
without FPGA programming or source change. Runtime identity and source
readiness passed. One new capture produced 2500/2500 structurally integral
records, sequence 0..2499 without gaps, and one complete real 1920x1080 frame.
The primary window contains no overflow or malformed-preceding record.

The captured camera content did not pass. Frame 311710
is byte-for-byte the independent limited-range UYVY black reference
`3B189674E4CBA4542AF800037704EF3A5DABAD5ACF43285C19082AB776B246B0`: one UYVY word, 100.0% exact-black groups, one Y/U/V value,
Y=16 for every pixel, 1080 identical lines, and zero horizontal/vertical edge
energy. The rendered PNG was visually inspected and is uniformly black with no
visible content. Thus transport/frame structure remains PASS while
`END_TO_END_CAMERA_IMAGE = NOT_PROVEN_BLACK_SCENE_OR_FALLBACK`.

Current internal route is NVP VIN1/channel 1 -> VDO1 -> FPGA INPUT_0, but the
as-built connector/refdes feeding VIN1 is unavailable. Manufacturer/source
evidence also shows the initialization programs solid black as the no-video
background. The current PRODUCT design has no governed runtime NVP status/read
or route-write service, and no safe multi-region internal pattern was proven.
Accordingly status, pattern isolation, and channel scan were not guessed.

The exact remaining physical action is: Connect a powered, uncovered AHD 1080p25 camera aimed at a bright high-contrast target to the PCB connector electrically mapped to NVP VIN1/channel 1; first supply the missing as-built connector-to-VIN1 refdes mapping so that connector can be identified without guessing.

One pre-MMIO controller invocation was rejected by device-node permissions. It
performed no MMIO or DMA and consumed no capture session. The exact unchanged
controller was then run with device access privileges; the single hardware
capture passed. Disable latency was 330.702
us (hard gate <=500 us). A post-target-only ring tail was cleared by the
authorized reset and did not alter primary data. Cleanup passed completely.
