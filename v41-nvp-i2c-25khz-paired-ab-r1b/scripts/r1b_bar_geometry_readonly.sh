#!/usr/bin/env bash
set -euo pipefail
d=/sys/bus/pci/devices/0000:01:00.0
for index in 0 1; do
  read -r start end flags < <(sed -n "$((index + 1))p" "$d/resource")
  start=${start#0x}
  end=${end#0x}
  if [[ $start == 0000000000000000 && $end == 0000000000000000 ]]; then
    size=0
  else
    size=$((16#$end - 16#$start + 1))
  fi
  printf 'BAR%s_START_HEX=%s\nBAR%s_END_HEX=%s\nBAR%s_BYTES=%s\n' "$index" "$start" "$index" "$end" "$index" "$size"
done
printf 'BAR_GEOMETRY_READ_ONLY=YES\n'

