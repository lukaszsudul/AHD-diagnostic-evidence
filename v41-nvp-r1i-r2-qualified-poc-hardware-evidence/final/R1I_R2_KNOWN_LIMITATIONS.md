# R1i–R2 Known Limitations

- This is a qualified proof-of-concept baseline, not a production release or production qualification.
- The hardware evidence is one frozen same-session A1/B1 comparison.
- The R1h control recorded only four autoinit NACKs; phase-specific counts are small.
- There is no post-init statistical separation: both arms recorded zero NACKs in all three 10,000-opportunity phases.
- The exact causal mechanism remains unresolved. ACK sampling, readiness/retry, initialization timing, or a combined effect may explain the functional separation.
- No multi-board or board-population campaign was performed.
- No temperature or supply-voltage campaign was performed.
- No long-duration reliability or aging campaign was performed.
- No full cold-start population campaign was performed.
- XDMA throughput and multi-channel DMA behavior were not qualified by this PoC.
- Formal verification remains `UNVERIFIED`.
- VCCO droop, ground bounce, and analog margin were not directly measured or proven.
- The public package omits internal access/authentication procedures and personal paths. Their omission does not change scientific data; the immutable internal archive remains referenced by hash.
