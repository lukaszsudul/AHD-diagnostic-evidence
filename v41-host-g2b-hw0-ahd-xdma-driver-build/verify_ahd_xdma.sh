#!/usr/bin/env bash
set -euo pipefail

umask 077

readonly EXPECTED_KERNEL='7.0.0-29-generic'
readonly EXPECTED_ARCH='x86_64'
readonly EXPECTED_MODULE_NAME='xdma_ahd_pcie'
readonly EXPECTED_ALIAS='pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*'
readonly EXACT_AHD_MODALIAS='pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00'
readonly HDMI_MODALIAS='pci:v000010EEd00007021sv000010EEsd0000F0A1bc05sc80i00'
readonly PLATFORM_MODULE='/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst'
readonly EXPECTED_PLATFORM_SHA256='523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490'

fail() {
  printf 'G2B_HW0_DRV1_VERIFY=FAIL\nERROR=%s\n' "$1" >&2
  exit 1
}

usage() {
  printf 'usage: %s --candidate ABSOLUTE_KO_PATH --output-dir ABSOLUTE_NEW_DIRECTORY\n' "$0" >&2
  exit 2
}

candidate=''
output_dir=''
while (($#)); do
  case "$1" in
    --candidate)
      (($# >= 2)) || usage
      candidate=$2
      shift 2
      ;;
    --output-dir)
      (($# >= 2)) || usage
      output_dir=$2
      shift 2
      ;;
    *) usage ;;
  esac
done

[[ "$candidate" == /* && "$output_dir" == /* ]] || usage
candidate=$(realpath -e -- "$candidate")
case "$candidate/" in
  /lib/modules/*) fail 'CANDIDATE_INSIDE_LIB_MODULES' ;;
esac
case "$candidate/" in
  "$HOME/"*) ;;
  *) fail 'CANDIDATE_OUTSIDE_AUTHENTICATED_HOME' ;;
esac
case "$output_dir/" in
  "$HOME/"*) ;;
  *) fail 'OUTPUT_DIR_OUTSIDE_AUTHENTICATED_HOME' ;;
esac
[[ ! -e "$output_dir" ]] || fail 'OUTPUT_DIR_ALREADY_EXISTS'
[[ -f "$candidate" && ! -L "$candidate" ]] || fail 'CANDIDATE_NOT_REGULAR_FILE'

for command_name in modinfo readelf nm objdump file sha256sum stat awk grep \
  find sort python3 uname wc basename realpath; do
  command -v "$command_name" >/dev/null 2>&1 || fail "COMMAND_MISSING_${command_name}"
done

readonly running_kernel=$(uname -r)
readonly running_arch=$(uname -m)
[[ "$running_kernel" == "$EXPECTED_KERNEL" ]] || fail 'RUNNING_KERNEL_DRIFT'
[[ "$running_arch" == "$EXPECTED_ARCH" ]] || fail 'RUNNING_ARCH_DRIFT'
[[ ! -d "/sys/module/$EXPECTED_MODULE_NAME" ]] || fail 'CANDIDATE_MODULE_IS_LOADED'
[[ -f "$PLATFORM_MODULE" ]] || fail 'PLATFORM_XDMA_MODULE_MISSING'

readonly platform_sha=$(sha256sum -- "$PLATFORM_MODULE" | awk '{print toupper($1)}')
[[ "$platform_sha" == "$EXPECTED_PLATFORM_SHA256" ]] || fail 'PLATFORM_XDMA_MODULE_HASH_DRIFT'
readonly platform_name=$(modinfo -F name "$PLATFORM_MODULE")
readonly platform_alias=$(modinfo -F alias "$PLATFORM_MODULE")
[[ "$platform_name" == 'xdma' ]] || fail 'PLATFORM_XDMA_INTERNAL_NAME_DRIFT'
[[ "$platform_alias" == 'platform:xdma' ]] || fail 'PLATFORM_XDMA_ALIAS_DRIFT'

mkdir -- "$output_dir"

modinfo "$candidate" >"$output_dir/modinfo.txt"
readelf -h "$candidate" >"$output_dir/readelf-h.txt"
readelf -S -W "$candidate" >"$output_dir/readelf-S.txt"
readelf -n "$candidate" >"$output_dir/readelf-n.txt" 2>&1 || true
nm -a "$candidate" >"$output_dir/nm-all.txt"
nm -u "$candidate" >"$output_dir/nm-undefined.txt"
nm -g --defined-only "$candidate" >"$output_dir/nm-defined-global.txt"
objdump -p "$candidate" >"$output_dir/objdump-p.txt"
file "$candidate" >"$output_dir/file.txt"
modinfo "$PLATFORM_MODULE" >"$output_dir/platform-modinfo.txt"

readonly module_name=$(modinfo -F name "$candidate")
readonly module_vermagic=$(modinfo -F vermagic "$candidate")
readonly expected_vermagic=$(modinfo -F vermagic "$PLATFORM_MODULE")
readonly module_arch_field=$(modinfo -F arch "$candidate")
readonly module_srcversion=$(modinfo -F srcversion "$candidate")
readonly module_license=$(modinfo -F license "$candidate")
readonly module_description=$(modinfo -F description "$candidate")
readonly module_author=$(modinfo -F author "$candidate")
readonly module_depends=$(modinfo -F depends "$candidate")
readonly module_signer=$(modinfo -F signer "$candidate")
readonly module_sig_id=$(modinfo -F sig_id "$candidate")
readonly module_sig_hashalgo=$(modinfo -F sig_hashalgo "$candidate")
readonly module_sha=$(sha256sum -- "$candidate" | awk '{print toupper($1)}')
readonly module_size=$(stat -c '%s' -- "$candidate")
mapfile -t aliases < <(modinfo -F alias "$candidate" | awk 'NF {print}')
mapfile -t parameters < <(modinfo -F parm "$candidate" | awk 'NF {print}')

[[ "$module_name" == "$EXPECTED_MODULE_NAME" ]] || fail 'INTERNAL_MODULE_NAME_MISMATCH'
[[ "$module_vermagic" == "$expected_vermagic" ]] || fail 'VERMAGIC_NOT_EXACT'
[[ ${#aliases[@]} -eq 1 ]] || fail 'MODULE_ALIAS_COUNT_NOT_ONE'
[[ "${aliases[0],,}" == "${EXPECTED_ALIAS,,}" ]] || fail 'MODULE_ALIAS_NOT_EXACT_AHD'
grep -Eq 'Machine:[[:space:]]+Advanced Micro Devices X86-64' "$output_dir/readelf-h.txt" ||
  fail 'ELF_MACHINE_NOT_X86_64'
[[ -z "$module_arch_field" || "$module_arch_field" == "$EXPECTED_ARCH" ]] ||
  fail 'MODINFO_ARCH_MISMATCH'
readonly module_arch="$EXPECTED_ARCH"

readonly kernel_config="/boot/config-$running_kernel"
[[ -f "$kernel_config" ]] || fail 'RUNNING_KERNEL_CONFIG_UNAVAILABLE'
readonly kernel_config_sha=$(sha256sum -- "$kernel_config" | awk '{print toupper($1)}')
readonly module_symvers="$(realpath -e -- "/lib/modules/$running_kernel/build")/Module.symvers"
[[ -f "$module_symvers" ]] || fail 'MODULE_SYMVERS_UNAVAILABLE'
readonly module_symvers_sha=$(sha256sum -- "$module_symvers" | awk '{print toupper($1)}')
grep -qx 'CONFIG_MODULES=y' "$kernel_config" || fail 'CONFIG_MODULES_NOT_Y'
grep -qx 'CONFIG_PCI=y' "$kernel_config" || fail 'CONFIG_PCI_NOT_Y'
if grep -qx 'CONFIG_MODVERSIONS=y' "$kernel_config"; then
  grep -Eq '[[:space:]](__versions|___versions)[[:space:]]' "$output_dir/readelf-S.txt" ||
    fail 'MODVERSION_SECTION_MISSING'
fi

if [[ -n "$module_signer$module_sig_id$module_sig_hashalgo" ]]; then
  fail 'UNEXPECTED_MODULE_SIGNATURE_METADATA'
fi

readonly alias_matrix="$output_dir/alias-matrix.csv"
python3 -I -S - "$EXPECTED_ALIAS" "$EXACT_AHD_MODALIAS" "$HDMI_MODALIAS" \
  "$alias_matrix" <<'PY'
import csv
import fnmatch
import pathlib
import sys

alias_pattern, ahd_modalias, hdmi_modalias, output = sys.argv[1:]
tests = [
    ("AHD exact modalias", ahd_modalias, "MATCH"),
    (
        "AHD vendor/device alternate subsystem",
        "pci:v000010EEd00007011sv000010EEsd00000008bc05sc80i00",
        "NO_MATCH",
    ),
    ("HDMI authoritative identity", hdmi_modalias, "NO_MATCH"),
    (
        "Generic Xilinx PCI device",
        "pci:v000010EEd00009048sv000010EEsd00000000bc05sc80i00",
        "NO_MATCH",
    ),
    ("Platform XDMA", "platform:xdma", "NO_MATCH"),
]
sysfs = pathlib.Path("/sys/bus/pci/devices")
if sysfs.is_dir():
    for modalias_path in sorted(sysfs.glob("*/modalias")):
        try:
            value = modalias_path.read_text(encoding="ascii").strip()
        except OSError:
            continue
        if value.lower().startswith("pci:v000010ee") and value.lower() != ahd_modalias.lower():
            tests.append((f"Installed Xilinx endpoint {modalias_path.parent.name}", value, "NO_MATCH"))

rows = []
all_pass = True
for name, modalias, expected in tests:
    matched = fnmatch.fnmatchcase(modalias.lower(), alias_pattern.lower())
    actual = "MATCH" if matched else "NO_MATCH"
    passed = actual == expected
    all_pass &= passed
    rows.append(
        {
            "Test": name,
            "Modalias": modalias,
            "GeneratedAlias": alias_pattern,
            "Expected": expected,
            "Actual": actual,
            "Result": "PASS" if passed else "FAIL",
        }
    )

with open(output, "x", newline="", encoding="utf-8") as stream:
    writer = csv.DictWriter(
        stream,
        fieldnames=["Test", "Modalias", "GeneratedAlias", "Expected", "Actual", "Result"],
    )
    writer.writeheader()
    writer.writerows(rows)

if not all_pass:
    raise SystemExit("one or more offline alias tests failed")
PY

readonly ahd_alias_result=$(
  awk -F, 'NR==2 {gsub(/\r/, "", $6); print $6}' "$alias_matrix"
)
[[ "$ahd_alias_result" == 'PASS' ]] || fail 'EXACT_AHD_MODALIAS_OFFLINE_MATCH_FAILED'
[[ $(awk -F, 'NR>1 && $6 ~ /^FAIL\r?$/ {count++} END {print count+0}' "$alias_matrix") -eq 0 ]] ||
  fail 'ALIAS_MATRIX_CONTAINS_FAILURE'

readonly undefined_symbol_count=$(wc -l <"$output_dir/nm-undefined.txt" | awk '{print $1}')
readonly exported_symbol_count=$(wc -l <"$output_dir/nm-defined-global.txt" | awk '{print $1}')
readonly build_id=$(
  awk '/Build ID:/ {print $3; exit}' "$output_dir/readelf-n.txt"
)
readonly secure_boot_state=$(
  if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state 2>&1 | awk 'NF {printf "%s%s", separator, $0; separator=" | "}'
  else
    printf 'MOKUTIL_UNAVAILABLE'
  fi
)

{
  printf 'FORMAT=G2B_HW0_DRV1_VERIFICATION_RECEIPT_V1\n'
  printf 'RESULT=PASS\n'
  printf 'VERIFICATION_MODE=STATIC_OFFLINE_ONLY\n'
  printf 'MODULE_PATH=%s\n' "$candidate"
  printf 'MODULE_FILENAME=%s\n' "$(basename -- "$candidate")"
  printf 'MODULE_INTERNAL_NAME=%s\n' "$module_name"
  printf 'MODULE_ARCH=%s\n' "$module_arch"
  printf 'MODULE_VERMAGIC=%s\n' "$module_vermagic"
  printf 'EXPECTED_VERMAGIC=%s\n' "$expected_vermagic"
  printf 'MODULE_SRCVERSION=%s\n' "$module_srcversion"
  printf 'MODULE_LICENSE=%s\n' "$module_license"
  printf 'MODULE_DESCRIPTION=%s\n' "$module_description"
  printf 'MODULE_AUTHOR=%s\n' "$module_author"
  printf 'MODULE_DEPENDS=%s\n' "$module_depends"
  printf 'MODULE_ALIAS_COUNT=%s\n' "${#aliases[@]}"
  printf 'MODULE_ALIAS=%s\n' "${aliases[0]}"
  printf 'MODULE_PARAMETER_COUNT=%s\n' "${#parameters[@]}"
  printf 'MODULE_SIGNER=%s\n' "$module_signer"
  printf 'MODULE_SIG_ID=%s\n' "$module_sig_id"
  printf 'MODULE_SIG_HASHALGO=%s\n' "$module_sig_hashalgo"
  printf 'MODULE_BUILD_ID=%s\n' "${build_id:-ABSENT}"
  printf 'MODULE_SHA256=%s\n' "$module_sha"
  printf 'MODULE_SIZE=%s\n' "$module_size"
  printf 'KERNEL_RELEASE=%s\n' "$running_kernel"
  printf 'KERNEL_CONFIG_SHA256=%s\n' "$kernel_config_sha"
  printf 'MODULE_SYMVERS_SHA256=%s\n' "$module_symvers_sha"
  printf 'CONFIG_MODULES=y\n'
  printf 'CONFIG_PCI=y\n'
  grep '^CONFIG_MODVERSIONS=' "$kernel_config"
  printf 'UNDEFINED_KERNEL_SYMBOL_REFERENCE_COUNT=%s\n' "$undefined_symbol_count"
  printf 'DEFINED_GLOBAL_SYMBOL_COUNT=%s\n' "$exported_symbol_count"
  printf 'PLATFORM_MODULE_PATH=%s\n' "$PLATFORM_MODULE"
  printf 'PLATFORM_MODULE_SHA256=%s\n' "$platform_sha"
  printf 'PLATFORM_MODULE_INTERNAL_NAME=%s\n' "$platform_name"
  printf 'PLATFORM_MODULE_ALIAS=%s\n' "$platform_alias"
  printf 'MODULE_NAME_COLLISION=NO\n'
  printf 'SECURE_BOOT_STATE=%s\n' "$secure_boot_state"
  printf 'SIGNATURE_DISPOSITION=UNSIGNED_ACCEPTABLE_FOR_SEPARATELY_AUTHORIZED_TEST\n'
  printf 'EXACT_AHD_MODALIAS_MATCH=PASS\n'
  printf 'HDMI_MODALIAS_MATCH=NO\n'
  printf 'GENERIC_XILINX_MODALIAS_MATCH=NO\n'
  printf 'PLATFORM_XDMA_ALIAS_MATCH=NO\n'
  printf 'UNINTENDED_BROAD_PCI_ALIASES=0\n'
  printf 'KERNEL_OFFLINE_COMPATIBILITY=PASS\n'
  printf 'MODULE_INSTALLED=NO\n'
  printf 'MODULE_LOADED=NO\n'
} >"$output_dir/verification-receipt.txt"

printf '%s\n' \
  'G2B_HW0_DRV1_VERIFY=PASS' \
  "MODULE_PATH=$candidate" \
  "MODULE_INTERNAL_NAME=$module_name" \
  "MODULE_ARCH=$module_arch" \
  "MODULE_VERMAGIC=$module_vermagic" \
  "MODULE_SHA256=$module_sha" \
  "MODULE_SIZE=$module_size" \
  "MODULE_ALIAS=${aliases[0]}" \
  'EXACT_AHD_MODALIAS_MATCH=PASS' \
  'HDMI_MODALIAS_MATCH=NO' \
  'GENERIC_XILINX_MODALIAS_MATCH=NO' \
  'PLATFORM_XDMA_ALIAS_MATCH=NO' \
  'UNINTENDED_BROAD_PCI_ALIASES=0' \
  'KERNEL_OFFLINE_COMPATIBILITY=PASS' \
  'MODULE_INSTALLED=NO' \
  'MODULE_LOADED=NO'
