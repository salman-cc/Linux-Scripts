#!/usr/bin/env bash
# Muhammed Salman
#
# backup_rotate.sh - timestamped tar backup with count-based rotation.
#
# Creates DIR-YYYYmmdd-HHMMSS.tar.gz in the destination, then deletes
# the oldest archives of the same prefix until at most KEEP remain.
#
# Usage: backup_rotate.sh -s DIR -d DIR [-k KEEP] [-n]
#   -s DIR   directory to back up (required)
#   -d DIR   destination for archives (required)
#   -k KEEP  archives to keep, newest first (default 7)
#   -n       dry run: print what would happen, change nothing

set -euo pipefail

SRC=""
DEST=""
KEEP=7
DRY=0

usage() {
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
}

while getopts "s:d:k:nh" opt; do
    case "$opt" in
        s) SRC="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        k) KEEP="$OPTARG" ;;
        n) DRY=1 ;;
        h) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

if [ -z "$SRC" ] || [ -z "$DEST" ]; then
    usage >&2
    exit 2
fi
if [ ! -d "$SRC" ]; then
    echo "backup_rotate: source $SRC is not a directory" >&2
    exit 1
fi
case "$KEEP" in
    ''|*[!0-9]*) echo "backup_rotate: keep must be a number" >&2; exit 2 ;;
esac
if [ "$KEEP" -lt 1 ]; then
    echo "backup_rotate: keep must be at least 1" >&2
    exit 2
fi

mkdir -p "$DEST"

base=$(basename "$SRC")
stamp=$(date +%Y%m%d-%H%M%S)
archive="$DEST/${base}-${stamp}.tar.gz"

if [ "$DRY" -eq 1 ]; then
    echo "would create $archive from $SRC"
else
    tar -czf "$archive" -C "$(dirname "$SRC")" "$base"
    echo "created $archive"
fi

# Rotate: list this prefix's archives oldest first, drop the excess.
mapfile -t archives < <(ls -1 "$DEST/${base}-"*.tar.gz 2>/dev/null | sort)
total=${#archives[@]}

if [ "$total" -gt "$KEEP" ]; then
    excess=$((total - KEEP))
    for old in "${archives[@]:0:excess}"; do
        # Never delete the archive just made, even on clock skew.
        if [ "$old" = "$archive" ]; then
            continue
        fi
        if [ "$DRY" -eq 1 ]; then
            echo "would delete $old"
        else
            rm -- "$old"
            echo "deleted $old"
        fi
    done
fi
