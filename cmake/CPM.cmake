include_guard(GLOBAL)
set(PROJECT_CPM_VERSION 0.43.1)
set(PROJECT_CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${PROJECT_CPM_VERSION}.cmake")

# A matching cached file is reused without downloading. CPM handles its own cache.
file(DOWNLOAD
  "https://github.com/cpm-cmake/CPM.cmake/releases/download/v${PROJECT_CPM_VERSION}/CPM.cmake"
  "${PROJECT_CPM_DOWNLOAD_LOCATION}"
  EXPECTED_HASH SHA256=1c40fc102ce9625d7de7eb14f541cab30cc3138dca627f0b0ec40293ce6c2934
  TLS_VERIFY ON
)
include("${PROJECT_CPM_DOWNLOAD_LOCATION}")
