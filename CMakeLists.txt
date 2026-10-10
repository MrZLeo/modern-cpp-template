cmake_minimum_required(VERSION 4.4)
project(Project VERSION 0.1.0 LANGUAGES CXX)

if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
  message(FATAL_ERROR "In-source builds are not supported. Use cmake -G Ninja -S . -B build.")
endif()

# Initialize project targets and dependencies before they are created.
set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
string(TOLOWER "${PROJECT_NAME}" PROJECT_NAME_LOWERCASE)
string(TOUPPER "${PROJECT_NAME}" PROJECT_NAME_UPPERCASE)
string(MAKE_C_IDENTIFIER "${PROJECT_NAME_UPPERCASE}" PROJECT_NAME_UPPERCASE)

include(cmake/StandardSettings.cmake)
include(cmake/CompilerWarnings.cmake)
include(cmake/StaticAnalyzers.cmake)
include(cmake/SourcesAndHeaders.cmake)
include(cmake/Utils.cmake)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(generated_include_dir "${PROJECT_BINARY_DIR}/include")
set(generated_project_dir "${generated_include_dir}/${PROJECT_NAME_LOWERCASE}")
set(PROJECT_HEADER_ONLY 0)
if(${PROJECT_NAME}_BUILD_HEADERS_ONLY)
  set(PROJECT_HEADER_ONLY 1)
  add_library(${PROJECT_NAME} INTERFACE)
  set(library_scope INTERFACE)
else()
  add_library(${PROJECT_NAME} ${sources})
  set(library_scope PUBLIC)
  set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN ON
    VERIFY_PRIVATE_HEADER_SETS ON
  )
  if(private_headers)
    target_sources(${PROJECT_NAME} PRIVATE FILE_SET private_headers TYPE HEADERS
      BASE_DIRS "${PROJECT_SOURCE_DIR}/src"
      FILES ${private_headers}
    )
  endif()
  target_include_directories(${PROJECT_NAME} PRIVATE "${PROJECT_SOURCE_DIR}/src")
  include(GenerateExportHeader)
  generate_export_header(${PROJECT_NAME}
    EXPORT_FILE_NAME "${generated_project_dir}/export.hpp"
    EXPORT_MACRO_NAME "${PROJECT_NAME_UPPERCASE}_EXPORT"
    NO_EXPORT_MACRO_NAME "${PROJECT_NAME_UPPERCASE}_NO_EXPORT"
    DEPRECATED_MACRO_NAME "${PROJECT_NAME_UPPERCASE}_DEPRECATED"
    STATIC_DEFINE "${PROJECT_NAME_UPPERCASE}_STATIC_DEFINE"
  )
  set_project_warnings(${PROJECT_NAME})
  project_enable_static_analysis(${PROJECT_NAME})
  if(${PROJECT_NAME}_ENABLE_CODE_COVERAGE)
    target_compile_options(${PROJECT_NAME} PRIVATE --coverage)
    target_link_options(${PROJECT_NAME} PUBLIC --coverage)
  endif()
  if(${PROJECT_NAME}_ENABLE_ASAN AND NOT MSVC)
    target_link_options(${PROJECT_NAME} PUBLIC -fsanitize=address)
  endif()
endif()
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})
target_compile_features(${PROJECT_NAME} ${library_scope} cxx_std_26)

configure_file(cmake/config.hpp.in "${generated_project_dir}/config.hpp" @ONLY)
configure_file(cmake/version.hpp.in "${generated_project_dir}/version.hpp" @ONLY)
set(generated_headers
  "${generated_project_dir}/config.hpp"
  "${generated_project_dir}/version.hpp"
)
if(NOT ${PROJECT_NAME}_BUILD_HEADERS_ONLY)
  list(APPEND generated_headers "${generated_project_dir}/export.hpp")
endif()
target_sources(${PROJECT_NAME} ${library_scope}
  FILE_SET HEADERS
    BASE_DIRS "${PROJECT_SOURCE_DIR}/include"
    FILES ${headers}
  FILE_SET generated_headers TYPE HEADERS
    BASE_DIRS "${generated_include_dir}"
    FILES ${generated_headers}
)
set_target_properties(${PROJECT_NAME} PROPERTIES VERIFY_INTERFACE_HEADER_SETS ON)

# Add dependencies here with include(cmake/CPM.cmake) and CPMAddPackage(... SYSTEM YES).
# Link their targets with PRIVATE/PUBLIC/INTERFACE according to the API requirements.

if(${PROJECT_NAME}_BUILD_EXECUTABLE)
  # Always test and export the same library that the executable uses.
  add_executable(${PROJECT_NAME}_app ${exe_sources} ${exe_headers})
  add_executable(${PROJECT_NAME}::app ALIAS ${PROJECT_NAME}_app)
  set_target_properties(${PROJECT_NAME}_app PROPERTIES OUTPUT_NAME "${PROJECT_NAME_LOWERCASE}")
  target_link_libraries(${PROJECT_NAME}_app PRIVATE ${PROJECT_NAME}::${PROJECT_NAME})
  set_project_warnings(${PROJECT_NAME}_app)
  project_enable_static_analysis(${PROJECT_NAME}_app)
  if(${PROJECT_NAME}_ENABLE_CODE_COVERAGE)
    target_compile_options(${PROJECT_NAME}_app PRIVATE --coverage)
    target_link_options(${PROJECT_NAME}_app PRIVATE --coverage)
  endif()
  if(BUILD_SHARED_LIBS AND NOT ${PROJECT_NAME}_BUILD_HEADERS_ONLY)
    file(RELATIVE_PATH library_from_bin "${CMAKE_INSTALL_FULL_BINDIR}" "${CMAKE_INSTALL_FULL_LIBDIR}")
    if(APPLE)
      set_property(TARGET ${PROJECT_NAME}_app PROPERTY INSTALL_RPATH "@loader_path/${library_from_bin}")
    elseif(UNIX)
      set_property(TARGET ${PROJECT_NAME}_app PROPERTY INSTALL_RPATH "$ORIGIN/${library_from_bin}")
    endif()
  endif()
  install(TARGETS ${PROJECT_NAME}_app RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
endif()

install(TARGETS ${PROJECT_NAME} EXPORT ${PROJECT_NAME}Targets
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  FILE_SET HEADERS DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  FILE_SET generated_headers DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)
install(EXPORT ${PROJECT_NAME}Targets
  NAMESPACE ${PROJECT_NAME}::
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
)
set(version_arch_option)
if(${PROJECT_NAME}_BUILD_HEADERS_ONLY)
  set(version_arch_option ARCH_INDEPENDENT)
endif()
write_basic_package_version_file("${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  VERSION "${PROJECT_VERSION}"
  COMPATIBILITY SemanticVersion
  ${version_arch_option}
)
# This template filename stays unchanged when the project is renamed.
configure_package_config_file(cmake/ProjectConfig.cmake.in
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
  PATH_VARS CMAKE_INSTALL_INCLUDEDIR
)
install(FILES
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}"
)

include(cmake/Doxygen.cmake)
if(PROJECT_IS_TOP_LEVEL)
  add_clang_format_target()
endif()
if(${PROJECT_NAME}_ENABLE_UNIT_TESTING)
  enable_testing()
  add_subdirectory(test)
endif()
