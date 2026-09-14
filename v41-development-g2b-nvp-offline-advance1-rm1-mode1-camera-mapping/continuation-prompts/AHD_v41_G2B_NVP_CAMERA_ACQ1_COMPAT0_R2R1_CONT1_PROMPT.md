# AHD v41 — G2B-NVP-CAMERA-ACQ1-COMPAT0-R2R1-CONT1

## Purpose

Resume the already offline-qualified CH1 two-register slice/format campaign
after DUT network reachability is restored. This continuation reuses the
existing candidate and runtime bundle. It performs no source change and no
build.

This prompt authorizes a future hardware task. It is not authorization to run
while the DUT remains unreachable.

## Exact protected inputs

Source:

```text
branch: diag/v41-g2b-nvp-camera-acq1-compat0
commit: dae2aff60141ecdbc0afac08fc0df9a3166f66c6
tree: 21e33d481ef637667756caa8015e7fa1b1dd8ebf
```

Offline sign-off:

```text
run root:
C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_20260912T121125Z

signed-off routed DCP SHA-256:
EE0982524E8C6E5B1395836BEF55130FC6914C9C9BFE47731C09D7621CD86BDC

bitstream:
C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_20260912T121125Z\signoff\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_SLICE_FORMAT_GATE.bit

bitstream size:
2192144

bitstream SHA-256:
CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B

runtime bundle archive:
C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_20260912T121125Z\hardware\upload\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_RUNTIME_BUNDLE.tar.gz

runtime bundle archive SHA-256:
5F84DA282834AB4AFBD4B6375998D87C302E9EF4BAC5DE8A098C6E57E5344799

runtime bundle aggregate identity SHA-256:
699895BEE2F40C9561C93F463062987E430C99A61AC7336487BCBBCD818B210B

continuation state:
C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_20260912T121125Z\reports\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONTINUATION_STATE.json
```

Re-hash every protected local input before first DUT contact. Stop on any
mismatch. Do not rebuild or regenerate any protected input.

## Resume point

The recorded first blocker is exactly:

```text
DUT_SSH_ENDPOINT_UNAVAILABLE
```

Resume at:

```text
REMOTE_DUT_ROOT_BOOTSTRAP
```

Do not repeat synthesis, implementation, sign-off, bitstream generation,
local runtime-bundle construction, or the local isolated-import gate.

## Authority boundary

Authorized after network reachability is proven:

- one fresh task-local controller lock and one fresh DUT hardware lock;
- one fresh DUT artifact root using the established atomic bootstrap method;
- upload and exact verification of the existing closed runtime bundle;
- exact candidate activation only after all identity and quiescence gates;
- the bounded CH1 two-register campaign;
- read-only format classification;
- mandatory exact rollback after any functional write;
- evidence collection and cleanup.

Not authorized:

```text
source edits
build or rebuild
Flash programming
second FPGA programming attempt
generic host I2C
register/value supplied by the host
MODE1
EQ
ACP/coax
CH2-CH4 writes
DMA video capture
RM1
driver recovery outside the already qualified exact path
reboot or power-cycle
retry after a failed identity, programming, I2C or rollback gate
PRODUCT or SSOT/META change
```

Stop at the first failed or unauthorized gate.

## Fresh-contact and deployment gates

1. Prove SSH reachability once, then create a fresh DUT root. Never reuse a
   prior remote artifact directory.
2. Acquire fresh locks and prove no parallel AHD/HDMI hardware activity.
3. Record boot identity, PCI function identity, exact qualified driver
   path/hash/modalias, current module ownership, processes and locks.
4. Require stream disabled, AIO `0`, DMA inactive and the ring quiescent before
   activation or any NVP action.
5. Upload the archive and verifier into the fresh DUT root.
6. Verify archive SHA-256, extract locally inside that root, verify the bundle
   manifest, local-only import closure, module origins and negative missing-
   dependency test. Hardware access remains prohibited until this gate passes.
7. Immediately before programming, re-hash the candidate and require the exact
   SHA-256 above. Permit exactly one SRAM programming attempt. Flash remains
   prohibited.
8. Read back `MAGIC`, `VERSION`, `CAPABILITIES`, all five source SHA words and
   exact profile flags. Any mismatch is a hard stop before functional writes.

## Exact campaign

Use only the closed-bundle controller:

```text
g2b_nvp_camera_acq1_compat0_r2r1_controller.py
```

The controller, not an interactive operator, owns the complete bounded
sequence. The host can select only the compiled campaign modes; it cannot send
bank/register/value tuples.

1. Run the controller self-test and pre-camera read-only gate.
2. At the explicit human gate, connect the known powered camera to the same
   tested physical connector instance. Record camera/cable identity and do not
   infer its format from a sales label.
3. Start one connected campaign.
4. Capture the stable CH1 baseline. If NOVID is already stably `0`, perform no
   slice write and proceed directly to read-only format identification.
5. If NOVID is stably `1`, require exact full-byte baseline authority for only:

   ```text
   Bank5/0x08
   Bank5/0x05
   ```

6. Execute at most the compiled sequence:

   ```text
   0x08=0x50 then 0x05=0xA4
   0x08=0x40 then 0x05=0xA4
   0x08=0x60 then 0x05=0xA4
   ```

   Each pair is atomic, uses Bank5 only, has the frozen readback gates and
   stops the sweep immediately when NOVID becomes stably `0`.
7. Collect at least three coherent read-only format snapshots and apply only
   the frozen format-decision manifest.
8. Classify exactly one terminal outcome:

   ```text
   AHD_1080P25_CONFIRMED
   OTHER_FORMAT_CONFIRMED
   SIGNAL_PRESENT_FORMAT_UNRESOLVED
   NO_SIGNAL_AFTER_BOUNDED_SLICE_CAMPAIGN
   ```

9. After any functional write, always execute the frozen reverse-ledger exact
   rollback, verify the restored bytes and entry bank, then collect three
   matching post-rollback SCAN1 control snapshots.
10. Stop after format classification and rollback. Do not enter MODE1, EQ,
    BT.656 capture or any broader NVP action in this task.

On NACK, timeout, readback mismatch, stale generation, MMIO failure or host
abort, invoke only the bounded rollback already implemented by the controller.
If rollback cannot be proven, stop, preserve state/evidence/locks and request
Owner direction. Do not retry a functional write.

## Evidence and hard stop

Persist all raw numeric register snapshots, action/result ledgers, hashes,
runtime identity, programming receipt, format-decision inputs, rollback proof
and final quiescent state. Do not publish camera imagery, raw video, bitstream,
DCP, driver, credentials, vendor source or vendor PDFs.

Release the DUT hardware lock only after safe final state is proven. Release
the local controller lock last.

Final execution point:

```text
HARD STOP AFTER COMPAT0-R2R1 CH1 TWO-REGISTER FORMAT CLASSIFICATION AND ROLLBACK
```

If and only if the terminal result is `AHD_1080P25_CONFIRMED`, the Owner may
start a separately qualified MODE1 hardware task. Otherwise report the exact
camera/format/analog authority gap; do not broaden the write set.
