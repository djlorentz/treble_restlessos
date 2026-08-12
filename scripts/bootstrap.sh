#!/usr/bin/env bash
#
# This script bootstraps the fetching of RestlessOS, a GSI version of Graphene.
#
set -euo pipefail

# Get the restless OS project
# git clone https://github.com/djlorentz/treble_restlessos.git
# pushd treble_restlessos

# remove the cawilliamson private keys
git apply <<"EOF"
diff --git a/configs/manifests/default.xml b/configs/manifests/default.xml
index b14c3ed..1d9379c 100644
--- a/configs/manifests/default.xml
+++ b/configs/manifests/default.xml
@@ -21,8 +21,8 @@
   <project path="prebuilts/vndk/v30" name="platform/prebuilts/vndk/v30" remote="aosp" revision="5f9884aa352825291757dfd6694b874ad8c1805e" clone-depth="1" />
 
   <!-- lineage: apn database -->
-  <project path="vendor/apn" name="android_vendor_apn" remote="lineage" revision="main" clone-depth="1" />
+  <project path="vendor/apn" name="android_vendor_apn" remote="lineage" revision="f61eef690eac185e6f10a227cd8ac28ab7861557" clone-depth="1" />
 
   <!-- vendor-priv -->
-  <project path="vendor/cawilliamson-priv" name="vendor_cawilliamson-priv" remote="cawilliamson-priv" revision="main" clone-depth="1" />
+  <!-- <project path="vendor/cawilliamson-priv" name="vendor_cawilliamson-priv" remote="cawilliamson-priv" revision="main" clone-depth="1" /> -->
 </manifest>
EOF

# Make working directories
mkdir --parents out/ src/ tmp/

# Resolve latest GrapheneOS tag
GRAPHENEOS_TAG='2026060600'
echo "${GRAPHENEOS_TAG}" > tmp/.grapheneos_tag

# Sync sources
pushd src
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

# copy the trebledroid overlays in
echo "Syncing trebledroid resources..."
rsync --archive --verbose ../trebledroid/ .
echo "Done."

popd # src/
popd # treble_restlessos/
