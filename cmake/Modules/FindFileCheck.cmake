#.rst:
# FindFileCheck
# -------------
# 
# Find the FileCheck tool.
#
# See https://llvm.org/docs/CommandGuide/FileCheck.html
# 
# The module defines the following variables:
# 
#  ::
# 
#    FileCheck_FOUND   - TRUE if lit was found
#    FileCheck_PATH    - path to the lit executable (if found)
#    FileCheck_VERSION - version of the FileCheck tool (e.g. 15.0.0 or 14.0.1dev)

find_program(FileCheck_PATH
             NAMES FileCheck
             PATHS ${LLVM_TOOLS_BINARY_DIR})

# Determine FileCheck version and clean it up. Example output:
#
#       $ FileCheck --version
#       LLVM (http://llvm.org/):
#          LLVM version 12.0.1
#          Optimized build.
#          Default target: x86_64-unknown-linux-gnu
#          Host CPU: skylake-avx512
if (NOT FileCheck_PATH MATCHES "-NOTFOUND$")
  execute_process(COMMAND ${FileCheck_PATH} --version
                  OUTPUT_VARIABLE FILE_CHECK_VERSION_RAW_OUTPUT)
  string(REGEX MATCH "LLVM version [0-9]+\.[0-9]+\.[0-9]"
         FILE_CHECK_VERSION_OUTPUT ${FILE_CHECK_VERSION_RAW_OUTPUT})
  string(STRIP ${FILE_CHECK_VERSION_OUTPUT} FILE_CHECK_VERSION_OUTPUT)
  string(REPLACE "LLVM version " "" FileCheck_VERSION
         ${FILE_CHECK_VERSION_OUTPUT})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(FileCheck
                                  FAIL_MESSAGE
                                    "Failed to find the FileCheck tool"
                                  FOUND_VAR
                                    FileCheck_FOUND
                                  VERSION_VAR
                                    FileCheck_VERSION
                                  REQUIRED_VARS
                                    FileCheck_PATH
                                    FileCheck_VERSION)
mark_as_advanced(FileCheck_PATH
                 FileCheck_VERSION)
