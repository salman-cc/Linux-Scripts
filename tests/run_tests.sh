#!/usr/bin/env bash
# Muhammed Salman
#
# run_tests.sh - functional tests for the scripts in ../scripts.
# Each test works in a private /tmp sandbox and asserts observable
# behaviour. Exits non-zero on the first failure.

set -euo pipefail

cd "$(dirname "$0")/.."

fail=0

check() {
    if [ "$1" -eq 0 ]; then
        echo "  ok   $2"
    else
        echo "  FAIL $2"
        fail=1
    fi
}

T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

echo "sys_health"
out=$(scripts/sys_health.sh); rc=$?
check "$rc" "runs and exits 0 on a healthy-enough host"
echo "$out" | grep -qE '^(OK|WARN|CRIT) +load' ; check $? "prints a load verdict"
echo "$out" | grep -qE '^(OK|WARN|CRIT) +memory' ; check $? "prints a memory verdict"
echo "$out" | grep -qE '^(OK|WARN|CRIT) +disk' ; check $? "prints a disk verdict"
scripts/sys_health.sh -w 95 -c 99 >/dev/null; check $? "accepts custom thresholds"
if scripts/sys_health.sh -w 99 -c 50 2>/dev/null; then
    check 1 "rejects warn >= critical"
else
    check 0 "rejects warn >= critical"
fi
if scripts/sys_health.sh --definitely-not-a-flag 2>/dev/null; then
    check 1 "rejects an unknown flag"
else
    check 0 "rejects an unknown flag"
fi

echo "backup_rotate"
mkdir -p "$T/src/sub" "$T/dst"
echo alpha > "$T/src/a.txt"
echo beta > "$T/src/sub/b.txt"

scripts/backup_rotate.sh -s "$T/src" -d "$T/dst" -k 3 > "$T/run1.log"
check $? "first backup runs"
[ -f "$T/dst"/src-*.tar.gz ]; check $? "archive created with prefix name"
tar -tzf "$T/dst"/src-*.tar.gz | grep -q 'src/sub/b.txt'
check $? "archive contains the source tree"

# Three more backups with distinct timestamps, then rotation to 3.
for i in 2 3 4; do
    sleep 1
    scripts/backup_rotate.sh -s "$T/src" -d "$T/dst" -k 3 > /dev/null
done
count=$(ls -1 "$T/dst"/src-*.tar.gz | wc -l)
[ "$count" -eq 3 ]; check $? "rotation keeps exactly the newest 3"

dry=$(scripts/backup_rotate.sh -s "$T/src" -d "$T/dst" -k 1 -n)
echo "$dry" | grep -q '^would create '; check $? "dry run reports create"
count=$(ls -1 "$T/dst"/src-*.tar.gz | wc -l)
[ "$count" -eq 3 ]; check $? "dry run changes nothing"

if scripts/backup_rotate.sh -s "$T/nope" -d "$T/dst" 2>/dev/null; then
    check 1 "missing source fails"
else
    check 0 "missing source fails"
fi

if [ "$fail" -eq 0 ]; then
    echo "all script tests passed"
fi
exit "$fail"
