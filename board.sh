#!/bin/bash

BOARD_IP_ADDRESS=192.168.100.2
SSH_KEY_FILE="${ROOTDIR}/cache/ssh_key"
SSH_PUB_FILE="${ROOTDIR}/cache/ssh_key.pub"
SSH_OPTIONS="-oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -i${SSH_KEY_FILE}"

function die
{
    echo "board: $@" >/dev/stderr
    exit 1
}

function try
{
    "$@" || die "$@ failed. Aborting."
}

function copy-key
{
    if [[ ! -f "${SSH_KEY_FILE}" ]]; then
        die "${SSH_KEY_FILE} not found -- run setup-key first."
    fi

    local ssh_pub_file_contents="$(cat ${SSH_PUB_FILE})"
    try ssh ${SSH_OPTIONS} -C aiy@${BOARD_IP_ADDRESS} " \
        mkdir -p /home/aiy/.ssh; \
        echo '${ssh_pub_file_contents}' >/home/aiy/.ssh/authorized_keys"
}

function command::setup-key
{
    if [[ ! -f "${SSH_KEY_FILE}" || ! -f "${SSH_PUB_FILE}" ]]; then
        rm -f "${SSH_KEY_FILE}" "${SSH_PUB_FILE}"
        echo "Generating SSH keyfile in ${SSH_KEY_FILE}..."
        try ssh-keygen -f "${SSH_KEY_FILE}" -N "" >/dev/null
    fi

    echo "Copying keyfile to board (you may be prompted for aiy's password -- it's 'aiy')..."
    copy-key
    echo "Done."
}

function command::install
{
    local package_partial="$1"; shift

    if [[ -z "${package_partial}" ]]; then
        die "Usage: board.sh install <package-partial-name>"
    fi

    local filename="${package_partial}"
    if [[ ! -f "${filename}" ]]; then
        filename=$(echo $PRODUCT_OUT/packages/$filename*.deb)

        if [[ ! -f "${filename}" ]]; then
            die "push: no such package ${filename}"
        fi
    fi

    copy-key
    try scp ${SSH_OPTIONS} -C "${filename}" aiy@${BOARD_IP_ADDRESS}:/tmp

    local basename=$(basename "${filename}")
    try ssh ${SSH_OPTIONS} -Ct aiy@${BOARD_IP_ADDRESS} " \
        sudo dpkg -i /tmp/${basename}; \
        sudo apt-get -f -y install"
}

function command::push
{
    local source_path="$1"; shift
    local dest_path="$1"; shift

    if [[ -z "${source_path}" || -z "${dest_path}" ]]; then
        die "Usage: board.sh pull <local-source> <remote-dest>"
    fi

    copy-key
    try scp ${SSH_OPTIONS} -C "${source_path}" "aiy@${BOARD_IP_ADDRESS}:${dest_path}"
}

function command::pull
{
    local source_path="$1"; shift
    local dest_path="$1"; shift

    if [[ -z "${source_path}" || -z "${dest_path}" ]]; then
        die "Usage: board.sh pull <remote-source> <local-dest>"
    fi

    copy-key
    try scp ${SSH_OPTIONS} -C "aiy@${BOARD_IP_ADDRESS}:${source_path}" "${dest_path}"
}

function command::shell
{
    if [[ ! -f "${SSH_KEY_FILE}" ]]; then
        die "${SSH_KEY_FILE} not found -- run setup-key first."
    fi

    copy-key

    if [[ ! -z "$@" ]]; then
        ssh ${SSH_OPTIONS} -Ct aiy@${BOARD_IP_ADDRESS} "$@"
    else
        ssh ${SSH_OPTIONS} -Ct aiy@${BOARD_IP_ADDRESS}
    fi
}

function command::reboot
{
    if [[ ! -f "${SSH_KEY_FILE}" ]]; then
        die "${SSH_KEY_FILE} not found -- run setup-key first."
    fi

    copy-key
    ssh ${SSH_OPTIONS} -Ct aiy@${BOARD_IP_ADDRESS} "sudo reboot"
}

function command::reboot-bootloader
{
    if [[ ! -f "${SSH_KEY_FILE}" ]]; then
        die "${SSH_KEY_FILE} not found -- run setup-key first."
    fi

    copy-key
    ssh ${SSH_OPTIONS} -Ct aiy@${BOARD_IP_ADDRESS} "sudo reboot-bootloader"
}

function command::help
{
    local subcommand="$1"; shift

    if [[ -z "${subcommand}" ]]; then
        echo "Usage: board.sh [<options>] <subcommand> [<subcommand-options>]"
        echo "Where <subcommand> is one of the following:"
        echo
        echo "    setup-key         - generate an ssh key and store it to the attached board."
        echo "    install           - install a deb from your product directory to the board."
        echo "    push              - upload a file somewhere to the board."
        echo "    pull              - download a file from the board."
        echo "    shell             - open a shell to the board."
        echo "    reboot            - reboot the board."
        echo "    reboot-bootloader - reboot the board into fastboot."
        echo "    help              - get help on subcommands."
        echo
        echo "Global options are"
        echo "    -i <filename>    - set the location of the identity filename"
        echo "    -a <ip-address>  - use an alternative IP address"
        echo "    -h               - show this help text"
        echo
        die "Use 'help <subcommand>' for more details."
    fi
}

function main
{
    local subcommand="$1"; shift

    if [[ -z "$ROOTDIR" ]]; then
        die "\$ROOTDIR is not defined. 'source build/setup.sh' first!"
    fi

    if ! which ssh >/dev/null || ! which scp >/dev/null; then
        die "ssh or scp not found -- please ensure they're installed."
    fi

    case "${subcommand}" in
        setup-key)         command::setup-key "$@" ;;
        install)           command::install "$@" ;;
        push)              command::push "$@" ;;
        pull)              command::pull "$@" ;;
        shell)             command::shell "$@" ;;
        reboot)            command::reboot ;;
        reboot-bootloader) command::reboot-bootloader ;;
        help|'')           command::help "$@" ;;

        *)
            die "Unknown subcommand '${subcommand}' -- try 'help'."
            ;;
    esac

    return 0
}

main "$@"
