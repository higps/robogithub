#!/usr/bin/env python3
from __future__ import annotations

import argparse
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:
    raise SystemExit(
        "Pillow is required. Install it with: pip install pillow"
    ) from exc


def crop_to_visible_content(image: Image.Image, padding: int = 0) -> Image.Image | None:
    rgba = image.convert("RGBA")
    alpha = rgba.getchannel("A")
    bbox = alpha.getbbox()

    if bbox is None:
        return None

    left, upper, right, lower = bbox
    if padding > 0:
        width, height = rgba.size
        left = max(0, left - padding)
        upper = max(0, upper - padding)
        right = min(width, right + padding)
        lower = min(height, lower + padding)

    return rgba.crop((left, upper, right, lower))


def process_images(input_dir: Path, output_dir: Path, padding: int) -> None:
    webp_files = sorted(input_dir.glob("*.webp"), key=lambda p: p.name)
    if not webp_files:
        raise SystemExit(f"No .webp files found in: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    written = 0
    skipped = 0
    for src in webp_files:
        with Image.open(src) as image:
            cropped = crop_to_visible_content(image, padding=padding)

        if cropped is None:
            skipped += 1
            print(f"Skipped fully transparent image: {src.name}")
            continue

        out_path = output_dir / src.name
        cropped.save(out_path, format="WEBP", lossless=True)
        written += 1
        print(f"{src.name} -> {out_path.name} ({cropped.width}x{cropped.height})")

    print(
        f"\nDone. Wrote {written} cropped files to: {output_dir}"
        + (f" | Skipped {skipped} fully transparent files" if skipped else "")
    )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Crop WEBP images to the minimum rectangle containing non-transparent pixels."
    )
    parser.add_argument(
        "--input-dir",
        default=r"D:\HiGPS\Manned Machines\robot images\raw\chroma keyed",
        help="Folder containing chroma-keyed WEBP files.",
    )
    parser.add_argument(
        "--output-dir",
        default=r"D:\HiGPS\Manned Machines\robot images\raw\cropped",
        help="Destination folder for cropped WEBP files.",
    )
    parser.add_argument(
        "--padding",
        type=int,
        default=0,
        help="Optional transparent padding (in pixels) to keep around content.",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    if args.padding < 0:
        raise SystemExit("--padding must be >= 0")

    input_dir = Path(args.input_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()

    if not input_dir.exists() or not input_dir.is_dir():
        raise SystemExit(f"Input folder not found: {input_dir}")

    process_images(input_dir=input_dir, output_dir=output_dir, padding=args.padding)


if __name__ == "__main__":
    main()