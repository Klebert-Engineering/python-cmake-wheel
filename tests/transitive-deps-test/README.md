# Transitive Dependencies Test

This test validates that `python-cmake-wheel` correctly handles transitive library dependencies on macOS using `delocate`.

## Dependency Chain

```
py_transitive (Python module)
    ↓ links to
lib_a (shared library)
    ↓ links to
lib_b (shared library)
```

## What This Tests

1. **Build**: All three libraries are built and bundled into a wheel
2. **Delocate**: The `delocate-path` tool should:
   - Fix rpaths in `py_transitive.so` to use `@loader_path`
   - Fix rpaths in `lib_a` to use `@loader_path`
   - Fix rpaths in `lib_b` to use `@loader_path`
   - Bundle all dependencies into the `.dylibs` directory
3. **Runtime**: When the wheel is installed and imported:
   - `py_transitive` can find `lib_a`
   - `lib_a` can find `lib_b`
   - Function calls work correctly across all three levels

## Why This Matters

Without proper delocate handling, `lib_a` would still have absolute paths to `lib_b` (e.g., `/usr/local/lib/lib_b.dylib`), causing runtime failures when the wheel is installed in a different environment.

## Running the Test

```bash
cd tests/transitive-deps-test
mkdir build && cd build
cmake ..
cmake --build .
ctest
```
