# AHD v41 R2 Primary Campaign Blocker Summary

Generated offline: `2026-08-28T18:38:05.2291659Z`

## Authoritative state

| Field | Value |
| --- | --- |
| Primary campaign progress | `10/32` countable runs |
| Halt sequence | `10` |
| Halt run | `R2OM-R03-P2-C3` |
| Candidate | `C3` — exact qualified R1i |
| Run classification | `INCONCLUSIVE` |
| Halt reason | `C3_NON_CLEAN_SUSPEND_BLOCK` |
| Safe restoration | `PASS` before halt |
| Remaining planned runs | `22` not run |
| Scientific causal result | `BLOCKED` |
| Partial-data disposition | `INCONCLUSIVE; no causal assignment` |

## First blocker

`C3_NON_CLEAN_SUSPEND_BLOCK`

Run 10 used exact C3 identity and produced `INIT_DONE=1`, `INIT_ERROR=0`, zero autoinit NACK, zero retry/recovery, no retry exhaustion, no SCL timeout, and video present. Its measured frame rate was `25.776567 Hz`, outside the frozen clean band of `24.803727 ± 0.10 Hz`. The immutable capture therefore classified the run `INCONCLUSIVE`, not `CLEAN_PASS`.

The frozen R0 protocol states that any non-clean C3 run invalidates its block and suspends the campaign for identity/environment review. The fail-closed orchestrator consequently restored and verified the Formal Phase-2 safe baseline, committed run 10 as countable `INCONCLUSIVE`, wrote the halt receipt, and did not execute sequence 11 or later.

## Safe state after halt

The post-run Formal receipt is:

`R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/runs/010_R2OM-R03-P2-C3/10_SAFE_BASELINE_SEAL/SAFE_FORMAL_BASELINE_RECEIPT.txt`

SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`

It records:

- Formal Phase-2 bitstream SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`;
- `FPGA_DONE=1`;
- PCIe endpoint `10ee:7011`, `GEN1_X1`;
- bound driver `xdma`;
- `BLOCK_ID=0xA40A0C07`;
- `PROTOCOL=0x0000400B`;
- `CAPABILITIES=0x00031002`;
- Formal diagnostic magic `0x00000000`;
- zero flash operations.

## Scientific consequence

No frozen primary causal outcome is assignable:

- every cell requires 8/8 completed runs, but observed denominators are C0 `2/8`, C1 `2/8`, C2 `3/8`, and C3 `3/8`;
- C3 is mixed (`2 CLEAN_PASS`, `1 INCONCLUSIVE`), so its positive-control role is not established for the completed block;
- C2 already contains two `RECOVERED_PASS` observations, which cannot be counted as clean causal success and independently trigger margin/recovery review;
- the frozen O1-O4 interpretation rules must not be retrofitted to this partial prefix.

Accordingly, the scientific gate is **BLOCKED**. The partial-data disposition is **INCONCLUSIVE**, not M1-supported, M2-supported, independently sufficient, or combined-effect-required.

## Required disposition

Preserve the halt and immutable 10-run prefix. Do not resume at sequence 11, execute R3, or reinterpret C3 until the Owner authorizes the frozen identity/environment review and any permitted replay. Any continuation must retain the frozen order and must not repeat or overwrite the ten countable runs.

## Hash-bound blocker sources

| Source | SHA-256 |
| --- | --- |
| `R2_PRIMARY_CAMPAIGN_HALT.txt` | `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B` |
| `R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv` | `E3A2B5A52B10D4140FDBB0D5E620EEDE09A0698F402E354F3EBE45E70F9C9D7B` |
| `R2_PRIMARY_RAW_RESULTS_APPEND_ONLY.csv` | `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0` |
| `R2_PRIMARY_CAMPAIGN_LEDGER.jsonl` | `AA110E907571C9C1CD6E1B454A5284315C816C7507AC02E0DFE512342ADB1914` |
| Run-10 `R2_PRIMARY_RUN_COMMIT_RECEIPT.txt` | `3C7F8DBFD4BB64BEF39140F0BE136F37E0A7B8DF0766FD71255509742489B801` |
| Run-10 candidate capture receipt | `C911525528E125CE382024BA0D56B845564C94ADD1CE61FF009C5B308910E010` |
| Run-10 Formal safe-baseline receipt | `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF` |
| Frozen R0 experiment plan | `2F687813F0A299CE72E160E3BF5B4F35E334825A54002A2F43D00A0BCFD8BD6C` |
| Frozen R0 outcome matrix | `26B34E14F813DF3D6CB27469D09396942B657FE3B98182720B6CD1DB301D6836` |
| Frozen R0 margin trigger | `04261D83A28017E880B01B474D3A1A210D0B276E2B7FF99F87B02BBD38E7F92D` |
