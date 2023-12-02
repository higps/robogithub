import os

def replace_rage_giving_scale(file_path, new_value):
    with open(file_path, 'r') as file:
        lines = file.readlines()

    with open(file_path, 'w') as file:
        for line in lines:
            if '"rage giving scale"' in line:
                # Replace the current float value with the new user input value
                line_parts = line.split('"')
                current_value = line_parts[3]
                line = line.replace(f'"{current_value}"', f'"{new_value}"')

            file.write(line)

def process_cfg_files(directory, new_value):
    for filename in os.listdir(directory):
        if filename.endswith(".cfg"):
            file_path = os.path.join(directory, filename)
            replace_rage_giving_scale(file_path, new_value)
            print(f"Processed: {file_path}")

if __name__ == "__main__":
    directory = input("Enter the directory path: ")
    
    try:
        new_value = float(input("Enter the new value for 'rage giving scale': "))
    except ValueError:
        print("Invalid input. Please enter a valid float.")
        exit()

    process_cfg_files(directory, new_value)
    print("Replacement complete.")
