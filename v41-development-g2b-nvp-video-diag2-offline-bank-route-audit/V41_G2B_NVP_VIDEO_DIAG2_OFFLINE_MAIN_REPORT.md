
# AHD v41 G2B-NVP-VIDEO-DIAG2-OFFLINE

## Outcome

Engineering gate: **PASS**  
Overall result: **PASS_STRONG_BANK6_8_CONFIGURATION_CANDIDATE_HARDWARE_ISOLATION_REQUIRED**

The exact R3 source replay is deterministic and contains 840 physical I2C transactions across seven governed layers. The CH1->Bank5, CH2->Bank6, CH3->Bank7, CH4->Bank8 mapping and route-code mapping are proven. No parity/index defect and no authoritative VDO1 re-arm omission is proven.

## Strong configuration candidate

The source applies 51 stage-2 writes over 37 vendor-private relative addresses to Bank5 only. It applies none of those operations to Banks6-8, while `CONFIGURE_ALL_CHANNELS` is a runtime no-op that verifies only public fields. This is a strong four-channel configuration-completeness candidate, but not an exact causal defect: Bank7/CH3 works despite also receiving no private writes, and the local vendor manual withholds these fields.

## Route and mode result

The PDF defines C2 0/1/2/3 as CH1/2/3/4 under C8=one-port/one-channel, with CA enabling VCLK1/VDO1 and CD selecting its clock. It does not define a mandatory re-arm sequence. The legacy local driver performs startup configuration only and supplies no runtime switch reference. A guessed re-arm patch is therefore forbidden.

## Observability and next gate

R3 provides VCLK, legal raw SAV, parser lock, and aggregate parser outcomes, but lacks raw VDO activity, prefix-stage, all-candidate, legal-EAV, illegal-XY, and direct parser-state counters. That gap prevents offline selection among constant-output, invalid-prefix/parity, and parser-admission causes. The published future protocol specifies one bounded, no-DMA CH1->CH2->CH1 and CH3->CH4->CH3 counter comparison using only the current hot-switch sequence.

## Safety and provenance

No DUT or hardware interface was accessed. No source branch, SSOT, DCP, bitstream, or prior evidence was changed. No correction candidate was created because no proof gate was met.

See `G2B_NVP_DIAG2_OFFLINE_EVIDENCE_INDEX.md` for the complete evidence map.
