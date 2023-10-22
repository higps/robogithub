import os
import re

# Paint names mapped to their index values
PAINTS = {
    3100495: "A Color Similar to Slate",
    8208497: "A Deep Commitment to Purple",
    1315860: "A Distinctive Lack of Hue",
    12377523: "A Mann's Mint",
    2960676: "After Eight",
    8289918: "Aged Moustache Grey",
    15132390: "An Extraordinary Abundance of Tinge",
    15185211: "Australium Gold",
    14204632: "Color No. 216-190-216",
    15308410: "Dark Salmon Injustice",
    8421376: "Drably Olive",
    7511618: "Indubitably Green",
    13595446: "Mann Co. Orange",
    10843461: "Muskelmannbraun",
    5322826: "Noble Hatter's Violet",
    12955537: "Peculiarly Drab Tincture",
    16738740: "Pink as Hell",
    6901050: "Radigan Conagher Brown",
    3329330: "The Bitter Taste of Defeat and Lime",
    15787660: "The Color of a Gentlemann's Business Pants",
    8154199: "Ye Olde Rustic Colour",
    4345659: "Zepheniah's Greed"
}

MULTIPLE_PAINTS = {
    "An Air of Debonair": [6637376, 2636109],
    "Balaclavas Are Forever": [3874595, 1581885],
    "Cream Spirit": [12807213, 12091445],
    "Operator's Overalls": [4732984, 3686984],
    "Team Spirit": [12073019, 5801378],
    "The Value of Teamwork": [8400928, 2452877],
    "Waterlogged Lab Coat": [11049612, 8626083]
}
# Create a set of valid paints (strings and indices)
VALID_PAINTS = set(PAINTS.values())

def is_valid_paint(value):
    try:
        # If the value is an index, convert it to int and check its validity
        int_value = int(float(value))
        
        # Accept 0 as a valid value
        if int_value == 0:
            return True
        
        return int_value in PAINTS
    except ValueError:
        # If the value is a string, check its validity
        return value in VALID_PAINTS

def convert_paint_values(text):
    cosmetics_section_match = re.search(r'"cosmetics"\s*{(.+?)}', text, re.DOTALL)
    if not cosmetics_section_match:
        return text
    
    cosmetics_section = cosmetics_section_match.group(1)
    modified_section = cosmetics_section
    
    paint_matches = re.findall(r'"paint" "(.*?)"', cosmetics_section)
    for match in paint_matches:
        if not is_valid_paint(match):
            # This file has an invalid paint value
            return None
        # If it's a numeric value, replace with its string counterpart
        try:
            int_value = int(float(match))
            if int_value in PAINTS:
                modified_section = modified_section.replace(f'"paint" "{match}"', f'"paint" "{PAINTS[int_value]}"')
        except ValueError:
            pass
    
    # Replace the cosmetics section in the original text with the modified section
    return text.replace(cosmetics_section, modified_section)

def is_valid_paint(value):
    try:
        # If the value is an index, convert it to int and check its validity
        int_value = int(float(value))
        
        # Accept 0 as a valid value
        if int_value == 0:
            return True
        
        return int_value in PAINTS
    except ValueError:
        # If the value is a string, check its validity
        return value in VALID_PAINTS

def process_file(filepath):
    with open(filepath, 'r', encoding="utf-8") as f:
        content = f.read()

    paint_values = set(re.findall(r'"paint" "(.*?)"', content))

    for value in paint_values:
        if not is_valid_paint(value):
            exception_folder = os.path.join(os.path.dirname(filepath), "exceptions")
            if not os.path.exists(exception_folder):
                os.mkdir(exception_folder)
            os.rename(filepath, os.path.join(exception_folder, os.path.basename(filepath)))
            return

    new_content = convert_paint_values(content)

    with open(filepath, 'w', encoding="utf-8") as f:
        f.write(new_content)

def main():
    directory = input("Please enter the directory path: ")

    for dirpath, _, filenames in os.walk(directory):
        for filename in filenames:
            if filename.endswith('.cfg'):
                process_file(os.path.join(dirpath, filename))

if __name__ == "__main__":
    main()