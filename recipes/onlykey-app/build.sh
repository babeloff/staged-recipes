#!/usr/bin/env bash
set -euo pipefail

# Extract the .deb archive (ar format)
ar x "OnlyKey_${PKG_VERSION}_amd64.deb"

# Find and extract the data tarball (may be .tar.xz, .tar.gz, or .tar.zst)
DATA_TAR=$(ls data.tar.*)
echo "Extracting ${DATA_TAR}"
tar xf "${DATA_TAR}"

echo "=== Extracted layout ==="
find . -maxdepth 4 -not -path './.git*' | sort
echo "========================="

mkdir -p "${PREFIX}/bin"

# Copy usr/* content (bin, share, lib, etc.)
if [ -d usr ]; then
    cp -r usr/. "${PREFIX}/"
fi

# Electron apps sometimes install to /opt/<Name>/
if [ -d opt ]; then
    cp -r opt/. "${PREFIX}/opt/"
fi

# Patch absolute paths in .desktop files
find "${PREFIX}/share/applications" -name '*.desktop' 2>/dev/null | while read -r f; do
    sed -i "s|/usr|${PREFIX}|g;s|/opt|${PREFIX}/opt|g" "$f"
done

# Install the launcher script so `onlykey-app` is on the PATH.
# NW.js must be invoked from its own directory to find its resources.
cp "${RECIPE_DIR}/onlykey-app" "${PREFIX}/bin/onlykey-app"
chmod +x "${PREFIX}/bin/onlykey-app"
