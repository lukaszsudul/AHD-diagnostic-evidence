# CH1 format detection manifest

- Authority: pinned reference commit `081ebbff9a2722d47acf16c680594be43cb179e2` and frozen SCAN0 detector artifacts.
- Frozen detector decision-tree SHA-256: `110A42871547B7A3DB5212A35BA9FC90F54B851EF6E62FFF7A0DDEFBB22B238B`.
- Frozen detector read-set SHA-256: `688A09C524D9E265E2A3CCA45BAB99A3E5B5966A713BF2218A19AE99CFDCC7CF`.
- Campaign state: fresh host-owned generation; no inherited buffers.
- Required stability: three consecutive complete, coherent, byte-identical tuples.
- Tuple: Bank0 `A8`; Bank5 `F0/F2/F3/F4/F5/E2/E3/E8/E9/EA/EB`; public lock/status fields.
- Bank discipline: verified selection and exact entry-bank restore for every atomic snapshot.
- Raw `F0=0x31` alone: `INSUFFICIENT`.
- Exact initial `F0=0x31` reference branch: the published discriminator manifest includes nine unique functional preconditioning/postlude targets, all already contained in the 137-target mode/EQ set.
- Decision predicate: AHD only when Y-plus >= 80, Y-minus >= 80 and ACC gain > 2010; otherwise CVI for the 1080p25 ambiguity.
- Output set: `AHD_1080P25_CONFIRMED`, `CVI_1080P25_CONFIRMED`, `OTHER_FORMAT_CONFIRMED`, or `FORMAT_UNRESOLVED`.
- Execution authority: `NOT_REACHED`; the earlier complete rollback authority gate failed.
- Functional writes executed: `0`.
