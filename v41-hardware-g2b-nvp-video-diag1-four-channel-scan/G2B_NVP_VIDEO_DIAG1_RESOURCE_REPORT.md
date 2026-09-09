# Resource report

| Resource | Used | Available | Percent | Limit | Result |
|---|---:|---:|---:|---:|---|
| Slice LUT | 22306 | 20800 | 107.240% | 98.000% | FAIL |
| FF | 23674 | 41600 | 56.909% | 95.000% | PASS |
| BRAM | 26.5 | 50 | 53.000% | 90.000% | PASS |
| DSP | 0 | 90 | 0.000% | 90.000% | PASS |

Hierarchical attribution:

- Diagnostic scan core: 3,992 LUT / 4,222 FF
- Fixed I2C master: 158 LUT / 137 FF
- G2B one-channel C2H: 2,007 LUT / 2,908 FF
- XDMA: 10,485 LUT / 11,602 FF

The diagnostic core contains a 128x32 result table implemented with asynchronous read and whole-array reset. Its 4,096 bits map to FFs plus a broad read mux. Exact corrective target: infer a compact synchronous block RAM without bulk reset, using validity/session metadata for logical clear, or collect each entry on the host at the existing handshake. Minimum reduction to meet 98%: 1,922 LUTs. No resource-limit waiver is authorized.
