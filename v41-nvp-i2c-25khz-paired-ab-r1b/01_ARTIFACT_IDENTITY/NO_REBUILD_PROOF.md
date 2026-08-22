# No-build and no-source-change proof

R1b consumes the already sealed R1 bit by its exact filename, size, and
SHA-256. No DCP is opened, no bit is exported, and no FPGA repository is
written.

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
DIAGNOSTIC_BUILD_REUSED=YES_EXACT_ARTIFACT
```

