import os
import re

# Mapping of keys from _defines_only.cfg to output .cfg format
key_mapping = {
    'ROBOT_NAME': 'name',
    'ROBOT_ROLE': 'role',
    'ROBOT_CLASS': 'class',
    'ROBOT_SUBCLASS': 'subclass',
    'ROBOT_DESCRIPTION': 'shortdescription',
    'ROBOT_ON_DEATH': 'deathtip',
    'ROBOT_TIPS': 'tips'
}

sound_keys = [
    'DEATH', 'LOOP', 'SPAWN'
    # You can add more keys related to sounds if necessary
]

def extract_values_from_file(filename):
    with open(filename, 'r') as f:
        content = f.read()
        pattern = r'#define\s+([\w]+)\s+"([^"]+)"'
        matches = re.findall(pattern, content)
        
        values = {}
        for key, value in matches:
            if key in key_mapping:
                values[key_mapping[key]] = value
            elif key in sound_keys:
                if 'sounds' not in values:
                    values['sounds'] = {}
                values['sounds'][key.lower()] = value
            elif value.endswith('.mdl'):
                values['model'] = value
        
        return values

def write_to_cfg_file(values, output_filename):
    with open(output_filename, 'w') as f:
        f.write('"Robot"\n{\n')
        
        for key, value in values.items():
            if key != 'sounds':
                f.write(f'\t"{key}" "{value}"\n')
        
        if 'sounds' in values:
            f.write('\t"sounds"\n\t{\n')
            for sound_key, sound_value in values['sounds'].items():
                f.write(f'\t\t"{sound_key}" "{sound_value}"\n')
            f.write('\t}\n')
        
        f.write('}\n')

def main():
    # Prompt the user for the directory containing _defines_only.cfg files
    directory_path = input("Please specify the directory path containing _defines_only.cfg files: ")
    
    # List all files in the directory with the _defines_only.cfg ending
    files = [f for f in os.listdir(directory_path) if f.endswith('_defines_only.cfg')]

    for file in files:
        filepath = os.path.join(directory_path, file)
        extracted_values = extract_values_from_file(filepath)
        output_filename = os.path.join(directory_path, file.replace('_defines_only', ''))
        write_to_cfg_file(extracted_values, output_filename)
        print(f"Converted values saved to {output_filename}")

if __name__ == '__main__':
    main()
