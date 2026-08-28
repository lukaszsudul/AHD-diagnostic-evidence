# AHD v41 R2 Hardware Causal Experiment — Owner-Mediated Continuation

This directory is the publication input package for the halted Owner-mediated R2 continuation. It preserves the actual execution record without converting an incomplete campaign into a causal result.

## Result at the sealed execution point

- Engineering gate: `BLOCKED`
- Scientific causal result: `BLOCKED`
- Hardware authority: `PASS`
- Hardware authority mechanism: `OWNER_CHAT_DECLARATION`
- Cold-start control: `OWNER_MEDIATED_MANUAL_RESET`
- Primary campaign: `10/32` countable runs completed
- Exact-R1i cold-start qualification: `0/10`, `NOT_RUN`
- INIT_DONE timing protocol: `NOT_RUN`
- First blocker: `C3_NON_CLEAN_SUSPEND_BLOCK`
- Final hardware state: exact Formal Phase-2 safe baseline, independently sealed after run 10
- Evidence publication: `PENDING` until repository commit and remote read-back

The run-10 C3 image had valid identity, `INIT_DONE=1`, `INIT_ERROR=0`, zero NACK/retry/recovery/timeout activity, and video present, but its one-second frame-counter estimate was `25.776567 Hz`, outside the frozen `24.803727 ± 0.10 Hz` clean band. Under the frozen R0 rule, any non-clean C3 run invalidates its block and suspends the campaign for identity/environment review. The run was therefore retained as `INCONCLUSIVE`; it was not relabeled, discarded, or repeated.

## Completed primary observations

| Cell | Runs | CLEAN_PASS | RECOVERED_PASS | FAIL | INCONCLUSIVE |
|---|---:|---:|---:|---:|---:|
| C0 — exact R1h | 2 | 0 | 0 | 2 | 0 |
| C1 — R1i-a | 2 | 0 | 0 | 0 | 2 |
| C2 — R1i-b | 3 | 1 | 2 | 0 | 0 |
| C3 — exact qualified R1i | 3 | 2 | 0 | 0 | 1 |

C0 reproduced the historical negative condition in both executed control runs. C2 activated NACK/retry/recovery in two of three executed runs. C1 and the halted C3 run exposed the frozen one-second frame-rate classification limitation. These incomplete and mixed observations do not satisfy the preconditions for the frozen C1/C2/C3 causal interpretation matrix.

## Authority and cold-reset status

The Owner explicitly granted exclusive DUT authority in this chat. The captured declaration timestamp is `2026-08-28T10:08:52.027Z`; its source receipt SHA-256 is `2DEC89DBC82EBE4361288BBC1557766C2225162BD86C63ADA56F38A5B06BE002`. No software mutex was created or required for this continuation.

The Owner cold reset that preceded the earlier attempt remains a precondition only and was not counted as a formal trial. The primary 10 runs were warm campaign runs. No formal manual cold reset was requested because the frozen C3 suspension occurred before the separate 10-start phase. Consequently, the manual-reset receipt count is zero.

## Final safe state

The final sealed receipt after `R2OM-R03-P2-C3` records:

- Formal Phase-2 bitstream SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- `DONE=1`
- PCIe endpoint: `10ee:7011`, Gen1 ×1
- bound driver: `xdma`
- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- diagnostic magic: `0x00000000`
- secondary diagnostic magic: `0x00000000`
- boot ID: `d12b3a07-ea25-4769-8293-88ee8fc92ef2`
- final safe-baseline receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`
- final live read-only receipt SHA-256: `57D0BA961EE73C2B89574B04FF5ED19782F4EE0FA909A47C7DA005F181EAD49A`

The live read-back at `2026-08-28T18:34:18.741078119Z` reconfirmed exact Formal identity and recorded zero MMIO writes and zero DMA transfers.

## Scope controls

- Product R1i modified: `NO`
- G-track modified: `NO`
- G2A bitstream used: `NO`
- Flash: `UNCHANGED` (`0` flash operations)
- Drivers: `UNCHANGED`
- R3 executed: `NO`
- G2B resumed: `NO`
- project-current-state modified: `NO`

See `R2_CAUSAL_HARDWARE_REPORT.md` for the engineering narrative and `R2_EVIDENCE_INDEX.md` for the immutable source receipts used to construct this package.
