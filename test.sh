#!/bin/bash
set -e

function die() {
    echo "$*"
    exit 1
}

[ "$USER" != "root" ] || die "Run the script as normal user (in docker group)"
count1=$(mlx se whoami | grep root | wc -l)
count2=$(mlx seu whoami | grep $USER | wc -l)
count3=$(mlx seu sudo whoami | grep root | wc -l)

echo "Expected counts should be same and > 0"
echo "mlx se whoami: $count1"
echo "mlx seu whoami: $count2"
echo "mlx seu sudo whoami: $count3"

test $count1 -gt 0 || die FAILED
test $count1 -eq $count2 || die FAILED
test $count2 -eq $count3 || die FAILED
echo PASSED

