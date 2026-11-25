cmake_minimum_required(VERSION 3.26)
project(wheel_metadata LANGUAGES C)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../..")
include(python-wheel)
set(WHEEL_DEPLOY_DIRECTORY "${CMAKE_BINARY_DIR}/dist")

if (TEST_STABLE_ABI)
  find_package(Python3 REQUIRED COMPONENTS Interpreter Development.SABIModule)
  Python3_add_library(example MODULE USE_SABI 3.10 WITH_SOABI example.c)
  set(metadata LIMITED_API cp310 README_PATH "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
               LICENSE_EXPRESSION BSD-3-Clause)
else()
  Python3_add_library(example MODULE WITH_SOABI example.c)
endif()
add_wheel(example VERSION 1.0 AUTHOR "Example"
          LICENSE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../LICENSE" ${metadata})
