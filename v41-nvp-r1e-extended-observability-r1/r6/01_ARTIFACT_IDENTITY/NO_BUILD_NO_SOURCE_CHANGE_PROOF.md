# R6 no-build and no-source-change proof

```text
FULL_BUILDS_THIS_TASK=0
SYNTHESIS_RUNS_THIS_TASK=0
IMPLEMENTATION_RUNS_THIS_TASK=0
BITSTREAMS_GENERATED_THIS_TASK=0
FPGA_SOURCE_CHANGES_THIS_TASK=0
DCP_MUTATIONS_THIS_TASK=0
FORMAL_REPOSITORY_MUTATIONS=0
BITSTREAM_ARTIFACT_COPIES_CREATED=2_EXACT_HASH_VERIFIED
```

P0 used filesystem hashing and read-only Git object queries only. It did not
invoke Vivado, alter either repository, or generate a replacement bitstream.
