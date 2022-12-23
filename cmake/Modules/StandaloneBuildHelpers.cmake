# This file provides helper functions for projects that can be built in
# standalone mode which you often find in packaging situations.

include_guard()

# NOTE: The reason to first run `find_package(LLVM)` is that all the imported
#       executables in LLVMExports.cmake are checked for existence. This saves
#       us from checking for them ourselves.
# WARNING: The functions in this file only makes sense when building in standalone mode.
#          Therefore it raises a FATAL_ERROR if you're using it in some other
#          context.
if (NOT (CLANG_BUILT_STANDALONE OR LLD_BUILT_STANDALONE OR COMPILER_RT_STANDALONE_BUILD OR OPENMP_STANDALONE_BUILD OR MLIR_STANDALONE_BUILD OR LLDB_BUILT_STANDALONE))
    message(FATAL_ERROR "Make sure you build in standalone mode")
endif()
find_package(LLVM REQUIRED)

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
#       installed with LLVM. Your utility target must be define there.
function(get_llvm_utility_binary_path utility out_var)
    set(_imploc IMPORTED_LOCATION_NOCONFIG)
    # Based on the build type that LLVM was built with, we pick the right
    # import location.
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
endfunction()

macro(set_lit_defaults)
    # Define the default arguments to use with 'lit', and an option for the user
    # to override.
    set(LIT_ARGS_DEFAULT "-sv")
    if (MSVC OR XCODE)
      set(LIT_ARGS_DEFAULT "${LIT_ARGS_DEFAULT} --no-progress-bar")
    endif()
    set(LLVM_LIT_ARGS "${LIT_ARGS_DEFAULT}" CACHE STRING "Default options for lit")
  
    get_errc_messages(LLVM_LIT_ERRC_MESSAGES)
    set(LLVM_LIT_ERRC_MESSAGES ${LLVM_LIT_ERRC_MESSAGES})
  
    # On Win32 hosts, provide an option to specify the path to the GnuWin32 tools.
    if( WIN32 AND NOT CYGWIN )
      set(LLVM_LIT_TOOLS_DIR "" CACHE PATH "Path to GnuWin32 tools")
    endif()
endmacro()

macro(find_external_lit)
    if (NOT DEFINED LLVM_EXTERNAL_LIT)
      message(FATAL_ERROR "In standalone build mode you MUST configure with -DLLVM_EXTERNAL_LIT=... pointing to your lit binary")
    endif()
    if (NOT EXISTS ${LLVM_EXTERNAL_LIT})
      message(FATAL_ERROR "Failed to find external lit in: ${LLVM_EXTERNAL_LIT}")
    endif()
endmacro()
