# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R1 G2B functional-body identity

Comparison target:

`rtl/g2b/v41_g2b_onech_c2h.sv`

Exact inputs read from the Git object database:

| Profile | Commit | Git blob | Raw bytes | Raw SHA-256 |
|---|---|---|---:|---|
| PRODUCT | `30b14d13b0b789b62b05ab513eb9578c7c43b11a` | `62fcda6664718b6ff273a67c2fed8ce25f42764a` | 93210 | `7d7f139cc3c246f696a2fe4ff1c41e6db423c4bf997722e33e370040a975f0d4` |
| diagnostic | `fcab95726761a0666a67e31c283dbdfb9e775074` | `bd9b4b1d4b43d04086477657e57392440527c1d9` | 93701 | `eb4a79608f1954440fa957c4f2571f6430dbd5dc89955b9cec98b11ab171a97a` |

## Exact allowlisted diagnostic delta

The diagnostic blob contains exactly four additional complete output-port
items, at diagnostic source lines 38-41:

```systemverilog
output logic diag_stored_enable,
output logic diag_c2h_active,
output logic diag_ring_empty,
output logic diag_ring_full
```

It contains exactly four additional continuous assignments, at diagnostic
source lines 1255-1258:

```systemverilog
assign diag_stored_enable = stored_enable_axi;
assign diag_c2h_active = c2h_active_axi;
assign diag_ring_empty = ring_empty_axi;
assign diag_ring_full = ring_full_axi;
```

Each diagnostic tap identifier occurs exactly twice in the comment-free source:
once in its output declaration and once as the left-hand side of its exact
continuous assignment. The PRODUCT blob contains none of the four identifiers.

## Deterministic canonical comparison

Tool:

`C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z\scripts\compare_g2b_functional_body.ps1`

Tool SHA-256:

`5F4D54544711DE9702FC30507E7CAB3F3C0FC24C95DAB852C0ADA831A340E778`

Method identifier:

`COMMENT_STRIP_THEN_EXACT_PORT_ITEM_EXCLUSION_THEN_EXACT_ASSIGN_TOKEN_EXCLUSION_THEN_LENGTH_PREFIXED_TOKEN_STREAM`

The comparator is fail-closed:

1. It obtains each exact commit:path blob as raw bytes with `git show` and
   requires strict UTF-8 decoding.
2. It lexically removes line and block comments while preserving string
   literals.
3. It resolves exactly one `v41_g2b_onech_c2h` module declaration, parses its
   balanced top-level port list, and removes only complete port items whose
   compact signature is exactly `outputlogic<tap-name>` for one of the four
   allowlisted tap names. It requires one of each in diagnostic and zero of
   each in PRODUCT.
4. It reconstructs the retained comma-separated port list. This canonicalizes
   the separator that must be added to the preceding PRODUCT port when the four
   diagnostic ports are present; it does not discard commas elsewhere.
5. It tokenizes the full comment-free source and removes only the four exact
   five-token sequences `assign <tap> = <mapped-existing-signal> ;`. It
   requires one of each in diagnostic and zero in PRODUCT.
6. It requires zero remaining occurrences of every diagnostic tap identifier.
7. It compares every remaining token case-sensitively and hashes a deterministic
   length-prefixed token stream. No source-base normalization, family merging,
   identifier rewriting, or bit-index stripping is performed.

Results:

| Measurement | PRODUCT | Diagnostic before exclusions | Diagnostic after exclusions |
|---|---:|---:|---:|
| module ports | 21 | 25 | 21 |
| comment-free tokens | 11773 | 11809 | 11773 |
| canonical bytes | 87315 | N/A | 87315 |
| canonical SHA-256 | `d1e9479c66598baf8ed152b763e9ee4a733751e6e59304e2464a7018b4bdc85e` | N/A | `d1e9479c66598baf8ed152b763e9ee4a733751e6e59304e2464a7018b4bdc85e` |

First canonical mismatch: `NONE`.

The 36-token pre-exclusion difference is exhausted exactly by four additional
port items and their list separators plus four five-token continuous
assignments. After the allowlisted exclusions, the complete residual token
streams are identical.

Disposition:

```text
G2B_FUNCTIONAL_BODY_IDENTITY = PASS
DIAGNOSTIC_TAPS_ONLY = YES
FUNCTIONAL_OWNERSHIP_LOGIC_CHANGED = NO
FUNCTIONAL_RELEASE_LOGIC_CHANGED = NO
FUNCTIONAL_RESET_LOGIC_CHANGED = NO
```

This is a source-functional proof. It supports but does not replace the required
routed-DCP support-set and diagnostic-tap fanout proof.
