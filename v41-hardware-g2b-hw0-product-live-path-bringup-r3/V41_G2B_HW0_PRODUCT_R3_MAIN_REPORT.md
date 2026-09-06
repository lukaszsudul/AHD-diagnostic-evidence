# AHD v41 G2B-HW0-PRODUCT-R3 exact-driver live-path qualification

## Result

- Engineering gate: **FAIL**
- Evidence publication: **PASS**
- Overall result: **FAIL**
- First blocker: **FAIL — PRIOR_IMMUTABLE_ARTIFACT_BOUNDARY_VIOLATION**
- Final execution point: **HARD STOP BEFORE T1 INSMOD**

This published package records a governed stop. The exact sealed driver was
statically reverified, but it was never loaded. No automatic probe, device-node
creation, MMIO access, DMA read, or stream-control write occurred.

## Why the task failed

During the initial authenticated identity/lock sequence, a previously accepted
connection helper created ACL-restricted temporary password files under the
prior R1 controller artifact tree:

`C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\secret`

Every temporary password file was deleted in the helper's finally path; no
credential remains, no credential value entered R3 evidence, and no prior
evidence file was overwritten. The creation itself nevertheless crossed the
literal R3 prohibition on reusing prior R1 artifact storage. A later corrected
R3-local helper cannot repair that historical boundary crossing. The run
therefore stopped before the single authorized module-load attempt.

## Authority

- PROJECT_STATE_REV_AT_START / AT_END: `8 / 8`
- META-8A: `f92f4d8fcc0dc88d3dc5753c799e1d891846e392` — VERIFIED
- Recovery-4: `6843d582fd367fbc0edc0b1d55a9617162c489b0` — VERIFIED
- R2: `9caa9c339966eda999219e4ed686c01654b9a87e` — VERIFIED
- DRV1: `9aacc157dab5fe604faf66501b0129613b98ae2d` — VERIFIED
- PRODUCT source commit/tree:
  `92e9b3d914134c044371779def1ee18eaaeda98a` /
  `cf6bf82249c90782eab1978c68541ed9c0e6430b`
- PRODUCT bitstream SHA-256:
  `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`
- signed-off DCP SHA-256:
  `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`

The sealed chronology proves revision 8, the evidence remote head, and all four
predecessor manifests before the first authenticated DUT inventory. Full
candidate decoding and remote-reference recheck completed before JTAG. The
later 83-check audit independently repeated and materialized the same state.

## Technical T0

Technical T0 passed:

- authenticated `VCDE-DUT-1`, machine ID
  `0e90f50d9465492b80258da5658446f8`, IP `10.132.1.111`, kernel
  `7.0.0-29-generic`, architecture `x86_64`;
- boot ID `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac`;
- controller and Linux locks held through final state capture;
- no competing DUT/JTAG/XDMA hardware task;
- R3-local JTAG rerun: one target, one `xc7a35t`, index 0, IDCODE
  `0362D093`, DONE 1 in five samples, zero programming;
- exactly one endpoint `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`,
  class `058000`, upstream `0000:00:01.1`;
- exact modalias
  `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00`;
- endpoint/upstream link stable at `5.0 GT/s x1`;
- endpoint unbound; `driver_override` raw `(null)` is the unset sentinel;
- both XDMA modules absent, no `/dev/xdma*`, kernel taint `0`.

AER sysfs counter files were not exposed. No zero unavailable-counter claim is
made. Available endpoint/root-port status, link, and kernel-log evidence were
clean. A preserved V4 controller inventory failed closed on a transient
unrelated `ssh.exe`; V5 proved it did not reference or connect to the DUT.

## Driver and stopped gates

The exact module at
`/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko`
passed immediate static verification: size `3296104`, SHA-256
`E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`,
internal name `xdma_ahd_pcie`, x86-64, exact vermagic and one exact PCI alias.
Load attempts were `0`.

T1-T5 and the one-channel live-path execution were **NOT_REACHED**. There is no
runtime embedded identity, MMIO dump, record, frame, capture metric, or
throughput measurement. Hardware qualification of the one-channel path and the
project-level 288 MB/s requirement remain `NOT_PROVEN`.

The offline T1 trio was never copied to or run on the DUT. Its hashes,
nonexecution receipt, and review findings are retained; unsafe source bodies
are excluded from public evidence.

## Final controlled state

The final live read-only receipt recorded clean pre-load state: modules/nodes
absent, endpoint present and unbound at Gen2 x1, taint `0`, and zero module,
MMIO, DMA, programming, reboot, or power-cycle operations. The Linux lock was
released, then the controller lock was released last. The last JTAG DONE
observation was `1` at `2026-09-06T14:55:47Z`; it was not re-read in the
15:18 final snapshot.

No `.ko`, credential, raw log, raw video, frame, or reconstructed image is in
this public package.

## Evidence publication

- required initial commit message:
  `Run AHD v41 G2B-HW0 PRODUCT R3 exact-driver live-path qualification`
- initial evidence commit:
  `e277c22e14a8fd42c12b70d223db94c0763deac4`
- commit-pinned remote read-back: `PASS`
- checked UTC: `2026-09-06T16:11:22.397776+00:00`
- files / manifest entries: `67 / 66`
- missing files / size mismatches / SHA-256 mismatches: `0 / 0 / 0`
- initial manifest SHA-256:
  `12C9EAD435A13E4B4E48AFEF3E731D55F2E92039ECF3E8FD9E4837A05006E4AC`

The completion commit is the commit containing this receipt. Its final
commit-pinned read-back is recorded externally to avoid self-reference.

## Qualification boundary

`ONE_CHANNEL_FIXED_LIVE_AHD_PATH_HARDWARE_PASS` is not claimed. Four-input
selection and two-channel capture are not qualified; synthetic generation and
V4L2 were not tested; `release/v41.0.0` was not created. SSOT was not modified
and no META promotion is warranted.
