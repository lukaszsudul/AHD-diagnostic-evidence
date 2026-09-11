#!/usr/bin/env bash
# SANITIZED PUBLICATION COPY; executed-source SHA-256: 8BAF57F81E34D20D9552E4BB0976E4C9742EC5EF8DD68D126F7FC921A6BE5513
set -euo pipefail
umask 077

EXPECTED_USER='DUT_USER_REDACTED'
HOME_ROOT='/home/DUT_USER_REDACTED'
ARTIFACT_BASE='/home/DUT_USER_REDACTED/vcde_artifacts'
TASK_PARENT='/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1'
RUN_ID='20260911T202728Z'
RUN_ROOT="${TASK_PARENT}/${RUN_ID}"
NONCE='37adf301793c4ff49cf4a8b7e3d769e5'
PROBE_ROOT="${TASK_PARENT}/.bootstrap-probe-${NONCE}"
LOCK_PARENT='/home/DUT_USER_REDACTED/vcde_artifacts'
LOCK_PROBE="${LOCK_PARENT}/.scan1-r1r1-lock-probe-${NONCE}.lock"

cleanup_probe() {
  if [[ -d "${LOCK_PROBE}" && ! -L "${LOCK_PROBE}" ]]; then
    rm -f -- "${LOCK_PROBE}/receipt"
    rmdir -- "${LOCK_PROBE}" 2>/dev/null || true
  fi
  if [[ -d "${PROBE_ROOT}" && ! -L "${PROBE_ROOT}" ]]; then
    rm -f -- "${PROBE_ROOT}/a/b/c/write-read.probe"
    rmdir -- "${PROBE_ROOT}/a/b/c" 2>/dev/null || true
    rmdir -- "${PROBE_ROOT}/a/b" 2>/dev/null || true
    rmdir -- "${PROBE_ROOT}/a" 2>/dev/null || true
    rmdir -- "${PROBE_ROOT}" 2>/dev/null || true
  fi
}
trap cleanup_probe EXIT

[[ "$(id -un)" == "${EXPECTED_USER}" ]]
[[ -d "${HOME_ROOT}" && ! -L "${HOME_ROOT}" ]]
[[ -d "${ARTIFACT_BASE}" && ! -L "${ARTIFACT_BASE}" ]]
[[ -d "${LOCK_PARENT}" && ! -L "${LOCK_PARENT}" ]]

install -d -m 0700 -- "${TASK_PARENT}"
[[ -d "${TASK_PARENT}" && ! -L "${TASK_PARENT}" ]]
[[ "$(stat -c '%U' -- "${TASK_PARENT}")" == "${EXPECTED_USER}" ]]
chmod 0700 -- "${TASK_PARENT}"

[[ ! -e "${PROBE_ROOT}" && ! -L "${PROBE_ROOT}" ]]
mkdir -p -- "${PROBE_ROOT}/a/b/c"
chmod 0700 -- "${PROBE_ROOT}" "${PROBE_ROOT}/a" "${PROBE_ROOT}/a/b" "${PROBE_ROOT}/a/b/c"
for probe_dir in "${PROBE_ROOT}" "${PROBE_ROOT}/a" "${PROBE_ROOT}/a/b" "${PROBE_ROOT}/a/b/c"; do
  [[ "$(stat -c '%U' -- "${probe_dir}")" == "${EXPECTED_USER}" ]]
  [[ "$(stat -c '%a' -- "${probe_dir}")" == '700' ]]
done
python3 - "${PROBE_ROOT}/a/b/c/write-read.probe" "${NONCE}" <<'PY'
import os
import sys
path, nonce = sys.argv[1:]
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
try:
    data = (nonce + "\n").encode("ascii")
    if os.write(fd, data) != len(data):
        raise RuntimeError("short write")
    os.fsync(fd)
finally:
    os.close(fd)
PY
[[ "$(cat -- "${PROBE_ROOT}/a/b/c/write-read.probe")" == "${NONCE}" ]]
rm -f -- "${PROBE_ROOT}/a/b/c/write-read.probe"
rmdir -- "${PROBE_ROOT}/a/b/c" "${PROBE_ROOT}/a/b" "${PROBE_ROOT}/a" "${PROBE_ROOT}"
printf '%s\n' 'DISPOSABLE_NESTED_ROOT_BOOTSTRAP_TEST=PASS'

[[ ! -e "${RUN_ROOT}" && ! -L "${RUN_ROOT}" ]]
install -d -m 0700 -- "${RUN_ROOT}"
for child in runtime-bundle scripts logs scanner captures campaign private artifacts evidence-staging; do
  install -d -m 0700 -- "${RUN_ROOT}/${child}"
done
chmod 0700 -- "${TASK_PARENT}" "${RUN_ROOT}" "${RUN_ROOT}/private"

[[ -d "${RUN_ROOT}" && ! -L "${RUN_ROOT}" ]]
RESOLVED_PARENT="$(readlink -f -- "${TASK_PARENT}")"
RESOLVED_RUN="$(readlink -f -- "${RUN_ROOT}")"
[[ "${RESOLVED_PARENT}" == "${TASK_PARENT}" ]]
case "${RESOLVED_RUN}" in
  "${RESOLVED_PARENT}"/*) ;;
  *) exit 41 ;;
esac
[[ "$(stat -c '%U' -- "${RUN_ROOT}")" == "${EXPECTED_USER}" ]]
[[ "$(stat -c '%a' -- "${RUN_ROOT}")" == '700' ]]
[[ -w "${RUN_ROOT}" ]]
EXPECTED_CHILDREN=$'artifacts\ncampaign\ncaptures\nevidence-staging\nlogs\nprivate\nruntime-bundle\nscanner\nscripts'
ACTUAL_CHILDREN="$(find "${RUN_ROOT}" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort)"
[[ "${ACTUAL_CHILDREN}" == "${EXPECTED_CHILDREN}" ]]

ROOT_PROBE="${RUN_ROOT}/.write-read-${NONCE}.probe"
python3 - "${ROOT_PROBE}" "${NONCE}" <<'PY'
import os
import sys
path, nonce = sys.argv[1:]
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
try:
    data = (nonce + "\n").encode("ascii")
    if os.write(fd, data) != len(data):
        raise RuntimeError("short write")
    os.fsync(fd)
finally:
    os.close(fd)
PY
[[ "$(cat -- "${ROOT_PROBE}")" == "${NONCE}" ]]
rm -f -- "${ROOT_PROBE}"
printf '%s\n' 'RECURSIVE_PARENT_CREATION=PASS'
printf '%s\n' 'DUT_RUN_ROOT_CONTAINMENT=PASS'
printf '%s\n' 'DUT_RUN_ROOT_OWNER_MODE=PASS'
printf '%s\n' 'DUT_ROOT_WRITE_READ_PROBE=PASS'
printf '%s\n' 'UNEXPECTED_PREEXISTING_FILES=0'

[[ ! -e "${LOCK_PROBE}" && ! -L "${LOCK_PROBE}" ]]
mkdir -- "${LOCK_PROBE}"
if mkdir -- "${LOCK_PROBE}" 2>/dev/null; then
  exit 42
fi
python3 - "${LOCK_PROBE}/receipt" "${NONCE}" <<'PY'
import os
import sys
path, nonce = sys.argv[1:]
fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
try:
    data = ("OWNER=G2B-NVP-CAMERA-SCAN1-R1R1\nNONCE=" + nonce + "\n").encode("ascii")
    if os.write(fd, data) != len(data):
        raise RuntimeError("short write")
    os.fsync(fd)
finally:
    os.close(fd)
PY
grep -Fx 'OWNER=G2B-NVP-CAMERA-SCAN1-R1R1' "${LOCK_PROBE}/receipt" >/dev/null
grep -Fx "NONCE=${NONCE}" "${LOCK_PROBE}/receipt" >/dev/null
rm -f -- "${LOCK_PROBE}/receipt"
rmdir -- "${LOCK_PROBE}"
printf '%s\n' 'ATOMIC_LOCK_FIRST_MKDIR=PASS'
printf '%s\n' 'ATOMIC_LOCK_SECOND_MKDIR=EXPECTED_FAIL'
printf '%s\n' 'ATOMIC_LOCK_METADATA_WRITE_READ=PASS'
printf '%s\n' 'ATOMIC_LOCK_PROBE_CLEANUP=PASS'
printf 'DUT_TASK_PARENT=%s\n' "${TASK_PARENT}"
printf 'DUT_RUN_ROOT=%s\n' "${RUN_ROOT}"
printf '%s\n' 'REMOTE_ROOT_BOOTSTRAP_GATE=PASS'
