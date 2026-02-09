#!/usr/bin/env python3
"""
iOS App Icon Generator

マスター画像（1024x1024）から全サイズのアプリアイコンを生成し、
Contents.jsonを自動作成します。

Usage:
    python generate_icons.py <master_image.png> <output_dir> [--legacy] [--dark <dark_image.png>] [--tinted <tinted_image.png>]

Options:
    --legacy    レガシー形式（個別サイズファイル）で生成
    --dark      ダークモード用マスター画像
    --tinted    ティンテッド用マスター画像

Requirements:
    pip install Pillow
"""

import argparse
import json
import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is required. Install with: pip install Pillow")
    sys.exit(1)


# iOS icon sizes configuration
ICON_SIZES = {
    "iphone": [
        {"size": 20, "scales": [2, 3]},   # Notification
        {"size": 29, "scales": [2, 3]},   # Settings
        {"size": 40, "scales": [2, 3]},   # Spotlight
        {"size": 60, "scales": [2, 3]},   # App
    ],
    "ipad": [
        {"size": 20, "scales": [1, 2]},   # Notification
        {"size": 29, "scales": [1, 2]},   # Settings
        {"size": 40, "scales": [1, 2]},   # Spotlight
        {"size": 76, "scales": [1, 2]},   # App
        {"size": 83.5, "scales": [2]},    # iPad Pro App
    ],
    "ios-marketing": [
        {"size": 1024, "scales": [1]},    # App Store
    ],
}


def generate_icon(master_image: Image.Image, size: int, output_path: Path) -> None:
    """Generate a resized icon from the master image."""
    resized = master_image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(output_path, "PNG")
    print(f"  Generated: {output_path.name} ({size}x{size})")


def generate_legacy_icons(
    master_path: Path,
    output_dir: Path,
    dark_path: Path | None = None,
    tinted_path: Path | None = None,
) -> dict:
    """Generate all icon sizes in legacy format."""
    master = Image.open(master_path).convert("RGBA")
    dark = Image.open(dark_path).convert("RGBA") if dark_path else None
    tinted = Image.open(tinted_path).convert("RGBA") if tinted_path else None
    
    images = []
    
    for idiom, sizes in ICON_SIZES.items():
        for size_config in sizes:
            size = size_config["size"]
            for scale in size_config["scales"]:
                pixel_size = int(size * scale)
                
                if scale == 1:
                    filename = f"icon-{size}.png"
                else:
                    filename = f"icon-{size}@{scale}x.png"
                
                output_path = output_dir / filename
                generate_icon(master, pixel_size, output_path)
                
                image_entry = {
                    "filename": filename,
                    "idiom": idiom,
                    "scale": f"{scale}x",
                    "size": f"{size}x{size}",
                }
                images.append(image_entry)
                
                # Generate dark variant
                if dark:
                    dark_filename = filename.replace(".png", "-dark.png")
                    generate_icon(dark, pixel_size, output_dir / dark_filename)
                    dark_entry = image_entry.copy()
                    dark_entry["filename"] = dark_filename
                    dark_entry["appearances"] = [
                        {"appearance": "luminosity", "value": "dark"}
                    ]
                    images.append(dark_entry)
                
                # Generate tinted variant
                if tinted:
                    tinted_filename = filename.replace(".png", "-tinted.png")
                    generate_icon(tinted, pixel_size, output_dir / tinted_filename)
                    tinted_entry = image_entry.copy()
                    tinted_entry["filename"] = tinted_filename
                    tinted_entry["appearances"] = [
                        {"appearance": "luminosity", "value": "tinted"}
                    ]
                    images.append(tinted_entry)
    
    return {"images": images, "info": {"author": "xcode", "version": 1}}


def generate_modern_icons(
    master_path: Path,
    output_dir: Path,
    dark_path: Path | None = None,
    tinted_path: Path | None = None,
) -> dict:
    """Generate icons in modern single-asset format (Xcode 14+)."""
    master = Image.open(master_path).convert("RGBA")
    
    images = []
    
    # Main icon
    output_path = output_dir / "AppIcon.png"
    generate_icon(master, 1024, output_path)
    images.append({
        "filename": "AppIcon.png",
        "idiom": "universal",
        "platform": "ios",
        "size": "1024x1024",
    })
    
    # Dark variant
    if dark_path:
        dark = Image.open(dark_path).convert("RGBA")
        dark_output = output_dir / "AppIcon-dark.png"
        generate_icon(dark, 1024, dark_output)
        images.append({
            "appearances": [{"appearance": "luminosity", "value": "dark"}],
            "filename": "AppIcon-dark.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        })
    
    # Tinted variant
    if tinted_path:
        tinted = Image.open(tinted_path).convert("RGBA")
        tinted_output = output_dir / "AppIcon-tinted.png"
        generate_icon(tinted, 1024, tinted_output)
        images.append({
            "appearances": [{"appearance": "luminosity", "value": "tinted"}],
            "filename": "AppIcon-tinted.png",
            "idiom": "universal",
            "platform": "ios",
            "size": "1024x1024",
        })
    
    return {"images": images, "info": {"author": "xcode", "version": 1}}


def main():
    parser = argparse.ArgumentParser(
        description="Generate iOS app icons from a master image"
    )
    parser.add_argument("master", type=Path, help="Path to master image (1024x1024 PNG)")
    parser.add_argument("output", type=Path, help="Output directory for generated icons")
    parser.add_argument("--legacy", action="store_true", help="Generate legacy individual files")
    parser.add_argument("--dark", type=Path, help="Path to dark mode master image")
    parser.add_argument("--tinted", type=Path, help="Path to tinted master image")
    
    args = parser.parse_args()
    
    # Validate master image
    if not args.master.exists():
        print(f"Error: Master image not found: {args.master}")
        sys.exit(1)
    
    master = Image.open(args.master)
    if master.size != (1024, 1024):
        print(f"Warning: Master image is {master.size}, expected (1024, 1024)")
        print("  Continuing anyway, but App Store may reject non-1024x1024 images.")
    
    # Create output directory
    output_dir = args.output / "AppIcon.appiconset"
    output_dir.mkdir(parents=True, exist_ok=True)
    print(f"Output directory: {output_dir}")
    
    # Generate icons
    if args.legacy:
        print("\nGenerating legacy format icons...")
        contents = generate_legacy_icons(args.master, output_dir, args.dark, args.tinted)
    else:
        print("\nGenerating modern format icons...")
        contents = generate_modern_icons(args.master, output_dir, args.dark, args.tinted)
    
    # Write Contents.json
    contents_path = output_dir / "Contents.json"
    with open(contents_path, "w") as f:
        json.dump(contents, f, indent=2)
    print(f"\nGenerated: {contents_path}")
    
    print("\n✅ Icon generation complete!")
    print(f"   Copy {output_dir} to your Xcode project's Assets.xcassets folder")


if __name__ == "__main__":
    main()
