import os
import re

# Define a regular expression pattern to match the line containing TF2_SetPlayerClass
tfclass_pattern = r'TF2_SetPlayerClass\(client, (TFClass_\w+);\)'

# Define a regular expression pattern to match the line containing iHealth assignment
ihealth_pattern = r'iHealth\s*=\s*(\d+)'

# Define a regular expression pattern to match the lines to be removed
remove_pattern = r'\b(float OverHeal =|float TotalHealthOverHeal =|float OverHealPenaltyRate =|TF2Attrib_SetByName\(client, "patient overheal penalty",)'

# Directory where your .sp files are located
directory = 'D:/Github/robogithub'

# Loop through files in the directory
for filename in os.listdir(directory):
    if filename.endswith('.sp') and not filename.startswith('berobot_'):
        file_path = os.path.join(directory, filename)
        
        with open(file_path, 'r') as file:
            lines = file.readlines()

        tfclass_name = None
        updated_lines = []
        for line in lines:
            # Check if the line contains TF2_SetPlayerClass
            tfclass_match = re.match(tfclass_pattern, line)
            if tfclass_match:
                tfclass_name = tfclass_match.group(1)
            
            # Check if the line contains iHealth assignment
            ihealth_match = re.match(ihealth_pattern, line)
            if ihealth_match and tfclass_name:
                ihealth = ihealth_match.group(1)
                updated_line = f'RoboSetHealth(client, {tfclass_name}, {ihealth}, 1.5);\n'
                updated_lines.append(updated_line)
            else:
                # Check and exclude lines containing unwanted variables and patterns
                if not re.search(remove_pattern, line):
                    updated_lines.append(line)

        # Write the updated content back to the file
        with open(file_path, 'w') as file:
            file.writelines(updated_lines)