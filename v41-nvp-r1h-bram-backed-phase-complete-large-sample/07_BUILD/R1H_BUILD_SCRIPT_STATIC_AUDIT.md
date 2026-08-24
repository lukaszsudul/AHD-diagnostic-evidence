# R1h build-Tcl static audit

STATUS: `PREPARED_NOT_EXECUTED`

No Vivado process, synthesis, optimization, placement, routing, checkpoint open, or bitstream generation was run while preparing this file.

## Identity

- R1g frozen source script: `C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\scripts\r1g_build.tcl`
- R1g frozen script SHA-256: `C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A`
- R1h candidate script: `C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\07_BUILD\r1h_build.tcl`
- R1h candidate script SHA-256: `2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18`
- Required branch: `diag/v41-nvp-r1h-bram-backed-large-sample`
- Required direct parent: `e112a5addb7ac62700a9a71af81bf368fad0bada`
- Exact R1f ancestor: `225544084dbfcaadb8592fcecc947aa1cec4970e`
- Exact R1e base: `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`
- Required topology: one R1h commit above R1g and exactly three commits above R1e.
- Vivado contract retained: 2025.2, SW build 6299465, part `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`.

## Frozen-flow preservation

The R1h script was derived from the exact frozen R1g Tcl. It retains:

- the seven positional arguments and manifest grammar;
- exact clean-tree, branch, commit/tree, ancestry and one-build sentinel checks;
- exact XDMA XCI import/configuration/property audit;
- exact XDC list and processing order;
- unchanged VHDL list and production language mode;
- the same synthesis command and `-flatten_hierarchy rebuilt`;
- `opt_design -directive Explore`;
- `place_design -directive Explore`;
- `phys_opt_design -directive Explore`;
- `route_design -directive Explore`;
- timing, DRC, REQP-1839 semantic, CDC, bus-skew, power, IO and NVP path gates;
- bitstream emission only after the implementation gate passes;
- one-build fail-closed terminal receipt and no retry loop.

Only the R1h identity/provenance, source inventory, prebuild proof obligations, post-synthesis resource gates, and R1h evidence names were added or updated.

## Compile-order additions

The SystemVerilog source list adds:

1. `rtl/v41/r1h_probe_index_bram_store.sv` before `nvp_i2c_tri_phase_probe.sv`;
2. `rtl/v41/r1h_mmio_read_service.sv` before the top-level consumer.

The queried synthesis compile-order audit requires every R1h dependency before the top and separately proves the index-store wrapper precedes its probe consumer.

The source-contract gate also requires that the read service advertises neither
request-ready nor response-valid while reset is asserted, and that its top-level
reset is the logical OR of AXI reset and NVP POR reset. This prevents accepting
a BRAM request while the logger/index response pipelines are reset.

## Static command cardinality and ordering

The candidate contains exactly one active command of each consuming stage:

- one-build sentinel selection: line 771;
- atomic sentinel creation: line 860;
- `synth_design`: line 1054;
- post-synthesis DCP write: line 1065;
- mandatory resource receipt: line 1219;
- fail-closed combined-gate error: line 1260;
- `opt_design`: line 1265;
- `place_design`: line 1269;
- `phys_opt_design`: line 1283;
- `route_design`: line 1286;
- routed checkpoint write: one;
- `write_bitstream`: line 1585 and only inside the complete implementation PASS branch.

Therefore `opt_design` is textually downstream of the post-synthesis gate; `place_design`, routing and bitstream generation cannot be reached if that gate fails.

## Post-synthesis evidence and gates

Immediately after synthesis and before optimization, the script:

1. proves the synthesized cell/net sets are non-empty;
2. writes `R1H_synth.dcp`;
3. computes its SHA-256;
4. emits flat and depth-20 hierarchical utilization plus timing summary;
5. records Slice LUT, LUT-as-logic, LUTRAM, Slice Register, MUXF7, MUXF8, RAMB18E1 and RAMB36E1 totals;
6. inventories each matching payload primitive by exact netlist cell name;
7. applies the memory-mapping and total-resource gates;
8. writes `R1H_POST_SYNTH_RESOURCE_GATE.txt` before any optimization command.

Mandatory mapping conditions are exactly six record `RAMB18E1`, one `RAMB18E1` for each WADDR/REGADDR/DATA index bank, nine new payload `RAMB18E1` total, zero payload `RAMB36E1`, zero record/index `RAM64M` and `RAMD64E`, and at most 192 FDRE/all-FF objects in each bounded storage region. Counting is based on `REF_NAME` and retained hierarchy names, not `ram_style` or XPM parameters alone.

Mandatory total limits are Slice LUTs <= 18,720 and Slice Registers <= 37,440, with device availability also required to query as exactly 20,800 and 41,600. Failure raises `BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING` before `opt_design`.

## Provenance fail-closed behavior

The prebuild manifest SHA-256 is supplied as an argument and rehashed. All required repository sources, XCI and XDC files are rehashed. Accepted proof logs are rehashed. The manifest must also bind `R1H_BUILD_TCL_SHA256` to the hash of the executing Tcl (`[info script]`). The final R1h commit and tree remain runtime arguments, are compared with the clean repository, and are encoded into the runtime provenance generics.

## Static limitations

This audit establishes script structure only. It does not claim that synthesis will produce the required primitives or meet the limits. Those claims become valid only if the exact one-build run produces a PASS receipt and named-cell inventory from its exact post-synthesis netlist.
