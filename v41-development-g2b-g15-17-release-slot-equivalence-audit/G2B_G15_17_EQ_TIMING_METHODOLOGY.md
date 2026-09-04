# Candidate timing-methodology review

The focused command evaluated `TIMING-32`, `TIMING-34`, `TIMING-37`, `TIMING-38`, and `TIMING-39` in 7.633 seconds after the combined candidate was active.

## Findings

| Rule | Findings | Candidate-slot relevance | Disposition |
|---|---:|---|---|
| TIMING-32 | 0 | None | ABSENT |
| TIMING-34 | 11 | None | PRESENT_GLOBALLY_NOT_CANDIDATE_ATTRIBUTABLE |
| TIMING-37 | 0 | None | ABSENT |
| TIMING-38 | 0 | None | ABSENT |
| TIMING-39 | 1 | None | PRESENT_GLOBALLY_NOT_CANDIDATE_ATTRIBUTABLE |

The 11 TIMING-34 warnings correspond one-for-one to the 11 retained non-release bus-skew constraints. Their first endpoints are unrelated mailbox, status, Gray, snapshot, transport, descriptor, and hard-event objects. The one TIMING-39 warning is the retained transport-payload bus-skew at constraint position 46, first endpoint `overflow_count_source_reg[0]/R`. The position-46 relation also accounts for one of the TIMING-34 warnings.

The applied context had zero release-slot bus-skew commands. The Groups 15-17 candidate uses only nine scoped datapath-only max-delay relations, so it recreates neither the retired release-slot TIMING-34 pattern nor its multi-level TIMING-39 pathology. The report summary's `STATUS=PASS` means the query completed; the 12 global findings still require and receive the disposition above.

## Per-family result

Every one of the nine families has the same focused disposition:

- TIMING-32: absent.
- TIMING-34: global finding present, unrelated and not applicable to the family.
- TIMING-37: absent.
- TIMING-38: absent.
- TIMING-39: global finding present, unrelated and not applicable to the family.

`CANDIDATE_TIMING_METHODOLOGY = PASS_WITH_DISPOSITION`
