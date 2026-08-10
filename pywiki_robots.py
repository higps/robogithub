import pywikibot
import json
import subprocess

IMAGE_BASE_PATH = "https://www.bmod.tf/assets/images/mm/cropped/"


def robot_name_to_image_filename(robot_name):
    return robot_name.lower().replace(" ", "_") + ".webp"


def robot_name_to_image_url(robot_name, image_base_path=IMAGE_BASE_PATH):
    return f"{image_base_path.rstrip('/')}/{robot_name_to_image_filename(robot_name)}"


def build_wiki_image_markup(robot_name, image_base_path=IMAGE_BASE_PATH):
    """
    Build external image markup for MediaWiki. If external image embedding is
    disabled in the wiki config, this still renders as a clickable link.
    """
    image_url = robot_name_to_image_url(robot_name, image_base_path)
    return f"{image_url}\n''Image source: [{image_url} {robot_name}]''"


def format_attributes(details, robot_name, image_base_path=IMAGE_BASE_PATH, include_wiki_image=True):
    """
    Convert attributes dictionary to wiki text format, ensuring compatibility
    with varied nested structures within weapon details and player attributes,
    including separate handling for custom attributes and Warpaint Id.
    """
    wiki_text = "== Description ==\n"
    if include_wiki_image:
        wiki_text += build_wiki_image_markup(robot_name, image_base_path=image_base_path) + "\n"
    contents = ["* [[#Description|1 Description]]"]

    # Handling Description
    for key, value in details.items():
        if key not in ["Player Attributes", "Weapons"]:
            wiki_text += f"* '''{key}''': {value}\n"

    # Player Attributes with handling for Custom Attributes Player
    if "Player Attributes" in details:
        contents.append("* [[#Player Attributes|2 Player Attributes]]")
        wiki_text += "\n== Player Attributes ==\n{| class=\"wikitable\"\n! Attribute !! Value\n"
        for attr, val in details["Player Attributes"].items():
            if attr != "Custom Attributes Player":
                wiki_text += f"|-\n| {attr} || {val}\n"
        wiki_text += "|}\n"

        # Custom Attributes Player
        if "Custom Attributes Player" in details["Player Attributes"]:
            wiki_text += "'''Custom Attributes Player'''\n{| class=\"wikitable\"\n! Attribute !! Value\n"
            for custom_attr, custom_val in details["Player Attributes"]["Custom Attributes Player"].items():
                wiki_text += f"|-\n| {custom_attr} || {custom_val}\n"
            wiki_text += "|}\n"

    # Weapons and their specific attributes handling
    if "Weapons" in details:
        contents.append("* [[#Weapons|3 Weapons]]")
        weapon_section_number = 1
        for weapon_name, weapon_info in details["Weapons"].items():
            contents.append(f"** [[#{weapon_name}|3.{weapon_section_number} {weapon_name}]]")
            wiki_text += f"\n=== {weapon_name} ===\n"

            # Standard Attributes
            if "Attributes" in weapon_info:
                wiki_text += "{| class=\"wikitable\"\n! Attribute !! Value\n"
                for attr, val in weapon_info["Attributes"].items():
                    wiki_text += f"|-\n| {attr} || {val}\n"
                wiki_text += "|}\n"
            
            # Custom Attributes Weapon
            if "Custom Attributes Weapon" in weapon_info:
                wiki_text += "'''Custom Attributes Weapon'''\n{| class=\"wikitable\"\n! Attribute !! Value\n"
                for custom_attr, custom_val in weapon_info["Custom Attributes Weapon"].items():
                    wiki_text += f"|-\n| {custom_attr} || {custom_val}\n"
                wiki_text += "|}\n"

            # Warpaint Id
            if "Warpaint Id" in weapon_info:
                wiki_text += f"'''Warpaint Id:''' {weapon_info['Warpaint Id']}\n"
            
            weapon_section_number += 1

    # Prepend Contents
    contents_section = "= Contents =\n" + "\n".join(contents) + "\n\n"
    wiki_text = contents_section + wiki_text

    return wiki_text

def create_individual_robot_pages(site, robot_details):
    """
    Updated to include links to collective pages on each individual robot's page.
    """
    for robot_name, details in robot_details.items():
        page = pywikibot.Page(site, robot_name)
        wiki_content = format_attributes(details, robot_name, include_wiki_image=True)
        wiki_content += "\n\nSee also:\n"
        wiki_content += f"* [[Robot Overview by Class|Robots in Class {details['Class']}]]\n"
        wiki_content += f"* [[Robot Overview by Subclass|Robots in Subclass {details['Subclass']}]]\n"
        wiki_content += f"* [[Robot Overview by Role|Robots with Role {details['Role']}]]\n"
        page.text = wiki_content
        page.save(summary=f'Updating robot details for {robot_name}')


def create_collected_page(site, robot_details):
    """
    Create the main overview page listing all robots and linking to detailed 
    collected pages by Class, Subclass, and Role.
    """
    # Link to grouped pages at the top
    main_page_content = "== Robot Overview ==\n"
    main_page_content += "See robots grouped by:\n"
    main_page_content += "* [[Robot Overview by Class]]\n"
    main_page_content += "* [[Robot Overview by Subclass]]\n"
    main_page_content += "* [[Robot Overview by Role]]\n\n"
    
    # Sort robots for the main list
    sorted_robots = sorted(robot_details.items(), key=lambda x: (x[1]['Role'], x[1]['Subclass'], x[1]['Class'], x[1]['Name']))
    
    current_role, current_subclass, current_class = None, None, None

    for robot_name, details in sorted_robots:
        role = details['Role']
        subclass = details['Subclass']
        robot_class = details['Class']
        
        # Check for new role and subclass to start new sections
        if current_role != role or current_subclass != subclass:
            if current_role is not None:  # Add a newline for spacing between sections
                main_page_content += "\n"
            main_page_content += f"=== {role} {subclass} ===\n"
            current_role, current_subclass, current_class = role, subclass, None
        
        # Check and write new class within the same role and subclass
        if current_class != robot_class:
            if current_class is not None:  # Add a newline for spacing within the section
                main_page_content += "\n"
            main_page_content += f"==== {robot_class} ====\n"
            current_class = robot_class
        
        # Write robot entry
        main_page_content += f"* [[{robot_name}]]: {details.get('Short Description', 'No description available.')}\n"

    # Create or update the main page on the wiki
    main_page = pywikibot.Page(site, "Robot Overview")
    main_page.put(main_page_content, summary='Updated main robot overview page.')

def create_grouped_page(site, robot_details, grouping_key, page_title):
    """
    Generic function to create collected pages grouped by a specific key.
    """
    sorted_robots = sorted(robot_details.items(), key=lambda x: (x[1][grouping_key], x[1]['Name']))
    page_content = f"== {page_title} ==\n\n"
    current_group = None

    for robot_name, details in sorted_robots:
        group = details[grouping_key]
        
        if current_group != group:
            if current_group is not None:
                page_content += "\n"
            page_content += f"=== {group} ===\n"
            current_group = group
        
        page_content += f"* [[{robot_name}]]: {details.get('Short Description', 'No description')}\n"

    page = pywikibot.Page(site, page_title)
    page.put(page_content, summary=f'Updating {page_title.lower()} page')


def load_data_and_create_pages(json_path):
    """
    Load JSON data and create/update wiki pages accordingly.
    """
    with open(json_path, 'r') as file:
        robot_details = json.load(file)

    # site = pywikibot.Site('en', 'localwiki')
    site = pywikibot.Site('en', 'prodwiki')

    # Create individual pages for each robot
    create_individual_robot_pages(site, robot_details)
    create_grouped_page(site, robot_details, 'Class', 'Robot Overview by Class')
    create_grouped_page(site, robot_details, 'Subclass', 'Robot Overview by Subclass')
    create_grouped_page(site, robot_details, 'Role', 'Robot Overview by Role')
    # Create a collected page with links to individual robots
    create_collected_page(site, robot_details)

# Define the path to your JSON file
json_path = 'D:\Github\Bmod-ETL-Pipeline\silver\cfg\Robot Dict.json'
prev_data_path = 'previous_data.json'
# Load data from JSON and create/update wiki pages


# Function to save data to a file
def save_data(data, file_path):
    with open(file_path, 'w') as file:
        json.dump(data, file)

# Function to load data from a file
def load_data(file_path):
    with open(file_path, 'r') as file:
        return json.load(file)

def run_etl_pipeline(json_path, prev_data_path):
    # Load previous data
    try:
        prev_data = load_data(prev_data_path)
    except FileNotFoundError:
        prev_data = {}  # Initialize with empty dictionary if file doesn't exist

    # Load current data
    with open(json_path, 'r') as file:
        current_data = json.load(file)

    # Compare current data with previous data
    if current_data != prev_data:
        # Data has changed, proceed with updating wiki pages

        # Perform ETL operations and update wiki pages

        # Save current data as previous data for next run
        save_data(current_data, prev_data_path)
    else:
        print("No changes detected. Skipping update.")

# Define paths
json_path = 'D:\Github\Bmod-ETL-Pipeline\silver\cfg\Robot Dict.json'
prev_data_path = 'previous_data.json'

# # Run ETL pipeline
# run_etl_pipeline(json_path, prev_data_path)



def run_pwb_login():
    try:
        # Assuming 'pwb.py' is in your PATH, otherwise provide the full path
        result = subprocess.run(['pwb', 'login'], check=True, text=True, capture_output=True)
        print("Login successful.")
        load_data_and_create_pages(json_path)
    except subprocess.CalledProcessError as e:
        print(f"Login failed: {e}")

if __name__ == "__main__":
    run_pwb_login()

