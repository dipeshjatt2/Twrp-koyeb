#!/bin/bash

set -e

echo "=== Starting TWRP Build ==="
echo "Device Tree: $DEVICE_TREE_URL"
echo "Device Code: $DEVICE_CODE"

# Initialize repo
echo "Initializing TWRP manifest..."
mkdir -p ~/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo

# Sync TWRP source
echo "Syncing TWRP source..."
mkdir -p twrp
cd twrp
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1 --depth=1
repo sync -j$(nproc --all) --no-tags --no-clone-bundle --current-branch

# Clone device tree
echo "Cloning device tree..."
git clone --depth=1 $DEVICE_TREE_URL device/samsung/$DEVICE_CODE

# Build TWRP
echo "Building TWRP..."
source build/envsetup.sh
lunch twrp_${DEVICE_CODE}-eng
make -j$(nproc --all) recoveryimage

# Prepare output
echo "Preparing output..."
mkdir -p /output
cp out/target/product/${DEVICE_CODE}/recovery.img /output/
cp out/target/product/${DEVICE_CODE}/recovery.img /output/twrp-${DEVICE_CODE}-$(date +%Y%m%d).img

# Generate download page
echo "Generating download page..."
cat > /output/index.html <<EOF
<html>
<head><title>TWRP Build</title></head>
<body>
<h1>TWRP Build for ${DEVICE_CODE}</h1>
<p>Build completed: $(date)</p>
<ul>
<li><a href="recovery.img">recovery.img</a></li>
<li><a href="twrp-${DEVICE_CODE}-$(date +%Y%m%d).img">twrp-${DEVICE_CODE}-$(date +%Y%m%d).img</a></li>
</ul>
</body>
</html>
EOF

# Start HTTP server
echo "Build complete! Access your files at:"
echo "http://<your-koyeb-service>.koyeb.app/"
cd /output
python3 -m http.server 8080