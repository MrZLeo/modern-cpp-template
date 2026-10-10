#include "project/tmp.hpp"
#include "project/version.hpp"

#include <catch2/catch_test_macros.hpp>

#if PROJECT_HEADER_ONLY
static_assert(tmp::add(1, 2) == 3);
#endif
static_assert(PROJECT_VERSION[0] != '\0');

TEST_CASE("tmp::add sums two integers", "[tmp]") {
  REQUIRE(tmp::add(1, 2) == 3);
  REQUIRE(tmp::add(-2, 2) == 0);
  REQUIRE(tmp::add(0, 0) == 0);
}
