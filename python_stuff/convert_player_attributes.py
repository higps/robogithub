import os
import re

def extract_data_from_file(file_path):
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
        content = file.read()
        
        # Extracting class information
        class_match = re.search(r'TF2_SetPlayerClass\(client, TFClass_(\w+)\);', content)
        class_name = class_match.group(1).lower() if class_match else None

        # Extracting scale information
        scale_match = re.search(r'float scale = ([\d.]+);', content)
        if not scale_match:
            scale_match = re.search(r'UpdatePlayerHitbox\(client, ([\d.]+)\);', content)
        scale = scale_match.group(1) if scale_match else None

        # Extracting player attributes
        attributes = re.findall(r'TF2Attrib_SetByName\(client, "(.+?)", ([\d.]+)\);', content)

        # Extracting custom player attributes
        custom_attributes = re.findall(r'TF2CustAttr_SetString\(client, "(.+?)", "(.+?)"\);', content)
        
        return class_name, scale, attributes, custom_attributes

input_directory = '.'  # Current directory. Change path if needed.
output_directory = './CFG_PLAYER_ATTRIBUTES/'

if not os.path.exists(output_directory):
    os.mkdir(output_directory)

for filename in os.listdir(input_directory):
    if filename.endswith('.sp') and (filename.startswith('free_') or filename.startswith('paid_') or filename.startswith('boss_')):
        output_filename = filename.replace('.sp', '_attributes.cfg')
        output_path = os.path.join(output_directory, output_filename)
        
        result = extract_data_from_file(filename)
        
        if result:
            class_name, scale, attributes, custom_attributes = result
            with open(output_path, 'w') as output_file:
                output_file.write(f'"class" "{class_name}"\n')
                if scale:
                    output_file.write(f'"scale" "{scale}"\n')
                
                if attributes:
                    output_file.write('"player_attributes"\n{\n')
                    for attr_name, attr_value in attributes:
                        output_file.write(f'"{attr_name}" "{attr_value}"\n')
                    output_file.write('}\n')
                
                if custom_attributes:
                    output_file.write('"player_custom_attributes"\n{\n')
                    for custom_attr_name, custom_attr_values in custom_attributes:
                        output_file.write(f'"{custom_attr_name}" "{custom_attr_values}"\n')
                    output_file.write('}\n')

print("Processing complete.")
