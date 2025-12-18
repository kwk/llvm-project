# Stage 1: Build ASan-instrumented clang/LLVM
# This stage builds the compiler toolchain with ASan instrumentation
# The resulting clang will be used in stage 2 to build libclc

set(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "")
set(CMAKE_C_COMPILER clang CACHE STRING "")
set(CMAKE_CXX_COMPILER clang++ CACHE STRING "")

# Build clang and lld (no runtimes in stage 1)
set(LLVM_ENABLE_PROJECTS "clang;lld" CACHE STRING "")

# Use ASan to instrument the compiler
set(LLVM_USE_SANITIZER "Address" CACHE STRING "")

# Target configuration
set(LLVM_TARGETS_TO_BUILD "X86;AMDGPU;NVPTX;SPIRV" CACHE STRING "")
set(LLVM_DEFAULT_TARGET_TRIPLE "x86_64-redhat-linux" CACHE STRING "")

# Build optimizations
set(LLVM_PARALLEL_LINK_JOBS 1 CACHE STRING "")
set(LLVM_ENABLE_ZLIB FORCE_ON CACHE BOOL "")
set(LLVM_ENABLE_ZSTD FORCE_ON CACHE BOOL "")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON CACHE BOOL "")

# Don't use lld for stage 1 (system linker can find ASan runtime)
# set(LLVM_USE_LINKER "lld" CACHE STRING "")
