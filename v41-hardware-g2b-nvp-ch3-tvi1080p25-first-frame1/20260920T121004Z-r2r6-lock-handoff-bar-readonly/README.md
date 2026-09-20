# AHD v41 CH3 R2R6 — lock handoff and bounded BAR read-only check

## Result

- Engineering gate: `PASS_SCOPED_BAR_READONLY_CHECK`
- BAR check: `PASS_24_DURABLY_LOGGED_READS`
- PREPARE / ONESHOT / capture: `NOT_EXECUTED`
- Cleanup: `PASS_MODULE_UNLOADED_NO_NODES_HANDLES_OR_MAPPINGS`
- Locks: `RELEASED`

The exact qualified `xdma_ahd_pcie` module was loaded once and unloaded once. The
fresh binding chain established `/dev/xdma0_user` (`dev_t 511:0`) →
`0000:01:00.0` → driver user BAR index 0 → physical BAR0 at `0xF6E00000`,
length `0x20000`. Offset `0x12400` therefore translated to `0xF6E12400` and was
inside the selected BAR.

All 24 planned 32-bit reads completed once. Each raw response was appended and
fsynced before validation and before the next read. The Candidate 2 top identity,
SCAN1 identity, loader identity mask, W3a identity, autoinit/I2C idle state, and
transport idle state passed. The first invalid response is `NONE`.

This is a scoped read-only BAR check. It does not repeat PREPARE and does not
establish fresh camera detection or frame capture. Loader F0/NOVID fields are
internal loader state in this observation.
