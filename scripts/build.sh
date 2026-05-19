#!/usr/bin/env bash
set -eo pipefail # envsetup has unbound variables...

# This is ours and should be removed once we have the system running on a
# device, it is only useful for developer diagnostics. The differences in patch
# sets are related to enabling ADB by default, this allows for debugging in
# early boot.

# DEBUG_BUILD="true"

pushd src

# Set the build vars
AOSP_TAG=$(grep --max-count=1 "aosp_revision:" .repo/manifests/config.yml | sed "s/.*: *//")
ANDROID_VERSION=$(echo "${AOSP_TAG}" | sed "s/android-//;s/_r.*//")
echo "Detected ANDROID_VERSION: ${ANDROID_VERSION}"
echo "${ANDROID_VERSION}" > ../tmp/.android_version
ANDROID_VERSION_TAG=$(grep --max-count=1 "target:" build/release/release_config_map.textproto \
    | sed "s/.*\"\([^\"]*\)\".*/\1/")
echo "Detected ANDROID_VERSION_TAG: ${ANDROID_VERSION_TAG}"
echo "${ANDROID_VERSION_TAG}" > ../tmp/.android_version_tag

# Apply patches
# only apply the patches once
if [ ! -e ../tmp/.patches_applied ]; then
    ../patches/apply.sh . trebledroid
    ../patches/apply.sh . trebledroid-staging
    ../patches/apply.sh . rom
    ../patches/apply.sh . personal
    if [ "${DEBUG_BUILD}" = "true" ]; then
        echo "*** DEBUG BUILD: applying debug-builds tier ***"
        ../patches/apply.sh . debug-builds
    else
        echo "*** RELEASE BUILD: applying release-builds tier ***"
        ../patches/apply.sh . release-builds
    fi
    echo "${DEBUG_BUILD}" > ../tmp/.patches_applied
fi

# Build ROM image
ANDROID_VERSION_TAG_VAL=$(cat ../tmp/.android_version_tag)
pushd device/phh/treble
cp --force --verbose ../../../../configs/rom/rom.mk .
bash generate.sh rom
popd
. build/envsetup.sh
BUILD_VARIANT="user"
if [ "${DEBUG_BUILD}" == "true" ]; then
    BUILD_VARIANT="userdebug"
fi
lunch "treble_arm64_bvN-${ANDROID_VERSION_TAG_VAL}-${BUILD_VARIANT}"
make systemimage -j"$(nproc --all)"
make target-files-package otatools -j"$(nproc --all)"

popd # src/
