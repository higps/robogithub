import os
import shutil

# Source and target directories
source_dir = r'C:\Steam\steamapps\workshop\content\440'
target_dir = r'C:\Steam\steamapps\common\Team Fortress 2\tf\maps\workshop'

def rename_and_copy_bsp_files(source, target):
    # Iterate through each subdirectory in the source directory
    for folder_name in os.listdir(source):
        folder_path = os.path.join(source, folder_name)
        
        # Ensure the current path is a directory
        if os.path.isdir(folder_path):
            # Iterate through each file in the subdirectory
            for file_name in os.listdir(folder_path):
                if file_name.endswith('.bsp'):
                    # Construct the new file name with .ugc<folder_name> inserted before .bsp
                    new_file_name = file_name.replace('.bsp', f'.ugc{folder_name}.bsp')
                    source_file_path = os.path.join(folder_path, file_name)
                    target_file_path = os.path.join(target, new_file_name)
                    
                    # Copy the file from the source to the target directory with the new name
                    shutil.copy2(source_file_path, target_file_path)
                    print(f'Copied: {source_file_path} to {target_file_path}')

# Call the function
rename_and_copy_bsp_files(source_dir, target_dir)
