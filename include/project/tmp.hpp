#ifndef PROJECT_TMP_HPP_
#define PROJECT_TMP_HPP_

#include "project/config.hpp"
#if !PROJECT_HEADER_ONLY
#include "project/export.hpp"
#endif

namespace tmp {

#if PROJECT_HEADER_ONLY
[[nodiscard]] constexpr int add(int lhs, int rhs) noexcept { return lhs + rhs; }
#else
[[nodiscard]] PROJECT_EXPORT int add(int lhs, int rhs) noexcept;
#endif

} // namespace tmp

#endif // PROJECT_TMP_HPP_
