# Comparator DCP Discovery and Provenance Decision

Discovery was bounded to the known `C:\FPGA` build/evidence roots and the accepted project/evidence roots under `C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807`. No build was run and filenames alone were not treated as provenance.

## Exact formal Phase-2 comparator

```text
FORMAL_PHASE2_COMPARATOR=FOUND_EXACT
FORMAL_PHASE2_DCP=C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\02_FRESH_BUILD\R1\PHASE1B_routed.dcp
FORMAL_PHASE2_DCP_SIZE=47338027
FORMAL_PHASE2_DCP_SHA256=788248912C227790068B9005651E1C4E1AF05C53A04A27A1C86A711924CAC460
FORMAL_PHASE2_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_PHASE2_SOURCE_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
FORMAL_PHASE2_TOP=ahd_capture_top_xdma
FORMAL_PHASE2_PART=xc7a35tcsg325-2
FORMAL_PHASE2_VIVADO=2025.2_BUILD_6299465
FORMAL_PHASE2_DCP_TO_BIT_PROVENANCE=PASS_EXPLICIT_REOPEN_AND_WRITE_BITSTREAM_CHAIN
```

Proof chain:

- `PRE_HARDWARE_ARTIFACT_MANIFEST_SHA256.txt` records the exact routed DCP at line 37 and exact generated bit at line 25.
- The build log records generation of `PHASE1B_routed.dcp` at lines 2911–2924.
- The same build log explicitly reopens that DCP at line 3082 and then writes `ahd_capture_v41_phase2.bit` at lines 3122–3149.
- `PHASE2_BUILD_IDENTITY.md` identifies source commit `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`, Vivado 2025.2 build 6299465, top `ahd_capture_top_xdma`, part `xc7a35tcsg325-2`, and the exact formal bit hash.

Older plausible formal DCPs were rejected when a different bit hash was proven or the exact DCP-to-bit chain was absent.

## Exact RC-A comparator

```text
RCA_COMPARATOR=FOUND_EXACT
RCA_DCP=C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\V40_1_0_NVP_PATCH\V40_1_0_FINAL_ACCEPTANCE_R2\BUILD\REPORTS\ahd_capture_v40_release_routed.dcp
RCA_DCP_SIZE=3198162
RCA_DCP_SHA256=584010F53D0162B1C8FFD04FCFDE744BBE87C20F4A7A7306310E9BD96AF8AEB3
RCA_BIT_SHA256=A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6
RCA_SOURCE_COMMIT=55ce0df41552bb74e0923f89eff43977b040f2e5
RCA_TOP=ahd_capture_top_pcie
RCA_PART=xc7a35tcsg325-2
RCA_VIVADO=2025.2_BUILD_6299465
RCA_DCP_TO_BIT_PROVENANCE=PASS_EXACT_HASHED_BUILD_OUTPUT_CHAIN
```

Proof chain:

- `RC_A_BUILD_IDENTITY.md` and `RELEASE_SOURCE_TRACEABILITY.md` bind source commit `55ce0df41552bb74e0923f89eff43977b040f2e5`, the exact RC-A bit hash, and routed DCP hash.
- `ARTIFACT_MANIFEST_SHA256.txt` records the exact RC-A bit at line 1 and routed DCP at line 24.
- `vivado_build.log` records the routed checkpoint generation at lines 2005–2018 and the generated release bit at lines 2064–2085. The generated release bit and retained RC-A artifact are byte-identical by SHA-256.
- `ahd_capture_v40_release_project_model.txt` records top `ahd_capture_top_pcie` and part `xc7a35tcsg325-2`.

Exact duplicate routed DCP copies exist in other accepted release-closure roots; the final-acceptance copy above is the canonical comparator for this audit.

## Decision

Both comparators are admissible for identical report-only analysis. Architectural hierarchy may differ, so later comparison is by semantic connectivity rather than forced name equality.
