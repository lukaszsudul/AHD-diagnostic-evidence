# W3 authority and scope preflight (public copy)

## Entry result

`PASS_AT_ENTRY`. This is an offline, SSOT read-only W3 diagnostic development task. No DUT contact, MMIO, programming, driver change, SSOT update, W4 activity or product promotion is authorized. The live DUT state is `NOT_SURVEYED_IN_W3`; the private future endpoint is omitted from this public copy.

The evidence checkout was at commit `f3eafd4341752648f210afd0c8687c5cf4759294`, tree `fdb3ac413f7e4505d6249e8cd1252077420a2025` at entry. The required six `project-current-state` documents were read in order: `README.md`, `GOVERNANCE.md`, `UPDATE_POLICY.md`, `PROJECT_STATE.json`, `TRACK_STATUS.json`, `CURRENT_INTERFACES.md`. Both JSON `project_state_revision` fields equal **9**, as do the human-readable headers. The applicable `SHA256_MANIFEST.txt` has 18 entries; all 18 present file bytes match. This records `PROJECT_STATE_REV_AT_START=9`. Governance requires a fresh revision/hash read and stale-state classification before final release; this entry check is not that end check.

| Entry document | SHA-256 |
|---|---|
| `README.md` | `179C6BD16B2A4143BD5A116F3C6A63D59C2B7C96E65771E62FBDF63EAC30EBB9` |
| `GOVERNANCE.md` | `70BE3FF2A5BB65C843BFAC719D740DF467F4E00E7B3F9A9CAC8D331F146B7D8B` |
| `UPDATE_POLICY.md` | `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497` |
| `PROJECT_STATE.json` | `B441296763785CB0FD8764DB78175F1F0D2A5DA891D174FEF364417901C6A6C2` |
| `TRACK_STATUS.json` | `11B99A80D76C81C514FB24131F847EECFB75B6AD7E7B08563A383A98A4CA4686` |
| `CURRENT_INTERFACES.md` | `00F55BF703AC0541045D319352B248DB4CA9702530E4CA378171CAAE9080FD90` |

The source worktree was created from the exact parent commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`, on `diag/v41-g2b-w3-first-terminal-wait-delay-20260917T165535Z`. It was clean at the authority check. The pinned master blob `738a81ec621a4ff85efda48d14b45ba2b9a4803e` is 14,136 bytes and SHA-256 `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`. Subsequent W3 source edits belong on this isolated branch; the primary checkout and its pre-existing untracked files are outside the task.

## Pinned evidence inventory

Each commit and stated directory resolves locally in the evidence repository. Index filenames were read from each pinned Git tree; the last two packages use prefixed index/manifest names. The accepted W1/W2 package's 17 public manifest entries pass current byte-size and SHA-256 checks. These are historical authorities, not new hardware measurements.

| Purpose | Pinned commit | Index at pinned directory |
|---|---|---|
| Accepted W1/W2 | `f3eafd4341752648f210afd0c8687c5cf4759294` | `EVIDENCE_INDEX.md` |
| 214-case offline study | `173f23a799f8879e0dab1c29edd6e5c8b0805071` | `EVIDENCE_INDEX.md` |
| Bank5 failure replay | `74dd150c3438bbea24641cdd8e3bb45e62a5bc65` | `EVIDENCE_INDEX.md` |
| Last physical campaign | `b1b12524d41435aad49d7ce7662af26981682143` | `EVIDENCE_INDEX.md` |
| Corrected sign-off procedure | `9be3c9f023356f9dd04a4e42c2cc5944c97c211b` | `EVIDENCE_INDEX.md` |
| BRAM gate set | `df4a139c852fb0130246a6b959bdedc2b8b4cb3b` | `CONT1R3R1_EVIDENCE_INDEX.md` |
| Historical firmware generation | `20a4edeceb9ca77294f6e121c1b48686737c980b` | `CONT1R3R3_SHA256_MANIFEST.txt` and main report |

The W1/W2 handoff supplies the bounded clean baseline: 3,755 cycles from successful scanner bank-write STOP to verify initial START, ten group selects including three same-bank reselections, and successful terminal restore. The W3 option adds exactly 18,750 cycles after each successful scanner bank write while enabled. Historical 11 first-attempt `REGADDR_NACK` events and the distinct Bank5-select hard stop retain their separate interpretations. No physical root cause follows from this authority check.

Third-party reference `4e4o/nvp6134_ex` is checked out detached at `081ebbff9a2722d47acf16c680594be43cb179e2`. Its `common.h` blob `4b77ed5245354afbbd7e9547d79472c84b51409a` and `nvp6134_drv.c` blob `4af5f10c6a08b2a12f581f4e89f5898f721088f0` match the local W2 reviewed copies (SHA-256 `81E1D55940C5460A61BD51B377546D6F7E70802A8FDDF0B8E0D02B6689D8C922` and `F6AEEA5866E6315C04AB55935574A47CD9AEF5AA5041EDB28CBE3597B2BDE660`). This source is conditional hosted behavior, not a board specification.

The historical ID and the scoped 18/6 audit are documented in `../preflight/HISTORICAL_ID_AND_AUDITOR.md`. No authority conflict or preflight hard stop was found.
