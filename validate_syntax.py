import os
import re

def validate_cfg_content(content):
    stack = []
    error_lines = []

    for idx, line in enumerate(content.splitlines(), 1):
        # Strip inline comments
        actual_content = line.split('//')[0].strip()

        # Ignore completely commented out or empty lines
        if not actual_content:
            continue

        # Check for open curly brace or value encapsulated in curly braces
        if actual_content == '{' or re.match(r'^\{".*"\s+".*"\}$', actual_content):
            stack.append('{')
            continue

        # Check for close curly brace
        if actual_content == '}':
            if not stack or stack[-1] != '{':
                error_lines.append(idx)
            if stack:
                stack.pop()
            continue

        # Check for single or double values (with quotes)
        if not (re.match(r'^".*"$', actual_content) or re.match(r'^".*"\s+".*"$', actual_content)):
            error_lines.append(idx)

    if stack:  # If there are unmatched opening brackets
        error_lines.append("Unmatched opening brackets.")

    return error_lines


def find_invalid_cfg_files(directory):
    invalid_files = {}

    for filename in os.listdir(directory):
        if filename.endswith('.cfg'):
            with open(os.path.join(directory, filename), 'r') as f:
                content = f.read()

                error_lines = validate_cfg_content(content)
                if error_lines:
                    invalid_files[filename] = error_lines

    return invalid_files

def main():
    directory = input("Enter the directory path: ")
    
    if not os.path.exists(directory):
        print("Directory does not exist.")
        return

    invalid_files = find_invalid_cfg_files(directory)

    if invalid_files:
        print("Files and the lines that don't follow the syntax:")
        for filename, lines in invalid_files.items():
            print(f"{filename}:")
            for line in lines:
                if isinstance(line, int):
                    print(f"  - Line {line}")
                else:
                    print(f"  - {line}")
    else:
        print("All .cfg files adhere to the desired syntax.")

if __name__ == "__main__":
    main()
