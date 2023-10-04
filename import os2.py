import os

# Directory path
search_directory = 'D:/Github/robogithub'  # <-- Modify this to the path where you want to search

# List of class names
class_names = ["Scout", "Soldier", "Pyro", "DemoMan", "Heavy", "Engineer", "Medic", "Sniper", "Spy"]

# Search specified directory for .sp files
for filename in os.listdir(search_directory):
    if filename.endswith(".sp") and (filename.startswith("boss_") or filename.startswith("free_") or filename.startswith("paid_")):
        with open(os.path.join(search_directory, filename), 'r') as file:
            content = file.read()
        
        # Check for duplicates and replace them
        for class_name in class_names:
            duplicate_str = f"TFClass_{class_name}{class_name}"
            correct_str = f"TFClass_{class_name}"
            content = content.replace(duplicate_str, correct_str)
        
        # Write back the modified content
        with open(os.path.join(search_directory, filename), 'w') as file:
            file.write(content)