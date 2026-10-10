include("${PROJECT_SOURCE_DIR}/cmake/CPM.cmake")
CPMAddPackage(
  NAME Catch2
  GITHUB_REPOSITORY catchorg/Catch2
  VERSION 3.11.0
  SYSTEM YES
  OPTIONS
    "BUILD_SHARED_LIBS OFF"
    "BUILD_TESTING OFF"
    "CATCH_INSTALL_DOCS OFF"
    "CATCH_INSTALL_EXTRAS ON"
)

# Installed packages and CPM source packages expose the adapter differently.
if(Catch2_SOURCE_DIR)
  include("${Catch2_SOURCE_DIR}/extras/Catch.cmake")
elseif(catch2_SOURCE_DIR)
  include("${catch2_SOURCE_DIR}/extras/Catch.cmake")
else()
  include("${Catch2_DIR}/Catch.cmake")
endif()

foreach(file IN LISTS test_sources)
  get_filename_component(test_name "${file}" NAME_WE)
  set(test_target ${PROJECT_NAME}_${test_name})
  add_executable(${test_target} "${file}")
  target_link_libraries(${test_target} PRIVATE Catch2::Catch2WithMain ${PROJECT_NAME}::${PROJECT_NAME})
  set_project_warnings(${test_target})
  if(${PROJECT_NAME}_ENABLE_CODE_COVERAGE)
    target_compile_options(${test_target} PRIVATE --coverage)
    target_link_options(${test_target} PRIVATE --coverage)
  endif()
  catch_discover_tests(${test_target})
endforeach()
if(TARGET ${PROJECT_NAME}_app)
  add_test(NAME application-smoke COMMAND ${PROJECT_NAME}_app)
  set_tests_properties(application-smoke PROPERTIES PASS_REGULAR_EXPRESSION "3")
endif()
