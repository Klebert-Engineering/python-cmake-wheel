#pragma once

#ifdef _WIN32
  #ifdef LIB_A_EXPORTS
    #define LIB_A_API __declspec(dllexport)
  #else
    #define LIB_A_API __declspec(dllimport)
  #endif
#else
  #define LIB_A_API __attribute__((visibility("default")))
#endif

LIB_A_API int process_data(int x);
