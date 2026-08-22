# V41 NVP address-ACK probe R1d evidence

Offline implementation, simulation, and the single clean diagnostic FPGA build
are complete. The separate Owner hardware-window assignment was not supplied,
so the evidence correctly contains no live DUT telemetry and records zero
hardware actions.

- Diagnostic source: `1beb70536d8e57305813f377a9e2c0e810b0bfc0`
- Diagnostic tree: `c1ded5519ebe10d257014d2fbde45198f33fac97`
- Bit SHA-256: `26C132885C6BB328F592D433EB7DE0E7FD33ED1CD0392D3AA51544644043FF58`
- Evidence ZIP SHA-256: `42A6D5E2E5D2E752FAC2D8CD83C43B6E0A4F9547BC992D40D721EBC847908329`
- Hardware status: `WAITING_FOR_OWNER_HARDWARE_WINDOW`

The LFS ZIP contains the complete curated tree, including the bitstream, synth
and routed DCPs, full reports/logs, simulation evidence, source patch, host and
statistics tools, manifests, and final report. The browsable copy omits only
large binary artifacts already present in that ZIP.

