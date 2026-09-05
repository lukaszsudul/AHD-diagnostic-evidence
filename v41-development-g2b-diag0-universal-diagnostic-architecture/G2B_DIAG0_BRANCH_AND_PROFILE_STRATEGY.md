# Branch and profile strategy

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


PRODUCT remains unchanged at source 92e9b3d914134c044371779def1ee18eaaeda98a. Its signed DCP and bitstream remain immutable references, never diagnostic implementation outputs. PRODUCT_CANDIDATE_MODIFIED = NO.

Future branch: diag/v41-g2b-hw0-universal-diagnostic. Future worktree: C:\FPGA\V41_G2B_DIAG. Base: the exact PRODUCT source above. Neither is created in DIAG0.

| Profile | Diagnostic generators/scheduler | Historical deep R-track probes | LUT gate |
|---|---|---|---|
| PRODUCT | excluded by elaboration | current accepted reduced set | <=90%, preferred 80–85% |
| RESEARCH_DIAGNOSTIC | not automatically added | separately governed research profile | existing research governance |
| HW0_DIAGNOSTIC | included; disabled until START | excluded unless separately authorized | <=98%, 20384 LUT |

Reuse current PRODUCT protection and build substrate, with an explicit three-way profile selection and fatal rejection of unknown/mixed profiles. Keep R1i production observability. No V4L2 requirement. The generator must not enter release/v41.0.0. Do not merge this branch wholesale into release/v41.0.0; independently useful fixes require review and may be cherry-picked individually. DIAG1 starts only after the NVP blockers and governance disposition are resolved.
