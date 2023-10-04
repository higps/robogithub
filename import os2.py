import os

# Directory path
search_directory = 'D:/Github/robogithub'  # <-- Modify this to the path where you want to search

## Function to clean up and standardize whitespace in a line
def standardize_whitespace(line):
    return ' '.join(line.split())

# Search specified directory for .sp files
for filename in os.listdir(search_directory):
    if filename.endswith(".sp") and (filename.startswith("boss_") or filename.startswith("free_") or filename.startswith("paid_")):
        with open(os.path.join(search_directory, filename), 'r') as file:
            lines = file.readlines()

        # Standardize the whitespace for each line
        cleaned_lines = [standardize_whitespace(line) for line in lines]

        # Define the block start and end for easier identification
        block_start = "stock TF2_SetHealth(client, NewHealth)"
        block_end = "SetEntProp(client, Prop_Data, \"m_iMaxHealth\", NewHealth, 1);"

        # Identify the start and end indices of the block
        try:
            start_index = cleaned_lines.index(block_start)
            end_index = cleaned_lines.index(block_end)
        except ValueError:
            continue  # Block not found in this file

        # Remove the block
        del lines[start_index:end_index+2]  # +2 to remove the block end line and the closing brace

        # Write back the modified content
        with open(os.path.join(search_directory, filename), 'w') as file:
            file.writelines(lines)