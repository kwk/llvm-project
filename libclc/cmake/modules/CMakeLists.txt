include(GNUInstallPackageDir)
include(ExtendPath)
include(FindPrefixFromConfig)

set(LIBCLC_INSTALL_PACKAGE_DIR "${CMAKE_INSTALL_PACKAGEDIR}/libclc" CACHE STRING
  "Path for CMake subdirectory for libclc (defaults to '${CMAKE_INSTALL_PACKAGEDIR}/libclc')")

# Generate LibclcConfig.cmake for the build tree.
set(LIBCLC_CONFIG_CODE "")
set(LIBCLC_CONFIG_CMAKE_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(LIBCLC_CONFIG_LIBRARY_DIR "${LIBCLC_OUTPUT_LIBRARY_DIR}")

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/LibclcConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/LibclcConfig.cmake
  @ONLY)
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/LibclcConfigVersion.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/LibclcConfigVersion.cmake
  @ONLY)

# Generate LibclcConfig.cmake for the install tree.
find_prefix_from_config(LIBCLC_CONFIG_CODE LIBCLC_INSTALL_PREFIX "${LIBCLC_INSTALL_PACKAGE_DIR}")
extend_path(LIBCLC_CONFIG_CMAKE_DIR "\${LIBCLC_INSTALL_PREFIX}" "${LIBCLC_INSTALL_PACKAGE_DIR}")
extend_path(LIBCLC_CONFIG_LIBRARY_DIR "\${LIBCLC_INSTALL_PREFIX}" "${LIBCLC_INSTALL_DIR}")

configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/LibclcConfig.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/LibclcConfig.cmake
  @ONLY)
configure_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/LibclcConfigVersion.cmake.in
  ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/LibclcConfigVersion.cmake
  @ONLY)

set(LIBCLC_CONFIG_CODE)
set(LIBCLC_CONFIG_CMAKE_DIR)
set(LIBCLC_CONFIG_LIBRARY_DIR)

install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/LibclcConfig.cmake
  ${CMAKE_CURRENT_BINARY_DIR}/CMakeFiles/LibclcConfigVersion.cmake
  DESTINATION ${LIBCLC_INSTALL_PACKAGE_DIR}
  COMPONENT libclc-cmake-exports)

if(NOT LLVM_ENABLE_IDE)
  add_custom_target(libclc-cmake-exports)
  add_llvm_install_targets(install-libclc-cmake-exports
                           COMPONENT libclc-cmake-exports)
endif()
