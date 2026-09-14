# G2B-NVP-OFFLINE-ADVANCE1 publication policy receipt

## Scope

PUBLIC_REPOSITORY = `lukaszsudul/AHD-diagnostic-evidence`

PUBLIC_BRANCH = `main`

PUBLIC_DIRECTORY = `v41-development-g2b-nvp-offline-advance1-rm1-mode1-camera-mapping`

PUBLIC_COMMIT_MESSAGE = `Prepare AHD v41 NVP RM1 MODE1 and camera-mapping offline package`

PUBLICATION_MODE = `EXPLICIT_ALLOWLIST_ONLY`

The publication checkout is fresh, task-local, sparse, and separate from the
existing evidence checkout. Files are staged by exact path. The umbrella task
root is never copied recursively.

## Allowed evidence classes

- hash and source-identity manifests;
- RM1 clean-room source files changed from the frozen RM1 parent;
- RM1 normalized local-test and build/sign-off receipts;
- MODE1 clean-room manifests, matrices, model reports, and their task-local
  generator/verifier source;
- camera/connector mapping summaries, bounded-search receipts, analog audit,
  qualification protocol, Owner worksheet, evidence schema, and continuity
  plan;
- continuation prompts and their package index;
- umbrella authority, operation, test-gate, report, evidence-index, and
  publication receipts.

## Prohibited public payloads

- vendor source files or vendor PDFs;
- private KiCad, schematic, netlist, BOM, PCB, assembly, or as-built source;
- bitstreams, DCPs, probes, Vivado databases, or implementation payloads;
- drivers, credentials, secrets, tokens, or private keys;
- camera images, raw video, frame data, or runtime archives;
- raw XSim/Vivado working directories such as `.Xil`, `xsim.dir`, caches, or
  journals;
- owner-input copies and local controller-lock material.

## Required pre-push gates

1. The exact staged path set equals the approved allowlist.
2. Every staged blob SHA-256 equals its source file SHA-256.
3. A denylist scan finds no prohibited extension, path, credential marker, raw
   media, private design source, bitstream, DCP, driver, archive, or build
   database.
4. The public SHA manifest covers every published file except itself; the
   self-exclusion is explicit to avoid a recursive hash dependency.
5. One commit with the exact Owner-specified message is created on top of the
   currently fetched `origin/main`.

## Required post-push gate

A second fresh no-checkout clone must read the pushed commit by exact object
identity. Its `ls-tree` path set and every commit-pinned blob byte hash must
match the staged publication. A successful push by itself is not publication
PASS.

## Status

POLICY_DEFINITION = `PASS`

PRE_PUSH_ALLOWLIST_GATE = `PASS_58_FILES_57_MANIFEST_ROWS_SELF_EXCLUDED`

REMOTE_COMMIT_PINNED_READBACK = `PENDING_POST_PUSH_NOT_SELF_EMBEDDED`
