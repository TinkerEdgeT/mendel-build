#!/bin/bash

set -e

get_image_size_bytes() {
    parted -sm "$IMAGE" unit b print \
        |head -n2 \
        |tail -n1 \
        | awk -F: '{ print $2 }' \
        |sed 's/B$//'
}

get_boot_partition_size_bytes() {
    parted -sm "$IMAGE" unit b print \
        |awk -F: '/^1:/ { print $2 }' \
        |sed 's/B$//'
}

get_rootfs_size_bytes() {
    sudo du -sb "$ROOTFS" |awk '{ print $1 }'
}

get_total_size_bytes() {
    local boot_size=$(get_boot_partition_size_bytes)
    local rootfs_size=$(get_rootfs_size_bytes)
    echo $(($boot_size + $rootfs_size))
}

get_total_with_margin_bytes() {
    local total_size=$(get_total_size_bytes)
    echo $(($total_size + $MARGIN_BYTES))
}

usage() {
    echo "Usage: resize_image [-m <margin_size_bytes>] -i <image_file> -r <rootfs_dir>"
    exit 1
}

MARGIN_BYTES=100000000

IMAGE=""
ROOTFS=""
ARGS=$(getopt hm:i:r: $*)
set -- $ARGS

for i; do
    case "$1" in
        -m)  # margin
            MARGIN_BYTES="$2"
            shift 2
            ;;
        -i)  # image
            IMAGE="$2"
            shift 2
            ;;
        -r)  # rootfs
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

if [[ -z $IMAGE ]] || [[ -z $ROOTFS ]]; then
    usage
fi

CALCULATED_SIZE=$(get_total_with_margin_bytes)
ACTUAL_SIZE=$(get_image_size_bytes)

if [[ $ACTUAL_SIZE -lt $CALCULATED_SIZE ]]; then
    echo "$0: $IMAGE is $ACTUAL_SIZE. Resizing to $CALCULATED_SIZE."
    truncate --no-create --size=$CALCULATED_SIZE $IMAGE
else
    echo "$0: $IMAGE is $ACTUAL_SIZE, wanted $CALCULATED_SIZE. No resize necessary."
fi

parted -s $IMAGE resizepart 2 100%
