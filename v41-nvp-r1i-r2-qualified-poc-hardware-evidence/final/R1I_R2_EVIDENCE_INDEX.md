# R1i–R2 Public Evidence Index

## Primary review path

1. [README](../README.md)
2. [Author summary](../AUTHOR_SUMMARY.md)
3. [Authoritative conclusion](R1I_R2_AUTHORITATIVE_CONCLUSION.md)
4. [Measurements](R1I_R2_MEASUREMENTS.md)
5. [Statistical interpretation](R1I_R2_STATISTICAL_INTERPRETATION.md)
6. [Test protocol](R1I_R2_TEST_PROTOCOL.md)
7. [Source provenance](R1I_R2_SOURCE_PROVENANCE.md)
8. [Changeset explanation](R1H_TO_R1I_CHANGESET.md) and [exact patch](R1H_TO_R1I_SOURCE.patch)
9. [Known limitations](R1I_R2_KNOWN_LIMITATIONS.md)
10. [Redaction log](R1I_R2_PUBLICATION_REDACTION_LOG.md)

## Machine-readable evidence

- `raw/AHD_v41_R1i_R2_RAW.csv`: one exact row per A1/B1 arm.
- `raw/AHD_v41_R1i_R2_STATISTICAL_ANALYSIS.csv`: exact phase-level descriptive statistics.
- `raw/A1/` and `raw/B1/`: byte-for-byte decoded telemetry, word maps, and raw captures from both read points. The two extraction receipts have only their personal transport-log paths redacted and embed their original hashes.
- `final/AHD_v41_R1i_R2_DEPLOYMENT_AND_TEST_STATE.json`: sanitized final state.

## Hardware receipts

- `hardware/A1_PUBLIC_RECEIPTS.txt`: R1i programming, independent DONE, runtime identity, and sample gate.
- `hardware/B1_PUBLIC_RECEIPTS.txt`: R1h programming, independent DONE, runtime identity, and sample gate.
- `hardware/FORMAL_PHASE2_PUBLIC_RECEIPTS.txt`: final restoration and runtime identity.
- `hardware/AHD_v41_R1i_R2_HARDWARE_TRANSCRIPT.txt`: curated chronological result and operation accounting.

## Implementation artifacts

| Role | File | Bytes | SHA-256 |
| --- | --- | ---: | --- |
| Qualified R1i PoC | `implementation/R1I_POC.bit` | 2,192,144 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| Exact R1h control | `implementation/R1H_CONTROL.bit` | 2,192,144 | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` |
| Exact Formal Phase-2 restore | `implementation/FORMAL_PHASE2.bit` | 2,192,144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |

No `.ltx`, probe, or DCP is published. The qualified flow required no LTX; MMIO/BRAM instrumentation and independent DONE receipts supplied observability. DCPs are not required to review this hardware result and would add large unrelated payloads.

## Integrity model

The original internal archive remains immutable and is referenced by its SHA-256. Publication-relevant raw files are copied byte-for-byte. Transformed public documents state their original SHA-256 and are separately hashed in the public manifest. The sanitized public ZIP is a new artifact and is never represented as byte-identical to the internal archive.

The original-to-public hash mapping for every redacted source artifact is in [R1I_R2_PUBLICATION_REDACTION_LOG.md](R1I_R2_PUBLICATION_REDACTION_LOG.md). `SHA256_MANIFEST.txt` is authoritative for every public payload file.
