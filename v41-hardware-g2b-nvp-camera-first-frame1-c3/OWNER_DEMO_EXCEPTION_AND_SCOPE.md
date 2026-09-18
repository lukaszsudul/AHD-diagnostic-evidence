# FIRST-FRAME1 Owner decision and limits

Task: `CONT1R3R4R8-FIRST-FRAME1-C3`.

The Owner explicitly authorized one bounded attempt to obtain a real CH1 camera frame through the existing C3-PNR1 C2H path, before the separate 10,000-scan reliability qualification. This exception applies only to this task and does not promote the product or change SSOT.

```text
TEN_THOUSAND_SCAN_QUALIFICATION = NOT_RUN
FIRST_FRAME_DEMO_BEFORE_10000 = OWNER_AUTHORIZED_SCOPED_EXCEPTION
PRODUCT_RELIABILITY_QUALIFICATION = NOT_CLAIMED
W4_PAUSE_EFFECT = INCONCLUSIVE_LOW_EVENTS
W3A_PAUSE_POLICY_THIS_TASK = OFF
```

Authorized ceilings: at most 30 new complete SCAN1 scans; one ordered ACQ level sequence `0x50 -> 0x40 -> 0x60`, each level at most once and only when its existing gates pass; one C2H stream-enable session ending on the first complete frame or a 10-second/32-MiB limit including drain; at most two existing functional rollback attempts if needed. No repeat capture after a timeout or hardware error.

The task permits existing CH1 ACQ operations and existing transport controls only within their frozen contracts. It permits private binary transfer of raw data and PNG to the Windows controller and append-only publication of receipts without pixels.

New XSim, FPGA build, SRAM programming, DUT reboot or power cycle, driver modification, generic host I²C, H2C, electrical rework, alternate camera routing, MODE1, and W3a pause ON are outside scope. The existing C3 image must be reused exactly. The physical `FIRST_FRAME1_CAMERA_READY_GATE` requires explicit current confirmation from the Owner before CH1 scans or capture.
