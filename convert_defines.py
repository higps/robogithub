import os

# Directory containing your .sp files
source_directory = './'  # Current directory. Modify as needed.

# Output directory for the generated .cfg files
output_directory = os.path.join(source_directory, 'CFG_DEFINES')
if not os.path.exists(output_directory):
    os.makedirs(output_directory)

# Check if the filename matches the criteria
def is_valid_filename(fname):
    return fname.startswith(('free_', 'paid_', 'boss_'))

# Process each file
def process_file(filepath, output_path):
    with open(filepath, 'r', encoding='utf-8') as file:
        content = file.readlines()

    defines = [line for line in content if line.strip().startswith('#define')]

    if defines:
        with open(output_path, 'w', encoding='utf-8') as out_file:
            out_file.writelines(sorted(defines))

# Iterate over all .sp files in the directory
for filename in os.listdir(source_directory):
    if filename.endswith('.sp') and is_valid_filename(filename):
        source_filepath = os.path.join(source_directory, filename)
        output_filepath = os.path.join(output_directory, filename.replace('.sp', '_defines_only.cfg'))
        
        process_file(source_filepath, output_filepath)

print("Processing complete.")
