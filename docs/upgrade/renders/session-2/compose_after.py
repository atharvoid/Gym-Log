"""Label live Flutter screenshots without resizing or masking their pixels."""
from pathlib import Path
import json
from PIL import Image, ImageDraw, ImageFont
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[3]
ITERATION = sys.argv[1] if len(sys.argv) > 1 else "4"
assert ITERATION in {"4", "owner-fix", "owner-fix-2", "owner-fix-3", "owner-fix-4"}
AFTER = BASE / "after" / f"iteration-{ITERATION}"
FONT = ROOT / "assets/google_fonts/Inter-Regular.ttf"
BOLD = ROOT / "assets/google_fonts/Inter-SemiBold.ttf"


def sheet(filename, title, detail, panels):
    canvas = Image.new("RGB", (len(panels) * 406 + 24, 1030), "#151515")
    draw = ImageDraw.Draw(canvas)
    draw.text((20, 16), title, font=ImageFont.truetype(str(BOLD), 25), fill="white")
    draw.text((20, 54), detail, font=ImageFont.truetype(str(FONT), 17), fill="#dddddd")
    for index, (label, path) in enumerate(panels):
        x = 20 + index * 406
        draw.text((x, 96), label, font=ImageFont.truetype(str(BOLD), 20), fill="white")
        with Image.open(path) as source:
            assert source.size == (390, 844), (path, source.size)
            canvas.paste(source.convert("RGB"), (x, 128))
    draw.text((20, 988), "Live widgets / synthetic fixtures / real Inter / native surfaces unverified",
              font=ImageFont.truetype(str(FONT), 16), fill="#dddddd")
    canvas.save(BASE / filename)


def capture(screen, state="chosen", palette="higgsfield", scale="1.0"):
    return AFTER / f"{screen}-{state}-{palette}-{scale}x-synthetic.png"


for scale in ["1.0", "1.6"]:
    sheet(f"implemented-a-{scale}x.png", "Session 2: chosen routine launchpad",
          f"390 x 844 / {scale}x text / Volt",
          [(screen.title(), capture(screen, scale=scale)) for screen in ["home", "library"]])
    sheet(f"implemented-chooser-{scale}x.png", "Session 2: one-tap Change chooser",
          f"390 x 844 / {scale}x text / optional program suggestion",
          [("Volt", AFTER / f"chooser-higgsfield-{scale}x-synthetic.png"),
           ("Purple", AFTER / f"chooser-neonPurple-{scale}x-synthetic.png")])
    sheet(f"implemented-scroll-{scale}x.png", "Session 2: secondary content reached",
          f"390 x 844 / {scale}x text / Volt / after interaction",
          [("After History tap", AFTER / f"home-history-shortcut-higgsfield-{scale}x-synthetic.png"),
           ("Library below fold", AFTER / f"library-below-fold-higgsfield-{scale}x-synthetic.png")])
    sheet(f"implemented-chooser-states-{scale}x.png", "Session 2: bounded chooser interactions",
          f"390 x 844 / {scale}x text / Volt / after interaction",
          [(state, AFTER / f"chooser-{state}-higgsfield-{scale}x-synthetic.png")
           for state in ["search", "no-results", "page-2"]])
    for screen in ["home", "library"]:
        sheet(f"implemented-{screen}-active-{scale}x.png", f"Session 2: {screen.title()} active workout",
              f"390 x 844 / {scale}x text / Volt / Resume is explicit",
              [(state, capture(screen, state, scale=scale)) for state in
               ["active-chosen", "active-no-choice", "active-no-routine", "active-error"]])
        sheet(f"implemented-{screen}-choices-{scale}x.png", f"Session 2: {screen.title()} choice recovery",
              f"390 x 844 / {scale}x text / Volt",
              [(state, capture(screen, state, scale=scale)) for state in
               ["no-choice", "deleted-choice", "empty-choice", "new-user"]])
        sheet(f"implemented-{screen}-active-recovery-{scale}x.png", f"Session 2: {screen.title()} active-session priority",
              f"390 x 844 / {scale}x text / Volt / saved choice stays separate",
              [(state, capture(screen, state, scale=scale)) for state in
               ["active-deleted-choice", "active-empty-choice", "active-choice-error"]])
        sheet(f"implemented-{screen}-states-{scale}x.png", f"Session 2: {screen.title()} data states",
              f"390 x 844 / {scale}x text / Volt",
              [(state, capture(screen, state, scale=scale)) for state in
               ["no-routine", "inactive-return", "low-data", "error"]])
sheet("implemented-a-purple.png", "Session 2: chosen routine launchpad",
      "390 x 844 / 1.0x text / Purple",
      [(screen.title(), capture(screen, palette="neonPurple")) for screen in ["home", "library"]])
for screen in ["home", "library"]:
    sheet(f"implemented-{screen}-comparison.png", f"Session 2: {screen.title()} before and after",
          "390 x 844 / Volt / matched synthetic returning-user facts",
          [("Before / 1.0x", BASE / "before" / f"{screen}-returning-higgsfield-1.0x-synthetic.png"),
           ("After / 1.0x", capture(screen)),
           ("Before / 1.6x", BASE / "before" / f"{screen}-returning-higgsfield-1.6x-synthetic.png"),
           ("After / 1.6x", capture(screen, scale="1.6"))])
images = list(AFTER.glob("*.png"))
for path in images:
    with Image.open(path) as source:
        assert source.size == (390, 844), (path, source.size)
report = {"iteration": ITERATION, "live_after_pngs": len(images), "goldens": len(list((ROOT / "test/upgrade/goldens/session-2").glob("*.png"))),
          "viewport": [390, 844], "text_scales": [1.0, 1.6], "palettes": 6, "synthetic": True,
          "native_surfaces": "unverified", "masked_text": False}
(BASE / "after-inventory.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(json.dumps(report))
