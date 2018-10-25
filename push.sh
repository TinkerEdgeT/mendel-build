#!/bin/bash -e
#
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

orig_package="$1"

package=$orig_package
if [[ ! -f $package ]]; then
    package=$(find $PRODUCT_OUT/packages -name "${package}*.deb")

    if [[ ! -f $package ]]; then
        echo "push: no such package $package"
        exit 1
    fi
fi

filename="$(basename ${package})"

scp -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -C "${package}" aiy@192.168.100.2:/tmp
ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -Ct aiy@192.168.100.2 sudo dpkg -i "/tmp/${filename}"
ssh -oUserKnownHostsFile=/dev/null -oStrictHostKeyChecking=no -Ct aiy@192.168.100.2 sudo apt-get -f -y install
