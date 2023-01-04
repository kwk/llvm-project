# This file provides helper functions and macros for projects that can be built
# in standalone mode which you often find in linux packaging situations.
# We also noticed that most functions set a bunch of variables in the same way
# by default, so we do this while including this file.

include_guard()

# WARNING: The functions in this file only makes sense when building in standalone mode.
#          Therefore it raises a FATAL_ERROR if you're using it in some other
#          context.
# TODO: Add the XXX_STANDALONE check for anything that is missing here.
if (NOT (CLANG_BUILT_STANDALONE
         OR LLD_BUILT_STANDALONE
         OR COMPILER_RT_STANDALONE_BUILD
         OR OPENMP_STANDALONE_BUILD
         OR MLIR_STANDALONE_BUILD
         OR LLDB_BUILT_STANDALONE))
    message(FATAL_ERROR "Make sure you build in standalone mode")
endif()

set(CMAKE_CXX_STANDARD 17 CACHE STRING "C++ standard to conform to")
set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

if(NOT MSVC_IDE)
set(LLVM_ENABLE_ASSERTIONS ${ENABLE_ASSERTIONS}
  CACHE BOOL "Enable assertions")
# Assertions should follow llvm-config's.
mark_as_advanced(LLVM_ENABLE_ASSERTIONS)
endif()

# NOTE: The reason to first run `find_package(LLVM)` is that all the imported
#       executables in LLVMExports.cmake are checked for existence. This saves
#       us from checking for them ourselves.
find_package(LLVM REQUIRED HINTS "${LLVM_CMAKE_DIR}")
list(APPEND CMAKE_MODULE_PATH "${LLVM_DIR}")

# Turn into CACHE PATHs for overwritting
set(LLVM_INCLUDE_DIRS ${LLVM_INCLUDE_DIRS} CACHE PATH "Path to llvm/include and any other header dirs needed")
set(LLVM_BINARY_DIR "${LLVM_BINARY_DIR}" CACHE PATH "Path to LLVM build tree")
set(LLVM_MAIN_SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../llvm" CACHE PATH "Path to LLVM source tree")
set(LLVM_TOOLS_BINARY_DIR "${LLVM_TOOLS_BINARY_DIR}" CACHE PATH "Path to llvm/bin")
set(LLVM_LIBRARY_DIR "${LLVM_LIBRARY_DIR}" CACHE PATH "Path to llvm/lib")

# Automatically add the current source and build directories to the include path.
set(CMAKE_INCLUDE_CURRENT_DIR ON)

# This function tries to get the path to the installed utility binary.
#
# - utility: The utility's target name to look up (e.g. FileCheck). If it does
#            not exist, a FATAL_ERROR is raised.
#
# - out_var: The variable with this name is set in the caller's scope to hold
#            the path to the utility binary.
#
# NOTE: Check the add_llvm_utility macro in AddLLVM.cmake to find out about how
#       utilities are added. They get added to a global list property 
#       LLVM_EXPORTS which ends up in a file LLVMExports.cmake that is
#       installed with LLVM. Your utility target must be defined there.
function(get_llvm_utility_binary_path utility out_var)
    set(_imploc IMPORTED_LOCATION_NOCONFIG)
    # Based on the build type that the installed LLVM was built with,
    # we pick the right import location.
    if (LLVM_BUILD_TYPE STREQUAL "Release")
        set(_imploc IMPORTED_LOCATION_RELEASE)
    elseif (LLVM_BUILD_TYPE STREQUAL "Debug")
        set(_imploc IMPORTED_LOCATION_DEBUG)
    elseif (LLVM_BUILD_TYPE STREQUAL "RelWithDebInfo")
        set(_imploc IMPORTED_LOCATION_RELWITHDEBINFO)
    elseif (LLVM_BUILD_TYPE STREQUAL "MinSize")
        set(_imploc IMPORTED_LOCATION_MINSIZE)
    endif()
    if (TARGET ${utility})
        get_target_property(util_path "${utility}" ${_imploc})
        set(${out_var} "${util_path}" PARENT_SCOPE)
    else()
        message(FATAL_ERROR "The utility with the following target name does not exist: \"${utility}\".")
    endif()
    unset(_imploc)
endfunction()

# The set_lit_defaults macro exists because the code existed in multiple
# locations before.
macro(set_lit_defaults)
    set(LIT_ARGS_DEFAULT "-sv")
    if (MSVC OR XCODE)
      set(LIT_ARGS_DEFAULT "${LIT_ARGS_DEFAULT} --no-progress-bar")
    endif()
    set(LLVM_LIT_ARGS "${LIT_ARGS_DEFAULT}" CACHE STRING "Default options for lit")
  
    get_errc_messages(LLVM_LIT_ERRC_MESSAGES)
    set(LLVM_LIT_ERRC_MESSAGES ${LLVM_LIT_ERRC_MESSAGES} PARENT_SCOPE)
  
    # On Win32 hosts, provide an option to specify the path to the GnuWin32 tools.
    if( WIN32 AND NOT CYGWIN )
      set(LLVM_LIT_TOOLS_DIR "" CACHE PATH "Path to GnuWin32 tools")
    endif()
endmacro()

# The find_external_lit macro ensured the variable LLVM_EXTERNAL_LIT is defined
# and points to an existing file.
macro(find_external_lit)
    if (NOT DEFINED LLVM_EXTERNAL_LIT)
      message(FATAL_ERROR "In standalone build mode you MUST configure with -DLLVM_EXTERNAL_LIT=... pointing to your lit binary")
    endif()
    if (NOT EXISTS ${LLVM_EXTERNAL_LIT})
      message(FATAL_ERROR "Failed to find external lit at place pointed to by LLVM_EXTERNAL_LIT variable: ${LLVM_EXTERNAL_LIT}")
    endif()
endmacro()
