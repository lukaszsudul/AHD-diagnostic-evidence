# AHD v41 G2B-LUT1 Sign-Off Recovery Evidence Index

## Package state

| Field | Value |
|---|---|
| Evidence directory | v41-development-g2b-lut1-signoff-recovery |
| Engineering state | BLOCKED |
| First blocker | Group 13 REQUIRED_BUS_SKEW_TIMEOUT |
| Pre-bitstream gate | FAIL |
| Bitstream / LTX | NOT PRODUCED / NOT PRODUCED |
| Hardware accessed | NO |
| Publication | PENDING |
| Evidence commit | NONE |
| Remote read-back | NOT_RUN |

This index describes the package at the Group-13 hard stop. A PRESENT entry
exists in this directory. A RAW entry is direct tool output. A TOOL entry is
executable provenance but is not itself a sign-off result. PENDING means the
required artifact or phase was not completed at this execution point.

## Primary governed artifacts

| Artifact | Status | Purpose | SHA-256 / disposition |
|---|---|---|---|
| V41_G2B_LUT1_SIGNOFF_RECOVERY_REPORT.md | PRESENT | Main blocked engineering report | pending final package manifest |
| G2B_LUT1_EVIDENCE_INDEX.md | PRESENT | This evidence map | pending final package manifest |
| G2B_LUT1_SIGNOFF_RECOVERY_XDC_DIFF.md | PRESENT | Three-way Group-9 XDC scope proof | E897F676395184F66C016CD64A2151BEEB29127297A94B3AEC180F6C7DB0068E |
| G2B_LUT1_SOURCE_CHANGE_RECEIPT.md | PRESENT | Branch, parent, commit, and tree authority | CF7C7AADF2DFEB15CA01B52FFCDB0CDD0D62896D945A0E4993C64516E2C2B515 |
| G2B_LUT1_RECOVERY_MODE_DECISION.md | PRESENT | Routed-DCP reuse decision | 3E2CE970A60FEFF1BDE95A97CDB816BA15AA0431FFCB7162C6C378BD1802ECA8 |
| G2B_LUT1_GROUP9_SIGNOFF_RESULTS.csv | PRESENT | Slot/generation/epoch 6.000 ns results | 66D28113BD52EC0C32247FAAC5CC73B35E729B27F1F2E7A644643601F4B3638C |
| G2B_LUT1_GROUP9_GATE.txt | PRESENT | Promoted ownership CDC gate receipt | 4531FF587FEE60FA99DC6523C7F11E6585945390D1FE5AB66CA4B30E040BB25B |
| G2B_LUT1_GROUPS10_17_RESULTS.csv | PRESENT | Exact Groups 10-17 result ledger | 666A403FC01DADE0E95D3329D119473CF8D7D0E7EAD2B1E624F495FDAB5FFFF7 |
| G2B_LUT1_GROUPS10_17_GATE.txt | PRESENT | Aggregate failure and first-blocker receipt | 148C52D61CF059794F3145A2FEE361818A9630E2A453AC4E60CCED35CFEC3535 |
| G2B_LUT1_PROCESS_CLEANUP_RECEIPT.txt | PRESENT | Independent post-timeout zero-Vivado check | 14E62127C48018BB6CBB26BA96593439D3F089837EC39B9B1CD752360CBCFA5D |
| G2B_LUT1_FUNCTIONAL_PROTECTION.md | PRESENT | ABI/MMIO/G2B/R1i/XDMA protection | D04186E97B8D400BDC5C89EE6A83E53629AAAA78865A85EC61000EFE81703AD0 |
| G2B_LUT1_OFFLINE_PROTECTION_GATE.txt | PRESENT | Machine-readable offline protection receipt | 1AF5EB7F1DEAF98C271FF7C10C758895D2B81A3B891D259F6867B260C1F10A7D |
| G2B_LUT1_THROUGHPUT_SUMMARY.md | PRESENT | Governed 288 MB/s offline capacity gate | 374480090134AD93C516254515F3165C00BF40C5A95F923AFC70A56E3A4557B9 |

## Exact identity anchors

| Anchor | Identity |
|---|---|
| SSOT revision | 4 |
| META-4R2 evidence commit | 27dcf152e862c6db88a365328b92c0fd250f04c2 |
| BS3 evidence commit | 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae |
| Source parent | 224d194e5f82c85bcb29297561c5d5e76d28063b |
| Source commit | 66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49 |
| Source tree | 1e67e3f1fe06669839fe9ff8573e4d1e0114a889 |
| Active XDC SHA-256 | 6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227 |
| Sealed routed DCP SHA-256 | EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83 |
| Full base XDC SHA-256 | 3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507 |
| BS3 candidate XDC SHA-256 | AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087 |
| Device | xc7a35tcsg325-2 |
| Vivado | 2025.2, SW build 6299465 |

## Raw Group-9 provenance

Directory: raw/group9_fresh/

The directory contains the fresh BS3 launch command, console/Vivado logs,
external-watchdog receipt, exact-identity receipt, synchronizer inventory,
object inventories, applied constraints, per-family timing result receipts,
per-family worst-path reports, and query phase markers.

The governing Group-9 gate binds the following raw result identities:

| Raw receipt | SHA-256 |
|---|---|
| Exact identity receipt | 9390572741612FCA879A7EED4E5AB48413E6AF4866F401A5E705C4E9BF8A9F95 |
| Slot timing result | DC9627A742CF31A8C9D41E874B9EDB5539854E7B960A8988113DBE5F6DD128FF |
| Generation timing result | E880B9B12E3D0E8A7FB6F61DDD78BF3F3249321A67CE2AC1C232BE42BB04F2B7 |
| Epoch timing result | 8D081B2B03E93A6100C91832D3EF84D82F12683E550BB930D9F81B41803F0A8E |

GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = NO.

## Raw Groups 10-17 provenance

Directory: raw/groups10_17/

| Raw artifact | Status | SHA-256 / result |
|---|---|---|
| PREFLIGHT.txt | RAW PASS | 04DA7F96E72480E6D5249359D657478C9F2911210F162E058C34C914EA9485D2 |
| group_10_DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI/worker_result.txt | RAW PASS | E5B566114337E2517272938402F06A2B391412D50B49BC8D3B0F5E8DF5DEE30C |
| group_11_DESCRIPTOR_GENERATION_SOURCE_TO_AXI/worker_result.txt | RAW PASS | B43BA5805176FC123C3D67484E4E1E8E1A79581428CB2042842C27952F56DB00 |
| group_12_DESCRIPTOR_EPOCH_SOURCE_TO_AXI/worker_result.txt | RAW PASS | A073C8FCC35C8B095B803AAFCD7F4EF3F2A4C77D38F70B0E253424A327DC0DA7 |
| group_13_RESET_RETURN_SOURCE_TO_AXI/EXTERNAL_WATCHDOG.txt | RAW TIMEOUT | 6E751C0E172A6FCCCA89D4539AB2DEF9135BDE6D708D48E8FBCAB73C27EA6E0D |
| Group 13 query result report | ABSENT | query terminated at 301.094 s; no actual/slack |
| Groups 14-17 raw directories | ABSENT | NOT_RUN_AFTER_BLOCKER |

Each completed or attempted group directory includes its launch command,
worker-start/query phase markers, worker or watchdog receipt, resolved-object
inventory where available, isolated constraint context, console/Vivado logs,
warnings inventory, and group disposition.

## Tool provenance

These files are present under tools/. Their presence does not imply execution.

| Tool | Status | SHA-256 | Use |
|---|---|---|---|
| G2B_LUT1_GROUPS10_17_WORKER.tcl | TOOL, executed for Groups 10-13 only | C5981DC0FA27892C1CCD150ADEBFE032443EBC33B0B7039911CF226D2415FCCA | One isolated Group 10-17 bus-skew query |
| Invoke-G2BLut1Groups10To17.ps1 | TOOL, executed once | 9543B171C650AA18D19C361445B1AD0EAE876BBFD7D32A825D5B8156B9C841DA | Sequential one-attempt watchdog |
| g2b_lut1_routed_signoff_recovery.tcl | TOOL, NOT RUN | 1949AA25A070D943F8EBB1C03568E97381B7103248916498E931787748EACD35 | Prepared final routed-signoff/bitstream finalizer |
| Invoke-G2BLut1RoutedSignoffRecovery.ps1 | TOOL, NOT RUN | 563B82832D7B9951B4F1009B97CE81E1F47162448D533CF6C5535159FDDBD21E | Prepared bounded finalizer supervisor |

The finalizer tools were not launched because the Groups 10-17 gate failed.
No finalizer output directory or result receipt exists.

## Fail-closed downstream artifacts

| Required artifact | Status | SHA-256 / reason |
|---|---|---|
| G2B_LUT1_TIMING_SUMMARY.md | PRESENT; gate FAIL/NOT_RUN | A80ED5AE583F33111E5C82CAAB338581995EA7AFD5491CBFF36015A0CB3ECEA9 |
| G2B_LUT1_DRC_SUMMARY.md | PRESENT; gate FAIL/NOT_RUN | 26A4B640F8D2DB3F41C5E06FD36F13868CEBBF9ADBBE0227B0ABC7553A7D855E |
| G2B_LUT1_CDC_DISPOSITION.md | PRESENT; overall FAIL/NOT_RUN; ownership PASS | 2F251B4C667F0CC0D6B941F63A069EDDE0D2838F2AE73469F90E423C975D0838 |
| G2B_LUT1_CLOCK_SUMMARY.md | PRESENT; gate FAIL/NOT_RUN | C6676B9F01757C7880C7B807A0A1B224EE0229342998B534C6454E7D7EE1ECEA |
| G2B_LUT1_RESOURCE_SUMMARY.md | PRESENT; gate FAIL/NOT_RUN | 09B3A1FA08E819AF16BC7B15A647FD4C00A262C72E11AF2820AAFB98DE4BCCDD |
| G2B_PRE_BITSTREAM_HARD_GATE.txt | PRESENT; PRE_BITSTREAM_HARD_GATE=FAIL | 98AC1AD33ACFD97148D271B82F1571C24F5F1F82DC4A87240E337C2A7B52D8C7 |
| G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json | PRESENT no-candidate record | 72CE6116E913F11CE6D9DA8269F1CF2C6CB1F6AA0E412C799C84E126C6CD4808 |
| G2B_LUT1_STATE.json | PRESENT blocked-state record | 19F599D7020BFE7E682F715652DA60287EE4BE76A44CB675C22062AE425F2656 |
| G2B_LUT1_SHA256_MANIFEST.txt | PRESENT | manifest self-entry intentionally omitted by design |
| Bitstream metadata/hash | NOT APPLICABLE | no bitstream produced |
| LTX metadata/hash | NOT APPLICABLE | no debug probes produced |

## Publication boundary

No evidence commit or remote mutation has been performed for this recovery
directory. Before any publication, the blocked-state package must receive its
final state record and SHA-256 manifest, then be committed and pushed without
force under explicit publication authority. Remote read-back remains NOT_RUN.
