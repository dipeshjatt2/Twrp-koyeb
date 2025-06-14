#!/bin/bash

set -e

# Clone TWRP manifest
echo "Initializing TWRP build environment..."
export PATH=~/bin:$PATH
mkdir -p twrp
cd twrp
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git -b twrp-12.1
repo sync -j$(nproc --all)

# Clone device tree (replace with your actual device tree)
echo "Cloning device tree..."
git clone https://github.com/dipeshjatt2/android_device_samsung_gta9p.git device/samsung/a9p

# Build TWRP
echo "Building TWRP..."
source build/envsetup.sh
lunch twrp_a9p-eng
make -j$(nproc --all) recoveryimage

# Prepare output
echo "Preparing output..."
mkdir -p /output
cp out/target/product/a9p/recovery.img /output/
cp out/target/product/a9p/recovery.img /output/twrp-a9p-$(date +%Y%m%d).img

# Create simple HTTP server to access files
echo "Build complete! Access TWRP image at:"
echo "http://<your-koyeb-service>.koyeb.app/output/recovery.img"
cd /output
python3 -m http.server 8080