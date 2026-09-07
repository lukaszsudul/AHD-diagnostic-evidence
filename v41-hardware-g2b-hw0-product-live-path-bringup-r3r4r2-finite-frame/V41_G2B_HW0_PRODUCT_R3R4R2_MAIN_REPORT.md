# AHD v41 G2B-HW0-PRODUCT-R3R4R2

## Outcome

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `R3R4R2_CAPTURE_TOOL_ARCHITECTURE_HARD_GATE_FAILED:PERSISTED_FIRST_RECORD_REREAD_HASH_PROOF_ABSENT`
- Hardware accessed: `NO`

## Completed offline gates

R3R3, failed R3R4, and failed R3R4R1 evidence and manifests verified at their
pinned commits. PROJECT_STATE_REV remained 8. The exact PRODUCT source,
bitstream, DCP, frozen ABI, and qualified driver identities matched.

The only capture/self-test delta was the authorized R3R4R2 identity update and
the case-5 expected vector correction to
`[false,false,false,false,false,true,true]`. The runtime quiet-window function
was unchanged. All 11 offline self-tests passed, including the 2,507-record
partial-read fixture with exactly 2,500 primary records, seven drain records,
and zero trailing bytes.

## First stopped gate

The independent architecture hard gate found that `_persist_first` flushes and
fsyncs the dedicated first-record and payload files, but computes the reported
hashes and performs ABI validation from the pre-write in-memory `blob` and
`payload`. It never re-reads the persisted files. R3R4R2 sections 9 and 19
explicitly require the hashes and parse to use re-read persisted bytes.

The audit also preserved other downstream contract gaps: no periodic primary
file fsync checkpoint before `PRIMARY_TARGET_REACHED`, no enforced first-record
durability-before-primary ordering, no multi-observation stability requirement
in parent quiescence, and split nonfatal/fatal normalization logic that can
permit two W1C writes instead of the single combined-mask budget. These were
not modified because this run authorizes no runtime semantic change.

Credential-helper execution and all DUT activity were therefore prohibited.
Connections, driver loads, MMIO operations, DMA operations, programming,
reboots, Flash writes, and power cycles all remained zero.
