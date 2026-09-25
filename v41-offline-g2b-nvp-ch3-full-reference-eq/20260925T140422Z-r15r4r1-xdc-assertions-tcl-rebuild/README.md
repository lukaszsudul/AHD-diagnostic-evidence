# R15R4R1 — XDC assertion relocation and attempted rebuild

**Engineering result: `BLOCKED_SYNTH_XDC_EMPTY_SHADOW_TARGET`.** No checkpoint or bitstream was released.

The two unsupported `if/error` assertion blocks were moved out of XDC into ordinary Tcl. The 6.000 ns datapath-only command remained in XDC. Preflight found no remaining executable `if/error` in the active XDC files. The functional RTL is byte-identical to R15R4. During the single authorized `synth_design`, Vivado reached the implementation XDC pass and reported `CRITICAL WARNING [Vivado 12-4739]`: the `-to` target of that max-delay command contained no valid objects. Execution stopped at that first critical warning. The Tcl netlist validator was never reached. The retained log does not contain intermediate selector counts, so the precise missing cell or pin class is unproven.

Project setup took 48.277 s. One synthesis invocation started; no ExploreArea, placement, routing, physical optimization, final CDC/timing/bus-skew checks, or bit generation ran. New LUT use is not reported. The earlier R15R4 failure remains unchanged. Reader work was deferred by the Owner. No functional tests or DUT contact occurred. No firmware is available for hardware activation.

The source commit is `3376bd67a104698b6be2e4d803b4b94c984466e3`, tree `ed7223a0366c9b72325a56c0f453368154069956`. The two changed source blobs passed independent commit-pinned byte readback. The next candidate, including a real-netlist confirmation of the shadow selector and an additional build, requires separate authorization.
