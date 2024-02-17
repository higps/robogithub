import os
import re

def process_cfg_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    modified_lines = []
    for line in lines:
        if 'rc_cost' in line:
            # Extracting the number using regular expression
            number = re.search(r'"rc_cost"\s+"(\d+(\.\d+)?)\s*"', line)
            if number:
                # Multiplying the number by 10
                new_number = str(float(number.group(1)) * 10)
                # Replacing the old number with the new one
                modified_line = re.sub(r'"rc_cost"\s+"(\d+(\.\d+)?)\s*"', r'"rc_cost" "{}"'.format(new_number), line)
                modified_lines.append(modified_line)
        else:
            modified_lines.append(line)

    with open(file_path, 'w') as file:
        file.writelines(modified_lines)

def process_directory(directory_path):
    for root, dirs, files in os.walk(directory_path):
        for file in files:
            if file.endswith('.cfg'):
                file_path = os.path.join(root, file)
                process_cfg_file(file_path)

if __name__ == "__main__":
    directory_path = input("Enter the directory path: ")
    process_directory(directory_path)
    print("Processing complete.")