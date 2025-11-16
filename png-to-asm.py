from PIL import Image
import sys
import os

# Usage:
#   python png_to_asm.py gem_blue.png gem_blue_sprite sprites.asm

if len(sys.argv) < 4:
    print("Usage: python png_to_asm_append.py <image.png> <label_name> <sprites.asm>")
    sys.exit(1)

png_path = sys.argv[1]
label = sys.argv[2]
sprites_path = sys.argv[3]

# Load image as RGBA
img = Image.open(png_path).convert("RGBA")
w, h = img.size
pixels = img.load()

# Open sprites.asm in append mode so we don't overwrite it
with open(sprites_path, "a", encoding="utf-8") as f:
    f.write("\n\n##############################################################################\n")
    f.write(f"# Sprite generated from {os.path.basename(png_path)} ({w}x{h})\n")
    f.write("##############################################################################\n\n")

    # Declare the label
    f.write(f".globl {label}\n")
    f.write(f"{label}:    # {w}x{h} sprite\n")

    # Emit .word rows
    for y in range(h):
        words = []
        for x in range(w):
            r, g, b, a = pixels[x, y]
            # pack as 0x00RRGGBB (alpha ignored for MARS Bitmap Display)
            value = (r << 16) | (g << 8) | b
            words.append(f"0x{value:08X}")
        f.write("    .word " + ", ".join(words) + "\n")

