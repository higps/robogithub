#!/usr/bin/env python3
"""
Extract robot names from robot_selection.json and write them to a CSV file.

Output format is a single CSV row with all names quoted, for example:
"Big Joey","HiGPS","Other Robot"
"""

import argparse
import csv
import json
from pathlib import Path
from typing import Any, List


def collect_robot_names(node: Any) -> List[str]:
    """Recursively collect names from objects inside any 'robots' list."""
    names: List[str] = []

    if isinstance(node, dict):
        robots = node.get("robots")
        if isinstance(robots, list):
            for robot in robots:
                if isinstance(robot, dict):
                    name = robot.get("name")
                    if isinstance(name, str):
                        names.append(name)

        for value in node.values():
            names.extend(collect_robot_names(value))

    elif isinstance(node, list):
        for item in node:
            names.extend(collect_robot_names(item))

    return names


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Extract robot names from a JSON file and write them as quoted CSV."
    )
    parser.add_argument(
        "input_json",
        nargs="?",
        default="robot_selection.json",
        help="Path to input JSON file (default: robot_selection.json)",
    )
    parser.add_argument(
        "output_csv",
        nargs="?",
        default="robot_names.csv",
        help="Path to output CSV file (default: robot_names.csv)",
    )
    args = parser.parse_args()

    input_path = Path(args.input_json)
    output_path = Path(args.output_csv)

    with input_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    names = collect_robot_names(data)

    with output_path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.writer(f, quoting=csv.QUOTE_ALL)
        writer.writerow(names)

    print(f"Extracted {len(names)} robot names to {output_path}")


if __name__ == "__main__":
    main()
