# R1h combined pre-commit memory-inference report

## Identity and scope

- Exact parent: `e112a5addb7ac62700a9a71af81bf368fad0bada`
- Candidate state: authorized, uncommitted R1h worktree
- Part: `xc7a35tcsg325-2`
- Vivado: `2025.2`, SW build `6299465`
- Logger SHA-256: `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761`
- Index-store SHA-256: `67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F`
- Verification-top SHA-256: `7B77B07339ADA100B43348316877EF6CCB1C636DFF8671DCCAA6C6045E1A6B82`

This was one bounded out-of-context `synth_design` memory-inference check. It
was not the authorized full clean build and invoked no `opt_design`,
`place_design`, `route_design`, checkpoint write or bitstream write.

## Netlist-derived result

The final synthesis mapping report identifies exactly:

```text
six  64 x 32 simple-dual-port memories -> six RAMB18E1
three 512 x 16 simple-dual-port memories -> three RAMB18E1
RAMB36E1                                      0
failed-record RAM64M                         0
failed-record RAMD64E                        0
```

The post-synthesis primitive inventory is:

```text
FAILED_RECORD_RAMB18=6
FAILED_RECORD_RAMB36=0
FAILED_RECORD_RAM64M=0
FAILED_RECORD_RAMD64E=0
FAILED_RECORD_HIERARCHY_FDRE=81
PROBE_INDEX_RAMB18=3
PROBE_INDEX_RAMB36=0
PROBE_INDEX_HIERARCHY_FDRE=3
MEMORY_INFERENCE_GATE=PASS
```

The logger hierarchy's 81 FDREs are metadata, counters and read-control state;
the 12,288-bit payload is in the six RAMB18E1 cells. The index hierarchy has
three control FDREs; the 24,576-bit payload is in three RAMB18E1 cells.

`report_ram_utilization` and the explicit primitive paths are preserved in this
directory. Exact full-design mapping remains a mandatory post-synthesis gate in
the sole clean R1h build.

## Action accounting

```text
MEMORY_INFERENCE_OOC_SYNTH_DESIGN_INVOCATIONS=1
FULL_CLEAN_BUILDS=0
OPT_DESIGN_RUNS=0
PLACE_RUNS=0
ROUTE_RUNS=0
CHECKPOINTS_WRITTEN=0
BITSTREAMS=0
HARDWARE_ACTIONS=0
```
