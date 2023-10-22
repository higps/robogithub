import os

def insert_health_attribute(file_path, output_directory, cfg_output_directory):
    # Prepare path for the lookup in CFG_OUTPUT folder
    cfg_output_file_path = os.path.join(cfg_output_directory, os.path.basename(file_path))
    
    if not os.path.exists(cfg_output_file_path):
        print(f"Lookup file {cfg_output_file_path} not found. Skipping...")
        return

    # Read the content from the original CFG file
    with open(file_path, 'r') as file:
        content = file.read()
    
    # If "health" is missing, fetch its value from CFG_OUTPUT
    if '"health" ' not in content:
        with open(cfg_output_file_path, 'r') as lookup_file:
            lookup_content = lookup_file.read()
                
            # Extracting health value from CFG_OUTPUT file
            health_pos = lookup_content.find('"health" ')
            if health_pos != -1:
                health_line_end = lookup_content.find('\n', health_pos)
                health_value = lookup_content[health_pos: health_line_end].strip()
                
                # Inserting the health value after "tips"
                tips_end = content.find('"tips"') + len('"tips"')
                next_line = content.find('\n', tips_end)
                content = content[:next_line + 1] + health_value + "\n" + content[next_line + 1:]
                
    # Saving the new content to the FIXED_HEALTH directory
    output_path = os.path.join(output_directory, os.path.basename(file_path))
    with open(output_path, 'w') as file:
        file.write(content)

def main():
    directory = input("Enter the directory of the .CFG files: ")

    # Path to the CFG_OUTPUT directory
    cfg_output_directory = os.path.join(directory, 'CFG_OUTPUT')
    
    if not os.path.exists(cfg_output_directory):
        print(f"CFG_OUTPUT directory {cfg_output_directory} not found. Exiting...")
        return

    # Create the "FIXED_HEALTH" directory if it doesn't exist
    output_directory = os.path.join(directory, 'FIXED_HEALTH')
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    for file_name in os.listdir(directory):
        if file_name.endswith(".cfg"):
            file_path = os.path.join(directory, file_name)
            insert_health_attribute(file_path, output_directory, cfg_output_directory)

if __name__ == "__main__":
    main()
