#!/usr/bin/env bash
set -euo pipefail

umask 077

readonly UPSTREAM_URL='https://github.com/Xilinx/dma_ip_drivers.git'
readonly UPSTREAM_COMMIT='b8466090b4e812e191da9e9305ffb11cb7ace768'
readonly UPSTREAM_TREE='f9286c5d1bdae57285570ac5c23244d54076b99f'
readonly PATCH_SHA256='415F0836E56782D0F8667FA4510E63016A065A6F175A25433CD6D2EAA57E6AD7'
readonly EXPECTED_KERNEL='7.0.0-29-generic'
readonly EXPECTED_ARCH='x86_64'
readonly MODULE_NAME='xdma_ahd_pcie'
readonly MODULE_RELATIVE='XDMA/linux-kernel/xdma/xdma_ahd_pcie.ko'
readonly SOURCE_DATE_EPOCH_VALUE='1787236279'
readonly KBUILD_BUILD_TIMESTAMP_VALUE='Thu Aug 20 14:31:19 UTC 2026'
readonly KBUILD_BUILD_USER_VALUE='ahd-drv1'
readonly KBUILD_BUILD_HOST_VALUE='vcde-dut-1'
readonly KBUILD_BUILD_VERSION_VALUE='1'

fail() {
  printf 'G2B_HW0_DRV1_BUILD=FAIL\nERROR=%s\n' "$1" >&2
  exit 1
}

usage() {
  printf 'usage: %s --build-root ABSOLUTE_PATH --label BUILD_A|BUILD_B|BUILD_C\n' "$0" >&2
  exit 2
}

build_root=''
build_label=''
while (($#)); do
  case "$1" in
    --build-root)
      (($# >= 2)) || usage
      build_root=$2
      shift 2
      ;;
    --label)
      (($# >= 2)) || usage
      build_label=$2
      shift 2
      ;;
    *) usage ;;
  esac
done

[[ -n "$build_root" && "$build_label" =~ ^BUILD_[ABC]$ ]] || usage
[[ "$build_root" == /* ]] || fail 'BUILD_ROOT_NOT_ABSOLUTE'
case "$build_root/" in
  "$HOME/"*) ;;
  *) fail 'BUILD_ROOT_OUTSIDE_AUTHENTICATED_HOME' ;;
esac
[[ ! -e "$build_root" ]] || fail 'BUILD_ROOT_ALREADY_EXISTS'

for command_name in git make gcc ld ar as nm objcopy objdump strip sha256sum \
  modinfo readelf realpath stat awk grep sed find sort xargs python3; do
  command -v "$command_name" >/dev/null 2>&1 || fail "COMMAND_MISSING_${command_name}"
done

readonly running_kernel=$(uname -r)
readonly running_arch=$(uname -m)
[[ "$running_kernel" == "$EXPECTED_KERNEL" ]] || fail 'RUNNING_KERNEL_DRIFT'
[[ "$running_arch" == "$EXPECTED_ARCH" ]] || fail 'RUNNING_ARCH_DRIFT'
[[ ! -d "/sys/module/$MODULE_NAME" ]] || fail 'CANDIDATE_MODULE_ALREADY_LOADED'

readonly headers_link="/lib/modules/$EXPECTED_KERNEL/build"
[[ -e "$headers_link" ]] || fail 'EXACT_KERNEL_HEADERS_LINK_MISSING'
readonly headers_root=$(realpath -e -- "$headers_link")
for required_header_file in Makefile .config Module.symvers \
  include/generated/utsrelease.h include/generated/autoconf.h; do
  [[ -f "$headers_root/$required_header_file" ]] ||
    fail "HEADER_FILE_MISSING_${required_header_file//\//_}"
done

readonly script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
readonly patch_path="$script_dir/0001-ahd-exact-pci-match.patch"
[[ -f "$patch_path" && ! -L "$patch_path" ]] || fail 'AHD_PATCH_MISSING_OR_SYMLINK'
readonly actual_patch_sha=$(sha256sum -- "$patch_path" | awk '{print toupper($1)}')
[[ "$actual_patch_sha" == "$PATCH_SHA256" ]] || fail 'AHD_PATCH_SHA256_MISMATCH'

mkdir -p -- "$(dirname -- "$build_root")"
mkdir -- "$build_root"
readonly source_dir="$build_root/source"

git -c core.autocrlf=false clone --filter=blob:none --no-checkout \
  "$UPSTREAM_URL" "$source_dir"
git -C "$source_dir" -c core.autocrlf=false checkout --detach "$UPSTREAM_COMMIT"

readonly actual_commit=$(git -C "$source_dir" rev-parse HEAD)
readonly actual_tree=$(git -C "$source_dir" rev-parse 'HEAD^{tree}')
readonly actual_origin=$(git -C "$source_dir" remote get-url origin)
[[ "$actual_commit" == "$UPSTREAM_COMMIT" ]] || fail 'UPSTREAM_COMMIT_MISMATCH'
[[ "$actual_tree" == "$UPSTREAM_TREE" ]] || fail 'UPSTREAM_TREE_MISMATCH'
[[ "$actual_origin" == "$UPSTREAM_URL" ]] || fail 'UPSTREAM_ORIGIN_MISMATCH'
[[ -z "$(git -C "$source_dir" status --porcelain=v1 --untracked-files=all)" ]] ||
  fail 'UPSTREAM_CHECKOUT_NOT_CLEAN'

git -C "$source_dir" apply --check --whitespace=error-all "$patch_path"
git -C "$source_dir" apply --whitespace=error-all "$patch_path"
git -C "$source_dir" diff --check

mapfile -t changed_paths < <(git -C "$source_dir" diff --name-only | LC_ALL=C sort)
[[ ${#changed_paths[@]} -eq 2 ]] || fail 'SOURCE_DELTA_PATH_COUNT_NOT_TWO'
[[ "${changed_paths[0]}" == 'XDMA/linux-kernel/xdma/Makefile' ]] ||
  fail 'SOURCE_DELTA_PATH_0_UNEXPECTED'
[[ "${changed_paths[1]}" == 'XDMA/linux-kernel/xdma/xdma_mod.c' ]] ||
  fail 'SOURCE_DELTA_PATH_1_UNEXPECTED'

readonly module_dir="$source_dir/XDMA/linux-kernel/xdma"
readonly makefile="$module_dir/Makefile"
readonly module_source="$module_dir/xdma_mod.c"
[[ $(grep -Fxc 'TARGET_MODULE:=xdma_ahd_pcie' "$makefile") -eq 1 ]] ||
  fail 'UNIQUE_KBUILD_MODULE_IDENTITY_MISSING'
[[ $(grep -Fxc 'ccflags-y := -I$(topdir)/include $(XVC_FLAGS)' "$makefile") -eq 1 ]] ||
  fail 'KBUILD_INCLUDE_FLAG_MISSING'
[[ $(grep -Ec '^[[:space:]]*EXTRA_CFLAGS[[:space:]]*[:+?]?=' "$makefile" || true) -eq 0 ]] ||
  fail 'ACTIVE_EXTRA_CFLAGS_REMAINS'
[[ $(grep -Ec '^#define[[:space:]]+DRV_MODULE_NAME[[:space:]]+"xdma_ahd_pcie"$' "$module_source") -eq 1 ]] ||
  fail 'UNIQUE_PCI_DRIVER_NAME_MISSING'
[[ $(grep -Fxc $'\t{ PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007), },' "$module_source") -eq 1 ]] ||
  fail 'EXACT_AHD_PCI_ENTRY_MISSING'

python3 -I -S - "$module_source" <<'PY'
import pathlib
import re
import sys

text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
start = text.index("static const struct pci_device_id pci_ids[] = {")
end = text.index("MODULE_DEVICE_TABLE(pci, pci_ids);", start)
table = text[start:end]
entries = re.findall(r"PCI_DEVICE(?:_SUB)?\s*\(", table)
if len(entries) != 1:
    raise SystemExit("patched PCI table does not contain exactly one entry")
if "PCI_DEVICE_SUB(0x10ee, 0x7011, 0x10ee, 0x0007)" not in table:
    raise SystemExit("patched PCI table is not exact AHD identity")
PY

git -C "$source_dir" diff --no-ext-diff --binary -- \
  XDMA/linux-kernel/xdma/Makefile XDMA/linux-kernel/xdma/xdma_mod.c \
  >"$build_root/source.diff"
readonly source_diff_sha=$(sha256sum -- "$build_root/source.diff" | awk '{print toupper($1)}')

(
  cd -- "$source_dir"
  git ls-files -z | LC_ALL=C sort -z | xargs -0 sha256sum
) >"$build_root/source-inputs.sha256"
readonly source_inputs_sha=$(sha256sum -- "$build_root/source-inputs.sha256" | awk '{print toupper($1)}')

readonly make_path=$(realpath -e -- "$(command -v make)")
readonly compiler_path=$(realpath -e -- "$(command -v gcc)")
readonly linker_path=$(realpath -e -- "$(command -v ld)")
readonly archiver_path=$(realpath -e -- "$(command -v ar)")
readonly assembler_path=$(realpath -e -- "$(command -v as)")
readonly nm_path=$(realpath -e -- "$(command -v nm)")
readonly objcopy_path=$(realpath -e -- "$(command -v objcopy)")
readonly objdump_path=$(realpath -e -- "$(command -v objdump)")
readonly strip_path=$(realpath -e -- "$(command -v strip)")
readonly debug_root='/usr/src/xdma_ahd_pcie'
readonly prefix_flags="-fdebug-prefix-map=$source_dir=$debug_root -ffile-prefix-map=$source_dir=$debug_root -fmacro-prefix-map=$source_dir=$debug_root"

set +e
env -i HOME="$HOME" PATH=/usr/sbin:/usr/bin:/sbin:/bin LC_ALL=C \
  SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH_VALUE" \
  KBUILD_BUILD_TIMESTAMP="$KBUILD_BUILD_TIMESTAMP_VALUE" \
  KBUILD_BUILD_USER="$KBUILD_BUILD_USER_VALUE" \
  KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST_VALUE" \
  KBUILD_BUILD_VERSION="$KBUILD_BUILD_VERSION_VALUE" \
  "$make_path" -C "$module_dir" all V=1 \
  DEBUG=0 config_bar_num= xvc_bar_num= xvc_bar_offset= XVC_FLAGS= \
  BUILDSYSTEM_DIR="$headers_root" ARCH=x86_64 CROSS_COMPILE= \
  CC="$compiler_path" HOSTCC="$compiler_path" \
  LD="$linker_path" HOSTLD="$linker_path" AR="$archiver_path" \
  AS="$assembler_path" NM="$nm_path" OBJCOPY="$objcopy_path" \
  OBJDUMP="$objdump_path" STRIP="$strip_path" \
  KCFLAGS="$prefix_flags" KCPPFLAGS= CFLAGS_MODULE= LDFLAGS_MODULE= \
  KBUILD_EXTRA_SYMBOLS= \
  >"$build_root/make.stdout" 2>"$build_root/make.stderr"
make_rc=$?
set -e

cat -- "$build_root/make.stdout"
cat -- "$build_root/make.stderr" >&2
((make_rc == 0)) || fail "MAKE_FAILED_RC_${make_rc}"

readonly module_path="$source_dir/$MODULE_RELATIVE"
[[ -f "$module_path" && ! -L "$module_path" ]] || fail 'MODULE_NOT_CREATED'
readonly module_sha=$(sha256sum -- "$module_path" | awk '{print toupper($1)}')
readonly module_size=$(stat -c '%s' -- "$module_path")
readonly module_name=$(modinfo -F name "$module_path")
readonly module_alias=$(modinfo -F alias "$module_path")
readonly module_vermagic=$(modinfo -F vermagic "$module_path")
[[ "$module_name" == "$MODULE_NAME" ]] || fail 'BUILT_INTERNAL_MODULE_NAME_MISMATCH'
[[ $(printf '%s\n' "$module_alias" | awk 'NF {count++} END {print count+0}') -eq 1 ]] ||
  fail 'BUILT_MODULE_ALIAS_COUNT_NOT_ONE'
[[ "${module_alias,,}" == 'pci:v000010eed00007011sv000010eesd00000007bc*sc*i*' ]] ||
  fail 'BUILT_MODULE_ALIAS_NOT_EXACT_AHD'
[[ "$module_vermagic" == "$EXPECTED_KERNEL "* ]] || fail 'BUILT_MODULE_VERMAGIC_KERNEL_MISMATCH'
[[ ! -d "/sys/module/$MODULE_NAME" ]] || fail 'CANDIDATE_MODULE_BECAME_LOADED'

readonly post_source_inputs_sha=$(
  (
    cd -- "$source_dir"
    git ls-files -z | LC_ALL=C sort -z | xargs -0 sha256sum
  ) | sha256sum | awk '{print toupper($1)}'
)
[[ "$post_source_inputs_sha" == "$source_inputs_sha" ]] || fail 'SOURCE_INPUTS_CHANGED_DURING_BUILD'

readonly headers_config_sha=$(sha256sum -- "$headers_root/.config" | awk '{print toupper($1)}')
readonly headers_symvers_sha=$(sha256sum -- "$headers_root/Module.symvers" | awk '{print toupper($1)}')
readonly compiler_identity=$(gcc --version | sed -n '1p')
readonly make_identity=$(make --version | sed -n '1p')
readonly git_identity=$(git --version)

{
  printf 'FORMAT=G2B_HW0_DRV1_BUILD_MANIFEST_V1\n'
  printf 'BUILD_LABEL=%s\n' "$build_label"
  printf 'BUILD_ROOT=%s\n' "$build_root"
  printf 'UPSTREAM_URL=%s\n' "$UPSTREAM_URL"
  printf 'UPSTREAM_COMMIT=%s\n' "$actual_commit"
  printf 'UPSTREAM_TREE=%s\n' "$actual_tree"
  printf 'PATCH_SHA256=%s\n' "$actual_patch_sha"
  printf 'SOURCE_DIFF_SHA256=%s\n' "$source_diff_sha"
  printf 'SOURCE_INPUTS_SHA256=%s\n' "$source_inputs_sha"
  printf 'KERNEL_RELEASE=%s\n' "$running_kernel"
  printf 'ARCHITECTURE=%s\n' "$running_arch"
  printf 'HEADERS_ROOT=%s\n' "$headers_root"
  printf 'KERNEL_CONFIG_SHA256=%s\n' "$headers_config_sha"
  printf 'MODULE_SYMVERS_SHA256=%s\n' "$headers_symvers_sha"
  printf 'COMPILER_IDENTITY=%s\n' "$compiler_identity"
  printf 'MAKE_IDENTITY=%s\n' "$make_identity"
  printf 'GIT_IDENTITY=%s\n' "$git_identity"
  printf 'SOURCE_DATE_EPOCH=%s\n' "$SOURCE_DATE_EPOCH_VALUE"
  printf 'KBUILD_BUILD_TIMESTAMP=%s\n' "$KBUILD_BUILD_TIMESTAMP_VALUE"
  printf 'KBUILD_BUILD_USER=%s\n' "$KBUILD_BUILD_USER_VALUE"
  printf 'KBUILD_BUILD_HOST=%s\n' "$KBUILD_BUILD_HOST_VALUE"
  printf 'KBUILD_BUILD_VERSION=%s\n' "$KBUILD_BUILD_VERSION_VALUE"
  printf 'DEBUG_PREFIX_MAP=%s=%s\n' "$source_dir" "$debug_root"
  printf 'BUILD_COMMAND=make -C XDMA/linux-kernel/xdma all V=1 DEBUG=0 BUILDSYSTEM_DIR=%s ARCH=x86_64 [exact tool paths and deterministic prefix maps]\n' "$headers_root"
  printf 'MODULE_PATH=%s\n' "$module_path"
  printf 'MODULE_FILENAME=xdma_ahd_pcie.ko\n'
  printf 'MODULE_INTERNAL_NAME=%s\n' "$module_name"
  printf 'MODULE_SHA256=%s\n' "$module_sha"
  printf 'MODULE_SIZE=%s\n' "$module_size"
  printf 'MODULE_VERMAGIC=%s\n' "$module_vermagic"
  printf 'MODULE_ALIAS=%s\n' "$module_alias"
  printf 'MODPOST_RESULT=PASS\n'
  printf 'MODULE_INSTALLED=NO\n'
  printf 'MODULE_LOADED=NO\n'
} >"$build_root/build-manifest.txt"

printf '%s\n' \
  'G2B_HW0_DRV1_BUILD=PASS' \
  "BUILD_LABEL=$build_label" \
  "BUILD_ROOT=$build_root" \
  "UPSTREAM_COMMIT=$actual_commit" \
  "UPSTREAM_TREE=$actual_tree" \
  "PATCH_SHA256=$actual_patch_sha" \
  "MODULE_PATH=$module_path" \
  "MODULE_NAME=$module_name" \
  "MODULE_SHA256=$module_sha" \
  "MODULE_SIZE=$module_size" \
  "MODULE_VERMAGIC=$module_vermagic" \
  "MODULE_ALIAS=$module_alias" \
  'MODULE_INSTALLED=NO' \
  'MODULE_LOADED=NO'
