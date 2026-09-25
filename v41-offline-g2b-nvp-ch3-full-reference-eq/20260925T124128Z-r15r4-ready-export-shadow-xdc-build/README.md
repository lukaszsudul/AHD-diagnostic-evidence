# AHD v41 R15R4 — firmware-only candidate stopped during synthesis

Engineering result: `BLOCKED_SYNTH_XDC_UNSUPPORTED_COMMAND`. The single authorized candidate changed only the readiness status export and a local shadow timing constraint. Vivado 2025.2 issued two Critical Warnings (`Designutils 20-1307`) because `if` is unsupported inside the versioned XDC. The one synthesis attempt was stopped without a completed post-synth checkpoint. ExploreArea, placement, routing, post-route physical optimization and bitgen were not run. No DCP or bitstream was produced; no new CDC/timing/LUT conclusion is claimed.

Base source `e32dae86af20fa5c385026397b7042d8b1dafcd4`; candidate source `b7937abf3d63d253d77aa74c9b0630b1324fde7a`, tree `eaad0af366b770d813d94fb3770c04444b93700a`. The frozen full EQ scope, FEQ1, ABI, host source and microcode were not changed. Linux reader work was deferred by Owner. No functional tests or DUT contact occurred. Historical R15R2 remains blocked at final timing.

A further candidate requires separate authorization to move the selector assertions out of XDC into the build validation step, then repeat synthesis and implementation. This result is not a firmware release or product qualification.
