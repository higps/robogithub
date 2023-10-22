import os

def rename_files(directory_path):
    # List all files in the specified directory
    for filename in os.listdir(directory_path):
        # Check if the file is a .cfg file and contains the string "_attributes"
        if filename.endswith('.cfg') and "_output" in filename:
            # Form the new filename by removing "_attributes"
            new_filename = filename.replace("_output", "")
            # Rename the file
            os.rename(os.path.join(directory_path, filename), os.path.join(directory_path, new_filename))
            print(f'Renamed {filename} to {new_filename}')

if __name__ == "__main__":
    directory_path = input("Enter the directory path: ")
    if os.path.exists(directory_path):
        rename_files(directory_path)
    else:
        print("The specified directory path does not exist!")

