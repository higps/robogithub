import os

def read_file(file_path):
    with open(file_path, 'r') as file:
        return file.read()

def write_file(file_path, content):
    with open(file_path, 'w') as file:
        file.write(content)

def parse_cfg(cfg_content):
    lines = cfg_content.splitlines()
    parsed_data = {}
    key_stack = []
    for line in lines:
        line = line.strip()
        split_line = line.split('"')
        if len(split_line) > 3:  # Ensure there are enough segments to extract key and value
            key, value = split_line[1], split_line[3]
            if key_stack:
                current_dict = parsed_data
                for k in key_stack:
                    current_dict = current_dict[k]
                current_dict[key] = value
            else:
                parsed_data[key] = value
        elif "{" in line:
            key = split_line[1]
            if key_stack:
                current_dict = parsed_data
                for k in key_stack:
                    current_dict = current_dict[k]
                current_dict[key] = {}
            else:
                parsed_data[key] = {}
            key_stack.append(key)
        elif "}" in line:
            key_stack.pop()
    return parsed_data



def reorder_cfg(parsed_data):
    order = ["name", "role", "class", "subclass", "shortdescription", "deathtip", "difficulty", "tips", "model",
             "health", "health_bonus_per_player", "boss_cost", "rc_cost", "scale", "sounds", "player_attributes",
             "player_conditions", "remove_weapon_slots", "weapons", "cosmetics"]
    reordered_data = {}
    for key in order:
        if key in parsed_data:
            reordered_data[key] = parsed_data[key]
    return reordered_data

def write_reordered_cfg(parsed_data):
    lines = []
    for key, value in parsed_data.items():
        lines.append(f'"{key}"')
        if isinstance(value, dict):
            lines.append("{")
            for subkey, subvalue in value.items():
                lines.append(f'\t"{subkey}" "{subvalue}"')
            lines.append("}")
        else:
            lines.append(f'"{value}"')
    return "\n".join(lines)

def main():
    # User input
    root_dir = input("Enter the directory: ")

    for subdir, _, files in os.walk(root_dir):
        for file in files:
            file_path = os.path.join(subdir, file)
            cfg_content = read_file(file_path)
            parsed_data = parse_cfg(cfg_content)
            reordered_data = reorder_cfg(parsed_data)
            reordered_cfg_content = write_reordered_cfg(reordered_data)

            # Create 'REORDERED' directory if not exists
            reordered_dir = os.path.join(root_dir, "REORDERED")
            if not os.path.exists(reordered_dir):
                os.makedirs(reordered_dir)

            write_file(os.path.join(reordered_dir, file), reordered_cfg_content)
            print(f"Processed file: {file_path}")

if __name__ == "__main__":
    main()
