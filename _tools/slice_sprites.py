"""Slice sprite sheets into individual alpha-cropped PNG sprites.

Each sheet has objects laid out on a uniform grid with transparent padding.
We cut each grid cell, then crop to the alpha bounding box so every exported
sprite is tight and centered. Output goes to assets/sprites/<name>/<index>.png.
"""
import os
from PIL import Image

SRC = r"d:\flutter_proj\Prism_Pegway\assets"
OUT = r"d:\flutter_proj\Prism_Pegway\assets\sprites"

# (filename, out_folder, rows, cols)
SHEETS = [
    ("pegs_asset.webp", "pegs", 2, 6),
    ("main_spheres_skins_asset.webp", "skins", 2, 4),
    ("Collectible_Energy_Crystals_asset.webp", "crystals", 3, 5),
    ("Crystal_Prisms_asset.webp", "prisms", 2, 6),
    ("Boost_Pads_asset.webp", "boosters", 2, 5),
    ("Springs_asset.webp", "springs", 2, 4),
    ("Magnetic_Rings_asset.webp", "magnets", 2, 4),
    ("Teleport_Portals_asset.webp", "teleporters", 2, 4),
    ("Decorative_Floor_Markers_StartFinish_Elements_asset.webp", "markers", 2, 5),
]


def alpha_crop(cell, pad_ratio=0.02):
    """Crop to alpha bbox with a tiny transparent margin, keep square-ish."""
    if cell.mode != "RGBA":
        cell = cell.convert("RGBA")
    alpha = cell.split()[-1]
    bbox = alpha.getbbox()
    if bbox is None:
        return cell
    cropped = cell.crop(bbox)
    # add small symmetric padding so glow isn't clipped
    w, h = cropped.size
    pad = int(max(w, h) * pad_ratio)
    padded = Image.new("RGBA", (w + pad * 2, h + pad * 2), (0, 0, 0, 0))
    padded.paste(cropped, (pad, pad))
    return padded


def main():
    for fname, folder, rows, cols in SHEETS:
        path = os.path.join(SRC, fname)
        if not os.path.exists(path):
            print(f"MISSING {path}")
            continue
        img = Image.open(path).convert("RGBA")
        W, H = img.size
        cw, ch = W / cols, H / rows
        dst = os.path.join(OUT, folder)
        os.makedirs(dst, exist_ok=True)
        idx = 0
        for r in range(rows):
            for c in range(cols):
                box = (round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))
                cell = img.crop(box)
                sprite = alpha_crop(cell)
                out_path = os.path.join(dst, f"{idx}.png")
                sprite.save(out_path)
                idx += 1
        print(f"{folder}: exported {idx} sprites")


if __name__ == "__main__":
    main()
