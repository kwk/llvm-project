#!/bin/bash

# Two-Stage ASan Build for LLVM/libclc
# Stage 1: Build ASan-instrumented clang
# Stage 2: Use instrumented clang to build libclc (to detect SPIRV backend leaks)

set -e
set -x

# Configuration
STAGE1_BUILD_DIR="build-stage1-asan"
STAGE1_INSTALL_DIR="$(pwd)/install-stage1-asan"
STAGE2_BUILD_DIR="build-stage2-libclc-asan"
STAGE2_INSTALL_DIR="$(pwd)/install-stage2-libclc-asan"
SANITIZER_LOG="sanitizer-findings-two-stage.log"

# Number of parallel jobs
JOBS=$(nproc)

echo "========================================="
echo "Two-Stage ASan Build Configuration"
echo "========================================="
echo "Stage 1 build: ${STAGE1_BUILD_DIR}"
echo "Stage 1 install: ${STAGE1_INSTALL_DIR}"
echo "Stage 2 build: ${STAGE2_BUILD_DIR}"
echo "Stage 2 install: ${STAGE2_INSTALL_DIR}"
echo "Parallel jobs: ${JOBS}"
echo "========================================="

# Create MSAN blocklist file (for potential future use)
MSAN_BLOCKLIST="$(pwd)/msan-blocklist.txt"
cat > "${MSAN_BLOCKLIST}" << 'EOF'
src:*/CMakeFiles/CMakeTmp/getErrc.cpp
EOF

# Set up sanitizer runtime options
export ASAN_OPTIONS="log_path=$(pwd)/${SANITIZER_LOG}:halt_on_error=0:continue_after_strdup_overflow=1:detect_leaks=1"
export UBSAN_OPTIONS="log_path=$(pwd)/${SANITIZER_LOG}:halt_on_error=0:print_stacktrace=1"

echo ""
echo "========================================="
echo "STAGE 1: Building ASan-instrumented clang"
echo "========================================="

# Clean and create stage 1 build directory
if [[ "${CLEAN_BUILD:-0}" == "1" ]]; then
    echo "Cleaning stage 1 build directory..."
    rm -rf "${STAGE1_BUILD_DIR}" "${STAGE1_INSTALL_DIR}"
fi

mkdir -p "${STAGE1_BUILD_DIR}"
cd "${STAGE1_BUILD_DIR}"

# Configure stage 1
cmake -G Ninja \
    -C ../cmake-cache-stage1-asan.cmake \
    -DCMAKE_INSTALL_PREFIX="${STAGE1_INSTALL_DIR}" \
    ../llvm

# Build stage 1
echo "Building stage 1 (clang with ASan instrumentation)..."
ninja -j "${JOBS}" -k 0 || true

# Install stage 1
echo "Installing stage 1..."
ninja install || true

cd ..

echo ""
echo "========================================="
echo "STAGE 2: Building libclc with instrumented clang"
echo "========================================="

# Verify stage 1 clang exists
if [[ ! -f "${STAGE1_INSTALL_DIR}/bin/clang" ]]; then
    echo "ERROR: Stage 1 clang not found at ${STAGE1_INSTALL_DIR}/bin/clang"
    echo "Stage 1 build may have failed. Check the build log."
    exit 1
fi

echo "Using instrumented clang from: ${STAGE1_INSTALL_DIR}/bin/clang"

# Clean and create stage 2 build directory
if [[ "${CLEAN_BUILD:-0}" == "1" ]]; then
    echo "Cleaning stage 2 build directory..."
    rm -rf "${STAGE2_BUILD_DIR}" "${STAGE2_INSTALL_DIR}"
fi

mkdir -p "${STAGE2_BUILD_DIR}"
cd "${STAGE2_BUILD_DIR}"

# Configure stage 2
cmake -G Ninja \
    -C ../cmake-cache-stage2-libclc.cmake \
    -DSTAGE1_DIR="${STAGE1_INSTALL_DIR}" \
    -DCMAKE_INSTALL_PREFIX="${STAGE2_INSTALL_DIR}" \
    ../llvm

# Build stage 2 (this is where ASan will detect leaks in SPIRV backend)
echo "Building stage 2 (libclc with SPIRV backend)..."
echo "Any memory leaks in SPIRV will be logged to ${SANITIZER_LOG}*"
ninja -j "${JOBS}" -k 0 || true

cd ..

# Check if sanitizer log was created
if [[ -f "${SANITIZER_LOG}"* ]]; then
    echo ""
    echo "========================================="
    echo "Sanitizer findings detected!"
    echo "Check ${SANITIZER_LOG}* for details"
    echo "========================================="
fi

echo ""
echo "========================================="
echo "Two-stage build completed"
echo "========================================="
echo "Stage 1: ${STAGE1_BUILD_DIR}"
echo "Stage 2: ${STAGE2_BUILD_DIR}"
echo "Sanitizer log: ${SANITIZER_LOG}*"
echo "========================================="
