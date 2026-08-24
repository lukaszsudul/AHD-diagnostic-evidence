# R1f read-only host-tool interface

## Frozen implementation paths

```text
READER=scripts/v41/read_nvp_r1f.py
STATISTICS_HELPER=scripts/v41/r1f_statistics.py
OFFLINE_TESTS=tests/python/test_nvp_r1f_tools.py
OFFLINE_FIXTURE=tests/python/fixtures/r1f_valid_scenario.json
```

The implementation is new R1f tooling. The inherited
`scripts/v41/read_nvp_r1e.py` was not edited.

## Reader command line

Exactly one source is required:

```text
--node <exact already-proven XDMA user node>
--input-json <offline sparse word-map fixture>
```

The remaining contract is:

```text
--expect r1f|formal|none
--twice
--delay <seconds>
--output-dir <directory>
```

Campaign use must select `--expect r1f` for an Arm-A R1f sample and
`--expect formal` for an exact-formal Arm-B sample. `none` is a fail-closed
auto-classification convenience for offline inspection, not a replacement for
an arm's explicit expected-image receipt.

`--twice` collects two independently decoded complete snapshots, waits the
nonnegative `--delay`, and requires equality of the frozen static projection.
The live backend opens the exact node with `O_RDONLY | O_CLOEXEC` and uses
bounded `pread` only. It performs coherent high/low/high reads for the four
48-bit lifecycle/timestamp pairs.

On success the process exits zero and terminates its output with:

```text
READ_ONLY=YES
STATIC_SNAPSHOTS_MATCH=YES|NOT_REQUESTED
```

Any version, map, count, validity, zero-range, reconciliation, probe, bank, or
scientific-validity contradiction exits 2 with:

```text
R1F_DECODE_ERROR=<exact failure>
```

## Bounded read inventory

The reader preserves:

- normal local NVP/video telemetry `0x0000..0x00E0`;
- the existing R1e lifecycle page `0x2000..0x209C`;
- the complete R1f range `0x20A0..0x35FC`;
- the inherited 23-word detail vector `0x10080..0x100D8`, including the exact
  legacy 17-word window `0x10098..0x100D8`.

The R1f range includes all 64 x six-word failed-transaction entries, all three
probe aggregate/block areas, the scheduler/setup/restoration area, and all
three complete 512 x 16-bit target-NACK index areas. Raw inventory retains
every read word; decoded JSON additionally retains all 64 raw record entries.

## Version and scientific gates

R1f interpretation requires exact equality of magic, version, capabilities,
record version/width/word count, log capacity, probe phase mask, frozen safe
target `bank=0x00/register=0x85/data=0x00`, I2C rates, opportunity/block counts,
attempt limit, and index-log capacity. An all-ones identity is rejected.

The decoder enforces explicit valid bits, reserved-zero fields, transaction
kind/table-slot rules, NACK/opportunity subset and popcount rules, chronological
16-bit transaction serials, all-zero unused records, exact total/stored/
overflow behavior, legacy first-eight reconciliation, phase-counter equality,
probe prerequisite/target/block/index sequence invariants, setup/readback/
bank restoration, and bank-invariant status. A structurally coherent overflow
can be decoded for audit, but it is rejected by the hardware scientific-sample
gate. Exact formal requires deterministic zero over every aligned word in
`0x20A0..0x35FC`.

## Output set

`--output-dir` creates only host evidence files:

```text
decoded.json
raw_mmio_inventory.csv
decoded_flat.csv
failed_transactions.csv
phase_opportunities.csv
probe_per_phase.csv
probe_blocks.csv
probe_nack_indices.csv
bank_invariant_report.json
lifecycle_calculation.json
```

No output operation addresses the device node.

## Statistics interface

`scripts/v41/r1f_statistics.py` implements the frozen Section-16 primary plan:

- Wilson 95% intervals and fixed-family Holm adjustment;
- exact conditional equal-block homogeneity by integer dynamic programming;
- exact conditional Wald-Wolfowitz runs and adjacent-NACK-pair tests;
- exact first/last order-statistic context;
- exact Fisher greater and Fisher-Freeman-Halton probability-ordering tails;
- two-sample Miettinen-Nurminen 95% score interval with the prescribed
  `N/(N-1)` correction;
- 95% profiled two-binomial rate-ratio likelihood interval without a
  pseudocount;
- global 27-test stationarity classification;
- opportunity-normalized autoinit phase heterogeneity and context elevation;
- exact replicate rate/composition and equal-exposure Arm-B count tests;
- frozen paired-direction, bank, operation-86, and failed-composition labels.

Undefined planned hypotheses receive p=1 only for their frozen Holm family and
retain an explicit insufficiency reason. No mid-p, Monte Carlo, post-result test
selection, pseudocount, or asymptotic replacement is implemented.
