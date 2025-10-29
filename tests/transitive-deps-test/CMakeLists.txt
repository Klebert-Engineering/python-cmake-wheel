cmake_minimum_required(VERSION 3.20)
project(test-transitive-deps VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Export all symbols on Windows
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

# Create lib_b (lowest level dependency)
add_library(lib_b SHARED
    lib_b.cpp
    lib_b.h
)

target_compile_definitions(lib_b PRIVATE LIB_B_EXPORTS)

target_include_directories(lib_b PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# Create lib_a (depends on lib_b)
add_library(lib_a SHARED
    lib_a.cpp
    lib_a.h
)

target_compile_definitions(lib_a PRIVATE LIB_A_EXPORTS)

target_include_directories(lib_a PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(lib_a PUBLIC lib_b)

# Create Python module using pybind11 (depends on lib_a)
pybind11_add_module(py_transitive
    py_transitive.cpp
)

target_link_libraries(py_transitive PRIVATE lib_a)

# Package as wheel using add_wheel()
# Note: We include both lib_a and lib_b in TARGET_DEPENDENCIES
# This tests that delocate properly handles the transitive dependency chain
add_wheel(py_transitive
    NAME transitive_test
    VERSION "1.0.0"
    AUTHOR "Test Author"
    EMAIL "test@example.com"
    DESCRIPTION "Test wheel with transitive library dependencies (lib_a → lib_b)"
    PYTHON_REQUIRES ">=3.9"
    TARGET_DEPENDENCIES lib_a lib_b
)

# Add test to validate wheel functionality
add_wheel_test(test-transitive-wheel
    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
    COMMANDS -f "${CMAKE_CURRENT_SOURCE_DIR}/test_wheel.py"
)
