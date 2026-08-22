# R1d clean-build gate audit

## Identity

- Source commit: `1beb70536d8e57305813f377a9e2c0e810b0bfc0`
- Source tree: `c1ded5519ebe10d257014d2fbde45198f33fac97`
- Parent/base: `8464af66611f7c22b8a36a4aab915d598eedda3f`
- Vivado: 2025.2 build 6299465
- Part/top: `xc7a35tcsg325-2` / `ahd_capture_top_xdma`
- Full builds consumed: 1 of 1
- Bit SHA-256: `26C132885C6BB328F592D433EB7DE0E7FD33ED1CD0392D3AA51544644043FF58`
- Synth DCP SHA-256: `E4650D80DBA7F4C5D35FEC8A9DA5592884F787A3764992250DF94DFAB28C026C`
- Routed DCP SHA-256: `CBA74C4986D93A7376FE28039C5A7719BC8A35F904E5E8731AF0550EF28D309E`

## Gates

- Project creation, synthesis, implementation, route, bitgen: PASS.
- Route errors/unrouted/partially routed nets: 0/0/0.
- WNS/WHS: 0.617 ns / 0.036 ns.
- VDO WNS/WHS: 0.617 ns / 0.601 ns.
- DRC errors/critical warnings: 0/0.
- Bus-skew violations: 0.
- CDC Critical types: 0.
- CDC Unknown types: 0.
- Protected NVP blobs, NVP XDC, and XDMA XCI: unchanged.
- XDMA XCI SHA-256: `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`.
- NVP XDC SHA-256: `B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318`.
- Formal autoinit remains `I2C_HZ=50000`, divider 625, tick cycles 626.
- Provenance round trip: PASS; `BUILD_FLAGS=0x00000002`.

## Warning-accounting note

The authoritative final DRC report contains six warnings: four accepted
`REQP-1839`, one `PDCN-1569`, and one `RTSTAT-10`. The accepted baseline for
`REQP-1839` is four, so there is no increase. `PHASE3_BUILD_RESULT.txt` records
`REQP_1839_COUNT=0` because the build script counts that identifier only in the
methodology report; the identifier occurs in the DRC report. This evidence uses
the authoritative DRC count of four. No source change or second build was made.

Vivado also emitted a task-local `EXCEPTION_ACCESS_VIOLATION` helper-process
dump during synthesis. The primary Vivado invocation continued, returned zero,
and subsequently completed synthesis, implementation, routing, all reports,
and bitstream generation. The raw marker and dump are retained.

