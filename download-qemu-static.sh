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

version='8.2.4'
build='1.fc40'
for arch in aarch64 ppc64le s390x; do
    curl -sL \
        "https://kojipkgs.fedoraproject.org/packages/qemu/${version}/${build}/x86_64/qemu-user-static-${arch/ppc64le/ppc}-${version}-${build}.x86_64.rpm" |
        bsdtar -xf- --strip-components=3 ./usr/bin/qemu-${arch}-static
done

sha256sum --check << 'EOF'
5fb1ae8235807b310000ed3a1b03d49a000c51ec1a1f84869720b87273976466  qemu-aarch64-static
4d9e1b1fc7e51d6bee4e087e06c1185cadc2d85b1308e802ed15c754ff6475cc  qemu-ppc64le-static
3454f16b26dc94fcce23e4e2f97ab98033b659ad491675235c2388521154afac  qemu-s390x-static
EOF
