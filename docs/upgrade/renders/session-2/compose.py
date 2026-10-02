"""Compose owner-review sheets from Flutter PNGs without altering screenshots.

Run from the repository root: python docs/upgrade/renders/session-2/compose.py
Requires the already installed Pillow; it is not an app dependency.
"""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
FONT = ROOT / "assets/google_fonts/Inter-Regular.ttf"
BOLD = ROOT / "assets/google_fonts/Inter-SemiBold.ttf"
OPTIONS = [("chosen", "A - Chosen routine"),
           ("sequence", "B - Explained rotation"),
           ("chooser", "C - Choose each session")]


def capture(option, screen, scale="1.0", palette="higgsfield",
            state="returning", below=False):
    directory = "before" if option == "before" else f"options/{option}"
    suffix = "-below-fold" if below else ""
    return BASE / directory / f"{screen}-{state}-{palette}-{scale}x-synthetic{suffix}.png"


def sheet(filename, title, subtitle, panels):
    canvas = Image.new("RGB", (40 + 390 * len(panels) + 16 * (len(panels) - 1),
                               1016), "#202020")
    draw = ImageDraw.Draw(canvas)
    draw.text((20, 16), title, font=ImageFont.truetype(str(BOLD), 28), fill="white")
    draw.text((20, 55), subtitle, font=ImageFont.truetype(str(FONT), 17), fill="#dddddd")
    for index, (label, path) in enumerate(panels):
        x = 20 + index * 406
        draw.text((x, 96), label, font=ImageFont.truetype(str(BOLD), 21), fill="white")
        with Image.open(path) as source:
            assert source.size == (390, 844), (path, source.size)
            canvas.paste(source.convert("RGB"), (x, 128))
    draw.text((20, 988), "Static synthetic concepts; app production code unchanged.",
              font=ImageFont.truetype(str(FONT), 17), fill="#dddddd")
    canvas.save(BASE / filename)


for scale in ["1.0", "1.6"]:
    for screen in ["home", "library"]:
        sheet(f"{screen}-options-{scale}x.png", f"Session 2: {screen.title()} options",
              f"390 x 844 app viewport / {scale}x text / Volt / same sample history",
              [(label, capture(option, screen, scale)) for option, label in OPTIONS])
        sheet(f"{screen}-options-below-fold-{scale}x.png", f"Session 2: {screen.title()} after scrolling",
              f"390 x 844 / {scale}x text / Volt / lower content",
              [(label, capture(option, screen, scale, below=True)) for option, label in OPTIONS])
    sheet(f"before-{scale}x.png", "Session 2: current app baseline",
          f"390 x 844 / {scale}x text / Volt / synthetic returning-user data",
          [(screen.title(), capture("before", screen, scale)) for screen in ["home", "library"]])
    for option, label in OPTIONS:
        sheet(f"{option}-pair-{scale}x.png", f"Session 2: {label}",
              f"390 x 844 / {scale}x text / Volt / returning user",
              [(screen.title(), capture(option, screen, scale)) for screen in ["home", "library"]])
for option, label in OPTIONS:
    sheet(f"{option}-pair-purple.png", f"Session 2: {label}",
          "390 x 844 / 1.0x text / Purple / returning user",
          [(screen.title(), capture(option, screen, palette="neonPurple")) for screen in ["home", "library"]])
    sheet(f"{option}-home-states.png", f"Session 2: {label} - Home states",
          "390 x 844 / 1.0x text / Volt / synthetic fallback data",
          [(state, capture(option, "home", state=state)) for state in
           ["inactive", "empty", "noRoutine", "lowData", "error"]])
    sheet(f"{option}-library-states.png", f"Session 2: {label} - Library states",
          "390 x 844 / 1.0x text / Volt / synthetic fallback data",
          [(state, capture(option, "library", state=state)) for state in
           ["inactive", "empty", "noRoutine", "lowData", "error"]])

raw = list((BASE / "before").glob("*.png")) + list((BASE / "options").glob("*/*.png"))
for path in raw:
    with Image.open(path) as screenshot:
        assert screenshot.size == (390, 844), (path, screenshot.size)
report = {"raw_pngs": len(raw), "before_pngs": len(list((BASE / "before").glob("*.png"))),
          "concept_pngs": len(list((BASE / "options").glob("*/*.png"))),
          "raw_dimensions": [390, 844], "text_scales": [1.0, 1.6],
          "palettes": ["Volt", "Purple"], "synthetic": True,
          "composite_pngs": len(list(BASE.glob("*.png")))}
(BASE / "inventory.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report))
