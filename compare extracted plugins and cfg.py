import os

def extract_pairs_from_lines(lines, index=0):
    pairs = {}
    while index < len(lines):
        line = lines[index].strip()
        if "{" in line:
            index, nested_pairs = extract_pairs_from_lines(lines, index + 1)
            pairs[line.split('{')[0].strip('" ')] = nested_pairs
        elif "}" in line:
            return index, pairs
        else:
            parts = line.split(' ')
            if len(parts) == 2:
                key, value = parts[0].strip('"'), parts[1].strip('"')
                pairs[key] = value
        index += 1
    return index, pairs

def extract_pairs_from_file(filename):
    with open(filename, 'r') as f:
        lines = f.readlines()
        _, pairs = extract_pairs_from_lines(lines)
    return pairs

def compare_dicts(dict1, dict2):
    for key, value in dict1.items():
        if key not in dict2:
            return False, f'Missing key: {key}'
        elif isinstance(value, dict):
            is_identical, message = compare_dicts(value, dict2[key])
            if not is_identical:
                return False, message
        elif value != dict2[key]:
            return False, f'Mismatch in key {key}: {value} != {dict2[key]}'
    return True, ''

def main():
    print("Enter the directory path where the first set of .cfg files are located:")
    first_directory = input().strip()
    print("Enter the directory path where the second set of .cfg files are located:")
    second_directory = input().strip()

    identical_files = []
    differing_files = []

    for subdir1, _, files1 in os.walk(first_directory):
        for file1 in files1:
            if file1.endswith('.cfg'):
                file_path1 = os.path.join(subdir1, file1)
                extracted_pairs = extract_pairs_from_file(file_path1)

                file_path2 = os.path.join(second_directory, file1)
                if os.path.exists(file_path2):
                    other_pairs = extract_pairs_from_file(file_path2)
                    is_identical, message = compare_dicts(extracted_pairs, other_pairs)
                    if is_identical:
                        identical_files.append(file1)
                    else:
                        differing_files.append((file1, message))

    with open('results.txt', 'w') as f:
        f.write("Identical Files:\n")
        for file_name in identical_files:
            f.write(f"{file_name}\n")

        f.write("\nDiffering Files:\n")
        for file_entry in differing_files:
            f.write(f"{file_entry[0]} - {file_entry[1]}\n")

    print("Comparison done. Check 'results.txt' for results.")

if __name__ == "__main__":
    main()
