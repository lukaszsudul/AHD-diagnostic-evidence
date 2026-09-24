# R2R10R14R5 — bounded APPLY_A DATA_NACK write retry build

## Result

`BITSTREAM_GENERATED_UNTESTED_WITH_NATIVE_SETUP_VIOLATION`

A single experimental candidate was built from a new source revision. The loader can retry one exact allowlisted APPLY_A write after diagnostic-master DATA_NACK cause 4. The budget is one retry for the whole APPLY and one for an instruction. It does not replay the block. The private Bank0B write semantics remain undocumented; the effect of the first write after DATA_NACK remains unknown.

## Source identity

- Parent: `88ac649a8484ff359270ec19ab539478edf534c0`
- Candidate commit: `c05f62d204853f36263b5fd486596abd517f5e92`
- Candidate tree: `9d35c25b09718057bb100314309006baae8409c5`
- Part/top: `xc7a35tcsg325-2` / `ahd_capture_top_xdma`
- Vivado: `2025.2`, software build `6299465`

The changed product source is limited to the CH3 loader, plus a new read-only APPLY write-retry ABI, pure offline decoder, and contract document. Microcode, PREPARE retry ABI v1 and decoder, diagnostic I2C master, EQ program, PN, DMA, IP, driver, frontend, and XDC are unchanged.

## Experimental contract

- Scope: 19 exact APPLY_A writes at PC103–121, Bank0B/registers 0x60–0x72.
- Eligible failure: DATA_NACK cause 4 only, with no timeout and exact PC/bank/register/data/origin match.
- Retry: one complete write transaction, no PC advance before retry, no block replay, no extra bank select.
- Qualification: 18,750 consecutive idle cycles and a nonrenewable 62,500-cycle acceptance deadline.
- Telemetry: separate read-only version 1, one event slot; normative private ABI SHA-256 `ABE48CE78251A8B44772E9378E7D7F99FCF33B906C264082AA10F1962402EA43`.
- Decoder SHA-256: `634F4F0BDC6A2E62387C4C50169CDD92F98504B0B4F079D87B1467E3E6E3E6B7`.
- PREPARE v1 remains byte-identical. The reset-only hard-failure record remains the first unrecovered hard fault.

This is source-reasoned compatibility only. No simulation, host test, formal proof, lint, equivalence test, or hardware execution was performed.

## Build

| Stage | Attempts | Result | Elapsed (s) | Slice LUT |
|---|---:|---|---:|---:|
| synth_design | 1 | PASS | 1402.196 | 22652 |
| opt_design ExploreArea | 1 | PASS | 197.078 | 20666 |
| place_design | 1 | PASS | 548.616 | 19927 |
| route_design | 1 | PASS, complete | 420.364 | 19927 |
| write_bitstream | 1 | PASS, mandatory DRC 0 errors | 68.146 | 19927 |

The post-synth over-capacity result was used only as the authorized input to one ExploreArea run. The post-opt and later physical gate was `Slice LUT used < 20800`; every applicable stage passed. Compared with R13R2, post-opt is +91 LUT and routed is +22 LUT.

Routing completed with 40,037/40,037 routable nets fully routed and zero routing-error nets. Native post-route estimated timing was WNS -0.150 ns, TNS -1.381 ns, WHS +0.036 ns, THS 0.000 ns. Setup timing is therefore violated. No additional timing, CDC, bus-skew, methodology, or DRC sign-off was run.

Final Vivado message summary: 0 errors, 0 critical warnings, 442 warnings. The synthesis engine also emitted its cumulative internal count of 34,139 warnings; no new warning audit was performed.

## Private artifact identities

- Bitstream: 2,192,144 bytes; SHA-256 `08B02EE2086230E7A372BE64EDD5FD9B93BE91A4C9156CA1D5F6F35D14128F1F`.
- Post-synth DCP: 54,098,564 bytes; SHA-256 `9007B3DD43D002B2ECCDD6F6BD31A72A4FC410408C9C1260089EC9E8CFF43304`.
- Post-opt DCP: 53,415,176 bytes; SHA-256 `5A40EE88B6495165CA779D14DA2FD31703485DCC2337C1251FAC9286818E6443`.
- Routed DCP: 64,022,029 bytes; SHA-256 `B1AE995CD19BEFA562C7427F9A8DA183CAA0014FBAF1397F218D127519552AF8`.

The binary artifacts, DCPs, source diff, detailed ABI, logs, private tables, profiles, microcode, and credentials are not published here.

## Limits and next gate

Retry effectiveness, the first-write physical effect, EQ execution, camera output, and product behavior remain untested. Historical I2C-TA1 results belong only to the old R13R2 routed DCP and are not inherited by this implementation. A hardware activation and one bounded PREPARE → APPLY_A/EQ → SCAN1 → C2H/PNG attempt require separate Owner authorization.