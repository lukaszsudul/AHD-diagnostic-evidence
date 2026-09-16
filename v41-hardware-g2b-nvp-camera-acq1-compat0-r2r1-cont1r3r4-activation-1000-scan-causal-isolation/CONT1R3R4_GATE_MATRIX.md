# Gate matrix

| Gate | Verdict | Evidence or reason |
| --- | --- | --- |
| Revision-9 project authority | PASS | Start/end 9; unchanged SSOT hashes. |
| No duplicate CONT1R3R4 run | PASS | No matching local run root or evidence directory existed before this run. |
| Exact local firmware | PASS | 2,192,144 bytes; pinned SHA-256 matched. |
| Inherited closed payload verifier | PASS | 33 exact files; isolated import and projection preflight passed. |
| Effective SSH/host key | PASS | Three bounded successful calls to sole endpoint with pinned key; temporary credential files deleted. |
| Stable DUT identity | PASS | Hostname and machine-id matched; boot ID changed, which is informational. |
| Read-only PCI/driver ownership | BLOCKED | `xdma0` nodes map to foreign `0000:0b:00.0`; intended `0000:01:00.0` unbound. |
| Full task-specific closed-bundle admission | NOT_REACHED | Stopped at foreign-node safety prerequisite; no DUT deployment. |
| Exclusive controller/DUT locks | NOT_REACHED | No lock acquired or left behind. |
| Safe target JTAG/runtime disposition | NOT_REACHED | No JTAG or register access. |
| Qualified driver / FPGA activation / autoinit / reboot | NOT_REACHED | Foreign-node ownership blocks the governed path; zero attempts. |
| MMIO, telemetry, control scan, 1,000-scan campaign | NOT_REACHED | Zero scans; no NACK measurement. |
| Normal task cleanup | PASS | Read-only survey only; no task-owned hardware state to release. Foreign module untouched. |
| Publication | POST_COMMIT_RESPONSE | Commit and independent read-back are determined after this report is written. |

No recovered NACK or physical cause result is claimed. The inherited build and host results are not current DUT measurements.
