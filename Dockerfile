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

FROM debian:9.4
MAINTAINER support-aiyprojects@google.com

# Install Docker into this image, so we can run nested containers for ARM64 builds.
RUN apt-get update -qq && apt-get install -qqy \
        apt-transport-https \
        ca-certificates \
        curl \
        lxc \
        iptables
RUN curl -sSL https://get.docker.com/ | sh

# Install the prerequisite packages into the image.
ADD . /build
RUN /bin/bash -c '\
apt-get update && \
apt-get install sudo make && \
ln -sfr /build/Makefile /Makefile && \
source /build/setup.sh && \
make -C /build prereqs'

VOLUME /var/lib/docker
