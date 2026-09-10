# G2B-NVP-VIDEO-DIAG1-R2R1 Phase-N baseline capability audit

Result: **BLOCKED**

Exact blocker:

```text
BLOCKED — NVP_DIAG1_R2R1_FROZEN_BASELINE_DOUBLE_READ_AND_HOST_LEDGER_CAPABILITY_ABSENT
```

This was a read-only audit of the frozen diagnostic RTL and accepted R1 host
controller. No source, RTL, XDC or IP was changed. No DUT or hardware operation
was performed.

Phase N requires, before any diagnostic NVP write, two physical reads of the
complete restoration baseline, exact agreement, and retention in both firmware
and host ledgers. The frozen implementation cannot meet that literal contract:

- repeated `PREPARE_DIAGNOSTIC` is accepted by the IDLE state
  (`g2b_nvp_video_diag.sv`, lines 546–555);
- each PREPARE pass single-reads bank, BGDCOL 0x78, BGDCOL 0x79 and VDO1 route
  (`g2b_nvp_video_diag.sv`, lines 586–617);
- a second pass overwrites the same `original_*` registers rather than comparing
  two retained snapshots (`g2b_nvp_video_diag.sv`, lines 165–168 and 605–609);
- diagnostic MMIO exposes original route/BG values, but not `original_bank`
  (`g2b_nvp_video_diag.sv`, lines 337–339; other unmapped addresses default to
  zero at line 370);
- PREPARE itself performs bank-select writes (lines 590, 593 and 595), so two
  PREPARE passes do not satisfy the literal “before any diagnostic NVP write”
  ordering;
- the accepted host controller performs one PREPARE and one exposed baseline
  read set (`controller_nvp_video_diag1.py`, lines 908–917), and writes its MMIO
  ledger only during finalization (lines 1223–1238);
- the older R-track original-bank telemetry is unavailable because the routed
  profile has `ENABLE_RTRACK_DIAGNOSTICS=0`.

Consequently, two PREPARE cycles are only a partial technical workaround. They
cannot create two firmware-retained baseline snapshots, cannot compare the
hidden bank/page value host-side, and cannot create the required firmware and
host baseline ledgers under the frozen source/host CLI.

Hardware remains **NO-GO** even if offline routed sign-off passes. Resolution
requires an explicit Owner/Architect contract reconciliation or a separately
authorized bounded RTL/MMIO/host change. Neither is authorized in R2R1.
