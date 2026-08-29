# G2B-LUT0 G2B Cost Breakdown

## Measured incremental cost

The only valid stage-matched comparison is post-opt to post-opt:

| Contributor | LUT delta | FF delta | BRAM-tile delta | Status |
|---|---:|---:|---:|---|
| `G2B_ONECH_C2H` hierarchy | +1,990 | +2,908 | +4 | measured hierarchy; BRAM confirmed by direct checkpoint query |
| XDMA with C2H streaming active | +619 | +598 | 0 | measured hierarchy |
| Router/top/integration/repartition residual | +234 | 0 | 0 | derived reconciliation, not a literal module cost |
| **Comparable G2B delta** | **+2,843** | **+3,506** | **+4** | exact |

The residual is `2,843 - 1,990 - 619 = 234 LUT`. Its raw hierarchy movements are +371 in the AXI-Lite bridge, +28 in the R1h read service, +2 in the logger and +7 shared, offset by -56 control/status, -14 capture, -92 NVP autoinit and -12 probe. Flattening and cross-hierarchy combining prevent treating any one of those movements as the router's standalone cost.

The XDMA delta is mandatory. Internally, its `udma_wrapper` grows by 617 LUT/594 FF; the remaining XDMA reconciliation is 2 LUT/4 FF. C2H realization includes the streaming interface and write/C2H engine. The effective configuration remains the required Gen2 x1 configuration.

## Direct G2B-core attribution

The published hierarchical row is the authoritative comparison number (`1,990 LUT`). A read-only `report_utilization -cells G2B_ONECH_C2H` query against the sealed post-opt DCP returned `1,994 LUT`, `2,908 FF`, and four `RAMB36E1`; the four-LUT difference is a report scope/combining artifact. The additive estimates below normalize to the direct 1,994-LUT scope, not to the hierarchy row.

| G2B functional block | Estimated LUT | Estimated FF | BRAM | Evidence/confidence |
|---|---:|---:|---:|---|
| Four-slot RAM and address glue | 26 | 0 | 4 | checkpoint name group; high |
| Source parser, payload formatter, ring control | 547 | 493 | 0 | reconciled name groups; medium |
| Ownership, descriptors and source-domain CDC | 239 | 404 | 0 | reconciled name groups; medium-high |
| AXIS scheduler, header and output | 227 | 230 | 0 | reconciled name groups; medium |
| Live statistics and status | 168 | 361 | 0 | reconciled name groups; medium-high |
| Coherent snapshot, Gray CDC and shadows | 308 | 939 | 0 | reconciled name groups; medium-high |
| G2B MMIO decoder/readback/control | 170 | 52 | 0 | reconciled name groups; medium-high |
| Reset, recovery and reset epoch | 224 | 376 | 0 | reconciled name groups; medium |
| Error/fatal/drop logic | 83 | 51 | 0 | reconciled name groups; medium |
| Identity/capability and miscellaneous glue | 2 | 2 | 0 | optimized constants/shared logic; low |
| **Direct-cell normalized total** | **1,994** | **2,908** | **4** | exact total; estimated partition |

The requested conceptual categories overlap in source. A second, design-oriented normalization to the hierarchy total is therefore supplied for planning:

| Conceptual category | Estimated LUT | Notes |
|---|---:|---|
| four-slot storage/control | 355 | 26 RAM glue plus most ring allocation/control; payload storage is BRAM |
| record formatter/parser | 300 | BT.656 record admission, packing and malformed handling |
| header generation | 140 | fixed ABI header construction/staging |
| AXI scheduler | 230 | prefetch, ready/valid and output selection |
| sequence logic | 160 | source/global/channel sequences and attempts |
| reset epoch | 150 | reset coordinator and epoch protection |
| MMIO decoder/registers | 130 | required frozen G2B page |
| statistics counters | 115 | live counters only |
| snapshot CDC | 260 | held Gray buses, two-stage synchronization, shadows and handshake |
| error logic | 85 | sticky/fatal/error/drop accounting |
| host-facing identity | 10 | constants largely optimize away |
| other source-domain CDC | 30 | non-snapshot controls/status |
| integration glue inside core | 25 | shared/reconciled remainder |
| **Hierarchy-normalized total** | **1,990** | estimate sums to measured hierarchy total |

## Counter and snapshot obligation

The implementation contains four 32-bit source snapshot counters, a 32-bit epoch echo, registered Gray holds, two synchronizer stages for all five 32-bit buses, AXI-domain live counters (including a 64-bit accepted-beat counter), complete shadow registers, snapshot generation, BUSY/VALID, and request/acknowledge control. The frozen MMIO contract fixes their increment events, coherency, reset-epoch behavior and readback semantics.

No defined G2B counter may be replaced by zero or a non-coherent value without violating the frozen contract. Reserved addresses already return deterministic zero. Mandatory G2B observability—MMIO, counters, coherent snapshot, error state, identity and capabilities—is estimated at `600 ±100 LUT` and about `1,350 FF`, all classified as product logic.

## Largest contributors and safe optimization boundary

The largest G2B cones are source formatting/ring control, snapshot CDC/shadows, ownership/descriptor state, and AXIS scheduling. No research-only logic exists in either G2B source file, so category-A G2B removal is zero LUT.

Category-B, same-semantics candidates for a later controlled implementation are:

1. Time-multiplex Gray-to-binary conversion while retaining atomic publication: estimated 55–80 LUT.
2. Prove and reduce duplicated descriptor attempt/generation/epoch metadata: estimated 45–90 LUT.
3. Replace wide fatal/reset-generation bookkeeping with an equivalent finite-state proof: estimated 35–65 LUT.
4. Share repeated per-slot generation/epoch comparisons: estimated 50–100 LUT.

After overlap and added control, a realistic aggregate is `120–220 LUT`. These are not de-instrumentation credits and require exhaustive frozen-contract, reset, CDC and backpressure regression. No frozen ABI, MMIO, R1i behavior or four-slot architecture change is required.

