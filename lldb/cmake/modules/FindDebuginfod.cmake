#.rst:
# FindDebuginfod
# -----------
#
# Find debuginfod library and headers
#
# The module defines the following variables:
#
# ::
#
#   Debuginfod_FOUND          - true if debuginfod was found
#   Debuginfod_INCLUDE_DIRS   - include search path
#   Debuginfod_LIBRARIES      - libraries to link
#   Debuginfod_VERSION_STRING - version number
#
# TODO(kwk): Debuginfod_VERSION_STRING is only set if pkg-config file is
# available. Trying to see if we can get a MAJOR, MINOR, PATCH define in the
# debuginfod.h file.

if(Debuginfod_INCLUDE_DIRS AND Debuginfod_LIBRARIES)
  set(Debuginfod_FOUND TRUE)
else()
  # Utilize package config (e.g. /usr/lib64/pkgconfig/libdebuginfod.pc) to fetch
  # version information. 
  find_package(PkgConfig QUIET)
  pkg_check_modules(PC_Debuginfod QUIET libdebuginfod)

  find_path(Debuginfod_INCLUDE_DIRS
            NAMES
              elfutils/debuginfod.h
            HINTS
              /usr/include
              ${PC_Debuginfod_INCLUDEDIR}
              ${PC_Debuginfod_INCLUDE_DIRS}
              ${CMAKE_INSTALL_FULL_INCLUDEDIR})
  find_library(Debuginfod_LIBRARIES
               NAMES
                 debuginfod
               HINTS
                 ${PC_Debuginfod_LIBDIR}
                 ${PC_Debuginfod_LIBRARY_DIRS}
                 ${CMAKE_INSTALL_FULL_LIBDIR})

  if(Debuginfod_INCLUDE_DIRS AND EXISTS "${Debuginfod_INCLUDE_DIRS}/debuginfod.h")
    set(Debuginfod_VERSION_STRING "${PC_Debuginfod_VERSION}")
  endif()

  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Debuginfod
                                    FOUND_VAR
                                      Debuginfod_FOUND
                                    REQUIRED_VARS
                                      Debuginfod_INCLUDE_DIRS
                                      Debuginfod_LIBRARIES
                                    VERSION_VAR
                                      Debuginfod_VERSION_STRING)
  mark_as_advanced(Debuginfod_INCLUDE_DIRS Debuginfod_LIBRARIES)
endif()