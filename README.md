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
# EMAIL
#  Package author email address.
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
# SCRIPTS
#  Additional scripts that should be part of the wheel.
# PYTHON_PACKAGE_DIRS
#  Paths to directories of additional Python packages, which
#  are bundled with the wheel. This could for example contain
#  pybind11 binding module wrappers.
# SUBMODULES
#  Any pybind11 submodules must be listed here to support imports like 
#  "from mod.sub import x". A nested submodule must be listed like
#  "sub.subsub". Parent submodules must be listed explicitly.
add_wheel(mylib-python-bindings
  NAME mylib
  VERSION "0.0.1"
  AUTHOR "Bob Ross"
  EMAIL "email@address.com"
  URL "http://python.org"
  PYTHON_REQUIRES ">=3.8"
  DESCRIPTION "Binary Python wheel."
  DEPLOY_FILES "MY_LICENSE.txt"
  TARGET_DEPENDENCIES
    dependency-lib
  MODULE_DEPENDENCIES
    pypi-dependency1 pypi-dependency2
  SCRIPTS
    /path/to/python/script1
    /path/to/python/script2
  PYTHON_PACKAGE_DIRS
    /path/to/python/project1
    /path/to/python/project2
)
```

The `add_wheel` command will create a temporary `setup.py` for your project in the build folder, which bundles the necessary files. The execution of this `setup.py` is attached to the custom target `wheelname-setup-py`. It will be executed when you run `cmake --build .` in your build directory.

**Note: On macOS, when the `MACOSX_DEPLOYMENT_TARGET` env is set, the wheel will be
tagged with the indicated deployment target version.**

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

## CI Utilities

This repository also provides several utilities to facilitate additional wheel deployment steps that are needed on macOS and Linux.

### Linux

For CI jobs, this repo provides the following docker images:

* `manylinux-cpp17-py3.9-x86_64`
* `manylinux-cpp17-py3.10-x86_64`
* `manylinux-cpp17-py3.11-x86_64`
* `manylinux-cpp17-py3.12-x86_64`

This images are based on GLIBC 2.28, so e.g. the minimum Ubuntu version
for wheels from your CI will be 21.04.

Note: `aarch64` images are not yet deployed. Let us know if you need them!

You may use a Github Actions Snippet like this to build your wheels:

```yaml
jobs:
  build-manylinux:
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]
    runs-on: ubuntu-latest
    container: ghcr.io/klebert-engineering/manylinux-cpp17-py${{ matrix.python-version }}-x86_64:2024.1
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      - name: Configure and Build
        run: |
          mkdir build && cd build
          cmake ..
          cmake --build .
          # Important step: Audit the wheels!
          mv bin/wheel bin/wheel-auditme
          auditwheel repair bin/wheel-auditme/mapget*.whl -w bin/wheel
      - name: Deploy
        uses: actions/upload-artifact@v3
        with:
          name: mapget-py${{ matrix.python-version }}-ubuntu-latest
          path: build/**/bin/wheel/*.whl
      - name: Test
        run: |
          cd build
          ctest --verbose --no-tests=error
```

### macOS

For macOS, this repo provides the `repair-wheel-macos.bash` script, which controls
invocations of the `delocate-path` tool which bundles dependencies into your wheel.

Use it in your Github action like this:

```yaml
jobs:
  build-macos:
    runs-on: macos-13
    strategy:
      matrix:
        python-version: ["3.9", "3.10", "3.11", "3.12"]
    env:
      SCCACHE_GHA_ENABLED: "true"
    steps:
      - uses: actions/checkout@v3
        with:
          submodules: recursive
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          architecture: x64
      - name: Build (macOS)
        if: matrix.os == 'macos-13'
        run: |
          python -m pip install delocate
          export MACOSX_DEPLOYMENT_TARGET=10.15
          mkdir build && cd build
          cmake ..
          cmake --build .
          # Important step: Audit the wheels!
          mv bin/wheel bin/wheel-auditme  # Same as on Linux
          ./_deps/python-cmake-wheel-src/repair-wheel-macos.bash \
                "$(pwd)"/bin/wheel-auditme/mapget*.whl \
                "$(pwd)"/bin/wheel mapget
      - name: Deploy
        uses: actions/upload-artifact@v3
        with:
          name: mapget-py${{ matrix.python-version }}-macos-13
          path: build/**/bin/wheel/*.whl
      - name: Test
        run: |
          cd build
          ctest --verbose --no-tests=error
```

### Windows

No special utilties/audit steps are needed when building on Windows.