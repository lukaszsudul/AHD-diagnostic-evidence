# Future full-rebuild sign-off gate

Scope: DIAG0 offline architecture proposal; no implementation or hardware qualification. Normative decisions apply to the future HW0_DIAGNOSTIC profile. Engineering gate is BLOCKED by the explicitly identified NVP evidence gaps; publication does not promote SSOT.


FULL_REBUILD_REQUIRED=YES. Only derivative source may change in future DIAG1. Do not reuse the routed PRODUCT DCP as a diagnostic implementation result. Resolve B1/B2 before declaring universal-image acceptance; partial synthetic implementation cannot satisfy the three-mode gate.

Run synthesis -> opt -> place -> phys_opt -> route -> timing -> methodology -> DRC -> CDC -> resources -> pre-bitstream hard gate -> bitstream. Bitstream only after all preceding checks pass; artifacts bind one committed clean source,tree,profile,tool version and generated identities. PRODUCT DCP/bitstream remain immutable references.

Offline requirements: all RTL/unit simulations PASS;host golden models PASS;all three modes elaborated;mutually exclusive producers;runtime source switches with stalled output and absent/reappearing NVP clock PASS;frame1,2,1000,0 continuous and invalid1001 tests;record1,finite,ffffffff boundary-model and0 continuous tests;scan preference/order/mask and all absent/unsupported/stale status cases;STOP/RESCAN and count retention;finite/infinite scheduler,time/count tie,pause0 and stop in pause;graceful stop/abort at every beat/stall phase;AXI TKEEP/TLAST/stability;pattern vectors/endianness/PRBS seed/reseed;coherent64-bit snapshots beyond4GB;ABI unchanged;MMIO CSV/JSON/RTL/host constants agree;legacy routing/access semantics outside diagnostic block unchanged;R1i pre-init behavior unchanged;no black boxes.

Implementation requirements:timing setup/hold PASS with correct62.5MHz constraints;DRC errors0,critical warnings0;CDC disposition PASS with every modified crossing independently reviewed;methodology dispositions approved;LUT<=20384 (98%);all resource limits legal;zero unresolved identity or enabled-capability gaps;diagnostic bitstream produced only in DIAG1. Common formatter extraction must revalidate every live ownership proof endpoint and constrain new paths; do not assume unchanged source code means unchanged routed CDC endpoints.

Hardware T0..L6 follow later and are separate from offline sign-off. No measured-throughput or live four-input qualification claim follows from this gate document.
