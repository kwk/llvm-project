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

# Configure clang and libclc as projects
# Note: clang is only configured to satisfy libclc's requirements - we don't build it
# libclc will use the instrumented stage 1 clang via LIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR
set(LLVM_ENABLE_PROJECTS "clang;libclc" CACHE STRING "")
set(LLVM_ENABLE_RUNTIMES "" CACHE STRING "")
set(LIBCLC_USE_SPIRV_BACKEND ON CACHE BOOL "")

# CRITICAL: Tell libclc to use the stage 1 instrumented clang instead of building/using stage 2 clang
# This ensures the SPIRV backend is monitored by ASan during libclc compilation
if(DEFINED STAGE1_DIR)
    set(LIBCLC_CUSTOM_LLVM_TOOLS_BINARY_DIR "${STAGE1_DIR}/bin" CACHE PATH "")
endif()

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
