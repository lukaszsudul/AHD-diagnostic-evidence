# Safety-invariant comparison

The reference invariant is the accepted G14-A invariant at evidence commit `9e91315968453e859006077191cd5fc711fc6b96`. Status `PROVEN` below means direct slot-indexed RTL plus routed-DCP evidence, not inheritance from a name match.

| Invariant | Slot 1 | Slot 2 | Slot 3 | Evidence |
|---|---|---|---|---|
| 1. Payload held stable before release event | PROVEN | PROVEN | PROVEN | Token and toggle update together only on selected final beat; prior descriptor token is already stable. |
| 2. Release event crosses intended synchronizer | PROVEN | PROVEN | PROVEN | One toggle and direct sync1-to-sync2 FDRE chain per slot; both stages `ASYNC_REG=1`. |
| 3. Destination uses token only after synchronized release | PROVEN | PROVEN | PROVEN | Ordinary decode is gated by `release_sync2 != release_seen`; no pre-sync2 use found. |
| 4. Payload stable through destination consumption | PROVEN | PROVEN | PROVEN | Payload survives reset branches and is not rewritten until a later same-slot lifecycle completes. |
| 5. Mismatch contained and recorded | PROVEN | PROVEN | PROVEN | Generation/epoch/state failure asserts ownership fatal/event/deferred channel and disables admission. |
| 6. Reset overlap cannot accept stale release | PROVEN | PROVEN | PROVEN | Reset captures same-edge final release phase; epoch mismatch fails closed; request has its own two-stage qualifier. |
| 7. Captured release phase retired coherently | PROVEN | PROVEN | PROVEN | Full synchronized release vector and ownership phase must match captures before acknowledgement. |
| 8. Source cannot overwrite state prematurely | PROVEN | PROVEN | PROVEN | Slot state machine requires release to WRITABLE before allocation; release payload changes only at later final beat. |

No invariant depends on identical mapped combinational depth. The mapped differences were retained in the structural matrix and each resulting family was independently timed.

Result: all eight safety invariants are `PROVEN` for slots 1, 2, and 3. No assumption-only proof was used and no RTL change is required.
