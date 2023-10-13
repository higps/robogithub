import os
import shutil

def move_files(directory_path):
    # Ensure there is an 'equipment' subfolder
    equipment_folder = os.path.join(directory_path, "equipment")
    if not os.path.exists(equipment_folder):
        os.mkdir(equipment_folder)

    # List all files in the specified directory
    for filename in os.listdir(directory_path):
        # If the file contains "_equipment", move it to the 'equipment' subfolder
        if "_equipment" in filename:
            shutil.move(os.path.join(directory_path, filename), os.path.join(equipment_folder, filename))
            print(f'Moved {filename} to {equipment_folder}')

if __name__ == "__main__":
    directory_path = input("Enter the directory path: ")
    if os.path.exists(directory_path):
        move_files(directory_path)
    else:
        print("The specified directory path does not exist!")
