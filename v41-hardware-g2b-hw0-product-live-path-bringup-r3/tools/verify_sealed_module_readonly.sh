#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

lock_receipt=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock/receipt.json
module_dir="$HOME/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z"
module_path="$module_dir/xdma_ahd_pcie.ko"
expected_sha=e8b48e342c80b019bb4884fd7af16ab1049bc60266101e6e4a8b6514aeeb3d77
expected_size=3296104
expected_alias='pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*'
expected_vermagic='7.0.0-29-generic SMP preempt mod_unload modversions '
expected_build_id=1471c3a284ec1cb26115fe9e9bd59890a034f83e
expected_srcversion=EE8B149D1883AE8C6B1EE31
bdf=0000:01:00.0

test "$(hostname)" = VCDE-DUT-1
test "$(id -u)" = 1000
test "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
test "$(uname -r)" = 7.0.0-29-generic
test "$(uname -m)" = x86_64
test -f "$lock_receipt"
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R3"' "$lock_receipt"
grep -Fq '"lock_release_state": "HELD"' "$lock_receipt"
test -d "$module_dir"
test -f "$module_path"
test ! -L "$module_path"

dir_mode="$(stat -Lc '%A' "$module_dir")"
file_mode="$(stat -Lc '%A' "$module_path")"
[[ "$dir_mode" != *w* ]]
[[ "$file_mode" != *w* ]]
size="$(stat -Lc '%s' "$module_path")"
sha="$(sha256sum "$module_path" | awk '{print $1}')"
name="$(modinfo -F name "$module_path")"
vermagic="$(modinfo -F vermagic "$module_path")"
mapfile -t aliases < <(modinfo -F alias "$module_path")
depends="$(modinfo -F depends "$module_path")"
srcversion="$(modinfo -F srcversion "$module_path")"
signer="$(modinfo -F signer "$module_path")"
sig_id="$(modinfo -F sig_id "$module_path")"
build_id="$(readelf -n "$module_path" | awk '/Build ID:/ {print $3; exit}')"
machine="$(readelf -h "$module_path" | awk -F: '/Machine:/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')"
elf_class="$(readelf -h "$module_path" | awk -F: '/Class:/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')"

test "$size" -eq "$expected_size"
test "$sha" = "$expected_sha"
test "$name" = xdma_ahd_pcie
test "$vermagic" = "$expected_vermagic"
test "${#aliases[@]}" -eq 1
test "${aliases[0]}" = "$expected_alias"
test -z "$depends"
test "$srcversion" = "$expected_srcversion"
test -z "$signer"
test -z "$sig_id"
test "$build_id" = "$expected_build_id"
test "$machine" = 'Advanced Micro Devices X86-64'
test "$elf_class" = ELF64
test "$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)" -eq 0
test "$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)" -eq 0
test ! -L "/sys/bus/pci/devices/$bdf/driver"
test "$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)" -eq 0

secure_boot="$(mokutil --sb-state 2>&1 || true)"
printf '%s\n' "$secure_boot" | grep -Fq 'SecureBoot disabled'

echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=SEALED_MODULE_IMMEDIATE_PRELOAD_VERIFICATION
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo RESOLVED_MODULE_PATH="$module_path"
echo MODULE_DIRECTORY_STAT="$(stat -Lc '%a:%A:%U:%G:%s' "$module_dir")"
echo MODULE_FILE_STAT="$(stat -Lc '%a:%A:%U:%G:%s' "$module_path")"
echo MODULE_REGULAR_FILE=YES
echo MODULE_SYMLINK=NO
echo MODULE_DIRECTORY_READ_ONLY=YES
echo MODULE_PAYLOAD_READ_ONLY=YES
echo MODULE_SIZE="$size"
echo MODULE_SHA256="${sha^^}"
echo MODULE_NAME="$name"
printf 'MODULE_VERMAGIC=%s\n' "$vermagic"
echo MODULE_ALIAS_COUNT="${#aliases[@]}"
echo MODULE_ALIAS="${aliases[0]}"
echo MODULE_DEPENDS="${depends:-EMPTY}"
echo MODULE_SRCVERSION="$srcversion"
echo MODULE_SIGNER="${signer:-UNSIGNED}"
echo MODULE_SIG_ID="${sig_id:-NONE}"
echo MODULE_GNU_BUILD_ID="$build_id"
echo MODULE_ELF_CLASS="$elf_class"
echo MODULE_MACHINE="$machine"
echo MODULE_FILE_UTILITY="$(file -b "$module_path")"
echo SECURE_BOOT_STATE_BEGIN
printf '%s\n' "$secure_boot"
echo SECURE_BOOT_STATE_END
echo KERNEL_TAINT_PRELOAD="$(cat /proc/sys/kernel/tainted)"
echo PLATFORM_XDMA_MODULE_COUNT=0
echo AHD_XDMA_MODULE_COUNT=0
echo XDMA_NODE_COUNT=0
echo ENDPOINT_DRIVER=NONE
echo LINUX_LOCK=HELD
echo RESULT=PASS
