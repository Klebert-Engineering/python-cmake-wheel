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
add_wheel(mylib
  VERSION "0.0.1"
  AUTHOR "Bob Ross"
  URL "http://python.org"
  PYTHON_REQUIRES ">=3.8"
  DESCRIPTION "Binary Python wheel."
  DEPLOY_FILES "MY_LICENSE.txt"
  TARGET_DEPENDENCIES
  dependency-lib
  MODULE_DEPENDENCIES
  pypi-dependency1 pypi-dependency2
```

The `add_wheel` command will create a temporary `setup.py` for your project in the build folder, which bundles the necessary files. The execution of this `setup.py` is attached to the custom target `wheelname-setup-py`. It will be executed when you run `cmake --build .` in your build directory.
