# LLVM Sanitizer Build Notes

This document explains key decisions and configurations for building LLVM with sanitizers.

## MemorySanitizer (MSan) Suppressions

### Why We Use `-fsanitize-ignorelist` Instead of Runtime Suppressions

**CRITICAL**: MemorySanitizer does NOT support runtime suppressions like other sanitizers (ASan, TSan, UBSan).

- **Other sanitizers**: Use runtime suppressions via environment variables:
  ```bash
  export ASAN_OPTIONS="suppressions=file.txt"
  export TSAN_OPTIONS="suppressions=file.txt"
  ```

- **MemorySanitizer**: Requires a **compile-time blocklist** passed via compiler flag:
  ```bash
  -fsanitize-ignorelist=/path/to/blocklist.txt
  ```

### Why This Matters

The blocklist file MUST be passed at compile time because:
1. MSan needs to know what to ignore during **instrumentation**, not at runtime
2. Setting `MSAN_OPTIONS="suppressions=file.txt"` has **NO EFFECT**
3. The blocklist changes how MSan instruments code, not just what it reports

### What Gets Suppressed

Since MemorySanitizer **only** detects use-of-uninitialized-value errors:
- Suppressing a file in the MSan blocklist = suppressing only uninitialized value errors
- Other error types (use-after-free, buffer-overflow, etc.) are detected by **other sanitizers** (ASan) and are **NOT affected** by the MSan blocklist

### Current MSan Suppressions

See `msan-blocklist.txt` for the current list of suppressed files. Key suppressions:
- `src:*/CMakeFiles/CMakeTmp/getErrc.cpp` - CMake temporary test file with known uninitialized value issues

## Compiler-RT and Circular Dependencies

### Why We Removed compiler-rt from LLVM_ENABLE_RUNTIMES

When building LLVM with sanitizers (Address, Memory, Thread), we encountered linker errors:
```
ld.lld: error: undefined symbol: __asan_*
```

**Root Cause**: Circular dependency
1. LLVM build needs sanitizer runtime libraries (`libclang_rt.asan*.so`) to link executables
2. compiler-rt (which provides these libraries) is built via `LLVM_ENABLE_RUNTIMES`
3. `LLVM_ENABLE_RUNTIMES` builds in a **separate stage AFTER** the main LLVM build
4. Result: Main build can't find sanitizer runtime because it hasn't been built yet

**Solution**: Remove compiler-rt from `LLVM_ENABLE_RUNTIMES`
- Use the **system's sanitizer runtime** instead (from your system's compiler-rt installation)
- Only build libclc as a runtime: `LLVM_ENABLE_RUNTIMES="libclc"`
- The sanitized LLVM links against system libraries, avoiding the circular dependency

### Why We Don't Use lld When Building with Sanitizers

**Problem**: When using `LLVM_USE_LINKER=lld` with sanitizer builds, we get linker errors:
```
ld.lld: error: undefined symbol: __asan_handle_no_return
ld.lld: error: undefined symbol: __asan_*
```

**Root Cause**: lld doesn't automatically search system library paths for sanitizer runtime libraries

**Solution**: Use the default system linker (GNU ld) when building with sanitizers
- The system linker knows where to find `/usr/lib64/clang/*/lib/linux/libclang_rt.asan*.so`
- Only use lld for non-sanitizer builds
- Still build lld as part of `LLVM_ENABLE_PROJECTS`, just don't use it for linking

The script automatically detects sanitizer builds and omits `LLVM_USE_LINKER=lld` from the CMake configuration.

### Why We Don't Override CMAKE Flags When Using LLVM_USE_SANITIZER

**Problem**: When manually setting `CMAKE_C_FLAGS`, `CMAKE_CXX_FLAGS`, and `CMAKE_*_LINKER_FLAGS` with sanitizer flags, we get linker errors:
```
/usr/bin/ld: ... undefined reference to `__asan_report_store8'
```

**Root Cause**: LLVM's build system has special handling for `LLVM_USE_SANITIZER` in `HandleLLVMOptions.cmake` that properly configures:
- Compiler flags (-fsanitize=...)
- Linker flags (-fsanitize=...)
- Ensures the compiler is used as the linker driver
- Handles sanitizer runtime library paths correctly

Manually overriding CMAKE flags interferes with this automatic setup.

**Solution**: Let `LLVM_USE_SANITIZER` do all the work
- Remove manual `CMAKE_C_FLAGS` and `CMAKE_CXX_FLAGS` overrides
- Remove manual `CMAKE_*_LINKER_FLAGS` overrides
- Only add custom flags when necessary (e.g., `-fsanitize-ignorelist` for MSAN blocklist)

This allows LLVM's build system to properly configure the sanitizer, including ensuring the linker can find the runtime libraries.

## References

- [MemorySanitizer — Clang 22.0.0git documentation](https://clang.llvm.org/docs/MemorySanitizer.html)
- [MemorySanitizer (MSan) - Chromium](https://www.chromium.org/developers/testing/memorysanitizer/)
- Search: "MemorySanitizer suppressions not working" - Many users encounter runtime suppression confusion

## Two-Stage Build for Detecting SPIRV Backend Issues

### Why Two-Stage Build?

When building libclc (which uses the SPIRV backend), we need an instrumented compiler to detect leaks. However:

**Problem**: Single-stage build creates a circular dependency:
1. Stage 1 builds ASan-instrumented clang
2. That clang is then used to build libclc
3. But the instrumented clang from stage 1 doesn't have access to ASan runtime
4. Result: `undefined reference to '__asan_*'` errors

**Solution**: Two-stage build:
- **Stage 1**: Build ASan-instrumented clang (without libclc)
- **Stage 2**: Use stage 1's instrumented clang to build libclc with SPIRV backend

### Using the Two-Stage Build

```bash
./build-two-stage-asan.sh
```

This will:
1. Build an ASan-instrumented clang in `build-stage1-asan/`
2. Install it to `install-stage1-asan/`
3. Use that clang to build libclc in `build-stage2-libclc-asan/`
4. Log any ASan findings to `sanitizer-findings-two-stage.log`

### Manual Two-Stage Build

If you need more control:

**Stage 1: Build instrumented clang**
```bash
mkdir build-stage1-asan
cd build-stage1-asan
cmake -G Ninja \
    -C ../cmake-cache-stage1-asan.cmake \
    -DCMAKE_INSTALL_PREFIX=/path/to/install \
    ../llvm
ninja
ninja install
```

**Stage 2: Build libclc with instrumented clang**
```bash
mkdir build-stage2-libclc-asan
cd build-stage2-libclc-asan
cmake -G Ninja \
    -C ../cmake-cache-stage2-libclc.cmake \
    -DSTAGE1_DIR=/path/to/stage1/install \
    ../llvm
ninja  # ASan will detect SPIRV leaks here
```

## Quick Reference (Single-Stage Builds)

### Building with AddressSanitizer
```bash
./build-with-sanitizer.sh Address
```
- Uses system sanitizer runtime
- No compiler-rt in build
- Detects: use-after-free, buffer-overflow, memory leaks, etc.
- **Note**: Cannot build libclc due to circular dependency (use two-stage instead)

### Building with MemorySanitizer
```bash
./build-with-sanitizer.sh Memory
```
- Uses compile-time blocklist via `-fsanitize-ignorelist`
- No runtime suppressions
- Detects: use-of-uninitialized-value ONLY
- Blocklist file: `msan-blocklist.txt`

### Adding MSan Suppressions

1. Edit the blocklist creation in `build-with-sanitizer.sh`:
   ```bash
   cat > "${MSAN_BLOCKLIST}" << 'EOF'
   src:*/path/to/file.cpp
   fun:functionNameToIgnore
   EOF
   ```

2. Rebuild - suppressions are applied at compile time, not runtime

3. **NEVER** add suppressions to `MSAN_OPTIONS` - they won't work!
