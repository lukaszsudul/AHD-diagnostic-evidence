# R15R3R1 — targeted CDC and physical transfer closeout

Result: `RTL_AND_CONSTRAINT_CORRECTION_REQUIRED` (proposal only; no product change). The one source-to-AXI `Unsafe` endpoint is a `CDC-10 Critical` combinational readiness-status signal before the first synchronizer, with no waiver. It is separate from the 128 reset-related frame/line shadow control endpoints retained by R15R3. The target-specific timing study found a 4.282 ns maximum routed datapath delay over the four held reset-commit bits and reachable shadow R/CE/D inputs. A 6.000 ns absolute bound is supported by the ACK-qualified source logic, but the existing constraint misses the new shadow inputs. R15R2 still has negative setup timing and no bitstream.

The targeted existing bus-skew report shows snapshot Gray actual 1.391 ns against 3.000 ns and epoch echo actual 0.991 ns against 3.000 ns. No existing bus-skew constraint applies to the held-commit-to-shadow cone; an additional relative skew limit is not required if each bit has the 6 ns absolute bound. This is source reasoning plus static analysis of a routed checkpoint, not a functional test or a measurement of board phase.

One future scoped revision is recommended: register exported readiness before its AXI synchronizer, and extend the 6 ns datapath-only constraint to the new shadow reset-control inputs. That revision would need a new build and targeted CDC/timing verification under separate authorization. No RTL, XDC, waiver, DCP, reader, build, or DUT action occurred here.

Source commit `e32dae86af20fa5c385026397b7042d8b1dafcd4`; routed DCP SHA-256 `E1E9F087810B4670A66A9F64C14F11A70A84117C966CF26EC704443DD8BA8DBD`. The historical R15R2 result remains `BLOCKED_FINAL_TIMING`; full EQ and the Linux reader remain functionally untested/deferred.
