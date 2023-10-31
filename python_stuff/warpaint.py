import os

def replace_paint_with_warpaint(file_path, output_dir):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    in_robot_section = False
    in_weapons_section = False
    in_tf_weapon_section = False
    in_cosmetics_section = False
    tf_weapon_nesting = 0
    for i, line in enumerate(lines):
        stripped_line = line.strip()
        if stripped_line.startswith('"Robot"'):
            in_robot_section = True
        elif in_robot_section and stripped_line.startswith('"weapons"'):
            in_weapons_section = True
        elif in_robot_section and stripped_line.startswith('"cosmetics"'):
            in_cosmetics_section = True
        elif in_weapons_section and stripped_line.startswith('"tf_'):
            in_tf_weapon_section = True
            tf_weapon_nesting = 1
        elif in_tf_weapon_section:
            if stripped_line.startswith('{'):
                tf_weapon_nesting += 1
            elif stripped_line.startswith('}'):
                tf_weapon_nesting -= 1
                if tf_weapon_nesting == 0:
                    in_tf_weapon_section = False
        elif in_cosmetics_section and stripped_line.startswith('}'):
            in_cosmetics_section = False

        if in_robot_section and in_weapons_section and in_tf_weapon_section and not in_cosmetics_section and ('"paint"' in stripped_line):
            lines[i] = line.replace('"paint"', '"warpaint_id"')

    # Saving the processed file in the output directory
    output_path = os.path.join(output_dir, os.path.basename(file_path))
    with open(output_path, 'w') as file:
        file.writelines(lines)

def process_directory(directory):
    output_dir = os.path.join(directory, "processed_files")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for filename in os.listdir(directory):
        if filename.endswith(".cfg"):
            file_path = os.path.join(directory, filename)
            replace_paint_with_warpaint(file_path, output_dir)
            print(f"Processed {filename}")

# User input for directory
directory = input("Enter the directory path containing .cfg files: ")

# Processing all .cfg files in the directory
process_directory(directory)

print("All .cfg files in the directory have been processed and saved in the 'processed_files' subfolder.")
