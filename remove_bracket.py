import os

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def write_file(file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)

def remove_second_top_level_bracket(file_path):
    content = read_file(file_path)
    
    # Count levels to determine top-level brackets
    bracket_level = 0
    removed = False
    new_content = []

    for char in content:
        if char == '{':
            bracket_level += 1
        elif char == '}':
            bracket_level -= 1
            if bracket_level == 0 and not removed:
                removed = True
                continue
        new_content.append(char)

    write_file(file_path, ''.join(new_content))

def main():
    # User input
    root_dir = input("Enter the directory: ")

    for subdir, _, files in os.walk(root_dir):
        for file in files:
            file_path = os.path.join(subdir, file)
            remove_second_top_level_bracket(file_path)
            print(f"Processed file: {file_path}")

if __name__ == "__main__":
    main()
