import os
import shutil
import subprocess
from pathlib import Path

# Define the paths
sourcemod_dir = Path(r"D:\sourcemod\addons\sourcemod")
spcomp_path = sourcemod_dir / "scripting" / "spcomp64.exe"
plugins_path = sourcemod_dir / "plugins"
default_arguments = "-i 'D:\\Github\\robogithub\\include' -i 'D:\\sourcemod-custom-includes' -O2 -v2"

# Define the root folder
root_folder = Path(__file__).parent

# Get all .sp files in the root folder
sp_files = root_folder.glob("*.sp")

# Filtering and processing the files
for sp_file in sp_files:
    if any(sub in sp_file.name for sub in ["joke", "test", "dont_compile", "don_compile"]) or \
       sp_file.name in ["changeteam.sp", "enablemvm.sp"]:
        continue

    output_path = None
    folder_path = None

    if sp_file.name.startswith("berobot_"):
        output_path = root_folder / f"compiled/mm_handlers/{sp_file.stem}.smx"
    elif sp_file.name.startswith("ability_"):
        folder_path = root_folder / "compiled/mm_robots/robot_abilities"
        output_path = folder_path / sp_file.name
    elif any(sp_file.name.startswith(prefix) for prefix in ["free_", "paid_", "boss_"]):
        folder_path = root_folder / "compiled/mm_robots"
        output_path = folder_path / sp_file.name
    elif sp_file.name.startswith("mm_"):
        folder_path = root_folder / "compiled/mm_attributes"
        output_path = folder_path / sp_file.name
    else:
        continue

    # Create the necessary folders if they don't exist
    if folder_path and not folder_path.exists():
        folder_path.mkdir(parents=True, exist_ok=True)

    arguments = f'"{sp_file}" -o="{output_path}" {default_arguments}'
    command = f'"{spcomp_path}" {arguments}'

    print(command)
    result = subprocess.run(command, shell=True, capture_output=True, text=True)

    if result.returncode != 0:
        print(f"Compilation failed for {sp_file} with error:\n{result.stderr}")
        exit(1)
    print("")

    # Check if the output file exists before attempting to copy
    if output_path and output_path.exists():
        # Copy the compiled file to the plugins directory
        shutil.copy(output_path, plugins_path)
    else:
        print(f"Output file {output_path} does not exist. Skipping copying to plugins directory.")
