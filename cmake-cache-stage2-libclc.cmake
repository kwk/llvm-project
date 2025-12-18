# Stage 2: Build libclc using the ASan-instrumented clang from stage 1
# This will use the instrumented compiler to build libclc, allowing ASan
# to detect any memory leaks in the SPIRV backend during compilation

# IMPORTANT: Set STAGE1_DIR before using this cache file
# Example: cmake -C cmake-cache-stage2-libclc.cmake -DSTAGE1_DIR=/path/to/stage1/install ../llvm

set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")

# Use the stage 1 clang (instrumented with ASan)
# These will be set from STAGE1_DIR variable
if(DEFINED STAGE1_DIR)
    set(CMAKE_C_COMPILER "${STAGE1_DIR}/bin/clang" CACHE STRING "")
    set(CMAKE_CXX_COMPILER "${STAGE1_DIR}/bin/clang++" CACHE STRING "")
endif()

# Only build libclc in stage 2 (we already have clang from stage 1)
set(LLVM_ENABLE_PROJECTS "" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "libclc" CACHE STRING "")
set(LIBCLC_USE_SPIRV_BACKEND ON CACHE BOOL "")

# Target configuration (same as stage 1)
set(LLVM_TARGETS_TO_BUILD "X86;AMDGPU;NVPTX;SPIRV" CACHE STRING "")
set(LLVM_DEFAULT_TARGET_TRIPLE "x86_64-redhat-linux" CACHE STRING "")

# Build optimizations
set(LLVM_PARALLEL_LINK_JOBS 1 CACHE STRING "")
set(LLVM_ENABLE_ZLIB FORCE_ON CACHE BOOL "")
set(LLVM_ENABLE_ZSTD FORCE_ON CACHE BOOL "")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "")

# Note: Not using lld from stage 1 to avoid issues if lld wasn't built/installed
# The default system linker works fine for non-instrumented libclc builds
