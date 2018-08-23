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
ADD pbuilderrc /etc/pbuilderrc
ADD D05deps /var/cache/pbuilder/hooks/D05deps

VOLUME /var/lib/docker
