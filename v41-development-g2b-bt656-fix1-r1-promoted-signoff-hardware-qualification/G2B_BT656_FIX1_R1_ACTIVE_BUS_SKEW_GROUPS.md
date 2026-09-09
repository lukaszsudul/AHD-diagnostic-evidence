# Active relative bus-skew groups

Active groups: 1,2,3,4,5,6,7,8,10,11,12. Expected/executed/passed: 11/11/11. Violations: 0. Requirement per group: 3.000 ns. Each group was measured in an isolated temporary timing view using its unchanged exact object contract; raw reports, isolated XDC and object manifests are included under `raw/offline/BUS_SKEW_GROUPS/`.

| Group | Name | Actual ns | Slack ns | Result |
| --- | --- | --- | --- | --- |
| 1 | CFG_PCIE_TO_NVP | 1.208 | 1.792 | PASS |
| 2 | STATUS_NVP_TO_PCIE | 1.577 | 1.423 | PASS |
| 3 | DIAGNOSTIC_GRAY_TO_FIRST_STAGE | 1.130 | 1.870 | PASS |
| 4 | SNAPSHOT_GRAY_SOURCE_TO_AXI | 1.453 | 1.547 | PASS |
| 5 | SNAPSHOT_EPOCH_SOURCE_TO_AXI | 0.914 | 2.086 | PASS |
| 6 | HARD_EVENT_BASELINE_SOURCE_TO_AXI | 0.801 | 2.199 | PASS |
| 7 | SNAPSHOT_EPOCH_AXI_TO_SOURCE | 1.063 | 1.937 | PASS |
| 8 | TRANSPORT_AXI_TO_SOURCE | 2.154 | 0.846 | PASS |
| 10 | DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI | 1.149 | 1.851 | PASS |
| 11 | DESCRIPTOR_GENERATION_SOURCE_TO_AXI | 1.143 | 1.857 | PASS |
| 12 | DESCRIPTOR_EPOCH_SOURCE_TO_AXI | 1.923 | 1.077 | PASS |
