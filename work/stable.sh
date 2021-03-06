#!/bin/bash

set -e

# configure build specific settings
GLUON_VERSION="2016.2.4-2"
SIGN_KEYDIR="/opt/freifunk/signkeys_ffv"
MANIFEST_KEY="manifest_key"
SITE_TAG=b20170420-v
TARGET_BRANCH=stable
GLUONDIR="gluon-ffv-${TARGET_BRANCH}"

# set gluon env variables
export GLUON_OPKG_KEY="${SIGN_KEYDIR}/gluon-opkg-key"
export GLUON_RELEASE="${SITE_TAG}"
export FORCE_UNSAFE_CONFIGURE=1

TARGETS="\
    ar71xx-generic \
    ar71xx-nand \
    brcm2708-bcm2708 \
    brcm2708-bcm2709 \
    mpc85xx-generic \
    x86-generic \
    x86-kvm_guest \
    x86-64 \
    x86-xen_domu \
"

# clean
if [ -d "${GLUONDIR}" ]; then
	rm "${GLUONDIR}" -R
fi

# build
git clone https://github.com/FreifunkVogtland/gluon.git "${GLUONDIR}" -b v"${GLUON_VERSION}"
git clone https://github.com/FreifunkVogtland/site-ffv.git "${GLUONDIR}"/site -b "${SITE_TAG}"
make -C "${GLUONDIR}" update
for target in ${TARGETS}; do
    make -C "${GLUONDIR}" GLUON_TARGET="${target}" clean -j"$(nproc || echo 1)"
    make -C "${GLUONDIR}" GLUON_TARGET="${target}" GLUON_BRANCH="${TARGET_BRANCH}" -j"$(nproc || echo 1)"
done

make -C "${GLUONDIR}" GLUON_BRANCH="${TARGET_BRANCH}" manifest
"${GLUONDIR}"/contrib/sign.sh "${SIGN_KEYDIR}/${MANIFEST_KEY}" "${GLUONDIR}"/output/images/sysupgrade/"${TARGET_BRANCH}".manifest
