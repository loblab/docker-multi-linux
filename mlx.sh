#!/bin/bash
# Copyright 2017 loblab
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#       http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

function config() {
    LOG_DIR=$HOME/docker/log
    BACKUP_DIR=$HOME/docker/backup
    INIT_SCRIPT="container/init.sh $USER"
    INSTALL_DIR=/usr/local/bin
    INSTALL_NAME=mlx

    SYSTEMS="debian9 debian8 ubuntu17 ubuntu16 centos7 centos6 archlinux"
    debian9=debian:stretch
    debian8=debian:jessie
    ubuntu17=ubuntu:17.10
    ubuntu16=ubuntu:16.04
    centos7=centos:7
    centos6=centos:6.9
    fedora=fedora
    archlinux=base/archlinux
    opensuse=opensuse
}

function help() {
    echo ""
    echo "Docker based multiple Linux environment"
    echo "======================================="
    echo "Ver 0.3, 11/13/2017, loblab"
    echo ""
    echo "Usage:"
    echo "$PROG se <command...>       - Sequence exec <command...> on all linux systems"
    echo "$PROG pe <command...>       - Parallel exec <command...> on all linux systems. Output to log files"
    echo "$PROG seu <command...>      - 'se' as normal user (instead of 'root')"
    echo "$PROG peu <command...>      - 'pe' as normal user (instead of 'root')"
    echo "$PROG logs                  - Quick look logs of '$PROG pe'"
    echo "$PROG init [command...]     - Init the environment. Default command is '$INIT_SCRIPT'"
    echo "$PROG backup <backup-dir>   - Backup all the systems to $BACKUP_DIR/<backup-dir>"
    echo "$PROG restore [backup-dir]  - Restore all the systems from $BACKUP_DIR/<backup-dir> or backup images"
    echo "$PROG download              - Download/update the docker images"
    echo "$PROG install [install-dir] - Install this script, default to '$INSTALL_DIR'"
    echo "$PROG list                  - List systems"
    echo "$PROG help                  - Help message"
    echo ""
    exit $1
}

function log_msg() {
    echo $(date +'%m/%d %H:%M:%S') - "$*"
}

function install_script() {
    local srcfile=$0
    local dstfile=$1/$INSTALL_NAME
    if [ $srcfile == $dstfile ]; then
        echo "Seems already installed."
        exit 1
    fi
    echo "Copy/rename this script to $dstfile..."
    $SUDO cp -f $srcfile $dstfile
    which $INSTALL_NAME > /dev/null
    if [ $? -eq 0 ]; then
        echo "Now you can run the script by name '$INSTALL_NAME'"
    else
        echo "Make sure '$1' in your PATH"
    fi
}

function check_docker_engine() {
    set +e
    which docker &> /dev/null
    set -e
    if [ $? -ne 0 ]; then
        echo "Docker engine is not installed."
        echo "Follow below link to install it before running the script:"
        echo "https://docs.docker.com/engine/installation/"
        exit 250
    fi
}

function image_existed() {
    local iid=$(docker images $1 -q)
    test -n "$iid"
}

function container_existed() {
    local cid=$(docker ps -a -f name=^/$1$ -q)
    test -n "$cid"
}

function remove_existed_image() {
    local image=$1
    if image_existed $image; then
        echo "Image '$image' existed. Remove..."
        docker image rm $image
    fi
}

function remove_existed_container() {
    local con=$1
    if container_existed $con; then
        echo "Container '$con' existed. remove..."
        docker rm -f $con
    fi
}

function download_images() {
    local sys
    for sys in $SYSTEMS
    do
        log_msg "Download '$sys'..."
        local image=${!sys}
        docker pull $image
    done
}

function list_systems() {
    local sys
    for sys in $SYSTEMS
    do
        local image=${!sys}
        echo "$sys => $image"
    done
}

function create_containers() {
    local workdir=$(pwd)
    local rootdir=/$(echo $workdir | cut -d'/' -f2)
    local sys
    for sys in $SYSTEMS
    do
        log_msg "Create '$sys'..."
        remove_existed_container $sys
        local image=${!sys}
        docker run -dit --name $sys -h $sys -v $rootdir:$rootdir -w $workdir $image
    done
}

function add_user_containers() {
    local uid=$(id -u $USER)
    local homedir=$HOME
    if [ "$USER" != "root" ]; then
        log_msg "Add user '$USER' to all systems..."
        seq_exec_containers useradd -u $uid -d $homedir -s $SHELL $USER
    fi
}

function seq_exec_containers() {
    set +e
    local cmd=$*
    local workdir=$(pwd)
    local sys
    for sys in $SYSTEMS
    do
        echo $sys
        echo "==================="
        docker exec -it $AS_USER $sys bash -c "cd $workdir; $cmd"
        local rc=$?
        echo "-----"
        echo "Exit: $rc ($sys)"
        echo ""
    done
}

function par_exec_containers() {
    local cmd=$*
    [ -d $LOG_DIR ] || mkdir -p $LOG_DIR || { echo "Error: cannot create dir '$LOG_DIR'. Quit."; exit 252; }
    local workdir=$(pwd)
    local sys
    for sys in $SYSTEMS
    do
        log_msg "Exec in '$sys': '$cmd' ..."
        docker exec $AS_USER $sys bash -c "cd $workdir; $cmd" &> $LOG_DIR/$sys.log &
    done
}

function backup_containers() {
    local bakdir=$BACKUP_DIR/$1
    test -d $bakdir || mkdir -p $bakdir || { echo "Error: cannot create dir '$bakdir'. Quit.";  exit 254; }
    local sys
    for sys in $SYSTEMS
    do
        local bakfile=$bakdir/$sys.tgz
        log_msg "Backup $sys to $bakfile..."
        docker export $sys | gzip > $bakfile
    done
}

function restore_containers() {
    local workdir=$(pwd)
    local rootdir=/$(echo $workdir | cut -d'/' -f2)
    if [ -n "$1" ]; then
        local bakdir=$BACKUP_DIR/$1
        test -d $bakdir || { echo "Error: cannot find dir '$bakdir'. Quit.";  exit 253; }
    fi
    local sys
    for sys in $SYSTEMS
    do
        local image=$sys:backup
        if [ -n "$bakdir" ]; then
            local bakfile=$bakdir/$sys.tgz
            log_msg "restore '$sys' from file '$bakfile'..."
            remove_existed_container $sys
            remove_existed_image $image
            echo "Import image '$image' from '$bakfile'..."
            docker import $bakfile $image
        else
            log_msg "restore '$sys' from image '$image'..."
            if image_existed $image; then
                remove_existed_container $sys
            else
                echo "Error: image '$image' does not exist. Quit."
                exit 251
            fi
        fi
        echo "Start container '$sys'..."
        docker run -dit --name $sys -h $sys -v $rootdir:$rootdir -w $workdir $image /bin/bash
    done
}

function mlx_install() {
    test -n "$1" && local dstdir=$1 || local dstdir=$INSTALL_DIR
    echo "Install this script..."
    install_script $dstdir
}

function mlx_list() {
    echo "All systems"
    list_systems
}

function mlx_download() {
    echo "Download/update images..."
    download_images
}

function mlx_init() {
    check_docker_engine
    echo "Create/init all systems..."
    create_containers
    add_user_containers
    local cmd=$INIT_SCRIPT
    if [ -n "$1" ]; then
        cmd=$*
    fi
    log_msg "Run '$cmd' in all systems..."
    par_exec_containers $cmd
    echo "Check status with '$PROG logs'"
}

function mlx_se() {
    test -n "$1" || help 255
    seq_exec_containers $*
}

function mlx_pe() {
    test -n "$1" || help 255
    par_exec_containers $*
    echo "Check exec logs with '$PROG logs'"
}

function mlx_seu() {
    test -n "$1" || help 255
    [ "$USER" != "root" ] || { echo "'seu' should run as normal user. Quit."; exit 249; }
    AS_USER="-u $USER"
    seq_exec_containers $*
}

function mlx_peu() {
    test -n "$1" || help 255
    [ "$USER" != "root" ] || { echo "'peu' should run as normal user. Quit."; exit 248; }
    AS_USER="-u $USER"
    par_exec_containers $*
    echo "Check exec logs with '$PROG logs'"
}

function mlx_backup() {
    test -n "$1" || help 255 
    echo "Backup all containers..."
    backup_containers $1
}

function mlx_restore() {
    echo "Restore all containers..."
    restore_containers $1
}

function mlx_logs() {
    echo "Quick look logs in '$LOG_DIR'"
    echo ""
    tail -n 5 $LOG_DIR/*.log
    echo ""
    echo "List logs in '$LOG_DIR'"
    ls -lrt $LOG_DIR
}

function mlx_help() {
    help 0
}

test -n "$USER" || USER=$(whoami)
[ "$USER" == "root" ]  || SUDO=sudo
config
PROG=$(basename $0)
operation=$1

[ "$(type -t mlx_$operation)" = function ] || help 255
shift
mlx_$operation $*

