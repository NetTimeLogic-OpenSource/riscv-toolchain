#!/usr/bin/env bash

set -euo pipefail

# Variables
RISCV_GNU_TOOLCHAIN_TAG=2026.08.25
RISCV_GNU_TOOLCHAIN_SRC=$PWD/riscv-gnu-toolchain
RISCV_GNU_TOOLCHAIN_INSTALL=$1

LLVM_VERSION=22.1.8
LLVM_INSTALL=$2

# Script to build full toolchain for riscv32-unknown-linux-gnu with
# -march=rv32imac and -mabi=ilp32
# The toolchain involves a GNU GCC compiler and LLVM (clang, lld)

git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git $RISCV_GNU_TOOLCHAIN_SRC -b $RISCV_GNU_TOOLCHAIN_TAG --depth 1
pushd $RISCV_GNU_TOOLCHAIN_SRC
./configure \
    --prefix=$RISCV_GNU_TOOLCHAIN_INSTALL \
    --with-arch=rv32imac \
    --with-abi=ilp32
make -j$(nproc) linux

popd
rm -rf $RISCV_GNU_TOOLCHAIN_SRC

# Strip host binaries (target libs in sysroot stay untouched)
find $RISCV_GNU_TOOLCHAIN_INSTALL/bin $RISCV_GNU_TOOLCHAIN_INSTALL/libexec \
    -type f -exec strip --strip-unneeded {} \; 2>/dev/null || true

echo "Toolchain built and installed in $RISCV_GNU_TOOLCHAIN_INSTALL"

# Prebuilt LLVM (clang, lld); target/sysroot are set via clang config file
case $(uname -m) in
    x86_64) LLVM_ARCH=X64 ;;
    aarch64) LLVM_ARCH=ARM64 ;;
    *) echo "Unsupported architecture: $(uname -m)" >&2; exit 1 ;;
esac

# The release tarball is the full LLVM distribution (~5 GB); install only
# what the toolchain uses
LLVM_TMP=$PWD/llvm-dist
mkdir -p $LLVM_TMP
curl -fL https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/LLVM-$LLVM_VERSION-Linux-$LLVM_ARCH.tar.xz \
    | tar -xJ --strip-components=1 -C $LLVM_TMP

LLVM_MAJOR=${LLVM_VERSION%%.*}
mkdir -p $LLVM_INSTALL/bin $LLVM_INSTALL/lib
for tool in clang clang++ clang-cpp clang-$LLVM_MAJOR lld ld.lld llvm-ar llvm-ranlib llvm-strip llvm-objcopy llvm-nm; do
    cp -P $LLVM_TMP/bin/$tool $LLVM_INSTALL/bin/
done
cp -rP $LLVM_TMP/lib/clang $LLVM_INSTALL/lib/
cp -P $LLVM_TMP/lib/libclang.so* $LLVM_INSTALL/lib/
cp -P $LLVM_TMP/lib/libclang-cpp.so* $LLVM_INSTALL/lib/ 2>/dev/null || true
cp -P $LLVM_TMP/lib/libLLVM.so* $LLVM_INSTALL/lib/ 2>/dev/null || true
rm -rf $LLVM_TMP

$LLVM_INSTALL/bin/clang --version
$LLVM_INSTALL/bin/ld.lld --version
$LLVM_INSTALL/bin/llvm-ar --version > /dev/null

echo "LLVM toolchain installed in $LLVM_INSTALL"
echo "RISC-V toolchain build completed successfully."
