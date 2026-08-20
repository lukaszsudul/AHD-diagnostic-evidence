# N0 before-state and input identity

UTC collection window: `2026-08-19T23:35:10Z` to `2026-08-19T23:50:47Z`.

## Formal repository

- Path: `C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\V41_V40_1_0_RESUME\FPGA_AHD`
- Branch: `v41/xdma-v40.1.0-base`
- HEAD and tag target: `c89e88bcdf389614c884fb129e8b2d42a585bccb`
- Tree: `417820c69c134161fcafae0947dc5976919814d1`
- Status: clean
- Formal-repository mutations during NVP: `0`

## Formal bitstream

- Path: `C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\V41_V40_1_0_RESUME\EVIDENCE\PHASE_2\02_FRESH_BUILD\SEALED\artifacts\ahd_capture_v41_phase2_p1.bit`
- Bytes: `2192144`
- SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- Identity gate: PASS

## Live host gate

- TCP/22 reachability: PASS.
- Observed SSH ED25519 fingerprint: `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8` / MD5 `6a:47:47:53:87:21:90:76:cb:bc:0f:d4:c3:21:db:02`.
- Sealed fingerprint match: PASS.
- Non-interactive authentication for `vcdeagent1`: FAIL; the available keys were rejected and the approved PuTTY path requested an interactive password.
- Boot ID, endpoint/link/BARs, driver/nodes, runtime identity, and diagnostic magic: not freshly collected because authentication did not complete.
- No credential was recorded.

## Fresh JTAG gate

- Recovery attempts: 2. Attempt 1 stalled before connecting because no local `hw_server` was listening; it was safely closed. Attempt 2 used one fresh hidden server and session.
- Exact target: `localhost:3121/xilinx_tcf/Digilent/210241768436`
- Device count: `1`
- FPGA: `xc7a35t`
- IDCODE: `0362D093`
- DONE: `1`
- Read-only JTAG gate: PASS
- SRAM programming operations: `0`

## Before-state conclusion

The prompt's authoritative current state identified the active image as the formal Phase-2 reference. Fresh JTAG independently confirmed the exact device and `DONE=1`, and no programming operation occurred. Host-side image identity could not be freshly re-proven because the no-interaction-compatible SSH authentication path was unavailable.
