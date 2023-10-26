import os
import re

def extract_sp_strings(file_path):
    patterns = {
        'client': re.compile(r'TF2Attrib_SetByName\(client, "(.*?)", (.*?)\);'),
        'other': re.compile(r'TF2Attrib_SetByName\(\w+, "(.*?)", (.*?)\);')
    }

    attributes = {
        'client': [],
        'other': []
    }

    with open(file_path, 'r') as f:
        for line in f:
            if line.strip().startswith('//'):  # Skip commented lines
                continue

            for key, pattern in patterns.items():
                match = pattern.search(line)
                if match:
                    attributes[key].append(match.groups())

    return attributes

def write_to_cfg(attributes, output_path):
    with open(output_path, 'w') as f:
        if attributes['client']:
            f.write('"Robot"\n{\n')
            for attr, value in attributes['client']:
                f.write(f'  "{attr}" "{value}"\n')
            f.write('}\n\n')
        for attr, value in attributes['other']:
            f.write(f'"{attr}" "{value}"\n')

def main():
    sp_folder = input("Enter the path to the .SP input folder: ")

    if not os.path.exists(sp_folder):
        print("Provided .SP folder path doesn't exist!")
        return
    
    output_folder = os.path.join(sp_folder, "extracted pairs")
    os.makedirs(output_folder, exist_ok=True)
    
    sp_files = [f for f in os.listdir(sp_folder) if f.startswith(('free_', 'paid_', 'boss_')) and f.endswith('.sp')]

    for sp_file in sp_files:
        attributes = extract_sp_strings(os.path.join(sp_folder, sp_file))
        cfg_file_name = sp_file.replace('.sp', '.cfg')
        write_to_cfg(attributes, os.path.join(output_folder, cfg_file_name))
        
    print("Extraction complete. Check the 'extracted pairs' folder for the .cfg files.")

if __name__ == '__main__':
    main()
