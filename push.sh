#!/bin/bash -e

orig_package="$1"

package=$orig_package
if [[ ! -f $package ]]; then
    package=$(echo $PRODUCT_OUT/packages/$package*.deb)

    if [[ ! -f $package ]]; then
        echo "push: no such package $package"
        exit 1
    fi
fi

filename="$(basename ${package})"

scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -C "${package}" aiy@192.168.100.2:/tmp
ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -Ct aiy@192.168.100.2 sudo dpkg -i "/tmp/${filename}"
ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -Ct aiy@192.168.100.2 sudo apt-get -f -y install
