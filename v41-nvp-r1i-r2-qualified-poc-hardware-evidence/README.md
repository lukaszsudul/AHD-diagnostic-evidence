# AHD v41 R1i–R2 Qualified PoC Hardware Evidence

**Result: THESIS_CONFIRMED / STRONG_PASS**  
**Scope: qualified PoC baseline; production qualification is not claimed**  
**Candidate: R1i fixed PoC**  
**Control: exact unmodified R1h**

| Result | R1i candidate | R1h control |
| --- | ---: | ---: |
| Autoinit NACKs | 0 | 4 |
| `INIT_ERROR` | No | Yes |
| Video | Present | Absent |
| Post-init NACKs | 0 / 30,000 | 0 / 30,000 |

## What was investigated

The legacy NVP I²C master sampled ACK and read data on the same state transition that released SCL, and it continued later transaction phases after a NACK. R1i tested a combined correction: wait for filtered physical SCL high before sampling, stop on the first qualified NACK, and retry the same logical transaction with a bounded backoff. It preserved raw error visibility and added causal/recovery telemetry.

## Frozen hardware comparison

The test order was fixed before measurement:

1. Read-only Formal Phase-2 baseline.
2. A1: fixed R1i PoC.
3. B1: exact unmodified R1h control.
4. Exact Formal Phase-2 restoration and hard stop.

Each arm completed 10,000 WADDR, 10,000 REGADDR, and 10,000 DATA post-init opportunities. The combined post-init sample is therefore 60,000 phase observations. The historical 90,000 count belongs to the earlier R1h-R4 investigation and is not the R1i–R2 denominator.

## Result

R1i initialized successfully, recorded zero autoinit NACKs, did not latch `INIT_ERROR`, and produced normal video. Its reported frame rate was 24.803727 Hz (24.804 Hz rounded). The exact R1h control recorded four autoinit NACKs, latched `INIT_ERROR`, and produced no video. Both arms recorded zero NACKs in all three later 10,000-opportunity phases.

This functionally confirms the combined R1i correction under the frozen same-session PoC conditions. It does **not** prove whether the decisive low-level mechanism was ACK sampling, device readiness, initialization timing, or a combined effect. It is not a production release claim.

## Review map

- [Author summary](AUTHOR_SUMMARY.md)
- [Polish owner summary](OWNER_SUMMARY_PL.md)
- [Authoritative conclusion](final/R1I_R2_AUTHORITATIVE_CONCLUSION.md)
- [Protocol](final/R1I_R2_TEST_PROTOCOL.md)
- [Measurements](final/R1I_R2_MEASUREMENTS.md)
- [Statistical interpretation](final/R1I_R2_STATISTICAL_INTERPRETATION.md)
- [Source provenance](final/R1I_R2_SOURCE_PROVENANCE.md)
- [R1h-to-R1i changeset](final/R1H_TO_R1I_CHANGESET.md)
- [Exact source patch](final/R1H_TO_R1I_SOURCE.patch)
- [Raw campaign CSV](raw/AHD_v41_R1i_R2_RAW.csv)
- [Raw statistics CSV](raw/AHD_v41_R1i_R2_STATISTICAL_ANALYSIS.csv)
- [Known limitations](final/R1I_R2_KNOWN_LIMITATIONS.md)
- [Evidence index](final/R1I_R2_EVIDENCE_INDEX.md)
- [Cryptographic manifest](SHA256_MANIFEST.txt)

The original internal evidence ZIP is referenced by its immutable SHA-256 but is not published because it contains operational authentication and infrastructure detail unrelated to scientific review. The public ZIP is a curated, independently hashed package.
