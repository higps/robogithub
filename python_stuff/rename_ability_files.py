import os

def rename_files(directory):
    try:
        # List all files in the specified directory
        files = os.listdir(directory)

        for file in files:
            # Check if the file has the ".sp" extension
            if file.endswith(".sp"):
                # Check if the string "ability" is in the filename
                if "ability" in file:
                    # Rename the file with "ability" at the front
                    new_name = "ability_" + file
                    os.rename(os.path.join(directory, file), os.path.join(directory, new_name))
                    print(f'Renamed: {file} -> {new_name}')

    except FileNotFoundError:
        print(f"Directory '{directory}' not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    # Get directory from user input
    user_directory = input("Enter the directory path: ")

    # Call the function to rename files
    rename_files(user_directory)
