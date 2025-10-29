#!/usr/bin/env python3
"""Test script for transitive dependency wheel."""

import sys

def test_import():
    """Test that the module can be imported."""
    try:
        import transitive_test
        print("✓ Module imported successfully")
        return True
    except ImportError as e:
        print(f"✗ Failed to import module: {e}")
        return False

def test_transitive_deps():
    """Test that transitive dependencies work correctly."""
    import transitive_test

    # Test the transitive dependency chain: py_transitive → lib_a → lib_b
    result = transitive_test.process(5)
    expected = 25  # (5 * 2 + 10) + 5 = 25

    if result == expected:
        print(f"✓ Transitive dependency test passed: process(5) = {result}")
        return True
    else:
        print(f"✗ Transitive dependency test failed: expected {expected}, got {result}")
        return False

def test_built_in_validation():
    """Test the built-in validation function."""
    import transitive_test

    if transitive_test.test_transitive():
        print("✓ Built-in transitive test passed")
        return True
    else:
        print("✗ Built-in transitive test failed")
        return False

if __name__ == "__main__":
    all_passed = True

    all_passed &= test_import()
    all_passed &= test_transitive_deps()
    all_passed &= test_built_in_validation()

    if all_passed:
        print("\n✓ All tests passed!")
        sys.exit(0)
    else:
        print("\n✗ Some tests failed")
        sys.exit(1)
