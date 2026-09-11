# Validator Regression

Result: **16/16 PASS**.

The suite covers retained CH1 exact-tail control, accepted immutable CH3 delta-2 metadata, legal minimum/maximum boundaries, invalid zero/above-maximum deltas, invalid non-boundary delta, frame/flag/sequence/counter failures, event flags, variable-but-bounded tails, and incomplete/duplicate active frames. A full synthetic 2500-record delta-2 integration also passed active-frame integrity, bounded VBI, and complete-frame reconstruction while the independent legacy exact-22 fingerprint failed as expected.
