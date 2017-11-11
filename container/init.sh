#!/bin/bash

APT_MIRROR=mirrors.aliyun.com

function check_pm() {
    test -f /usr/bin/apt && PM=apt
    test -f /usr/bin/yum && PM=yum
    test -f /usr/sbin/pacman && PM=pacman
    if [ -z "$PM" ]; then
        echo "Unsupported system <$(hostname)>. quit."
        exit 1
    fi
}

function update_apt_sources() {
    aptfile=/etc/apt/sources.list
    [ -n "APT_MIRROR" ] || return
    [ -f $aptfile ] || return
    echo "Modify $aptfile, replace mirrors with <$APT_MIRROR>..."
    sed -i "s/deb.debian.org/$APT_MIRROR/" $aptfile
    sed -i "s/archive.ubuntu.com/$APT_MIRROR/" $aptfile
}

function apt_init() {
    update_apt_sources
    apt -y update
    apt -y upgrade
    PMI="apt -y install"
    $PMI procps lsb-release
}

function yum_init() {
    yum -y update
    PMI="yum -y install"
    $PMI which redhat-lsb-core
}

function pacman_init() {
    pacman -Syu --noconfirm
    PMI="pacman -S --noconfirm"
    $PMI lsb-release
}

function common_init() {
    $PMI man sudo wget tree
    $PMI vim
    echo "Copy xpm.sh, and rename to xpm..."
    cp $(dirname $0)/xpm.sh /usr/local/bin/xpm
    echo "You can use xpm as package manager across linux distributions"
}

function show_env() {
    echo "Work dir: $(pwd)"
    echo "Package manager: $PM"
    echo "Hostname: $(hostname)"
    echo "PATH: $PATH"
}

function main() {
    echo "Init container <$(hostname)>..."
    check_pm
    show_env
    set -e
    ${PM}_init
    common_init
    echo "Init container <$(hostname)>... Done."
}

main

