# All owned sources are formatted, including disabled application/test targets.
# Dependencies and generated headers are deliberately excluded.
function(add_clang_format_target)
  find_program(${PROJECT_NAME}_CLANG_FORMAT_BINARY clang-format)
  if(${PROJECT_NAME}_CLANG_FORMAT_BINARY)
    add_custom_target(clang-format
      COMMAND "${${PROJECT_NAME}_CLANG_FORMAT_BINARY}" -i
        ${sources} ${headers} ${private_headers} ${exe_sources} ${exe_headers} ${test_sources} ${check_sources}
      WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
      COMMAND_EXPAND_LISTS
      VERBATIM
    )
  endif()
endfunction()
