#!/bin/bash
set -euo pipefail

# Configuration
TWRP_BRANCH="twrp-12.1"
BUILD_THREADS=$(($(nproc --all)/2))  # Use half available cores for stability
DEVICE_TREE_DIR="device/samsung/${DEVICE_CODE}"
OUTPUT_DIR="/output"
LOG_FILE="${OUTPUT_DIR}/build.log"

# Initialize directories
mkdir -p "${OUTPUT_DIR}"
exec > >(tee -a "${LOG_FILE}") 2>&1  # Log all output

echo "=== Starting TWRP Build ==="
echo "Build Date: $(date)"
echo "Device Tree: ${DEVICE_TREE_URL}"
echo "Device Code: ${DEVICE_CODE}"
echo "TWRP Branch: ${TWRP_BRANCH}"
echo "Build Threads: ${BUILD_THREADS}"

# Install repo tool
echo "--- Setting up repo tool ---"
mkdir -p ~/bin
curl -s https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH

# Initialize TWRP source
echo "--- Initializing TWRP source ---"
mkdir -p twrp
cd twrp
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_aosp.git \
           -b "${TWRP_BRANCH}" \
           --depth=1 \
           --no-repo-verify

# Sync repositories with retries
echo "--- Syncing repositories ---"
for i in {1..3}; do
  repo sync -j"${BUILD_THREADS}" --no-tags --no-clone-bundle --current-branch && break || sleep 30
  [[ $i == 3 ]] && { echo "Failed to sync repositories after 3 attempts"; exit 1; }
  echo "Retrying sync (attempt $i/3)..."
done

# Clone device tree
echo "--- Cloning device tree ---"
git clone --depth=1 "${DEVICE_TREE_URL}" "${DEVICE_TREE_DIR}" || {
  echo "Failed to clone device tree"
  exit 1
}

# Apply patches if patch directory exists
if [[ -d "${DEVICE_TREE_DIR}/patches" ]]; then
  echo "--- Applying patches ---"
  for patch in "${DEVICE_TREE_DIR}"/patches/*.patch; do
    [ -f "$patch" ] || continue
    echo "Applying patch: $(basename "$patch")"
    patch -p1 < "$patch" || {
      echo "Failed to apply patch: $(basename "$patch")"
      exit 1
    }
  done
fi

# Build environment setup
echo "--- Setting up build environment ---"
source build/envsetup.sh

# Lunch configuration
echo "--- Configuring build for device ---"
lunch "twrp_${DEVICE_CODE}-eng" || {
  echo "Failed to configure lunch"
  exit 1
}

# Build recovery image
echo "--- Starting build ---"
time make -j"${BUILD_THREADS}" recoveryimage || {
  echo "Build failed"
  exit 1
}

# Prepare output files
echo "--- Preparing output files ---"
BUILD_DATE=$(date +%Y%m%d)
RECOVERY_IMG="out/target/product/${DEVICE_CODE}/recovery.img"
OUTPUT_IMG="twrp-${DEVICE_CODE}-${BUILD_DATE}.img"

cp "${RECOVERY_IMG}" "${OUTPUT_DIR}/recovery.img"
cp "${RECOVERY_IMG}" "${OUTPUT_DIR}/${OUTPUT_IMG}"

# Generate build info
echo "--- Generating build info ---"
cat > "${OUTPUT_DIR}/build-info.txt" <<EOF
TWRP Build Information
=====================
Build Date: $(date)
Device: ${DEVICE_CODE}
TWRP Branch: ${TWRP_BRANCH}
Build Threads: ${BUILD_THREADS}

Device Tree: ${DEVICE_TREE_URL}
Commit: $(git -C "${DEVICE_TREE_DIR}" rev-parse HEAD)

Build Command:
make -j${BUILD_THREADS} recoveryimage
EOF

# Generate index.html
echo "--- Generating download page ---"
cat > "${OUTPUT_DIR}/index.html" <<EOF
<html>
<head>
  <title>TWRP Build for ${DEVICE_CODE}</title>
  <style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
    h1 { color: #3273dc; }
    .file-list { background: #f5f5f5; padding: 15px; border-radius: 5px; }
    .file-item { margin: 10px 0; }
  </style>
</head>
<body>
  <h1>TWRP Build for ${DEVICE_CODE}</h1>
  <p>Build completed: $(date)</p>
  
  <div class="file-list">
    <h3>Download Files:</h3>
    <div class="file-item">
      <a href="recovery.img">recovery.img</a> (Standard filename)
    </div>
    <div class="file-item">
      <a href="${OUTPUT_IMG}">${OUTPUT_IMG}</a> (Dated version)
    </div>
    <div class="file-item">
      <a href="build-info.txt">build-info.txt</a> (Build details)
    </div>
    <div class="file-item">
      <a href="build.log">build.log</a> (Full build log)
    </div>
  </div>
</body>
</html>
EOF

# Final status
echo "=== Build Successful ==="
echo "Output files available in ${OUTPUT_DIR}:"
ls -lh "${OUTPUT_DIR}"

# Start HTTP server
echo "Starting HTTP server on port 8080..."
echo "Access your files at: http://<your-koyeb-service>.koyeb.app/"
cd "${OUTPUT_DIR}"
python3 -m http.server 8080
