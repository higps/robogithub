import os
import re
import shutil

# Constants
WEAPON_SLOTS = {
    "TFWeaponSlot_Primary": "0",
    "TFWeaponSlot_Secondary": "1",
    "TFWeaponSlot_Melee": "2",
    "TFWeaponSlot_Grenade": "3",
    "TFWeaponSlot_Building": "4",
    "TFWeaponSlot_PDA": "5",
    "TFWeaponSlot_Item1": "6",
    "TFWeaponSlot_Item2": "7"
}

def extract_equipment_data(filename):
    with open(filename, 'r') as file:
        content = file.readlines()

    data = {
        "weapons": {}
    }

    weapon_attrs = {}
    current_weapon = None
    current_slot = None

    for line in content:

        # Skip commented lines
        if line.strip().startswith('//'):
            continue

        # Create weapons
        weapon_match = re.search(r'CreateRoboWeapon\(\w+, "([^"]+)", (\d+), (\d+), (\d+), (\d+), \d+\);', line)
        if weapon_match:
            weapon_name = weapon_match.group(1)
            data["weapons"][weapon_name] = {
                "itemindex": weapon_match.group(2),
                "quality": weapon_match.group(3),
                "level": weapon_match.group(4),
                "slot": weapon_match.group(5)
            }
            current_weapon = weapon_name
            current_slot = weapon_match.group(5)
            weapon_attrs[current_weapon] = []

        # Extract the weapon slot
        weapon_slot_match = re.search(r'GetPlayerWeaponSlot\(\w+, (\w+)\);', line)
        if weapon_slot_match:
            weapon_slot_enum = weapon_slot_match.group(1)

            # Ensure the weapon_slot_enum is in our dictionary
            if weapon_slot_enum not in WEAPON_SLOTS:
                print(f"Warning: Unexpected weapon slot '{weapon_slot_enum}' found. Skipping...")
                continue

            current_slot = WEAPON_SLOTS[weapon_slot_enum]

        # Weapon attributes
        attrs_match = re.search(r'TF2Attrib_SetByName\(\w+, "([^"]+)", ([\d.]+)\);', line)
        if attrs_match and current_slot:
            attr_name = attrs_match.group(1)
            attr_val = attrs_match.group(2)
            for weapon, details in data["weapons"].items():
                if details["slot"] == current_slot:
                    if "attributes" not in details:
                        details["attributes"] = {}
                    details["attributes"][attr_name] = attr_val

    return data



def write_cfg_file(filename, data):
    output_dir = "CFG_WEAPON_GROUPING"
    os.makedirs(output_dir, exist_ok=True)  # Ensure the directory exists
    
    new_filename = os.path.join(output_dir, os.path.splitext(filename)[0] + "WEAPONS.cfg")
    
    with open(new_filename, 'w') as output_file:
        output_file.write("\"weapons\"\n{\n")
        for weapon, details in data["weapons"].items():
            output_file.write(f'  "{weapon}"\n  {{\n')
            for key, value in details.items():
                if key != "attributes":
                    output_file.write(f'    "{key}" "{value}"\n')
                else:
                    output_file.write('    "attributes"\n    {\n')
                    for attr_name, attr_val in value.items():
                        output_file.write(f'      "{attr_name}" "{attr_val}"\n')
                    output_file.write('    }\n')
            output_file.write("  }\n")
        output_file.write("}\n")

def get_files_from_directory(prefixes=["free_", "boss_", "paid_"], extension=".sp"):
    # Get all files from the current directory
    all_files = os.listdir()

    # Filter files based on the given prefixes and extension
    filtered_files = [f for f in all_files if any(f.startswith(prefix) for prefix in prefixes) and f.endswith(extension)]
    
    return filtered_files

def check_for_manual_input(filename):
    with open(filename, 'r') as file:
        content = file.readlines()

    for line in content:
        # Skip commented lines
        if line.strip().startswith('//'):
            continue
        
        # Check for the specific while loop pattern
        if "while" in line and "FindEntityByClassname" in line and "tf_wearable" in line:
            return True

    return False

def rename_with_prefix(filename):
    new_filename = "XXX_" + filename
    os.rename(filename, new_filename)
    return new_filename

if __name__ == "__main__":
    files_to_process = get_files_from_directory()
    for filename in files_to_process:
        needs_manual_input = check_for_manual_input(filename)
            
        if needs_manual_input:
            filename = rename_with_prefix(filename)
                
        data = extract_equipment_data(filename)
        write_cfg_file(filename, data)

        