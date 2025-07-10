import os
import re

def process_cfg_files(directory="."):
    # Match:     "class" "anything"
    class_pattern = re.compile(r'^(\s*)"class"\s*"\S+"')

    for filename in os.listdir(directory):
        if filename.lower().endswith(".cfg") and "free" in filename.lower():
            filepath = os.path.join(directory, filename)
            print(f"🔍 Checking: {filename}")
            with open(filepath, "r", encoding="utf-8") as file:
                lines = file.readlines()

            new_lines = []
            modified = False

            for line in lines:
                new_lines.append(line)
                match = class_pattern.match(line)
                if match:
                    indent = match.group(1)
                    insert_line = f'{indent}"rc_on_death" "10"\n'
                    new_lines.append(insert_line)
                    print(f"   ➕ Inserting after 'class': {insert_line.strip()}")
                    modified = True

            if modified:
                with open(filepath, "w", encoding="utf-8") as file:
                    file.writelines(new_lines)
                print(f"✅ Modified: {filename}")
            else:
                print(f"⚠️  No 'class' matches in: {filename}")

# Run in the current directory
process_cfg_files()
