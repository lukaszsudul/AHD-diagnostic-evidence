# AHD v41 G2B-NVP-CAMERA-SCAN1-R1 Read-Only Oneshot Four-Channel Register Scanner, Verified Bank-Atomic I2C Arbitration, Immutable BAR Snapshot, Fresh Diagnostic Build and Camera Connect/Disconnect Detection Qualification

Engineering gate:
BLOCKED

Evidence publication:
PASS

Overall result:
BLOCKED

PROJECT_STATE_REV:
8 — OWNER_ATTESTED_NOT_REVERIFIED

SCAN0 started in a new clean Codex window:
YES

SCAN1 continued in the same SCAN0 window:
YES

Prior pre-SCAN0 conversation context required:
NO

Owner SCAN1 implementation authorization:
GRANTED

Owner SCAN1 build/sign-off authorization:
GRANTED

Owner SCAN1 hardware authorization:
GRANTED_AFTER_OFFLINE_SIGNOFF

Owner physical camera campaign authorization:
GRANTED_WITH_EXPLICIT_HUMAN_GATES

Future ACQ1 compatibility campaign:
CONDITIONALLY_AUTHORIZED_AFTER_SCAN1_PASS_AND_CREDIBLE_SIGNAL_CANDIDATE

ACQ1 functional writes executed in SCAN1-R1:
NO

Product branch modified:
NO

Product profile scanner elaborated:
NO

Product profile executor elaborated:
NO

Diagnostic branch:
diag/v41-g2b-nvp-camera-scan1

Diagnostic source parent:
fc37d815b5d64ef90dfbd99c57ae4cc09567b56f

SCAN1 source commit:
c7e16fa3da26545cef960a6c75427a3614c4b655

SCAN1 source tree:
56526e17154f8e06f3eb4b95233934c18b6ee06e

SCAN1 branch publication:
PASS

FPGA source changed:
YES_DIAGNOSTIC_BRANCH_ONLY

PRODUCT source changed:
NO

Transport ABI changed:
NO

PRODUCT MMIO changed:
NO

NVP functional configuration changed:
NO

Generic host NVP I2C writes:
PROHIBITED_AND_ABSENT

SCAN1 mode:
READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT

I2C master reused:
YES

I2C frequency:
25000 Hz

Read manifest entries:
82/82

Bank groups:
10/10

Read-side-effect prohibited entries present:
0

Unresolved-semantics entries:
40/40

A8_PRE/A8_POST:
PRESENT

Entry-bank save/restore:
PASS_OFFLINE_ONLY

Bank-select readback:
PASS_OFFLINE_ONLY

Expected clean transactions:
105

Observed clean transactions:
N/A_NOT_REACHED_IN_HARDWARE

MMIO range:
0x12000..0x123FF

Legacy DIAG1 core elaborated in SCAN1 profile:
NO

ACQ1 executor elaborated in SCAN1 profile:
NO

Simulation and host gate:
24/24

Fresh synthesis:
PASS

Fresh implementation:
PASS

Fully routed:
YES

WNS:
0.094 ns

TNS:
0.000 ns

WHS:
0.035 ns

THS:
0.000 ns

Internal unconstrained endpoints:
0

CDC disposition:
PASS

New unresolved critical CDC:
0

New unresolved warning CDC:
0

Active bus-skew groups:
11/11

Promoted replacement checks:
17/17

DRC:
PASS

Methodology:
PASS

Diagnostic LUT:
18517/20800 (89.024%)

Diagnostic FF:
20416/41600 (49.077%)

Diagnostic BRAM:
27/50 (54.000%)

Diagnostic DSP:
0/90 (0.000%)

Resource gate:
PASS

SCAN1 bitstream:
C:\FPGA\G2B_NVP_CAMERA_SCAN1_R1_20260911T152909Z\signoff\G2B_NVP_CAMERA_SCAN1_R1_READONLY_ONESHOT.bit

SCAN1 bitstream SHA-256:
6DACBFFF9B6DA0A904B2A49B18C9BA59695DBA04B834A8A758AD44184769443E

FPGA SRAM programming:
NOT_REACHED

Programming attempts:
0

Flash programming:
NO

Warm reboot:
0

Power-cycle:
NO

Driver load:
NOT_REACHED

PCIe endpoint:
N/A

PCIe Gen2 x1:
NOT_REACHED

Runtime scanner identity:
NOT_REACHED

Scanner MAGIC:
N/A

Scanner VERSION:
N/A

Scanner CAPABILITIES:
N/A

Runtime entry count:
0/82

Runtime bank-group count:
0/10

MMIO WRITE→READ sanity:
0/16

Post-write 0xFFFFFFFF reads:
N/A

Post-write timeouts:
N/A

Single-scan integrity:
NOT_REACHED

Single-scan generation:
N/A

Single-scan entry count:
0/82

Single-scan transaction count:
0/105

Single-scan entry bank:
N/A

Single-scan exit bank:
N/A

Single-scan bank restore:
NOT_REACHED

256-scan repetition:
0/256

256-scan NACK count:
N/A

256-scan timeout count:
N/A

256-scan bank-verify failures:
N/A

256-scan incomplete publications:
N/A

256-scan snapshot mutations:
N/A

Measured scan duration minimum:
N/A

Measured scan duration maximum:
N/A

Measured scan duration mean:
N/A

Measured I2C occupancy:
N/A

Video/DMA noninterference:
NOT_REACHED

Reference capture:
NOT_RUN

Overlapped scanner/capture:
NOT_RUN

Post-scan capture:
NOT_RUN

Physical campaign phase A:
NOT_REACHED

Baseline scans:
0/5

Physical campaign phase B:
NOT_REACHED

Connected scans:
0/10

Physical campaign phase C:
NOT_REACHED

Return-control scans:
0/5

Physical connector label:
UNKNOWN

Accepted campaign scans:
0/20

Scans excluded by A8 bookend change:
0

Campaign scanner NACK count:
0_NOT_EXECUTED

Campaign scanner timeout count:
0_NOT_EXECUTED

Campaign bank-restore failures:
0_NOT_EXECUTED

Channels with credible connected-phase response:
NONE_NOT_TESTED

Primary responding logical channel:
UNRESOLVED

NOVID transition observed:
UNRESOLVED

Stable detector tuple observed:
UNRESOLVED

Stable raw F0 code:
NONE

Agreeing stable snapshots:
0

Detected-format scientific classification:
PHYSICAL_CAMPAIGN_NOT_COMPLETED

Disconnected → connected response:
NOT_REACHED

Connected → disconnected return:
NOT_REACHED

Physical connector-to-logical-channel mapping candidate:
UNRESOLVED

ACQ1 compatibility condition opened:
NO

ACQ1 functional writes executed:
NO

Scanner busy at final state:
NO_NOT_ELABORATED_IN_RUNNING_IMAGE

Snapshot acknowledged or preserved:
N/A_NOT_REACHED

Entry bank restored at final state:
NOT_REACHED

Stream disabled at end:
NOT_OPENED_BY_THIS_TASK

Physical quiescence:
PASS_NO_TASK_HARDWARE_ACTIVATION

Final pending AIO:
N/A_DEVICE_NODES_ABSENT

Driver unloaded:
NOT_LOADED

XDMA nodes removed:
NOT_CREATED

Fresh locks released:
YES

Final FPGA runtime profile:
PREVIOUS_PROFILE_UNCHANGED

Vendor PDF published:
NO

Reference-driver source published:
NO

Camera image pixels published:
NO

NVP persistent state changed:
NO

PRODUCT source changed:
NO

SSOT changed:
NO

META performed:
NO

Evidence repository:
lukaszsudul/AHD-diagnostic-evidence

Evidence directory:
v41-hardware-g2b-nvp-camera-scan1-r1-readonly-oneshot-detection

Evidence commit:
SELF_COMMIT_SHA_REPORTED_BY_COMMIT_PINNED_REMOTE_READBACK

Remote read-back:
PASS_REQUIRED_BEFORE_FINAL_CLAIM

Main report:
V41_G2B_NVP_CAMERA_SCAN1_R1_MAIN_REPORT.md

Physical Owner action required:
NONE_HARDWARE_BLOCKER_PRECEDED_OWNER_GATE

First blocker:
DUT_LOCK_ACQUIRE_DID_NOT_REACH_PASS: mkdir: No such file or directory

Working causal model:
The fresh DUT lock directory was created and its receipt proved this task as owner, but the task root remained absent. The next literal mkdir targeted a nested path whose intermediate task-family directory was absent, so the task-local acquisition harness exited before DUT_LOCK_ACQUIRE=PASS. This is an operational lock/preparation blocker; no JTAG, PCIe device node, MMIO, NVP, DMA, driver, reboot or programming action followed.

Recommended next step:
Open a new governed run. Correct the task-local DUT-root creation command before first contact, create wholly fresh controller/DUT locks and a fresh remote root, then repeat the hardware activation from its first gate. Do not reuse this run's failed acquisition receipt as a PASS and do not treat the offline-qualified candidate as hardware-qualified.

Final execution point:
HARD STOP AT FIRST FAILED AHD V41 G2B-NVP-CAMERA-SCAN1-R1 HARDWARE LOCK GATE
