# Deterministic offline evidence-sealing workflow

## Scope

This staging directory prepares the evidence sealer for
`V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1`. It has not sealed the real
task root and performs no network, hardware, MMIO, DMA, build, synthesis,
implementation, or FPGA-source operation.

Copy the two PowerShell files into the final task's `scripts` directory only
after the analytical evidence and final report are complete:

```text
C:\FPGA\V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1\scripts\
```

Run the test script first. Run the production sealer exactly once only after
the test reports `SEAL_TESTS=PASS_ALL` and the parent task has completed its
final report audit.

## Exact outputs

The production sealer creates fresh outputs only:

```text
V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE.zip
V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE_SHA256.txt
SHA256_MANIFEST.txt
08_FINAL/SECURITY_SCAN.txt
08_FINAL/EVIDENCE_ZIP_INTEGRITY.txt
```

The ZIP uses the exact single root prefix:

```text
V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1/
```

The external sidecar and integrity receipt include the final ZIP hash. The
manifest and security report are also published outside the ZIP and occur as
byte-identical entries inside it. The manifest intentionally does not hash
itself.

## Fail-closed gates

The sealer enforces:

- exact production-root placement and a separately bounded OS-temporary test
  root;
- mandatory evidence-file presence and non-empty content;
- final-report fixed identities, zero-operation fields, and non-empty result
  fields;
- zero-operation contracts in both ledgers;
- no reparse points, path escape, unsafe ZIP names, case-insensitive source
  collisions, exact ZIP-name duplicates, or wrong archive root;
- no credential-like filenames or content signatures;
- no temporary/backup files, FPGA bitstreams, DCPs, VCS metadata, or nested
  archives;
- an immutable OS-temporary snapshot using source pre-hash, copy hash,
  post-hash, size, and last-write checks;
- ordinal ZIP entry order and a fixed `2000-01-01T00:00:00Z` entry timestamp;
- decompression and SHA-256 verification of every ZIP entry;
- exact manifest-to-ZIP hash and size correspondence;
- a final source-set and staged-snapshot recheck to detect concurrent changes;
- rollback of any root outputs if output publication is only partially
  completed.

The payload excludes the ZIP, ZIP sidecar, ZIP integrity receipt, synthetic
test marker, and post-seal/publication receipts. Any other archive, bitstream,
DCP, temporary file, credential-like filename, or detected secret aborts the
seal instead of being silently omitted.

## Validation model

The synthetic suite exercises two successful roots and proves identical ZIP
hashes despite different source filesystem timestamps and paths. It also
independently opens the archive and checks root prefix, duplicate names,
unsafe names, forbidden extensions, manifest/security inclusion, and output
receipt exclusion.

Negative fixtures verify fail-closed handling of:

```text
secret content
standalone .bit input
nested archive input
temporary-file input
source mutation after immutable snapshot
```

The synthetic roots are created only below the operating-system temporary
directory and are recursively removed only after the absolute path and leaf
prefix are revalidated.

## Intended invocation

```powershell
& 'C:\FPGA\V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1\scripts\Test-Seal-ControlFlowShorteningEvidence.ps1'
& 'C:\FPGA\V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1\scripts\Seal-ControlFlowShorteningEvidence.ps1'
```

The first command is an offline synthetic test. The second is the one-shot
production seal and must not run until the evidence tree is final and stable.

