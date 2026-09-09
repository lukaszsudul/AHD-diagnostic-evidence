# Fresh diagnostic build report

- Vivado: 2025.2 build 6299465
- Mode: fresh nonincremental; no checkpoint reuse
- Source commit/tree: `bed970032dd4acdfbb2cf254f3e21ebcfb60c6f1` / `a0dacf5d727cf051bfb1725136e394ae43317605`
- Profile: `NVP_VIDEO_DIAGNOSTIC`
- BUILD_FLAGS: `0x00000402`
- Project/IP generation: PASS
- Synthesis: PASS (0 errors, 0 critical warnings)
- Optimization: PASS
- Post-opt resource gate: FAIL
- Placement/routing/sign-off/bitstream: NOT_RUN

Exact blocker: `BLOCKED - RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: LUT_GT_98_PERCENT`.

Task classification uses engineering FAIL because the executed resource property was disproven; the tool's literal blocker text is preserved as evidence.
