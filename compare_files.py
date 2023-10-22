import os

def list_files_without_extension(dir_path):
    """Return a set of filenames without their extensions."""
    filenames = os.listdir(dir_path)
    return set(os.path.splitext(filename)[0] for filename in filenames if os.path.isfile(os.path.join(dir_path, filename)))

def main():
    # Get the directory paths from the user
    dir1 = input("Enter the path to the first directory: ").strip()
    dir2 = input("Enter the path to the second directory: ").strip()

    # Ensure the directories exist
    if not os.path.exists(dir1) or not os.path.isdir(dir1):
        print(f"Invalid directory path: {dir1}")
        return
    if not os.path.exists(dir2) or not os.path.isdir(dir2):
        print(f"Invalid directory path: {dir2}")
        return

    # Get filenames without extensions
    filenames_dir1 = list_files_without_extension(dir1)
    filenames_dir2 = list_files_without_extension(dir2)

    # Find unmatched filenames
    unmatched_in_dir1 = filenames_dir1 - filenames_dir2
    unmatched_in_dir2 = filenames_dir2 - filenames_dir1

    # Print unmatched filenames
    if unmatched_in_dir1:
        print(f"\nFiles in {dir1} not found in {dir2}:")
        for filename in unmatched_in_dir1:
            print(filename)

    if unmatched_in_dir2:
        print(f"\nFiles in {dir2} not found in {dir1}:")
        for filename in unmatched_in_dir2:
            print(filename)

    if not unmatched_in_dir1 and not unmatched_in_dir2:
        print("\nAll filenames match between the two directories!")

if __name__ == "__main__":
    main()
