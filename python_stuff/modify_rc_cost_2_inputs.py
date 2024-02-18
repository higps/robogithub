import os
import re

def modify_cfg_file(file_path, original_value, new_value):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    for line in lines:
        if 'rc_cost' in line:
            # Extracting the current rc_cost value
            current_value = re.search(r'"rc_cost"\s+"(\d+(\.\d+)?)\s*"', line)
            if current_value and float(current_value.group(1)) == original_value:
                # Replacing the current value with the new value
                modified_line = re.sub(r'"rc_cost"\s+"(\d+(\.\d+)?)\s*"', r'"rc_cost" "{}"'.format(new_value), line)
                modified_lines.append(modified_line)
            else:
                modified_lines.append(line)
        else:
            modified_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(modified_lines)

def modify_directory(directory_path, original_value, new_value):
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.cfg'):
                file_path = os.path.join(root, file)
                modify_cfg_file(file_path, original_value, new_value)

if __name__ == "__main__":
    directory_path = r'D:\Github\robogithub\cfg\robots'  # Change this to your desired directory
    original_value = 6.5  # Change this to the original value to be replaced
    new_value = 10  # Change this to the new value to replace the original value with
    modify_directory(directory_path, original_value, new_value)
    print("Processing complete.")
