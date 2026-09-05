# Throughput architecture feasibility

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


Architecture result PASS for selected SYNTHETIC_RECORD datapath; measured throughput NOT_TESTED. Required decimal application rate=288000000bytes/s. Payload fraction3840/4096=0.9375. Required transport=307200000bytes/s and75000records/s. AXI64 at62.5MHz gives500000000bytes/s raw. Required sustained acceptance=61.44% of raw cycles.

Selected producer writes all488 stored64-bit words in488 ticks. Freeze a service bound of<=16 extra writer ticks per record when a slot is available; writer capacity >=62500000/(488+16)=124007.94records/s. Common formatter emits512 accepted beats and has<=32 non-stall preparation/grant/release overhead ticks per synthetic record: >=62500000/(512+32)=114889.71records/s,470588235.29 transport bytes/s and441176470.59 payload bytes/s. Producer and formatter overlap using distinct slots and separate RAM ports; do NOT add504+544 as serialized time. Four slots provide elasticity; a synchronous ready descriptor FIFO/prefetch and generation check must meet this bound. Explicitly test no-stall service intervals and TREADY stalls in DIAG1.

At target rate833.333 AXI ticks/record are available, versus544 non-stall ticks; thus bounded internal overhead cannot impose a ceiling below307.2MB/s. The64-bit PRBS transformation must sustain one write/tick after pipeline fill. A byte-serial orbit-serial PRBS producer would fail. MAX_RATE record mode never traverses synthetic video parser or NVP domain.

Actual PCIe Gen2 x1 efficiency, XDMA descriptor supply, Linux scheduling, DMA buffers and storage can reduce throughput. Current PRODUCT evidence only establishes configured AXI clock/link design and offline timing; it does not establish hardware payload. T3 must measure payload from completed records separately from4096-byte transport with explicit elapsed timestamps, no rounding288 downward and no hidden dropped records.
