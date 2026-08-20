# Sample continuity report

The controlled evidence supports continuity of the delayed-reboot sample.

- Original and current boot ID: `20ce3f85-63d7-4d02-a3ad-9c87de8ad794`
- Endpoint: `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`, class `058000`
- Link: Gen1 x1
- BAR0/BAR1: 128 KiB / 64 KiB
- Driver binding: none
- `driver_override`: `(null)`
- Evidence repository remained at the original delayed-test commit before this task.
- No later controlled reboot, FPGA programming, PCI remove/rescan/reset, or Phase-3/Phase-4 action was found.

This proves continuity only within the recorded controlled environment; it does not claim independent physical surveillance.

    SAMPLE_CONTINUITY=SAMPLE_CONTINUITY_PROVEN
    SALVAGE_ALLOWED=YES_AT_CONTINUITY_GATE

