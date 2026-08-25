#!/usr/bin/env bash

# This script is a wrapper for the Clang compiler configured for RISC-V
# It sets the configuration file and passes all arguments to the Clang command

exec /opt/riscv-llvm/bin/clang --config=/opt/clang-wrapper/riscv32-unknown-linux-gnu-clang.cfg "$@"
