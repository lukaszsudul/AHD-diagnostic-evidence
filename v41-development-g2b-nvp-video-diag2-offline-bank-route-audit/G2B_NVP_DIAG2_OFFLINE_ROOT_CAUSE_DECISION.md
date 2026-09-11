
# Offline root-cause decision

Decision: `STRONG_BANK6_8_CONFIGURATION_CANDIDATE_REQUIRES_HARDWARE`.

Exact mapping and route indexing are correct. The effective replay finds 51 writes over 37 undocumented private addresses in Bank5 and zero analogous writes in Banks6, 7, or 8. The runtime diagnostic's `CONFIGURE_ALL_CHANNELS` state is a no-op and verifies only public Bank0 fields. This is a strong all-channel configuration-completeness concern.

It is not a proven Bank6/8 defect: the PDF withholds private meanings and does not require replication, the local reference is single-channel, and working CH3/Bank7 receives the same no-write treatment as failing Banks6/8. No exact alternating parity/index path or authoritative re-arm omission was found. Hardware raw-marker isolation is therefore required before any functional patch.
