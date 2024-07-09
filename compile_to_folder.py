import os
import glob
import shutil
import subprocess

sourcemod_dir = r"D:\sourcemod\addons\sourcemod"
spcomp_path = os.path.join(sourcemod_dir, r"scripting\spcomp64.exe")
plugins_path = os.path.join(sourcemod_dir, "plugins")
default_arguments = "-i 'D:\Github\robogithub\include' -i 'D:\sourcemod-custom-includes' -O2 -v2"

# Specify the root folder explicitly
root_folder = os.path.dirname(os.path.abspath(__file__))
sp_files = glob.glob(os.path.join(root_folder, "*.sp"))

for sp_file in sp_files:
    sp_file_name = os.path.basename(sp_file)
    
    if ("joke" in sp_file_name or
        "test" in sp_file_name or
        "dont_compile" in sp_file_name or
        "don_compile" in sp_file_name or
        sp_file_name == "changeteam.sp" or
        sp_file_name == "enablemvm.sp"):
        continue

    output_path = ""
    folder_path = ""

    if sp_file_name.startswith("berobot_"):
        folder_path = os.path.join(root_folder, r"compiled\mm_handlers")
        output_path = os.path.join(folder_path, os.path.splitext(sp_file_name)[0] + ".smx")
    elif sp_file_name.startswith("ability_"):
        folder_path = os.path.join(root_folder, r"compiled\mm_robots\robot_abilities")
        output_path = os.path.join(folder_path, sp_file_name)
    elif any(sp_file_name.startswith(prefix) for prefix in ["free_", "paid_", "boss_"]):
        folder_path = os.path.join(root_folder, r"compiled\mm_robots")
        output_path = os.path.join(folder_path, sp_file_name)
    elif sp_file_name.startswith("mm_"):
        folder_path = os.path.join(root_folder, r"compiled\mm_attributes")
        output_path = os.path.join(folder_path, sp_file_name)
    else:
        continue

    # Create the necessary folders if they don't exist
    os.makedirs(folder_path, exist_ok=True)

    arguments = f"{sp_file} -o={output_path} {default_arguments}"
    command = f"{spcomp_path} {arguments}"

    print(command)
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        print(f"Compilation failed for {sp_file}")
        exit()

    print("")

    # Check if the output file exists before attempting to copy
    if os.path.exists(output_path):
        # Copy the compiled file to the plugins directory
        shutil.copy(output_path, plugins_path)
    else:
        print(f"Output file {output_path} does not exist. Skipping copying to plugins directory.")
