#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required. Install it with: pip install pillow"
    ) from exc


def sanitize_name(name: str) -> str:
    cleaned = name.strip().lower().replace(" ", "_")
    cleaned = re.sub(r"_+", "_", cleaned)
    return cleaned.strip("_")


def load_names(csv_path: Path) -> list[str]:
    names: list[str] = []
    with csv_path.open("r", newline="", encoding="utf-8") as fh:
        reader = csv.reader(fh)
        for row in reader:
            for cell in row:
                value = sanitize_name(cell)
                if value:
                    names.append(value)
    return names


def unique_name(base: str, used: set[str]) -> str:
    if base not in used:
        used.add(base)
        return base

    counter = 2
    while True:
        candidate = f"{base}_{counter}"
        if candidate not in used:
            used.add(candidate)
            return candidate
        counter += 1


def convert_images(csv_path: Path, raw_dir: Path) -> None:
    names = load_names(csv_path)
    jpg_files = sorted(raw_dir.glob("*.jpg"), key=lambda p: p.name)

    if not jpg_files:
        raise SystemExit(f"No .jpg files found in: {raw_dir}")
    if len(names) < len(jpg_files):
        raise SystemExit(
            f"Not enough names in CSV ({len(names)}) for JPG files ({len(jpg_files)})."
        )

    output_dir = raw_dir / "output"
    output_dir.mkdir(parents=True, exist_ok=True)

    used_names: set[str] = set()
    for idx, jpg_path in enumerate(jpg_files):
        target_stem = unique_name(names[idx], used_names)
        target_path = output_dir / f"{target_stem}.webp"

        with Image.open(jpg_path) as image:
            image.save(target_path, format="WEBP")

        print(f"{jpg_path.name} -> {target_path.name}")

    print(f"\nDone. Wrote {len(jpg_files)} files to: {output_dir}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Rename JPGs by CSV names and convert them to WEBP in raw/output."
    )
    parser.add_argument(
        "--csv",
        default="robot_names.csv",
        help="Path to CSV file with names in order (default: robot_names.csv)",
    )
    parser.add_argument(
        "--raw-dir",
        default=r"D:\HiGPS\Manned Machines\robot images\raw",
        help="Path to folder containing JPG files.",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    csv_path = Path(args.csv).expanduser().resolve()
    raw_dir = Path(args.raw_dir).expanduser().resolve()

    if not csv_path.exists():
        raise SystemExit(f"CSV file not found: {csv_path}")
    if not raw_dir.exists() or not raw_dir.is_dir():
        raise SystemExit(f"Raw directory not found: {raw_dir}")

    convert_images(csv_path, raw_dir)


if __name__ == "__main__":
    main()