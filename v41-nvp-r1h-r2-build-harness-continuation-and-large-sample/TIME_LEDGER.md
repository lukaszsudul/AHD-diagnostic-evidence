# Time ledger — R1h-R2

Task: `V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION`

| Event | Local time (Europe/Warsaw) | UTC time |
|---|---|---|
| Task-root initialization | 2026-08-25T09:09:45.9545663+02:00 | 2026-08-25T07:09:45.9545663Z |
| Exact prompt and P0 identity verification complete | 2026-08-25T09:18:30.7277606+02:00 | 2026-08-25T07:18:30.7277606Z |
| Failed-assertion audit complete | 2026-08-25T09:22:33.1081229+02:00 | 2026-08-25T07:22:33.1081229Z |
| Corrected task-local harness frozen | 2026-08-25T09:27:13.0081317+02:00 | 2026-08-25T07:27:13.0081317Z |
| Sole project-setup dry-run complete | 2026-08-25T09:56:28.2140353+02:00 | 2026-08-25T07:56:28.2140353Z |
| Sole semantic elaboration started | 2026-08-25T10:08:46.1399957+02:00 | 2026-08-25T08:08:46.1399957Z |
| Sole semantic elaboration complete | 2026-08-25T10:09:23.6618725+02:00 | 2026-08-25T08:09:23.6618725Z |
| R1h-R2 prebuild manifest finalized | 2026-08-25T10:19:05.9448389+02:00 | 2026-08-25T08:19:05.9448389Z |
| Sole clean build consumed | 2026-08-25T10:37:41+02:00 | 2026-08-25T08:37:41Z |
| Post-synthesis checkpoint generated | 2026-08-25T10:58:33+02:00 | 2026-08-25T08:58:33Z |
| Post-synthesis mapping/resource gate evaluated | 2026-08-25T10:59:30+02:00 | 2026-08-25T08:59:30Z |
| Sole build terminal hard stop | 2026-08-25T10:59:35.7750435+02:00 | 2026-08-25T08:59:35.7750435Z |

No FPGA, host, MMIO, DMA, or physical action was performed. The sole build
performed exactly one synthesis and then stopped before optimization,
placement, routing, and bitstream generation because the Slice-LUT margin gate
failed by 535 LUTs.
