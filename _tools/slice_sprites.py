"""Slice sprite sheets into individual, content-centered PNG sprites.

Each sheet lays objects out in a roughly uniform grid, but the source art is
not pixel-perfectly gridded (balls/icons sit at slightly different offsets
inside their nominal cell, and cell boundaries don't split the sheet into
perfectly even columns/rows either). Dividing the sheet evenly by
rows/cols and then cropping therefore bakes in a per-sprite positional
error, which shows up in-game as icons rendered a few pixels off from the
point they're supposed to be centered on.

Instead we detect each sprite's *real* footprint directly from the alpha
channel via connected-component labeling, crop tightly to that footprint,
and re-paste it dead-center in a square canvas. This guarantees the visual
content's own centroid is exactly in the middle of every exported PNG,
independent of any grid assumptions. Output goes to
assets/sprites/<name>/<index>.png, numbered in reading order (top-to-bottom
rows, left-to-right within a row).
"""
import os
import numpy as np
from PIL import Image
from scipy import ndimage

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


def find_sprites(img, expected_count):
    """Find each sprite's bounding box via connected-component labeling on
    the alpha channel, returning boxes sorted in reading order."""
    alpha = np.array(img.split()[-1])
    mask = alpha > 10
    labeled, n = ndimage.label(mask)
    boxes = []
    for sl in ndimage.find_objects(labeled):
        if sl is None:
            continue
        ys, xs = sl
        boxes.append((xs.start, ys.start, xs.stop, ys.stop))

    # Drop tiny specks (anti-aliasing noise, stray artifacts) relative to
    # the largest component so only genuine sprite blobs remain.
    areas = [(x1 - x0) * (y1 - y0) for x0, y0, x1, y1 in boxes]
    max_area = max(areas) if areas else 0
    boxes = [b for b, a in zip(boxes, areas) if a >= max_area * 0.15]

    if len(boxes) != expected_count:
        print(
            f"  WARNING: expected {expected_count} sprites, found {len(boxes)}"
        )

    return boxes


def order_grid(boxes, rows, cols):
    """Sort boxes into reading order given the nominal row/col count."""
    boxes = sorted(boxes, key=lambda b: (b[1] + b[3]) / 2)
    ordered = []
    n = len(boxes)
    per_row = max(1, round(n / rows)) if rows else cols
    for i in range(0, n, per_row):
        chunk = boxes[i : i + per_row]
        chunk.sort(key=lambda b: (b[0] + b[2]) / 2)
        ordered.extend(chunk)
    return ordered


def crop_centered(img, box, pad_ratio=0.06):
    """Crop to the exact alpha footprint inside box, then re-center it in a
    square canvas so the content's centroid is dead-center in the PNG."""
    x0, y0, x1, y1 = box
    content = img.crop(box)
    bw, bh = content.size
    side = max(2, int(round(max(bw, bh) * (1 + pad_ratio))))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    paste_x = (side - bw) // 2
    paste_y = (side - bh) // 2
    canvas.paste(content, (paste_x, paste_y), content)
    return canvas


def main():
    for fname, folder, rows, cols in SHEETS:
        path = os.path.join(SRC, fname)
        if not os.path.exists(path):
            print(f"MISSING {path}")
            continue
        img = Image.open(path).convert("RGBA")
        expected = rows * cols
        boxes = find_sprites(img, expected)
        boxes = order_grid(boxes, rows, cols)
        dst = os.path.join(OUT, folder)
        os.makedirs(dst, exist_ok=True)
        for idx, box in enumerate(boxes):
            sprite = crop_centered(img, box)
            sprite.save(os.path.join(dst, f"{idx}.png"))
        print(f"{folder}: exported {len(boxes)} sprites")


if __name__ == "__main__":
    main()
