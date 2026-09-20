# AHD v41 CH3 R2R8 — minimal MMIO fix evidence

## Result

- MMIO integration defect: `REPRODUCED_EXACT_SIGNATURE`
- Focused responder fix: `PASS`
- One implementation: `PASS_ROUTE_AND_RESOURCE`
- PREPARE-only scoped admission: `BLOCKED`
- New bitstream: `NONE`
- DUT: `UNTOUCHED`
- Overall: `BLOCKED_NO_BITSTREAM`

The old loader left an internal read response pending after an accepted write. The next read could not be accepted by the shared AXI-Lite bridge. The focused RTL change makes accepted writes side-effect-only and makes accepted reads produce one latched response held through backpressure.

## Focused integration regression

The regression used the production AXI-Lite bridge, G2B router, CH3 wrapper, loader, and SCAN1 control on the same BFM/checker.

- Old loader: exact deadlock signature reproduced (`READ_REQUEST`, response ready low, loader response valid high, loader request ready low, watchdog 24).
- Unchanged SCAN1 control: PASS.
- Patched loader: PASS for busy status reads, both AW/W orders, delayed BREADY/RREADY, response stability, consecutive reads, rejected command handling, and completion of the deterministic PREPARE register model.
- Model boundary: no analog timing, physical I2C, camera, PCIe/XDMA IP, or hardware qualification.

Base source: `d8dc9592037ca73e2321b30fd1f65a2a3f8b92e7`, tree `46bc7d8c6269ce74c14b72af771b29a410e84fb3`.

Patched source: `b2f80cf4fda1775ab34804a246cb7be61e0ecd62`, tree `fd19d5e27923f69d16d2d8679db85d7813124c37`. The source remains in the confirmed private source repository. No source, profile, microcode, binary, or pixel data is published here.

## Implementation evidence

Exactly one implementation ran with Vivado 2025.2 build 6299465.

| Stage | Calls | Elapsed |
|---|---:|---:|
| synth | 1 | 1426.457 s |
| opt | 1 | 88.167 s |
| place | 1 | 628.936 s |
| phys_opt | 1 | 42.838 s |
| route | 1 | 401.377 s |
| bitgen | 0 | not run |

Route completed with zero unrouted or partially routed nets.

| Stage | LUT | FF | BRAM tile | LUT margin to 20384 |
|---|---:|---:|---:|---:|
| post-opt | 20150 | 21559 | 28.5 | 234 |
| routed | 19695 | 21559 | 28.5 | 689 |

Final routed DCP: 62555747 bytes, SHA-256 `F589B7C6151EC2EAB576B358837D0A331B02D69A11DF30F5BCF5910416EEBA64`. The DCP is retained privately.

One aggregate bus-skew report covered 11/11 active constraints with zero negative slack; minimum slack was `+1.119 ns`.

## First blocker

`FINALIZER_RAW_ACTIVE_XDC_HASH_SELF_REFERENTIAL_HEADER_MISMATCH_AFTER_SINGLE_ALLOWED_DCP_REOPEN`

The finalizer compared two complete Vivado `write_xdc` exports by raw hash. Exactly one of 162 lines differed: the generated `# Command Used:` header embedded a different destination path. The remaining 161 lines were sequence-identical without sorting, all 11 bus-skew constraints were present, and both constraint payloads had SHA-256 `64EB95F3F938C4803A83B818291FB3CA42BF4974C50CC20FB3FD7A53AF15BF9D`.

The script had already closed the single allowed controlled DCP reopen. It was not retried. Consequently:

- final timing summary and pulse-width/coverage: `NOT_RUN`;
- final DRC and write-bitstream DRC: `NOT_RUN`;
- realized local CDC register-clock proof: `UNRESOLVED_NOT_REACHED`;
- bitstream: `NONE`;
- PREPARE-only scoped admission: `BLOCKED`.

The router's intermediate post-route snapshot (`WNS +0.230 ns`, `TNS 0`, `WHS +0.032 ns`, `THS 0`) is recorded only as diagnostic context and is not substituted for the missing final timing gate.

## Scope and counters

- `HARDWARE_QUALIFICATION = NOT_RUN`
- `CAMERA_CONFIGURATION_ADMISSION = NOT_GRANTED_BY_THIS_TASK`
- `CAPTURE_ADMISSION = NOT_GRANTED`
- `PRODUCT_QUALIFICATION = NOT_CLAIMED`
- DUT contact, hardware PREPARE, APPLY, ONESHOT, scans, DMA, capture, programming, reset, and reboot: all `0`
- SSOT: revision 9; all 19 before/after files unchanged

The smallest continuation is a separately authorized single reopen of the same DCP, one corrected content comparison, one final timing summary, one DRC, a realized local clock check, and one conditional bitgen. No rebuild or RTL revision is indicated by this blocker.
