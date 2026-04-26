"""
Generates assets/icons/app_icon.png (1024x1024) for SpeakUp Reading.
Design: deep navy gradient background, stylised open book, AI spark accent.
"""
import math
from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
CORNER = 220  # rounded-rect corner radius for the background

# ── Colours ────────────────────────────────────────────────────────────────
BG_TOP    = (18,  32,  74)   # deep navy
BG_BOTTOM = (10,  10,  35)   # near-black
BOOK_L    = (255, 255, 255)  # left page — white
BOOK_R    = (200, 215, 255)  # right page — light blue tint
SPINE     = (100, 140, 255)  # spine line — accent blue
SPARK     = (100, 200, 255)  # spark dots — cyan-blue
LINES_L   = (180, 190, 220)  # text lines left page
LINES_R   = (140, 155, 200)  # text lines right page


def make_rounded_rect_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    return mask


def vertical_gradient(size, top, bottom):
    img = Image.new("RGB", (size, size))
    for y in range(size):
        t = y / size
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        ImageDraw.Draw(img).line([(0, y), (size - 1, y)], fill=(r, g, b))
    return img


def draw_icon():
    icon = vertical_gradient(SIZE, BG_TOP, BG_BOTTOM)
    draw = ImageDraw.Draw(icon)

    # ── Open book ──────────────────────────────────────────────────────────
    # Centre the book on the canvas
    cx, cy = SIZE // 2, SIZE // 2 + 30   # slight downward offset

    # Page dimensions
    pw = 310   # page width (each half)
    ph = 380   # page height
    curve = 18 # top/bottom corner softness

    # Left page
    lx0, ly0 = cx - pw - 8, cy - ph // 2
    lx1, ly1 = cx - 8,      cy + ph // 2
    draw.rounded_rectangle([lx0, ly0, lx1, ly1], radius=curve, fill=BOOK_L)

    # Right page
    rx0, ry0 = cx + 8, cy - ph // 2
    rx1, ry1 = cx + pw + 8, cy + ph // 2
    draw.rounded_rectangle([rx0, ry0, rx1, ry1], radius=curve, fill=BOOK_R)

    # Spine divider
    draw.rounded_rectangle([cx - 10, ly0 + 10, cx + 10, ly1 - 10],
                            radius=6, fill=SPINE)

    # Text lines — left page
    line_start_x = lx0 + 40
    line_end_x   = lx1 - 30
    for i, y_off in enumerate(range(-120, 160, 44)):
        w = line_end_x if i % 3 != 2 else line_end_x - 60
        draw.rounded_rectangle(
            [line_start_x, cy + y_off, w, cy + y_off + 14],
            radius=7, fill=LINES_L,
        )

    # Text lines — right page
    line_start_x2 = rx0 + 30
    line_end_x2   = rx1 - 40
    for i, y_off in enumerate(range(-120, 160, 44)):
        w = line_end_x2 if i % 3 != 1 else line_end_x2 - 50
        draw.rounded_rectangle(
            [line_start_x2, cy + y_off, w, cy + y_off + 14],
            radius=7, fill=LINES_R,
        )

    # ── AI spark — three glowing dots in top-right of right page ──────────
    spark_cx = rx0 + pw - 60
    spark_cy = ry0 + 60
    for ang, r_off in [(0, 0), (120, 0), (240, 0)]:
        rad = math.radians(ang)
        sx = spark_cx + int(32 * math.cos(rad))
        sy = spark_cy + int(32 * math.sin(rad))
        # glow halo
        for halo in range(14, 4, -3):
            alpha = int(120 * (1 - halo / 14))
            halo_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
            ImageDraw.Draw(halo_layer).ellipse(
                [sx - halo, sy - halo, sx + halo, sy + halo],
                fill=(*SPARK, alpha),
            )
            icon.paste(
                Image.new("RGB", (SIZE, SIZE), SPARK),
                mask=halo_layer.split()[3],
            )
        # solid dot
        draw.ellipse([sx - 7, sy - 7, sx + 7, sy + 7], fill=SPARK)

    # Connecting lines between spark dots
    angles = [0, 120, 240]
    for i in range(3):
        a1 = math.radians(angles[i])
        a2 = math.radians(angles[(i + 1) % 3])
        p1 = (spark_cx + int(32 * math.cos(a1)),
              spark_cy + int(32 * math.sin(a1)))
        p2 = (spark_cx + int(32 * math.cos(a2)),
              spark_cy + int(32 * math.sin(a2)))
        draw.line([p1, p2], fill=(*SPARK, 160), width=2)

    # ── Apply rounded-rect mask ────────────────────────────────────────────
    mask = make_rounded_rect_mask(SIZE, CORNER)
    result = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    result.paste(icon.convert("RGBA"), mask=mask)

    out_path = "assets/icons/app_icon.png"
    result.save(out_path, "PNG")
    print(f"Icon saved → {out_path}  ({SIZE}x{SIZE})")


if __name__ == "__main__":
    draw_icon()
