cmake_minimum_required(VERSION 3.20)
project(test-macos-wheel VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Export all symbols on Windows (like zswag does)
set(CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS ON)

# Enable testing
enable_testing()

# Include python-wheel.cmake from repository root
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../..")
include(python-wheel)

# Set wheel output directory
set(WHEEL_DEPLOY_DIRECTORY "${CMAKE_BINARY_DIR}/wheel")

# Find Python
find_package(Python3 COMPONENTS Interpreter Development.Module REQUIRED)

# Fetch CPM.cmake
set(CPM_DOWNLOAD_VERSION 0.40.2)
if(CPM_SOURCE_CACHE)
  set(CPM_DOWNLOAD_LOCATION "${CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
elseif(DEFINED ENV{CPM_SOURCE_CACHE})
  set(CPM_DOWNLOAD_LOCATION "$ENV{CPM_SOURCE_CACHE}/cpm/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
else()
  set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")
endif()
if(NOT (EXISTS ${CPM_DOWNLOAD_LOCATION}))
  message(STATUS "Downloading CPM.cmake to ${CPM_DOWNLOAD_LOCATION}")
  file(DOWNLOAD
       https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake
       ${CPM_DOWNLOAD_LOCATION}
  )
endif()
include(${CPM_DOWNLOAD_LOCATION})

# Fetch pybind11 via CPM
CPMAddPackage("gh:pybind/pybind11@2.13.6")

# Create simple C++ library
add_library(simple_lib SHARED
    simple_lib.cpp
    simple_lib.h
)

target_include_directories(simple_lib PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Diagnostic logging for Windows
if(WIN32)
    message(STATUS "=== Windows Build Diagnostics ===")
    message(STATUS "CMAKE_GENERATOR: ${CMAKE_GENERATOR}")
    message(STATUS "CMAKE_BINARY_DIR: ${CMAKE_BINARY_DIR}")
    message(STATUS "CMAKE_CONFIGURATION_TYPES: ${CMAKE_CONFIGURATION_TYPES}")
    get_target_property(simple_lib_output simple_lib RUNTIME_OUTPUT_DIRECTORY)
    get_target_property(simple_lib_archive simple_lib ARCHIVE_OUTPUT_DIRECTORY)
    message(STATUS "simple_lib RUNTIME_OUTPUT_DIRECTORY: ${simple_lib_output}")
    message(STATUS "simple_lib ARCHIVE_OUTPUT_DIRECTORY: ${simple_lib_archive}")
    message(STATUS "simple_lib will output to: $<TARGET_FILE:simple_lib>")
    message(STATUS "simple_lib import lib: $<TARGET_LINKER_FILE:simple_lib>")
endif()

# Create Python module using pybind11
pybind11_add_module(py_simple
    py_simple.cpp
)

target_link_libraries(py_simple PRIVATE simple_lib)

# More diagnostics after linking
if(WIN32)
    get_target_property(py_simple_output py_simple RUNTIME_OUTPUT_DIRECTORY)
    message(STATUS "py_simple RUNTIME_OUTPUT_DIRECTORY: ${py_simple_output}")
    message(STATUS "py_simple will output to: $<TARGET_FILE:py_simple>")
    message(STATUS "py_simple will link: $<TARGET_LINKER_FILE:simple_lib>")
endif()

# Package as wheel using add_wheel()
add_wheel(py_simple
    NAME simple_test
    VERSION "1.0.0"
    AUTHOR "Test Author"
    EMAIL "test@example.com"
    DESCRIPTION "Minimal test wheel for python-cmake-wheel"
    PYTHON_REQUIRES ">=3.9"
    TARGET_DEPENDENCIES simple_lib
)

# Add test to validate wheel functionality
add_wheel_test(test-simple-wheel
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMANDS -f "${CMAKE_CURRENT_SOURCE_DIR}/test_wheel.py"
)
