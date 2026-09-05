# AHD v41 G2B-LUT1 Sign-Off Recovery 4 and PRODUCT Bitstream Candidate

Engineering gate: PASS. Source publication: PASS. Evidence publication is completed and remotely checked after this package is committed; the final task receipt records that result. SSOT remains revision 7. No hardware was accessed.

## Implemented source

The exact authorized combined candidate is appended to active g2b_cdc.xdc and only the three retired global Groups 15â€“17 skew commands are removed. Source commit `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`, parent `bdae16e06fb5b8564763941f530e4ce9e28896c7`. One file changed; tracked state and index are clean. The primary FPGA_AHD main worktree is preserved exactly.

## Sign-off results

| Gate | Result |
|---|---|
| DCP reuse | Valid; 34 non-XDC inputs exact, original project/IP identity exact; no rebuild |
| Groups 1â€“14 | PRESERVED_PASS with exact provenance and unchanged scope |
| Groups 15â€“17 | 9/9 fresh PASS; minimum slack +0.260 ns; all reference delays reproduced |
| Retired global BUS_SKEW queries | None executed |
| Route | 33,985/33,985 routable nets routed; zero errors/unrouted/partial |
| Timing | WNS +0.023 ns, TNS 0, WHS +0.043 ns, THS 0; recovery/removal PASS |
| Timing completeness | No-clock, unconstrained internal endpoints, loops and latch loops all zero |
| Methodology | Eleven TIMING-34 and one TIMING-39 mapped to governed PASS; zero unresolved |
| DRC | Zero errors, zero critical warnings; all fourteen inherited warnings inventoried |
| CDC | 1,401 rows classified; 427/427 critical findings dispositioned; zero unresolved/RTL-change |
| Clocks | User and AXI 62.500 MHz; required clocks and routing PASS |
| PRODUCT resources | LUT 17,366/20,800 (83.490%); FF 19,314/41,600 (46.428%); BRAM 26.5/50 (53%); DSP 0/90 |
| Other resources | LUTRAM 1,159; BUFGCTRL 8/32; MMCM 2/5; PLL 0/5; bonded IOB 15/150 |
| Functional protection | Fresh 27/27 Python tests plus exact hash-bound functional, MMIO, profile and R1i evidence |
| ABI/MMIO | Frozen ABI v1 and 0x3800..0x3BFF unchanged |
| Offline throughput | PASS at governed required payload 288 MB/s; hardware throughput NOT_PROVEN |
| Pre-bitstream hard gate | PASS, all 29 mandatory lines explicit |
| Signed-off DCP and bitstream | Produced and sealed; exact identities below |

## Candidate

Classification: OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE.

- Bitstream: `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit`; 2192144 bytes; SHA256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
- Signed-off DCP: `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp`; 15726324 bytes; SHA256 `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`.
- Debug probes: none; NONE_EXPECTED_PRODUCT_PROFILE.
- Hardware qualification: false.

The original embedded Gen12 precommit fingerprint and BUILD_FLAGS 0x00000103 remain in the reused logic. The candidate identity binds that original sealed build manifest to the new approved constraint source. This is explicit in the HW0 preparation plan.

## Resolved execution stop and limitations

The first worker stopped at the older CDC canonical hash, after successful groups, route, timing, methodology and DRC reports. The comparison proved the complete destination/domain/exception/severity/depth multiset unchanged. Twenty-six launch representatives differed within already reviewed stable-data collections. Every current finding was individually classified; the unchanged netlist, promoted structural proofs and routed bounds support the disposition. A serialized continuation verified exact synchronizer attributes and completed remaining gates. Original logs/failure markers are preserved. No completed timing or CDC report was rerun and no watchdog timeout occurred.

The first G2B Python test invocation lacked the sparse-checkout ABI file. The successful rerun used the exact tracked frozen JSON and passed all eleven tests; all sixteen R1i tests also passed. These environment/comparator corrections changed no RTL or governed source scope.

DRC reset warnings remain visible and dispositioned; no hardware reset/glitch immunity or measured DMA throughput is claimed. This evidence does not itself change accepted project truth.

## Continuation

First blocker: NONE. After evidence publication and remote read-back PASS, recommend a separate META promotion of this exact offline-qualified candidate, followed by separately authorized G2B-HW0 synthetic DMA bring-up, starting with runtime identity and one deterministic 4096-byte C2H record. No hardware step was executed here.

Final execution point: HARD STOP AFTER G2B-LUT1 SIGN-OFF RECOVERY 4.


Large raw timing reports are published as lossless `.rpt.gz` files. `raw/COMPRESSED_REPORTS.json` binds each archive to the original uncompressed report hash and size; original reports remain in the local recovery directory.
