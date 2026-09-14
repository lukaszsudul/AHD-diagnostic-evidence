# G2B NVP DIAG2-RM1 one-shot build failure report

## Outcome

- One-shot full-build invocation count: `1`
- Vivado version: `2025.2`, build `6299465`
- Vivado session started: `2026-09-14T09:10:09Z`
- Pre-Vivado receipt binding: `PASS`
- Direct parent: `PASS`
- Authorized changed set: `11/11 PASS`
- Focused HashAfter binding: `11/11 PASS`
- Affected input binding: `11/11 PASS`
- Remote ref read-back: `PASS`
- Commit-pinned blob read-back: `PASS`
- Build result: `FAIL`
- Finalizer: `NOT_RUN`
- Synthesis: `NOT_REACHED`
- Implementation: `NOT_REACHED`
- Timing/CDC/DRC/methodology/resource sign-off: `NOT_REACHED`
- Signed-off DCP count: `0`
- Bitstream count: `0`
- Hardware accessed: `NO`
- Retry performed: `NO`

## First failed gate

`RM1_PRE_SYNTH_TCL_PUBLICATION_RECEIPT_PATTERN_INVALID_COMMAND_NAME_BACKSLASH_T`

Vivado stopped while evaluating the publication-receipt patterns in
`g2b_nvp_diag2_rm1_build.tcl` at line 1079. The dynamically quoted
`SourceCommit` / `SourceTree` regular expressions contained `[ \\t]` inside a
Tcl double-quoted word. Tcl attempted bracket command substitution and emitted:

`invalid command name "\\t"`

This is a pre-synthesis harness failure. It is not timing, CDC, DRC,
methodology, resource, or hardware evidence. The known historical 3/3/3
unconstrained condition was not reached or measured by this run.

The Owner-authorized single full-build opportunity is consumed. No fix, retry,
alternate route, finalizer, DCP, bitstream, RM1 HW1 prompt, or hardware action
was performed.

## Immutable evidence identities

- One-shot result SHA-256: `9013BA8E0054E13E7F3B1E806734E3D71C88B6DA992177BA3BABEA18405AD09A`
- Vivado console SHA-256: `D8D33A4A86EAB0D9D44BC33E5B031CDF6C9985DA5BFD98F05E73AE1A76062DF9`
- Receipt-binding SHA-256: `272D705D612854149EF2A9BD47E5F40DF4EA2724320615BB1BCD5527E4168884`
- Pre-Vivado seal SHA-256: `AA7A0B7B99D062364308BE0C8F8761D5E24F994BCDDF2C832476992C494701D7`

