from __future__ import annotations

import argparse
import csv
import hashlib
import json
import shutil
from pathlib import Path


TASK_ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R1_20260905")
REPO_ROOT = Path(r"C:\FPGA\V41_G2B_EVIDENCE")
DIR_NAME = "v41-hardware-g2b-hw0-product-live-path-bringup-r1"
OUT = REPO_ROOT / DIR_NAME
BLOCKER = "BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE"
BIT_SHA = "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7"
DCP_SHA = "95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175"
SOURCE_COMMIT = "92e9b3d914134c044371779def1ee18eaaeda98a"
SOURCE_TREE = "cf6bf82249c90782eab1978c68541ed9c0e6430b"
RUNTIME_SHA = "224d194e5f82c85bcb29297561c5d5e76d28063b"
BUILD_FLAGS = "0x00000103"
REQUIRED_COMMIT_MESSAGE = "Run authorized AHD v41 G2B-HW0 PRODUCT live-path bring-up R1"


def write_text(name: str, text: str) -> None:
    (OUT / name).write_text(text.strip() + "\n", encoding="utf-8", newline="\n")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def copy_inputs() -> None:
    if OUT.exists():
        raise SystemExit(f"REFUSE_OVERWRITE:{OUT}")
    OUT.mkdir()
    shutil.copytree(TASK_ROOT / "raw", OUT / "raw")
    shutil.copytree(
        TASK_ROOT / "tools",
        OUT / "tools",
        ignore=shutil.ignore_patterns(
            "__pycache__", "*.pyc", "Invoke-G2BR1Plink.ps1"
        ),
    )
    accepted = OUT / "tools" / "accepted"
    accepted.mkdir()
    source = Path(
        r"C:\FPGA\AHD_G1_EVIDENCE\_agent_evidence_20260827_164925"
        r"\v41-nvp-r1e-extended-observability-r1\r6\scripts"
    )
    shutil.copy2(source / "select_r6_jtag_target.tcl", accepted)
    shutil.copy2(source / "r6_jtag_stability_session.tcl", accepted)


def result_block(publication: str, remote: str) -> str:
    return rf"""
| Field | Result |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `{publication}` |
| Overall result | `BLOCKED` |
| T0 candidate/environment gate | `PASS` |
| T1 SRAM/endpoint gate | `BLOCKED` |
| T2 runtime/MMIO gate | `NOT_REACHED` |
| T3 one-record gate | `NOT_REACHED` |
| T4 finite-capture gate | `NOT_REACHED` |
| T5 continuous-capture gate | `NOT_REACHED` |
| Remote read-back | `{remote}` |
| First blocker | `{BLOCKER}` |
| Final execution point | `HARD STOP AFTER G2B-HW0-PRODUCT-R1 LIVE-PATH BRING-UP` |
""".strip()


def main_report(publication: str, remote: str, initial_commit: str | None) -> str:
    publication_detail = (
        "The initial evidence commit and commit-pinned byte read-back are recorded in "
        "`G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md`."
        if publication == "PASS"
        else "Publication is sealed locally and awaits the containing commit, non-force push, and commit-pinned byte read-back."
    )
    initial_line = initial_commit or "PENDING_CONTAINING_GIT_COMMIT"
    evidence_commit = "CONTAINING_COMPLETION_COMMIT" if publication == "PASS" else "PENDING"
    return rf"""
# AHD v41 G2B-HW0-PRODUCT-R1 Exact Candidate Live-Path Bring-Up

## Result

{result_block(publication, remote)}

The exact offline-qualified PRODUCT candidate was programmed once into volatile
SRAM. The command returned successfully and `DONE=1` was confirmed immediately
and again in five independent final samples. The AHD PCIe endpoint did not
return during the bounded automatic-recovery interval. Read-only feasibility
checks then proved that no exact AHD-only root-port or endpoint subtree was
available for the one conditionally authorized recovery operation. Execution
therefore stopped before any PCIe write, driver bind, MMIO access, or DMA.

## Authority and immutable inputs

- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- META-8A: `VERIFIED`; evidence commit
  `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`.
- Previous blocked HW0 evidence: `VERIFIED`; final evidence commit
  `be8e5c6a875d5f4c21717d1fa8b5ae6419d3f8c2`.
- Recovery-4 evidence commit:
  `6843d582fd367fbc0edc0b1d55a9617162c489b0`.
- `G2B-LUT1 = ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- `G2B-HW0-PRODUCT = AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Initial source: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- META-8A state: `PROMOTED / VERIFIED`.
- SSOT, META-8A, Recovery-4, and previous-HW0 manifests verified respectively
  `18/18`, `32/32`, `181/181`, and `11/11`, with zero mismatches.
- Owner hardware authorization: `GRANTED`.
- Additional legacy-MMIO read authorization: `GRANTED` for aligned reads only
  in `0x0000..0x0030` and `0x0080..0x00B4` after T1.
- Legacy-MMIO write authorization: `DENIED`.
- Documented G2B control access was authorized only in `0x3800..0x3BFF`; T2
  was not reached, so no G2B access occurred.

The authoritative source worktree `C:\FPGA\V41_G2B` was tracked-clean at
branch `integration/v41-g2b-onech-c2h`, commit `{SOURCE_COMMIT}`, tree
`{SOURCE_TREE}`, with the remote branch at the same commit. The exact PRODUCT
bitstream is 2,192,144 bytes with SHA-256 `{BIT_SHA}`. The signed-off DCP is
15,726,324 bytes with SHA-256 `{DCP_SHA}`. Their local paths and rehashes are
recorded in `G2B_HW0_PRODUCT_R1_CANDIDATE_VERIFICATION.md`.

The pre-program authority checks were completed in the executing task before
T0. `raw/LOCAL_AUTHORITY_VERIFICATION.log` is a post-hardware read-only replay
at `2026-09-05T22:21:45Z`; it proves the protected static state was preserved
after execution and does not claim an earlier capture timestamp.

## T0 and board ownership

The authenticated DUT was `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`,
machine ID `0e90f50d9465492b80258da5658446f8`, user `vcdeagent1`, kernel
`7.0.0-29-generic`, and boot ID
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`. Host-key pinning and sanitized
credential handling passed. Fresh process checks found no competing JTAG,
Vivado, XDMA, or capture owner. Exact Windows and Linux task locks were held
before programming and released only after final-state capture.

Fresh JTAG selection found exactly one target,
`localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`, and one device at chain
index 0: `xc7a35t`, IDCODE `0362D093`, 6 MHz. Five pre-program samples all
reported `DONE=0`. Accepted historical binding evidence correlates this exact
cable/device/DUT to AHD endpoint `0000:01:00.0`, parent `0000:00:01.1`,
`10ee:7011`, subsystem `10ee:0007`, class `058000`. That binding was used only
for T0 physical-board correlation; it was not used to claim that a current
endpoint existed. T0 passed.

This was a fresh T0 correlation decision: the current JTAG and PCIe inventories
were combined with the accepted physical binding because an unprogrammed
`DONE=0` FPGA exposes no live endpoint. The accepted binding sources were
reviewed in the executing task before T0. The later
`raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log` is a post-run hash replay
of those same sources, not a claim that a live endpoint existed before program.

## One authorized SRAM program

- Program start: `2026-09-05T22:03:58Z`.
- Command returned/end: `2026-09-05T22:04:05Z`.
- Program invocations: `1`; retry count: `0`.
- Target/device: exact selector above, `xc7a35t`, IDCODE `0362D093`.
- Vendor startup result: `HIGH`.
- Immediate result: `PROGRAM_TCL_RESULT=PASS_DONE_1` and `DONE=1`.
- Final independent JTAG session: five of five samples `DONE=1`, ending
  `2026-09-05T22:14:31Z`.
- Flash, CFGMEM, and PROGRAM_B operations: `0`.

## Endpoint recovery and first blocker

The bounded automatic wait ran from `2026-09-05T22:05:55Z` through
`2026-09-05T22:06:26Z`; `AUTO_RECOVERY_FOUND=0`. No Xilinx/AHD endpoint and no
XDMA node appeared.

Fresh read-only recovery feasibility then established:

- accepted AHD root function `0000:00:01.1` was absent from PCI config and
  sysfs;
- `0000:00:01.0` was an AMD Phoenix Dummy Host Bridge, so its rescan was not
  proven AHD-only;
- the current external tree was `0000:00:02.1` to AMD switch upstream
  `0000:01:00.0`, then seven downstream ports serving buses 03 through 09;
- several downstream branches were empty and several contained unrelated
  Ethernet, USB, or SATA devices, with no slot map and no evidence selecting
  one branch as AHD;
- endpoint-specific reset/remove was impossible because the endpoint was
  absent.

Rescanning the root/current switch would have covered an unrelated-device
subtree, while choosing an empty downstream port would have been guesswork.
No recovery write was issued. The required first blocker is therefore
`{BLOCKER}`. T1 is `BLOCKED`; the actual AHD endpoint check is `FAIL` because
the post-program endpoint was sought and remained absent. PCIe Gen2 x1, exact
XDMA mapping, and T2 through T5 are `NOT_REACHED`.

## Runtime and capture disposition

The governed offline runtime expectations remain embedded Git SHA
`{RUNTIME_SHA}` and `BUILD_FLAGS={BUILD_FLAGS}`. They were not read from
hardware. Dual-layer identity, transport ABI, PRODUCT profile, legacy identity
MMIO, NVP/video telemetry, MMIO baseline, NVP initialization, fixed live
source, first record, finite capture, frame reconstruction, and continuous
capture are all `NOT_REACHED`.

No first-record or frame payload was created. Their hashes are `NONE`, and
their local paths are `N/A`. There is no claim about a 4096-byte record,
header, payload, padding, sequence, epoch, frame, live-video validity, internal
AXI `TKEEP`/`TLAST`, or throughput.

## Final state and protection

The exact programmed candidate remains in volatile SRAM by the unbroken
programming chain, and final JTAG reads show `DONE=1`. The AHD endpoint is
absent; its BDF, vendor/device, LnkCap, and LnkSta are `N/A`. The `xdma` module
is not loaded, the xdma driver sysfs directory is absent, and the XDMA node
count is zero. Last MMIO state is `NOT_REACHED_NO_MMIO_ACCESS`; the G2B stream
was never enabled. Both task locks were released after this state was captured.

`C:\FPGA\FPGA_AHD`, tracked source in `C:\FPGA\V41_G2B`, active XDC, SSOT,
Flash, driver files, package state, reboot state, and power state were not
modified. The task performed zero PCI config writes, rescans, resets, MMIO
reads, MMIO writes, and DMA captures. `HARDWARE_THROUGHPUT_288_MB_S` remains
`NOT_PROVEN`; four-input selection and two-channel capture are `NOT_QUALIFIED`;
the PRODUCT synthetic generator remains `NO`; V4L2 was not tested; and
`release/v41.0.0` was not created. `G2B-HW qualification = NOT_PROVEN` and
`SSOT_UPDATE_REQUIRED = NO`.

## Evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `{DIR_NAME}`.
- Required initial commit message: `{REQUIRED_COMMIT_MESSAGE}`.
- Initial evidence commit: `{initial_line}`.
- Push mode: ordinary non-force.

{publication_detail}

## Final-response field ledger

| Field | Exact value |
|---|---|
| Engineering gate | `BLOCKED` |
| Evidence publication | `{publication}` |
| Overall result | `BLOCKED` |
| PROJECT_STATE_REV_AT_START / END | `8 / 8` |
| META-8A / previous blocked HW0 evidence | `VERIFIED / VERIFIED` |
| Owner hardware authorization | `GRANTED` |
| Additional legacy MMIO read / legacy MMIO write | `GRANTED / DENIED` |
| Authoritative Linux DUT | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Authenticated connection / exclusivity | `PASS / PASS` |
| Source worktree / commit | `C:\FPGA\V41_G2B / {SOURCE_COMMIT}` |
| PRODUCT bitstream / SHA-256 | `VERIFIED / {BIT_SHA}` |
| Signed-off DCP / SHA-256 | `VERIFIED / {DCP_SHA}` |
| JTAG-to-PCIe board correlation | `PASS` at T0 from accepted physical binding |
| FPGA device | `xc7a35t / 0362D093 / chain index 0` |
| SRAM / Flash programming | `PASS / NO` |
| DONE | `1` |
| AHD endpoint / BDF | `FAIL / N/A` |
| PCIe vendor-device / LnkCap / LnkSta | `N/A / N/A / N/A` |
| PCIe Gen2 x1 / XDMA driver | `NOT_REACHED / NOT_REACHED` |
| XDMA version-hash / user / C2H | `N/A / N/A / N/A` |
| Runtime embedded GIT_SHA / BUILD_FLAGS | `N/A / N/A` |
| Expected runtime GIT_SHA / BUILD_FLAGS | `{RUNTIME_SHA} / {BUILD_FLAGS}` |
| Dual-layer identity / transport ABI / ABI version | `NOT_REACHED / NOT_REACHED / N/A` |
| PRODUCT / legacy / NVP / baseline MMIO | `NOT_REACHED / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| NVP initialization / NACK count / INIT_ERROR | `NOT_REACHED / N/A / N/A` |
| Fixed live source | `NOT_REACHED` |
| T0 / T1 / T2 / T3 / T4 / T5 | `PASS / BLOCKED / NOT_REACHED / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| First record bytes / SHA / header / payload / padding | `N/A / NONE / NOT_REACHED / NOT_REACHED / NOT_REACHED` |
| Finite requested / received | `2500 / N/A` |
| Finite gaps / duplicates / padding errors / epoch changes | `N/A / N/A / N/A / N/A` |
| Frame reconstruction / SHA | `NOT_REACHED / NONE` |
| Continuous duration / records / records per second | `N/A / N/A / N/A` |
| Estimated frame rate / application payload / transport throughput | `N/A / N/A / N/A` |
| Malformed / unexplained gaps / formatter fatal / ownership fatal | `N/A / N/A / N/A / N/A` |
| One-channel live AHD path | `NOT_REACHED` |
| Hardware throughput >=288 MB/s | `NOT_PROVEN` |
| Four-input / two-channel | `NOT_QUALIFIED / NOT_QUALIFIED` |
| Synthetic generator / V4L2 / release | `NO / NOT_TESTED / NOT_CREATED` |
| Final FPGA state | Exact candidate last programmed to volatile SRAM; `DONE=1` |
| Final PCIe/driver state | AHD absent; xdma unloaded; zero nodes; no binding |
| Persistent state / reboot / power-cycle | `NO / NO / NO` |
| Hardware accessed | `YES` |
| G2B-HW0-PRODUCT / G2B-HW qualification | `BLOCKED / NOT_PROVEN` |
| SSOT update required | `NO` |
| Evidence repository / directory | `lukaszsudul/AHD-diagnostic-evidence / {DIR_NAME}` |
| Evidence commit | `{evidence_commit}` |
| Remote read-back | `{remote}` |
| Main report | `C:\FPGA\V41_G2B_EVIDENCE\{DIR_NAME}\V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md` |
| First blocker | `{BLOCKER}` |

## Recommended next action

Owner-authorize one controlled warm reboot of `VCDE-DUT-1` in a new governed
hardware run so the accepted `0000:00:01.1 -> 0000:01:00.0` AHD path can be
re-enumerated and freshly verified before any MMIO or DMA action.
"""


AUTHORIZATION = rf"""
# G2B-HW0-PRODUCT-R1 Authorization Receipt

## Exact grants and denials

| Contract field | Value |
|---|---|
| `OWNER_HARDWARE_AUTHORIZATION` | `GRANTED` |
| `ADDITIONAL_LEGACY_MMIO_READ_AUTHORIZATION` | `GRANTED` |
| Authorized legacy read range 1 | `0x0000..0x0030`, aligned read-only |
| Authorized legacy read range 2 | `0x0080..0x00B4`, aligned read-only |
| `LEGACY_MMIO_WRITE_AUTHORIZATION` | `DENIED` |
| G2B page | `0x3800..0x3BFF`, documented controls only |
| SRAM programming | Exactly one invocation of the verified candidate |
| PCIe recovery | At most one exact AHD-only targeted operation, conditionally |
| XDMA binding | At most one exact BDF bind, conditionally |
| Flash / reboot / power-cycle | `DENIED` / `DENIED` / `DENIED` |

Legacy and G2B accesses were contingent on T1. T1 blocked before a mapped AHD
user device existed, so the granted legacy reads and G2B controls were not
used. Reserved G2B offsets were not written.

## Actual operation accounting

| Operation | Count/result |
|---|---|
| FPGA SRAM programs | `1` |
| Automatic program retries | `0` |
| Flash / CFGMEM / PROGRAM_B operations | `0 / 0 / 0` |
| Automatic endpoint wait | `1`, read-only, no endpoint |
| Targeted PCIe recovery operations | `0` |
| PCI config writes / rescans / resets | `0 / 0 / 0` |
| XDMA module loads / unloads / exact binds | `0 / 0 / 0` |
| Legacy MMIO reads / writes | `0 / 0` |
| G2B MMIO reads / writes | `0 / 0` |
| DMA captures | `0` |
| Reboots / power-cycles | `0 / 0` |

Execution honored the mandatory stop literal `{BLOCKER}`. The verified
candidate was left in volatile SRAM, `DONE=1`; no rollback image was loaded.
"""


CANDIDATE = rf"""
# G2B-HW0-PRODUCT-R1 Candidate Verification

Result: `PASS`

## Governance

- `PROJECT_STATE_REV_AT_START = 8`
- `PROJECT_STATE_REV_AT_END = 8`
- SSOT manifest: `18/18 PASS`.
- META-8A manifest: `32/32 PASS`; commit
  `f92f4d8fcc0dc88d3dc5753c799e1d891846e392`.
- Recovery-4 manifest: `181/181 PASS`; evidence commit
  `6843d582fd367fbc0edc0b1d55a9617162c489b0`.
- Previous blocked HW0 manifest: `11/11 PASS`; final evidence commit
  `be8e5c6a875d5f4c21717d1fa8b5ae6419d3f8c2`.
- `G2B-LUT1 = ACCEPTED / OFFLINE_QUALIFIED`.
- Candidate maturity: `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`.
- `G2B-HW0-PRODUCT = AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`.
- Initial source: `ONE_CHANNEL_FIXED_LIVE_AHD_PATH`.
- META-8A: `PROMOTED / VERIFIED`.

## Exact source and artifacts

| Item | Exact value |
|---|---|
| Source worktree | `C:\FPGA\V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Source commit | `{SOURCE_COMMIT}` |
| Source tree | `{SOURCE_TREE}` |
| Remote branch | Exact commit match |
| Bitstream path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit` |
| Bitstream bytes | `2192144` |
| Bitstream SHA-256 | `{BIT_SHA}` |
| Signed-off DCP path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp` |
| Signed-off DCP bytes | `15726324` |
| Signed-off DCP SHA-256 | `{DCP_SHA}` |
| FPGA part | `xc7a35tcsg325-2` |
| Offline profile | `PRODUCT` |

The pre-program task checks found both protected worktrees tracked-clean. The
post-hardware replay in `raw/LOCAL_AUTHORITY_VERIFICATION.log` re-established
that state and rehashed the bitstream and DCP with the same exact results.
No source, active XDC, SSOT, or binary artifact was modified. Offline PRODUCT
authority does not constitute runtime identity or hardware qualification.
"""


DUT_LOCK = rf"""
# G2B-HW0-PRODUCT-R1 DUT Authority and Lock Receipt

Result: `PASS`

## Authoritative DUT

| Field | Exact value |
|---|---|
| Logical identity | `VCDE-DUT-HOST-01` |
| Authenticated hostname | `VCDE-DUT-1` |
| IPv4 / SSH port | `10.132.1.111 / 22` |
| User | `vcdeagent1` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Kernel | `7.0.0-29-generic` |
| Boot ID throughout task | `37131b8d-0e38-4b4e-b77a-b3bda55b4e97` |
| ED25519 host-key pin | `SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8` |
| Authentication | `PASS`, sanitized pwfile workflow |

The stale alias `ahd-ubuntu -> developer@10.132.1.227` was excluded. No secret
or transient password file is published. Plink SHA-256 was
`E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915`.

## Exclusivity and lock lifecycle

- Fresh DUT inventory at `2026-09-05T21:55:37Z` found no relevant process,
  lock, XDMA node, or node user. The exact Windows and Linux locks were then
  acquired at `2026-09-05T21:57:13Z` and `2026-09-05T21:57:30Z`.
- A supplemental controller snapshot at `2026-09-05T21:57:34Z`, after those
  acquisitions, found no competing Vivado, hw_server, JTAG, XDMA, or capture
  process and no listener on controller ports 3121, 3122, or 2542.
- One Xilinx Platform Cable USB II firmware loader was present at the expected
  controller USB identity; this established controller presence only.
- Windows lock started `2026-09-05T21:57:13.1232489Z` for task
  `G2B-HW0-PRODUCT-R1`, controller `NBLSUDUL`, this Codex task, and candidate
  SHA `{BIT_SHA}`.
- Linux lock `/tmp/ahd-g2b-hw0-product-r1.lock` was acquired at
  `2026-09-05T21:57:30Z` and freshly verified before programming.
- Final state was captured while both locks were held.
- Linux release: `PASS` at `2026-09-05T22:17:04.349801Z`; exact lock directory
  absent afterward.
- Windows release: `PASS` at `2026-09-05T22:17:51.0513312Z`; the original
  `.windows.lock` path was removed from the lock namespace and its released
  receipt was retained under `raw/`.
- Final endpoint BDF in both receipts: `N/A_ENDPOINT_NOT_RECOVERED`.

Lock release state: `RELEASED_AFTER_FINAL_STATE_CAPTURE` for both task-local
locks.
"""


PREPROGRAM = r"""
# G2B-HW0-PRODUCT-R1 Pre-program Inventory

Result: `PASS`

The fresh read-only DUT inventory completed at `2026-09-05T21:55:37Z`, before
the only SRAM programming operation.

| Item | Pre-program state |
|---|---|
| DUT / kernel | `VCDE-DUT-1 / 7.0.0-29-generic` |
| Boot ID | `37131b8d-0e38-4b4e-b77a-b3bda55b4e97` |
| Relevant DUT processes | None |
| Relevant pre-existing task locks | None |
| JTAG target count / device count | `1 / 1` |
| FPGA | `xc7a35t`, IDCODE `0362D093`, chain index 0 |
| Five JTAG DONE samples | `0,0,0,0,0` |
| Exact AHD/Xilinx endpoint | Absent |
| Historical AHD root `0000:00:01.1` | Absent |
| `xdma` loaded | `NO` |
| XDMA node count | `0` |

The visible external PCIe tree was AMD Phoenix GPP bridge `0000:00:02.1` to
AMD 600-series switch upstream `0000:01:00.0`, then buses 03 through 09. That
current `0000:01:00.0` is `1022:43f4`, not the historical AHD endpoint. The
inventory retained full topology, link, AER, node, module, process, and kernel
log output in `raw/PREPROGRAM_DUT_INVENTORY_READONLY.log`.

The pre-program inventory made zero MMIO accesses, PCI writes, rescans, resets,
driver changes, DMA accesses, reboots, or power actions.
"""


CORRELATION = r"""
# G2B-HW0-PRODUCT-R1 JTAG to PCIe Correlation

T0 correlation result: `PASS`

## Fresh JTAG identity

- Target count: `1`.
- Full path: `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`.
- Canonical ID: `Xilinx/80802026a98b01`.
- TID/device: `jsn-DLC10-80802026a98b01`.
- Frequency: `6000000 Hz`, unchanged.
- Device count: `1`; chain index: `0`.
- Part / IDCODE: `xc7a35t / 0362D093`.
- Additional JTAG devices: `0`.

The first legacy-selector inventory refused the obsolete
`Digilent/210241768436` literal and performed no program operation. The
accepted exact selector then passed five stable pre-program samples and five
stable final samples.

## Accepted physical binding

Accepted migration/R1H/R7 evidence binds the exact Xilinx cable, FPGA,
authoritative DUT, and physical AHD board to historical endpoint
`0000:01:00.0`, parent `0000:00:01.1`, vendor/device `10ee:7011`, subsystem
`10ee:0007`, class `058000`, BAR0 131072 bytes. File paths and SHA-256 values
are frozen in `raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log`.

This accepted binding supports T0 board ownership. It does not replace the
required fresh post-program endpoint and link measurements. After programming,
the historical root function and AHD endpoint remained absent, so correlation
could not be retained into T1. T1 stopped with
`BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`.

The accepted sources were reviewed in the executing task before T0. The raw
historical-binding verification file in this package is a post-run rehash at
`2026-09-05T22:26:29Z`; it preserves source identity and does not claim a fresh
pre-program live endpoint/root mapping.
"""


PROGRAMMING = rf"""
# G2B-HW0-PRODUCT-R1 Programming Receipt

Result: `PASS`

| Field | Exact value |
|---|---|
| Candidate path | `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit` |
| Candidate bytes / SHA-256 | `2192144 / {BIT_SHA}` |
| Target | `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01` |
| FPGA | `xc7a35t`, IDCODE `0362D093` |
| Pre-program DONE samples | `0,0,0,0,0` |
| Program start | `2026-09-05T22:03:58Z` |
| Program returned / end | `2026-09-05T22:04:05Z` |
| Vendor startup | `HIGH` |
| Immediate DONE | `1` |
| Final DONE samples | `1,1,1,1,1` |
| Final JTAG sample end | `2026-09-05T22:14:31Z` |
| Program invocations | `1` |
| Automatic retries | `0` |
| Flash / CFGMEM / PROGRAM_B | `0 / 0 / 0` |

The executing supervisor rehashed the exact candidate before launch. The Tcl
script independently checked the exact path argument, filename, and byte size;
recorded the expected SHA-256 and the requirement for a Windows-supervisor PASS;
selected the exact target/device; and contained one static `program_hw_devices`
invocation. The post-run authority
replay independently rehashed the candidate again. The Tcl final literal is
`PROGRAM_TCL_RESULT=PASS_DONE_1`. No second program or rollback operation
occurred.
"""


PCIE_XDMA = r"""
# G2B-HW0-PRODUCT-R1 PCIe and XDMA Inventory

T1 result: `BLOCKED`

| Field | Result |
|---|---|
| Bounded automatic recovery | Complete; `AUTO_RECOVERY_FOUND=0` |
| Exact AHD endpoint | `FAIL`, absent after programming |
| Endpoint BDF / vendor-device | `N/A / N/A` |
| AHD LnkCap / LnkSta | `N/A / N/A` |
| PCIe Gen2 x1 gate | `NOT_REACHED` |
| Targeted recovery | `0` operations |
| XDMA gate / exact bind | `NOT_REACHED / NOT_RUN` |
| `xdma` loaded / driver sysfs | `NO / ABSENT` |
| XDMA user / C2H nodes | `N/A / N/A` |
| XDMA node count | `0` |

The accepted AHD root `0000:00:01.1` did not exist. The current AMD switch
subtree includes multiple downstream branches and unrelated Ethernet, USB,
and SATA endpoints. No firmware slot map or other evidence uniquely selected
an AHD branch. Consequently there was no exact root-port sysfs object, endpoint
BDF, or AHD-only subtree on which the conditional recovery or bind could act.

No broad bus rescan, bridge remove, guessed downstream-port rescan, endpoint
reset, config write, module load/unload, or sysfs bind was issued. No unrelated
endpoint was changed. First blocker:
`BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`.
"""


RUNTIME_IDENTITY = rf"""
# G2B-HW0-PRODUCT-R1 Runtime Identity

Dual-layer identity result: `NOT_REACHED`

The governed candidate layer passed offline:

- source commit `{SOURCE_COMMIT}`;
- source tree `{SOURCE_TREE}`;
- bitstream SHA-256 `{BIT_SHA}`;
- DCP SHA-256 `{DCP_SHA}`;
- SSOT revision `8` and META-8A `VERIFIED`.

Expected runtime layer:

- embedded `GIT_SHA={RUNTIME_SHA}`;
- `BUILD_FLAGS={BUILD_FLAGS}`;
- PRODUCT profile indication;
- transport `AHD_C2H_TRANSPORT_ABI_V1`, ABI version 1;
- legacy block/protocol/build schemas and Vivado build;
- NVP initialization, NACK, `INIT_ERROR`, live-video, VCLK, SAV, and frame
  telemetry.

T1 blocked before an exact XDMA user device existed. Therefore no legacy or
G2B MMIO was read, and none of the expected runtime values is reported as an
observed hardware value. PRODUCT profile, transport ABI, NVP readiness, and
fixed live source remain `NOT_REACHED`.
"""


FIRST_RECORD = r"""
# G2B-HW0-PRODUCT-R1 First Record Analysis

T3 result: `NOT_REACHED`

T1 blocked before XDMA and T2 was not executed. No C2H read was attempted and
no first-record file was created.

| Field | Value |
|---|---|
| Local record path | `N/A` |
| Record bytes | `N/A` |
| SHA-256 | `NONE` |
| Header | `NOT_REACHED` |
| Payload size | `NOT_REACHED` |
| Padding / all-zero padding | `NOT_REACHED` |
| Channel / input / sequence / epoch / flags | `N/A` |
| Reserved / malformed / fatal fields | `N/A` |

No host-visible record-boundary claim and no internal AXI `TKEEP` or `TLAST`
claim is made.
"""


FINITE = r"""
# G2B-HW0-PRODUCT-R1 Finite Capture Summary

T4 result: `NOT_REACHED`

| Field | Value |
|---|---|
| Records requested | `2500` |
| Records received | `N/A` |
| Sequence gaps / duplicates | `N/A / N/A` |
| Padding / malformed errors | `N/A / N/A` |
| Epoch changes | `N/A` |
| Channel / input | `N/A / N/A` |
| Formatter / ownership fatal | `N/A / N/A` |
| Slot ownership/release counters | `N/A` |
| Drop/discontinuity accounting | `N/A` |
| Capture path / hash samples | `N/A / NONE` |

T4 was forbidden by the earlier T1 blocker. No finite DMA capture occurred.
"""


FRAME = r"""
# G2B-HW0-PRODUCT-R1 Frame Reconstruction

Result: `NOT_REACHED`

No finite capture existed from which to reconstruct a frame.

| Field | Value |
|---|---|
| Lossless frame path | `N/A` |
| Frame SHA-256 | `NONE` |
| Complete active lines | `N/A` |
| Required active lines | `1080` |
| Line order / missing / duplicate lines | `N/A` |
| Frame ID / epoch | `N/A / N/A` |
| Bytes per active line | `3840` expected, not observed |
| Stale-slot mixing | `NOT_REACHED` |
"""


CONTINUOUS = r"""
# G2B-HW0-PRODUCT-R1 Continuous Capture Summary

T5 result: `NOT_REACHED`

| Field | Value |
|---|---|
| Required measured duration | `60 seconds` |
| Actual measured duration | `N/A` |
| Complete records | `N/A` |
| Records/s / estimated frame rate | `N/A / N/A` |
| Application / transport throughput | `N/A / N/A` |
| Malformed / gaps / duplicates | `N/A / N/A / N/A` |
| Epoch / drop / overflow changes | `N/A` |
| Formatter / ownership fatal | `N/A / N/A` |
| Before/after counters | `N/A` |
| Initial/final/anomaly samples | `N/A` |
| Rolling/bounded hashes | `NONE` |

No continuous DMA capture occurred. The one-channel live AHD path and hardware
throughput remain unproven.
"""


FINAL_STATE = rf"""
# G2B-HW0-PRODUCT-R1 Final Hardware State

Final state was captured after the stop decision and while both task locks were
still held.

| Field | Exact final value |
|---|---|
| Candidate | Exact verified candidate still loaded in volatile SRAM by unbroken operation chain |
| FPGA | `xc7a35t`, IDCODE `0362D093` |
| DONE | `1` in five of five final samples |
| AHD endpoint / BDF | Absent / `N/A` |
| Driver binding | None; `xdma` not loaded and driver sysfs absent |
| Device nodes | No XDMA nodes; count `0` |
| Last MMIO state | `NOT_REACHED_NO_MMIO_ACCESS` |
| Stream | `NEVER_ENABLED` |
| Linux task lock | Released after capture; `PASS` |
| Windows task lock | Released after capture; `PASS` |

The DUT boot ID remained
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`. There was no reboot or power-cycle.

## Protected state

| Protected item | Modified |
|---|---|
| `C:\FPGA\FPGA_AHD` | `NO` |
| `C:\FPGA\V41_G2B` tracked source | `NO` |
| Active XDC | `NO` |
| Project SSOT | `NO` |
| Persistent Flash | `NO` |
| Driver files | `NO` |
| Package state | `NO` |
| Unrelated PCIe endpoints | `NO` |

Program operations were limited to the one authorized volatile-SRAM load.
Final blocker: `{BLOCKER}`.
"""


def legacy_csv() -> None:
    path = OUT / "G2B_HW0_PRODUCT_R1_LEGACY_MMIO_RAW.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "status", "read_timestamp_utc", "offset", "width_bits",
            "raw_value", "byte_order", "register", "decoded_value",
            "authorized_range", "access", "provenance",
        ])
        writer.writerow([
            "NOT_REACHED", "N/A", "N/A", "N/A", "N/A", "N/A", "N/A",
            "T1 blocked before exact XDMA user-device mapping",
            "0x0000..0x0030;0x0080..0x00B4", "READ_ONLY_NOT_EXECUTED",
            "No legacy MMIO access performed",
        ])


def g2b_csv() -> None:
    path = OUT / "G2B_HW0_PRODUCT_R1_G2B_MMIO_BASELINE.csv"
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow([
            "status", "timestamp_utc", "offset", "register", "raw_value",
            "decoded_value", "access", "expected_geometry", "provenance",
        ])
        writer.writerow([
            "NOT_REACHED", "N/A", "N/A", "N/A", "N/A",
            "T1 blocked before exact XDMA user-device mapping",
            "NO_READ_OR_WRITE", "4096/64/3840/192 bytes; ABI v1",
            "No G2B MMIO access performed; stream never enabled",
        ])


def gate_matrix(publication: str, remote: str) -> None:
    rows = [
        ("META-8A", "rev8 and 32/32 manifest", "PASS", "raw/LOCAL_AUTHORITY_VERIFICATION.log", "VERIFIED"),
        ("AUTHORIZATION", "hardware + exact MMIO contract", "PASS", "G2B_HW0_PRODUCT_R1_AUTHORIZATION_RECEIPT.md", "legacy writes DENIED"),
        ("DUT_AUTH", "exact authenticated host", "PASS", "raw/DUT_IDENTITY_READONLY.log", "VCDE-DUT-1"),
        ("DUT_EXCLUSIVITY", "fresh ownership and locks", "PASS", "G2B_HW0_PRODUCT_R1_DUT_AUTHORITY_AND_LOCK_RECEIPT.md", "both locks held before programming"),
        ("CANDIDATE", "source/bit/DCP exact", "PASS", "raw/LOCAL_AUTHORITY_VERIFICATION.log", "exact Recovery-4 candidate"),
        ("JTAG", "one target/device exact", "PASS", "raw/JTAG_SESSION_1.csv", "five DONE=0 samples"),
        ("PCIE_PREPROGRAM", "fresh read-only inventory", "PASS", "raw/PREPROGRAM_DUT_INVENTORY_READONLY.log", "AHD endpoint absent and recorded"),
        ("JTAG_PCIE_CORRELATION", "accepted physical binding", "PASS", "raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log", "T0 binding only"),
        ("T0", "candidate/environment", "PASS", "V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md", "programming authorized to proceed"),
        ("SRAM_PROGRAM", "one exact invocation", "PASS", "raw/PROGRAM_G2B_PRODUCT_R1_ONCE_VIVADO.log", "DONE=1; no retry"),
        ("AUTO_PCIE_RECOVERY", "bounded wait and inventory", "COMPLETE_NO_ENDPOINT", "raw/POSTPROGRAM_AUTO_RECOVERY_WAIT.log", "AUTO_RECOVERY_FOUND=0"),
        ("TARGETED_PCIE_RECOVERY", "exact AHD-only subtree required", "BLOCKED", "raw/TARGETED_RECOVERY_IDENTITY_READONLY.log", BLOCKER),
        ("AHD_ENDPOINT", "fresh endpoint after program", "FAIL", "raw/FINAL_DUT_STATE_BEFORE_LOCK_RELEASE.log", "endpoint absent"),
        ("T1", "SRAM + endpoint + Gen2x1 + XDMA", "BLOCKED", "G2B_HW0_PRODUCT_R1_PCIE_XDMA_INVENTORY.md", BLOCKER),
        ("T2", "runtime/MMIO", "NOT_REACHED", "G2B_HW0_PRODUCT_R1_RUNTIME_IDENTITY.md", "blocked by T1"),
        ("T3", "one 4096-byte record", "NOT_REACHED", "G2B_HW0_PRODUCT_R1_FIRST_RECORD_ANALYSIS.md", "blocked by T1"),
        ("T4", "2500 records + frame", "NOT_REACHED", "G2B_HW0_PRODUCT_R1_FINITE_CAPTURE_SUMMARY.md", "blocked by T1"),
        ("T5", "60-second capture", "NOT_REACHED", "G2B_HW0_PRODUCT_R1_CONTINUOUS_CAPTURE_SUMMARY.md", "blocked by T1"),
        ("PERSISTENT_SOURCE_PROTECTION", "source/XDC/SSOT/Flash/driver/package unchanged", "PASS", "G2B_HW0_PRODUCT_R1_FINAL_HARDWARE_STATE.md", "no persistent mutation"),
        ("EVIDENCE_PUBLICATION", "new directory + non-force push", publication, "G2B_HW0_PRODUCT_R1_EVIDENCE_INDEX.md", "separate from engineering gate"),
        ("REMOTE_READBACK", "commit-pinned byte verification", remote, "G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md" if remote == "PASS" else "PENDING", "0 mismatches" if remote == "PASS" else "pending"),
    ]
    with (OUT / "G2B_HW0_PRODUCT_R1_GATE_MATRIX.csv").open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, lineterminator="\n")
        writer.writerow(["gate", "prerequisite", "result", "evidence", "blocker_or_note"])
        writer.writerows(rows)


def state(publication: str, remote: str, initial_commit: str | None, readback_files: int | None) -> None:
    payload = {
        "task": "G2B-HW0-PRODUCT-R1",
        "title": "Exact Candidate Live-Path Bring-Up",
        "engineering_gate": "BLOCKED",
        "evidence_publication": publication,
        "overall_result": "BLOCKED",
        "first_blocker": BLOCKER,
        "project_state_rev_at_start": 8,
        "project_state_rev_at_end": 8,
        "meta_8a": "VERIFIED",
        "previous_blocked_hw0_evidence": "VERIFIED",
        "authoritative_project_state": {
            "g2b_lut1": "ACCEPTED / OFFLINE_QUALIFIED",
            "candidate_maturity": "OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE",
            "g2b_hw0_product_readiness": "AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION",
            "initial_source": "ONE_CHANNEL_FIXED_LIVE_AHD_PATH",
            "meta_8a": "PROMOTED / VERIFIED",
        },
        "owner_hardware_authorization": "GRANTED",
        "additional_legacy_mmio_read_authorization": "GRANTED",
        "legacy_mmio_write_authorization": "DENIED",
        "authoritative_dut": {
            "logical": "VCDE-DUT-HOST-01",
            "hostname": "VCDE-DUT-1",
            "ip": "10.132.1.111",
            "user": "vcdeagent1",
            "machine_id": "0e90f50d9465492b80258da5658446f8",
            "kernel": "7.0.0-29-generic",
            "boot_id": "37131b8d-0e38-4b4e-b77a-b3bda55b4e97",
            "authenticated": "PASS",
            "exclusivity": "PASS",
        },
        "candidate": {
            "source_worktree": r"C:\FPGA\V41_G2B",
            "source_branch": "integration/v41-g2b-onech-c2h",
            "source_commit": SOURCE_COMMIT,
            "source_tree": SOURCE_TREE,
            "bitstream_path": r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit",
            "bitstream_bytes": 2192144,
            "bitstream_sha256": BIT_SHA,
            "dcp_path": r"C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp",
            "dcp_bytes": 15726324,
            "dcp_sha256": DCP_SHA,
            "offline_profile": "PRODUCT",
        },
        "jtag": {
            "correlation": "PASS_AT_T0",
            "target": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01",
            "canonical_id": "Xilinx/80802026a98b01",
            "part": "xc7a35t",
            "idcode": "0362D093",
            "chain_index": 0,
            "device_count": 1,
            "preprogram_done_samples": [0, 0, 0, 0, 0],
            "final_done_samples": [1, 1, 1, 1, 1],
        },
        "programming": {
            "sram": "PASS",
            "invocations": 1,
            "retries": 0,
            "start_utc": "2026-09-05T22:03:58Z",
            "end_utc": "2026-09-05T22:04:05Z",
            "done": 1,
            "flash": "NO",
        },
        "pcie": {
            "automatic_recovery_found": 0,
            "targeted_recovery_operations": 0,
            "targeted_recovery": "BLOCKED",
            "endpoint": "FAIL_ABSENT_AFTER_AUTOMATIC_RECOVERY",
            "endpoint_bdf": None,
            "vendor_device": None,
            "lnkcap": None,
            "lnksta": None,
            "gen2_x1_gate": "NOT_REACHED",
        },
        "xdma": {
            "gate": "NOT_REACHED",
            "module_loaded": False,
            "driver_sysfs_present": False,
            "user_device": None,
            "c2h_device": None,
            "node_count": 0,
            "loads": 0,
            "unloads": 0,
            "binds": 0,
        },
        "expected_runtime_identity": {"git_sha": RUNTIME_SHA, "build_flags": BUILD_FLAGS},
        "observed_runtime_identity": None,
        "dual_layer_identity": "NOT_REACHED",
        "transport_abi": "NOT_REACHED",
        "product_profile": "NOT_REACHED",
        "legacy_identity_mmio": "NOT_REACHED",
        "nvp_video_telemetry_mmio": "NOT_REACHED",
        "mmio_baseline": "NOT_REACHED",
        "nvp_initialization": "NOT_REACHED",
        "fixed_live_source": "NOT_REACHED",
        "gates": {"t0": "PASS", "t1": "BLOCKED", "t2": "NOT_REACHED", "t3": "NOT_REACHED", "t4": "NOT_REACHED", "t5": "NOT_REACHED"},
        "capture": {
            "first_record_bytes": None,
            "first_record_sha256": None,
            "finite_records_requested": 2500,
            "finite_records_received": None,
            "frame_sha256": None,
            "continuous_duration_seconds": None,
        },
        "final_hardware_state": {
            "candidate": "STILL_LOADED_VOLATILE_SRAM_BY_UNBROKEN_CHAIN",
            "done": 1,
            "endpoint": "ABSENT",
            "driver": "NOT_LOADED",
            "device_nodes": [],
            "last_mmio": "NOT_REACHED_NO_MMIO_ACCESS",
            "stream": "NEVER_ENABLED",
            "linux_lock": "RELEASED_AFTER_FINAL_STATE_CAPTURE",
            "windows_lock": "RELEASED_AFTER_FINAL_STATE_CAPTURE",
        },
        "operation_counts": {
            "pcie_config_writes": 0,
            "pcie_rescans": 0,
            "pcie_resets": 0,
            "legacy_mmio_reads": 0,
            "legacy_mmio_writes": 0,
            "g2b_mmio_reads": 0,
            "g2b_mmio_writes": 0,
            "dma_captures": 0,
            "reboots": 0,
            "power_cycles": 0,
        },
        "hardware_accessed": True,
        "persistent_state_modified": False,
        "hardware_throughput_288_mb_s": "NOT_PROVEN",
        "four_input_selection": "NOT_QUALIFIED",
        "two_channel_capture": "NOT_QUALIFIED",
        "synthetic_generator_in_product": "NO",
        "v4l2": "NOT_TESTED",
        "release_v41_0_0": "NOT_CREATED",
        "g2b_hw0_product": "BLOCKED",
        "g2b_hw_qualification": "NOT_PROVEN",
        "ssot_update_required": "NO",
        "publication": {
            "repository": "lukaszsudul/AHD-diagnostic-evidence",
            "branch": "main",
            "directory": DIR_NAME,
            "required_initial_commit_message": REQUIRED_COMMIT_MESSAGE,
            "initial_evidence_commit": initial_commit or "PENDING_CONTAINING_GIT_COMMIT",
            "completion_commit": "CONTAINING_GIT_COMMIT" if publication == "PASS" else None,
            "remote_readback": remote,
            "remote_readback_files": readback_files,
            "remote_readback_mismatches": 0 if remote == "PASS" else None,
        },
        "final_response_fields": {
            "engineering_gate": "BLOCKED",
            "evidence_publication": publication,
            "overall_result": "BLOCKED",
            "project_state_rev_at_start": 8,
            "project_state_rev_at_end": 8,
            "meta_8a": "VERIFIED",
            "previous_blocked_hw0_evidence": "VERIFIED",
            "owner_hardware_authorization": "GRANTED",
            "additional_legacy_mmio_read_authorization": "GRANTED",
            "legacy_mmio_write_authorization": "DENIED",
            "authoritative_linux_dut": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
            "authenticated_dut_connection": "PASS",
            "dut_exclusivity": "PASS",
            "authoritative_source_worktree": r"C:\FPGA\V41_G2B",
            "source_commit": SOURCE_COMMIT,
            "product_bitstream": "VERIFIED",
            "product_bitstream_sha256": BIT_SHA,
            "signed_off_dcp": "VERIFIED",
            "signed_off_dcp_sha256": DCP_SHA,
            "jtag_to_pcie_board_correlation": "PASS",
            "fpga_device": "xc7a35t / IDCODE 0362D093 / chain index 0",
            "sram_programming": "PASS",
            "flash_programming": "NO",
            "done": 1,
            "ahd_endpoint": "FAIL",
            "endpoint_bdf": "N/A",
            "pcie_vendor_device": "N/A",
            "pcie_lnkcap": "N/A",
            "pcie_lnksta": "N/A",
            "pcie_gen2_x1_hardware_gate": "NOT_REACHED",
            "xdma_driver": "NOT_REACHED",
            "xdma_driver_version_hash": "N/A",
            "xdma_user_device": "N/A",
            "xdma_c2h_device": "N/A",
            "runtime_embedded_git_sha": "N/A",
            "expected_runtime_embedded_git_sha": RUNTIME_SHA,
            "runtime_build_flags": "N/A",
            "expected_runtime_build_flags": BUILD_FLAGS,
            "dual_layer_identity": "NOT_REACHED",
            "transport_abi": "NOT_REACHED",
            "abi_version": "N/A",
            "product_profile": "NOT_REACHED",
            "legacy_identity_mmio": "NOT_REACHED",
            "nvp_video_telemetry_mmio": "NOT_REACHED",
            "mmio_baseline": "NOT_REACHED",
            "nvp_initialization": "NOT_REACHED",
            "nack_count": "N/A",
            "init_error": "N/A",
            "fixed_live_source": "NOT_REACHED",
            "t0": "PASS",
            "t1": "BLOCKED",
            "t2": "NOT_REACHED",
            "t3": "NOT_REACHED",
            "first_record_bytes": "N/A",
            "first_record_sha256": "NONE",
            "header": "NOT_REACHED",
            "payload_size": "NOT_REACHED",
            "padding": "NOT_REACHED",
            "t4": "NOT_REACHED",
            "finite_records_requested": 2500,
            "finite_records_received": "N/A",
            "sequence_gaps": "N/A",
            "sequence_duplicates": "N/A",
            "padding_errors": "N/A",
            "epoch_changes": "N/A",
            "frame_reconstruction": "NOT_REACHED",
            "reconstructed_frame_sha256": "NONE",
            "t5": "NOT_REACHED",
            "continuous_measured_duration": "N/A",
            "complete_records": "N/A",
            "records_per_second": "N/A",
            "estimated_frame_rate": "N/A",
            "application_payload": "N/A",
            "transport_throughput": "N/A",
            "malformed_records": "N/A",
            "unexplained_drops_gaps": "N/A",
            "formatter_fatal": "N/A",
            "ownership_fatal": "N/A",
            "one_channel_live_ahd_path": "NOT_REACHED",
            "hardware_throughput_ge_288_mb_s": "NOT_PROVEN",
            "four_input_selection": "NOT_QUALIFIED",
            "two_channel_capture": "NOT_QUALIFIED",
            "synthetic_generator_in_product": "NO",
            "v4l2": "NOT_TESTED",
            "release_v41_0_0": "NOT_CREATED",
            "final_fpga_state": "Exact candidate last programmed to volatile SRAM; DONE=1",
            "final_pcie_driver_state": "AHD endpoint absent; xdma unloaded; zero nodes; no binding",
            "persistent_state_modified": "NO",
            "reboot": "NO",
            "power_cycle": "NO",
            "hardware_accessed": "YES",
            "g2b_hw0_product": "BLOCKED",
            "g2b_hw_qualification": "NOT_PROVEN",
            "ssot_update_required": "NO",
            "evidence_repository": "lukaszsudul/AHD-diagnostic-evidence",
            "evidence_directory": DIR_NAME,
            "evidence_commit": "CONTAINING_COMPLETION_COMMIT" if publication == "PASS" else "PENDING",
            "remote_readback": remote,
            "main_report": rf"C:\FPGA\V41_G2B_EVIDENCE\{DIR_NAME}\V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md",
            "first_blocker": BLOCKER,
            "recommended_next_step": "Owner-authorize one controlled warm reboot of VCDE-DUT-1 in a new governed run for fresh AHD path re-enumeration.",
            "final_execution_point": "HARD STOP AFTER G2B-HW0-PRODUCT-R1 LIVE-PATH BRING-UP",
        },
        "recommended_next_step": "Owner-authorize one controlled warm reboot of VCDE-DUT-1 in a new governed run for fresh AHD path re-enumeration.",
        "final_execution_point": "HARD STOP AFTER G2B-HW0-PRODUCT-R1 LIVE-PATH BRING-UP",
    }
    write_text("G2B_HW0_PRODUCT_R1_STATE.json", json.dumps(payload, indent=2, ensure_ascii=False))


def evidence_index(publication: str, remote: str) -> None:
    required = [
        ("V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md", "overall result and decision"),
        ("G2B_HW0_PRODUCT_R1_AUTHORIZATION_RECEIPT.md", "exact grants, denials, operation counts"),
        ("G2B_HW0_PRODUCT_R1_CANDIDATE_VERIFICATION.md", "source, SSOT, bitstream, DCP identity"),
        ("G2B_HW0_PRODUCT_R1_DUT_AUTHORITY_AND_LOCK_RECEIPT.md", "DUT authentication, exclusivity, lock lifecycle"),
        ("G2B_HW0_PRODUCT_R1_PREPROGRAM_INVENTORY.md", "pre-mutation JTAG/PCIe/XDMA state"),
        ("G2B_HW0_PRODUCT_R1_JTAG_PCIE_CORRELATION.md", "fresh JTAG and accepted physical binding"),
        ("G2B_HW0_PRODUCT_R1_PROGRAMMING_RECEIPT.md", "one exact SRAM program and DONE"),
        ("G2B_HW0_PRODUCT_R1_PCIE_XDMA_INVENTORY.md", "endpoint recovery blocker and final driver state"),
        ("G2B_HW0_PRODUCT_R1_LEGACY_MMIO_RAW.csv", "explicit NOT_REACHED legacy MMIO ledger"),
        ("G2B_HW0_PRODUCT_R1_RUNTIME_IDENTITY.md", "offline identity versus unobserved runtime layer"),
        ("G2B_HW0_PRODUCT_R1_G2B_MMIO_BASELINE.csv", "explicit NOT_REACHED G2B MMIO ledger"),
        ("G2B_HW0_PRODUCT_R1_FIRST_RECORD_ANALYSIS.md", "T3 NOT_REACHED and no payload"),
        ("G2B_HW0_PRODUCT_R1_FINITE_CAPTURE_SUMMARY.md", "T4 NOT_REACHED"),
        ("G2B_HW0_PRODUCT_R1_FRAME_RECONSTRUCTION.md", "reconstruction NOT_REACHED"),
        ("G2B_HW0_PRODUCT_R1_CONTINUOUS_CAPTURE_SUMMARY.md", "T5 NOT_REACHED"),
        ("G2B_HW0_PRODUCT_R1_GATE_MATRIX.csv", "all gate dispositions"),
        ("G2B_HW0_PRODUCT_R1_FINAL_HARDWARE_STATE.md", "state captured before lock release"),
        ("G2B_HW0_PRODUCT_R1_STATE.json", "machine-readable task state"),
        ("G2B_HW0_PRODUCT_R1_EVIDENCE_INDEX.md", "this index"),
        ("G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt", "all other published bytes; self-excluded"),
    ]
    rows = "\n".join(f"| `{name}` | {purpose} |" for name, purpose in required)
    extra = ""
    if (OUT / "G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md").exists():
        extra = "\n| `G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md` | commit-pinned remote byte read-back |"
    raw_lines = []
    for root_name in ("raw", "tools"):
        for path in sorted((OUT / root_name).rglob("*"), key=lambda p: p.as_posix()):
            if path.is_file():
                rel = path.relative_to(OUT).as_posix()
                raw_lines.append(f"| `{rel}` | `{path.stat().st_size}` | `{sha256(path)}` |")
    raw_table = "\n".join(raw_lines)
    return write_text("G2B_HW0_PRODUCT_R1_EVIDENCE_INDEX.md", rf"""
# G2B-HW0-PRODUCT-R1 Evidence Index

Publication status: `{publication}`
Remote read-back: `{remote}`

## Required artifacts

| File | Purpose |
|---|---|
{rows}{extra}

All 20 mandatory filenames are present even though T2 through T5 were not
reached. Their artifacts explicitly record `NOT_REACHED`, `N/A`, or `NONE`
instead of omitting the evidence surface.

## Raw receipts and executed tooling

| Relative path | Bytes | SHA-256 |
|---|---:|---|
{raw_table}

The `raw/` directory contains immutable logs and released lock receipts. The
`tools/` directory contains the publish-safe task-local scripts plus accepted
JTAG selector/session copies. The authenticated-command helper source is
intentionally excluded because its credential-validation logic is sensitive;
the exact executed local helper remains at
`C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1`, SHA-256
`274DB6DDB1D3CDEAB0578275BABAEBFAA70DFCADC3F1FF35E717CACFED8119C0`.
Credentials, transient pwfiles, and the task-local `secret/` directory are
excluded. Authentication logs contain sanitized audit fields only.

## External binary payload policy

- Exact bitstream: local-only at
  `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit`,
  SHA-256 `{BIT_SHA}`.
- Signed-off DCP: local-only at
  `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp`,
  SHA-256 `{DCP_SHA}`.
- First 4096-byte record: not produced; path `N/A`, SHA-256 `NONE`.
- Reconstructed frame: not produced; path `N/A`, SHA-256 `NONE`.

The manifest hashes every published file except itself, using exact relative
paths and byte content.
""")


def manifest() -> None:
    path = OUT / "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt"
    entries = []
    for item in sorted(OUT.rglob("*"), key=lambda p: p.as_posix()):
        if item.is_file() and item != path:
            entries.append(f"{sha256(item)}  {item.relative_to(OUT).as_posix()}")
    path.write_text("\n".join(entries) + "\n", encoding="utf-8", newline="\n")


def publication_receipt(initial_commit: str, readback_files: int, readback_utc: str) -> None:
    write_text("G2B_HW0_PRODUCT_R1_PUBLICATION_RECEIPT.md", rf"""
# G2B-HW0-PRODUCT-R1 Publication Receipt

Result: `PASS`

- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `{DIR_NAME}`.
- Initial evidence commit: `{initial_commit}`.
- Required commit message: `{REQUIRED_COMMIT_MESSAGE}`.
- Push mode: ordinary non-force.
- Remote branch after push: exact initial commit match.
- Commit-pinned read-back UTC: `{readback_utc}`.
- Read-back transport: Git object bytes from the commit-pinned remote checkout.
- Files read back: `{readback_files}`.
- Missing files: `0`.
- Byte-length mismatches: `0`.
- SHA-256 mismatches: `0`.
- Manifest verification: `PASS`.

The read-back compared every path and byte in the initial evidence directory,
including the manifest. Engineering remains independently `BLOCKED` at
`{BLOCKER}`.
""")


def build(mode: str, initial_commit: str | None, readback_files: int | None, readback_utc: str | None) -> None:
    if mode == "pending":
        copy_inputs()
        pub_label = "AWAITING_POST_COMMIT_REMOTE_READBACK"
        remote_label = "NOT_RUN"
    elif mode == "refresh":
        if not OUT.is_dir():
            raise SystemExit("MISSING_INITIAL_PACKAGE")
        pub_label = "AWAITING_POST_COMMIT_REMOTE_READBACK"
        remote_label = "NOT_RUN"
    else:
        if not OUT.is_dir():
            raise SystemExit("MISSING_INITIAL_PACKAGE")
        if not initial_commit or readback_files is None or not readback_utc:
            raise SystemExit("FINAL_MODE_REQUIRES_READBACK_FIELDS")
        pub_label = "PASS"
        remote_label = "PASS"
        publication_receipt(initial_commit, readback_files, readback_utc)

    write_text("V41_G2B_HW0_PRODUCT_R1_MAIN_REPORT.md", main_report(pub_label, remote_label, initial_commit))
    write_text("G2B_HW0_PRODUCT_R1_AUTHORIZATION_RECEIPT.md", AUTHORIZATION)
    write_text("G2B_HW0_PRODUCT_R1_CANDIDATE_VERIFICATION.md", CANDIDATE)
    write_text("G2B_HW0_PRODUCT_R1_DUT_AUTHORITY_AND_LOCK_RECEIPT.md", DUT_LOCK)
    write_text("G2B_HW0_PRODUCT_R1_PREPROGRAM_INVENTORY.md", PREPROGRAM)
    write_text("G2B_HW0_PRODUCT_R1_JTAG_PCIE_CORRELATION.md", CORRELATION)
    write_text("G2B_HW0_PRODUCT_R1_PROGRAMMING_RECEIPT.md", PROGRAMMING)
    write_text("G2B_HW0_PRODUCT_R1_PCIE_XDMA_INVENTORY.md", PCIE_XDMA)
    legacy_csv()
    write_text("G2B_HW0_PRODUCT_R1_RUNTIME_IDENTITY.md", RUNTIME_IDENTITY)
    g2b_csv()
    write_text("G2B_HW0_PRODUCT_R1_FIRST_RECORD_ANALYSIS.md", FIRST_RECORD)
    write_text("G2B_HW0_PRODUCT_R1_FINITE_CAPTURE_SUMMARY.md", FINITE)
    write_text("G2B_HW0_PRODUCT_R1_FRAME_RECONSTRUCTION.md", FRAME)
    write_text("G2B_HW0_PRODUCT_R1_CONTINUOUS_CAPTURE_SUMMARY.md", CONTINUOUS)
    gate_matrix(pub_label, remote_label)
    write_text("G2B_HW0_PRODUCT_R1_FINAL_HARDWARE_STATE.md", FINAL_STATE)
    state(pub_label, remote_label, initial_commit, readback_files)
    evidence_index(pub_label, remote_label)
    manifest()


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--mode", choices=("pending", "refresh", "final"), required=True)
    parser.add_argument("--initial-commit")
    parser.add_argument("--readback-files", type=int)
    parser.add_argument("--readback-utc")
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()
    build(
        args.mode,
        args.initial_commit,
        args.readback_files,
        args.readback_utc,
    )
