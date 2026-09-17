# W3 historical-ID and scoped auditor preflight

## Historical completed-scan ID

Result: `HISTORICAL_ID_AVAILABLE_VALIDATED`. The named local `characterization-hardstop.tar.gz` has exactly **108,145 bytes** and SHA-256 `96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB`. The in-memory extractor checks safe archive-member names, the session/progress/private-manifest identity and schemas, all **26** constituent raw-file sizes and SHA-256 values, rolling hashes, legacy and CONT1R3 sideband hashes, and each record with the accepted SCAN1 manifest and CONT1R3 frozen decoder. Event counts reconcile to 11. No archive content was extracted to disk.

The control and 25 completed campaign scans have generations **1 through 26**, each with Bank0/`F4` raw word `0x00F49005` and Bank0/`F5` raw word `0x00F50105`. Thus device ID is `0x90`, revision ID `0x01`, both valid (`status=0x05`) and with no retry in all 26 completed records. The incomplete next scan is excluded. `HISTORICAL_ID_RECORDS.csv` includes the two raw words, flags, generation and per-file hash for every completed scan; `HISTORICAL_ID_PREFLIGHT.json` binds the archive and record-list hashes. The extractor is `extract_historical_id.py` and opens only local files.

The pinned reference `common.h` labels `0x90` as the shared B/C device ID and `0x01` as the C revision. `nvp6134_drv.c` reads Bank0/`F4` and `F5`, accepts `0x90` or `0x91`, and selects the `0x90` two-port `2MUX_FHD` branch in its default module-init path. This is a **conditional classification of historical measured ID** under that reference source. It does not establish live W3 device identity, camera format, board wiring, or which reference host transport ran. W4 still needs its separately authorized live identity check.

## Narrow W2 18/6 check

Result: `PASS_SCOPED_OCCURRENCE_ALIGNMENT_ONLY`. `check_auditor_18_6.py` independently parses the accepted W1/W2 `W2_SEQUENCE_DIFF.csv` (SHA-256 `C996E946E8E895AC16856AEC950326D5303480DEBE5FA84CF30ADE8927A6F68C`) at pinned evidence commit `f3eafd4341752648f210afd0c8687c5cf4759294` and restricts itself to the 51 `MAREK_STAGE2_SLOT_*` Bank5 rows. It finds **27 matching-value**, **18 differing-value**, and **6 no-comparable-step** rows. None of the 18 differing-value rows directly has Bank5 register `F2`, `F4`, or `F5`.

| Stage-2 slot | Bank/register | FPGA occurrence / scoped reference occurrence | Narrow classification |
|---:|---|---:|---|
| 53 | `05/08` | 2 / 1 | extra occurrence |
| 54 | `05/11` | 2 / 1 | extra occurrence |
| 63 | `05/56` | 1 / 0 | absent key in scoped subpath |
| 106 | `05/64` | 1 / 0 | absent key in scoped subpath |
| 138 | `05/01` | 3 / 2 | extra occurrence |
| 140 | `05/59` | 4 / 3 | extra occurrence |

The JSON receipt `AUDITOR_18_6_PREFLIGHT.json` records these counts and exact rows. This alignment is for the conditional CH0/PAL 1080P2530 core subpath only. It is not a count of correct or wrong device settings, a whole-reference execution comparison, or a reason to edit the frozen autoinit table.
