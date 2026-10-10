if(${PROJECT_NAME}_ENABLE_CLANG_TIDY)
  set(CACHE{CLANGTIDY_EXTRA_ARGS} TYPE STRING HELP "Additional clang-tidy arguments (semicolon-separated)." VALUE "")
  find_program(CLANGTIDY clang-tidy REQUIRED)
endif()
if(${PROJECT_NAME}_ENABLE_CPPCHECK)
  find_program(CPPCHECK cppcheck REQUIRED)
endif()

# Do not impose project analysis rules on dependencies or Catch2 test macros.
function(project_enable_static_analysis target)
  if(${PROJECT_NAME}_ENABLE_CLANG_TIDY)
    set_property(TARGET ${target} PROPERTY CXX_CLANG_TIDY
      "${CLANGTIDY}" -extra-arg=-Wno-unknown-warning-option ${CLANGTIDY_EXTRA_ARGS}
    )
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
      # These targets do not use modules; Clang cannot parse GCC's mapper flags.
      set_property(TARGET ${target} PROPERTY CXX_SCAN_FOR_MODULES OFF)
    endif()
  endif()
  if(${PROJECT_NAME}_ENABLE_CPPCHECK)
    set_property(TARGET ${target} PROPERTY CXX_CPPCHECK
      "${CPPCHECK};--suppress=missingInclude;--enable=all;--inline-suppr;--inconclusive"
    )
  endif()
endfunction()
