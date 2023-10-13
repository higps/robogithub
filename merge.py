import os

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def write_file(file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)

def merge_files(root_dir):
    merged_data = {}  # filename: content

    # Helper function to append data within "Robot" bracket
    def append_within_robot_bracket(existing_content, new_content):
        return existing_content.rstrip('}').strip() + '\n' + new_content.replace('"Robot"\n{', '').rstrip('}').strip() + '\n}'

    # Step 1: Get root cfg files
    for item in os.listdir(root_dir):
        if item.endswith('.cfg'):
            content = read_file(os.path.join(root_dir, item))
            merged_data[item] = content

    # Step 2: Get sub directory cfg files
    for subdir, _, _ in os.walk(root_dir):
        for item in os.listdir(subdir):
            if item.endswith('.cfg') and subdir != root_dir:
                content = read_file(os.path.join(subdir, item))
                if item in merged_data:
                    merged_data[item] = append_within_robot_bracket(merged_data[item], content)

    return merged_data

def main():
    # User input
    root_dir = input("Enter the root directory: ")

    # Merge cfg files
    merged_data = merge_files(root_dir)

    # Create 'MERGED' directory if not exists
    merged_dir = os.path.join(root_dir, "MERGED")
    if not os.path.exists(merged_dir):
        os.makedirs(merged_dir)

    # Save merged content
    for filename, content in merged_data.items():
        full_path = os.path.join(merged_dir, filename)
        write_file(full_path, content)
        print(f"File '{filename}' saved in MERGED directory!")

if __name__ == "__main__":
    main()
