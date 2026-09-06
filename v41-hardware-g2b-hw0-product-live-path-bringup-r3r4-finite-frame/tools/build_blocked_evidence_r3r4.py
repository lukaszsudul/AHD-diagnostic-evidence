#!/usr/bin/env python3
"""Build sanitized R3R4 blocked evidence after the offline hard-gate stop."""
from __future__ import annotations

import csv
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
from typing import Iterable


TASK = 'G2B-HW0-PRODUCT-R3R4'
ROOT = Path(r'C:\FPGA\G2B_HW0_PRODUCT_R3R4_20260906T215021Z')
EVIDENCE_REPO = Path(r'C:\FPGA\V41_G2B_EVIDENCE')
SOURCE_REPO = Path(r'C:\FPGA\V41_G2B')
EVIDENCE_DIR_NAME = 'v41-hardware-g2b-hw0-product-live-path-bringup-r3r4-finite-frame'
STAGE = ROOT / 'artifacts' / 'public' / EVIDENCE_DIR_NAME
R3R3_DIR = 'v41-hardware-g2b-hw0-product-live-path-bringup-r3r3-cold-start-first-record'
R3R3_COMMIT = '6cff7ad374575df84bc7d8794565dbd7d9cd869f'
DRV_COMMIT = '9aacc157dab5fe604faf66501b0129613b98ae2d'
SOURCE_COMMIT = '92e9b3d914134c044371779def1ee18eaaeda98a'
SOURCE_TREE = 'cf6bf82249c90782eab1978c68541ed9c0e6430b'
BIT_SHA = 'AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7'
DCP_SHA = '95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175'
DRIVER_SHA = 'E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77'
ABI_SHA = 'AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6'
EXPECTED_BOOT = '614295f4-c62b-4430-ae67-06013bea7084'
BLOCKER = 'R3R4_CAPTURE_TOOL_HARD_GATE_FAILED'


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest().upper()


def git_bytes(cwd: Path, *args: str) -> bytes:
    return subprocess.check_output(['git', *args], cwd=cwd)


def git_text(cwd: Path, *args: str) -> str:
    return git_bytes(cwd, *args).decode('utf-8').strip()


def git_json(cwd: Path, object_name: str) -> dict:
    return json.loads(git_bytes(cwd, 'show', object_name).decode('utf-8'))


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8', newline='\n') as handle:
        handle.write(text.rstrip() + '\n')
        handle.flush()
        os.fsync(handle.fileno())


def write_json(path: Path, value: dict) -> None:
    write_text(path, json.dumps(value, indent=2))


def write_csv(path: Path, columns: Iterable[str], rows: Iterable[dict]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8', newline='') as handle:
        writer = csv.DictWriter(handle, fieldnames=list(columns), lineterminator='\n')
        writer.writeheader()
        for row in rows:
            writer.writerow(row)
        handle.flush()
        os.fsync(handle.fileno())


def verify_r3r3() -> tuple[dict, int]:
    remote = git_text(EVIDENCE_REPO, 'ls-remote', 'origin', 'refs/heads/main').split()[0]
    require(remote == R3R3_COMMIT, 'R3R3_REMOTE_MAIN_COMMIT_MISMATCH')
    state = git_json(
        EVIDENCE_REPO,
        f'{R3R3_COMMIT}:{R3R3_DIR}/G2B_HW0_PRODUCT_R3R3_STATE.json',
    )
    expected = {
        'T0': 'PASS', 'T1': 'PASS', 'T2': 'PASS',
        'sram_programming_attempts': 1, 'warm_reboots': 1,
        'reset_writes': 1, 'pre_reset_epoch': 1, 'post_reset_epoch': 2,
        'post_reset_error_status': '0x00000000',
        'reader_primary_records': 1, 'reader_drain_records': 52,
        'reader_complete_records': 53, 'reader_trailing_bytes': 0,
        'record_bytes_persisted': False, 'header': 'NOT_REACHED',
        'counter_reconciliation': 'NOT_REACHED',
        'first_blocker': 'R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA',
        'rollback_assessment': 'PASS', 'cleanup': 'PASS',
        'final_dma_quiescent': True, 'endpoint_final': 'PRESENT_UNBOUND',
        'nodes_final': 'REMOVED', 'final_done': 1,
        'candidate_left_in_volatile_sram': True,
        'post_boot_id': EXPECTED_BOOT, 'kernel_taint_final': 12288,
        'post_failure_error_status': '0x00000007',
    }
    for key, value in expected.items():
        require(state.get(key) == value,
                f'R3R3_STATE_MISMATCH:{key}:{state.get(key)!r}:{value!r}')
    rollback = git_json(
        EVIDENCE_REPO,
        f'{R3R3_COMMIT}:{R3R3_DIR}/raw/post-t3-rollback-assessment.json',
    )
    cleanup = git_json(
        EVIDENCE_REPO,
        f'{R3R3_COMMIT}:{R3R3_DIR}/raw/cleanup-result.json',
    )
    require(rollback['result'] == 'PASS' and rollback['dma_quiescent'] is True,
            'R3R3_ROLLBACK_ASSESSMENT_NOT_PASS')
    require(rollback['mmio']['0x383C'] == 7 and
            rollback['mmio']['0x3840'] == 2,
            'R3R3_FINAL_ERROR_IDENTITY_MISMATCH')
    require(cleanup['result'] == 'PASS' and cleanup['rmmod_attempts'] == 1 and
            cleanup['module'] == 'ABSENT' and cleanup['nodes'] == 'REMOVED' and
            cleanup['automatic_unbind'] == 'PASS' and
            cleanup['endpoint_link'] == 'Gen2 x1' and
            cleanup['boot_id'] == EXPECTED_BOOT,
            'R3R3_CLEANUP_MISMATCH')

    manifest_path = f'{R3R3_DIR}/G2B_HW0_PRODUCT_R3R3_SHA256_MANIFEST.txt'
    manifest = git_bytes(EVIDENCE_REPO, 'show', f'{R3R3_COMMIT}:{manifest_path}')
    entries = []
    for line in manifest.decode('utf-8').splitlines():
        expected_hash, relative = line.split('  ', 1)
        blob = git_bytes(EVIDENCE_REPO, 'show',
                         f'{R3R3_COMMIT}:{R3R3_DIR}/{relative}')
        actual = hashlib.sha256(blob).hexdigest().upper()
        require(actual == expected_hash,
                f'R3R3_MANIFEST_MISMATCH:{relative}:{actual}:{expected_hash}')
        entries.append(relative)
    require(entries, 'R3R3_MANIFEST_EMPTY')
    return state, len(entries)


def verify_authority() -> dict:
    r3r3, manifest_count = verify_r3r3()
    project = git_json(EVIDENCE_REPO, 'HEAD:project-current-state/PROJECT_STATE.json')
    require(project['project_state_revision'] == 8, 'PROJECT_STATE_REV_NOT_8')
    require(project['tracks']['meta']['current_task'] == 'META-8A',
            'META8A_NOT_AUTHORITATIVE')
    product = project['tracks']['product']['g2b_hw0_product']
    require(product['readiness'] == 'AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION',
            'PRODUCT_CONTROLLED_HARDWARE_NOT_AUTHORIZED')
    require(product['qualification_state'] == 'NOT_PROVEN',
            'G2B_HW_ALREADY_QUALIFIED_UNEXPECTEDLY')
    require(git_text(EVIDENCE_REPO, 'rev-parse', 'HEAD') == R3R3_COMMIT,
            'LOCAL_EVIDENCE_HEAD_MISMATCH')
    remote_main = git_text(EVIDENCE_REPO, 'ls-remote', 'origin',
                           'refs/heads/main').split()[0]
    require(remote_main == R3R3_COMMIT, 'NEWER_EVIDENCE_MAIN_SUPERSEDES_TASK')

    require(git_text(SOURCE_REPO, 'branch', '--show-current') ==
            'integration/v41-g2b-onech-c2h', 'SOURCE_BRANCH_MISMATCH')
    require(git_text(SOURCE_REPO, 'rev-parse', 'HEAD') == SOURCE_COMMIT,
            'SOURCE_COMMIT_MISMATCH')
    require(git_text(SOURCE_REPO, 'rev-parse', 'HEAD^{tree}') == SOURCE_TREE,
            'SOURCE_TREE_MISMATCH')
    require(not git_text(SOURCE_REPO, 'status', '--porcelain',
                         '--untracked-files=no'), 'SOURCE_TRACKED_DIRTY')
    remote_source = git_text(SOURCE_REPO, 'ls-remote', 'origin',
                             'refs/heads/integration/v41-g2b-onech-c2h').split()[0]
    require(remote_source == SOURCE_COMMIT, 'SOURCE_REMOTE_MISMATCH')

    bitstream = Path(r'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit')
    dcp = Path(r'C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp')
    controller_driver = Path(r'C:\FPGA\V41_G2B_DRIVER_ARTIFACTS\G2B_HW0_DRV1_20260906T121539Z\xdma_ahd_pcie.ko')
    require(bitstream.stat().st_size == 2_192_144 and sha(bitstream) == BIT_SHA,
            'PRODUCT_BITSTREAM_IDENTITY_MISMATCH')
    require(dcp.stat().st_size == 15_726_324 and sha(dcp) == DCP_SHA,
            'PRODUCT_DCP_IDENTITY_MISMATCH')
    require(controller_driver.stat().st_size == 3_296_104 and
            sha(controller_driver) == DRIVER_SHA,
            'DRIVER_CONTROLLER_SEALED_COPY_MISMATCH')
    abi = ROOT / 'scripts' / 'V41_C2H_TRANSPORT_ABI_V1.json'
    require(sha(abi) == ABI_SHA, 'FROZEN_ABI_HASH_MISMATCH')

    driver = git_json(
        EVIDENCE_REPO,
        f'{DRV_COMMIT}:v41-host-g2b-hw0-ahd-xdma-driver-build/G2B_HW0_DRV1_STATE.json',
    )
    require(driver['engineering_gate'] == 'PASS' and
            driver['candidate']['sha256'] == DRIVER_SHA and
            driver['candidate']['internal_module_name'] == 'xdma_ahd_pcie' and
            driver['candidate']['vermagic'] ==
            '7.0.0-29-generic SMP preempt mod_unload modversions ' and
            driver['sealed_artifacts']['remote_module_path'] ==
            '/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko',
            'DRV1_AUTHORITY_MISMATCH')
    return {
        'result': 'PASS', 'project_state_rev': 8,
        'meta8a_authoritative': True, 'g2b_hw_qualified': False,
        'remote_main_before_publication': remote_main,
        'r3r3_evidence_commit': R3R3_COMMIT,
        'r3r3_manifest_entries_verified': manifest_count,
        'r3r3_state_verified': True,
        'source_branch': 'integration/v41-g2b-onech-c2h',
        'source_commit': SOURCE_COMMIT, 'source_tree': SOURCE_TREE,
        'source_remote_match': True, 'source_tracked_clean': True,
        'bitstream_bytes': bitstream.stat().st_size,
        'bitstream_sha256': BIT_SHA, 'dcp_bytes': dcp.stat().st_size,
        'dcp_sha256': DCP_SHA, 'driver_sha256': DRIVER_SHA,
        'driver_authority_commit': DRV_COMMIT,
        'abi_sha256': ABI_SHA,
        'runtime_embedded_git_sha_expected':
            '224d194e5f82c85bcb29297561c5d5e76d28063b',
        'runtime_build_flags_expected': '0x00000103',
    }


def helper_audit() -> dict:
    helper = ROOT / 'scripts' / 'Invoke-R3R4DutConnection.ps1'
    text = helper.read_text(encoding='utf-8')
    args_match = re.search(r'\$argsList\s*=\s*@\((.*?)\)\s*\n', text, re.DOTALL)
    require(args_match is not None, 'R3R4_HELPER_ARGUMENT_LIST_NOT_FOUND')
    actual_argument_list = args_match.group(1)
    checks = {
        'pinned_host_key':
            'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' in text,
        'pwfile_used': "'-pwfile'" in text,
        'plain_pw_switch_absent':
            re.search(r"['\"]-pw['\"]", actual_argument_list) is None,
        'plain_pw_switch_guard_present': "-ceq '-pw'" in text,
        'private_acl_check': 'Assert-PrivateAcl' in text,
        'credential_deleted_finally':
            'Remove-Item -LiteralPath $temp -Force' in text,
        'process_argument_secret_guard': 'R3R4_SECRET_ARGUMENT' in text,
        'credential_not_in_environment': 'psi.Environment.Remove' in text,
        'receipt_source_hash': 'helper_sha256=' in text,
        'remote_ip_exact': "'10.132.1.111'" in text,
    }
    require(all(checks.values()), 'R3R4_CREDENTIAL_HELPER_AUDIT_FAILED')
    remnants = list(ROOT.rglob('*.credential.tmp'))
    require(not remnants, 'R3R4_CREDENTIAL_REMNANT')
    return {
        'result': 'PASS', 'helper': str(helper), 'helper_sha256': sha(helper),
        'checks': checks, 'credential_remnants': 0,
        'invocations': len(list((ROOT / 'logs').glob('connection-*.json'))),
    }


def capture_gate() -> dict:
    failure_path = ROOT / 'artifacts' / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_FAILURE.json'
    failure = json.loads(failure_path.read_text(encoding='utf-8'))
    require(failure['blocker'] == BLOCKER and failure['hardware_access'] is False and
            failure['dut_connections'] == 0 and
            failure['exception_type'] == 'AssertionError',
            'R3R4_CAPTURE_FAILURE_RECEIPT_INVALID')
    synthetic = ROOT / 'artifacts' / 'offline-selftest' / 'successful-capture'
    reader = json.loads((synthetic / 'T34-reader-result.json').read_text())
    require(reader['result'] == 'PASS' and reader['primary_records'] == 2500 and
            reader['drain_records'] == 7 and
            reader['incomplete_trailing_bytes'] == 0 and
            reader['first_record_durable'] is True and
            reader['first_record_valid'] is True,
            'R3R4_FIRST_SELFTEST_CASE_EVIDENCE_INVALID')
    require((synthetic / 'T34-primary-records.bin').stat().st_size == 10_240_000 and
            (synthetic / 'T34-drain-records.bin').stat().st_size == 28_672 and
            (synthetic / 'T34-first-record.bin').stat().st_size == 4096 and
            (synthetic / 'T34-first-payload.bin').stat().st_size == 3840,
            'R3R4_SYNTHETIC_SELFTEST_FILE_SIZE_INVALID')
    return {
        'result': 'FAIL', 'blocker': BLOCKER,
        'selftests_passed_before_stop': 1, 'selftests_total': 11,
        'first_completed_case': 'FIRST_RECORD_PERSISTENCE_PASS',
        'failed_case': 'PARTIAL_READ_ASSEMBLY_PASS',
        'failure_detail': 'Self-test harness assertion part_count > len(records) failed.',
        'exception_type': failure['exception_type'],
        'exception_repr': failure['exception_repr'],
        'traceback': failure['traceback'],
        'hardware_access': False, 'dut_connections': 0,
        'first_record_asynchronous_persistence': 'PASS',
        'raw_payload_control_ipc': False,
        'parent_owned_mmio_design': True,
        'parent_owned_quiescence_design': True,
        'capture_tool': str(ROOT / 'scripts' / 'capture_r3r4.py'),
        'capture_tool_sha256': sha(ROOT / 'scripts' / 'capture_r3r4.py'),
    }


def prior_boundary() -> dict:
    protected_paths = [
        path for path in EVIDENCE_REPO.iterdir()
        if path.is_dir() and re.search(r'product-live-path-bringup-r3(?:r[123])?',
                                       path.name, re.IGNORECASE)
    ]
    status = git_text(EVIDENCE_REPO, 'status', '--porcelain', '--',
                      *[str(path.relative_to(EVIDENCE_REPO))
                        for path in protected_paths]) if protected_paths else ''
    require(not status, 'PRIOR_PUBLISHED_EVIDENCE_CHANGED')
    root_birth = ROOT.stat().st_ctime_ns
    late_files = []
    for predecessor in Path(r'C:\FPGA').glob('G2B_HW0_PRODUCT_R3R3_*'):
        for path in predecessor.rglob('*'):
            if path.is_file() and path.stat().st_mtime_ns > root_birth:
                late_files.append(str(path))
    require(not late_files, 'PRIOR_R3R3_RUN_ARTIFACT_CHANGED')
    ssot_status = git_text(EVIDENCE_REPO, 'status', '--porcelain', '--',
                           'project-current-state')
    require(not ssot_status, 'SSOT_CHANGED')
    return {
        'result': 'PASS', 'prior_immutable_artifact_new_writes': 0,
        'protected_published_directories_checked': len(protected_paths),
        'prior_r3r3_late_files': 0, 'ssot_changes': 0,
        'preexisting_untracked_work_areas_preserved': ['.diag0-work/', '.meta8a-work/'],
    }


def report_not_reached(title: str, reason: str = BLOCKER) -> str:
    return f'''# {title}

Result: `NOT_REACHED`.

The governed R3R4 run stopped before its first DUT connection because the mandatory offline capture-tool hard gate failed with `{reason}`. No hardware, driver, PCIe, JTAG, MMIO, DMA, lock, reboot, power, Flash, NVP, or camera operation was performed. No value from R3R3 is reinterpreted as a current R3R4 observation.
'''


def build() -> dict:
    require(not STAGE.exists(), 'R3R4_PUBLIC_STAGE_ALREADY_EXISTS')
    authority = verify_authority()
    helper = helper_audit()
    capture_gate_result = capture_gate()
    boundary = prior_boundary()
    STAGE.mkdir(parents=True)
    (STAGE / 'tools').mkdir()
    (STAGE / 'raw').mkdir()

    write_json(ROOT / 'logs/authority-verification.json', authority)
    write_json(ROOT / 'logs/helper-audit.json', helper)
    write_json(ROOT / 'logs/capture-hard-gate.json', capture_gate_result)
    write_json(ROOT / 'logs/boundary-final.json', boundary)

    state = {
        'task': TASK, 'engineering_gate': 'BLOCKED',
        'evidence_publication': 'SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK',
        'overall_result': 'BLOCKED', 'first_blocker': BLOCKER,
        'project_state_rev_at_start': 8, 'project_state_rev_at_end': 8,
        'r3r3_evidence': 'VERIFIED', 'owner_r3r4_authorization': 'GRANTED',
        'run_root': str(ROOT), 'linux_root': None,
        'credential_helper': str(ROOT / 'scripts' / 'Invoke-R3R4DutConnection.ps1'),
        'credential_helper_sha256': helper['helper_sha256'],
        'credential_helper_hard_gate': 'PASS', 'credential_remnants': 0,
        'capture_tool': str(ROOT / 'scripts' / 'capture_r3r4.py'),
        'capture_tool_sha256': capture_gate_result['capture_tool_sha256'],
        'capture_tool_architecture_hard_gate': 'FAIL',
        'capture_tool_offline_selftests': {'passed': 1, 'total': 11},
        'first_record_asynchronous_persistence_offline': 'PASS',
        'raw_payload_control_ipc': False, 'parent_owned_mmio_design': True,
        'parent_owned_quiescence_design': True,
        'prior_immutable_artifact_new_writes': 0,
        'hardware_accessed': False, 'dut_connections': 0,
        'current_boot_id': None, 'boot_continuity': 'NOT_REACHED',
        'dut_exclusivity': 'NOT_REACHED', 'parallel_hdmi_activity': 'UNRESOLVED',
        'fpga_device': None, 'fpga_idcode': None,
        'fpga_done_before': None, 'fpga_done_after': None,
        'product_candidate_continuity': 'NOT_REACHED',
        'fpga_sram_programming': 0, 'warm_reboots': 0, 'power_cycles': 0,
        'flash_programming': 0, 'driver_load_attempts': 0,
        'driver_module_loaded': 'NOT_RUN', 'endpoint_bound': 'NOT_RUN',
        'combined_t34_sessions': 0, 'reset_writes': 0,
        'stream_enable_writes': 0, 'normal_disable_writes': 0,
        'safety_disable_writes': 0, 'snapshot_writes': 0,
        'nonfatal_w1c_writes': 0, 'fatal_w1c_writes': 0,
        'statistics_clear_writes': 0, 'unauthorized_mmio_writes': 0,
        't3_persistent_first_record': 'NOT_REACHED',
        't4_finite_capture': 'NOT_REACHED', 'primary_records_requested': 2500,
        'primary_records_received': None, 'drain_records': None,
        'incomplete_trailing_bytes': None,
        'counter_reconciliation': 'NOT_REACHED',
        'frame_reconstruction': 'NOT_REACHED',
        'pcie_aer_kernel_health': 'NOT_REACHED', 'cleanup': 'NOT_REQUIRED',
        'raw_records_published': False, 'raw_frame_published': False,
        'viewable_camera_image_published': False,
        'continuous_60_second_capture': 'NOT_RUN',
        'throughput_288_MBps': 'NOT_PROVEN', 'four_input': 'NOT_QUALIFIED',
        'two_channel': 'NOT_QUALIFIED', 'synthetic_generator': 'NOT_TESTED',
        'v4l2': 'NOT_TESTED', 'full_g2b_hw': 'NOT_YET_PROVEN',
        'ssot_update_required': False,
        'recommended_next_step':
            'Create a new R3R4 run root, correct the partial-read chunk-count self-test assertion, and require all 11/11 offline cases before any DUT connection.',
        'final_execution_point':
            'HARD STOP AT R3R4_CAPTURE_TOOL_HARD_GATE_FAILED BEFORE DUT CONNECTION',
    }

    write_text(STAGE / 'V41_G2B_HW0_PRODUCT_R3R4_MAIN_REPORT.md', f'''# AHD v41 G2B-HW0-PRODUCT-R3R4

## Outcome

- Engineering gate: `BLOCKED`
- Evidence publication: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `{BLOCKER}`
- Hardware accessed: `NO`

## Governed stop

The fresh run stopped before its first DUT connection. The mandatory offline suite completed `FIRST_RECORD_PERSISTENCE_PASS`, then the test harness failed while evaluating `PARTIAL_READ_ASSEMBLY_PASS` because the assertion `part_count > len(records)` was false. This is an offline orchestration-test defect, not a hardware observation. The frozen rule requires a hard stop on any self-test failure, so no correction or rerun occurred in this run.

## Preserved boundaries

PROJECT_STATE_REV remained 8. R3R3 evidence commit `{R3R3_COMMIT}` and its {authority['r3r3_manifest_entries_verified']} manifested files were verified without reclassifying its 53 volatile records. The PRODUCT and driver authority hashes matched. No DUT lock, SSH connection, JTAG, PCIe inventory, module load, bind, MMIO, DMA, stream, reboot, power-cycle, FPGA programming, Flash programming, NVP access, or video capture occurred. Prior immutable artifact new writes: `0`. No real camera bytes exist in this run or this package.

## Corrective action

Create a completely new R3R4 run root, correct the partial-read chunk-count test assertion, and require all `11/11` offline cases before the first DUT connection.
''')

    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_AUTHORIZATION_RECEIPT.md', f'''# R3R4 authorization receipt

Owner authorization was `GRANTED` by the R3R4 directive. The directive's permitted hardware operations were never reached. Prohibited FPGA programming, Flash programming, reboot, power-cycle, PCI rescan/reset, manual bind/unbind, `new_id`, `driver_override`, platform `xdma`, H2C, NVP writes, input switching, statistics clear, V4L2, synthetic generator, and release creation all remained unperformed.

First blocker: `{BLOCKER}`. Hardware accessed: `NO`.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_AUTHORITY_VERIFICATION.md', f'''# R3R4 authority verification

Result: `PASS` for the offline authority checks completed before the tool hard gate.

- PROJECT_STATE_REV: `8`; META-8A authoritative; G2B-HW not qualified; no newer remote `main` revision before publication.
- R3R3 evidence: `VERIFIED` at `{R3R3_COMMIT}`; manifested entries verified byte-for-byte: `{authority['r3r3_manifest_entries_verified']}`.
- Source: `integration/v41-g2b-onech-c2h` / `{SOURCE_COMMIT}` / `{SOURCE_TREE}`; tracked clean and remote-matching.
- PRODUCT bitstream SHA-256: `{BIT_SHA}`.
- Signed-off DCP SHA-256: `{DCP_SHA}`.
- Driver authority commit: `{DRV_COMMIT}`; sealed controller copy SHA-256: `{DRIVER_SHA}`.
- Frozen ABI SHA-256: `{ABI_SHA}`.

Current DUT continuity was not checked because the offline hard gate stopped before the first connection.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_BOUNDARY_RECEIPT.md', f'''# R3R4 boundary receipt

Prior immutable artifact new writes: `0`. SSOT changes: `0`. Source tracked changes: `0`. The pre-existing untracked evidence work areas `.diag0-work/` and `.meta8a-work/` were preserved and excluded. All R3R4 writes remained under `{ROOT}` until publication of this new evidence directory.

Hardware access: `NO`. Real-video payload published: `NO`.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_CREDENTIAL_HELPER_AUDIT.md', f'''# R3R4 credential-helper audit

Result: `PASS` (offline static hard gate).

- Helper: `Invoke-R3R4DutConnection.ps1`
- SHA-256: `{helper['helper_sha256']}`
- Pinned host key: `PASS`
- Credential in process arguments: `NO`
- ACL-restricted temporary credential design: `PASS`
- Finally-path deletion and zero-remnant check: `PASS`
- Helper invocations: `0`
- Credential remnants: `0`

No DUT connection was attempted.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_DUT_LOCK_RECEIPT.md',
               report_not_reached('R3R4 DUT lock receipt') +
               '\nController lock acquired: `NO`. Linux lock acquired: `NO`.\n')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_AUDIT.md', f'''# R3R4 capture-tool architecture audit

Integrated hard-gate result: `FAIL`.

The source implements parent-only MMIO, compact control IPC, direct private-file persistence, a separate first-record persister thread, a 2500-record primary boundary, bounded 512-record drain, parent quiescence, and cooperative one-second quiet exit. The first synthetic persistence case completed. However, the mandatory suite stopped at `1/11` because its partial-read case used an invalid chunk-count assertion. Under the frozen rule, any self-test failure fails the architecture hard gate for this run.

Blocker: `{BLOCKER}`. DUT connections: `0`. Hardware access: `NO`.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_SELFTEST.md', f'''# R3R4 capture-tool offline self-test

- Result: `FAIL`
- Passed before stop: `1/11`
- Completed PASS: `FIRST_RECORD_PERSISTENCE_PASS`
- Failed case: `PARTIAL_READ_ASSEMBLY_PASS`
- Failure: `AssertionError` at the harness assertion `part_count > len(records)`
- First-record asynchronous persistence: `PASS`
- Raw record payload through control IPC: `NO`
- Hardware access: `NO`
- DUT connections: `0`

The test run and its synthetic files were preserved privately under the fresh controller root. Synthetic raw fixtures are not included in public evidence.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_PRELOAD_INVENTORY.md',
               report_not_reached('R3R4 preload inventory'))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_DRIVER_VERIFICATION.md', f'''# R3R4 driver verification

DRV1 authority evidence was verified at `{DRV_COMMIT}`. The sealed controller copy is 3,296,104 bytes with SHA-256 `{DRIVER_SHA}`, internal name `xdma_ahd_pcie`, and governed vermagic `7.0.0-29-generic SMP preempt mod_unload modversions `.

The exact Linux DUT module path was not connected to or rehashed in R3R4 because the offline hard gate failed. Driver load attempts: `0`.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_DRIVER_LOAD_PROBE.md',
               report_not_reached('R3R4 driver load and automatic probe') +
               '\nDriver load attempts: `0`. Manual bind/unbind: `NO`.\n')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_NODE_TO_BDF_PROOF.md',
               report_not_reached('R3R4 node-to-BDF proof'))
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_NODE_MAP.csv',
              ['Result','Node','BDF','Reason'],
              [{'Result':'NOT_REACHED','Node':'N/A','BDF':'N/A','Reason':BLOCKER}])
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_MMIO_RAW.csv',
              ['Timestamp','Session','UserNode','BDF','Offset','Operation','Value','Result'],
              [{'Timestamp':'N/A','Session':'N/A','UserNode':'N/A','BDF':'N/A',
                'Offset':'N/A','Operation':'NONE','Value':'N/A','Result':'NOT_REACHED'}])
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_MMIO_DECODED.md',
               report_not_reached('R3R4 MMIO decoded evidence') +
               '\nMMIO reads: `0`. MMIO writes: `0`.\n')
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_MMIO_WRITE_LEDGER.csv',
              ['Timestamp','Session','UserNode','BDF','Offset','Operation','Value',
               'Purpose','Authorized','Precondition','Result'],
              [{'Timestamp':'N/A','Session':'N/A','UserNode':'N/A','BDF':'N/A',
                'Offset':'N/A','Operation':'NONE','Value':'N/A','Purpose':'NONE',
                'Authorized':'N/A','Precondition':'OFFLINE_HARD_GATE_FAILED',
                'Result':'NOT_REACHED'}])
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_SESSION_START_RECEIPT.md',
               report_not_reached('R3R4 combined T3/T4 session start') +
               '\nCombined T3/T4 sessions: `0`.\n')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_FIRST_RECORD_REPORT.md',
               report_not_reached('R3R4 persistent first-record report') +
               '\nThe offline synthetic first-record case passed; that is not a hardware result.\n')
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_FIRST_RECORD_HEADER.csv',
              ['Result','Field','Value','Reason'],
              [{'Result':'NOT_REACHED','Field':'N/A','Value':'N/A','Reason':BLOCKER}])
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_FINITE_CAPTURE_REPORT.md',
               report_not_reached('R3R4 finite 2500-record capture'))
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_FINITE_CAPTURE_METRICS.csv',
              ['Metric','Value','Result'], [
                  {'Metric':'primary_records_requested','Value':'2500','Result':'NOT_REACHED'},
                  {'Metric':'primary_records_received','Value':'N/A','Result':'NOT_REACHED'},
                  {'Metric':'drain_records','Value':'N/A','Result':'NOT_REACHED'},
                  {'Metric':'incomplete_trailing_bytes','Value':'N/A','Result':'NOT_REACHED'},
              ])
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_RECORD_VALIDATION_SUMMARY.md',
               report_not_reached('R3R4 full record validation'))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_COUNTER_RECONCILIATION.md',
               report_not_reached('R3R4 counter reconciliation'))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_FRAME_RECONSTRUCTION_REPORT.md',
               report_not_reached('R3R4 complete-frame reconstruction'))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_PCIE_AER_KERNEL_REVIEW.md',
               report_not_reached('R3R4 PCIe, AER, driver, and kernel review'))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_CLEANUP_RECEIPT.md', f'''# R3R4 cleanup receipt

Result: `NOT_REQUIRED_NO_HARDWARE_ACCESS`.

The run stopped before controller or Linux lock acquisition and before the first DUT connection. Task-loaded modules: `0`; task-created XDMA nodes: `0`; stream enables: `0`; open task-owned XDMA descriptors: `0`. No driver unload or hardware rollback was required.
''')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_FINAL_HARDWARE_STATE.md', f'''# R3R4 final hardware state

Hardware accessed: `NO`. Current boot ID, FPGA DONE, PCIe link, endpoint state, driver state, and DMA state are `NOT_REACHED` and are not inferred from R3R3. FPGA SRAM programming, Flash programming, warm reboot, cold reboot, power-cycle, PCIe reset/rescan, driver load, MMIO, and DMA counts are all `0` for R3R4.

Candidate left in volatile SRAM: `UNRESOLVED` because no current hardware observation was authorized after the offline hard stop.
''')
    write_csv(STAGE / 'G2B_HW0_PRODUCT_R3R4_GATE_MATRIX.csv',
              ['Gate','Result','Blocker_or_basis'], [
                  {'Gate':'Authority and predecessor evidence','Result':'PASS','Blocker_or_basis':'PROJECT_STATE_REV_8_AND_R3R3_VERIFIED'},
                  {'Gate':'Credential helper static audit','Result':'PASS','Blocker_or_basis':'PINNED_NO_SECRET_ARGUMENT_ACL_DELETE'},
                  {'Gate':'Capture tool offline hard gate','Result':'FAIL','Blocker_or_basis':BLOCKER},
                  {'Gate':'T0 continuity and exclusivity','Result':'NOT_REACHED','Blocker_or_basis':BLOCKER},
                  {'Gate':'T1 driver load and node proof','Result':'NOT_REACHED','Blocker_or_basis':BLOCKER},
                  {'Gate':'T2 runtime identity and source','Result':'NOT_REACHED','Blocker_or_basis':BLOCKER},
                  {'Gate':'T3 persistent first record','Result':'NOT_REACHED','Blocker_or_basis':BLOCKER},
                  {'Gate':'T4 finite capture and frame','Result':'NOT_REACHED','Blocker_or_basis':BLOCKER},
                  {'Gate':'Cleanup','Result':'NOT_REQUIRED','Blocker_or_basis':'NO_HARDWARE_ACCESS'},
                  {'Gate':'Engineering','Result':'BLOCKED','Blocker_or_basis':BLOCKER},
              ])
    write_json(STAGE / 'G2B_HW0_PRODUCT_R3R4_STATE.json', state)

    for name in (
        'Invoke-R3R4DutConnection.ps1', 'capture_r3r4.py',
        'capture_r3r4_selftest.py', 'frame_reconstruct_r3r4.py',
        'abi_v1.py', 'V41_C2H_TRANSPORT_ABI_V1.json',
        'build_blocked_evidence_r3r4.py',
    ):
        shutil.copyfile(ROOT / 'scripts' / name, STAGE / 'tools' / name)
    shutil.copyfile(ROOT / 'artifacts' /
                    'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_FAILURE.json',
                    STAGE / 'raw' /
                    'G2B_HW0_PRODUCT_R3R4_CAPTURE_TOOL_FAILURE.json')
    write_json(STAGE / 'raw' / 'G2B_HW0_PRODUCT_R3R4_AUTHORITY.json', authority)
    write_json(STAGE / 'raw' / 'G2B_HW0_PRODUCT_R3R4_BOUNDARY.json', boundary)

    index_names = sorted(str(path.relative_to(STAGE)).replace('\\','/')
                         for path in STAGE.rglob('*') if path.is_file())
    index_names.extend([
        'G2B_HW0_PRODUCT_R3R4_EVIDENCE_INDEX.md',
        'G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt',
    ])
    index_names = sorted(set(index_names))
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_EVIDENCE_INDEX.md',
               '# R3R4 evidence index\n\n' +
               '\n'.join(f'- `{name}`' for name in index_names) +
               '\n\nReal camera/video payload files published: `0`.')
    manifest_lines = []
    for path in sorted(item for item in STAGE.rglob('*') if item.is_file() and
                       item.name != 'G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt'):
        relative = str(path.relative_to(STAGE)).replace('\\','/')
        manifest_lines.append(f'{sha(path)}  {relative}')
    write_text(STAGE / 'G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt',
               '\n'.join(manifest_lines))

    # Local manifest read-back.
    for line in (STAGE / 'G2B_HW0_PRODUCT_R3R4_SHA256_MANIFEST.txt').read_text().splitlines():
        expected, relative = line.split('  ', 1)
        require(sha(STAGE / relative) == expected,
                'R3R4_LOCAL_MANIFEST_READBACK_FAILED:' + relative)
    receipt = {
        'result': 'PASS', 'stage': str(STAGE),
        'files': len([path for path in STAGE.rglob('*') if path.is_file()]),
        'manifest_entries': len(manifest_lines),
        'real_camera_payload_files': 0,
        'engineering_gate': 'BLOCKED', 'first_blocker': BLOCKER,
    }
    write_json(ROOT / 'logs/public-stage-seal.json', receipt)
    print(json.dumps(receipt, indent=2))
    return receipt


if __name__ == '__main__':
    try:
        build()
    except BaseException as exc:
        print(json.dumps({'result':'FAIL','exception_type':type(exc).__name__,
                          'exception_repr':repr(exc)}, indent=2))
        raise
