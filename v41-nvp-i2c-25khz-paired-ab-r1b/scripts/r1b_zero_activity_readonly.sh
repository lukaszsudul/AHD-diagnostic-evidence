#!/usr/bin/env bash
set -euo pipefail
printf 'CURRENT_BOOT_ID=%s\n' "$(< /proc/sys/kernel/random/boot_id)"
open_pids=$(
  find /proc/[0-9]*/fd -maxdepth 1 -type l -lname '/dev/xdma*' -printf '%h\n' 2>/dev/null |
    sed -E 's#^/proc/([0-9]+)/fd$#\1#' | sort -un | paste -sd, -
)
if [[ -n $open_pids ]]; then
  printf 'XDMA_OPEN_PROCESS_COUNT=%s\n' "$(tr ',' '\n' <<< "$open_pids" | wc -l)"
  printf 'XDMA_OPEN_PIDS=%s\n' "$open_pids"
  exit 41
fi
printf 'XDMA_OPEN_PROCESS_COUNT=0\nXDMA_OPEN_PIDS=NONE\n'
interrupt_total=$(awk '/xdma/ {for (i=2; i<=NF; ++i) {if ($i !~ /^[0-9]+$/) break; sum += $i}} END {print sum+0}' /proc/interrupts)
printf 'XDMA_INTERRUPT_TOTAL=%s\n' "$interrupt_total"
if [[ $interrupt_total -ne 0 ]]; then
  printf 'PRE_PROGRAM_ZERO_ACTIVITY_GATE=FAIL_INTERRUPTS_NONZERO\n'
  exit 42
fi
printf 'TASK_C2H_TRANSFERS=0\nTASK_H2C_TRANSFERS=0\nDMA_ACTIVITY=0\n'
printf 'PRE_PROGRAM_ZERO_ACTIVITY_GATE=PASS\n'

