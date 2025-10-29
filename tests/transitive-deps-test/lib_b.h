#pragma once

#ifdef _WIN32
  #ifdef LIB_B_EXPORTS
    #define LIB_B_API __declspec(dllexport)
  #else
    #define LIB_B_API __declspec(dllimport)
  #endif
#else
  #define LIB_B_API __attribute__((visibility("default")))
#endif

LIB_B_API int compute_value(int x);
