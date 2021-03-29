find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

# Guess python wheel filename infixes (abi + platform) to be used
# with binary python module dependency URLs.
#
# Example:
#   - "https://my.url/packages/pkg/1.0/pkg-1.0${PY_WHEEL_C_INFIX}.whl"
#
# See:
#   - https://www.python.org/dev/peps/pep-0427/#file-name-convention
#   - https://github.com/pypa/wheel/blob/master/src/wheel/bdist_wheel.py#L43
set(PY_WHEEL_C_ABI "cp${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}-cp${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}")

if (WIN32)
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PY_WHEEL_PLATFORM "win_amd64")
  else()
    set(PY_WHEEL_PLATFORM "win_x86")
  endif()
elseif (APPLE)
  # NOTE: This is the build servers OSX version!
  set(PY_WHEEL_PLATFORM "macosx_10_14_x86_64")
else()
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    set(PY_WHEEL_PLATFORM "linux_x86_64")
  else()
    set(PY_WHEEL_PLATFORM "linux_i686")
  endif()
endif()

set(PY_WHEEL_C_INFIX "-${PY_WHEEL_C_ABI}-${PY_WHEEL_PLATFORM}")
