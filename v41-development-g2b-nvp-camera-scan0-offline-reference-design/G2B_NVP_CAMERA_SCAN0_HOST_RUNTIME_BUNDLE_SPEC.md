# Closed host runtime bundle

The future SCAN1 host decoder must be delivered as a fresh, task-local, hash-pinned bundle modeled on the accepted R3R2R1 architecture. Its manifest includes every Python/module file, non-code resource, launcher and expected SHA-256. Qualification order is fixed:

1. Resolve transitive import and resource closure offline.
2. Copy only that closure into an isolated local test directory.
3. Pass an isolated local import/`--self-test` gate with ambient package paths removed.
4. Prove a negative missing-dependency test fails closed.
5. Copy to DUT only under later explicit hardware authority.
6. Read back every DUT byte and compare SHA-256.
7. Pass isolated DUT import and module-provenance gates before the first device call.

No network installation, ambient dependency, prior-run runtime, mutable manifest, or fallback import is allowed. Runtime qualification remains a separate future gate; this offline task creates only the specification.
