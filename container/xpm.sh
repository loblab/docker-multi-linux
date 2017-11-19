#!/bin/sh
set -e

help() {
    echo "Cross linux package manager"
    echo "Ver 0.2, 11/19/2017, loblab"
    echo "Usage:"
    echo "$prog install [package...]: install package"
    echo "$prog remove [package...]: uninstall package"
    echo "$prog init: install basic packages"
    echo "$prog update: update/upgrade system/packages"
    echo "$prog type: show package manager type"
    exit 1
}

config_apt() {
    PM=apt
    PM_update="apt update && apt -y upgrade"
    PM_install="apt -y install"
    PM_remove="apt -y remove"
    INIT_PACKAGES="procps lsb-release"
}

config_yum() {
    PM=yum
    PM_update="yum -y update"
    PM_install="yum -y install"
    PM_remove="yum -y erase"
    INIT_PACKAGES="which redhat-lsb-core"
}

config_pacman() {
    PM=pacman
    PM_update="pacman -Syu --noconfirm"
    PM_install="pacman -S --noconfirm"
    PM_remove="pacman -Rs --noconfirm"
    INIT_PACKAGES="lsb-release"
}

config_apk() {
    PM=apk
    PM_update="apk update; apk upgrade"
    PM_install="apk add"
    PM_remove="apk del"
    INIT_PACKAGES=""
}

config_pm() {
    test -f /usr/bin/apt && config_apt
    test -f /usr/bin/yum && config_yum
    test -f /usr/sbin/pacman && config_pacman
    test -f /sbin/apk && config_apk
    if [ -z "$PM" ]; then
        echo "Unsupported system <$(hostname)>. Quit."
        exit 2
    fi
}

init_packages() {
    eval $PM_install $INIT_PACKAGES
    eval $PM_install man sudo wget tree vim
}

prog=$(basename $0)
[ -n "$1" ] || help
operation=$1
shift

config_pm
if [ "$operation" = "type" ]; then
    echo "$PM"
    exit 0
fi
if [ "$operation" = "init" ]; then
    init_packages
    exit 0
fi
func=PM_$operation
cmd=$(eval echo \$$func)
if [ -z "$cmd" ]; then
    echo "Unsupported operation <$operation>. Quit."
    exit 3
fi
eval $cmd $*

