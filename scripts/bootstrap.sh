#!/usr/bin/env bash
#
# This script bootstraps the fetching of RestlessOS, a GSI version of Graphene.
#
set -euo pipefail

# Get the restless OS project
git clone https://github.com/djlorentz/treble_restlessos.git
pushd treble_restlessos

# remove the cawilliamson private keys
git apply <<"EOF"
diff --git a/configs/manifests/default.xml b/configs/manifests/default.xml
index 6d5f39a..50f1328 100644
--- a/configs/manifests/default.xml
+++ b/configs/manifests/default.xml
@@ -45,5 +45,5 @@
   <project path="vendor/apn" name="android_vendor_apn" remote="lineage" revision="main" clone-depth="1" />
 
   <!-- vendor-priv -->
-  <project path="vendor/cawilliamson-priv" name="vendor_cawilliamson-priv" remote="cawilliamson-priv" revision="main" clone-depth="1" />
+  <!-- <project path="vendor/cawilliamson-priv" name="vendor_cawilliamson-priv" remote="cawilliamson-priv" revision="main" clone-depth="1" /> -->
 </manifest>
EOF

# Added by us to mimic github runner behavior.
GRAPHENEOS_RELEASE_CHANNEL="stable"

# Make working directories
mkdir --parents out/ src/ tmp/

# Resolve latest GrapheneOS tag
BUILD_DATETIME=$(date "+%s")
BUILD_NUMBER=$(date "+%Y%m%d%H%M")
echo "${BUILD_DATETIME}" > tmp/.build_datetime
echo "${BUILD_NUMBER}" > tmp/.build_number

echo "Fetching latest ${GRAPHENEOS_RELEASE_CHANNEL} tag from grapheneos.org/releases..."
RELEASES_HTML=$(curl --fail --silent "https://grapheneos.org/releases")
TAG=$(echo "${RELEASES_HTML}" \
| grep --only-matching --perl-regexp "id=[a-z]+-${GRAPHENEOS_RELEASE_CHANNEL}><td>[^<]+</td><td><a href=#\K[0-9]{10}" \
| sort --numeric-sort --reverse | head --lines=1)
if [ -z "${TAG}" ]; then
echo "ERROR: failed to extract a valid ${GRAPHENEOS_RELEASE_CHANNEL} tag"
exit 1
fi
echo "Resolved latest ${GRAPHENEOS_RELEASE_CHANNEL} tag: ${TAG}"
echo "${TAG}" > tmp/.grapheneos_tag


# Sync sources
pushd src
GRAPHENEOS_TAG=$(cat ../tmp/.grapheneos_tag)
echo "Initialising from tag: ${GRAPHENEOS_TAG}"
repo init --depth=1 --git-lfs \
    --manifest-branch "refs/tags/${GRAPHENEOS_TAG}" \
    --manifest-url https://github.com/GrapheneOS/platform_manifest.git
mkdir --parents .repo/local_manifests
cp --verbose ../configs/manifests/*.xml .repo/local_manifests/
SYNC_JOBS=8 # using more jobs causes google ratelimit for me
while ! repo sync --force-sync --jobs=${SYNC_JOBS} --no-clone-bundle --no-tags; do
    echo "repo sync failed, retrying in 30s..."
    sleep 30
done

popd # src/
popd # treble_restlessos/
