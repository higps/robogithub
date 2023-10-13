import os

def remove_duplicates_and_empty_braces_in_cfg(file_path, output_directory):
    # Read the file content
    with open(file_path, 'r') as file:
        lines = file.readlines()

    encountered_strings = {}  # Dictionary to hold the strings and their line numbers
    lines_to_remove = []  # List to hold the line numbers of duplicate strings

    # Iterate over the lines and check for duplicates
    for idx, line in enumerate(lines):
        stripped_line = line.strip()

        # Ignore lines with single brackets and quotes
        if stripped_line in {"{", "}", '""'}:
            continue

        # Check for empty {} pairs
        if stripped_line == "{}":
            lines_to_remove.append(idx)
            continue

        # Check if this line was encountered before
        if stripped_line in encountered_strings:
            lines_to_remove.append(idx)
        else:
            encountered_strings[stripped_line] = idx

    # Construct the new content excluding the duplicates and empty braces
    new_content = "".join([line for idx, line in enumerate(lines) if idx not in lines_to_remove])

    # Save the new content back to the file in the "no_duplicates" directory
    output_path = os.path.join(output_directory, os.path.basename(file_path))
    with open(output_path, 'w') as file:
        file.write(new_content)

    print(f"Removed duplicates and empty braces from {file_path} and saved to {output_path}")

def main():
    directory = input("Enter the directory of the .cfg file: ")

    # Create the "no_duplicates" directory
    output_directory = os.path.join(directory, 'no_duplicates')
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    for file_name in os.listdir(directory):
        if file_name.endswith(".cfg"):
            file_path = os.path.join(directory, file_name)
            remove_duplicates_and_empty_braces_in_cfg(file_path, output_directory)

if __name__ == "__main__":
    main()
