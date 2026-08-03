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


# Tweak these defaults, or override them with CLI flags.
DEFAULTS = {
    "input_dir": r"D:\HiGPS\Manned Machines\robot images\raw\output",
    "output_dir": r"D:\HiGPS\Manned Machines\robot images\raw\chroma keyed",
    "min_green": 120,
    "green_over_red": 60,
    "green_over_blue": 60,
    "soften_edges": False,
    "edge_soften_min_bias": 18,
    "edge_soften_scale": 2,
    "edge_soften_max_reduction": 48,
}


def is_green_screen_pixel(
    r: int,
    g: int,
    b: int,
    min_green: int,
    green_over_red: int,
    green_over_blue: int,
) -> bool:
    return (
        g >= min_green
        and (g - r) >= green_over_red
        and (g - b) >= green_over_blue
    )


def chroma_key_image(
    input_path: Path,
    output_path: Path,
    min_green: int,
    green_over_red: int,
    green_over_blue: int,
    soften_edges: bool,
    edge_soften_min_bias: int,
    edge_soften_scale: int,
    edge_soften_max_reduction: int,
) -> None:
    with Image.open(input_path).convert("RGBA") as image:
        pixels = image.load()
        width, height = image.size

        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[x, y]
                if is_green_screen_pixel(
                    r,
                    g,
                    b,
                    min_green=min_green,
                    green_over_red=green_over_red,
                    green_over_blue=green_over_blue,
                ):
                    pixels[x, y] = (r, g, b, 0)
                    continue

                if soften_edges:
                    # Soften only near green spill instead of globally reducing alpha.
                    green_bias = g - max(r, b)
                    if green_bias >= edge_soften_min_bias:
                        alpha_reduce = min(
                            edge_soften_max_reduction,
                            (green_bias - edge_soften_min_bias + 1)
                            * edge_soften_scale,
                        )
                        new_alpha = max(0, a - alpha_reduce)
                        pixels[x, y] = (r, g, b, new_alpha)

        image.save(output_path, format="WEBP", lossless=True)


def run_chroma_key(
    input_dir: Path,
    output_dir: Path,
    min_green: int,
    green_over_red: int,
    green_over_blue: int,
    soften_edges: bool,
    edge_soften_min_bias: int,
    edge_soften_scale: int,
    edge_soften_max_reduction: int,
) -> None:
    webp_files = sorted(input_dir.glob("*.webp"), key=lambda p: p.name)
    if not webp_files:
        raise SystemExit(f"No .webp files found in: {input_dir}")

    output_dir.mkdir(parents=True, exist_ok=True)

    for webp in webp_files:
        out_path = output_dir / webp.name
        chroma_key_image(
            input_path=webp,
            output_path=out_path,
            min_green=min_green,
            green_over_red=green_over_red,
            green_over_blue=green_over_blue,
            soften_edges=soften_edges,
            edge_soften_min_bias=edge_soften_min_bias,
            edge_soften_scale=edge_soften_scale,
            edge_soften_max_reduction=edge_soften_max_reduction,
        )
        print(f"{webp.name} -> {out_path.name}")

    print(f"\nDone. Wrote {len(webp_files)} chroma-keyed files to: {output_dir}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Remove green-screen background from WEBP files and output transparent WEBP copies."
    )
    parser.add_argument(
        "--input-dir",
        default=DEFAULTS["input_dir"],
        help="Folder containing source WEBP files.",
    )
    parser.add_argument(
        "--output-dir",
        default=DEFAULTS["output_dir"],
        help="Destination folder for chroma-keyed WEBP files.",
    )
    parser.add_argument(
        "--min-green",
        type=int,
        default=DEFAULTS["min_green"],
        help="Minimum green value (0-255) for keying.",
    )
    parser.add_argument(
        "--green-over-red",
        type=int,
        default=DEFAULTS["green_over_red"],
        help="Required amount green exceeds red.",
    )
    parser.add_argument(
        "--green-over-blue",
        type=int,
        default=DEFAULTS["green_over_blue"],
        help="Required amount green exceeds blue.",
    )
    parser.add_argument(
        "--soften-edges",
        action="store_true",
        default=DEFAULTS["soften_edges"],
        help="Enable edge softening around green spill.",
    )
    parser.add_argument(
        "--edge-soften-min-bias",
        type=int,
        default=DEFAULTS["edge_soften_min_bias"],
        help="Green bias threshold before softening starts.",
    )
    parser.add_argument(
        "--edge-soften-scale",
        type=int,
        default=DEFAULTS["edge_soften_scale"],
        help="How quickly alpha reduction grows once softening starts.",
    )
    parser.add_argument(
        "--edge-soften-max-reduction",
        type=int,
        default=DEFAULTS["edge_soften_max_reduction"],
        help="Maximum alpha reduction for softened edge pixels.",
    )
    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()

    input_dir = Path(args.input_dir).expanduser().resolve()
    output_dir = Path(args.output_dir).expanduser().resolve()

    if not input_dir.exists() or not input_dir.is_dir():
        raise SystemExit(f"Input folder not found: {input_dir}")

    for value_name, value in (
        ("min-green", args.min_green),
        ("green-over-red", args.green_over_red),
        ("green-over-blue", args.green_over_blue),
        ("edge-soften-min-bias", args.edge_soften_min_bias),
        ("edge-soften-scale", args.edge_soften_scale),
        ("edge-soften-max-reduction", args.edge_soften_max_reduction),
    ):
        if value < 0:
            raise SystemExit(f"--{value_name} must be >= 0")

    run_chroma_key(
        input_dir=input_dir,
        output_dir=output_dir,
        min_green=args.min_green,
        green_over_red=args.green_over_red,
        green_over_blue=args.green_over_blue,
        soften_edges=args.soften_edges,
        edge_soften_min_bias=args.edge_soften_min_bias,
        edge_soften_scale=args.edge_soften_scale,
        edge_soften_max_reduction=args.edge_soften_max_reduction,
    )


if __name__ == "__main__":
    main()