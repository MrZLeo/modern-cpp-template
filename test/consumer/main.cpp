#include "project/tmp.hpp"

#ifndef _MSC_VER
static_assert(__cplusplus > 202302L);
#endif

int main() { return tmp::add(1, 2) == 3 ? 0 : 1; }
