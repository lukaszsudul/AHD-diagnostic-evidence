# W4 A/B decision

**Scientific outcome: `INCONCLUSIVE_LOW_EVENTS_OR_INCOMPLETE`.** The complete comparable pilot contains no recovered first-attempt REGADDR_NACK in either arm. The observed rate difference is 0 per 1000 first entry-read opportunities; B/A is undefined because A=0. This does not establish a pause effect, a repair, or absence of an effect.

| Replica | OFF scans | ON scans | OFF events / opportunities | ON events / opportunities | OFF/ON per 1000 |
|---|---:|---:|---:|---:|---:|
| I | 64 | 64 | 0/5248 | 0/5248 | 0 / 0 |
| II | 64 | 64 | 0/5248 | 0/5248 | 0 / 0 |
| Total | 128 | 128 | 0/10496 | 0/10496 | 0 / 0 |

All 16 blocks completed 16/16 scans. Each scan evaluated 82 first entry reads and recorded 105 transactions. Other recovered causes, retries, and bank select/verify/restore/cleanup errors were all zero. The control scan is excluded from A/B denominators. Raw first-cause/event rows remain empty because no such events were observed; successful raw snapshots remain private with published hashes.

FPGA duration per scan: OFF 167.993888 ms, ON 171.293888 ms, difference +3.300000 ms. The duration difference is consistent with 11 successful bank writes and a 18,750-cycle pause at 62.5 MHz. It is not a measurement of analog SCL rise, SCL_WAIT_MAX, ACK phase, or physical cause. Both replicas ran on one card in one post-activation boot.

`SCL_WAIT_MAX=NOT_COLLECTED`; `ACK_PHASE_WAIT=NOT_COLLECTED`. The 10,000-scan gate is `NOT_RUN_NOT_WAIVED`.
