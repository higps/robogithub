import os
import re

def process_cfg_files(directory="."):
    rc_cost_pattern = re.compile(r'^(\s*)"rc_cost"\s*".*?"')

    for filename in os.listdir(directory):
        if filename.lower().endswith(".cfg"):
            filepath = os.path.join(directory, filename)
            with open(filepath, "r", encoding="utf-8") as file:
                lines = file.readlines()

            new_lines = []
            for line in lines:
                new_lines.append(line)
                if rc_cost_pattern.match(line):
                    indent = rc_cost_pattern.match(line).group(1)
                    new_lines.append(f'{indent}"rc_on_death" "0"\n')

            with open(filepath, "w", encoding="utf-8") as file:
                file.writelines(new_lines)

            print(f"Processed: {filename}")

# Run the script in the current directory
process_cfg_files()
