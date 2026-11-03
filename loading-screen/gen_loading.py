"""Build the Bug Crush loading screen art.

Outputs (in ~/workspace/):
  bug-crush-logo-splash.png  - static logo, neon-purple zapper style
  bug-crush-loading.apng     - 5s loop: text pulses, ladybug crawls the
                               name and gets zapped, then it all repeats.

Deploy note: the Godot web export writes a static index.png from
splash.png. After every export, replace export/index.png with the APNG
before copying to live -- the default shell then plays the animation
with zero loader changes.
"""
import math
from PIL import Image, ImageDraw, ImageFont, ImageEnhance

FONT = "/home/hatch/workspace/bug-crush/fonts/LuckiestGuy-Regular.ttf"
PURPLE = (204, 77, 255, 255)   # bug-zapper neon purple
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)
RED = (220, 40, 40, 255)
GLOW = (255, 240, 150)

W, H = 1200, 620
TEXT_CX, TEXT_CY = 600, 480


def ladybug_layer(w, h):
    img = Image.new("RGBA", (int(w * 1.3), int(h * 1.3)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    cx, cy = img.width // 2, img.height // 2
    d.ellipse([cx - w / 2, cy - h / 2, cx + w / 2, cy + h / 2], fill=RED)
    d.ellipse([cx - w * 0.22, cy - h / 2 - h * 0.08, cx + w * 0.22, cy - h / 2 + h * 0.28], fill=BLACK)
    d.line([cx, cy - h / 2 + h * 0.22, cx, cy + h / 2], fill=BLACK, width=max(3, int(w * 0.03)))
    for dx, dy, r in [(-0.28, -0.15, 0.09), (0.28, -0.15, 0.09),
                      (-0.30, 0.18, 0.10), (0.30, 0.18, 0.10),
                      (-0.22, 0.38, 0.08), (0.22, 0.38, 0.08)]:
        d.ellipse([cx + dx * w - r * w, cy + dy * h - r * w,
                   cx + dx * w + r * w, cy + dy * h + r * w], fill=BLACK)
    for ex in (-0.11, 0.11):
        d.ellipse([cx + ex * w - w * 0.06, cy - h / 2 + h * 0.06,
                   cx + ex * w + w * 0.06, cy - h / 2 + h * 0.18], fill=WHITE)
        d.ellipse([cx + ex * w - w * 0.025, cy - h / 2 + h * 0.09,
                   cx + ex * w + w * 0.025, cy - h / 2 + h * 0.15], fill=BLACK)
    return img


def text_layer():
    """Tight layer with the title: black shadow, purple fill, white outline."""
    img = Image.new("RGBA", (1150, 240), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT, 170)
    d.text((575 + 6, 120 + 6), "BUG CRUSH", font=font, fill=BLACK, anchor="mm")
    d.text((575, 120), "BUG CRUSH", font=font, fill=PURPLE, anchor="mm",
           stroke_width=10, stroke_fill=WHITE)
    return img


def zap_layer(cx, cy, strength):
    """Starburst flash at (cx, cy); strength 1 -> 0 over the zap."""
    img = Image.new("RGBA", (420, 420), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    a = int(230 * strength)
    d.ellipse([210 - 90 * strength, 210 - 90 * strength,
               210 + 90 * strength, 210 + 90 * strength],
              fill=(255, 255, 200, int(140 * strength)))
    for k in range(12):
        ang = k * math.pi / 6
        ln = 90 + 70 * strength
        d.line([210, 210, 210 + ln * math.cos(ang), 210 + ln * math.sin(ang)],
               fill=GLOW + (a,), width=7)
    return img


TEXT = text_layer()
BUG = ladybug_layer(170, 135)

# --- static splash (also the Godot boot splash source) ---
frame = Image.new("RGBA", (W, H), (0, 0, 0, 0))
frame.alpha_composite(TEXT, (TEXT_CX - TEXT.width // 2, TEXT_CY - TEXT.height // 2))
frame.save("/home/hatch/workspace/bug-crush-logo-splash.png")

# --- animated 5s loop: 12 fps x 60 frames ---
FPS, N = 12, 60
frames = []
for i in range(N):
    t = i / FPS
    fr = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    # title pulse: 1.0 -> 1.06 -> 1.0 every 0.5s, like the in-game zapper
    p = 1 + 0.03 * (1 - math.cos(2 * math.pi * t / 0.5))
    tw, th = int(TEXT.width * p), int(TEXT.height * p)
    scaled = TEXT.resize((tw, th), Image.LANCZOS)
    fr.alpha_composite(scaled, (TEXT_CX - tw // 2, TEXT_CY - th // 2))
    # ladybug crawl: 0.5s -> 3.5s across the name, then zap 3.5 -> 3.9s
    if 0.5 <= t < 3.5:
        x = -120 + (t - 0.5) / 3.0 * 1220
        y = TEXT_CY + math.sin(t * 30) * 6
        rock = math.degrees(math.sin(t * 30) * 0.2)
        bug = BUG.rotate(rock, resample=Image.BICUBIC, center=(BUG.width // 2, BUG.height // 2))
        fr.alpha_composite(bug, (int(x - bug.width // 2), int(y - bug.height // 2)))
    elif 3.5 <= t < 3.9:
        k = (t - 3.5) / 0.4
        x, y = 1100, TEXT_CY
        bug = BUG.resize((int(BUG.width * (1 + 0.8 * k)), int(BUG.height * (1 + 0.8 * k))), Image.LANCZOS)
        alpha = bug.split()[3].point(lambda a: int(a * (1 - k)))
        bug.putalpha(alpha)
        fr.alpha_composite(bug, (int(x - bug.width // 2), int(y - bug.height // 2)))
        zap = zap_layer(0, 0, 1 - k)
        fr.alpha_composite(zap, (int(x - 210), int(y - 210)))
    frames.append(fr)

frames[0].save("/home/hatch/workspace/bug-crush-loading.apng", save_all=True,
               append_images=frames[1:], duration=83, loop=0)
print("static + apng written")

# verify the apng
data = open("/home/hatch/workspace/bug-crush-loading.apng", "rb").read()
im = Image.open("/home/hatch/workspace/bug-crush-loading.apng")
print("acTL present:", b"acTL" in data, "| frames:", getattr(im, "n_frames", 1),
      "| bytes:", len(data))
