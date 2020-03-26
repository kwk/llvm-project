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
#   Debuginfod_FOUND             - true if debuginfod was found
#   Debuginfod_INCLUDE_DIRS      - include search path
#   Debuginfod_LIBRARIES         - libraries to link
#   Debuginfod_VERSION_STRING    - version number

if(Debuginfod_INCLUDE_DIRS AND Debuginfod_LIBRARIES AND Debuginfod_VERSION_STRING)
  set(Debuginfod_FOUND TRUE)
else()
  # Utilize package config (e.g. /usr/lib64/pkgconfig/libdebuginfod.pc) to fetch
  # version information.

  # If you happend to have *.pc files installed under another prefix, I suggest
  # to do set PKG_CONFIG_USE_CMAKE_PREFIX_PATH=TRUE and give CMAKE_PREFIX_PATH
  # a reasonable path value. For more information, see:
  # https://cmake.org/cmake/help/latest/module/FindPkgConfig.html#variable:PKG_CONFIG_USE_CMAKE_PREFIX_PATH
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(PC_Debuginfod REQUIRED libdebuginfod)

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

  set(Debuginfod_VERSION_STRING "${PC_Debuginfod_VERSION}")
  
  include(FindPackageHandleStandardArgs)
  find_package_handle_standard_args(Debuginfod
                                    FOUND_VAR
                                      Debuginfod_FOUND
                                    REQUIRED_VARS
                                      Debuginfod_INCLUDE_DIRS
                                      Debuginfod_LIBRARIES
                                    VERSION_VAR
                                      Debuginfod_VERSION_STRING)
  mark_as_advanced(
    Debuginfod_INCLUDE_DIRS
    Debuginfod_LIBRARIES)
endif()
