#!/bin/bash
set -euxo pipefail

# Pre-apply patches to the vendored openconnect source so that build.rs
# doesn't need to find `patch` on the PATH during cargo build.
pushd crates/openconnect/deps/openconnect
for p in ../patches/*.patch; do
    patch -p1 -i "$p"
done
popd

# Remove patch files so build.rs finds none to apply (but keep the directory
# since build.rs calls read_dir on it and panics if it's missing)
rm -f crates/openconnect/deps/patches/*.patch

# The Rust autotools crate derives --host for configure by stripping -cc/-gcc
# from the C compiler path. In conda-forge, CC is a full path like
# $BUILD_PREFIX/bin/x86_64-conda-linux-gnu-cc, so stripping -cc yields the
# full path as the --host value, which config.sub rejects.
# Set target-specific env vars that the cc crate checks first, using basename
# only so the autotools crate derives a valid triplet (x86_64-conda-linux-gnu).
_CC_BASENAME="$(basename "${CC}")"
_CXX_BASENAME="$(basename "${CXX}")"
export CC="${_CC_BASENAME}"
export CXX="${_CXX_BASENAME}"
export CC_x86_64_unknown_linux_gnu="${_CC_BASENAME}"
export CXX_x86_64_unknown_linux_gnu="${_CXX_BASENAME}"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="${_CC_BASENAME}"

# Patch hardcoded /usr/bin/ paths in constants.rs to use bare binary names
# so they are found via PATH at runtime, regardless of install location.
sed -i 's|"/usr/bin/gpclient"|"gpclient"|g' crates/common/src/constants.rs
sed -i 's|"/usr/bin/gpservice"|"gpservice"|g' crates/common/src/constants.rs
sed -i 's|"/usr/bin/gpauth"|"gpauth"|g' crates/common/src/constants.rs
sed -i 's|"/usr/bin/gpgui-helper"|"gpgui-helper"|g' crates/common/src/constants.rs
sed -i 's|"/usr/bin/gpgui"|"gpgui"|g' crates/common/src/constants.rs

# Remove rust-toolchain.toml to use the conda-forge Rust toolchain
rm -f rust-toolchain.toml

# The vendored static openconnect uses libiconv but build.rs doesn't emit
# the link flag. Add it via RUSTFLAGS.
export RUSTFLAGS="${RUSTFLAGS:-} -L native=${PREFIX}/lib -l iconv"

# Build CLI components with --no-default-features to skip webview-auth
# (which pulls in webkit2gtk, tauri, and heavy GUI dependencies).
cargo build --release --no-default-features -p gpclient -p gpauth -p gpservice

# Install binaries into the conda prefix
# cargo may place outputs under target/<triple>/release/ or target/release/
_TARGET_DIR="target/release"
if [ -d "target/x86_64-unknown-linux-gnu/release" ]; then
    _TARGET_DIR="target/x86_64-unknown-linux-gnu/release"
fi
install -Dm755 "${_TARGET_DIR}/gpclient" "${PREFIX}/bin/gpclient"
install -Dm755 "${_TARGET_DIR}/gpauth" "${PREFIX}/bin/gpauth"
install -Dm755 "${_TARGET_DIR}/gpservice" "${PREFIX}/bin/gpservice"

# Bundle third-party licenses
cargo-bundle-licenses --format yaml --output THIRDPARTY.yml
