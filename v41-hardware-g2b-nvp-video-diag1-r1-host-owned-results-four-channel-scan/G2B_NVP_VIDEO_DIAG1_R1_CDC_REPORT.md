# CDC disposition and blocker

Formal task CDC disposition: **FAIL / undispositioned**.

Current report: 427 Critical, 874 Warning, 0 Unknown. CDC-1 is 423 rows,
CDC-10 is 2, CDC-13 is 2; warning rules are CDC-6=13 and CDC-15=861.

CDC-1 actual SHA-256:
`BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99`.
The expected `A7FE...` manifest came from the PRODUCT routed DCP and was never
validated on a routed diagnostic design. Both manifests have identical 423
destination endpoints, rule, severity, clock-direction, and exception sets.
Exactly 302 rows differ only in synthesis-selected launch representatives:
285 reset-commit representative bit 1 to bit 0, and 17 ownership representatives
from 10 axis-slot-bit-0 plus 7 release-epoch rows to axis-slot-bit-1. The other
121 rows and all CDC-10/CDC-13 rows are byte-identical. Warning counts and all
destinations are also identical; 220 warning rows differ only by source
representative. No current-result/NVP-diagnostic hierarchy appears in CDC.rpt.

Structural CDC passed and all 17 replacement-method checks passed. These facts
strongly support stale harness physical-name authority rather than a new
crossing, but do not prove Boolean-cone equivalence or authorize a disposition.
Thus the fail-closed blocker is `NVP_DIAG1_R1_DIAGNOSTIC_CDC_MANIFEST_RECONCILIATION_AUTHORITY_REQUIRED`. No hash was silently updated and
no waiver or message suppression was applied.
