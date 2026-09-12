# Reference slice sequence

- Reference repository/commit: `4e4o/nvp6134_ex` / `081ebbff9a2722d47acf16c680594be43cb179e2`
- Reference file identity: `video.c` SHA-256 `CBC10B8585CF9F300C47EBD40AACB08635EF62784CF94B691B722758BA49657A`
- Function: `nvp6134_getvideoloss`
- Entry condition: NOVID asserted; the phase-level write additionally requires format-set state clear
- Source order: select Bank5, write `0x08=level`, write `0x05=0xA4`, then call a stored-mode-dependent helper that can write `0x08=0x50`
- Source phase mapping: modulo phases map to `0x50 -> 0x40 -> 0x60`
- Reset nuance: the counter increments before dispatch, so the first post-reset level is `0x40`
- Inter-write delay: none visible in the source branch
- Detector-path delay after handling: approximately `200 ms`
- R1 mandatory executor order: select Bank5, write `0x05=0xA4`, read back, write `0x08=level`, read back
- R1 mandatory campaign order: `0x50 -> 0x40 -> 0x60`

The two functional-write orders are reversed. Implementing either order would violate a different mandatory authority. The source is pinned and the R1 action order is explicit, so this is not resolved as ambiguous wording.

First blocker: `ACQ1_COMPAT0_R1_REFERENCE_SEQUENCE_AUTHORITY_CONTRADICTION`
