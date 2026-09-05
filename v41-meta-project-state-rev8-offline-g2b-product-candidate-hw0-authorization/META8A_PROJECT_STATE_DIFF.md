# META-8A project state diff

UTF-8 textual diff of the exact verified revision-7 files and proposed revision-8 files. Changelog old bytes separately verified unchanged; only one new entry is appended.

```diff
--- a/project-current-state/ACTIVE_BASELINES.md
+++ b/project-current-state/ACTIVE_BASELINES.md
@@ -1,6 +1,6 @@
 # AHD Active Baselines and Working Identities
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 This page distinguishes accepted/frozen baselines from active or provisional
 working branches. Branch existence is provenance; it does not confer
@@ -111,13 +111,13 @@
 | G2B MMIO contract | `FROZEN`, `0x3800..0x3BFF` |
 | Linux consumer contract | `FROZEN_INPUT_CONTRACT` for transport parsing only |
 | G2B-PRE contract-input readiness | `READY`; this is historical interface readiness, not current G2B-IMPL readiness |
-| G2B-HW | lifecycle `BLOCKED`; final offline sign-off, pre-bitstream gate, and a bitstream candidate do not exist; hardware remains `NOT_PROVEN` |
+| G2B-HW | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; candidate available; hardware NOT_PROVEN |
 | Evidence | `v41-development-g2b-pre-c2h-abi-mmio-freeze` at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
 | G2B-LUT0 | `ACCEPTED`; resource-architecture review only |
-| Build profiles | `PRODUCT` and `RESEARCH_DIAGNOSTIC`, both `AUTHORIZED_NOT_IMPLEMENTED` |
+| Build profiles | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC post-G2B qualification not promoted |
 | PRODUCT resource policy | LUT hard gate `<= 90%`; preferred target `80–85%`; estimated 84.192% is not qualification evidence |
-| G2B-IMPL | lifecycle `BLOCKED`; `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; Groups 15–17 candidate-XDC implementation and remaining routed hard gates are pending; no accepted offline-qualified implementation |
-| G2B-LUT1 | lifecycle `PLANNED`; readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` |
+| G2B-IMPL | Exact one-channel PRODUCT implementation accepted through `G2B-LUT1-SIGNOFF-RECOVERY-4`; hardware NOT_PROVEN |
+| G2B-LUT1 | `ACCEPTED`; `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; next gate `G2B-HW0-PRODUCT` |
 | Retired Group-9 method | `GLOBAL_SET_BUS_SKEW_3NS`; `RETIRED_FROM_REQUIRED_SIGNOFF` for `OWNERSHIP_AXI_TO_SOURCE` |
 | Current Group-9 method | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; `PROMOTED` |
 | Ownership CDC basis | Two-stage request and acknowledgement synchronizers; held 58-bit stable-data payload; source hold until acknowledgement; reset/epoch coherency |
@@ -137,14 +137,15 @@
 | Group-14 structural basis | Held 56-bit generation/epoch release token; same-edge token/toggle launch; two-stage release-toggle synchronization for normal use; two-stage transport-request synchronization for reset accounting; stable-data lifetime; fail-closed generation/epoch/ownership identity; captured release-phase retirement/completion barrier; destination-use ordering; reset/release coherency |
 | Group-14 evidence disposition | `GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION`; `SIGNOFF_RUNTIME = PRACTICAL`; replacement `SAFER_AND_MORE_SEMANTICALLY_CORRECT` |
 | HISTORICAL Group-14 promotion-time RTL/XDC disposition | `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from evidence commit `9e91315968453e859006077191cd5fc711fc6b96` |
-| Remaining sign-off | `GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`; `GROUP13 = PRESERVE_PASS`; `GROUPS_15_TO_17 = PROMOTED`; G2B-HW remains blocked |
+| Offline sign-off completion | Groups 1–17 and final routed/pre-bitstream gates PASS; hardware separate |
 | Ownership evidence | BS1R `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62`; BS2 `4699632c591238fee46ada3b0de37532fddd0b6f`; BS3 `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` |
 | Reset-return evidence | `v41-development-g2b-g13a-reset-return-signoff-audit` at `10c7c2898d162af8e2262b3f99861c7d560c4557` |
 | Release-slot evidence | `v41-development-g2b-g14a-release-slot0-signoff-audit` at `9e91315968453e859006077191cd5fc711fc6b96` |
 | Resource evidence | `v41-development-g2b-lut0-resource-attribution` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` |
 
-These accepted architecture baselines do not promote source, bitstream, DMA,
-Gen2, throughput or Linux/V4L2 results. Resource estimates remain unmeasured.
+Earlier architecture-only boundaries remain historical. META-8A accepts the
+exact source-bound offline PRODUCT candidate below. Hardware DMA, Gen2,
+throughput and Linux/V4L2 are not qualified.
 
 ## META-7R combined release-slot promotion
 
@@ -158,36 +159,12 @@
 `RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
 requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
-
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
-
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
-
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
 
 
 ## Held research context
@@ -215,3 +192,28 @@
 `be94f88ee8d179f12928ab791bdae27c22cd1762`, tree
 `e128ff47a5e21e8131971f5e5caa7657e2eccc7f`. This is an audit context, not the
 qualified v41 baseline.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/CHANGELOG.md
+++ b/project-current-state/CHANGELOG.md
@@ -558,3 +558,47 @@
 Audit package: `v41-meta-project-state-rev7-groups15-17-release-slot-signoff`. One ordinary non-force promotion commit;
 remote byte/hash read-back is an executor completion action recorded after
 publication. Earlier changelog bytes are preserved unchanged.
+
+
+## PROJECT_STATE_REV 8 — 2026-09-05 — META-8A
+
+Update type: TRACK_GATE_ACCEPTANCE. SSOT WRITE AUTHORIZED.
+Expected prior revision: 7; resulting revision: 8. Owner/Architect decision:
+META-8A_TASK_DIRECTIVE. Evidence: `6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4`.
+
+Accept exact G2B-LUT1-SIGNOFF-RECOVERY-4 as completed offline PRODUCT gate;
+G2B-LUT1 ACCEPTED, maturity OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE. Last accepted gate: G2B-LUT1-SIGNOFF-RECOVERY-4; next allowed
+engineering step: G2B-HW0-PRODUCT, PLANNED / AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION. G2B-HW NOT_STARTED / NOT_PROVEN.
+
+Source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; signed-off DCP `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`; bitstream `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`,
+2192144 bytes. Runtime logic fingerprint 224d194e5f82c85bcb29297561c5d5e76d28063b
+and BUILD_FLAGS 0x00000103 intentionally differ from governed source identity.
+Both layers must be verified in the future separate hardware gate.
+
+All Groups 1–17 and final offline hard gates PASS; actual PRODUCT LUT 83.490%.
+R1i qualified PoC ACCEPTED/FROZEN preserved. No hardware operation or proof,
+measured 288 MB/s, release, Flash authorization, V4L2, synthetic generator,
+four-input or two-channel qualification. DIAG0 remains BLOCKED / NOT_PROMOTED.
+Source/XDC/binaries unchanged; Vivado not executed. Historical entries remain
+byte-for-byte unchanged. GOVERNANCE revision metadata alone advances to 8.
+
+Exactly 16 affected SSOT files:
+
+- project-current-state/ACTIVE_BASELINES.md
+- project-current-state/CHANGELOG.md
+- project-current-state/COMPATIBILITY_MATRIX.csv
+- project-current-state/CURRENT_ARCHITECTURE.md
+- project-current-state/CURRENT_INTERFACES.md
+- project-current-state/CURRENT_REQUIREMENTS.md
+- project-current-state/CURRENT_RESOURCE_STATE.md
+- project-current-state/CURRENT_STATUS.md
+- project-current-state/CURRENT_TRACKS.md
+- project-current-state/EVIDENCE_MAP.md
+- project-current-state/GOVERNANCE.md
+- project-current-state/OPEN_DECISIONS.md
+- project-current-state/PROJECT_STATE.json
+- project-current-state/README.md
+- project-current-state/SHA256_MANIFEST.txt
+- project-current-state/TRACK_STATUS.json
+
+Audit package: `v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization`. One ordinary non-force commit. Publication SHA and remote read-back are post-commit executor completion data; no future SHA or precompleted remote PASS is invented here.
--- a/project-current-state/COMPATIBILITY_MATRIX.csv
+++ b/project-current-state/COMPATIBILITY_MATRIX.csv
@@ -1,19 +1,20 @@
 Consumer,Dependency,Current_Interface,Status,Current_Revision,Compatibility_Risk,Required_Action,Evidence
 "FPGA G-track","Qualified NVP/I2C behavior","R1i commit 20c3323d; 25 kHz SCL/ACK/STOP/BUS_FREE/retry/timeout/bank/MMIO contract","FROZEN","1","Any source or timing regression invalidates the qualified PoC baseline","Preserve exact behavior; validate equivalence; obtain Owner decision before baseline change","955ba0cd2462f4dec9dcb086175ab6eca57365bb:v41-nvp-r1i-r2-qualified-poc-hardware-evidence; b5efb25082d7d18c8e022142e2303fd8a7bc3c6d:v41-development-g0-baseline-freeze"
 "FPGA G-track","C2H transport architecture","One C2H/card; two private four-record rings; shared formatter; record-boundary round-robin","ACCEPTED","1","Implementation may diverge from accepted scheduling/ownership or exceed resources","Implement only after gate authorization; preserve channel isolation and record boundaries","f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd:v41-development-g1-integration-architecture"
-"FPGA G2B implementation","G2A implementation-input base","ARCHITECTURE_COMPATIBLE: G2B-PRE accepts integration/v41-r1i-gen2-g2a commit 224d194e5f82c85bcb29297561c5d5e76d28063b as its exact implementation input; this does not advance the separately tracked G2A gate from ACTIVE; legacy v40B identity and all behavior through 0x37FF remain protected; no G2B C2H or MMIO implementation is present","FROZEN","2","The accepted implementation input could be mistaken for G2A gate promotion or a G2B data-plane/hardware result","Start future G2B work only from the accepted input commit; preserve legacy/R1i behavior; do not advertise the frozen ABI before it is implemented","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze"
-"FPGA and host implementations","AHD_C2H_TRANSPORT_ABI_V1","ARCHITECTURE_COMPATIBLE: lifecycle FROZEN and semantic status FROZEN_FOR_G2B; version 1; 4096-byte record with 64-byte header, 3840-byte UYVY payload, 192 zero bytes; fixed sequence/epoch/identity/parser rules; implementation NOT_IMPLEMENTED and hardware NOT_PROVEN","FROZEN","2","Producer/parser divergence would corrupt fixed boundaries, identities, continuity, or frame assembly","Implement and validate the exact Markdown/JSON contract; reject unsupported version or malformed fixed records; never reinterpret padding or reserved fields","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze"
-"G2B-PRE gate","C2H ABI and MMIO architecture freeze","ARCHITECTURE_COMPATIBLE: engineering PASS; AHD_C2H_TRANSPORT_ABI_V1 frozen; AHD_V41_G2B_MMIO_V1 frozen at 0x3800..0x3BFF; support and implemented-this-build capabilities are distinct; no hardware qualification","FROZEN","2","An architecture PASS could be misreported as implemented transport, DMA, Gen2 negotiation, or throughput proof","Use this package as the only G2B interface input; retain NOT_IMPLEMENTED and NOT_PROVEN until later accepted evidence and META promotion","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze"
-"Future G2B implementation","Frozen G2B transport ABI and MMIO contract","Not offline-qualified; G2B-LUT1 is READY_FOR_SIGNOFF_RECOVERY at G2B-LUT1-SIGNOFF-RECOVERY-4; Group-9 PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-13 SETTLING_PLUS_STRUCTURAL_CDC and its PASS remain authoritative; Group-14 RELEASE_SLOT_0_AXI_TO_SOURCE requires SETTLING_PLUS_STRUCTURAL_CDC and its old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew is RETIRED_FROM_REQUIRED_SIGNOFF; no bitstream or hardware result; Groups 9-14 PASS preserved; Groups 15-17 SETTLING_PLUS_STRUCTURAL_CDC promoted; old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew RETIRED_FROM_REQUIRED_SIGNOFF for each; partial routed equivalence, proven safety protocol, independent slot checks","BLOCKED","7","An implementation could violate frozen bytes, ownership, reset-return or release-slot coherency, protected legacy timing, resource policy, or Linux expectations","In C:/FPGA/V41_G2B at G2B-LUT1-SIGNOFF-RECOVERY-4 implement G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc; validate nine independent 6.000 ns families with structural CDC, 13.468 ns launch-to-use basis and 7.468 ns gross reserve; preserve Groups 9-14 PASS and unrelated constraints; complete routed timing, DRC, CDC, clocks/PRODUCT resources and pre-bitstream gate; no META RTL/XDC/bitstream/hardware action","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62:v41-development-g2b-bs1r-single-sink-bus-skew-retry; 4699632c591238fee46ada3b0de37532fddd0b6f:v41-development-g2b-bs2-alternative-timing-equivalence; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit"
+"FPGA G2B implementation","G2A implementation-input base","ARCHITECTURE_COMPATIBLE: G2B-PRE accepts integration/v41-r1i-gen2-g2a commit 224d194e5f82c85bcb29297561c5d5e76d28063b as its exact implementation input; this does not advance the separately tracked G2A gate from ACTIVE; legacy v40B identity and all behavior through 0x37FF remain protected; this historical input commit is distinct from the accepted exact Recovery-4 offline PRODUCT candidate","FROZEN","8","The accepted implementation input could be mistaken for G2A gate promotion or a G2B data-plane/hardware result","Start future G2B work only from the accepted input commit; preserve legacy/R1i behavior; do not advertise the frozen ABI before it is implemented","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
+"FPGA and host implementations","AHD_C2H_TRANSPORT_ABI_V1","ARCHITECTURE_COMPATIBLE: lifecycle FROZEN and semantic status FROZEN_FOR_G2B; version 1; 4096-byte record with 64-byte header, 3840-byte UYVY payload, 192 zero bytes; fixed sequence/epoch/identity/parser rules; exact one-channel PRODUCT implementation OFFLINE_QUALIFIED; hardware NOT_PROVEN","FROZEN","8","Producer/parser divergence would corrupt fixed boundaries, identities, continuity, or frame assembly","Implement and validate the exact Markdown/JSON contract; reject unsupported version or malformed fixed records; never reinterpret padding or reserved fields","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
+"G2B-PRE gate","C2H ABI and MMIO architecture freeze","ARCHITECTURE_COMPATIBLE: engineering PASS; AHD_C2H_TRANSPORT_ABI_V1 frozen; AHD_V41_G2B_MMIO_V1 frozen at 0x3800..0x3BFF; support and implemented-this-build capabilities are distinct; no hardware qualification","FROZEN","8","An architecture PASS could be misreported as implemented transport, DMA, Gen2 negotiation, or throughput proof","Preserve frozen contract; exact PRODUCT implementation now accepted separately through G2B-LUT1; hardware NOT_PROVEN","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
+"Exact G2B PRODUCT implementation","Frozen G2B transport ABI and MMIO contract","OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE; source 92e9b3d914134c044371779def1ee18eaaeda98a; all Groups 1-17 and final routed/pre-bitstream gates PASS; promoted sign-off methods retained; ABI/MMIO unchanged","ACCEPTED","8","An implementation could violate frozen bytes, ownership, reset-return or release-slot coherency, protected legacy timing, resource policy, or Linux expectations","Preserve exact candidate; next G2B-HW0-PRODUCT under separate authority; no source/XDC change","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62:v41-development-g2b-bs1r-single-sink-bus-skew-retry; 4699632c591238fee46ada3b0de37532fddd0b6f:v41-development-g2b-bs2-alternative-timing-equivalence; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
 "R-track","Product baseline isolation and research resumability","Execution state HOLD, not closed; R1i remains the functional product baseline and RESEARCH_DIAGNOSTIC must preserve R2/R3 observability","ACTIVE","3","Research result could be mistaken for product acceptance or PRODUCT reduction could destroy resumability","Keep research evidence and branches unchanged; preserve reproducible RESEARCH_DIAGNOSTIC profile; require explicit later scientific promotion/closure","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; aff7e32edc1cf71bde95b6c19e54e6f307764237:v41-research-r0-r1i-causal-isolation-design"
-"PRODUCT profile","Qualified R1i functional behavior","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; full physical SCL, ACK sampling, synchronizers, initialization, readiness/recovery, I2C, video and product observability behavior retained","PLANNED","3","Removing research instrumentation could accidentally remove functional fanout or product health visibility","G2B-LUT1 must prove signal-level functional equivalence and minimum production observability before offline acceptance","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution"
+"PRODUCT profile","Qualified R1i functional behavior","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; full physical SCL, ACK sampling, synchronizers, initialization, readiness/recovery, I2C, video and product observability behavior retained","ACCEPTED","8","Removing research instrumentation could accidentally remove functional fanout or product health visibility","Offline R1i functional protection and regression PASS for exact Recovery-4 candidate; keep hardware NOT_PROVEN","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
 "RESEARCH_DIAGNOSTIC profile","PRODUCT profile","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; RESOURCE_EQUIVALENCE=NOT_REQUIRED; RESEARCH_OBSERVABILITY_EQUIVALENCE=NOT_REQUIRED because RESEARCH_DIAGNOSTIC intentionally adds observability","PLANNED","3","Profile-specific logic could alter qualified behavior or external semantics, or PRODUCT could become necessary for research reconstruction","Build both reproducibly from one accepted source state; compare qualified behavior and product interfaces; preserve additional R2/R3 observability in RESEARCH_DIAGNOSTIC","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution"
 "PRODUCT and RESEARCH_DIAGNOSTIC profiles","AHD_C2H_TRANSPORT_ABI_V1","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; same frozen ABI identity, bytes, sequencing, reset, ownership, loss and parser semantics wherever G2B is included","FROZEN","3","Profile selection could silently create incompatible producers or capabilities","Use the unchanged ABI in both profiles and run the same golden-vector/parser qualification; resource and research-observability equivalence are not required","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze; a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution"
 "PRODUCT and RESEARCH_DIAGNOSTIC profiles","G2B MMIO 0x3800..0x3BFF","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; identical defined registers, counters, reset/error semantics, capability meaning, response behavior and reserved-zero space","FROZEN","3","Research-only cones could alias, change latency, expose stale data, or alter advertised capabilities","Preserve the frozen MMIO contract and deterministic compatibility behavior in both profiles; profile differences are observability/resource differences only","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze; a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution"
-"Future G2B hardware","PRODUCT and RESEARCH_DIAGNOSTIC profiles","FUNCTIONAL_INTERFACE_COMPATIBILITY=REQUIRED; resource equivalence NOT_REQUIRED; research observability equivalence NOT_REQUIRED; G2B-HW is BLOCKED and NOT_PROVEN until Groups 15-17 candidate implementation and validation, remaining final offline sign-off, the pre-bitstream hard gate, and a bitstream candidate exist; Groups 9-14 PASS preserved; Groups 15-17 SETTLING_PLUS_STRUCTURAL_CDC promoted; old global GLOBAL_SET_BUS_SKEW_3NS/report_bus_skew RETIRED_FROM_REQUIRED_SIGNOFF for each; partial routed equivalence, proven safety protocol, independent slot checks","BLOCKED","7","A promoted Group-9, Group-13, or Group-14 sign-off method or estimated-fit PRODUCT profile could be mistaken for routed, bitstream, or hardware proof","After complete offline acceptance and a valid bitstream candidate, qualify authorized hardware separately and report the exact selected profile, routed resources, timing, ABI/MMIO behavior and DMA result","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit"
+"G2B-HW0-PRODUCT","PRODUCT and RESEARCH_DIAGNOSTIC profiles","PLANNED; AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION; exact PRODUCT available; ONE_CHANNEL_FIXED_LIVE_AHD_PATH; hardware NOT_PROVEN","PLANNED","8","A promoted Group-9, Group-13, or Group-14 sign-off method or estimated-fit PRODUCT profile could be mistaken for routed, bitstream, or hardware proof","Follow META8A_HW0_PRODUCT_GATE_CONTRACT.md in separate governed task with fresh DUT exclusivity and exact operational authority","a70c55eca5f0c0ad349143ad93ab87eb80d11ac4:v41-development-g2b-lut0-resource-attribution; 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae:v41-development-g2b-bs3-ownership-mailbox-settling-proof; 10c7c2898d162af8e2262b3f99861c7d560c4557:v41-development-g2b-g13a-reset-return-signoff-audit; 9e91315968453e859006077191cd5fc711fc6b96:v41-development-g2b-g14a-release-slot0-signoff-audit; fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c:v41-development-g2b-g15-17-release-slot-equivalence-audit; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
 "Linux transport consumer","FPGA transport ABI","ARCHITECTURE_COMPATIBLE: frozen input contract for AHD_C2H_TRANSPORT_ABI_V1; negotiate MMIO ABI/capabilities; reset each session; parse fixed 4096-byte boundaries; validate ABI/version/identity/sequence/epoch/flags/line/padding; extract exactly 3840 UYVY bytes; V4L2 remains NOT_IMPLEMENTED","FROZEN","2","A consumer that attaches mid-epoch, scans for magic, ignores implementation capability, or accepts sequence/padding violations can silently combine corrupt or mixed-identity data","Implement the exact Linux transport consumer contract; keep V4L2, timestamps, DMABUF, persistent identity, and multi-card policy as later decisions","e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e:v41-development-g2b-pre-c2h-abi-mmio-freeze"
 "Linux/V4L2","Topology and concurrency","4 logical inputs/card; maximum 2 STREAMON/card; planned 2 cards/host","PLANNED","1","Resource arbitration and stable identity are not yet designed or qualified","Define L0 policy after final transport, timestamp, pixel-format, and identity decisions","META-0_TASK_DIRECTIVE; no L0 package at f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
-"XDMA host tooling","BAR/MMIO and device nodes","Discovered user BAR0 128 KiB; config BAR1 64 KiB; /dev/xdma*_c2h_0; legacy <=0x35FF; R1i 0x3600-0x367F","FROZEN","1","Hard-coded BAR or activation of tied-zero placeholders could break compatibility","Discover BAR assignments; preserve identity/map; treat application C2H as unavailable until accepted","654b9adf7d02cbf8946e420538955ffaaeae7eb2:v41-development-g-minus-1-existing-work-inventory; f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd:v41-development-g1-integration-architecture"
+"XDMA host tooling","BAR/MMIO and device nodes","Discovered user BAR0 128 KiB; config BAR1 64 KiB; /dev/xdma*_c2h_0; legacy <=0x35FF; R1i 0x3600-0x367F","FROZEN","8","Hard-coded BAR or activation of tied-zero placeholders could break compatibility","Discover BAR assignments; preserve identity/map; verify both exact candidate identity layers; execute capture only in separately authorized HW0","654b9adf7d02cbf8946e420538955ffaaeae7eb2:v41-development-g-minus-1-existing-work-inventory; f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd:v41-development-g1-integration-architecture; 6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
 "FFmpeg/GStreamer future integration","V4L2 format and buffer ABI","Native /dev/videoX direction; final pixel format/timestamps/DMABUF not selected","PLANNED","1","Userspace compatibility could be constrained by an early ABI choice","Choose standard V4L2 formats and timestamp/buffer semantics in L-track; validate both frameworks","META-0_TASK_DIRECTIVE; no Linux package at f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
 "OpenCV future integration","V4L2 frontend","Standard /dev/videoX presentation planned","PLANNED","1","Format conversion or timestamp behavior may prevent direct capture","Validate selected V4L2 format and multi-device behavior after L0 implementation","META-0_TASK_DIRECTIVE"
 "Future LitePCIe backend","Linux transport abstraction","Backend is a future option behind the common capture core","PLANNED","1","XDMA-specific assumptions may leak into common APIs and record semantics may differ","Keep transport contract backend-neutral; require separate architecture and compatibility decision","META-0_TASK_DIRECTIVE; no LitePCIe evidence package at f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
+"Exact PRODUCT candidate vs HW0-PRODUCT","Binary identity and unchanged ABI/MMIO","OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE; source 92e9b3d914134c044371779def1ee18eaaeda98a; tree cf6bf82249c90782eab1978c68541ed9c0e6430b; bitstream AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7; DCP 95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175; ABI v1; MMIO 0x3800..0x3BFF; hardware NOT_PROVEN","ACCEPTED","8","Offline acceptance must not be mistaken for hardware qualification or synthetic support","Only G2B-HW0-PRODUCT, PLANNED / AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION; ONE_CHANNEL_FIXED_LIVE_AHD_PATH; verify dual identity","6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4; META-8A_TASK_DIRECTIVE"
--- a/project-current-state/CURRENT_ARCHITECTURE.md
+++ b/project-current-state/CURRENT_ARCHITECTURE.md
@@ -1,6 +1,6 @@
 # AHD Current Architecture
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 This architecture separates accepted/proven substrate, accepted but not yet
 implemented architecture, active work, planned product layers, and open
@@ -38,16 +38,16 @@
 | R1i NVP/I2C bring-up and one video-presence path | `ACCEPTED` | `PROVEN` | Qualified PoC behavior and exact identity |
 | XDMA endpoint, BAR/MMIO, AXI-Lite control plane | `ACCEPTED` | `PROVEN` | Enumeration, driver, BAR discovery, identity/status/scratch scope |
 | Current Gen1 x1 donor link configuration | `FROZEN` | `PROVEN` | Control-plane donor only; inadequate for final 288 MB/s target |
-| G1 one-C2H/two-ring architecture | `ACCEPTED` | `PLANNED` | Architecture decision accepted; data plane not implemented/qualified |
+| G1 one-C2H/two-ring architecture | `ACCEPTED` | `PARTIAL_IMPLEMENTATION` | One-channel offline candidate accepted; two-channel target not qualified |
 | Local R1i-a/R1i-b research candidate commits | `PROVISIONAL` | `IMPLEMENTED_UNQUALIFIED` | Research-only source candidates; no product-baseline authority |
 | G2A | `ACTIVE` | `ACTIVE` | Work in progress; no accepted execution result represented |
 | G2B-PRE architecture contract | `ACCEPTED` | `FROZEN_FOR_G2B` | `AHD_C2H_TRANSPORT_ABI_V1`, G2B MMIO, and Linux transport-input contract are frozen |
-| G2B-LUT0 resource architecture | `ACCEPTED` | `PASS / IMPLEMENTATION_PENDING` | Dual-profile Plan B accepted; estimate is not qualification evidence |
-| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | Qualified R1i behavior, production observability, XDMA Gen2, G2B and frozen ABI/MMIO retained |
+| G2B-LUT0 resource architecture | `ACCEPTED` | `PASS` | Plan B retained; PRODUCT now offline-qualified |
+| PRODUCT profile | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` | Exact candidate; hardware NOT_PROVEN |
 | RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | PRODUCT functional behavior plus reproducible R-track observability for R2/R3 resumability |
-| Application record-to-C2H plane | `BLOCKED` | `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` | Groups 15–17 candidate-XDC implementation and complete final routed sign-off remain pending; no offline-qualified implementation |
-| G2B-LUT1 | `PLANNED` | `READY_FOR_SIGNOFF_RECOVERY / SIGNOFF_RECOVERY_PENDING` | Authorized next gate is `G2B-LUT1-SIGNOFF-RECOVERY-4`; active XDC is not changed by META-6 |
-| G2B-HW | `BLOCKED` | `NOT_STARTED / NOT_PROVEN` | Final offline sign-off, pre-bitstream hard gate, and a bitstream candidate do not exist |
+| Application record-to-C2H plane | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` | Fixed one-channel live path; hardware NOT_PROVEN |
+| G2B-LUT1 | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` | `G2B-LUT1-SIGNOFF-RECOVERY-4` |
+| G2B-HW | `PLANNED` | `NOT_STARTED / NOT_PROVEN` | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION` |
 | Linux/V4L2 product layer | `PLANNED` | `NOT_IMPLEMENTED` | Transport input is frozen; frontend, buffer, identity, and policy work remain later L-track scope |
 | Gen2 training, actual `user_clk`, and throughput | `OPEN` | `NOT_PROVEN` | Require later qualification |
 
@@ -83,8 +83,8 @@
 exhaustive no-alias and response-equivalence validation.
 
 G2B-PRE freezes the new G2B MMIO contract at `0x3800..0x3BFF`. This is an
-accepted interface allocation and semantic contract, not a claim that the
-registers exist in the current build. All protected behavior through
+accepted interface allocation implemented unchanged by the exact offline
+PRODUCT candidate; hardware is NOT_PROVEN. All protected behavior through
 `0x37FF` remains compatible and unchanged.
 
 ### Capture and record plane
@@ -104,10 +104,8 @@
 64-byte header, a 3,840-byte payload containing one complete 1,920-active-pixel
 UYVY 4:2:2 line, and 192 bytes of zero padding, with explicit
 logical/physical channel identity. Its interface status is `FROZEN_FOR_G2B`.
-The freeze makes the interface contract implementation-ready; the complete
-G2B implementation remains in sign-off recovery and not offline-qualified. It
-does not mean the formatter, rings, scheduler, or application C2H data plane
-is accepted or hardware-qualified.
+The exact one-channel PRODUCT implementation is accepted offline.
+The two-channel target and hardware DMA remain unqualified.
 
 ### Ownership mailbox CDC and Group-9 sign-off
 
@@ -361,36 +359,12 @@
 subject to normal final sign-off disposition, outside this architecture
 decision. Project-wide warning closure is not claimed.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
-
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
-
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
-
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
 
 ### Build-profile boundary
 
@@ -414,40 +388,20 @@
 remain reproducibly buildable. No claim is made that the research profile
 currently builds or routes after G2B.
 
-G2B-LUT1 may select a reversible repository-supported mechanism such as
-generics, Tcl profile selection/defines, generate blocks, or source sets. The
-implementation agent, not META-3, must choose the least invasive method.
+Recovery-4 binds PRODUCT elaboration with enable_rtrack_diagnostics=0 and
+zero debug cores. META-8A selects no new source implementation mechanism.
 
 ### Application DMA qualification boundary
 
 Current accepted state:
 
-- PCIe endpoint: `PROVEN`.
-- BAR/MMIO: `PROVEN`.
-- AXI-Lite: `PROVEN`.
-- G2B-PRE transport/MMIO architecture contract: `ACCEPTED` and
-  `FROZEN_FOR_G2B`.
-- Application C2H payload: not accepted.
-- Record-to-AXI-stream/G2B implementation:
-  `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` and not offline-qualified.
-- Group-9 ownership sign-off method:
-  `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; the promoted method and
-  authoritative PASS are preserved.
-- Group-13 reset-return sign-off method: `SETTLING_PLUS_STRUCTURAL_CDC`; the
-  old global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is retired from
-  required sign-off; its promoted method and recovery-2 PASS are preserved.
-- Group-14 release-slot sign-off method: `SETTLING_PLUS_STRUCTURAL_CDC`; the
-  old global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` is retired from
-  required sign-off; its authoritative PASS is preserved. Groups 15–17
-  candidate implementation and validation are the next governed work.
-- G2B-LUT1 readiness: `READY_FOR_SIGNOFF_RECOVERY`; next gate
-  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
-- One-channel DMA: not yet qualified.
-- Two-channel DMA: not yet qualified.
-- Sustained 288 MB/s: not yet qualified.
-- G2B-HW: lifecycle `BLOCKED`, `NOT_STARTED`, and `NOT_PROVEN` until final
-  offline sign-off, the pre-bitstream hard gate, and a bitstream candidate
-  exist.
+- Donor/R1i endpoint, BAR/MMIO and AXI-Lite remain proven in their original scope.
+- Exact one-channel PRODUCT data plane ACCEPTED offline via G2B-LUT1-SIGNOFF-RECOVERY-4; hardware NOT_PROVEN.
+- All Groups 1–17 and final routed gates PASS; sign-off methods and structural requirements preserved.
+- G2B-LUT1 ACCEPTED, maturity OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE; next gate G2B-HW0-PRODUCT.
+- G2B-HW PLANNED, AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION, NOT_STARTED / NOT_PROVEN.
+- One-channel hardware DMA, two-channel DMA, Gen2 hardware and >=288 MB/s hardware throughput remain NOT_PROVEN.
+- Offline >=288 MB/s analysis PASS is distinct from hardware measurement.
 
 Enumeration, driver load, or a nonzero byte count alone is not C2H correctness
 or throughput evidence.
@@ -512,3 +466,28 @@
 - Research instrumentation excluded from PRODUCT remains recoverable through
   the reproducible RESEARCH_DIAGNOSTIC profile; evidence and R-track branches
   are not deleted or modified by META-3.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/CURRENT_INTERFACES.md
+++ b/project-current-state/CURRENT_INTERFACES.md
@@ -1,6 +1,6 @@
 # AHD Current Interfaces
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 > `CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`
 
@@ -22,7 +22,7 @@
 | `0x0004` | `PROTOCOL` | `0x0000400B` (`v40B`) | `FROZEN` |
 | `0x0008` | `CAPABILITIES` | `0x00031002` | `FROZEN` |
 | `0x000C` | `BUILD_ID_SCHEMA` | `0x00010000` | `FROZEN` |
-| `0x0010–0x0020` | `GIT_SHA_W0..W4` | exact 40-hex clean source commit | `FROZEN` |
+| `0x0010–0x0020` | `GIT_SHA_W0..W4` | Runtime fingerprint `224d194e5f82c85bcb29297561c5d5e76d28063b` for this candidate; dual identity binding below | `FROZEN` |
 | `0x002C` | `BUILD_FLAGS` | dirty and verified-clean provenance bits | `FROZEN` |
 | `0x0030` | `TRANSPORT_SIGNATURE` | `0x58444D41` (`XDMA`) | `FROZEN` |
 | `0x0034` | `SCRATCH_RW` | byte-enable-aware, no side effect | `FROZEN` |
@@ -36,7 +36,7 @@
 |---|---|---|---|
 | User AXI-Lite BAR | observed BAR0, 128 KiB aperture at local address 0 | `FROZEN` | Host tooling must discover BAR assignments; preserve the 128 KiB semantic aperture |
 | XDMA configuration BAR | observed BAR1, 64 KiB aperture | `FROZEN` | Distinct from the user AXI-Lite aperture; use driver/device discovery |
-| C2H device interface | one C2H channel, host node family `/dev/xdma*_c2h_0` | `FROZEN` | One engine per card; current application payload is inactive |
+| C2H device interface | one C2H channel, host node family `/dev/xdma*_c2h_0` | `FROZEN` | One engine per card; donor application payload is inactive; exact PRODUCT data plane offline-qualified, hardware NOT_PROVEN |
 | H2C device interface | one mandatory donor H2C interface | `FROZEN` | Unsupported by application; application `TREADY=0` and host must not submit H2C |
 
 BAR numbering is the verified donor observation, not permission for consumers
@@ -61,12 +61,12 @@
 
 | Interface decision | Current value | Status | Qualification boundary |
 |---|---|---|---|
-| XDMA C2H channel count | 1 per card | `ACCEPTED` | Donor interface exists; application data plane not accepted |
+| XDMA C2H channel count | 1 per card | `ACCEPTED` | One-channel plane offline-qualified; hardware NOT_PROVEN |
 | Logical capture channels | IDs 0 and 1 | `ACCEPTED` | Two-channel hardware not qualified |
 | Physical input IDs | 0 through 3 | `ACCEPTED` | Current evidence proves only the present VDO1 path |
 | Mapping rule | two distinct physical IDs may map to logical 0/1 | `ACCEPTED` | Change only while affected channel disabled and drained |
-| Scheduling | record-boundary work-conserving round-robin | `FROZEN` | No beat interleave; no implementation is accepted/offline-qualified and current G2B-IMPL is in sign-off recovery |
-| Buffer ownership | private four-record ring per logical channel | `FROZEN` | Exact ownership contract is frozen; implementation and resources are not qualified |
+| Scheduling | record-boundary work-conserving round-robin | `FROZEN` | No beat interleave; one-channel offline candidate accepted; two-channel target unqualified |
+| Buffer ownership | private four-record ring per logical channel | `FROZEN` | One-channel offline qualification; two-channel and hardware unqualified |
 | Host transport order | one global streamed order plus per-channel attempt order | `FROZEN` | Encoded fields are frozen by `AHD_C2H_TRANSPORT_ABI_V1`; hardware is `NOT_PROVEN` |
 
 Channel identity semantics are authoritative at the architecture level:
@@ -88,8 +88,8 @@
 | ABI numeric version | `1` |
 | MMIO ABI version | `0x00010000` (`major=1`, `minor=0`) |
 | Record family / version | `v41D` / `0x00004101` |
-| Accepted G2B implementation | none; current G2B-IMPL is `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING` and not offline-qualified |
-| G2B-HW | lifecycle `BLOCKED`; `NOT_PROVEN` pending final offline sign-off and a bitstream candidate |
+| Accepted G2B implementation | Exact one-channel `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` via `G2B-LUT1-SIGNOFF-RECOVERY-4` |
+| G2B-HW | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; hardware NOT_PROVEN |
 | Normative evidence | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
 
 #### Record geometry and header
@@ -407,44 +407,19 @@
 subject to normal final sign-off disposition, outside this architecture
 decision. Project-wide warning closure is not claimed.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
-
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
-
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
-
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
 
 ### Frozen G2B MMIO contract
 
 `MMIO STATUS = FROZEN`
 
-`AHD_V41_G2B_MMIO_V1` is lifecycle `FROZEN` at `0x3800..0x3BFF`, but no
-implementation is accepted/offline-qualified; current G2B-IMPL is in sign-off
-recovery and G2B-HW is lifecycle `BLOCKED` and `NOT_PROVEN`.
+`AHD_V41_G2B_MMIO_V1` is lifecycle `FROZEN` at `0x3800..0x3BFF`, and implemented unchanged in the exact offline PRODUCT candidate.
+G2B-HW is lifecycle PLANNED and NOT_PROVEN.
 The router must claim exactly that range before legacy forwarding. Every
 address through `0x37FF` retains its frozen accepted-base value, side effect,
 byte-enable behavior, ordering, and response latency. `0x3C00..0x3FFF` is not
@@ -518,9 +493,9 @@
 contract and deterministic compatibility behavior without aliasing or stale
 data. The source-level mechanism is deliberately not selected by META-3.
 
-Both profiles are `AUTHORIZED_NOT_IMPLEMENTED`. No current
-RESEARCH_DIAGNOSTIC post-G2B build/route, PRODUCT LUT qualification, G2B
-bitstream, or hardware result is claimed.
+PRODUCT is the accepted exact offline-qualified candidate, with actual LUT
+qualification and bitstream bound below. RESEARCH_DIAGNOSTIC post-G2B
+build/route is not promoted. No hardware result is claimed.
 
 ## Interface change control
 
@@ -529,3 +504,28 @@
 revision, updates to this document and `COMPATIBILITY_MATRIX.csv`, a one-step
 revision increment, changelog/evidence-map updates, non-force publication, and
 remote read-back.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/CURRENT_REQUIREMENTS.md
+++ b/project-current-state/CURRENT_REQUIREMENTS.md
@@ -1,6 +1,6 @@
 # AHD Current Requirements
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 This document separates a frozen requirement from its implementation target
 and from actual qualification. A requirement is not evidence that the product
@@ -14,15 +14,15 @@
 | `REQ-INPUTS-CARD` | 4 physical inputs per card | `FROZEN` | Four selectable Linux/V4L2 input identities; at most two FPGA capture channels active | Only the current VDO1 path is proven; second physical ingress remains open |
 | `REQ-ACTIVE-CARD` | Maximum 2 simultaneously active inputs per card | `FROZEN` | Two logical capture channels with enforced selection limit | Two-channel DMA not qualified |
 | `REQ-CARDS-HOST` | Planned 2 cards per Linux host | `FROZEN` | Multi-card-capable driver/core and stable identity | Two-card hardware operation not qualified |
-| `REQ-PCIE-PAYLOAD` | Sustained application payload `>= 288 MB/s` per card | `FROZEN` | Efficient 4 KiB C2H records over Gen2 x1 or better | Not yet qualified |
+| `REQ-PCIE-PAYLOAD` | Sustained application payload `>= 288 MB/s` per card | `FROZEN` | Efficient 4 KiB C2H records over Gen2 x1 or better | Offline analysis PASS; hardware NOT_PROVEN |
 | `REQ-PCIE-MIN` | PCIe Gen2 x1 or better | `FROZEN` | Gen2 x1 is the minimum current target | Actual Gen2 training not qualified |
-| `REQ-C2H-COUNT` | One XDMA C2H channel per card | `FROZEN` | Shared formatter/engine for up to two logical channels | Architecture accepted; application data plane not qualified |
+| `REQ-C2H-COUNT` | One XDMA C2H channel per card | `FROZEN` | Shared formatter/engine for up to two logical channels | Architecture accepted; one-channel PRODUCT offline-qualified; hardware NOT_PROVEN |
 | `REQ-LINUX-FRONTEND` | Native Linux V4L2 integration | `FROZEN` | Standard `/dev/videoX` presentation through common capture core | `PLANNED`, not implemented |
 | `REQ-TRANSPORT-ABSTRACTION` | Linux capture core must be transport-independent | `FROZEN` | XDMA first backend; future LitePCIe backend possible | `PLANNED`; final backend API is open |
 | `REQ-CARD-IDENTITY` | Stable card and input identity for multi-card use | `FROZEN` | Persistent mapping independent of enumeration order | Architecture decision remains open |
 | `REQ-STREAM-LIMIT` | Four logical inputs/card, maximum two `STREAMON`/card | `FROZEN` | V4L2 policy enforced per physical card | `PLANNED`, not implemented |
-| `REQ-PRODUCT-LUT-GATE` | Routed PRODUCT LUT utilization `<= 90%` | `FROZEN` | Preferred target band `80–85%` | Not yet measured or achieved; 84.192% is an estimate only |
-| `REQ-BUILD-PROFILES` | Reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles | `FROZEN` | One functional source architecture with explicit profile selection | `AUTHORIZED_NOT_IMPLEMENTED`; G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY` |
+| `REQ-PRODUCT-LUT-GATE` | Routed PRODUCT LUT utilization `<= 90%` | `FROZEN` | Preferred target band `80–85%` | PASS: PRODUCT 17366/20800 LUT (83.490%); historical 84.192% remains an estimate |
+| `REQ-BUILD-PROFILES` | Reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles | `FROZEN` | One functional source architecture with explicit profile selection | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC qualification not promoted |
 
 ## Derived host topology
 
@@ -61,36 +61,35 @@
 - exactly 3,840 useful bytes per record under
   `AHD_C2H_TRANSPORT_ABI_V1`.
 
-The architecture decision is accepted and the named transport ABI is
-`FROZEN_FOR_G2B` with lifecycle status `FROZEN`. No application C2H
-implementation is accepted/offline-qualified; current G2B-IMPL is
-`ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; one-channel and two-channel
-DMA qualification has not occurred; G2B-HW remains lifecycle `BLOCKED` and
-`NOT_PROVEN`.
+The architecture and FROZEN_FOR_G2B ABI remain unchanged. The exact
+one-channel PRODUCT candidate is ACCEPTED offline. One-channel and
+two-channel hardware DMA are NOT_PROVEN. G2B-HW is PLANNED and
+AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION.
 
 ## Frozen transport implementation requirements
 
 The following are normative requirements derived from the accepted G2B-PRE
 contract. Their `FROZEN` status makes them implementation and parser inputs;
-it does not claim that any data plane or hardware result exists.
+the exact PRODUCT implementation is separately accepted offline by META-8A;
+no hardware result is claimed.
 
 | ID | Frozen requirement | Status | Qualification state |
 |---|---|---|---|
-| `REQ-C2H-RECORD` | Every C2H record is exactly 4,096 bytes: 64-byte header, 3,840-byte useful payload, and 192-byte padding | `FROZEN` | No accepted/offline-qualified G2B implementation; sign-off recovery pending; G2B-HW `BLOCKED` and `NOT_PROVEN` |
+| `REQ-C2H-RECORD` | Every C2H record is exactly 4,096 bytes: 64-byte header, 3,840-byte useful payload, and 192-byte padding | `FROZEN` | Exact one-channel implementation accepted offline; G2B-HW PLANNED / NOT_PROVEN |
 | `REQ-C2H-PAYLOAD` | Every valid record contains one complete validated 1,920-pixel active line in packed UYVY 4:2:2 byte order `U0,Y0,V0,Y1`; no SAV/EAV, blanking, timestamp, checksum, or descriptor bytes | `FROZEN` | No host DMA or frame-delivery qualification |
-| `REQ-C2H-PADDING` | Record bytes `3904..4095` are formatter-generated zero; stale or unwritten RAM is forbidden; the consumer must validate zero | `FROZEN` | Formatter not implemented or proven |
+| `REQ-C2H-PADDING` | Record bytes `3904..4095` are formatter-generated zero; stale or unwritten RAM is forbidden; the consumer must validate zero | `FROZEN` | Formatter offline-qualified; hardware NOT_PROVEN |
 | `REQ-C2H-IDENTITY` | Each record carries frozen logical channel, physical input, source frame/line/capture, reset epoch, per-channel attempt, and global stream identities with all reserved container bits zero | `FROZEN` | G2B emits logical 0, physical 0, active count 1; future channel 1 remains unimplemented |
-| `REQ-C2H-SEQUENCE` | Sequence and epoch semantics must remain coherent: attempts consume per-channel numbers even when later dropped/malformed/aborted; only complete streamed records consume contiguous global order; a new transport epoch resets both transport next-values to zero | `FROZEN` | No RTL or hardware continuity proof |
-| `REQ-C2H-RESET` | A transport reset must disable admission, require host re-enable, atomically flush ownership/descriptors through acknowledged epoch coordination, expose no partial record, and resume only at beat 0; source and NVP/I2C lifecycles remain independent | `FROZEN` | Reset implementation and CDC behavior not proven |
-| `REQ-C2H-AXIS` | The 64-bit stream has exactly 512 beats, `TKEEP=0xFF` throughout, and `TLAST` only on beat 511; while `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain stable and record state advances only on handshake | `FROZEN` | Backpressure simulation and hardware DMA not performed |
-| `REQ-C2H-OWNERSHIP` | A committed record and matching descriptor are immutable; slot release occurs only after the final-beat handshake and acknowledged return; overwrite of committed or in-flight records is forbidden | `FROZEN` | Ring/data-plane implementation not accepted |
+| `REQ-C2H-SEQUENCE` | Sequence and epoch semantics must remain coherent: attempts consume per-channel numbers even when later dropped/malformed/aborted; only complete streamed records consume contiguous global order; a new transport epoch resets both transport next-values to zero | `FROZEN` | Offline functional regression PASS; hardware continuity NOT_PROVEN |
+| `REQ-C2H-RESET` | A transport reset must disable admission, require host re-enable, atomically flush ownership/descriptors through acknowledged epoch coordination, expose no partial record, and resume only at beat 0; source and NVP/I2C lifecycles remain independent | `FROZEN` | Offline reset/CDC PASS; hardware reset NOT_PROVEN |
+| `REQ-C2H-AXIS` | The 64-bit stream has exactly 512 beats, `TKEEP=0xFF` throughout, and `TLAST` only on beat 511; while `TVALID && !TREADY`, `TVALID`, `TDATA`, `TKEEP`, and `TLAST` remain stable and record state advances only on handshake | `FROZEN` | Offline functional regression PASS; hardware DMA NOT_PROVEN |
+| `REQ-C2H-OWNERSHIP` | A committed record and matching descriptor are immutable; slot release occurs only after the final-beat handshake and acknowledged return; overwrite of committed or in-flight records is forbidden | `FROZEN` | One-channel implementation accepted offline; hardware NOT_PROVEN |
 | `REQ-G2B-GROUP9-OWNERSHIP-SIGNOFF` | Group-9 `OWNERSHIP_AXI_TO_SOURCE` requires `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`: two-stage request and acknowledgement synchronizers, held 58-bit payload, source hold until acknowledgement, reset/epoch coherency, and `6.000 ns` absolute settling checks for `slot`, `generation`, and `epoch` | `FROZEN` | Method promoted from BS3; authoritative result `PRESERVE_PASS`; `RTL_CHANGE_REQUIRED = NO` |
 | `REQ-G2B-GROUP13-RESET-RETURN-SIGNOFF` | Group-13 `RESET_RETURN_SOURCE_TO_AXI` requires `SETTLING_PLUS_STRUCTURAL_CDC`: two exact semantic families, `6.000 ns` absolute datapath-only settling, retained broad aggregate `6.000 ns` coverage, stable-until-acknowledgement behavior, two-stage request/acknowledgement and live commit-phase synchronization, commit-phase equality, hard-episode qualification, reset-return coherency, destination-use sequencing, and atomic epoch/state publication | `FROZEN` | Method promoted from G13-A; recovery-2 result `PRESERVE_PASS`; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO` |
 | `REQ-G2B-GROUP14-RELEASE-SLOT0-SIGNOFF` | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` requires `SETTLING_PLUS_STRUCTURAL_CDC`: exactly three semantic families with `6.000 ns` absolute datapath-only settling, held 56-bit generation/epoch token lifetime, same-edge token/toggle ordering, two-stage release-toggle synchronization for normal use, two-stage transport-request synchronization for reset accounting, fail-closed generation/epoch/ownership identity, captured release-phase retirement/completion barrier, destination-use ordering, and reset/release coherency | `FROZEN` | Method promoted from G14-A; `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; `RTL_CHANGE_REQUIRED = NO`; HISTORICAL META-6 active-XDC boundary: authorized for recovery-3, not yet implemented at promotion; current Group-14 result `PRESERVE_PASS` |
-| `REQ-C2H-LOSS` | Ring-full and other noncommitted attempts use whole-record drop; attempted/dropped and applicable overflow/malformed accounting increments exactly once; pending discontinuity/loss context reaches the next committed record; partial drop and silent sequence repair are forbidden | `FROZEN` | Drop/overflow behavior not implemented or measured |
+| `REQ-C2H-LOSS` | Ring-full and other noncommitted attempts use whole-record drop; attempted/dropped and applicable overflow/malformed accounting increments exactly once; pending discontinuity/loss context reaches the next committed record; partial drop and silent sequence repair are forbidden | `FROZEN` | Offline functional regression PASS; hardware NOT_PROVEN |
 | `REQ-LINUX-C2H-PARSER` | The Linux transport parser must negotiate MMIO ABI/capabilities, create a session epoch with `RESET_STREAM_STATE`, parse only fixed 4,096-byte boundaries, and validate ABI/version, identities, flags, source/attempt/global sequences, epoch, line/SOF, payload length, and zero padding | `FROZEN` | Linux consumer contract is frozen input; V4L2 remains `NOT_IMPLEMENTED` |
 | `REQ-C2H-INPUT-SCALE` | The product exposes 4 physical input identities per card and permits at most 2 active logical inputs per card | `FROZEN` | Second ingress and two-channel DMA remain unqualified |
-| `REQ-C2H-THROUGHPUT` | Sustained AHD application payload target remains `>= 288 MB/s` per card | `FROZEN` | Target is not achieved or hardware-qualified; transport overhead, link, XDMA, host, drops, and long-run behavior still require measurement |
+| `REQ-C2H-THROUGHPUT` | Sustained AHD application payload target remains `>= 288 MB/s` per card | `FROZEN` | Offline >=288 MB/s analysis PASS; hardware NOT_PROVEN; link, XDMA, host, drops and long-run behavior require measurement |
 
 The normative evidence is
 `v41-development-g2b-pre-c2h-abi-mmio-freeze` at commit
@@ -316,40 +315,17 @@
 subject to normal final sign-off disposition, outside this architecture
 decision. Project-wide warning closure is not claimed.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
-
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
-
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
-
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
 
 ## Build-profile requirements
 
-The dual-profile architecture is authorized but not implemented.
+PRODUCT is implemented and offline-qualified. RESEARCH_DIAGNOSTIC
+post-G2B qualification is not promoted.
 
 ### PRODUCT
 
@@ -384,7 +360,7 @@
 video capture semantics, C2H transport ABI, externally visible MMIO contract,
 or XDMA configuration. Actual PRODUCT routed LUT utilization and timing must
 be requalified by G2B-LUT1/G2B-IMPL; the `<=90%` gate and preferred `80–85%`
-band are requirements, not achieved results.
+band remain requirements, achieved by this exact offline PRODUCT candidate.
 
 ## Linux Video product direction
 
@@ -428,3 +404,28 @@
 instrumentation classified by G2B-LUT0. The instrumentation must remain
 recoverable and reproducibly buildable through RESEARCH_DIAGNOSTIC; R-track
 state is `HOLD`, not closed, and no research evidence may be deleted.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/CURRENT_RESOURCE_STATE.md
+++ b/project-current-state/CURRENT_RESOURCE_STATE.md
@@ -1,6 +1,6 @@
 # AHD Current Resource State
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 ## Qualified routed result
 
@@ -15,10 +15,8 @@
 > **87.41% LUT is the current R1i diagnostic qualified-build result, not the
 > final production resource expectation.**
 
-The accepted G2B-PRE contract freeze adds no implementation or routed-resource
-result. G2B-IMPL is not offline-qualified, and G2B-HW is lifecycle `BLOCKED`
-and remains `NOT_PROVEN`. The qualified table above therefore remains the R1i
-result.
+The table above remains the R1i hardware-qualified PoC result. The separate
+exact PRODUCT result below is accepted offline; G2B-HW PLANNED / NOT_PROVEN.
 
 ## Accepted G2B-LUT0 resource architecture
 
@@ -29,10 +27,9 @@
 | Estimated research/diagnostic LUT | approximately 3,900 (range 3,500–4,300) | Planning attribution, not a measured removal result |
 | Estimated PRODUCT after Plan B | approximately 17,512 (84.192%) | Estimate only; not qualification evidence |
 
-The exact achieved recovery remains unknown until controlled paired profile
-builds and post-route requalification. The R1i functional fix is separable
-from research instrumentation, but mixed counters still require signal-level
-fanout proof during G2B-LUT1.
+Actual PRODUCT utilization is 17,366 LUT with offline R1i/functional
+regression PASS. Paired-profile diagnostic resource attribution remains
+outside this promotion.
 
 ## Accepted interpretation
 
@@ -43,8 +40,8 @@
 | Research/diagnostic LUT planning estimate | `ACCEPTED` | Approximately 3,900, range 3,500–4,300; not achieved recovery |
 | Current values as final production requirement | `REJECTED` | No such inference is permitted |
 | PRODUCT profile reduction architecture | `ACCEPTED` | Reversible exclusion of G2B-LUT0-classified research-only instrumentation is authorized |
-| Profile source/sign-off recovery | `PLANNED` | G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4`; no source or active-XDC change implemented by META-7R |
-| PRODUCT hard gate achieved | `OPEN` | Must be demonstrated by actual post-route utilization |
+| PRODUCT source/sign-off | `ACCEPTED` | Exact Recovery-4 offline candidate; no META-8A source/XDC edit |
+| PRODUCT hard gate achieved | `ACCEPTED` | Actual 17366/20800 (83.490%); <=90% and preferred 80–85% PASS |
 
 Named R1h diagnostic islands totaling 2,337 LUT, 3,086 FF, and nine RAMB18 are
 a non-additive reference only. They do not prove the exact removable amount in
@@ -56,17 +53,19 @@
 
 Preferred routed PRODUCT target: `80–85%` (`16,640–17,680 LUT`).
 
-The estimated 17,512 LUT / 84.192% point lies inside the preferred band, but
-the estimate is not qualification evidence and the target is not marked
-achieved. `G2B-LUT1-SIGNOFF-RECOVERY-4`/G2B-IMPL must measure actual post-route
-utilization.
+The historical 17,512 LUT / 84.192% remains an estimate. Actual PRODUCT
+utilization is 17,366 LUT / 83.490%, meeting both hard gate and preferred band.
 
-The META-4R2 Group-9, META-5 Group-13, and META-6 Group-14 sign-off-method
-promotions change no measured or estimated resource value in this document.
-META-7R also changes no measured or estimated resource value. Groups 9–14
-PASS are preserved; Groups 15–17 candidate implementation and validation and
-the remaining routed resource hard gate are pending. The combined promotion
-uses nine independent `6.000 ns` checks; the next task is recovery-4.
+## Accepted PRODUCT offline result
+
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
+Evidence: `6843d582fd367fbc0edc0b1d55a9617162c489b0:v41-development-g2b-lut1-signoff-recovery-4`. Bitstream SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`.
+No diagnostic-profile resource or hardware claim.
 
 ## Existing G1 resource policy
 
@@ -126,15 +125,14 @@
 
 ### Authorized PRODUCT exclusion boundary
 
-Lifecycle `PLANNED`, authorization state `AUTHORIZED_NOT_IMPLEMENTED`:
+PRODUCT implementation accepted offline; research preservation obligations remain:
 
 - research-only probe campaigns and deep histories;
 - research index/failed-record BRAMs; and
 - supporting diagnostic read services that an accepted interface decision
   permits to remove.
 
-No diagnostic address may be silently reused. G2B-LUT1 must prove fanout and
-functional equivalence, preserve externally visible MMIO behavior, produce
-paired profile resource/functional evidence, and keep all excluded research
-instrumentation reproducibly recoverable through RESEARCH_DIAGNOSTIC. No
+No diagnostic address may be silently reused. PRODUCT functional/MMIO
+preservation is accepted offline. Paired diagnostic-profile qualification is
+not promoted; excluded research instrumentation must remain recoverable. No
 research evidence is deleted, and R-track closure is not claimed.
--- a/project-current-state/CURRENT_STATUS.md
+++ b/project-current-state/CURRENT_STATUS.md
@@ -1,11 +1,11 @@
 # AHD Current Status
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 State type: `CURRENT_ACCEPTED_STATE`
 Accepted by role: `OWNER_ARCHITECT`
 Decision basis: historical accepted state plus explicit Owner/Architect
-promotion of the accepted combined Groups 15–17 release-slot CDC architecture
-and sign-off methods through META-7R
+acceptance of exact Recovery-4 offline PRODUCT and separately planned
+HW0-PRODUCT through META-8A
 
 ## Acceptance boundary
 
@@ -30,10 +30,10 @@
 | Product | G1 | `ACCEPTED` | Integration and C2H architecture accepted; G2 implementation allowed | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
 | Product | G2A | `ACTIVE` | In progress; no accepted result is represented | No G2A package on evidence `main` at revision-1 creation |
 | Product | G2B-PRE | `ACCEPTED` | C2H transport ABI, MMIO contract, and Linux transport-input contract frozen | Accepted evidence at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`; architecture contract only |
-| Product | G2B-IMPL | `BLOCKED` | Sign-off recovery pending; not offline-qualified | No G2B bitstream or hardware result; Groups 15–17 candidate XDC is authorized but not implemented; remaining routed hard gates are pending |
+| Product | G2B-IMPL | `ACCEPTED` | Exact one-channel offline implementation via G2B-LUT1 | `G2B-LUT1-SIGNOFF-RECOVERY-4`; hardware NOT_PROVEN |
 | Product | G2B-LUT0 | `ACCEPTED` | Plan B dual-profile resource architecture accepted | Evidence `PASS` at `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`; estimate is not qualification |
-| Product | G2B-LUT1 | `PLANNED` | readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` | Preserve Groups 9–14 authoritative PASS; implement and validate all nine Groups 15–17 candidate checks, then continue remaining routed hard gates |
-| Product | G2B-HW | `BLOCKED` | `NOT_STARTED / NOT_PROVEN` | Final offline sign-off, pre-bitstream hard gate, and a bitstream candidate do not exist |
+| Product | G2B-LUT1 | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE` | All offline gates PASS; exact candidate only |
+| Product | G2B-HW | `PLANNED` | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION` | NOT_STARTED / NOT_PROVEN; next `G2B-HW0-PRODUCT` |
 | Research | R0 | `ACCEPTED` | Causal-isolation design accepted | Evidence package engineering `PASS`; acceptance supplied by Owner/Architect |
 | Research | R1 | lifecycle `ACTIVE`; execution state `HOLD` | Valid research context; no closure or product promotion | `RESEARCH_DIAGNOSTIC` preserves the diagnostic continuation path |
 | Research | R2/R3 | lifecycle `PLANNED`; state `HOLD` | Resumable later; neither accepted nor complete | `RESEARCH_DIAGNOSTIC` must preserve R2/R3 observability |
@@ -44,7 +44,8 @@
 | META | META-5 | `ACCEPTED` | Reset-return CDC Group-13 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
 | META | META-6 | `ACCEPTED` | Release-slot CDC Group-14 sign-off method promoted | SSOT/meta only; no RTL, active XDC, Vivado, bitstream, or hardware action |
 
-| META | META-7R | `ACCEPTED` | Combined Groups 15–17 release-slot methods promoted | SSOT only; no RTL, active XDC, bitstream or hardware action |
+| META | META-7R | `ACCEPTED` | Combined Groups 15–17 release-slot methods promoted | Historical architecture promotion |
+| META | META-8A | `ACCEPTED` | Exact PRODUCT offline candidate and separate HW0 scope accepted | SSOT only; hardware NOT_STARTED / NOT_PROVEN |
 
 ## META-7R combined release-slot promotion
 
@@ -58,36 +59,12 @@
 `RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
 requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
 
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
 
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
 
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
 
 ## Accepted product state
 
@@ -101,18 +78,18 @@
 | R1i telemetry `0x3600–0x367F` | `FROZEN` | Read-only 32-word page |
 | One-C2H/two-private-ring architecture | `ACCEPTED` | G1 architecture decision; not an implemented data-plane claim |
 | `AHD_C2H_TRANSPORT_ABI_V1` version 1 | `FROZEN` | `FROZEN_FOR_G2B`; 4,096-byte record contract, not an implementation claim |
-| G2B MMIO `0x3800–0x3BFF` | `FROZEN` | Contract frozen; registers are `NOT_IMPLEMENTED` in accepted hardware |
+| G2B MMIO `0x3800–0x3BFF` | `FROZEN` | Contract frozen; exact PRODUCT registers accepted offline; hardware NOT_PROVEN |
 | Linux transport consumer contract | `FROZEN` | Frozen input contract only; V4L2 architecture/implementation is not promoted |
 | Group-9 `OWNERSHIP_AXI_TO_SOURCE` sign-off | `ACCEPTED` | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; old `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
 | Group-13 `RESET_RETURN_SOURCE_TO_AXI` sign-off | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC`; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-13 `report_bus_skew` retired from required sign-off |
 | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off (active-XDC literal is HISTORICAL at META-6 promotion; current result `PRESERVE_PASS`) | `ACCEPTED` | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14 `report_bus_skew` retired from required sign-off; `RTL_CHANGE_REQUIRED = NO`; `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` |
-| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; LUT hard gate `<=90%`, preferred `80–85%` |
+| PRODUCT profile | `ACCEPTED` | `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; LUT 83.490% meets hard gate/preferred band |
 | RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED`; PRODUCT functionality plus resumable research observability |
 | Gen2 x1 implementation target | `FROZEN` | Required final configuration or better; hardware remains `NOT_PROVEN` |
 | Sustained application payload `>= 288 MB/s/card` | `FROZEN` | Requirement remains `NOT_PROVEN` and not yet qualified |
-| Application C2H payload | `PLANNED` | Not yet accepted |
-| Record-to-AXI-stream data plane | `BLOCKED` | `READY_FOR_SIGNOFF_RECOVERY`; not offline-qualified |
-| G2B-HW | `BLOCKED` | No final offline sign-off, pre-bitstream PASS, bitstream candidate, or hardware proof |
+| Application C2H payload | `ACCEPTED` | Exact one-channel candidate offline only; hardware NOT_PROVEN |
+| Record-to-AXI-stream data plane | `ACCEPTED` | One-channel PRODUCT offline-qualified; hardware NOT_PROVEN |
+| G2B-HW | `PLANNED` | `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; NOT_STARTED / NOT_PROVEN |
 | One-channel application DMA | `PLANNED` | Not yet qualified |
 | Two-channel application DMA | `PLANNED` | Not yet qualified |
 | Two-card host topology | `PLANNED` | Architectural requirement, not two-card hardware qualification |
@@ -169,8 +146,8 @@
 
 The current Gen1 x1 donor is a proven control-plane donor and is not the final
 throughput configuration. G2B-LUT0 estimates PRODUCT at 17,512 LUT / 84.192%,
-but that value is not measured qualification evidence and the target is not
-marked achieved.
+as a historical estimate. Actual Recovery-4 PRODUCT is 17,366 LUT / 83.490%;
+the hard gate and preferred target are achieved offline.
 
 ## Current Linux Video direction
 
@@ -180,3 +157,28 @@
 Standard `/dev/videoX` presentation, FFmpeg, GStreamer, OpenCV, multi-card
 support, stable identity, and a future DMABUF/zero-copy path remain goals;
 V4L2 is `NOT_IMPLEMENTED`.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/CURRENT_TRACKS.md
+++ b/project-current-state/CURRENT_TRACKS.md
@@ -1,15 +1,15 @@
 # AHD Current Development Tracks
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
 ## Track summary
 
 | Track | Purpose | Last accepted gate | Active gate | Next expected decision point | Track status |
 |---|---|---|---|---|---|
-| G-track | Product FPGA integration, data plane, qualification, and release architecture | G2B-LUT0 resource architecture | G2A remains separately active | `G2B-LUT1-SIGNOFF-RECOVERY-4` and complete offline requalification | `ACTIVE`; G2B-IMPL sign-off recovery pending |
+| G-track | Product FPGA qualification | `G2B-LUT1-SIGNOFF-RECOVERY-4` | G2A separately active | `G2B-HW0-PRODUCT` | `ACTIVE`; exact PRODUCT offline candidate accepted |
 | R-track | Isolate the R1i physical-SCL/ACK/recovery causal mechanism and characterize margin | R0 | none executing | Resume R2/R3 later through RESEARCH_DIAGNOSTIC | lifecycle `ACTIVE`; execution state `HOLD`, not closed |
 | L-track | Native Linux/V4L2 product integration through a transport abstraction | none | none | Approve/launch L0 with final input assumptions and interfaces | `PLANNED` |
-| META track | Maintain current project truth, governance, provenance, revisions, and compatibility | META-7R | none | Next explicitly authorized accepted-state change | `ACCEPTED` |
+| META track | Accepted SSOT and auditability | META-8A | none | Next explicitly authorized state change | `ACCEPTED` |
 
 ## G-track — product development
 
@@ -29,16 +29,12 @@
   `AHD_C2H_TRANSPORT_ABI_V1` is `FROZEN_FOR_G2B`, G2B MMIO is `FROZEN` at
   `0x3800..0x3BFF`, and the Linux consumer contract is a frozen transport
   input.
-- G2B-IMPL: lifecycle `BLOCKED`; implementation state
-  `ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING`; not offline-qualified and
-  no bitstream exists; Groups 15–17 candidate implementation and validation remain
-  pending.
-- G2B-LUT0: `ACCEPTED` — Plan B resource architecture only.
-- G2B-LUT1: lifecycle `PLANNED`, readiness
-  `READY_FOR_SIGNOFF_RECOVERY`; exact next gate
-  `G2B-LUT1-SIGNOFF-RECOVERY-4`.
-- G2B-HW: lifecycle `BLOCKED`; final offline sign-off, pre-bitstream hard gate,
-  and a bitstream candidate do not exist.
+- G2B-IMPL: ACCEPTED for exact one-channel offline implementation via G2B-LUT1; hardware NOT_PROVEN.
+- G2B-LUT0: ACCEPTED — Plan B architecture retained.
+- G2B-LUT1: ACCEPTED; OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE; accepted gate G2B-LUT1-SIGNOFF-RECOVERY-4.
+- G2B-HW / G2B-HW0-PRODUCT: PLANNED, AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION, NOT_STARTED / NOT_PROVEN; hardware evidence absent.
+- LAST_ACCEPTED_GATE: G2B-LUT1-SIGNOFF-RECOVERY-4.
+- NEXT_ALLOWED_ENGINEERING_STEP: G2B-HW0-PRODUCT.
 
 ### Current dependencies
 
@@ -73,38 +69,14 @@
 - `GROUPS_10_TO_12 = PRESERVE_PASS`; and
 - `GROUPS_15_TO_17 = PROMOTED`.
 
-### Next decision
-
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
-
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
-
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
-
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
+### Offline gate completion and next hardware decision
+
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
 
 The PRODUCT hard gate remains routed LUT `<=90%`, with a preferred
 `80–85%` target; the 84.192% planning estimate is not an achieved result.
@@ -156,7 +128,7 @@
 ### Gate state
 
 - L0: `PLANNED`.
-- No accepted or active Linux gate exists at revision 7.
+- No accepted or active Linux gate exists at revision 8.
 - The Linux transport consumer input contract is frozen; V4L2 remains
   `NOT_IMPLEMENTED`.
 
@@ -209,8 +181,9 @@
 RTL or active XDC and does not accept G2B offline qualification, a bitstream,
 hardware, or V4L2.
 
-META-7R promotes the combined Groups 15–17 architecture through one
-unnumbered governed decision while preserving Groups 9–14 PASS.
+META-7R promoted the combined Groups 15–17 architecture. META-8A now
+accepts the exact completed offline PRODUCT candidate and separately plans
+G2B-HW0-PRODUCT; no hardware operation is started.
 
 ### Current dependencies
 
@@ -226,5 +199,30 @@
 
 ### Next decision
 
-After revision-7 publication, the next update begins only when a separate task
+After revision-8 publication, the next update begins only when a separate task
 satisfies every field in `META_UPDATE_TEMPLATE.md`.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/EVIDENCE_MAP.md
+++ b/project-current-state/EVIDENCE_MAP.md
@@ -1,9 +1,9 @@
 # AHD Current-State Evidence Map
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
-Evidence `main` accepted-evidence anchor used for revision 7:
-`fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`
+Evidence accepted-evidence anchor used for revision 8:
+`6843d582fd367fbc0edc0b1d55a9617162c489b0`
 
 ## Acceptance rule
 
@@ -54,6 +54,10 @@
 promoted.
 
 ## Authoritative evidence packages
+
+Earlier package descriptions retain their historical promotion-time boundaries;
+pending implementation/bitstream wording below is historical to that package,
+not current continuation authority. Revision-8 qualification is bound below.
 
 | Evidence ID | Directory | Latest path commit | Original payload/add commit | Current subtree |
 |---|---|---|---|---|
@@ -196,20 +200,20 @@
 | `STMT-GM1` | G-1 is current accepted product history/inventory | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1`; `STATE.json` and inventory report at `654b9ad...` | Engineering inventory `PASS`, source/donor context | Evidence `PASS` alone did not accept G-1 |
 | `STMT-G0` | G0 baseline freeze is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G0`; `V41_G0_STATE.json` and freeze report at `b5efb25...` | Exact R1i/donor identities and requirements | Acceptance supplied separately |
 | `STMT-G1` | G1 architecture is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1`; `V41_G1_STATE.json` and architecture report at `f1258ba...` | `G2_IMPLEMENTATION_ALLOWED` and integration/C2H design | Does not accept G2 execution or throughput |
-| `STMT-G2B-PRE` | G2B-PRE architecture freeze is accepted and its contract input was ready for implementation from the accepted G2A input base | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; architecture-freeze report, state, consistency report, and decision log at `e8ab101...` | Engineering `PASS`, exact G2A input identity, complete ABI/MMIO decisions, and Linux consumer input contract | Historical contract-input readiness is not current G2B-IMPL readiness; current G2B-LUT1 readiness is `READY_FOR_SIGNOFF_RECOVERY` at `G2B-LUT1-SIGNOFF-RECOVERY-4` |
+| `STMT-G2B-PRE` | G2B-PRE architecture contract remains ACCEPTED; exact PRODUCT implementation now separately accepted offline | `ACCEPTED` | `META-2_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Unchanged interface, distinct offline acceptance | No hardware proof |
 | `STMT-G2B-LUT0` | G2B-LUT0 resource-architecture review is accepted | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; architecture review, inventory, plan, targets, and proposal at `a70c55e...` | Engineering `PASS`; blocked G2B 21,412/20,800 LUT; separable R1i fix; reversible Plan B | Acceptance authorizes architecture only; no source profile, achieved target, timing, bitstream, or hardware result |
-| `STMT-BUILD-PROFILES` | PRODUCT and RESEARCH_DIAGNOSTIC are authorized but not implemented; functional and external product semantics must be identical | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; build-profile proposal and recommended plan | Reversible separation of qualified function from research observability | RESEARCH_DIAGNOSTIC post-G2B build/route is not proven; implementation mechanism remains for G2B-LUT1 |
-| `STMT-PRODUCT-LUT-POLICY` | PRODUCT routed LUT hard gate is `<=90%`, preferred target is `80–85%` | `FROZEN` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; resource targets | Point estimate 17,512 LUT / 84.192%, planning range and required recovery | Estimate is not qualification evidence; target is not achieved until actual post-route measurement |
-| `STMT-G2B-IMPL` | G2B-IMPL remains not offline-qualified; G2B-LUT1 is `READY_FOR_SIGNOFF_RECOVERY` and the next gate is `G2B-LUT1-SIGNOFF-RECOVERY-4` | `BLOCKED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-LUT0`, `EVID-G2B-BS3`, `EVID-G2B-G13A`, and `EVID-G2B-G14A`, `EVID-G2B-G15-17-EQ` | Accepted resource architecture; promoted Group-9, Group-13, and Group-14 sign-off methods; exact continuation boundary | Groups 15–17 active XDC is not yet updated; no final sign-off, bitstream, or hardware proof |
+| `STMT-BUILD-PROFILES` | PRODUCT exact candidate offline-qualified; RESEARCH_DIAGNOSTIC qualification not promoted | `ACCEPTED` | `META-3_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | PRODUCT profile receipt and functional protection PASS | Research build/route remains not proven |
+| `STMT-PRODUCT-LUT-POLICY` | <=90% hard gate, 80–85% preferred target; actual PRODUCT 17366/20800 (83.490%) | `FROZEN` | `META-3_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Actual routed resource gate PASS | Historical estimate is not substituted for actual result |
+| `STMT-G2B-IMPL` | Exact one-channel PRODUCT implementation ACCEPTED offline through G2B-LUT1; next G2B-HW0-PRODUCT | `ACCEPTED` | `META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | All Groups 1–17, final routed sign-off and exact bitstream | No separate G2A acceptance or hardware proof |
 | `STMT-GROUP9-SIGNOFF` | Current Group-9 `OWNERSHIP_AXI_TO_SOURCE` method is `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`; `GLOBAL_SET_BUS_SKEW_3NS` and the global Group-9 `report_bus_skew` are retired from required sign-off | `ACCEPTED` | `META-4R2_TASK_DIRECTIVE` | `EVID-G2B-BS1R`, `EVID-G2B-BS2`, `EVID-G2B-BS3` at their exact commits | Pathology reproduction, invalid global comparison, stable-data CDC proof, 3 families, `6.000 ns` cap, `13.468 ns` margin, `7.468 ns` reserve | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; not a relaxation of safety; `RTL_CHANGE_REQUIRED = NO`; promotion-time active-XDC boundary was pending; current result is `PRESERVE_PASS`, do not repeat |
 | `STMT-GROUP9-DECISION` | Named unnumbered Group-9 sign-off-methodology decision is `RESOLVED` as `REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS` | `ACCEPTED` | `META-4R2_TASK_DIRECTIVE` | BS1R `f3a0df6...`; BS2 `4699632...`; BS3 `10f1b66...` | Exact decision provenance and Owner/Architect approval | No `OD-*` ID invented; every registered open OD entry remains unchanged |
 | `STMT-GROUP13-SIGNOFF` | Current Group-13 `RESET_RETURN_SOURCE_TO_AXI` method is `SETTLING_PLUS_STRUCTURAL_CDC`; its global `GLOBAL_SET_BUS_SKEW_3NS` and `report_bus_skew` are retired from required sign-off | `ACCEPTED` | `META-5_TASK_DIRECTIVE` | `EVID-G2B-G13A` at `10c7c2898d162af8e2262b3f99861c7d560c4557` | 7/207 scope, verified timeout, invalid skew comparison, two exact families, `6.000 ns` family and retained aggregate settling, complete structural reset-return proof | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; no safety relaxation; `RTL_CHANGE_REQUIRED = NO`; promotion-time active-XDC boundary was pending; current result is `PRESERVE_PASS`, do not repeat |
 | `STMT-GROUP13-DECISION` | Named unnumbered Group-13 sign-off-methodology decision is `RESOLVED` as `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `META-5_TASK_DIRECTIVE` | `EVID-G2B-G13A` at `10c7c289...` | Exact decision provenance and Owner/Architect approval | No `OD-*` ID invented; all existing open and decided records remain unchanged |
 | `STMT-GROUP14-SIGNOFF` | Current Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` method is `SETTLING_PLUS_STRUCTURAL_CDC`; its global `GLOBAL_SET_BUS_SKEW_3NS` and `report_bus_skew` are retired from required sign-off | `ACCEPTED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` at `9e91315968453e859006077191cd5fc711fc6b96` | 56/20 scope, verified timeout, invalid skew comparison, three exact `6.000 ns` families, and complete release/reset structural CDC proof | `SAFER_AND_MORE_SEMANTICALLY_CORRECT`; no safety relaxation; `RTL_CHANGE_REQUIRED = NO`; HISTORICAL META-6 active XDC pending at promotion; current result `PRESERVE_PASS` |
 | `STMT-GROUP14-DECISION` | Named unnumbered Group-14 sign-off-methodology decision is `RESOLVED` as `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` at `9e913159...` | Exact decision provenance and Owner/Architect approval | No `OD-*` ID invented; all existing open and decided records remain unchanged |
-| `STMT-G2B-HW` | G2B-HW is `BLOCKED` | `BLOCKED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-BS3`, `EVID-G2B-G13A`, `EVID-G2B-G14A`, `EVID-G2B-G15-17-EQ`, and current SSOT | Groups 15–17 candidate implementation, remaining final offline sign-off, and bitstream candidate are absent | No hardware, qualification, release, or bitstream claim |
+| `STMT-G2B-HW` | G2B-HW PLANNED; AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION; NOT_STARTED / NOT_PROVEN | `PLANNED` | `META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Exact candidate available and scoped future gate | Fresh DUT exclusivity and exact operational authorization required |
 | `STMT-GROUPS-10-12` | `GROUPS_10_TO_12 = PRESERVE_PASS` | `FROZEN` | `META-6_TASK_DIRECTIVE` | `EVID-G2B-G14A` state and continuation plan plus predecessor authority | G14-A preserves the authoritative Group-10/11/12 PASS results | Do not repeat them in the recovery-3 continuation |
-| `STMT-GROUPS-15-17` | Groups 15–17 `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global methods retired; nine `6.000 ns` checks | `ACCEPTED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-G15-17-EQ` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c` | Partial routed equivalence; proven safety protocol; independent slot checks; 13.468 ns window and 7.468 ns reserve | Active XDC authorized but not implemented; no final sign-off or hardware proof |
+| `STMT-GROUPS-15-17` | Groups 15–17 `SETTLING_PLUS_STRUCTURAL_CDC` promoted; old global methods retired; nine `6.000 ns` checks | `ACCEPTED` | `META-7R_TASK_DIRECTIVE` | `EVID-G2B-G15-17-EQ` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c` | Partial routed equivalence; proven safety protocol; independent slot checks; 13.468 ns window and 7.468 ns reserve | Historical META-7R boundary: active XDC pending at promotion; Recovery-4 now implements and signs off exact PRODUCT; hardware NOT_PROVEN |
 | `STMT-G2A` | G2A is active/in progress | `ACTIVE` | `META-0_TASK_DIRECTIVE` | No G2A package at evidence snapshot; local-only `integration/v41-r1i-gen2-g2a@22f15a6befe911172073e46a95d50b53afe1fc33` | Execution-time working context only; no published evidence commit | No result, build, or architecture promotion inferred |
 | `STMT-R0` | R0 is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R0`; `R0_STATE.json` and experiment plan at `aff7e32...` | Research design/protocol `PASS` | R0 evidence states R1 was not started at publication |
 | `STMT-R1` | R-track lifecycle context remains active but execution state is `HOLD`; R2/R3 remain resumable and not closed | `ACTIVE` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0` instrumentation inventory/proposal plus preserved `EVID-R0` | Research instrumentation is separable and recoverable through RESEARCH_DIAGNOSTIC | No scientific closure, cancellation, supersession, branch modification, or research evidence deletion |
@@ -224,16 +228,16 @@
 | `STMT-INHERITANCE` | R1i already inherits required XDMA substrate | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` architecture report at `f1258ba...` | Git ancestry/blob comparison and conflict plan | Future integration starts from R1i |
 | `STMT-PCIE` | Gen2 x1 or better and `>=288 MB/s/card` are frozen requirements | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-G0` throughput contract; `EVID-G1` budget/feasibility | Gen1 impossibility and Gen2 planning feasibility | Gen2 and throughput not qualified |
 | `STMT-VIDEO` | 1080p25, 4 inputs/card, max 2 active/card, 2 planned cards/host | `FROZEN` | `META-0_TASK_DIRECTIVE` | G0/G1 support per-card inputs/concurrency; two-card direction is Owner input | Per-card architecture and planning assumptions | Two-card operation not qualified |
-| `STMT-C2H-ARCH` | One C2H/card, two private four-record rings, shared engine, record RR | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` C2H and two-channel architecture at `f1258ba...` | Selected G1 architecture and scheduler model | Second ingress and implementation not qualified |
-| `STMT-ABI` | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, is lifecycle `FROZEN` with semantic state `FROZEN_FOR_G2B`; geometry is 4096/64/3840/192 bytes | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; normative ABI Markdown/JSON and consistency report at `e8ab101...` | Exact header, UYVY line payload, zero padding, sequence/epoch, ownership, loss, reset, and 64-bit AXI mapping | Frozen contract is not implemented transport or hardware proof |
-| `STMT-G2B-MMIO` | G2B MMIO contract `0x3800..0x3BFF` is frozen; all legacy behavior through `0x37FF` remains protected | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; normative MMIO Markdown/CSV at `e8ab101...` | Exact capability, control/status, counter, snapshot, and error semantics | Implementation is `NOT_IMPLEMENTED`; hardware is `NOT_PROVEN`; no current build may advertise it |
+| `STMT-C2H-ARCH` | One C2H/card, two private four-record rings, shared engine, record RR | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` C2H and two-channel architecture at `f1258ba...` | Selected G1 architecture and scheduler model | Second ingress and two-channel implementation not qualified; one-channel PRODUCT now accepted offline |
+| `STMT-ABI` | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, is lifecycle `FROZEN` with semantic state `FROZEN_FOR_G2B`; geometry is 4096/64/3840/192 bytes | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; normative ABI Markdown/JSON and consistency report at `e8ab101...` | Exact header, UYVY line payload, zero padding, sequence/epoch, ownership, loss, reset, and 64-bit AXI mapping | Contract freeze alone is not implementation proof; exact PRODUCT implementation accepted separately by META-8A, hardware NOT_PROVEN |
+| `STMT-G2B-MMIO` | MMIO 0x3800..0x3BFF frozen and implemented in exact offline PRODUCT; legacy through 0x37FF protected | `FROZEN` | `META-2_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | ABI/MMIO unchanged and offline regression PASS | Hardware NOT_PROVEN; diagnostic range not promoted |
 | `STMT-LINUX-TRANSPORT-INPUT` | Linux consumer contract is frozen as the transport input contract for `AHD_C2H_TRANSPORT_ABI_V1` | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; Linux consumer contract and ABI artifacts at `e8ab101...` | Parser validation for ABI/version, record boundaries, sequence, epoch, and zero padding | V4L2, DMABUF, timestamping, persistent identity, and multi-card policy remain not implemented or open |
 | `STMT-OD-06-CLOSURE` | Tracked decision `OD-06 / Final C2H transport ABI` is closed by the accepted G2B-PRE contract, including all 15 technical closure groups | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; decision log closure matrix at `e8ab101...` | Final values for sequences, epoch, identity, payload/padding, ownership/reset, MMIO, coherency, errors, and compatibility | This closes only OD-06; OD-01..OD-05 and OD-07..OD-10 remain open |
-| `STMT-APP-DMA` | Endpoint/MMIO/AXI-Lite proven; application C2H and DMA qualification absent | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1` inventory; `EVID-G0` data-plane gap/donor receipt; `EVID-G1` | Proven control plane and documented tied-off C2H | Enumeration/nonzero bytes are insufficient |
-| `STMT-INTERFACES` | Identity words, BAR structure, legacy MMIO, R1i page, and the G2B extension contract are authoritative | `FROZEN` | `META-0_TASK_DIRECTIVE`; `META-2_TASK_DIRECTIVE` for the G2B extension only | G-1 document index, [donor AXI-Lite map](https://github.com/lukaszsudul/FPGA_AHD/blob/c89e88bcdf389614c884fb129e8b2d42a585bccb/docs/v41/phase3/AXI_LITE_REGISTER_MAP.md), R1i source `20c332...`, and `EVID-G2B-PRE` MMIO artifacts | Exact legacy values/ranges, preservation rule, and frozen G2B extension contract | The G2B extension remains not implemented and not hardware-qualified |
-| `STMT-RESOURCES` | R1i qualified resource result remains historical; G2A is 18,178 routed LUT, blocked G2B is 21,412 post-opt LUT, and PRODUCT is estimated at 17,512 LUT / 84.192% | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G1` for qualified R1i; `EVID-G2B-LUT0` for G2A/G2B attribution and estimates | Exact reported values, stage warning, 3,900 LUT estimate with 3,500–4,300 range | PRODUCT estimate is not an achieved or post-route-qualified result |
+| `STMT-APP-DMA` | Endpoint/MMIO substrate proven at original scope; one-channel PRODUCT accepted offline; hardware DMA unproven | `ACCEPTED` | `META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Offline regression and unchanged ABI/MMIO | Enumeration or nonzero bytes are insufficient |
+| `STMT-INTERFACES` | Legacy interfaces and unchanged G2B extension authoritative; candidate uses explicit dual identity | `FROZEN` | `META-2_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Runtime fingerprint and governed source/DCP/binary bound separately | Hardware NOT_PROVEN |
+| `STMT-RESOURCES` | R1i hardware baseline resources preserved; actual PRODUCT 17366 LUT, 19314 FF, 26.5 BRAM, 0 DSP accepted offline | `ACCEPTED` | `META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | Exact Recovery-4 routed utilization | No diagnostic-profile or hardware qualification |
 | `STMT-RESEARCH` | R-track research remains valid and resumable under state `HOLD`; RESEARCH_DIAGNOSTIC preserves its observability | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-R0` experiment plan/matrix; `EVID-G2B-LUT0` inventory/profile proposal | Controlled research purpose and reproducible observability boundary | R2/R3 scientific closure remains open and no branch/evidence is modified |
-| `STMT-OD-03-CLOSURE` | Resource-architecture question is decided by PRODUCT + RESEARCH_DIAGNOSTIC, with implementation pending | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; main review, recommended plan, build-profile proposal | Safest resource-recovery architecture without R1i/ABI/MMIO/G2B architecture changes | Actual LUT, timing, hardware, and R2/R3 closure remain open |
+| `STMT-OD-03-CLOSURE` | Plan B resource architecture retained; PRODUCT offline implementation accepted | `ACCEPTED` | `META-3_TASK_DIRECTIVE; META-8A_TASK_DIRECTIVE` | `EVID-G2B-RECOVERY4` at `6843d582fd367fbc0edc0b1d55a9617162c489b0`; earlier immutable package entries preserved | PRODUCT resource and functional preservation PASS | Paired diagnostic profile, hardware and R2/R3 closure remain open |
 | `STMT-LINUX` | V4L2/common core/transport abstraction/XDMA-first direction | `PLANNED` | `META-0_TASK_DIRECTIVE` | No matching evidence package at snapshot | Owner/Architect-approved planned direction | No driver/frontend/backend implementation claimed |
 | `STMT-GOV` | Only authorized META writer after explicit Owner decision may update SSOT | `FROZEN` | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` | `GOVERNANCE.md` and `UPDATE_POLICY.md` in revision 1 | Governance authorization itself | Future governance change needs new accepted META revision |
 
@@ -266,3 +270,40 @@
 evidence only. See `CURRENT_ARCHITECTURE.md` for the complete accepted basis.
 META-6 precedent: `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde` /
 `v41-meta-project-state-rev6-group14-release-slot-signoff` (HISTORICAL).
+
+## Revision-8 authoritative Recovery-4 evidence
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
+
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
+
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
+
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
+
+Required reviewed files: V41_G2B_LUT1_SIGNOFF_RECOVERY4_REPORT.md; G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json; G2B_LUT1_PRODUCT_CANDIDATE_PROVENANCE.md; G2B_PRE_BITSTREAM_HARD_GATE_RECOVERY4.txt; G2B_HW0_SYNTHETIC_DMA_TEST_PLAN.md; G2B_LUT1_RECOVERY4_ALL_GROUPS_MATRIX.csv; G2B_LUT1_RECOVERY4_CDC_DISPOSITION.md; G2B_LUT1_RECOVERY4_RESOURCE_SUMMARY.md; G2B_LUT1_RECOVERY4_TIMING_SUMMARY.md; G2B_LUT1_RECOVERY4_SHA256_MANIFEST.txt. All 181 manifest entries verified at the immutable commit.
+
+The historical synthetic HW0 plan and report continuation are not promoted. The explicit META-8A live-path gate contract governs the next step. DIAG0 at c231e1e575295638e3bd20ef8c942fcb7fd90408 is context only, BLOCKED / NOT_PROMOTED.
--- a/project-current-state/GOVERNANCE.md
+++ b/project-current-state/GOVERNANCE.md
@@ -1,7 +1,7 @@
 # AHD Project Current-State Governance
 
 Governance version: `1`
-Project-state revision governed: `7`
+Project-state revision governed: `8`
 Lifecycle status: `FROZEN`
 
 ## 1. Purpose and scope
--- a/project-current-state/OPEN_DECISIONS.md
+++ b/project-current-state/OPEN_DECISIONS.md
@@ -1,8 +1,8 @@
 # AHD Open Decisions
 
-`PROJECT_STATE_REV = 7`
+`PROJECT_STATE_REV = 8`
 
-Every item below has lifecycle status `OPEN`. An agent may investigate or
+Every item in the open table below has lifecycle status `OPEN`. An agent may investigate or
 publish evidence about an item, but may not silently choose a value or update
 project truth. Closure requires an explicit Owner/Architect decision and, when
 the SSOT changes, a separate authorized META update.
@@ -12,17 +12,33 @@
 | `OD-01` | Exact R1i causal mechanism | `OPEN` | R1i proves the intervention works but sole-root-cause attribution is `INCONCLUSIVE` | Accepted R1 controlled evidence discriminating physical SCL, ACK sampling, combined effect, and recovery/readiness |
 | `OD-02` | R1i timing margin | `OPEN` | Qualified point behavior is not a complete margin characterization | Triggered margin campaign with controlled timing sweep, failure boundaries, and Owner decision |
 | `OD-04` | Actual Gen2 training | `OPEN` | Gen2 is architecturally allowed but not hardware-qualified | Endpoint/parent capability and negotiated 5.0 GT/s x1 evidence, reset/retrain/AER results |
-| `OD-05` | Actual `user_clk` after Gen2 | `OPEN` | XCI request, metadata, and routed evidence are not fully consistent | Generated/post-route clock proof and later hardware lifecycle/frequency measurement |
+| `OD-05` | Actual `user_clk` after Gen2 | `OPEN` | Recovery-4 proves user/AXI 62.500 MHz offline; actual hardware clock behavior unproven | Generated/post-route clock proof and later hardware lifecycle/frequency measurement |
 | `OD-07` | Final V4L2 pixel format | `OPEN` | Linux frontend is planned and end-to-end format presentation is not decided | Userspace compatibility analysis and explicit V4L2 format decision |
 | `OD-08` | Timestamp architecture | `OPEN` | Source, DMA, host, monotonic, and cross-card timestamp semantics are undecided | Clock-domain/source definition, wrap/synchronization policy, V4L2 mapping, validation plan |
 | `OD-09` | Persistent card identity | `OPEN` | Enumeration order is not a stable two-card product identity | Hardware identity source and persistent card/input mapping policy |
 | `OD-10` | Future LitePCIe role | `OPEN` | It is only a potential later backend; compatibility and value are unproven | Transport abstraction contract, feature/performance/resource comparison, Owner decision |
-| `OD-11` | Actual PRODUCT post-route LUT result | `OPEN` | 17,512 LUT / 84.192% is only a G2B-LUT0 estimate | Paired G2B-LUT1 post-route utilization proving `<=90%`, preferably `80–85%` |
-| `OD-12` | Actual PRODUCT and RESEARCH_DIAGNOSTIC timing | `OPEN` | No profile implementation or post-route timing result exists | Complete timing/DRC/CDC requalification of both profiles |
-| `OD-13` | Actual G2B hardware result | `OPEN` | No G2B bitstream, DMA capture, or hardware proof exists | Separately authorized hardware qualification after offline acceptance |
+| `OD-11` | Actual PRODUCT post-route LUT result | `OPEN` | PRODUCT 17,366 LUT / 83.490% accepted offline; paired-profile attribution outside this promotion | Paired G2B-LUT1 post-route utilization proving `<=90%`, preferably `80–85%` |
+| `OD-12` | Actual PRODUCT and RESEARCH_DIAGNOSTIC timing | `OPEN` | PRODUCT routed WNS +0.023 ns and WHS +0.043 ns accepted; RESEARCH_DIAGNOSTIC timing unqualified | Complete timing/DRC/CDC requalification of both profiles |
+| `OD-13` | Actual G2B hardware result | `OPEN` | Exact PRODUCT bitstream available and accepted offline; DMA capture and hardware proof absent | Separately authorized hardware qualification after offline acceptance |
 | `OD-14` | R2/R3 scientific closure | `OPEN` | R-track is `HOLD`, not closed | Resume research through RESEARCH_DIAGNOSTIC and obtain explicit scientific closure decision |
 
-## Decided at project-state revision 7 — Groups 15–17
+## Decided at project-state revision 8 — exact offline PRODUCT candidate
+
+Record form: UNNUMBERED_GOVERNED_DECISION; no OD number invented.
+META-8A_TASK_DIRECTIVE accepts G2B-LUT1-SIGNOFF-RECOVERY-4 as the completed
+offline PRODUCT gate, promoting only the exact binding in ACTIVE_BASELINES.md
+for G2B-HW0-PRODUCT. Last accepted gate: Recovery-4; next allowed engineering
+step: G2B-HW0-PRODUCT, PLANNED, AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION,
+hardware NOT_PROVEN. R1i remains ACCEPTED and FROZEN.
+
+OD-05/11/12/13 descriptions incorporate evidence without closing registered
+decisions or accepting paired-profile/hardware work. Unrelated decisions are
+unchanged. Hardware throughput, Gen2, release, multi-input/two-channel, V4L2,
+DIAG0 and R2/R3 closure are not resolved. All earlier decision sections below
+are historical promotion-time records; their pending/next-task statements
+are not current instructions. Accepted methods, bounds and evidence remain.
+
+## Historical decision at project-state revision 7 — Groups 15–17
 
 | Decision subject | Decision | Lifecycle status | Decision state | Covered groups |
 |---|---|---|---|---|
--- a/project-current-state/PROJECT_STATE.json
+++ b/project-current-state/PROJECT_STATE.json
@@ -1,18 +1,18 @@
 {
   "project": "AHD_v41",
-  "project_state_revision": 7,
+  "project_state_revision": 8,
   "state_type": "CURRENT_ACCEPTED_STATE",
   "governance_version": 1,
   "last_update": "2026-09-05",
   "accepted_by_role": "OWNER_ARCHITECT",
-  "acceptance_authorization": "META-7R_TASK_DIRECTIVE",
+  "acceptance_authorization": "META-8A_TASK_DIRECTIVE",
   "ssot_write_authorization": "SSOT WRITE AUTHORIZED",
-  "update_type": "ARCHITECTURE_CHANGE",
+  "update_type": "TRACK_GATE_ACCEPTANCE",
   "source_evidence_repository": "lukaszsudul/AHD-diagnostic-evidence",
-  "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-  "source_evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
-  "expected_previous_project_state_revision": 6,
-  "write_contract_receipt": "v41-meta-project-state-rev7-groups15-17-release-slot-signoff/META7_FROZEN_WRITE_CONTRACT_RECEIPT.md",
+  "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+  "source_evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+  "expected_previous_project_state_revision": 7,
+  "write_contract_receipt": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_WRITE_CONTRACT_RECEIPT.md",
   "meta4r2_frozen_contract_header_sha256": "D7456D989F0D879B2E1FD8777876F5AE786947D789CE1D480CA720316AC7342B",
   "current_transport_abi_status": "FROZEN_FOR_G2B",
   "lifecycle_status_enum": [
@@ -38,14 +38,16 @@
   "tracks": {
     "product": {
       "status": "ACTIVE",
-      "last_accepted_gate": "G2B-LUT0",
+      "last_accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
       "active_gate": "G2A",
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "next_gate": "G2B-HW0-PRODUCT",
       "accepted_gates": [
         "G-1",
         "G0",
         "G1",
-        "G2B-LUT0"
+        "G2B-LUT0",
+        "G2B-LUT1",
+        "G2B-LUT1-SIGNOFF-RECOVERY-4"
       ],
       "accepted_contract_freezes": [
         "G2B-PRE"
@@ -68,11 +70,11 @@
         "evidence_directory": "v41-development-g2b-lut0-resource-attribution"
       },
       "g2b_lut1": {
-        "status": "PLANNED",
-        "readiness": "READY_FOR_SIGNOFF_RECOVERY",
-        "implementation_state": "SIGNOFF_RECOVERY_PENDING",
-        "scope": "PRESERVE_GROUPS9_TO_14_PASS_APPLY_PROMOTED_GROUPS15_TO_17_AND_COMPLETE_ROUTED_SIGNOFF",
-        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+        "status": "ACCEPTED",
+        "readiness": "OFFLINE_QUALIFIED",
+        "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED",
+        "scope": "EXACT_PRODUCT_ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "next_gate": "G2B-HW0-PRODUCT",
         "preserved_authoritative_results": [
           "GROUP9",
           "GROUP10",
@@ -82,8 +84,34 @@
           "GROUP14"
         ],
         "accepted_by_role": "OWNER_ARCHITECT",
-        "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "engineering_gate": "PASS",
+        "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+        "offline_qualification_state": "ACCEPTED",
+        "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+        "hardware_qualification": "NOT_PROVEN",
+        "release_state": "NOT_RELEASED",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
+      },
+      "next_allowed_engineering_step": "G2B-HW0-PRODUCT",
+      "g2b_hw0_product": {
+        "gate": "G2B-HW0-PRODUCT",
+        "status": "PLANNED",
+        "readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
+        "progress": "NOT_STARTED",
+        "qualification_state": "NOT_PROVEN",
+        "blocking_reason": null,
+        "bitstream_candidate": "AVAILABLE_EXACT_OFFLINE_QUALIFIED_PRODUCT",
+        "scope": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "next_gate": "G2B-HW0-PRODUCT",
+        "hardware_evidence_present": false,
+        "execution_requires_fresh_operational_authorization": true,
+        "gate_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
       }
     },
     "research": {
@@ -117,10 +145,12 @@
     },
     "meta": {
       "status": "ACCEPTED",
-      "current_task": "META-7R",
-      "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
-      "decision_source": "META-7R_TASK_DIRECTIVE",
-      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      "current_task": "META-8A",
+      "acceptance_basis": "EXACT_OFFLINE_PRODUCT_CANDIDATE_ACCEPTED_AND_SEPARATE_CONTROLLED_HW0_SCOPE_AUTHORIZED",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     }
   },
   "qualified_fpga_baseline": {
@@ -287,7 +317,10 @@
     "required_payload_qualified": false,
     "g1_classification": "G2_IMPLEMENTATION_ALLOWED",
     "accepted_by_role": "OWNER_ARCHITECT",
-    "source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
+    "source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd",
+    "offline_throughput_analysis": "PASS",
+    "offline_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+    "hardware_throughput_proven": false
   },
   "requirements": [
     {
@@ -328,9 +361,11 @@
       "status": "FROZEN",
       "requirement": ">= 288 MB/s per card",
       "implementation_target": "PCIe Gen2 x1 or better",
-      "qualification": "NOT_YET_QUALIFIED",
+      "qualification": "NOT_PROVEN",
       "accepted_by_role": "OWNER_ARCHITECT",
-      "source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
+      "source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd",
+      "offline_analysis": "PASS",
+      "offline_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     {
       "id": "REQ-LINUX-V4L2",
@@ -439,14 +474,16 @@
       "groups_10_to_12": "PRESERVE_PASS",
       "group_13": "PRESERVE_PASS",
       "groups_15_to_17": "PROMOTED",
-      "implementation_state": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
-      "qualification": "NOT_YET_QUALIFIED",
+      "qualification": "OFFLINE_PASS",
       "accepted_by_role": "OWNER_ARCHITECT",
       "decision_source": "META-6_TASK_DIRECTIVE",
       "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
       "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
       "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
-      "reexecution": "DO_NOT_REPEAT"
+      "reexecution": "DO_NOT_REPEAT",
+      "implementation_state_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "implementation_state": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     {
       "id": "REQ-G2B-GROUP15-RELEASE-SLOT-SIGNOFF",
@@ -473,11 +510,12 @@
         "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
       ],
       "rtl_change_required": "NO",
-      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
-      "qualification": "NOT_YET_QUALIFIED",
+      "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
+      "qualification": "OFFLINE_PASS",
       "accepted_by_role": "OWNER_ARCHITECT",
       "decision_source": "META-7R_TASK_DIRECTIVE",
-      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     {
       "id": "REQ-G2B-GROUP16-RELEASE-SLOT-SIGNOFF",
@@ -504,11 +542,12 @@
         "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
       ],
       "rtl_change_required": "NO",
-      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
-      "qualification": "NOT_YET_QUALIFIED",
+      "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
+      "qualification": "OFFLINE_PASS",
       "accepted_by_role": "OWNER_ARCHITECT",
       "decision_source": "META-7R_TASK_DIRECTIVE",
-      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     {
       "id": "REQ-G2B-GROUP17-RELEASE-SLOT-SIGNOFF",
@@ -535,11 +574,12 @@
         "NO_PREMATURE_OVERWRITE_OR_SLOT_REUSE"
       ],
       "rtl_change_required": "NO",
-      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
-      "qualification": "NOT_YET_QUALIFIED",
+      "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
+      "qualification": "OFFLINE_PASS",
       "accepted_by_role": "OWNER_ARCHITECT",
       "decision_source": "META-7R_TASK_DIRECTIVE",
-      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+      "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     }
   ],
   "c2h_architecture": {
@@ -561,10 +601,12 @@
     "transport_abi_name": "AHD_C2H_TRANSPORT_ABI_V1",
     "transport_abi_version": 1,
     "record_version": "0x00004101",
-    "implementation_state": "NOT_IMPLEMENTED",
+    "implementation_state": "ONE_CHANNEL_PRODUCT_OFFLINE_QUALIFIED_TWO_CHANNEL_TARGET_NOT_QUALIFIED",
     "hardware_qualification": "NOT_PROVEN",
     "accepted_by_role": "OWNER_ARCHITECT",
-    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
+    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e",
+    "candidate_source_commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "transport_abi": {
     "status": "FROZEN",
@@ -575,18 +617,24 @@
     "header_bytes": 64,
     "payload_bytes": 3840,
     "padding_bytes": 192,
-    "implementation_state": "NOT_IMPLEMENTED",
+    "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED_EXACT_ONE_CHANNEL_PRODUCT",
     "hardware_qualification": "NOT_PROVEN",
-    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
+    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e",
+    "candidate_source_commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "g2b_mmio": {
     "status": "FROZEN",
     "base": "0x3800",
     "end": "0x3BFF",
     "legacy_protected_through": "0x37FF",
-    "implementation_state": "NOT_IMPLEMENTED",
+    "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED_EXACT_ONE_CHANNEL_PRODUCT",
     "hardware_qualification": "NOT_PROVEN",
-    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
+    "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e",
+    "candidate_source_commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "application_dma": {
     "pcie_endpoint": {
@@ -602,16 +650,31 @@
       "maturity": "IMPLEMENTED_PROVEN"
     },
     "application_c2h_payload": {
-      "status": "PLANNED",
-      "qualification": "NOT_YET_ACCEPTED"
+      "status": "ACCEPTED",
+      "qualification": "OFFLINE_QUALIFIED_ONE_CHANNEL_HARDWARE_NOT_PROVEN",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     },
     "record_to_axi_stream_data_plane": {
-      "status": "BLOCKED",
-      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
-      "readiness": "READY_FOR_SIGNOFF_RECOVERY",
-      "implementation_state": "ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING",
-      "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
-      "offline_qualification_state": "NOT_ACCEPTED"
+      "status": "ACCEPTED",
+      "target_gate": "G2B-HW0-PRODUCT",
+      "readiness": "OFFLINE_QUALIFIED",
+      "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED",
+      "blocking_reason": null,
+      "offline_qualification_state": "ACCEPTED",
+      "engineering_gate": "PASS",
+      "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+      "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "hardware_qualification": "NOT_PROVEN",
+      "release_state": "NOT_RELEASED",
+      "scope": "EXACT_PRODUCT_ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+      "next_gate": "G2B-HW0-PRODUCT",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     },
     "one_channel_dma": {
       "status": "PLANNED",
@@ -623,7 +686,10 @@
     },
     "required_payload_288_mb_s": {
       "status": "PLANNED",
-      "qualification": "NOT_YET_QUALIFIED"
+      "qualification": "NOT_PROVEN",
+      "offline_analysis": "PASS",
+      "hardware_throughput_proven": false,
+      "offline_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd"
   },
@@ -694,11 +760,14 @@
       "axis_tlast": "FINAL_BEAT_ONLY",
       "build_identity_semantics": "MMIO_ONLY",
       "padding_semantics": "FORMATTER_GENERATED_ZERO",
-      "implementation_state": "NOT_IMPLEMENTED",
+      "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED_EXACT_ONE_CHANNEL_PRODUCT",
       "hardware_qualification": "NOT_PROVEN",
       "authoritative_markdown": "v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_TRANSPORT_ABI_V1.md",
       "authoritative_json": "v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_TRANSPORT_ABI_V1.json",
-      "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
+      "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e",
+      "candidate_source_commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "channel_identity": {
       "status": "ACCEPTED",
@@ -723,11 +792,14 @@
       "legacy_protected_through": "0x37FF",
       "future_reserved_start": "0x3C00",
       "future_reserved_end": "0x3FFF",
-      "implementation_state": "NOT_IMPLEMENTED",
+      "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED_EXACT_ONE_CHANNEL_PRODUCT",
       "hardware_qualification": "NOT_PROVEN",
       "authoritative_contract": "v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_MMIO_CONTRACT.md",
       "authoritative_map": "v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_MMIO_MAP.csv",
-      "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
+      "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e",
+      "candidate_source_commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "source_evidence_commit": "e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e"
   },
@@ -756,12 +828,12 @@
   "build_profiles": {
     "status": "ACCEPTED",
     "authorization_state": "AUTHORIZED",
-    "implementation_state": "NOT_IMPLEMENTED",
+    "implementation_state": "PRODUCT_OFFLINE_QUALIFIED_RESEARCH_DIAGNOSTIC_NOT_PROMOTED",
     "accepted_by_role": "OWNER_ARCHITECT",
     "decision_source": "META-3_TASK_DIRECTIVE",
     "product": {
-      "status": "PLANNED",
-      "authorization_state": "AUTHORIZED_NOT_IMPLEMENTED",
+      "status": "ACCEPTED",
+      "authorization_state": "OFFLINE_QUALIFIED",
       "lut_limit_operator": "<=",
       "lut_limit_percent": 90,
       "preferred_lut_range_percent": [
@@ -800,7 +872,15 @@
         "RESEARCH_ONLY_COUNTERS",
         "RESEARCH_ONLY_OBSERVATION_STRUCTURES",
         "OTHER_G2B_LUT0_CLASSIFIED_REMOVABLE_R_TRACK_INSTRUMENTATION"
-      ]
+      ],
+      "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+      "actual_post_route_lut": 17366,
+      "actual_post_route_lut_percent": 83.49,
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     },
     "research_diagnostic": {
       "status": "PLANNED",
@@ -828,8 +908,8 @@
       "PROFILE_REDUCTION_DOES_NOT_CHANGE_XDMA_CONFIGURATION"
     ],
     "implementation_authority": {
-      "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
-      "readiness": "READY_FOR_SIGNOFF_RECOVERY",
+      "target_gate": "G2B-HW0-PRODUCT",
+      "readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
       "mechanism_policy": "SELECT_LEAST_INVASIVE_REVERSIBLE_METHOD_SUPPORTED_BY_REPOSITORY",
       "permitted_mechanisms": [
         "VHDL_GENERICS",
@@ -837,8 +917,9 @@
         "GENERATE_BLOCKS",
         "SOURCE_SET_OR_PROFILE_SELECTION"
       ],
-      "selected_mechanism": null,
-      "meta3_source_change_authorized": false
+      "selected_mechanism": "PRODUCT_ELABORATION_ENABLE_RTRACK_DIAGNOSTICS_0",
+      "meta3_source_change_authorized": false,
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "research_reversibility": {
       "instrumentation_recoverable_through_research_diagnostic": true,
@@ -851,21 +932,22 @@
   },
   "g2b_resource_recovery": {
     "status": "ACCEPTED",
-    "plan_state": "PLAN_ACCEPTED_IMPLEMENTATION_PENDING",
+    "plan_state": "PRODUCT_IMPLEMENTED_OFFLINE_QUALIFIED_RESEARCH_PROFILE_QUALIFICATION_NOT_PROMOTED",
     "selected_plan": "PLAN_B_PRODUCT_AND_RESEARCH_DIAGNOSTIC",
-    "target_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "target_gate": "G2B-HW0-PRODUCT",
     "accepted_by_role": "OWNER_ARCHITECT",
     "decision_source": "META-3_TASK_DIRECTIVE",
-    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4"
+    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "g2b_implementation": {
-    "status": "BLOCKED",
-    "readiness": "READY_FOR_SIGNOFF_RECOVERY",
-    "implementation_state": "ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING",
-    "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
-    "offline_qualification_state": "NOT_ACCEPTED",
+    "status": "ACCEPTED",
+    "readiness": "OFFLINE_QUALIFIED",
+    "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED",
+    "blocking_reason": null,
+    "offline_qualification_state": "ACCEPTED",
     "decision_by_role": "OWNER_ARCHITECT",
-    "decision_source": "META-7R_TASK_DIRECTIVE",
+    "decision_source": "META-8A_TASK_DIRECTIVE",
     "accepted_g2a_base": {
       "scope": "G2B_PRE_IMPLEMENTATION_INPUT_ONLY",
       "branch": "integration/v41-r1i-gen2-g2a",
@@ -873,19 +955,27 @@
       "tree": "283f98c02e6f9c61716875415cf000682f8ab856",
       "g2a_gate_status_unchanged": "ACTIVE"
     },
-    "one_channel_c2h_rtl": "UNPROMOTED_RESOURCE_BLOCKED_EVIDENCE_SNAPSHOT",
-    "g2b_bitstream": "NOT_IMPLEMENTED",
+    "one_channel_c2h_rtl": "ACCEPTED_OFFLINE_EXACT_PRODUCT_CANDIDATE",
+    "g2b_bitstream": "AVAILABLE_EXACT_CANDIDATE",
     "g2b_host_capture": "NOT_IMPLEMENTED",
-    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-    "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+    "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+    "next_gate": "G2B-HW0-PRODUCT",
     "next_engineering_source": {
       "worktree": "C:\\FPGA\\V41_G2B",
+      "repository": "lukaszsudul/FPGA_AHD",
       "branch": "integration/v41-g2b-onech-c2h",
-      "commit": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
-      "tree": "e18833d46f7672f851c3cb8239f2f29091378294",
-      "scope": "AUTHORITATIVE_RECOVERY4_INPUT_NOT_QUALIFIED_BASELINE"
-    }
+      "commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "tree": "cf6bf82249c90782eab1978c68541ed9c0e6430b",
+      "scope": "ACCEPTED_OFFLINE_PRODUCT_CANDIDATE_NOT_HARDWARE_BASELINE"
+    },
+    "engineering_gate": "PASS",
+    "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+    "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "hardware_qualification": "NOT_PROVEN",
+    "release_state": "NOT_RELEASED",
+    "scope": "EXACT_PRODUCT_ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+    "accepted_by_role": "OWNER_ARCHITECT"
   },
   "ownership_cdc_signoff": {
     "status": "ACCEPTED",
@@ -933,7 +1023,12 @@
     "candidate_xdc": "G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc",
     "global_group9_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
     "groups_10_to_17": "UNCHANGED",
-    "future_signoff_recipe": [
+    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP9_REPORT_BUS_SKEW",
+    "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
+    "future_recipe_reexecution_required": false,
+    "next_gate": "G2B-HW0-PRODUCT",
+    "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "completed_offline_signoff_recipe": [
       "OWNERSHIP_STRUCTURAL_CDC_PROOF",
       "REQUEST_SYNCHRONIZER_VALIDATION",
       "ACKNOWLEDGEMENT_SYNCHRONIZER_VALIDATION",
@@ -946,10 +1041,8 @@
       "CLOCKS_AND_RESOURCES",
       "PRE_BITSTREAM_HARD_GATE"
     ],
-    "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP9_REPORT_BUS_SKEW",
-    "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
-    "future_recipe_reexecution_required": false,
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
+    "recipe_completion": "PASS_RECOVERY4",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "reset_return_cdc_signoff": {
     "status": "ACCEPTED",
@@ -1048,7 +1141,8 @@
       "admission_disabled_while_reset_busy": true,
       "commit_enqueue_and_scheduler_progress_suppressed_while_reset_busy": true,
       "reset_assertion_deassertion_model": "SYNCHRONOUS_PROCESS_OBSERVATION_NOT_ASYNC_ASSERT_SYNC_RELEASE",
-      "fresh_global_cdc_closure": "REQUIRED_LATER_HARD_GATE"
+      "fresh_global_cdc_closure": "PASS_RECOVERY4",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "rtl_change_required": "NO",
     "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
@@ -1060,7 +1154,7 @@
     "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP13_REPORT_BUS_SKEW",
     "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
     "future_recipe_reexecution_required": false,
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "next_gate": "G2B-HW0-PRODUCT",
     "historical_future_signoff_recipe_at_revision6": [
       "PRESERVE_GROUP9_PASS_DO_NOT_REPEAT",
       "PRESERVE_GROUPS10_TO_12_PASS_DO_NOT_REPEAT",
@@ -1078,7 +1172,8 @@
       "PRE_BITSTREAM_HARD_GATE",
       "BITSTREAM_ONLY_AFTER_PASS"
     ],
-    "historical_recipe_disposition": "SUPERSEDED_BY_GROUPS15_17_RELEASE_SLOT_CDC_SIGNOFF_FUTURE_SIGNOFF_RECIPE"
+    "historical_recipe_disposition": "SUPERSEDED_BY_GROUPS15_17_RELEASE_SLOT_CDC_SIGNOFF_FUTURE_SIGNOFF_RECIPE",
+    "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
   },
   "release_slot_cdc_signoff": {
     "status": "ACCEPTED",
@@ -1266,7 +1361,8 @@
         "epoch_identity_prevents_old_lifetime_alias": true
       },
       "group14_cdc_structure": "PASS_WITH_DISPOSITION",
-      "fresh_global_cdc_closure": "REQUIRED_LATER_HARD_GATE"
+      "fresh_global_cdc_closure": "PASS_RECOVERY4",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
     },
     "rtl_change_required": "NO",
     "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
@@ -1279,7 +1375,7 @@
     "group_13": "PRESERVE_PASS",
     "groups_15_to_17": "PROMOTED",
     "retired_check_excluded_from_future_recipe": "GLOBAL_GROUP14_REPORT_BUS_SKEW",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "next_gate": "G2B-HW0-PRODUCT",
     "historical_future_signoff_recipe_at_revision6": [
       "IMPLEMENT_G2B_G14A_CANDIDATE_CONSTRAINTS_XDC",
       "PRESERVE_GROUP9_PASS_DO_NOT_REPEAT",
@@ -1300,23 +1396,30 @@
     "historical_recipe_disposition": "SUPERSEDED_BY_GROUPS15_17_RELEASE_SLOT_CDC_SIGNOFF_FUTURE_SIGNOFF_RECIPE",
     "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
     "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
-    "reexecution": "DO_NOT_REPEAT"
+    "reexecution": "DO_NOT_REPEAT",
+    "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
   },
   "g2b_hardware": {
-    "status": "BLOCKED",
+    "status": "PLANNED",
     "progress": "NOT_STARTED",
     "qualification_state": "NOT_PROVEN",
-    "blocking_reason": "GROUPS15_TO_17_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
-    "bitstream_candidate": "NOT_AVAILABLE",
+    "blocking_reason": null,
+    "bitstream_candidate": "AVAILABLE_EXACT_OFFLINE_QUALIFIED_PRODUCT",
     "one_channel_dma": "NOT_PROVEN",
     "two_channel_dma": "NOT_PROVEN",
     "gen2_negotiation": "NOT_PROVEN",
     "payload_288_mb_s": "NOT_PROVEN",
     "decision_by_role": "OWNER_ARCHITECT",
-    "decision_source": "META-7R_TASK_DIRECTIVE",
-    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-    "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
+    "decision_source": "META-8A_TASK_DIRECTIVE",
+    "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+    "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+    "next_gate": "G2B-HW0-PRODUCT",
+    "readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
+    "scope": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+    "hardware_evidence_present": false,
+    "execution_requires_fresh_operational_authorization": true,
+    "gate_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md",
+    "accepted_by_role": "OWNER_ARCHITECT"
   },
   "resources": {
     "status": "ACCEPTED",
@@ -1355,18 +1458,47 @@
       80,
       85
     ],
-    "product_lut_target_achieved": false,
+    "product_lut_target_achieved": true,
     "estimate_is_qualification_evidence": false,
     "production_resource_expectation": false,
-    "interpretation": "G2B_LUT0_ESTIMATE_REQUIRES_G2B_LUT1_OR_G2B_IMPL_POST_ROUTE_REQUALIFICATION",
+    "interpretation": "R1I_HARDWARE_BASELINE_PRESERVED_EXACT_PRODUCT_OFFLINE_RESULT_ADDED",
     "qualified_r1i_source_evidence_commit": "f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd",
-    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4"
+    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4",
+    "product_offline_result": {
+      "status": "ACCEPTED",
+      "maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+      "LUT": {
+        "used": 17366,
+        "total": 20800,
+        "percent": 83.49
+      },
+      "FF": {
+        "used": 19314,
+        "total": 41600,
+        "percent": 46.428
+      },
+      "BRAM": {
+        "used": 26.5,
+        "total": 50,
+        "percent": 53.0
+      },
+      "DSP": {
+        "used": 0,
+        "total": 90,
+        "percent": 0.0
+      },
+      "hardware_qualification": "NOT_PROVEN",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
+    }
   },
   "diagnostic_reduction": {
     "status": "ACCEPTED",
     "authorization_state": "AUTHORIZED_FOR_REVERSIBLE_PRODUCT_PROFILE_IMPLEMENTATION",
     "currently_authorized": true,
-    "implementation_state": "PENDING_G2B_LUT1",
+    "implementation_state": "PRODUCT_IMPLEMENTED_OFFLINE_QUALIFIED_RESEARCH_PRESERVATION_REQUIRED",
     "requires_accepted_r_track_closure": false,
     "requires_owner_architect_decision": false,
     "requires_separate_meta_update": false,
@@ -1374,7 +1506,8 @@
     "research_evidence_deleted": false,
     "accepted_by_role": "OWNER_ARCHITECT",
     "decision_source": "META-3_TASK_DIRECTIVE",
-    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4"
+    "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
   },
   "linux_video": {
     "status": "PLANNED",
@@ -1399,7 +1532,8 @@
     "implemented": false,
     "accepted_by_role": "OWNER_ARCHITECT",
     "decision_source": "META-0_TASK_DIRECTIVE",
-    "source_evidence_commit": null
+    "source_evidence_commit": null,
+    "hw0_dependency": "NOT_REQUIRED_PLANNED_FOR_LATER_STAGE"
   },
   "open_decisions": [
     {
@@ -1472,7 +1606,8 @@
       "decision": "USE_PRODUCT_AND_RESEARCH_DIAGNOSTIC_PROFILES_AND_EXCLUDE_RESEARCH_ONLY_INSTRUMENTATION_FROM_PRODUCT_WHILE_PRESERVING_R1I_FUNCTIONALITY",
       "accepted_by_role": "OWNER_ARCHITECT",
       "decision_source": "META-3_TASK_DIRECTIVE",
-      "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4"
+      "source_evidence_commit": "a70c55eca5f0c0ad349143ad93ab87eb80d11ac4",
+      "decision_state_context": "HISTORICAL_META3_DECISION_CURRENT_PRODUCT_OFFLINE_IMPLEMENTATION_ACCEPTED_BY_META8A"
     },
     {
       "topic": "GROUP9_OWNERSHIP_AXI_TO_SOURCE_SIGNOFF_METHODOLOGY",
@@ -1528,6 +1663,17 @@
       "decision_source": "META-7R_TASK_DIRECTIVE",
       "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
       "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit"
+    },
+    {
+      "topic": "EXACT_OFFLINE_G2B_PRODUCT_CANDIDATE_ACCEPTANCE",
+      "record_form": "UNNUMBERED_GOVERNED_DECISION",
+      "status": "ACCEPTED",
+      "decision_state": "RESOLVED",
+      "decision": "ACCEPT_RECOVERY4_OFFLINE_PRODUCT_CANDIDATE_FOR_SEPARATE_G2B_HW0_PRODUCT",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     }
   ],
   "governance": {
@@ -1702,7 +1848,8 @@
         "STMT-R-TRACK-HOLD",
         "STMT-OD-03-CLOSURE"
       ],
-      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_RESOURCE_ARCHITECTURE_ONLY; PROFILE_IMPLEMENTATION_AND_POST_ROUTE_QUALIFICATION_REMAIN_PENDING; NO_BITSTREAM_OR_HARDWARE_RESULT"
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_RESOURCE_ARCHITECTURE_ONLY; PROFILE_IMPLEMENTATION_AND_POST_ROUTE_QUALIFICATION_REMAIN_PENDING; NO_BITSTREAM_OR_HARDWARE_RESULT",
+      "acceptance_boundary_context": "HISTORICAL_PROMOTION_TIME_BOUNDARY_CURRENT_OFFLINE_CANDIDATE_ACCEPTED_BY_META8A"
     },
     {
       "id": "EVID-G2B-BS1R",
@@ -1760,7 +1907,8 @@
         "STMT-G2B-IMPL",
         "STMT-G2B-HW"
       ],
-      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING"
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING",
+      "acceptance_boundary_context": "HISTORICAL_PROMOTION_TIME_BOUNDARY_CURRENT_OFFLINE_CANDIDATE_ACCEPTED_BY_META8A"
     },
     {
       "id": "EVID-G2B-G13A",
@@ -1786,7 +1934,8 @@
         "STMT-GROUPS-10-12",
         "STMT-GROUPS-14-17"
       ],
-      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_GROUP13_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; GROUP13_IMPLEMENTATION_FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING"
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_GROUP13_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; GROUP13_IMPLEMENTATION_FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING",
+      "acceptance_boundary_context": "HISTORICAL_PROMOTION_TIME_BOUNDARY_CURRENT_OFFLINE_CANDIDATE_ACCEPTED_BY_META8A"
     },
     {
       "id": "EVID-G2B-G14A",
@@ -1815,7 +1964,8 @@
         "STMT-GROUP13-SIGNOFF",
         "STMT-GROUPS-15-17"
       ],
-      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_GROUP14_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; GROUP14_IMPLEMENTATION_FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING"
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_GROUP14_SIGNOFF_ARCHITECTURE_ONLY; ACTIVE_XDC_NOT_MODIFIED; GROUP14_IMPLEMENTATION_FINAL_ROUTED_SIGNOFF_BITSTREAM_AND_HARDWARE_REMAIN_PENDING",
+      "acceptance_boundary_context": "HISTORICAL_PROMOTION_TIME_BOUNDARY_CURRENT_OFFLINE_CANDIDATE_ACCEPTED_BY_META8A"
     },
     {
       "id": "EVID-G2B-G15-17-EQ",
@@ -1839,7 +1989,35 @@
         "STMT-G2B-IMPL",
         "STMT-G2B-HW"
       ],
-      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_SIGNOFF_ARCHITECTURE_ONLY_ACTIVE_XDC_UNCHANGED_NO_FINAL_TIMING_BITSTREAM_OR_HARDWARE_PROOF"
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_SIGNOFF_ARCHITECTURE_ONLY_ACTIVE_XDC_UNCHANGED_NO_FINAL_TIMING_BITSTREAM_OR_HARDWARE_PROOF",
+      "acceptance_boundary_context": "HISTORICAL_PROMOTION_TIME_BOUNDARY_CURRENT_OFFLINE_CANDIDATE_ACCEPTED_BY_META8A"
+    },
+    {
+      "id": "EVID-G2B-RECOVERY4",
+      "repository": "lukaszsudul/AHD-diagnostic-evidence",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "payload_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "directory": "v41-development-g2b-lut1-signoff-recovery-4",
+      "files": [
+        "V41_G2B_LUT1_SIGNOFF_RECOVERY4_REPORT.md",
+        "G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json",
+        "G2B_LUT1_PRODUCT_CANDIDATE_PROVENANCE.md",
+        "G2B_PRE_BITSTREAM_HARD_GATE_RECOVERY4.txt",
+        "G2B_LUT1_RECOVERY4_ALL_GROUPS_MATRIX.csv",
+        "G2B_LUT1_RECOVERY4_CDC_DISPOSITION.md",
+        "G2B_LUT1_RECOVERY4_RESOURCE_SUMMARY.md",
+        "G2B_LUT1_RECOVERY4_TIMING_SUMMARY.md",
+        "G2B_LUT1_RECOVERY4_SHA256_MANIFEST.txt"
+      ],
+      "supports": [
+        "STMT-G2B-LUT1",
+        "STMT-G2B-IMPL",
+        "STMT-G2B-HW",
+        "STMT-PRODUCT-CANDIDATE",
+        "STMT-DUAL-IDENTITY",
+        "STMT-RESOURCES"
+      ],
+      "acceptance_boundary": "OWNER_ARCHITECT_ACCEPTED_EXACT_OFFLINE_PRODUCT_ONLY_HARDWARE_NOT_PROVEN_HISTORICAL_SYNTHETIC_HW0_PLAN_NOT_PROMOTED"
     }
   ],
   "groups15_17_release_slot_cdc_signoff": {
@@ -1908,11 +2086,13 @@
         },
         "cdc_structure": "PASS_WITH_DISPOSITION",
         "rtl_change_required": "NO",
-        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
         "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
         "accepted_by_role": "OWNER_ARCHITECT",
         "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
       },
       {
         "status": "ACCEPTED",
@@ -1972,11 +2152,13 @@
         },
         "cdc_structure": "PASS_WITH_DISPOSITION",
         "rtl_change_required": "NO",
-        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
         "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
         "accepted_by_role": "OWNER_ARCHITECT",
         "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
       },
       {
         "status": "ACCEPTED",
@@ -2036,11 +2218,13 @@
         },
         "cdc_structure": "PASS_WITH_DISPOSITION",
         "rtl_change_required": "NO",
-        "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
         "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
         "accepted_by_role": "OWNER_ARCHITECT",
         "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+        "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+        "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
       }
     ],
     "semantic_families_per_slot": 3,
@@ -2064,7 +2248,7 @@
     "signoff_runtime": "PRACTICAL",
     "replacement_equivalence": "SAFER_AND_MORE_SEMANTICALLY_CORRECT",
     "rtl_change_required": "NO",
-    "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+    "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
     "candidate_xdc": "G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc",
     "candidate_xdc_sha256": "BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F",
     "accepted_by_role": "OWNER_ARCHITECT",
@@ -2079,7 +2263,13 @@
       "group13": "PRESERVE_PASS",
       "group14": "PRESERVE_PASS"
     },
-    "future_signoff_recipe": [
+    "next_gate": "G2B-HW0-PRODUCT",
+    "remaining_methodology_warnings": "DISPOSITIONED_RECOVERY4_ZERO_UNRESOLVED",
+    "route_measurements_are_permanent_requirements": false,
+    "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+    "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+    "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+    "completed_offline_signoff_recipe": [
       "PRESERVE_GROUPS9_TO_14_PASS",
       "IMPLEMENT_G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS_XDC",
       "VALIDATE_NINE_SLOT_SPECIFIC_SETTLING_AND_STRUCTURAL_CDC_CHECKS",
@@ -2091,8 +2281,149 @@
       "PRE_BITSTREAM_HARD_GATE",
       "BITSTREAM_ONLY_AFTER_PASS"
     ],
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
-    "remaining_methodology_warnings": "OTHER_PRESERVED_RELATIONS_REQUIRE_FINAL_DISPOSITION_OUTSIDE_THIS_DECISION",
-    "route_measurements_are_permanent_requirements": false
+    "recipe_completion": "PASS_RECOVERY4"
+  },
+  "accepted_product_test_candidates": [
+    {
+      "name": "G2B_PRODUCT_RECOVERY4",
+      "status": "ACCEPTED",
+      "maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+      "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "repository": "lukaszsudul/FPGA_AHD",
+      "branch": "integration/v41-g2b-onech-c2h",
+      "commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "tree": "cf6bf82249c90782eab1978c68541ed9c0e6430b",
+      "source_parent": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
+      "source_worktree": "C:\\FPGA\\V41_G2B",
+      "fpga_part": "xc7a35tcsg325-2",
+      "vivado_version": "2025.2",
+      "vivado_sw_build": "6299465",
+      "profile": "PRODUCT",
+      "active_xdc_sha256": "9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE",
+      "base_routed_dcp_sha256": "EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83",
+      "signed_off_dcp_sha256": "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175",
+      "signed_off_dcp_size_bytes": 15726324,
+      "signed_off_dcp_path": "C:\\FPGA\\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\\G2B_PRODUCT_SIGNED_OFF.dcp",
+      "bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+      "bitstream_size_bytes": 2192144,
+      "bitstream_path": "C:\\FPGA\\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\\G2B_PRODUCT_RECOVERY4.bit",
+      "embedded_runtime_identity": {
+        "GIT_SHA": "224d194e5f82c85bcb29297561c5d5e76d28063b",
+        "BUILD_FLAGS": "0x00000103",
+        "kind": "MANIFEST_SEALED_UNCOMMITTED_WORKTREE",
+        "sealed_input_manifest_sha256": "0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD",
+        "note": "Original Gen12 logic fingerprint retained by constraints-only DCP reuse; current approved source identity is separately bound above."
+      },
+      "dual_identity_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_DUAL_IDENTITY_CONTRACT.md",
+      "debug_probes": "NONE_EXPECTED_PRODUCT_PROFILE",
+      "synthetic_generator": false,
+      "hardware_qualification": "NOT_PROVEN",
+      "hardware_throughput": "NOT_PROVEN",
+      "release_state": "NOT_RELEASED",
+      "replaces_r1i_hardware_baseline": false,
+      "accepted_for_gate": "G2B-HW0-PRODUCT",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
+    }
+  ],
+  "offline_product_qualification": {
+    "all_groups_1_to_17": "PASS",
+    "preserved_groups": [
+      1,
+      2,
+      3,
+      4,
+      5,
+      6,
+      7,
+      8,
+      9,
+      10,
+      11,
+      12,
+      13,
+      14
+    ],
+    "fresh_groups": [
+      15,
+      16,
+      17
+    ],
+    "route": {
+      "routable": 33985,
+      "routed": 33985,
+      "errors": 0,
+      "unrouted": 0
+    },
+    "timing": {
+      "WNS_ns": 0.023,
+      "TNS_ns": 0,
+      "WHS_ns": 0.043,
+      "THS_ns": 0
+    },
+    "DRC": {
+      "result": "PASS",
+      "errors": 0,
+      "critical_warnings": 0,
+      "warnings": 14
+    },
+    "CDC": {
+      "result": "PASS",
+      "total": 1401,
+      "critical": 427,
+      "critical_dispositioned": 427,
+      "unresolved_critical": 0,
+      "requires_rtl_change": 0,
+      "changed_representatives": 26,
+      "unchanged_endpoint_multiset": true,
+      "counts": {
+        "CDC-1": 423,
+        "CDC-3": 30,
+        "CDC-6": 13,
+        "CDC-9": 6,
+        "CDC-10": 2,
+        "CDC-13": 2,
+        "CDC-15": 925
+      },
+      "buckets": {
+        "ASYNC_ASSERT_SYNC_RELEASE_RESET": 6,
+        "FALSE_POSITIVE_WITH_PROOF": 2,
+        "TOGGLE_HANDSHAKE": 4,
+        "INTENTIONAL_TWO_STAGE_SYNCHRONIZER": 32,
+        "STABLE_DATA_WITH_SYNCHRONIZED_QUALIFIER": 1350,
+        "GRAY_CODED_CDC": 7
+      }
+    },
+    "clocks": {
+      "user_MHz": 62.5,
+      "AXI_MHz": 62.5
+    },
+    "r1i_protected_behavior": "PASS",
+    "functional_regression": "PASS",
+    "pre_bitstream_hard_gate": "PASS",
+    "offline_throughput_analysis": "PASS",
+    "hardware_throughput": "NOT_PROVEN",
+    "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
+  },
+  "g2b_diag0": {
+    "status": "BLOCKED",
+    "promotion_state": "NOT_PROMOTED",
+    "hw0_diagnostic_bitstream": "NOT_IMPLEMENTED",
+    "synthetic_generator_in_product": false,
+    "diagnostic_mmio": "NOT_PROMOTED_BY_META-8A",
+    "diagnostic_mmio_range": "0x3C00..0x3FFF",
+    "four_input_auto_scan": "NOT_QUALIFIED",
+    "blocks_fixed_input_product_test": false,
+    "source_evidence_commit": "c231e1e575295638e3bd20ef8c942fcb7fd90408",
+    "decision_source": "META-8A_TASK_DIRECTIVE"
+  },
+  "release": {
+    "name": "release/v41.0.0",
+    "creation_state": "NOT_CREATED",
+    "authorization_state": "NOT_AUTHORIZED",
+    "release_state": "NOT_RELEASED",
+    "hardware_and_stability_gates_required": true
   }
 }
--- a/project-current-state/README.md
+++ b/project-current-state/README.md
@@ -12,14 +12,14 @@
 | Field | Value |
 |---|---|
 | Project | `AHD_v41` |
-| `PROJECT_STATE_REV` | `7` |
+| `PROJECT_STATE_REV` | `8` |
 | Governance version | `1` |
 | State type | `CURRENT_ACCEPTED_STATE` |
 | Last update | `2026-09-05` |
 | Acceptance authority | `OWNER_ARCHITECT` |
 | SSOT writer | `META_UPDATE_AGENT_ONLY` |
 | Creation authorization | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` |
-| Revision-7 decision basis | Accepted combined G15–17 release-slot sign-off architecture; Groups 9–14 PASS preserved |
+| Revision-8 decision basis | Exact offline PRODUCT candidate accepted; separate HW0-PRODUCT planned |
 
 ## Mandatory read before any work
 
@@ -41,25 +41,25 @@
 
 | Area | Current project truth |
 |---|---|
-| Product | G2B-PRE and G2B-LUT0 `ACCEPTED`; G2B-IMPL remains `BLOCKED`; G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; G2B-HW `BLOCKED` |
+| Product | G2B-LUT1 `ACCEPTED`; `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`; G2B-HW `PLANNED / NOT_PROVEN` |
 | Research | R-track state `HOLD`, not closed; R2/R3 remain resumable |
 | Linux Video | L0 `PLANNED` |
-| META | META-7R promotes Groups 15–17; Groups 9–14 decisions and PASS preserved; no RTL or active-XDC implementation |
+| META | META-8A accepts the exact offline candidate and defines separate controlled hardware scope |
 | Qualified FPGA baseline | R1i `ACCEPTED`; preservation identity `FROZEN` |
 | PCIe product requirement | Gen2 x1 or better; sustained payload `>= 288 MB/s` per card |
 | Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, `FROZEN_FOR_G2B` |
 | G2B MMIO | `FROZEN`, `0x3800..0x3BFF` |
-| Build profiles | `PRODUCT` and `RESEARCH_DIAGNOSTIC`: `AUTHORIZED_NOT_IMPLEMENTED` |
-| PRODUCT LUT policy | hard gate `<= 90%`; preferred target `80–85%`; target not yet measured or achieved |
+| Build profiles | PRODUCT offline-qualified; RESEARCH_DIAGNOSTIC post-G2B qualification not promoted |
+| PRODUCT LUT policy | <=90% gate and 80–85% preferred target achieved offline: 83.490% |
 | Group-9 ownership sign-off | `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` promoted; `GLOBAL_SET_BUS_SKEW_3NS` retired from required sign-off |
 | Group-9 timing basis | 3 families (`slot`, `generation`, `epoch`); `6.000 ns` settling cap; `13.468 ns` minimum launch-to-use; `7.468 ns` gross reserve |
 | Group-13 reset-return sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off |
 | Group-13 timing basis | 2 families (`RESET_ABANDONED_COUNT_STABLE_PAYLOAD`, `RESET_COMMIT_PHASE_COMPLETION_BARRIER`); `6.000 ns` absolute settling cap; unchanged broad aggregate `6.000 ns` relation retained |
 | Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` promoted; global `GLOBAL_SET_BUS_SKEW_3NS` / `report_bus_skew` retired from required sign-off for the historical 56-source/20-destination scope |
 | Group-14 timing basis | 3 families (`RELEASE_SLOT0_NORMAL_STATE_TRANSITION`, `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`); `6.000 ns` absolute settling cap for each family |
-| G2B implementation | G2B-LUT1 readiness `READY_FOR_SIGNOFF_RECOVERY`; next gate `G2B-LUT1-SIGNOFF-RECOVERY-4` |
-| Active XDC change | Groups 15–17 `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; candidate `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` |
-| G2B hardware qualification | lifecycle `BLOCKED`; `NOT_STARTED`; `NOT_PROVEN` |
+| G2B implementation | Exact PRODUCT accepted offline; next gate `G2B-HW0-PRODUCT` |
+| Active XDC change | Groups 15–17 implemented and signed off by Recovery-4; META-8A edits no XDC |
+| G2B hardware qualification | `PLANNED`; `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`; NOT_STARTED / NOT_PROVEN |
 | Linux consumer contract | Frozen transport input; V4L2 remains `NOT_IMPLEMENTED` |
 
 META-4R2 Group-9 and META-5 Group-13 truth remain promoted without regression.
@@ -74,9 +74,9 @@
 `GROUPS_15_TO_17 = PROMOTED`. The retired global Group-9, Group-13,
 and Group-14 `report_bus_skew` queries are not required again. The estimated
 `PRODUCT` result of 17,512 LUT (84.192%) is still not qualification evidence.
-No profile source implementation, active XDC change, final routed sign-off,
-G2B bitstream, hardware capture, V4L2 implementation, Gen2 qualification, or
-288 MB/s result is claimed. The R-track is on `HOLD`, not closed, cancelled,
+Recovery-4 supplies the accepted exact PRODUCT source, active-XDC
+implementation, final routed sign-off and bitstream. Hardware capture, V4L2,
+Gen2 hardware qualification and measured 288 MB/s remain unproven. The R-track is on `HOLD`, not closed, cancelled,
 or superseded.
 
 ## META-7R combined release-slot promotion
@@ -91,36 +91,12 @@
 `RETIRED_FROM_REQUIRED_SIGNOFF`. See the complete family and structural
 requirements in `CURRENT_ARCHITECTURE.md` and `CURRENT_REQUIREMENTS.md`.
 
-`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups
-15–17. Candidate authority: `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` in
-`v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
-`RTL_CHANGE_REQUIRED = NO`; `SLOT1_RTL_CHANGE_REQUIRED = NO`,
-`SLOT2_RTL_CHANGE_REQUIRED = NO`, and `SLOT3_RTL_CHANGE_REQUIRED = NO`.
+Groups 1–17 are `PASS` at Recovery-4: Groups 1–14 retain hash-bound preserved PASS and Groups 15–17 have nine fresh independent PASS checks. All promoted Group-9 and Groups 13–17 methods, family collections, structural safety invariants and absolute `6.000 ns` bounds remain authoritative; no retired global query is reinstated.
 
-`GROUP9 = PRESERVE_PASS`; `GROUPS_10_TO_12 = PRESERVE_PASS`;
-`GROUP13 = PRESERVE_PASS`; `GROUP14 = PRESERVE_PASS`. Their methods, bounds,
-promotion evidence and promotion-time active-XDC dispositions are preserved.
-The Group-14 pending-XDC statements at META-6 are historical promotion-time
-boundaries; the authoritative audit now preserves its PASS. They do not
-instruct recovery-4 to reimplement Group 14.
+Groups 15–17 active-XDC implementation is complete in source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`; active XDC SHA-256 `9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE`. META-8A changes no source or XDC.
 
-`G2B-LUT1 = READY_FOR_SIGNOFF_RECOVERY`;
-`NEXT_ALLOWED_ENGINEERING_STEP = G2B-LUT1-SIGNOFF-RECOVERY-4`. That separate governed task uses
-`C:\FPGA\V41_G2B`, branch `integration/v41-g2b-onech-c2h`, current source
-commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree
-`e18833d46f7672f851c3cb8239f2f29091378294`. It may replace only the three retired
-global Groups 15–17 bus-skew constraints with the nine candidate checks,
-preserving every unrelated active constraint and Groups 9–14 PASS. It must
-validate all nine checks, then continue final routed timing, DRC, CDC
-disposition, clocks, PRODUCT resources and the pre-bitstream hard gate.
-Bitstream generation is a later engineering action allowed only after those
-gates pass; it is not performed or claimed by META-7R.
+Route `PASS`: 33985/33985 nets, zero unrouted. Final timing `PASS`: WNS `+0.023 ns`, TNS `0.000 ns`, WHS `+0.043 ns`, THS `0.000 ns`. DRC `PASS`: zero errors and zero critical warnings; ordinary warnings remain dispositioned. CDC `PASS`: 1401 findings dispositioned, including all 427 critical findings; unresolved critical zero. Clocks `PASS`: user and AXI `62.500 MHz`. PRODUCT LUT `17366/20800 (83.490%)`, FF `19314/41600 (46.428%)`, BRAM `26.5/50 (53.000%)`, DSP `0/90 (0.000%)`. PRODUCT LUT <=90%, R1i protected behavior, G2B functional regression and pre-bitstream hard gate: `PASS`. These are accepted offline facts, not hardware measurements.
 
-`G2B-HW = BLOCKED`: Groups 15–17 active-XDC replacement is not implemented;
-final timing, DRC, CDC, clocks/resources and the pre-bitstream gate are not
-complete; no G2B bitstream exists and hardware has not been tested. No final
-timing sign-off, qualification, release, hardware readiness, DMA operation,
-or hardware proof is promoted.
 
 ## Truth model
 
@@ -173,3 +149,28 @@
 Owner/Architect decision, an accepted evidence source, and the expected prior
 `PROJECT_STATE_REV`. If any condition is absent, the agent must stop without
 writing.
+
+## Accepted offline G2B PRODUCT test candidate — META-8A
+
+G2B-LUT1: `ACCEPTED`; engineering `PASS`; maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`. Accepted gate and `LAST_ACCEPTED_GATE`: `G2B-LUT1-SIGNOFF-RECOVERY-4`. `NEXT_ALLOWED_ENGINEERING_STEP`: `G2B-HW0-PRODUCT`. Acceptance is exclusively for controlled hardware evaluation; hardware qualification `NOT_PROVEN`; release state `NOT_RELEASED`.
+
+| Candidate binding | Exact value |
+|---|---|
+| Repository / branch | `lukaszsudul/FPGA_AHD` / `integration/v41-g2b-onech-c2h` |
+| Source commit | `92e9b3d914134c044371779def1ee18eaaeda98a` |
+| Source tree | `cf6bf82249c90782eab1978c68541ed9c0e6430b` |
+| Signed-off DCP SHA-256 | `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175` |
+| PRODUCT bitstream / bytes | `G2B_PRODUCT_RECOVERY4.bit` / `2192144` |
+| PRODUCT bitstream SHA-256 | `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7` |
+| Evidence commit / directory | `6843d582fd367fbc0edc0b1d55a9617162c489b0` / `v41-development-g2b-lut1-signoff-recovery-4` |
+| Runtime embedded GIT_SHA | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
+| Runtime BUILD_FLAGS | `0x00000103` |
+| Sealed input manifest SHA-256 | `0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD` |
+
+The older embedded GIT_SHA is expected and does not constitute a runtime identity failure when all other candidate bindings match. Constraints-only recovery retains the routed logic fingerprint; the future HW0 task must verify both identity layers.
+
+R1i remains the `ACCEPTED` and `FROZEN` hardware-qualified PoC baseline. This accepted offline test candidate does not replace R1i as a hardware baseline.
+
+G2B-HW / G2B-HW0-PRODUCT: lifecycle `PLANNED`, readiness `AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, progress `NOT_STARTED`, qualification `NOT_PROVEN`. Initial scope: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`. No hardware operation occurred in META-8A. The separate prompt must establish fresh DUT exclusivity and exact operational authority. Future gate: [META8A_HW0_PRODUCT_GATE_CONTRACT.md](../v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md).
+
+Offline >=288 MB/s analysis `PASS`; hardware throughput and PCIe Gen2 qualification `NOT_PROVEN`. One live 1080p25 stream is insufficient to prove 288 MB/s. Synthetic generator in PRODUCT: `NO`. G2B-DIAG0: `BLOCKED / NOT_PROMOTED`; HW0_DIAGNOSTIC bitstream: `NOT_IMPLEMENTED`; diagnostic MMIO `0x3C00..0x3FFF`: `NOT_PROMOTED_BY_META-8A`. Four-input selection/auto-scan and two-channel capture remain unqualified. V4L2: `PLANNED_FOR_LATER_STAGE`, not required for HW0. `release/v41.0.0`: `NOT_CREATED`, `NOT_AUTHORIZED`, `NOT_RELEASED`; persistent Flash programming is not authorized.
--- a/project-current-state/SHA256_MANIFEST.txt
+++ b/project-current-state/SHA256_MANIFEST.txt
@@ -1,18 +1,18 @@
-E25125DB6866D306C7930C197459B6736DB1FF70FB18F1BD91F5D9EA7D1414FD  ACTIVE_BASELINES.md
-682B1F9648B44D87A3BF812706624BBA68540158159EB6E7EDC321C2B164B2E7  CHANGELOG.md
-76D429FBB9C28589079E38817A96657FAB4DC64CDA47FE6B09BBEC9A30864058  COMPATIBILITY_MATRIX.csv
-55F3C765BB7B7BDF8C4BBD1038F322B44480EA14529E2222E424CEC83DDA0549  CURRENT_ARCHITECTURE.md
-FB391086FB448AFBFF0DC8766BF4FF9C7C89941B02F9A3C9D97ECBCA6219B72C  CURRENT_INTERFACES.md
-BC4820B32BB83E73F4879916AB42FCCEA1D84939833441D34190CDBFC1DB2684  CURRENT_REQUIREMENTS.md
-271F53443B3F063BD1505BFBBD4FB95FB40B0ADED2A8F86DEB8BAA3D64368B0B  CURRENT_RESOURCE_STATE.md
-BB3CF28F8E2AB06B8532838D6FAA2DE6408CBA0E10DACFDDCBE4516EDEC23164  CURRENT_STATUS.md
-5CB9898C95BD2E0BE7C137E147D5B0DFAA43DF6A76D4CDBF55E85F22F369A723  CURRENT_TRACKS.md
-20C5E803E922B9056F40849EAE7A41F40DE14D97FD4BF089E5DF81B5BF8259F4  EVIDENCE_MAP.md
-BEA6E809FD76C2D08DCE30B507A58CE1E1F8B88C851B8D9D20E18D381A9E5474  GOVERNANCE.md
+42DB7FA4FA660848574877A4ED3FCC393E9378043638174BC5C6D8742A736497  ACTIVE_BASELINES.md
+917C4967E8E899632486791F40C0CB20AB4198EC7F91F0148AD9F80AD5B74662  CHANGELOG.md
+4BE2FACBEC64760F1BFBF56F5D79E294F16ACD5C19C3376EFB6A99C9C8AC87F2  COMPATIBILITY_MATRIX.csv
+F918841D34061594A65EE7DBCDBA23F58A1090AD90322F330EEBF4E3439B0350  CURRENT_ARCHITECTURE.md
+94F11689011260F85349D01B61A4754343FEA8804D6699F6634B76D77A0FE8E8  CURRENT_INTERFACES.md
+2B5CC65328129A123829A96D1EAA161B2A2D4A443A6D30D6BF4D1A9B9C646627  CURRENT_REQUIREMENTS.md
+E1FD2BA9D02714EF3966A3075EAA65A759EA146A67A7C9F68D5AB6417239AF11  CURRENT_RESOURCE_STATE.md
+E9EDED945386B59B5CD0F695621A47778FC6A3CC1A64D44B2553A4673ADE7C83  CURRENT_STATUS.md
+52AB4EC0E234346B6C524B561FA8C4CEA3C37B1ABDD3328568D0F89F4609B1B3  CURRENT_TRACKS.md
+412E98C2B2F700034AD4542F61608D12D4A1AE0737B5290026E020461AF24788  EVIDENCE_MAP.md
+A5E4782C9C60FFF845D7EAFC8B040739D4FE91EED31E5FEC01B580BD8A39A958  GOVERNANCE.md
 F7119369043E5C348AAA4B14BC4A3BBB80FB6AC6E0343BAA904909A2C22D0B27  META_UPDATE_TEMPLATE.md
-1A0E2F255A156A947E09880DD7FEED8F3A60489E5FC952C17D948871428C3950  OPEN_DECISIONS.md
-B800B561863202A34DA87EE6273F15F65FE1A4A716CDA82AEAC825C3A6AA872E  PROJECT_STATE.json
-CDB53488D8F4BCA0BFF933F7593CB1CE5DC61548101E643F00EE717E567243C9  README.md
+57EC4A78C5214194D0642903BCD2C396BCD213C0DA124D826FA896DAE420A964  OPEN_DECISIONS.md
+9FEE5B8A2F9E2F0CB8D4CA730B087DA448E329524085FEBD1FF42CC41D0AD4AF  PROJECT_STATE.json
+849ABF1C39CDCE93510F05B4A4FE691577DABF68584D852AA72B07DACCD52B12  README.md
 6AE9C691748CE9FEF5186083DE50BF9F93EAF5E9AFEBDCB0156A7CDE650B60E3  STATE_SCHEMA.md
-92A6721670C214B5A178F309518B421412BA60974DA71BD85F6A7502BDBE2144  TRACK_STATUS.json
+675BC71817D2C955BC296330D21EA846E227016BE0DCAE0BA38E61628F761C58  TRACK_STATUS.json
 F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497  UPDATE_POLICY.md
--- a/project-current-state/TRACK_STATUS.json
+++ b/project-current-state/TRACK_STATUS.json
@@ -1,24 +1,24 @@
 {
   "project": "AHD_v41",
-  "project_state_revision": 7,
+  "project_state_revision": 8,
   "state_type": "CURRENT_TRACK_STATUS",
   "governance_version": 1,
   "last_update": "2026-09-05",
   "accepted_by_role": "OWNER_ARCHITECT",
-  "acceptance_authorization": "META-7R_TASK_DIRECTIVE",
+  "acceptance_authorization": "META-8A_TASK_DIRECTIVE",
   "ssot_write_authorization": "SSOT WRITE AUTHORIZED",
-  "update_type": "ARCHITECTURE_CHANGE",
+  "update_type": "TRACK_GATE_ACCEPTANCE",
   "source_evidence_repository": "lukaszsudul/AHD-diagnostic-evidence",
-  "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-  "source_evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
-  "expected_previous_project_state_revision": 6,
-  "write_contract_receipt": "v41-meta-project-state-rev7-groups15-17-release-slot-signoff/META7_FROZEN_WRITE_CONTRACT_RECEIPT.md",
+  "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+  "source_evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+  "expected_previous_project_state_revision": 7,
+  "write_contract_receipt": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_WRITE_CONTRACT_RECEIPT.md",
   "product_track": {
     "status": "ACTIVE",
-    "last_accepted_gate": "G2B-LUT0",
+    "last_accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
     "active_gate": "G2A",
-    "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
-    "resource_recovery_state": "PLAN_ACCEPTED_IMPLEMENTATION_PENDING",
+    "next_gate": "G2B-HW0-PRODUCT",
+    "resource_recovery_state": "PRODUCT_OFFLINE_QUALIFIED",
     "gates": [
       {
         "gate": "G-1",
@@ -65,17 +65,23 @@
       },
       {
         "gate": "G2B-IMPL",
-        "status": "BLOCKED",
-        "accepted_by_role": null,
-        "readiness": "READY_FOR_SIGNOFF_RECOVERY",
-        "implementation_state": "ROUTED_IMPLEMENTATION_SIGNOFF_RECOVERY_PENDING",
-        "blocking_reason": "GROUPS15_TO_17_CANDIDATE_XDC_IMPLEMENTATION_AND_FINAL_OFFLINE_SIGNOFF_PENDING",
-        "offline_qualification": "NOT_ACCEPTED",
+        "status": "ACCEPTED",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "readiness": "OFFLINE_QUALIFIED",
+        "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED",
+        "offline_qualification": "ACCEPTED",
         "hardware_qualification_progress": "NOT_STARTED",
         "hardware_qualification": "NOT_PROVEN",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-        "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit",
-        "decision_source": "META-7R_TASK_DIRECTIVE"
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "engineering_gate": "PASS",
+        "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+        "offline_qualification_state": "ACCEPTED",
+        "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+        "release_state": "NOT_RELEASED",
+        "scope": "EXACT_PRODUCT_ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "next_gate": "G2B-HW0-PRODUCT"
       },
       {
         "gate": "G2B-LUT0",
@@ -89,10 +95,10 @@
       },
       {
         "gate": "G2B-LUT1",
-        "status": "PLANNED",
-        "readiness": "READY_FOR_SIGNOFF_RECOVERY",
-        "scope": "PRESERVE_GROUPS9_TO_14_PASS_APPLY_PROMOTED_GROUPS15_TO_17_AND_COMPLETE_ROUTED_SIGNOFF",
-        "implementation_state": "SIGNOFF_RECOVERY_PENDING",
+        "status": "ACCEPTED",
+        "readiness": "OFFLINE_QUALIFIED",
+        "scope": "EXACT_PRODUCT_ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "implementation_state": "IMPLEMENTED_OFFLINE_QUALIFIED",
         "preserved_authoritative_results": [
           "GROUP9",
           "GROUP10",
@@ -102,22 +108,53 @@
           "GROUP14"
         ],
         "accepted_by_role": "OWNER_ARCHITECT",
-        "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-        "depends_on": "META7_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
-        "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "depends_on": "RECOVERY4_EXACT_CANDIDATE_AND_META8A_ACCEPTANCE",
+        "next_gate": "G2B-HW0-PRODUCT",
+        "engineering_gate": "PASS",
+        "qualification_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+        "offline_qualification_state": "ACCEPTED",
+        "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+        "hardware_qualification": "NOT_PROVEN",
+        "release_state": "NOT_RELEASED",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
       },
       {
         "gate": "G2B-HW",
-        "status": "BLOCKED",
+        "status": "PLANNED",
         "progress": "NOT_STARTED",
         "qualification_state": "NOT_PROVEN",
-        "blocking_reason": "GROUPS15_TO_17_CANDIDATE_IMPLEMENTATION_FINAL_OFFLINE_SIGNOFF_PRE_BITSTREAM_GATE_AND_BITSTREAM_CANDIDATE_NOT_AVAILABLE",
-        "bitstream_candidate": "NOT_AVAILABLE",
-        "accepted_by_role": "OWNER_ARCHITECT",
-        "decision_source": "META-7R_TASK_DIRECTIVE",
-        "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
-        "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit"
+        "blocking_reason": null,
+        "bitstream_candidate": "AVAILABLE_EXACT_OFFLINE_QUALIFIED_PRODUCT",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4",
+        "readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
+        "scope": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "next_gate": "G2B-HW0-PRODUCT",
+        "hardware_evidence_present": false,
+        "execution_requires_fresh_operational_authorization": true,
+        "gate_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md"
+      },
+      {
+        "gate": "G2B-HW0-PRODUCT",
+        "status": "PLANNED",
+        "readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
+        "progress": "NOT_STARTED",
+        "qualification_state": "NOT_PROVEN",
+        "blocking_reason": null,
+        "bitstream_candidate": "AVAILABLE_EXACT_OFFLINE_QUALIFIED_PRODUCT",
+        "scope": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
+        "next_gate": "G2B-HW0-PRODUCT",
+        "hardware_evidence_present": false,
+        "execution_requires_fresh_operational_authorization": true,
+        "gate_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_HW0_PRODUCT_GATE_CONTRACT.md",
+        "accepted_by_role": "OWNER_ARCHITECT",
+        "decision_source": "META-8A_TASK_DIRECTIVE",
+        "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+        "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
       }
     ],
     "group9_ownership_signoff": {
@@ -183,7 +220,8 @@
       "evidence_directory": "v41-development-g2b-g13a-reset-return-signoff-audit",
       "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
       "reexecution": "DO_NOT_REPEAT",
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
+      "next_gate": "G2B-HW0-PRODUCT",
+      "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
     },
     "group14_release_slot_signoff": {
       "status": "ACCEPTED",
@@ -267,10 +305,11 @@
       "decision_source": "META-6_TASK_DIRECTIVE",
       "source_evidence_commit": "9e91315968453e859006077191cd5fc711fc6b96",
       "evidence_directory": "v41-development-g2b-g14a-release-slot0-signoff-audit",
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "next_gate": "G2B-HW0-PRODUCT",
       "active_xdc_change_context": "HISTORICAL_META6_PROMOTION_TIME_BOUNDARY_CURRENT_GROUP14_PASS_PRESERVED",
       "authoritative_result": "PASS_PRESERVED_DO_NOT_REPEAT",
-      "reexecution": "DO_NOT_REPEAT"
+      "reexecution": "DO_NOT_REPEAT",
+      "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4"
     },
     "groups15_17_release_slot_signoff": {
       "status": "ACCEPTED",
@@ -338,11 +377,13 @@
           },
           "cdc_structure": "PASS_WITH_DISPOSITION",
           "rtl_change_required": "NO",
-          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
           "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
           "accepted_by_role": "OWNER_ARCHITECT",
           "decision_source": "META-7R_TASK_DIRECTIVE",
-          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+          "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
         },
         {
           "status": "ACCEPTED",
@@ -402,11 +443,13 @@
           },
           "cdc_structure": "PASS_WITH_DISPOSITION",
           "rtl_change_required": "NO",
-          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
           "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
           "accepted_by_role": "OWNER_ARCHITECT",
           "decision_source": "META-7R_TASK_DIRECTIVE",
-          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+          "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
         },
         {
           "status": "ACCEPTED",
@@ -466,11 +509,13 @@
           },
           "cdc_structure": "PASS_WITH_DISPOSITION",
           "rtl_change_required": "NO",
-          "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
           "global_report_bus_skew": "RETIRED_FROM_REQUIRED_SIGNOFF",
           "accepted_by_role": "OWNER_ARCHITECT",
           "decision_source": "META-7R_TASK_DIRECTIVE",
-          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+          "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
+          "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+          "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0"
         }
       ],
       "semantic_families_per_slot": 3,
@@ -494,7 +539,7 @@
       "signoff_runtime": "PRACTICAL",
       "replacement_equivalence": "SAFER_AND_MORE_SEMANTICALLY_CORRECT",
       "rtl_change_required": "NO",
-      "active_xdc_change": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "active_xdc_change": "IMPLEMENTED_AND_SIGNED_OFF_RECOVERY4",
       "candidate_xdc": "G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc",
       "candidate_xdc_sha256": "BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F",
       "accepted_by_role": "OWNER_ARCHITECT",
@@ -509,7 +554,13 @@
         "group13": "PRESERVE_PASS",
         "group14": "PRESERVE_PASS"
       },
-      "future_signoff_recipe": [
+      "next_gate": "G2B-HW0-PRODUCT",
+      "remaining_methodology_warnings": "DISPOSITIONED_RECOVERY4_ZERO_UNRESOLVED",
+      "route_measurements_are_permanent_requirements": false,
+      "active_xdc_change_at_promotion": "AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED",
+      "qualification_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "completed_offline_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "completed_offline_signoff_recipe": [
         "PRESERVE_GROUPS9_TO_14_PASS",
         "IMPLEMENT_G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS_XDC",
         "VALIDATE_NINE_SLOT_SPECIFIC_SETTLING_AND_STRUCTURAL_CDC_CHECKS",
@@ -521,16 +572,59 @@
         "PRE_BITSTREAM_HARD_GATE",
         "BITSTREAM_ONLY_AFTER_PASS"
       ],
-      "next_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
-      "remaining_methodology_warnings": "OTHER_PRESERVED_RELATIONS_REQUIRE_FINAL_DISPOSITION_OUTSIDE_THIS_DECISION",
-      "route_measurements_are_permanent_requirements": false
+      "recipe_completion": "PASS_RECOVERY4"
     },
     "next_engineering_source": {
       "worktree": "C:\\FPGA\\V41_G2B",
+      "repository": "lukaszsudul/FPGA_AHD",
       "branch": "integration/v41-g2b-onech-c2h",
-      "commit": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
-      "tree": "e18833d46f7672f851c3cb8239f2f29091378294",
-      "scope": "AUTHORITATIVE_RECOVERY4_INPUT_NOT_QUALIFIED_BASELINE"
+      "commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "tree": "cf6bf82249c90782eab1978c68541ed9c0e6430b",
+      "scope": "ACCEPTED_OFFLINE_PRODUCT_CANDIDATE_NOT_HARDWARE_BASELINE"
+    },
+    "next_allowed_engineering_step": "G2B-HW0-PRODUCT",
+    "accepted_product_test_candidate": {
+      "name": "G2B_PRODUCT_RECOVERY4",
+      "status": "ACCEPTED",
+      "maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
+      "accepted_gate": "G2B-LUT1-SIGNOFF-RECOVERY-4",
+      "repository": "lukaszsudul/FPGA_AHD",
+      "branch": "integration/v41-g2b-onech-c2h",
+      "commit": "92e9b3d914134c044371779def1ee18eaaeda98a",
+      "tree": "cf6bf82249c90782eab1978c68541ed9c0e6430b",
+      "source_parent": "bdae16e06fb5b8564763941f530e4ce9e28896c7",
+      "source_worktree": "C:\\FPGA\\V41_G2B",
+      "fpga_part": "xc7a35tcsg325-2",
+      "vivado_version": "2025.2",
+      "vivado_sw_build": "6299465",
+      "profile": "PRODUCT",
+      "active_xdc_sha256": "9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE",
+      "base_routed_dcp_sha256": "EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83",
+      "signed_off_dcp_sha256": "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175",
+      "signed_off_dcp_size_bytes": 15726324,
+      "signed_off_dcp_path": "C:\\FPGA\\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\\G2B_PRODUCT_SIGNED_OFF.dcp",
+      "bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
+      "bitstream_size_bytes": 2192144,
+      "bitstream_path": "C:\\FPGA\\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\\G2B_PRODUCT_RECOVERY4.bit",
+      "embedded_runtime_identity": {
+        "GIT_SHA": "224d194e5f82c85bcb29297561c5d5e76d28063b",
+        "BUILD_FLAGS": "0x00000103",
+        "kind": "MANIFEST_SEALED_UNCOMMITTED_WORKTREE",
+        "sealed_input_manifest_sha256": "0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD",
+        "note": "Original Gen12 logic fingerprint retained by constraints-only DCP reuse; current approved source identity is separately bound above."
+      },
+      "dual_identity_contract": "v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization/META8A_DUAL_IDENTITY_CONTRACT.md",
+      "debug_probes": "NONE_EXPECTED_PRODUCT_PROFILE",
+      "synthetic_generator": false,
+      "hardware_qualification": "NOT_PROVEN",
+      "hardware_throughput": "NOT_PROVEN",
+      "release_state": "NOT_RELEASED",
+      "replaces_r1i_hardware_baseline": false,
+      "accepted_for_gate": "G2B-HW0-PRODUCT",
+      "accepted_by_role": "OWNER_ARCHITECT",
+      "decision_source": "META-8A_TASK_DIRECTIVE",
+      "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+      "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
     }
   },
   "research_track": {
@@ -610,13 +704,14 @@
   },
   "meta_track": {
     "status": "ACCEPTED",
-    "current_task": "META-7R",
+    "current_task": "META-8A",
     "active_gate": null,
     "next_gate": null,
-    "acceptance_basis": "OWNER_ARCHITECT_PROMOTED_COMBINED_GROUPS15_TO_17_RELEASE_SLOT_SIGNOFF_METHODS",
+    "acceptance_basis": "EXACT_OFFLINE_PRODUCT_CANDIDATE_ACCEPTED_AND_SEPARATE_CONTROLLED_HW0_SCOPE_AUTHORIZED",
     "accepted_by_role": "OWNER_ARCHITECT",
-    "decision_source": "META-7R_TASK_DIRECTIVE",
-    "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c"
+    "decision_source": "META-8A_TASK_DIRECTIVE",
+    "source_evidence_commit": "6843d582fd367fbc0edc0b1d55a9617162c489b0",
+    "evidence_directory": "v41-development-g2b-lut1-signoff-recovery-4"
   },
   "reporting_requirements": {
     "record_project_state_rev_at_start": true,
```
