#!/bin/sh
set -e

USER=$1

APT_MIRROR=mirrors.aliyun.com

update_apt_sources() {
    aptfile=/etc/apt/sources.list
    [ -n "APT_MIRROR" ] || return
    [ -f $aptfile ] || return
    echo "Modify $aptfile, replace mirrors with <$APT_MIRROR>..."
    sed -i "s/deb.debian.org/$APT_MIRROR/" $aptfile
    sed -i "s/archive.ubuntu.com/$APT_MIRROR/" $aptfile
}

init_sudo() {
    test -n "$USER" || return 0
    [ "$USER" != "root" ] || return 0
    echo "Add user '$USER' to 'sudo/wheel' group..."
    adduser $USER sudo > /dev/null 2>&1 || 
        usermod -aG wheel $USER > /dev/null 2>&1 || 
        adduser $USER wheel > /dev/null 2>&1
    local line="$USER ALL=(ALL) NOPASSWD:ALL"
    grep "$line" /etc/sudoers > /dev/null || echo "$line" >> /etc/sudoers
    echo "User '$USER' can sudo any commands without password."
}

xpm_init() {
    echo "Copy xpm.sh, and rename to xpm..."
    cp $(dirname $0)/xpm.sh /usr/local/bin/xpm
    echo "You can use xpm as package manager across linux distributions"
    echo "Update/upgrade system..."
    xpm update
    echo "Install basic packages..."
    xpm init
}

show_env() {
    echo "Hostname: $(hostname)"
    echo "PATH: $PATH"
    echo "Work dir: $(pwd)"
    echo "Package manager: $(xpm type)"
}

main() {
    echo "Init container <$(hostname)>..."
    test -f /usr/bin/apt && update_apt_sources
    xpm_init
    init_sudo
    show_env
    echo "Init container <$(hostname)>... Done."
}

main

