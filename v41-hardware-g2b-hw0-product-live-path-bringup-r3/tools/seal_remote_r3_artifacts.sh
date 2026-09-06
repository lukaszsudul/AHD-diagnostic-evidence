#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 077

root="$HOME/vcde_artifacts/g2b_hw0_product_r3/20260906T140148Z"
manifest="$root/G2B_HW0_PRODUCT_R3_DUT_SHA256_MANIFEST.txt"
[ -d "$root" ]
[ ! -e "$manifest" ]
cd "$root"
mapfile -d '' files < <(find . -type f ! -name 'G2B_HW0_PRODUCT_R3_DUT_SHA256_MANIFEST.txt' -print0 | sort -z)
[ "${#files[@]}" -gt 0 ]
for file in "${files[@]}"; do
  sha256sum -- "$file"
done > "$manifest"
chmod 0444 "$manifest"
sha256sum -c "$manifest"
echo DUT_ARTIFACT_MANIFEST_RESULT=PASS
echo "DUT_ARTIFACT_FILE_COUNT=${#files[@]}"
echo "DUT_ARTIFACT_MANIFEST_SHA256=$(sha256sum "$manifest" | awk '{print toupper($1)}')"
