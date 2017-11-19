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

    SYSTEMS="debian9 debian8 ubuntu17 ubuntu16 centos7 centos6 archlinux alpine"
    debian9="debian:stretch   -p 221:22 -p 801:80"
    debian8="debian:jessie    -p 222:22 -p 802:80"
    ubuntu17="ubuntu:17.10    -p 223:22 -p 803:80"
    ubuntu16="ubuntu:16.04    -p 224:22 -p 804:80"
    centos7="centos:7         -p 225:22 -p 805:80"
    centos6="centos:6.9       -p 226:22 -p 806:80"
    archlinux="base/archlinux -p 227:22 -p 807:80"
    alpine="alpine            -p 228:22 -p 808:80"
    fedora="fedora"
    opensuse="opensuse"
}

function help() {
    echo ""
    echo "Docker based multiple Linux environment"
    echo "======================================="
    echo "Ver 0.5, 11/19/2017, loblab"
    echo ""
    echo "Usage:"
    echo "$PROG se <command...>       - Sequence exec <command...> on all systems"
    echo "$PROG pe <command...>       - Parallel exec <command...> on all systems. Output to log files"
    echo "$PROG seu <command...>      - 'se' as normal user (instead of 'root')"
    echo "$PROG peu <command...>      - 'pe' as normal user (instead of 'root')"
    echo "$PROG logs                  - Quick look logs of '$PROG pe'"
    echo "$PROG init [command...]     - Init the environment. Default command is '$INIT_SCRIPT'"
    echo "$PROG backup <backup-dir>   - Backup all the systems to $BACKUP_DIR/<backup-dir>"
    echo "$PROG restore [backup-dir]  - Restore all the systems from $BACKUP_DIR/<backup-dir> or backup images"
    echo "$PROG list                  - List all systems"
    echo "$PROG start                 - Start all systems"
    echo "$PROG stop                  - Stop all systems"
    echo "$PROG download              - Download/update the docker images"
    echo "$PROG install [install-dir] - Install this script, default to '$INSTALL_DIR'"
    echo "$PROG help                  - Help message"
    echo ""
    exit $1
}

function log_msg() {
    echo $(date +'%m/%d %H:%M:%S') - "$*"
}

function get_sys_image() {
    local sys=$1
    local cfg=${!sys}
    echo "$cfg" | awk '{ print $1 }'
}

function get_sys_option() {
    local sys=$1
    local cfg=${!sys}
    echo "$cfg" | perl -ne 'print $2 if /(\S+?) (.*)/'
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
    which docker > /dev/null 2>&1
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
        echo "System '$con' existed. remove..."
        docker rm -f $con
    fi
}

function download_images() {
    local sys
    for sys in $SYSTEMS
    do
        log_msg "Download image '$sys'..."
        local image=$(get_sys_image $sys)
        docker pull $image
    done
}

function list_systems() {
    local sys
    for sys in $SYSTEMS
    do
        local image=$(get_sys_image $sys)
        local option=$(get_sys_option $sys)
        echo "$sys => $image $option"
    done
}

function create_containers() {
    local workdir=$(pwd)
    local rootdir=/$(echo $workdir | cut -d'/' -f2)
    local sys
    for sys in $SYSTEMS
    do
        log_msg "Create system '$sys'..."
        remove_existed_container $sys
        local image=$(get_sys_image $sys)
        local option=$(get_sys_option $sys)
        docker run -dit --name $sys -h $sys -v $rootdir:$rootdir -w $workdir $option $image
    done
}

function add_user_to_containers() {
    local uid=$(id -u $USER)
    local homedir=$HOME
    [ "$USER" != "root" ] || return
    for sys in $SYSTEMS
    do
        log_msg "Add user '$USER' to '$sys'..."
        docker exec -it $sys useradd -u $uid -d $homedir -s $SHELL $USER > /dev/null 2>&1 || 
          docker exec -it $sys adduser -u $uid -h $homedir -s $SHELL -D $USER > /dev/null 2>&1
    done
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
        docker exec -it $AS_USER $sys sh -c "cd $workdir; $cmd"
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
        docker exec $AS_USER $sys sh -c "cd $workdir; $cmd" > $LOG_DIR/$sys.log 2>&1 &
    done
}

function operate_containers() {
    local operate=$1
    local sys
    for sys in $SYSTEMS
    do
        docker $operate $sys
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
        echo "Start system '$sys'..."
        local option=$(get_sys_option $sys)
        docker run -dit --name $sys -h $sys -v $rootdir:$rootdir -w $workdir $option $image sh
    done
}

function mlx_install() {
    test -n "$1" && local dstdir=$1 || local dstdir=$INSTALL_DIR
    echo "Install this script..."
    install_script $dstdir
}

function mlx_list() {
    echo "All systems:"
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
    add_user_to_containers
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

function mlx_start() {
    echo "Start all systems..."
    operate_containers start
}

function mlx_stop() {
    echo "Stop all systems..."
    operate_containers stop
}

function mlx_backup() {
    test -n "$1" || help 255 
    echo "Backup all systems..."
    backup_containers $1
}

function mlx_restore() {
    echo "Restore all systems..."
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

