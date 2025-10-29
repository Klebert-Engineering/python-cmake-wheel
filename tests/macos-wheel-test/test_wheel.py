#!/usr/bin/env python3
"""
Test script to validate that the simple_test wheel works correctly.
Tests import, instantiation, and basic functionality.
"""
import sys

def test_wheel():
    """Test that the wheel can be imported and used."""
    print("Testing simple_test wheel import and functionality...")

    # Debug: Show what's installed
    import site
    import os
    print(f"Site packages: {site.getsitepackages()}")
    for sp in site.getsitepackages():
        simple_test_dir = os.path.join(sp, "simple_test")
        if os.path.exists(simple_test_dir):
            print(f"Found simple_test in: {simple_test_dir}")
            print(f"Contents: {os.listdir(simple_test_dir)}")
        else:
            print(f"simple_test NOT in: {sp}")

    # Test import
    try:
        import simple_test
        print("[OK] Import successful")
    except ImportError as e:
        print(f"[FAIL] Import failed: {e}")
        import traceback
        traceback.print_exc()
        return False

    # Test instantiation
    try:
        calc = simple_test.Calculator()
        print("[OK] Calculator instantiation successful")
    except Exception as e:
        print(f"[FAIL] Calculator instantiation failed: {e}")
        return False

    # Test add method
    result = calc.add(10, 20)
    if result == 30:
        print(f"[OK] Calculator.add(10, 20) = {result}")
    else:
        print(f"[FAIL] Calculator.add(10, 20) returned {result}, expected 30")
        return False

    # Test multiply method
    result = calc.multiply(5, 6)
    if result == 30:
        print(f"[OK] Calculator.multiply(5, 6) = {result}")
    else:
        print(f"[FAIL] Calculator.multiply(5, 6) returned {result}, expected 30")
        return False

    print("\n[OK] All tests passed!")
    return True

if __name__ == "__main__":
    success = test_wheel()
    sys.exit(0 if success else 1)
