import os
import re

# Define the directory where your files are located
directory = 'D:/Github/robogithub'



# Define a regular expression pattern to match TFClass lines
tf_class_pattern = r'TFClass_(\w+);'

# Iterate through files in the directory
for filename in os.listdir(directory):
    # Check if the filename starts with the specified prefixes
    if filename.startswith(('boss_', 'free_', 'paid_')):
        file_path = os.path.join(directory, filename)

        # Initialize a list to store modified lines
        modified_lines = []

        with open(file_path, 'r') as file:
            lines = file.readlines()

        for line in lines:
            # Check for lines containing TFClass and iHealth
            if 'TFClass_' in line and 'int iHealth =' in line:
                # Extract TFClass and iHealth values
                tf_class_match = re.search(tf_class_pattern, line)
                if tf_class_match:
                    tf_class = tf_class_match.group(1)
                    i_health_match = re.search(r'int iHealth = (\d+);', line)
                    if i_health_match:
                        i_health = i_health_match.group(1)
                        # Replace the line with the modified line
                        modified_line = f'RoboSetHealth(client, TFClass_{tf_class}, iHealth, 1.5);\n'
                        modified_lines.append(modified_line)
                        print(f'Original Line: {line.strip()}')
                        print(f'Modified Line: {modified_line.strip()}')
                    else:
                        modified_lines.append(line)
                else:
                    modified_lines.append(line)
            else:
                modified_lines.append(line)

        # Write the modified lines back to the file
        with open(file_path, 'w') as file:
            file.writelines(modified_lines)