import os
import glob
import shutil
import subprocess

sourcemod_dir = r"D:\sourcemod\addons\sourcemod"
spcomp_path = os.path.join(sourcemod_dir, r"scripting\spcomp.exe")
plugins_path = os.path.join(sourcemod_dir, "plugins")
default_arguments = "-i 'D:\Github\robogithub\include' -i 'D:\sourcemod-custom-includes' -O2 -v2"

# Assuming the script is being run from the directory containing the .sp files
sp_files = glob.glob("*.sp")

for sp_file in sp_files:
    if ("joke" in sp_file or
        "test" in sp_file or
        "dont_compile" in sp_file or
        "don_compile" in sp_file or
        "changeteam.sp" in sp_file or
        "enablemvm.sp" in sp_file):
        continue

    if "ability_" in sp_file:
        output_path = os.path.join(os.path.dirname(sp_file), r"compiled\mm_robots\mm_robots_abilities", os.path.splitext(sp_file)[0] + ".smx")
    elif "berobot_" in sp_file:
        output_path = os.path.join(os.path.dirname(sp_file), r"compiled\mm_handlers", os.path.splitext(sp_file)[0] + ".smx")
    elif any(prefix in sp_file for prefix in ["free_", "paid_", "boss_"]):
        output_path = os.path.join(os.path.dirname(sp_file), r"compiled\mm_robots", os.path.splitext(sp_file)[0] + ".smx")
    else:
        output_path = os.path.join(os.path.dirname(sp_file), r"compiled\mm_attributes", os.path.splitext(sp_file)[0] + ".smx")

    arguments = f"{sp_file} -o={output_path} {default_arguments}"
    command = f"{spcomp_path} {arguments}"

    print(command)
    result = subprocess.run(command, shell=True)
    if result.returncode != 0:
        exit()

    print("")
    shutil.copy(output_path, plugins_path)
