#!/bin/bash

function help() {
    echo "Cross linux package manager"
    echo "Ver 0.1, 11/9/2017, loblab"
    echo "Usage: $prog install [package...]"
    exit 1
}

function init_pm() {
    test -f /usr/bin/apt && { PM=apt; PM_install="apt -y install"; }
    test -f /usr/bin/yum && { PM=yum; PM_install="yum -y install"; }
    test -f /usr/sbin/pacman && { PM=pacman; PM_install="pacman -S --noconfirm"; }
    if [ -z "$PM" ]; then
        echo "Unsupported system <$(hostname)>. Quit."
        exit 2
    fi
}

prog=$(basename $0)
[ -n "$2" ] || help
operation=$1
shift

init_pm
func=PM_$operation
cmd=${!func}
if [ -z "$cmd" ]; then
    echo "Unsupported operation <$operation>. Quit."
    exit 3
fi
$cmd $*

