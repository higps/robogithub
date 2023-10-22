import os
import re

def process_file(filepath):
    with open(filepath, 'r') as f:
        lines = f.readlines()

    # Extract name and role
    name = None
    role = None
    for line in lines:
        if '"name"' in line:
            name = line.split('"')[-2]
        elif '"role"' in line:
            role = line.split('"')[-2]

    # Check if name or role is missing
    if name is None or role is None:
        print(f"File {filepath} is missing either name or role. Skipping...")
        return

    # Prompt the user for the new value
    new_value = None
    while True:
        try:
            new_value = float(input(f"Please input dmg vs buildings value for {name}, {role}: "))
            break
        except ValueError:
            print("Invalid input. Please enter a float value.")

    # Replace dmg penalty vs buildings value
    new_lines = []
    for line in lines:
        # Skip commented lines
        if line.strip().startswith('//'):
            new_lines.append(line)
            continue

        if '"dmg penalty vs buildings"' in line:
            line = re.sub(r'"\d+(\.\d+)?"', f'"{new_value}"', line)
        new_lines.append(line)

    # Write changes back to the file
    with open(filepath, 'w') as f:
        f.writelines(new_lines)

    print(f"Updated dmg penalty vs buildings value for {name}, {role} in {filepath}")


def main():
    folder_path = input("Enter the path to the folder containing .cfg files: ")

    # Validate directory path
    if not os.path.exists(folder_path) or not os.path.isdir(folder_path):
        print("Invalid directory path.")
        return

    # Loop through all files with .cfg extension
    for filename in os.listdir(folder_path):
        if filename.endswith(".cfg"):
            process_file(os.path.join(folder_path, filename))

if __name__ == "__main__":
    main()
