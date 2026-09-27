#!/usr/bin/env python3
"""Bronze graft overlays per facing, drawn by rule from the bronze metal ramp.
Output: art/overlays/graft-<graft>-<facing>.png"""
import json, subprocess
from pathlib import Path
b = json.load(open("art/palettes/bronze.ramps.json"))
metal, outline = b["metal"], b["outline"]
out = Path("art/overlays")
def draw(name, cmds): subprocess.run(["magick", "-size", "32x32", "xc:none"] + cmds + [str(out / f"{name}.png")], check=True)
def rect(x1, y1, x2, y2, c): return ["-fill", c, "-stroke", "none", "-draw", f"rectangle {x1},{y1} {x2},{y2}"]
def px(x, y, c): return ["-fill", c, "-stroke", "none", "-draw", f"point {x},{y}"]
# Arm: the right arm (viewer's left when facing down) becomes a bronze bar with a highlight.
arm = lambda x1, y1, x2, y2: rect(x1, y1, x2, y2, outline) + rect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, metal[1]) + px(x1 + 1, y1 + 1, metal[2])
draw("graft-bronze_arm-down",  arm(9, 14, 12, 23))
draw("graft-bronze_arm-up",    arm(19, 14, 22, 23))
draw("graft-bronze_arm-left",  arm(12, 15, 15, 23))
draw("graft-bronze_arm-right", arm(16, 15, 19, 23))
# Leg: the left leg from knee to foot.
leg = lambda x1, y1, x2, y2: rect(x1, y1, x2, y2, outline) + rect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, metal[1]) + px(x1 + 1, y2 - 1, metal[2])
draw("graft-bronze_leg-down",  leg(17, 22, 20, 29))
draw("graft-bronze_leg-up",    leg(11, 22, 14, 29))
draw("graft-bronze_leg-left",  leg(13, 22, 16, 29))
draw("graft-bronze_leg-right", leg(15, 22, 18, 29))
# Jaw: a bronze band across the lower face.
draw("graft-bronze_jaw-down",  rect(12, 12, 19, 14, metal[1]) + rect(13, 12, 18, 12, metal[2]))
draw("graft-bronze_jaw-up",    [])
draw("graft-bronze_jaw-left",  rect(11, 12, 16, 14, metal[1]) + px(11, 12, metal[2]))
draw("graft-bronze_jaw-right", rect(15, 12, 20, 14, metal[1]) + px(20, 12, metal[2]))
# Ribs: three bronze bars across the torso.
ribs = lambda x1, x2: sum([rect(x1, y, x2, y, metal[1]) + px(x1, y, metal[2]) for y in (16, 18, 20)], [])
draw("graft-bronze_ribs-down",  ribs(12, 19))
draw("graft-bronze_ribs-up",    ribs(12, 19))
draw("graft-bronze_ribs-left",  ribs(12, 17))
draw("graft-bronze_ribs-right", ribs(14, 19))
print("graft overlays:", len(list(out.glob("graft-*.png"))))
