#!/bin/bash
set -euxo pipefail

INSTALL_DIR="${PREFIX}/lib/mcp-inspector"
mkdir -p "${INSTALL_DIR}"

# Install all workspace dependencies and compile TypeScript
npm ci
npm run build

# Copy built workspace directories preserving the relative structure that
# the CLI relies on: cli/build/cli.js references ../../client/bin/start.js
# and the server resolves its static/ dir via __dirname.
cp -r cli/build "${INSTALL_DIR}/cli/"
cp -r server/build "${INSTALL_DIR}/server/"
if [ -d server/static ]; then
    cp -r server/static "${INSTALL_DIR}/server/"
fi
mkdir -p "${INSTALL_DIR}/client"
if [ -d client/dist ]; then
    cp -r client/dist "${INSTALL_DIR}/client/"
fi
if [ -d client/bin ]; then
    cp -r client/bin "${INSTALL_DIR}/client/"
fi

# Copy node_modules, resolving workspace symlinks so the installed tree
# is self-contained (workspace packages are symlinked in-place by npm).
cp -r node_modules "${INSTALL_DIR}/"
for pkg_dir in "${INSTALL_DIR}/node_modules/@modelcontextprotocol"/inspector-*; do
    if [ -L "${pkg_dir}" ]; then
        real="$(readlink -f "${pkg_dir}")"
        rm "${pkg_dir}"
        cp -r "${real}" "${pkg_dir}"
    fi
done

# Wrapper script — resolves PREFIX at runtime via the script's own location
mkdir -p "${PREFIX}/bin"
cp "${RECIPE_DIR}/mcp-inspector.sh" "${PREFIX}/bin/mcp-inspector"
chmod +x "${PREFIX}/bin/mcp-inspector"
