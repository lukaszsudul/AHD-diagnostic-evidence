# Raw evidence disposition

`structural/` contains the completed object inventories and three bounded original-scope path queries from the sealed DCP. Each path query has matching start/completion markers and a complete CSV. The worker later failed while attempting to pass a Tcl collection string into the candidate phase; `WORKER_FAILED.marker` preserves that fail-closed harness event. The later failure does not invalidate the already completed structural CSVs and no candidate conclusion was taken from that session.

`candidate/` contains a clean serialized continuation. It reopened the identical sealed DCP, applied the exact candidate hash recorded in `INPUT_HASHES.txt`, resolved all collections, passed all nine family checks and three focused timing reports, dispositioned the focused methodology findings, and ended with `WORKER_COMPLETED.marker` status PASS.

No raw directory contains a Groups 15-17 global `report_bus_skew` invocation. No synthesis, implementation, routing, bitstream, or hardware command was executed.
