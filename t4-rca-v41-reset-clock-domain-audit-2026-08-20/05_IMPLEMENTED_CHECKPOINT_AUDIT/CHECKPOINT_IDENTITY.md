# Checkpoint identity

- RC-A authoritative routed DCP: `ahd_capture_v40_release_routed.dcp`, SHA-256 `584010F53D...`; sealed RC-A identity links it to commit `55ce0df...`, bit `A43B9280...`, Vivado 2025.2.
- Exact v41 Phase-2 build log proves `PHASE1B_routed.dcp` generated the sealed bit, but that generated DCP was not retained: `MISSING_PROVEN_CHECKPOINT`.
- A v41 precursor reference routed DCP is retained, SHA-256 `A73EC0A...`, provenance commit `b8523be...`. It was opened only as a non-authoritative structural reference.
- No exact Phase-3 routed DCP was retained. Diagnostic R2/Z8 checkpoints are not substitutes.

No replacement implementation or bitstream was generated.