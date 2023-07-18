import os
import glob
import sys
import shutil
import re

# Read the deployment target
deployment_target = os.getenv('MACOSX_DEPLOYMENT_TARGET')
if not deployment_target:
    sys.exit("MACOSX_DEPLOYMENT_TARGET is not set")

# Find the latest wheel file
wheel_files = glob.glob(f"{sys.argv[1]}/{sys.argv[2]}*.whl")
latest_file = max(wheel_files, key=os.path.getctime)

# Define the new filename
deployment_target = deployment_target.replace(".", "_")
new_filename = re.sub(r'macosx_\d+_\d+', f'macosx_{deployment_target}', latest_file)

# Rename the wheel file
shutil.move(latest_file, new_filename)
