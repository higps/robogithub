import os

def rename_files_with_extension(directory_path, extension):
    # List all files in the directory
    files = os.listdir(directory_path)

    # Iterate through each file
    for filename in files:
        # Check if the file has the desired extension
        if filename.endswith(extension):
            # Generate the new filename with "april_" prefix
            new_filename = "april_" + filename

            # Construct the full paths for old and new filenames
            old_filepath = os.path.join(directory_path, filename)
            new_filepath = os.path.join(directory_path, new_filename)

            # Rename the file
            os.rename(old_filepath, new_filepath)
            print(f"Renamed {filename} to {new_filename}")

# User input for directory path and extension
directory_path = input("Enter the directory path: ")
extension = input("Enter the file extension to rename (e.g., '.cfg'): ")

# Call the function to rename files
rename_files_with_extension(directory_path, extension)
