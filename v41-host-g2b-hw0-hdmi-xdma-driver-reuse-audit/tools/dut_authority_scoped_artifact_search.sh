#!/usr/bin/env bash
set -u

expected_sha256=b08c6e5cd296ddbd68b50b718b1efaa581c152ee07e6623e153e2cddf00124d2
roots=(/opt/fpga-hdmi-lab /run/r0f_a)

echo "AUDIT=G2B-HW0-DRV-REUSE0_AUTHORITY_SCOPED_ARTIFACT_SEARCH"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "EXPECTED_SHA256=$expected_sha256"
echo "SEARCH_ROOTS_BEGIN"
printf '%s\n' "${roots[@]}"
echo "SEARCH_ROOTS_END"
echo "CANDIDATES_BEGIN"
match_count=0
candidate_count=0
for root in "${roots[@]}"; do
  if [ ! -d "$root" ]; then
    echo "ROOT_ABSENT=$root"
    continue
  fi
  while IFS= read -r -d '' candidate; do
    candidate_count=$((candidate_count + 1))
    actual_sha256=$(sha256sum "$candidate" | awk '{print $1}')
    size=$(stat -Lc '%s' "$candidate")
    echo "CANDIDATE_PATH=$candidate"
    echo "CANDIDATE_SIZE=$size"
    echo "CANDIDATE_SHA256=$actual_sha256"
    if [ "$actual_sha256" = "$expected_sha256" ]; then
      match_count=$((match_count + 1))
      echo "CANDIDATE_AUTHORITY_MATCH=YES"
    else
      echo "CANDIDATE_AUTHORITY_MATCH=NO"
    fi
  done < <(find "$root" -xdev -type f -name xdma.ko -print0 2>/dev/null)
done
echo "CANDIDATES_END"
echo "CANDIDATE_COUNT=$candidate_count"
echo "EXACT_HASH_MATCH_COUNT=$match_count"
echo "AUDIT_COMPLETE=YES"
