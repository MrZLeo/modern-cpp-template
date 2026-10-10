cmake_minimum_required(VERSION 4.4)

# Reusable local/CI smoke matrix. Run inside the desired compiler environment.
# cmake -DMODE=shared -DENABLE_LINT=ON -P test/verify.cmake
get_filename_component(source_dir "${CMAKE_CURRENT_LIST_DIR}/.." ABSOLUTE)
if(NOT DEFINED MODE)
  set(MODE static)
endif()
set(valid_modes static shared executable header-only)
if(NOT MODE IN_LIST valid_modes)
  message(FATAL_ERROR "MODE must be one of: ${valid_modes}")
endif()
if(NOT DEFINED BUILD_DIR)
  set(BUILD_DIR "${source_dir}/build/${MODE}")
endif()
cmake_path(ABSOLUTE_PATH BUILD_DIR BASE_DIRECTORY "${source_dir}" NORMALIZE)
if(NOT DEFINED CONFIG)
  set(CONFIG Debug)
endif()
if(NOT DEFINED ENABLE_LINT)
  set(ENABLE_LINT OFF)
endif()
if(NOT DEFINED ENABLE_COVERAGE)
  set(ENABLE_COVERAGE OFF)
endif()
find_program(CTEST_COMMAND ctest REQUIRED)

function(run)
  message(STATUS "Running: ${ARGV}")
  execute_process(COMMAND ${ARGV}
    WORKING_DIRECTORY "${source_dir}"
    COMMAND_ERROR_IS_FATAL ANY
  )
endfunction()

set(build_shared OFF)
set(build_headers OFF)
set(build_app OFF)
if(MODE STREQUAL "shared")
  set(build_shared ON)
  set(build_app ON)
elseif(MODE STREQUAL "executable")
  set(build_app ON)
elseif(MODE STREQUAL "header-only")
  set(build_headers ON)
endif()
run("${CMAKE_COMMAND}" -G Ninja -S "${source_dir}" -B "${BUILD_DIR}"
  "-DCMAKE_BUILD_TYPE=${CONFIG}"
  "-DBUILD_SHARED_LIBS=${build_shared}"
  "-DProject_BUILD_HEADERS_ONLY=${build_headers}"
  "-DProject_BUILD_EXECUTABLE=${build_app}"
  -DProject_ENABLE_UNIT_TESTING=ON
  -DProject_WARNINGS_AS_ERRORS=ON
  "-DProject_ENABLE_CLANG_TIDY=${ENABLE_LINT}"
  "-DProject_ENABLE_CODE_COVERAGE=${ENABLE_COVERAGE}"
)
run("${CMAKE_COMMAND}" --build "${BUILD_DIR}" --parallel 4)
run("${CTEST_COMMAND}" --test-dir "${BUILD_DIR}" --output-on-failure --no-tests=error)
run("${CMAKE_COMMAND}" --build "${BUILD_DIR}" --target all_verify_header_sets --parallel 4)
if(ENABLE_LINT)
  # INTERFACE libraries have no translation units to lint. Check the public
  # sample header explicitly as well as compiled library/application sources.
  find_program(CLANG_TIDY_COMMAND clang-tidy REQUIRED)
  run("${CLANG_TIDY_COMMAND}" "${source_dir}/include/project/tmp.hpp" --
    -std=c++26 "-I${source_dir}/include" "-I${BUILD_DIR}/include"
  )
endif()

# Use a new private staging directory on each run; never delete a user's prefix.
string(RANDOM LENGTH 12 ALPHABET 0123456789abcdef package_id)
set(package_dir "${BUILD_DIR}/package-check-${package_id}")
set(original "${package_dir}/original")
set(relocated "${package_dir}/relocated install")
run("${CMAKE_COMMAND}" --install "${BUILD_DIR}" --prefix "${original}")
file(RENAME "${original}" "${relocated}")
run("${CMAKE_COMMAND}" -G Ninja -S "${source_dir}/test/consumer" -B "${package_dir}/consumer"
  "-DCMAKE_BUILD_TYPE=${CONFIG}" "-DCMAKE_PREFIX_PATH=${relocated}"
)
run("${CMAKE_COMMAND}" --build "${package_dir}/consumer" --parallel 4)
# Windows consumers need the installed shared DLL on PATH. Unix consumers use
# CMake's build RPATH; the installed application uses its relative install RPATH.
run("${CMAKE_COMMAND}" -E env --modify "PATH=path_list_prepend:${relocated}/bin" --
  "${CTEST_COMMAND}" --test-dir "${package_dir}/consumer" --output-on-failure --no-tests=error
)
if(build_app)
  set(executable_suffix "")
  if(CMAKE_HOST_WIN32)
    set(executable_suffix .exe)
  endif()
  run("${relocated}/bin/project${executable_suffix}")
endif()
message(STATUS "${MODE}: build, tests, headers, relocated package and real consumer passed")
