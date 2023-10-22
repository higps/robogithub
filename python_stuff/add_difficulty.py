import os

def find_difficulty_in_sp(sp_path):
    robot_difficulties = {
        "ROBOT_DIFFICULTY_EASY": "1",
        "ROBOT_DIFFICULTY_MEDIUM": "2",
        "ROBOT_DIFFICULTY_HARD": "3",
    }

    with open(sp_path, 'r') as file:
        content = file.read()
        for key, value in robot_difficulties.items():
            if key in content:
                return value
    return None

def append_difficulty_to_cfg(cfg_path, difficulty_value):
    with open(cfg_path, 'r') as file:
        lines = file.readlines()
    for i, line in enumerate(lines):
        if '"health"' in line:
            lines.insert(i + 1, f'\t"difficulty" "{difficulty_value}"\n')
            break
    with open(cfg_path, 'w') as file:
        file.writelines(lines)

def main():
    cfg_path = input("Please input the path to the folder containing .cfg files: ")
    sp_path = input("Please input the path to the folder containing .sp files: ")

    for root, dirs, files in os.walk(cfg_path):
        for file in files:
            if file.endswith(".cfg"):
                file_path = os.path.join(root, file)
                with open(file_path, 'r') as f:
                    content = f.read()
                    if '"difficulty"' not in content or (('"difficulty" "1"' not in content) and ('"difficulty" "2"' not in content) and ('"difficulty" "3"' not in content)):
                        sp_file_path = os.path.join(sp_path, os.path.splitext(file)[0] + ".sp")
                        if (sp_file_path.startswith(os.path.join(sp_path, "free_")) or sp_file_path.startswith(os.path.join(sp_path, "paid_")) or sp_file_path.startswith(os.path.join(sp_path, "boss_"))) and os.path.exists(sp_file_path):
                            difficulty_value = find_difficulty_in_sp(sp_file_path)
                            if difficulty_value:
                                append_difficulty_to_cfg(file_path, difficulty_value)

if __name__ == '__main__':
    main()
