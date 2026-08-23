# Post-route continuation hard stop

CLASSIFICATION=BLOCKED_SINGLE_POST_ROUTE_CONTINUATION_TOP_IDENTITY_HARNESS_MISMATCH

The one authorized continuation session opened the exact frozen routed DCP in
Vivado 2025.2. The checkpoint reported the correct device part
`xc7a35tcsg325-2` and had been created by the same Vivado build. Before the
remaining report tail, the task-local harness queried the current design
object's `NAME` property. Vivado returned the checkpoint design-object name
`checkpoint_PHASE3_routed`; the harness incorrectly required the source RTL
top identifier `ahd_capture_top_xdma` in that property and exited with code 1.

The failure happened before:

- the routed-DCP IOBUF query;
- the corrected per-object property reports;
- the remaining post-route reports;
- `write_bitstream`.

Measured command accounting:

```text
POST_ROUTE_CONTINUATION_SESSIONS=1
OPEN_CHECKPOINT_EXECUTIONS=1
WRITE_BITSTREAM_ATTEMPTS=0
BITSTREAM_PRODUCED=NO
```

The owner authorization permits only one continuation session and explicitly
forbids rerunning when a continuation report/check fails. Therefore the script
was not patched or rerun, no FPGA was programmed, and the hardware campaign was
not entered. The shared heavy-build lock was released.

