# CONT1R3R3 generation log excerpt

Selected verbatim markers from the private task-local Vivado 2025.2 log and launcher output; the complete log/journal remain private. The public task-local Tcl and launcher sources identify the exact command sequence.

```text
CONT1R3R3_OPENED_PART=xc7a35tcsg325-2
CONT1R3R3_OPENED_TOP=ahd_capture_top_xdma
CONT1R3R3_ROUTE_GATE=38667/38667;ERRORS=0
CONT1R3R3_DRC_GATE=0_ERRORS;0_CRITICAL_WARNINGS;24_ACCEPTED_ORDINARY_WARNINGS
CONT1R3R3_WRITE_BITSTREAM_BEGIN
Running DRC as a precondition to command write_bitstream
INFO: [Vivado 12-3199] DRC finished with 0 Errors
INFO: [Designutils 20-2272] Running write_bitstream with 2 threads.
INFO: [Vivado 12-1842] Bitgen Completed Successfully.
8 Infos, 0 Warnings, 0 Critical Warnings and 0 Errors encountered.
write_bitstream completed successfully
CONT1R3R3_WRITE_BITSTREAM_COMPLETED
CONT1R3R3_VIVADO_EXIT_CODE=0
```

The session startup also logged the previously observed `[Runs 36-547]` duplicate user-strategy name discard. The DCP open logged an informational `general.maxThreads` mismatch between stored checkpoint parameters and current Vivado settings. Neither was a design command or a bitgen warning. No full log, checkpoint, bitstream or tool binary is public.
