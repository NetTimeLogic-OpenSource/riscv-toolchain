#!/usr/bin/env bash

set -euo pipefail

# Variables
RISCV_GNU_TOOLCHAIN_TAG=2025.08.08
RISCV_GNU_TOOLCHAIN_SRC=$PWD/riscv-gnu-toolchain
RISCV_GNU_TOOLCHAIN_INSTALL=$1

LLVM_TAG=llvmorg-20.1.8
LLVM_SRC=$PWD/llvm-project
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
echo "Toolchain built and installed in $RISCV_GNU_TOOLCHAIN_INSTALL"

git clone https://github.com/llvm/llvm-project.git $LLVM_SRC -b $LLVM_TAG --depth 1
pushd $LLVM_SRC
mkdir build && cd build
cmake -G "Ninja" \
    -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="RISCV" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="riscv32-unknown-linux-gnu" \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
    -DDEFAULT_SYSROOT=$RISCV_GNU_TOOLCHAIN_INSTALL/sysroot \
    $LLVM_SRC/llvm
ninja -j$(nproc)
ninja install

popd
echo "LLVM toolchain built and installed in $LLVM_INSTALL"
echo "RISC-V toolchain build completed successfully."

# Cleanup
rm -rf $RISCV_GNU_TOOLCHAIN_SRC
rm -rf $LLVM_SRC
echo "Temporary files cleaned up."
# End of script
# EOF