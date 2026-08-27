# AHD v41 R1i–R2 Deployment and Hardware Qualification — Public Copy

Original file SHA-256: `2F5D3DBE79E67A49D5DD5EA6816C4DAA39604F781C0A40D9F17C333475069307`  
Publication status: sanitized narrative copy; scientific values unchanged.

## Result

Scientific verdict: **THESIS_CONFIRMED**  
Frozen outcome: **STRONG_PASS**  
Scope: **QUALIFIED POC BASELINE**

The fixed R1i candidate passed every frozen functional and sample-integrity gate. The exact same-session unmodified R1h control was a valid measurement but failed autoinit and produced no video. The exact sub-mechanism remains inconclusive because R1i's early-false, qualified-NACK, and recovery counters were all zero.

## Identities and scope

- Frozen order: A1 fixed R1i → B1 exact R1h → Formal Phase-2 restore → hard stop.
- Candidate commit/tree: `20c3323d79d3896edc586d6db1df7deee60f9e41` / `70d801fd7a879080da399bfa9ee95fd6eb008e16`.
- R1i bit: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`.
- R1h bit: `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41`.
- Formal bit: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.
- No rebuild, synthesis, implementation, source, XDC, IP, driver, or test-definition change occurred in the hardware qualification.
- No LTX was required; the flow used MMIO/BRAM instrumentation.

## Baseline

The approved transport reached `DUT_HOST` as `APPROVED_DUT_USER`. The read-only Formal baseline passed with kernel 7.0.0-29-generic, endpoint 10ee:7011, pinned XDMA, BAR0/BAR1 sizes 131072/65536 bytes, common identity A40A0C07 / 0000400B / 00031002, diagnostic magic zero, and no MMIO writes or DMA.

## A1 fixed R1i

- Runtime source: `20c3323d79d3896edc586d6db1df7deee60f9e41`; `BUILD_FLAGS=2`.
- Programming, independent DONE, and runtime identity: PASS.
- WADDR/REGADDR/DATA post-init: 0/10,000, 0/10,000, 0/10,000 NACK.
- Autoinit WADDR/REGADDR/DATA NACKs: 0/0/0.
- `INIT_DONE=1`, `INIT_ERROR=0`, unrecovered=0, retry exhausted=0.
- SAV rate: 28,124.980562/s; frame rate: 24.803727 Hz.
- Early-false/raw-qualified/recovered transactions: 0/0/0.
- Timeouts, overflow, bank-invariant errors: 0.
- Functional result: PASS.

## B1 exact unmodified R1h control

- Runtime source: `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`; `BUILD_FLAGS=2`; R1i page zero.
- Programming, independent DONE, and runtime identity: PASS.
- WADDR/REGADDR/DATA post-init: 0/10,000, 0/10,000, 0/10,000 NACK.
- Autoinit WADDR/REGADDR/DATA NACKs: 0/2/2; aggregate=4.
- `INIT_ERROR` latched; SAV and frame rate were zero.
- Timeouts, overflow, bank-invariant errors: 0.
- Measurement integrity: PASS; functional result: FAIL_INIT_ERROR_NACK_NO_VIDEO.

## Analysis

The frozen plan did not predeclare a p-value threshold. Each post-init phase is 0/10,000 versus 0/10,000 with Fisher one-sided p=1.0. Autoinit REGADDR is 0/275 versus 2/275, and DATA is 0/220 versus 2/220. The low counts are descriptive, not claimed statistically significant.

The valid functional separation is decisive under the frozen matrix: R1i initialized and produced video; exact R1h recorded autoinit NACKs, latched `INIT_ERROR`, and produced no video.

## Restoration and safety

Exact Formal Phase-2 restoration passed. Final identity was A40A0C07 / 0000400B / 00031002 with diagnostic magic zero, endpoint 10ee:7011, pinned XDMA, and DONE=1.

There were three volatile FPGA programming operations, six Vivado hardware processes, three warm reboots, and three pinned-driver loads. There were zero AXI-Lite writes, DMA transfers, flash changes, or physical actions. The dedicated lock was released and no hardware-owning process remained.

The combined R1i correction is a qualified PoC baseline. The precise ACK-sampling-versus-readiness mechanism remains unresolved, and production acceptance is not claimed.
