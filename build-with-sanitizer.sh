#!/bin/bash

# LLVM Build Script with Sanitizer Support
# Usage: ./build-with-sanitizer.sh [SANITIZER_TYPE]
# SANITIZER_TYPE can be: Address, Memory, MemoryWithOrigins, Undefined, Thread, DataFlow, or Address;Undefined

set -e

# Check if sanitizer argument is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <SANITIZER_TYPE>"
    echo ""
    echo "SANITIZER_TYPE can be one of:"
    echo "  Address           - AddressSanitizer (detects memory errors)"
    echo "  Memory            - MemorySanitizer (detects uninitialized reads)"
    echo "  MemoryWithOrigins - MemorySanitizer with origin tracking"
    echo "  Undefined         - UndefinedBehaviorSanitizer"
    echo "  Thread            - ThreadSanitizer (detects data races)"
    echo "  DataFlow          - DataFlowSanitizer"
    echo "  Address;Undefined - Combination of Address and Undefined sanitizers"
    echo ""
    echo "Example:"
    echo "  $0 Address"
    echo ""
    exit 1
fi

set -x 
# Configuration
SANITIZER="${1}"
BUILD_DIR="build-${SANITIZER}"
INSTALL_PREFIX="${PWD}/install-${SANITIZER}"
SANITIZER_LOG="sanitizer-findings-${SANITIZER}.log"
BUILD_LOG="build-${SANITIZER}.log"

# Number of parallel jobs (adjust based on your system)
JOBS=$(nproc)

echo "========================================="
echo "LLVM Build Configuration"
echo "========================================="
echo "Sanitizer: ${SANITIZER}"
echo "Build directory: ${BUILD_DIR}"
echo "Install prefix: ${INSTALL_PREFIX}"
echo "Parallel compile jobs: ${JOBS}"
echo "Parallel link jobs: 1"
echo "========================================="

# Clean previous build directory if requested
if [[ "${CLEAN_BUILD:-0}" == "1" ]]; then
    echo "Cleaning previous build directory..."
    rm -rf "${BUILD_DIR}"
fi

# Create build directory
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Set up compiler environment variables
export CC=clang
export CXX=clang++

# Create MSAN blocklist file (compile-time, not runtime!)
# IMPORTANT: MSAN does NOT support runtime suppressions like other sanitizers.
# It requires a blocklist file passed at compile time via -fsanitize-ignorelist.
# This blocklist will ONLY suppress use-of-uninitialized-value errors (MSAN's sole purpose)
# from the specified file. Other error types from other sanitizers are unaffected.
MSAN_BLOCKLIST="${PWD}/../msan-blocklist.txt"
cat > "${MSAN_BLOCKLIST}" << 'EOF'
src:*/llvm/include/llvm/TableGen/Record.h
src:*/CMakeFiles/CMakeTmp/getErrc.cpp
src:*llvm/include/llvm/TableGen/Record.h
src:*/llvm/lib/TableGen/Record.cpp
src:*/llvm/lib/TableGen/TGLexer.cpp
src:*/llvm/lib/Support/Path.cpp
src:*/llvm/lib/TableGen/TGLexer.cpp
EOF

echo "Created MSAN blocklist file: ${MSAN_BLOCKLIST}"

# Add MSAN blocklist to compiler flags if using Memory sanitizer
# LLVM_USE_SANITIZER will handle all other sanitizer setup automatically
if [[ "${SANITIZER}" == "Memory" || "${SANITIZER}" == "MemoryWithOrigins" ]]; then
    SANITIZER_BLOCKLIST_FLAG="-fsanitize-ignorelist=${MSAN_BLOCKLIST}"
else
    SANITIZER_BLOCKLIST_FLAG=""
fi

# LLVM_USE_SANITIZER expects capitalized format and handles all sanitizer setup
LLVM_USE_SANITIZER_OPT="-DLLVM_USE_SANITIZER=${SANITIZER}"


# Additional sanitizer runtime options
export ASAN_OPTIONS="log_path=${PWD}/../${SANITIZER_LOG}:halt_on_error=0:continue_after_strdup_overflow=1:detect_leaks=1"
export UBSAN_OPTIONS="log_path=${PWD}/../${SANITIZER_LOG}:halt_on_error=0:print_stacktrace=1"
export TSAN_OPTIONS="log_path=${PWD}/../${SANITIZER_LOG}:halt_on_error=0"
export MSAN_OPTIONS="log_path=${PWD}/../${SANITIZER_LOG}:halt_on_error=0:print_suppressions=1"

echo "Using LLVM_USE_SANITIZER=${SANITIZER} (automatic sanitizer setup)"
echo "Sanitizer log: ${SANITIZER_LOG}"
if [[ -n "${SANITIZER_BLOCKLIST_FLAG}" ]]; then
    echo "MSAN blocklist: ${MSAN_BLOCKLIST}"
fi

# When building with sanitizers, use the default system linker instead of lld
# The system linker knows where to find the sanitizer runtime libraries
if [[ "${SANITIZER}" == "Address" || "${SANITIZER}" == "Memory" || "${SANITIZER}" == "MemoryWithOrigins" || "${SANITIZER}" == "Thread" || "${SANITIZER}" == "Address;Undefined" ]]; then
    LINKER_OPT=""
    echo "Note: Using default system linker (not lld) to find sanitizer runtime libraries"
else
    LINKER_OPT="-DLLVM_USE_LINKER=lld"
fi

# CMake configuration
# Note: LLVM_USE_SANITIZER should handle most sanitizer setup automatically
# We only override flags to add the blocklist for MSAN
echo "Running CMake configuration..."
cmake -G Ninja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_C_FLAGS="${SANITIZER_BLOCKLIST_FLAG}" \
    -DCMAKE_CXX_FLAGS="${SANITIZER_BLOCKLIST_FLAG}" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
    -DLLVM_ENABLE_RUNTIMES="libclc" \
    -DLIBCLC_USE_SPIRV_BACKEND=ON \
    -DLLVM_TARGETS_TO_BUILD="X86;AMDGPU;NVPTX;SPIRV" \
    ${LLVM_USE_SANITIZER_OPT} \
    -DLLVM_PARALLEL_LINK_JOBS=1 \
    -DLLVM_PARALLEL_COMPILE_JOBS="${JOBS}" \
    -DLLVM_ENABLE_ZLIB:BOOL=FORCE_ON \
    -DLLVM_ENABLE_ZSTD:BOOL=FORCE_ON \
    -DLLVM_DEFAULT_TARGET_TRIPLE=x86_64-redhat-linux \
    ${LINKER_OPT} \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    ../llvm

echo "========================================="
echo "Starting build..."
echo "========================================="

# Build with ninja, continuing on error
# The -k 0 flag tells ninja to keep going and build as much as possible
echo "Building with sanitizer instrumentation (this may take a while)..."
echo "Build output will be logged to ${BUILD_LOG}"
echo "Sanitizer findings will be logged to ${SANITIZER_LOG}"

# Run ninja with continue-on-error
ninja -k 0 2>&1 | tee "../${BUILD_LOG}" || true

# Check if sanitizer log was created
if [[ -f "../${SANITIZER_LOG}"* ]]; then
    echo ""
    echo "========================================="
    echo "Sanitizer findings detected!"
    echo "Check ${SANITIZER_LOG}* for details"
    echo "========================================="
fi

echo ""
echo "========================================="
echo "Build process completed"
echo "Build directory: ${BUILD_DIR}"
echo "Build log: ${BUILD_LOG}"
echo "Sanitizer log: ${SANITIZER_LOG}*"
echo "========================================="
echo ""
echo "To install, run: cd ${BUILD_DIR} && ninja install"
