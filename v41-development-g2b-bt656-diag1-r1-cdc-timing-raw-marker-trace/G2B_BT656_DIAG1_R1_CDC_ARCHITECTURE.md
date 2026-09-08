# CDC architecture

The source trace writer consumes only source-clocked registered event data. Trace entries cross to AXI through one independent-clock XPM RAM, not bitwise synchronization.

Physical RAM entry 511 carries frozen metadata. A three-stage single-bit DONE toggle crosses to AXI; AXI reads and caches the immutable metadata before publishing DONE. CLEAR, ARM, and ABORT commands use reviewed two-stage toggle synchronization into the source domain.

Synthesis audit: 7 exact first-stage synchronizer D pins, zero raw userclk1 startpoints to trace state/write logic, zero raw source-metadata paths to AXI registers, zero wide bitwise metadata synchronizers, and zero new unresolved DIAG1 Critical/Warning CDC findings.
