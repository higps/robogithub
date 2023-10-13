import re
import os

def extract_equipment_data(filename):
    with open(filename, 'r') as file:
        content = file.readlines()

    weapons = {}
    weapon_references = {}

    for line in content:
        # Ignore commented out lines
        if line.strip().startswith("//"):
            continue

        # Extract weapon creation
        weapon_match = re.search(r'CreateRoboWeapon\(\w+, "([^"]+)", (\d+), (\d+), (\d+), (\d+), (\d+)\);', line)
        if weapon_match:
            weapon_name = weapon_match.group(1)
            weapon_data = {
                "itemindex": weapon_match.group(2),
                "quality": weapon_match.group(3),
                "level": weapon_match.group(4),
                "slot": weapon_match.group(5)
            }
            weapons[weapon_name] = weapon_data

        # Map the weapon reference variable to weapon name
        ref_match = re.search(r'int (\w+) = GetPlayerWeaponSlot\(\w+, \w+\);', line)
        if ref_match:
            weapon_ref = ref_match.group(1)
            weapon_references[weapon_ref] = None
            for key in weapons:
                weapon_references[weapon_ref] = key
                break

        # Extract weapon attributes
        attrs_match = re.search(r'if\(IsValidEntity\((\w+)\)\)', line)
        if attrs_match:
            weapon_ref = attrs_match.group(1)
            weapon_name = weapon_references.get(weapon_ref)
            attributes = {}

            index = content.index(line) + 1
            while 'TF2Attrib_SetByName' in content[index]:
                attr_match = re.search(r'TF2Attrib_SetByName\(\w+, "([^"]+)", ([\d.]+)\);', content[index])
                if attr_match:
                    attr_name = attr_match.group(1)
                    attr_val = attr_match.group(2)
                    attributes[attr_name] = attr_val
                index += 1

            if weapon_name:
                if weapon_ref not in weapons:
                    weapons[weapon_ref] = {
                        "weapon_class_name": weapon_name,
                        "attributes": {}
                    }

                weapons[weapon_ref]['attributes'].update(attributes)

    return weapons

def process_files(directory_path):
    output = {}
    for filename in os.listdir(directory_path):
        if filename.endswith('.sp') and (filename.startswith('free_') or filename.startswith('paid_') or filename.startswith('boss_')):
            filepath = os.path.join(directory_path, filename)
            weapons_data = extract_equipment_data(filepath)
            output.update(weapons_data)

    # Write the final CFG output
    with open("CFG_WEAPON_ATTRIBUTE_GROUPING/cfg_output.cfg", 'w') as out_file:
        for weapon_ref, details in output.items():
            out_file.write(f'"{weapon_ref}"\n{{\n')
            for key, value in details.items():
                if key != "attributes":
                    out_file.write(f'  "{key}" "{value}"\n')
                else:
                    out_file.write('  "attributes"\n  {\n')
                    for attr_name, attr_val in value.items():
                        out_file.write(f'    "{attr_name}" "{attr_val}"\n')
                    out_file.write('  }\n')
            out_file.write('}\n')

if __name__ == '__main__':
    directory_path = input("Enter the directory path: ")
    if not os.path.exists("CFG_WEAPON_ATTRIBUTE_GROUPING"):
        os.makedirs("CFG_WEAPON_ATTRIBUTE_GROUPING")
    process_files(directory_path)
