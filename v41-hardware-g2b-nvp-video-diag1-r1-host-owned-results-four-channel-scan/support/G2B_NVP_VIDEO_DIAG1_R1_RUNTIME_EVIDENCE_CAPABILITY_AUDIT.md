# G2B NVP VIDEO DIAG1-R1 Runtime Evidence Capability Audit

## Decision

The unchanged DIAG1-R1 RTL can truthfully prove the five-consecutive-sample
classification contract at session granularity. It cannot expose a raw event
record for each of the five samples or for every internal I2C transaction.

The coherent eight-word session snapshot retains:

- the final five-byte raw status signature;
- the consecutive stable-sample count;
- the total sample count;
- the route and BGDCOL readbacks;
- the cumulative accepted-I2C-command count;
- aggregate NACK, timeout and recovery counts;
- the first and last I2C error summaries.

For an `ACTIVE_STABLE`, `NO_VIDEO_STABLE`, or `STATUS_CONTRADICTORY` session,
`StableSamples = 5` proves through the verified RTL state-machine invariant that
the retained signature was observed in five consecutive complete status
samples. The FPGA does not retain five separately timestamped rows.

## Information not available through the frozen MMIO contract

- per-transaction sequence IDs;
- per-transaction start or completion timestamps;
- a transaction-by-transaction bank/register/read-write/value/ACK record;
- five individually retained raw status signatures;
- the intermediate signatures that preceded a `LOCK_UNSTABLE` timeout.

The low-level fixed I2C master has an internal transaction counter, but its
command/event payload is not exported through diagnostic MMIO. Polling live
status registers from the host would not repair this: the five fields are
updated serially and could be read as a torn signature.

## Safe host-only evidence

`extract_nvp_runtime_evidence.py` creates four explicitly scoped projections:

1. session-level final stable-signature summaries;
2. cumulative accepted-command interval summaries;
3. logical route/BGDCOL write receipts paired with coherent readback;
4. route, BGDCOL and final-stable-status readback summaries.

Every output states that raw per-transaction records and individual sample
timestamps were not retained. The tool does not duplicate a retained signature
into five synthetic rows.

## Gate disposition

This limitation is not, by itself, an engineering failure under the explicit
DIAG1-R1 engineering PASS list. Runtime `StableSamples = 5`, coherent raw
signature, exact route/BGDCOL readback, monotonic accepted-command counts, and
zero aggregate I2C errors support the status, routing, and I2C health decisions.

It is a publication-granularity gap if the required file name
`I2C_TRANSACTION_LOG.csv` is interpreted to require one raw row for every
physical I2C transaction. The host-only projections may be published under the
required names only with their included `EvidenceGranularity` and `Limitation`
columns preserved. A literal raw transaction-event requirement would require a
future RTL/MMIO telemetry change and cannot be satisfied by host software
against the current frozen source commit.
