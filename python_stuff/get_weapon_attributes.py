import os
import re

def extract_weapon_data(filename):
    with open(filename, 'r') as file:
        content = file.read()

    weapon_data = {}

    # Extracting weapon names
    weapon_blocks = re.findall(r'if\(IsValidEntity\((\w+)\)\)\s*{([\s\S]*?)}', content)

    for weapon_name, attributes_block in weapon_blocks:
        attributes = {}
        
        # Extracting attributes for the weapon
        attr_matches = re.findall(r'TF2Attrib_SetByName\(\w+, "([^"]+)", ([\d.]+)\);', attributes_block)
        for attr_name, attr_val in attr_matches:
            attributes[attr_name] = attr_val
        
        # Extracting custom attributes
        custom_attr_matches = re.findall(r'TF2CustAttr_SetString\(\w+, "([^"]+)", "([^"]+)"\);', attributes_block)
        if custom_attr_matches:
            custom_attrs = {}
            for attr_str1, attr_str2 in custom_attr_matches:
                custom_attrs[attr_str1] = attr_str2
            attributes["custom_attribute"] = custom_attrs
        
        weapon_data[weapon_name] = attributes
    
    return weapon_data

def write_cfg(output_filename, weapon_data):
    with open(output_filename, 'w') as out_file:
        for weapon_name, attributes in weapon_data.items():
            out_file.write(f'"{weapon_name}"\n{{\n')
            for attr_name, attr_val in attributes.items():
                if attr_name != "custom_attribute":
                    out_file.write(f'  "{attr_name}" "{attr_val}"\n')
                else:
                    out_file.write('  "custom_attribute"\n  {\n')
                    for custom_attr_key, custom_attr_val in attr_val.items():
                        out_file.write(f'    "{custom_attr_key}" "{custom_attr_val}"\n')
                    out_file.write('  }\n')
            out_file.write('}\n')

def process_files(directory_path):
    if not os.path.exists("CFG_WEAPON_ATTRIBUTE_GROUPING"):
        os.makedirs("CFG_WEAPON_ATTRIBUTE_GROUPING")
    
    for filename in os.listdir(directory_path):
        if filename.endswith('.sp') and (filename.startswith('free_') or filename.startswith('paid_') or filename.startswith('boss_')):
            filepath = os.path.join(directory_path, filename)
            weapon_data = extract_weapon_data(filepath)
            
            # Creating the new filename with the desired format
            new_filename = f"{filename.rsplit('.', 1)[0]}_weapon_attribute_grouping.cfg"
            new_filepath = os.path.join("CFG_WEAPON_ATTRIBUTE_GROUPING", new_filename)
            
            write_cfg(new_filepath, weapon_data)

if __name__ == '__main__':
    directory_path = input("Enter the directory path: ")
    process_files(directory_path)
