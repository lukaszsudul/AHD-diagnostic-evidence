# Scientific outcome rules

Classifications are additive; the first blocker does not suppress independent findings.

| Classification | Exact trigger |
|---|---|
| `CAMERA_SIGNAL_DETECTED` | at least one channel has consistent NOVID clear plus a coherent lock/status change across three eligible snapshots |
| `CAMERA_FORMAT_STABLE` | three consecutive eligible complete tuples decode to the same supported/unsupported format |
| `SIGNAL_PRESENT_FORMAT_UNRESOLVED` | signal/lock evidence exists but the read-only tuple cannot resolve the reference decision tree |
| `NO_SIGNAL_OBSERVED` | all channels retain NOVID/no-lock baseline across the bounded campaign; this is an observation, not proof no source exists |
| `REGISTER_SEMANTICS_UNCONFIRMED` | a conclusion depends on a reference-private field lacking NVP6134C field authority |
| `LIVE_STATUS_CHANGED_DURING_SCAN` | A8_PRE differs from A8_POST |
| `PHYSICAL_MAPPING_UNRESOLVED` | signal candidate cannot be tied to an authorized CH1/CH3 connector |
| `UNSUPPORTED_PRODUCT_FORMAT_<FORMAT>` | stable decoded format is not AHD1080p25; report only, no mode/EQ write |

`NO_SIGNAL_OBSERVED` and `SIGNAL_PRESENT_FORMAT_UNRESOLVED` are bounded experimental outcomes, not acquisition failures and not permission to broaden hardware actions.
