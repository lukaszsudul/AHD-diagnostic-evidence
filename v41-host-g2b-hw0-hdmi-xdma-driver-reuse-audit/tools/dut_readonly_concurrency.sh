#!/usr/bin/env bash
set -u

self=$$
echo "AUDIT=G2B-HW0-DRV-REUSE0_CONCURRENCY"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "AUDIT_PID=$self"
echo "MATCHING_PROCESSES_BEGIN"
ps -eo pid=,ppid=,user=,lstart=,comm=,args= | awk -v self="$self" '
  $1 != self && $0 ~ /[x]dma|[i]nsmod|[m]odprobe|[r]mmod|\/sys\/bus\/pci\/.*\/(bind|unbind|rescan|reset)|[v]ivado|[h]w_server|[o]penocd|[a]pt(-get)?|[d]pkg|[u]nattended-upgrade/ { print }
'
echo "MATCHING_PROCESSES_END"
echo "SYSTEMD_JOBS_BEGIN"
systemctl list-jobs --no-legend 2>&1 || true
echo "SYSTEMD_JOBS_END"
echo "PACKAGE_LOCK_HOLDERS_BEGIN"
for lockfile in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
  if command -v fuser >/dev/null 2>&1; then
    holders=$(fuser "$lockfile" 2>/dev/null || true)
    if [ -n "$holders" ]; then
      printf '%s:%s\n' "$lockfile" "$holders"
    fi
  fi
done
echo "PACKAGE_LOCK_HOLDERS_END"
echo "RESULT=COMPLETE"
