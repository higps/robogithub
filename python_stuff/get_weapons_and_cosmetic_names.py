import os
import re

def process_files(directory):
    for filename in os.listdir(directory):
        if filename.endswith(".sp") and (filename.startswith("free_") or filename.startswith("paid_") or filename.startswith("boss_")):
            weapon_data, cosmetics_data, team_paint = extract_weapon_and_hat_data(os.path.join(directory, filename))
            
            # Determine directory based on TeamPaint
            output_dir = "CFG_CREATED_WEAPONS_AND_HATS"
            if team_paint:
                output_dir = os.path.join(output_dir, "TEAMPAINT_NEED_FIX")
            
            # Ensure directory exists
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)

            with open(os.path.join(output_dir, filename.replace('.sp', '_weapons_and_hats.cfg')), 'w') as f:
                for weapon, attributes in weapon_data.items():
                    f.write('"{}"\n'.format(weapon))
                    f.write('{\n')
                    for key, value in attributes.items():
                        f.write('  "{}" "{}"\n'.format(key, value))
                    f.write('}\n\n')

                if cosmetics_data:
                    f.write('"cosmetics"\n')
                    f.write('{\n')
                    for cosmetic, attributes in cosmetics_data.items():
                        f.write('  "{}"\n'.format(cosmetic))
                        f.write('  {\n')
                        for key, value in attributes.items():
                            f.write('    "{}" "{}"\n'.format(key, value))
                        f.write('  }\n')
                    f.write('}\n')

def extract_weapon_and_hat_data(filename):
    with open(filename, 'r') as file:
        # Ignoring commented lines
        lines = file.readlines()
        content = "".join([line for line in lines if not line.strip().startswith("//")])
    
    weapon_data = {}
    cosmetics_data = {}
    team_paint = False

    # Extracting weapon details
    weapon_blocks = re.findall(r'CreateRoboWeapon\(\w+, "([^"]+)", (\d+), (\d+), (\d+), (\d+), (\d+)\);', content)
    for weapon, itemindex, quality, level, slot, paint in weapon_blocks:
        weapon_data[weapon] = {
            "itemindex": itemindex,
            "quality": quality,
            "level": level,
            "slot": slot,
            "paint": paint
        }

    # Extracting cosmetics details
    define_blocks = re.findall(r'#define (\w+) (\d+)', content)
    define_dict = {k: v for k, v in define_blocks}
    
    cosmetic_blocks = re.findall(r'CreateRoboHat\(\w+, (\w+), (\d+), (\d+), ([\w.]+), ([\d.-]+), ([\d.-]+)\);', content)
    for itemname, level, quality, paint, scale, style in cosmetic_blocks:
        cosmetic_name = itemname
        itemindex = define_dict.get(itemname, itemname)
        if not paint.replace('.', '', 1).isdigit():
            team_paint = True
        
        cosmetics_data[cosmetic_name] = {
            "itemindex": itemindex,
            "paint": paint,
            "style": style,
            "scale": scale
        }

    return weapon_data, cosmetics_data, team_paint

if __name__ == '__main__':
    directory_path = input("Enter the directory path: ")
    process_files(directory_path)
