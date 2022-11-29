#.rst:
# FindLIT
# -------
# 
# Find the *LLVM Integrated Tester* (LIT) either from external, in-source,
# or provided by the system.
# 
# The precedence is as follows:
# 
# 1. If an external LIT is requested by specifying the `LLVM_EXTERNAL_LIT`
#    variable, we check if the given path exists and if not, we bail.
# 2. If no `LLVM_EXTERNAL_LIT` is set, then we fall back to checking if the 
#    "in-source" version of lit exsits in `llvm/utils/lit/lit.py`.
# 3. If no "in-source" version of LIT could be find we try to find a
#    "system-provided" version.
# 
# The module defines the following variables:
# 
#  ::
# 
#    LIT_FOUND              - TRUE if lit was found
#    LIT_PATH               - path to the lit executable (if found)
#    LIT_VERSION            - version of lit (e.g. 15.0.0 or 14.0.0dev)
#    LIT_TYPE               - can be "external", "in-source", or "system-provided"
#    LIT_ARGS_DEFAULT       - contains the default LIT arguments and can be
#                             overwritten by the user
#    LLVM_LIT_ARGS          - 
#    LLVM_LIT_ERRC_MESSAGES - Error messages for add_err_msg_substitutions() in
#                             llvm/utils/lit/lit/llvm/config.py
#    LLVM_LIT_TOOLS_DIR     - only on windows as an option to specify the path
#                             to GnuWin32 tool

set(LIT_FOUND FALSE)
set(LIT_TYPE_EXTERNAL "external")
set(LIT_TYPE_IN_SOURCE "in-source")
set(LIT_TYPE_SYSTEM_PROVIDED "system-provided")

# LIT requires Python3
find_package(Python3 ${LLVM_MINIMUM_PYTHON_VERSION} REQUIRED
  COMPONENTS Interpreter)

unset(TMP_LIT_FOUND CACHE)

# Check if an explicitly requested external lit shall be used.
# This can happen when LLVM is build in standalone-mode package by package.
if (LLVM_EXTERNAL_LIT)
  set(LIT_TYPE LIT_TYPE_EXTERNAL)
  if (NOT EXISTS ${LLVM_EXTERNAL_LIT})
    message(WARNING "Failed to find external lit in: ${LLVM_EXTERNAL_LIT}")
  else()
    set(TMP_LIT_FOUND TRUE)
    set(LIT_PATH ${LLVM_EXTERNAL_LIT})
    message(STATUS "Have external lit in: ${LIT_PATH}")
  endif()
else()
  # Try to find the regular lit from within the source
  set(in_source_lit ${LLVM_MAIN_SRC_DIR}/utils/lit/lit.py)
  if(EXISTS ${in_source_lit})
    set(LIT_TYPE LIT_TYPE_IN_SOURCE)
    set(TMP_LIT_FOUND TRUE)
    set(LIT_PATH ${in_source_lit})
    message(STATUS "Have in-source lit in: ${LIT_PATH}")
  else()
    set(LIT_TYPE LIT_TYPE_SYSTEM_PROVIDED)
    find_program(LitProgram
          NAMES llvm-lit lit.py lit
          # NOTE(kwk): We could add the following line to find LIT
          #      "in-source" but it would make it less obvious.
          # PATHS "${LLVM_MAIN_SRC_DIR}/utils/lit"
          DOC "Path to system-provided lit")
    if (LitProgram)
      set(TMP_LIT_FOUND TRUE)
      set(LIT_PATH ${LitProgram})
      message(STATUS "Found system-provided lit: ${LIT_PATH}")
    else()
      message(WARNING "Failed to find system-provided lit")
    endif()
  endif()
endif()

if(TMP_LIT_FOUND)
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
endif()

# Determine lit version and clean it up (e.g. "lit 15.0.0dev" -> "15.0.0dev")
if(TMP_LIT_FOUND)
  execute_process(COMMAND ${LIT_PATH} --version
          OUTPUT_VARIABLE LIT_VERSION_VERSION_RAW_OUTPUT)
  string(STRIP ${LIT_VERSION_VERSION_RAW_OUTPUT} LIT_VERSION_OUTPUT)
  string(REPLACE "lit " "" LIT_VERSION ${LIT_VERSION_OUTPUT})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LIT
  FAIL_MESSAGE
    "Failed to find the LLVM integrated tester (LIT)"
  FOUND_VAR
    LIT_FOUND
  VERSION_VAR
    LIT_VERSION
  REQUIRED_VARS
    LIT_PATH
    LIT_TYPE
    LIT_VERSION
    LIT_ARGS_DEFAULT
    LLVM_LIT_ARGS
    LLVM_LIT_ERRC_MESSAGES)
mark_as_advanced(LIT_PATH
                 LIT_TYPE
                 LIT_VERSION
                 LIT_ARGS_DEFAULT
                 LLVM_LIT_ARGS
                 LLVM_LIT_ERRC_MESSAGES)
