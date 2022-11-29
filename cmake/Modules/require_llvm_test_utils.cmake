# Usage:
#
# require_llvm_test_utils()
# 
# Will require the existance of these tools:
# lit, FileCheck, count, not. For lit and FileCheck we're checking the version
# to match the current LLVM version. The "count" and "not" binaries don't have
# that option.
#
# After calling this macro you can use LIT_PATH, FileCheck_PATH, count_PATH, and
# not_PATH.
#
# NOTE(kwk): This is mostly meant to be used in standalone build mode when LLVM
#            sub-packages should not assume the presence of any source-code
#            except the one for their own. For example, clang should not assume
#            that the ../llvm source directory exists.

macro(require_llvm_test_utils)
  if (NOT DEFINED LLVM_VERSION)
    message(FATAL_ERROR "LLVM_VERSION not set. Maybe call find_package(LLVM) before using the require_llvm_test_utils macro?")
  endif()
  find_package(LIT ${LLVM_VERSION} EXACT REQUIRED)
  find_package(FileCheck ${LLVM_VERSION} EXACT REQUIRED)
  find_program(count_PATH count PATHS ${LLVM_TOOLS_BINARY_DIR} REQUIRED)
  find_program(not_PATH not PATHS ${LLVM_TOOLS_BINARY_DIR} REQUIRED)
endmacro()