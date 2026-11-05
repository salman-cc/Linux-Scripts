#!/usr/bin/env bash
# Muhammed Salman
#
# sys_health.sh - one-shot host health summary for Linux servers.
#
# Prints load, memory, disk and the top CPU processes, each with an
# OK/WARN/CRIT verdict, and exits non-zero when anything is CRIT so the
# script can gate cron mail or monitoring hooks.
#
# Usage: sys_health.sh [-w PCT] [-c PCT] [-h]
#   -w PCT   disk/memory warning threshold percent (default 80)
#   -c PCT   disk/memory critical threshold percent (default 90)

set -euo pipefail

WARN_PCT=80
CRIT_PCT=90

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while getopts "w:c:h" opt; do
    case "$opt" in
        w) WARN_PCT="$OPTARG" ;;
        c) CRIT_PCT="$OPTARG" ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

if [ "$WARN_PCT" -ge "$CRIT_PCT" ]; then
    echo "sys_health: warn threshold must be below critical" >&2
    exit 2
fi

crit_found=0

verdict() {
    # verdict LABEL VALUE_PCT DETAIL
    local label="$1" pct="$2" detail="$3" mark="OK"
    if [ "$pct" -ge "$CRIT_PCT" ]; then
        mark="CRIT"
        crit_found=1
    elif [ "$pct" -ge "$WARN_PCT" ]; then
        mark="WARN"
    fi
    printf '%-6s %-8s %s (%s%%)\n' "$mark" "$label" "$detail" "$pct"
}

# Load: 1-minute average vs CPU count.
cpus=$(nproc)
load1=$(cut -d' ' -f1 /proc/loadavg)
load_pct=$(awk -v l="$load1" -v c="$cpus" 'BEGIN { printf "%d", (l/c)*100 }')
verdict "load" "$load_pct" "$load1 on $cpus CPUs"

# Memory: used percent from /proc/meminfo (available-aware).
mem_pct=$(awk '
    /^MemTotal:/     { t = $2 }
    /^MemAvailable:/ { a = $2 }
    END { printf "%d", ((t - a) / t) * 100 }' /proc/meminfo)
mem_detail=$(awk '
    /^MemTotal:/     { t = $2 }
    /^MemAvailable:/ { a = $2 }
    END { printf "%d MiB free of %d MiB", a/1024, t/1024 }' /proc/meminfo)
verdict "memory" "$mem_pct" "$mem_detail"

# Disk: worst mounted real filesystem.
disk_line=$(df --output=pcent,target -x tmpfs -x devtmpfs -x squashfs \
            | tail -n +2 | sort -rn | head -n 1)
disk_pct=${disk_line%%%*}
disk_pct=${disk_pct//[[:space:]]/}
disk_target=${disk_line#* }
verdict "disk" "$disk_pct" "$disk_target fullest filesystem"

echo
echo "top 3 processes by CPU:"
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 4

exit "$crit_found"
