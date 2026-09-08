"""
Generate high-resolution (1200x630) social preview card for FlowSnap.
Design: Apple HIG + Shadcn Obsidian palette (#09090b), clean hairline borders,
macOS window mockup, and verified technical badges.
"""

from PIL import Image, ImageDraw, ImageFont
import os

WIDTH = 1200
HEIGHT = 630

# Create base canvas with Obsidian dark theme #09090b
img = Image.new("RGBA", (WIDTH, HEIGHT), (9, 9, 11, 255))
draw = ImageDraw.Draw(img)

# Outer 1px hairline border #27272a
draw.rectangle([20, 20, WIDTH - 20, HEIGHT - 20], outline=(39, 39, 42, 255), width=1)
draw.rectangle([24, 24, WIDTH - 24, HEIGHT - 24], outline=(24, 24, 27, 255), width=1)

# Subtle background grid lines
for x in range(60, WIDTH - 60, 80):
    draw.line([(x, 30), (x, HEIGHT - 30)], fill=(18, 18, 22, 255), width=1)
for y in range(60, HEIGHT - 60, 60):
    draw.line([(30, y), (WIDTH - 30, y)], fill=(18, 18, 22, 255), width=1)

# Try loading system font or fallback
font_title = None
font_subtitle = None
font_body = None
font_badge = None

for font_path in [
    "/System/Library/Fonts/SFPro-Bold.otf",
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
]:
    if os.path.exists(font_path):
        try:
            font_title = ImageFont.truetype(font_path, 52)
            font_subtitle = ImageFont.truetype(font_path, 26)
            font_body = ImageFont.truetype(font_path, 18)
            font_badge = ImageFont.truetype(font_path, 14)
            break
        except Exception:
            continue

if not font_title:
    font_title = ImageFont.load_default()
    font_subtitle = ImageFont.load_default()
    font_body = ImageFont.load_default()
    font_badge = ImageFont.load_default()

# Header: Logo & Title
# App icon box (rounded rectangle with window snap layout inside)
icon_x, icon_y = 60, 60
draw.rounded_rectangle([icon_x, icon_y, icon_x + 56, icon_y + 56], radius=12, fill=(24, 24, 27, 255), outline=(63, 63, 70, 255), width=1)
# Inside icon: split grid representation
draw.rounded_rectangle([icon_x + 8, icon_y + 8, icon_x + 26, icon_y + 48], radius=3, fill=(59, 130, 246, 220))
draw.rounded_rectangle([icon_x + 30, icon_y + 8, icon_x + 48, icon_y + 26], radius=3, fill=(161, 161, 170, 180))
draw.rounded_rectangle([icon_x + 30, icon_y + 30, icon_x + 48, icon_y + 48], radius=3, fill=(113, 113, 122, 180))

# App Title & Release Badge
draw.text((icon_x + 72, icon_y + 4), "FlowSnap", fill=(255, 255, 255, 255), font=font_title)

# Version pill
badge_x = icon_x + 340
draw.rounded_rectangle([badge_x, icon_y + 14, badge_x + 72, icon_y + 42], radius=14, fill=(39, 39, 42, 255), outline=(63, 63, 70, 255), width=1)
draw.text((badge_x + 14, icon_y + 20), "v1.3.1", fill=(228, 228, 231, 255), font=font_badge)

# Tagline
tagline = "macOS Window Manager with Intent & Snap Precision"
draw.text((60, 140), tagline, fill=(244, 244, 245, 255), font=font_subtitle)

sub_desc = "Windows 11-style snap picker, multi-display intent restoration, Quake scratchpad, and zero private APIs."
draw.text((60, 180), sub_desc, fill=(161, 161, 170, 255), font=font_body)

# Central Mock Window Display (macOS Native Window with 2D split layout)
win_x, win_y, win_w, win_h = 60, 230, 1080, 270
draw.rounded_rectangle([win_x, win_y, win_x + win_w, win_y + win_h], radius=12, fill=(18, 18, 22, 255), outline=(39, 39, 42, 255), width=1)

# Window Titlebar
draw.rounded_rectangle([win_x, win_y, win_x + win_w, win_y + 38], radius=12, fill=(24, 24, 27, 255))
draw.rectangle([win_x, win_y + 26, win_x + win_w, win_y + 38], fill=(24, 24, 27, 255)) # Square bottom of titlebar
draw.line([(win_x, win_y + 38), (win_x + win_w, win_y + 38)], fill=(39, 39, 42, 255), width=1)

# Traffic lights
draw.ellipse([win_x + 16, win_y + 14, win_x + 28, win_y + 26], fill=(239, 68, 68, 255)) # Red
draw.ellipse([win_x + 36, win_y + 14, win_x + 48, win_y + 26], fill=(234, 179, 8, 255)) # Yellow
draw.ellipse([win_x + 56, win_y + 14, win_x + 68, win_y + 26], fill=(34, 197, 94, 255)) # Green

# Titlebar title
draw.text((win_x + win_w // 2 - 120, win_y + 11), "FlowSnap Desktop Workspace (70 / 30 Split)", fill=(161, 161, 170, 255), font=font_badge)

# Window Interior: 70/30 Split with Collinear Divider
interior_top = win_y + 46
interior_bottom = win_y + win_h - 12
split_x = win_x + int(win_w * 0.68)

# Left Pane (70%): Editor / Browser
draw.rounded_rectangle([win_x + 12, interior_top, split_x - 6, interior_bottom], radius=8, fill=(12, 12, 15, 255), outline=(28, 28, 33, 255), width=1)
draw.text((win_x + 28, interior_top + 18), "VS Code / Main Workspace", fill=(212, 212, 216, 255), font=font_body)
# Mock code lines
for i in range(5):
    line_y = interior_top + 55 + i * 22
    draw.rounded_rectangle([win_x + 28, line_y, win_x + 28 + (320 if i % 2 == 0 else 240), line_y + 10], radius=3, fill=(39, 39, 42, 180))

# Collinear Divider (Active 2D Drag Handle)
draw.rounded_rectangle([split_x - 3, interior_top, split_x + 3, interior_bottom], radius=3, fill=(59, 130, 246, 200))

# Right Pane (30%): Chat / Docs
draw.rounded_rectangle([split_x + 6, interior_top, win_x + win_w - 12, interior_bottom], radius=8, fill=(12, 12, 15, 255), outline=(28, 28, 33, 255), width=1)
draw.text((split_x + 20, interior_top + 18), "Quake Scratchpad", fill=(212, 212, 216, 255), font=font_body)
for i in range(4):
    line_y = interior_top + 55 + i * 22
    draw.rounded_rectangle([split_x + 20, line_y, split_x + 20 + 160, line_y + 10], radius=3, fill=(39, 39, 42, 180))

# Bottom Metric Badges Row
metrics = [
    "Swift 6 Concurrency",
    "0 Private APIs",
    "470+ Unit Tests",
    "< 1ms Snap Math",
    "100% Offline",
    "Zero Telemetry",
]

metric_start_x = 60
badge_w = 170
for idx, metric in enumerate(metrics):
    mx = metric_start_x + idx * 182
    my = 530
    draw.rounded_rectangle([mx, my, mx + 172, my + 38], radius=8, fill=(18, 18, 22, 255), outline=(39, 39, 42, 255), width=1)
    # Green accent dot
    draw.ellipse([mx + 12, my + 15, mx + 20, my + 23], fill=(34, 197, 94, 255))
    draw.text((mx + 28, my + 11), metric, fill=(212, 212, 216, 255), font=font_badge)

output_path = os.path.join(os.path.dirname(__file__), "../public/og-preview.png")
os.makedirs(os.path.dirname(output_path), exist_ok=True)
img.save(output_path, "PNG", optimize=True)
print(f"Generated {output_path} ({os.path.getsize(output_path)} bytes)")
