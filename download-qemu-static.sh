#!/bin/bash -ex

set -eux

if [ "$(uname -m)" = "x86_64" ]; then
    docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi

rm -f qemu-*-static

# We use curl and bsdtar to obtain QEMU binaries. Install them beforehand.
sudo apt-get update -qq
DEBIAN_FRONTEND=noninteractive \
    sudo apt-get install --yes --no-install-recommends \
    ca-certificates curl libarchive-tools

version='8.1.3'
build='1.fc39'
for arch in aarch64 ppc64le s390x; do
    curl -sL \
        "https://kojipkgs.fedoraproject.org/packages/qemu/${version}/${build}/x86_64/qemu-user-static-${arch/ppc64le/ppc}-${version}-${build}.x86_64.rpm" |
        bsdtar -xf- --strip-components=3 ./usr/bin/qemu-${arch}-static
done
sha256sum --check << 'EOF'
3b78154b2aa59f886b530826b5dd01be03ce3c4b29751a814d724650bcc526b2  qemu-aarch64-static
15593a3ede391e218a61f7e5c28b714c9bce5cd2736f12127847cef1d8f0edd9  qemu-ppc64le-static
92dd7d9824c9c41635cf91761d8f9799f3b727918ae0f645a43c4317bab5d98f  qemu-s390x-static
EOF
