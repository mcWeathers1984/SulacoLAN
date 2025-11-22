#pragma once

#include <version>

// Platform
#if defined(_WIN32) || defined(_WIN64)
  #define MCW_PLATFORM_WINDOWS 1
#else
  #define MCW_PLATFORM_LINUX 1
#endif

// C++ standard
#if __cplusplus >= 202302L
  #define MCW_CPP23 1
#else
  #define MCW_CPP23 0
#endif

// std::print feature
#if defined(__cpp_lib_print) && (__cpp_lib_print >= 202207L)
  #define MCW_HAS_STD_PRINT 1
#else
  #define MCW_HAS_STD_PRINT 0
#endif

// std::format feature
#if defined(__cpp_lib_format) && (__cpp_lib_format >= 201907L)
  #define MCW_HAS_STD_FORMAT 1
#else
  #define MCW_HAS_STD_FORMAT 0
#endif

