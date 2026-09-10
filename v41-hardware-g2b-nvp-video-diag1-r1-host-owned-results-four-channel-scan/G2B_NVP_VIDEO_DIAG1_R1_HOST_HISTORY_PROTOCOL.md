# Host-owned history protocol

The host implementation performs valid/generation/session double reads around
the eight words, permits at most three immediate coherence retries, requires
the word-0 and live session IDs to agree, and durably appends the snapshot
before capture. Simulation collected 16 unique coherent session snapshots in
the exact 4x4 order with monotonic generations and no duplicates or omissions.
No live snapshot was collected because hardware eligibility was not reached.
