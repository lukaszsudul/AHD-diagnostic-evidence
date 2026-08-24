# R1h post-synthesis resource gate specification

STATUS: `DEFINED_NOT_RUN`

## Placement in flow

```text
synth_design
  -> non-empty netlist proof
  -> write/hash R1H_synth.dcp
  -> utilization/hierarchy/timing reports
  -> exact primitive inventory
  -> memory mapping gate
  -> 10% LUT/FF margin gate
  -> PASS only: opt_design -> place_design -> phys_opt_design -> route_design
```

No optimization or placement command executes after a failed gate.

## Mandatory primitive gate

```text
FAILED_RECORD_PAYLOAD_RAMB18=6
WADDR_INDEX_PAYLOAD_RAMB18=1
REGADDR_INDEX_PAYLOAD_RAMB18=1
DATA_INDEX_PAYLOAD_RAMB18=1
R1H_NEW_PAYLOAD_RAMB18_TOTAL=9
R1H_NEW_PAYLOAD_RAMB36_TOTAL=0
FAILED_RECORD_PAYLOAD_RAM64M=0
FAILED_RECORD_PAYLOAD_RAMD64E=0
INDEX_PAYLOAD_RAM64M=0
INDEX_PAYLOAD_RAMD64E=0
FAILED_RECORD_PAYLOAD_FDRE<=192
INDEX_PAYLOAD_FDRE_TOTAL<=192
FAILED_RECORD_REGION_ALL_FF<=192
INDEX_PAYLOAD_REGION_ALL_FF<=192
```

The all-FF bounds deliberately count the entire named logger/index-store regions, so they are stricter than attempting to infer which nearby registers are payload versus pipeline metadata.

The inventory is derived from `REF_NAME` and exact retained hierarchy patterns:

- record: `R1F_FAILED_TXN_LOGGER` / `r1f_failed_txn_logger`;
- index payload: `INDEX_PAYLOAD_STORE`;
- phases: `GEN_INDEX_BRAM[0]`, `[1]`, `[2]`.

Every matched primitive cell name is emitted. A source attribute alone cannot satisfy the gate.

## Mandatory total-resource gate

```text
POST_SYNTH_SLICE_LUTS<=18720
POST_SYNTH_SLICE_REGISTERS<=37440
DEVICE_SLICE_LUTS=20800
DEVICE_SLICE_REGISTERS=41600
```

The script also records post-synthesis logic LUT, LUTRAM, MUXF7, MUXF8, RAMB18E1 and RAMB36E1 counts. The expected targets of logic LUT <=18,000 and FF <=25,000 are reported context, not substitutes for the mandatory 10% raw-device headroom gate.

## Fail-closed result

The authoritative pre-opt receipt is `R1H_POST_SYNTH_RESOURCE_GATE.txt`. Either a mapping mismatch or resource-limit mismatch yields:

```text
BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING
```

The one-build terminal receipt records stage and command-run counters. No source correction, second build, or retry is encoded in the script.
