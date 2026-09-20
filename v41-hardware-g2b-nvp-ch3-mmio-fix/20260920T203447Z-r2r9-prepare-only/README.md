# AHD v41 CH3 R2R9 — recovery, exact image activation, PREPARE only

Status: **PASS_RECOVERY_ACTIVATION_PREPARE_ONLY**.

- Exact source: `b2f80cf4fda1775ab34804a246cb7be61e0ecd62` / tree `fd19d5e27923f69d16d2d8679db85d7813124c37`.
- Exact SRAM image: `34DFC48E9CCEDD9E4F608624EE51D1D79767E8E74035393576B69C21C07E8CB8` (2192144 bytes).
- Recovery order: one JTAG programming, then one warm reboot; no pre-recovery unload or unbind.
- Qualified driver loaded once and normally unloaded once after safe closeout.
- One PREPARE write at `0x1240C`, bytes `01 00 00 00`.
- MMIO during PREPARE: `PASS_OBSERVED`; MMIO after PREPARE: `PASS`.
- First post-write status: `0xC3C00001` at 6.592 ms.
- Terminal status: `0xC3CD0042` at 99.343 ms: engine done, `CAMP_PREPARED`, `ERR_NONE`, F0 `0x34`, no CH2 impact.
- Cleanup: `PASS_EXACT_MODULE_NORMAL_UNLOAD`; an independent read found the endpoint unbound, no XDMA nodes/FD/maps, and both task locks released.

The last MMIO measurement was made before normal driver unload. The PREPARED runtime state was deliberately not reread after unload. This result does not qualify camera readiness, APPLY, C2H, capture, PNG, or product use.

Two host-only corrections were recorded without repeating hardware actions: a result-collection query was repaired after durable JTAG PASS markers, and an unrelated operating-system D-state process was removed from the AHD-specific blocking predicate before any driver load or PREPARE attempt.
