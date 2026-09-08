
# Root-cause decision

`BT656_ROOT_CAUSE_DECISION=ROOT_CAUSE_NOT_PROVEN_RAW_MARKER_OBSERVABILITY_REQUIRED`

The host disable-path defect is independently corrected and its gate passes.
The preserved primary establishes a deterministic source-boundary signature,
but fixed record headers expose only cumulative source snapshots after each
committed line. They do not expose the raw markers or parser states within the
missing interval.

Current causal bounds:

- H1 is disproven as the sole root: pure unlocked-line admission suppression
  creates no attempt/drop, unlike the hardware boundary. Its conditional code
  mechanism remains proven and may occur after another malformed episode.
- H2 is the leading open protocol hypothesis: +21 requires 21 distinct early
  marker, invalid-EAV, or EAV-timeout episodes. The exact input bytes are absent.
- H3 is disproven by 1079->0->1 simulation with SOF.
- H4 remains open because the forced NVP profile is known but its exact boundary
  marker stream is not locally documented.
- H5 is not supported by current deterministic evidence and accepted timing.

No speculative RTL or NVP correction was created. No correction branch,
worktree, or commit exists.
