import os

# Folder path to search for .sp files
folder_path = 'D:/Github/robogithub'

# Substrings to search for in the files
substring1 = 'TF2Attrib_SetByName(client, "boots falling stomp"'
substring2 = 'TF2CustAttr_SetString(client, "fall-damage"'

# Initialize lists to store file names
files_with_substring1 = []
files_with_substring2 = []
files_with_either_substring = []

# Loop through files in the folder
for root, _, files in os.walk(folder_path):
    for file in files:
        if file.endswith(".sp"):
            file_path = os.path.join(root, file)
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                file_contents = f.read()
                if substring1 in file_contents and substring2 not in file_contents:
                    files_with_substring1.append(file)
                elif substring2 in file_contents and substring1 not in file_contents:
                    files_with_substring2.append(file)
                elif substring1 in file_contents or substring2 in file_contents:
                    files_with_either_substring.append(file)

# Print the results
print("Files with '{}' but not '{}':".format(substring1, substring2))
for file in files_with_substring1:
    print(file)

print("\nFiles with '{}' but not '{}':".format(substring2, substring1))
for file in files_with_substring2:
    print(file)

print("\nFiles with either '{}' or '{}', but not both:".format(substring1, substring2))
for file in files_with_either_substring:
    print(file)