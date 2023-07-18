# python-cmake-wheel

CMake helper for creating cross-platform binary Python packages.

## How to use?

In your CMakeLists.txt, make sure to include the python-cmake-wheel
directory. Then make a call to `add_wheel` for your library, such as the
following:

```cmake
# Adapt according to your checkout directory
set(CMAKE_MODULE_PATH "path/to/python-cmake-wheel")

# Adapt according to your build directory layout
set(WHEEL_DEPLOY_DIRECTORY "${CMAKE_BINARY_DIR}")

include(python-wheel)

# Placeholder statement to create the 'mylib' target.
# In practice, this will probably be pybind11_add_module(...).
add_library(mylib ...)

# Adapt using the following parameters:
# NAME
#  Wheel name. Defaults to extension module cmake target name.
# VERSION
#  Python package version.
# AUTHOR
#  Package author name.
# URL
#  Package website.
# PYTHON_REQUIRES
#  Python version requirement. Default: >=3.8
# DESCRIPTION
#  Python package short description.
# DEPLOY_FILES
#  Additional files that should be packaged with your wheel.
# TARGET_DEPENDENCIES
#  CMake targets which belong into the same wheel.
# MODULE_DEPENDENCIES
#  Python module dependencies (requirements.txt content)
# SUBMODULES
#  Any pybind11 submodules must be listed here to support imports like 
#  "from mod.sub import x". A nested submodule must be listed like
#  "sub.subsub". Parent submodules must be listed explicitly.
add_wheel(mylib-python-bindings
  NAME mylib
  VERSION "0.0.1"
  AUTHOR "Bob Ross"
  URL "http://python.org"
  PYTHON_REQUIRES ">=3.8"
  DESCRIPTION "Binary Python wheel."
  DEPLOY_FILES "MY_LICENSE.txt"
  TARGET_DEPENDENCIES
    dependency-lib
  MODULE_DEPENDENCIES
    pypi-dependency1 pypi-dependency2)
```

The `add_wheel` command will create a temporary `setup.py` for your project in the build folder, which bundles the necessary files. The execution of this `setup.py` is attached to the custom target `wheelname-setup-py`. It will be executed when you run `cmake --build .` in your build directory.

**Note: On macOS, when the `MACOSX_DEPLOYMENT_TARGET` env is set, the wheel will be
tagged with the indicated deployment target version.

## Adding tests

The `python-wheel.cmake` include also provides a function that lets you easily add a cmake test for your wheel: `add_wheel_test(...)`.

This function can be used as follows:

```cmake
add_wheel_test(mylib-test
  WORKING_DIRECTORY
    # Working directory where the test commands should be executed
    "${CMAKE_CURRENT_LIST_DIR}"
  COMMANDS
    # Two types of commands are available:
    #  -f (--foreground) are synchronous test tasks. They are executed
    #     within a clean temporary python environment, in which all
    #     wheels from your current WHEEL_DEPLOY_DIRECTORY are installed.
    #  -b (--background) are asynchronous background services that need
    #     to run while the synchronous tasks are running, for example
    #     to implement an integration test. They will be killed when
    #     all synchronous tasks are finished.
    #  Note: You can specify an arbitrary number of commands for
    #   both types. They are launched in the specified order, so
    #   make sure to put a background service before a foreground
    #   test script which depends on it.
    -b "${CMAKE_BINARY_DIR}/a-service"
    -f "pytest test.py"
)
```
