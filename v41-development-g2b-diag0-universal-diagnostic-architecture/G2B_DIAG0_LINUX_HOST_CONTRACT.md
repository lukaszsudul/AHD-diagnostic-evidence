# Linux control and capture contract

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


Future tools only; none implemented in DIAG0. g2b-diagctl owns MMIO configuration/control/status; g2b-capture owns XDMA C2H reading, ABI validation, reconstruction and evidence. Shared small library resolves BDF/device, locks control, checks identity and MMIO versions, enforces snapshot coherency and records run manifests. No V4L2. Use64-bit off_t,size/accounting and kernel-supported DMA transfer sizes; do not request a4.4GB single32-bit transfer.

Session: open the intended XDMA user aperture and C2H device; verify full clean diagnostic identity and ABI; acquire exclusive controller lock; ensure previous stream idle/drained and remove old host buffers. Start capture with aligned4096-byte buffers before START so initial records cannot be missed. Write all relevant SHADOW values explicitly, including continuous limits for stress; perform MMIO readback/fence; write START; poll command result and ACTIVE_VALID; snapshot RUN_ID/ACTIVE/epoch. Stop/reconcile counters before closing capture. A polling status result may be cached; use SNAPSHOT_COUNTERS for coherent totals. External reset/build-identity change requires close/reopen and discarding partial buffered frames.

Representative interface:
```sh
g2b-diagctl status
g2b-diagctl run --source synthetic-record --records 1 --rate max
g2b-diagctl run --source synthetic-record --records 75000 --rate max
g2b-diagctl run --source synthetic-video --pattern xy-frame-ramp --frames 100 --rate 1080p25
g2b-diagctl run --source live --input 2 --frames 100
g2b-diagctl run --source live --input auto --scan-mask 0xf --frames 1000 --loss-policy stop
g2b-diagctl cycle --source synthetic-record --rate max --run-ms 60000 --pause-ms 60000 --cycles 0
g2b-diagctl stop --graceful
g2b-diagctl abort
g2b-capture --device <xdma-c2h-device> --output <directory> --validate
```
The cycle command above must set RECORD_LIMIT=0,FRAME_LIMIT=0,SCHEDULER_ENABLE=1. A run command sets scheduler0. Live commands require live capability and closure of B1/B2; current contract must reject them while those bits are0. Do not silently fall back to input0 or synthetic output.

Manifest contains BDF,session UUID,diagnostic and legacy source-commit tuples,bitstream provenance when available,ABI/MMIO versions,ACTIVE config,RUN_ID,CYCLE_ID,SEGMENT transitions,epoch boundaries,first/last sequences,pattern/seed formulas,monotonic start/end timestamps,counter snapshots,command/error history,invalid-frame list,file byte counts and SHA256s. RUN_ID is scoped to one FPGA session, never globally unique. Bind metadata before validating Q-derived patterns. Monitor CYCLE_EVENT_SEQUENCE and reject incomplete historical evidence if events were missed; autonomous traffic does not guarantee unlimited event logging.

Host storage for1000 frames must reserve more than4423680000bytes plus manifests (use a64-bit-capable filesystem, not a4GiB single-file limit). It may stream validated results or rotate files on record/frame boundaries. Throughput tests should separate DMA receive rate from storage rate and document buffering; slow disks can cause real live drops and invalidate exact-frame success.
