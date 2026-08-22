# No-build and no-source-change proof

R1c reuses the already-built diagnostic bit and exact formal control bit. The diagnostic source worktree was inspected read-only and was clean at the exact accepted source identity.

```text
DIAGNOSTIC_BUILD_REUSED=YES_EXACT_ARTIFACT
DIAGNOSTIC_SOURCE_COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4
DIAGNOSTIC_SOURCE_TREE=b8f87966c8021396acb6341bd2d7d86a10fd7f13
DIAGNOSTIC_BRANCH=diag/v41-nvp-i2c-25khz-r1
DIAGNOSTIC_WORKTREE_STATUS_COUNT=0
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
```
