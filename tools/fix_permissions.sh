#!/bin/bash

set -e

usage() {
    echo "Usage: fix_permissions.sh -p <permissions_file> -t <rootfs_dir>"
    exit 1
}

apply_permissions() {
    local dentry
    local flags
    local flag
    local opts
    local user
    local group
    local file_mode

    cd $ROOTFS

    while read dentry flags user group file_mode; do
        if [[ $dentry =~ ^# ]] || [[ -z $dentry ]]; then
            continue
        fi

        opts=""

        set -- $(echo $flags |sed 's/,/ /g') --
        for flag; do
            case "$flag" in
                recurse)
                    opts="$opts -R"
                    shift
                    ;;
                -)
                    opts=""
                    shift
                    ;;
                --)
                    shift
                    break
                    ;;
            esac
        done

        echo chmod $opts $file_mode $dentry
        echo chown $opts $user:$group $dentry
        chmod $opts $file_mode $dentry
        chown $opts $user:$group $dentry
    done
}

PERMISSIONS=""
ROOTFS=""
ARGS=$(getopt hp:t: $*)
set -- $ARGS

for i; do
    case "$1" in
        -p)  # permissions_file
            PERMISSIONS="$2"
            shift 2
            ;;
        -t)  # rootfs_dir
            ROOTFS="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -h|*)
            usage
            ;;
    esac
done

if [[ -z $PERMISSIONS ]] || [[ -z $ROOTFS ]]; then
    usage
fi

apply_permissions < $PERMISSIONS
