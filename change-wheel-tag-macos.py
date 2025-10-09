import os
import glob
import sys
import shutil
import re

# Find the latest wheel file
wheel_files = glob.glob(f"{sys.argv[1]}/{sys.argv[2]}*.whl")
if not wheel_files:
    sys.exit(f"No wheel files found matching {sys.argv[1]}/{sys.argv[2]}*.whl")

latest_file = max(wheel_files, key=os.path.getctime)

# Extract current macOS version from wheel filename
match = re.search(r'macosx_(\d+)_(\d+)', latest_file)
if match:
    current_version = f"{match.group(1)}_{match.group(2)}"
else:
    # Fallback if we can't extract version
    current_version = None

# Determine target deployment version
deployment_target = os.getenv('MACOSX_DEPLOYMENT_TARGET')
if deployment_target:
    # Use environment variable if set
    deployment_target = deployment_target.replace(".", "_")
    print(f"Using MACOSX_DEPLOYMENT_TARGET from environment: {deployment_target}")
elif current_version:
    # Keep current version from wheel filename
    deployment_target = current_version
    print(f"Auto-detected macOS version from wheel: {deployment_target}")
else:
    # Use sensible default (macOS 11.0 - Big Sur, widely compatible)
    deployment_target = "11_0"
    print(f"Using default macOS version: {deployment_target}")

# Define the new filename
new_filename = re.sub(r'macosx_\d+_\d+', f'macosx_{deployment_target}', latest_file)

# Only rename if filename actually changed
if latest_file != new_filename:
    print(f"Renaming: {os.path.basename(latest_file)} -> {os.path.basename(new_filename)}")
    shutil.move(latest_file, new_filename)
else:
    print(f"Wheel already has correct tag: {os.path.basename(latest_file)}")
