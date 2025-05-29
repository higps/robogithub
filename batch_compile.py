import os
import glob
import subprocess
import shutil

# Configuration
sourcemod_dir = r"D:\sourcemod\addons\sourcemod"
spcomp_path = os.path.join(sourcemod_dir, "scripting", "spcomp64.exe")
plugins_path = os.path.join(sourcemod_dir, "plugins")
default_arguments = [
    "-i", r"D:\Github\robogithub\include",
    "-i", r"D:\sourcemod-custom-includes",
    "-O2", "-v2"
]

# Get the script directory
root_folder = os.path.dirname(os.path.abspath(__file__))

# Find all .sp files in the root folder
sp_files = glob.glob(os.path.join(root_folder, "*.sp"))

# Compile each relevant .sp file
for sp_file in sp_files:
    filename = os.path.basename(sp_file)

    # Skip filtered files
    if any((
        "joke" in filename,
        "test" in filename,
        "dont_compile" in filename,
        "don_compile" in filename,
        filename in ("changeteam.sp", "enablemvm.sp")
    )):
        continue

    output_path = ""
    folder_path = ""

    if filename.startswith("berobot_"):
        folder_path = os.path.join(root_folder, "compiled", "mm_handlers")
        output_path = os.path.join(folder_path, os.path.splitext(filename)[0] + ".smx")
    elif filename.startswith("ability_"):
        folder_path = os.path.join(root_folder, "compiled", "mm_robots", "robot_abilities")
        output_path = os.path.join(folder_path, filename)
    elif filename.startswith(("free_", "paid_", "boss_")):
        folder_path = os.path.join(root_folder, "compiled", "mm_robots")
        output_path = os.path.join(folder_path, filename)
    elif filename.startswith("mm_"):
        folder_path = os.path.join(root_folder, "compiled", "mm_attributes")
        output_path = os.path.join(folder_path, filename)
    else:
        continue  # Skip files that don't match any category

    # Create folder if it doesn't exist
    os.makedirs(folder_path, exist_ok=True)

    # Build and run compile command
    cmd = [spcomp_path, sp_file, f"-o={output_path}"] + default_arguments
    print("Running:", " ".join(cmd))
    result = subprocess.run(cmd)

    # Check result
    if result.returncode != 0:
        print(f"Compilation failed for {sp_file}")
        exit(1)
    print()

    # Copy to plugins folder if it exists
    if os.path.exists(output_path):
        shutil.copy(output_path, plugins_path)
    else:
        print(f"Output file {output_path} does not exist. Skipping copying.")
