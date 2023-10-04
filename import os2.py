import os
import re

# Define the directory where your files are located
directory = 'D:/Github/robogithub'


# Define a regular expression pattern to match the desired string
# Define regular expression patterns to match and capture TFClass_ values
set_class_pattern = r'TF2_SetPlayerClass\(client, (TFClass_[^),]+)\);'
set_health_pattern = r'RoboSetHealth\(client, TFClass_,'

# Loop through the files in the directory
for filename in os.listdir(directory):
    if filename.startswith(("boss_", "free_", "paid_")) and filename.endswith(".sp"):
        file_path = os.path.join(directory, filename)
        
        # Read the file content
        with open(file_path, 'r') as file:
            file_content = file.read()
        
        # Search for and capture TFClass_ values in TF2_SetPlayerClass calls
        class_matches = re.findall(set_class_pattern, file_content)
        
        # Replace TFClass_ values in RoboSetHealth calls
        transformed_content = re.sub(set_health_pattern + r'\s*TFClass_,', lambda match: f'{set_health_pattern}{match.group(1)},', file_content)
        
        # Write the modified content back to the file
        with open(file_path, 'w') as file:
            file.write(transformed_content)