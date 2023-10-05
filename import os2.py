import os

def main():
    # Check all files in the current directory
    files = [f for f in os.listdir() if f.endswith('.sp')]

    # Filter files with desired prefixes
    desired_prefixes = ['boss_', 'paid_', 'free_']
    files_with_prefix = [f for f in files if any(f.startswith(prefix) for prefix in desired_prefixes)]

    # Check for the absence of the string "RoboSetHealth(" in the file's content
    files_without_string = []
    for filename in files_with_prefix:
        with open(filename, 'r') as file:
            content = file.read()
            if "RoboSetHealth(" not in content:
                files_without_string.append(filename)

    # Print out the files that don't contain the string
    if files_without_string:
        print("Files without the string 'RoboSetHealth(':")
        for f in files_without_string:
            print(f)
    else:
        print("All files contain the string 'RoboSetHealth('.")

if __name__ == '__main__':
    main()