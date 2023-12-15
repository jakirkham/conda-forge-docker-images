#!/bin/bash -ex

set -eux

if [ "$(uname -m)" = "x86_64" ]; then
    docker run --rm --privileged multiarch/qemu-user-static:register --reset
fi

rm -f qemu-*-static

# We use curl and bsdtar to obtain QEMU binaries. Install them beforehand.
apt-get update -qq
DEBIAN_FRONTEND=noninteractive \
    apt-get install --yes --no-install-recommends \
    ca-certificates curl libarchive-tools

version='8.0.3'
build='4.fc40'
for arch in aarch64 ppc64le s390x; do
    curl -sL \
        "https://kojipkgs.fedoraproject.org/packages/qemu/${version}/${build}/x86_64/qemu-user-static-${arch/ppc64le/ppc}-${version}-${build}.x86_64.rpm" |
        bsdtar -xf- --strip-components=3 ./usr/bin/qemu-${arch}-static
done
sha256sum --check << 'EOF'
d02f52c9135453a453a80e5746eee13bb4ea9cd31080d9ad9a75e6442f930402  qemu-aarch64-static
b68bdd489120afe8d4f76dc040651dbb0d6012d33395920fe4a1e4afb84f5b72  qemu-ppc64le-static
68e711c57b7e74306bafc08a0884f34dde45b8866a07d4fe5506f673d9ea485b  qemu-s390x-static
EOF
