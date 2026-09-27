#!/usr/bin/env python3
"""Class weapon overlays, drawn by rule on a 32x32 canvas per facing, from theme ramps.
Output: art/overlays/<class>-<facing>.png  (facings: down, left, right, up)"""
import json, subprocess
from pathlib import Path
b = json.load(open("art/palettes/bronze.ramps.json"))
metal, leather, outline, wood = b["metal"], b["leather"], b["outline"], b["leather"]
out = Path("art/overlays"); out.mkdir(exist_ok=True)

def draw(name, cmds):
	subprocess.run(["magick", "-size", "32x32", "xc:none"] + cmds + [str(out / f"{name}.png")], check=True)

def line(x1, y1, x2, y2, colour): return ["-fill", colour, "-stroke", colour, "-draw", f"line {x1},{y1} {x2},{y2}"]
def rect(x1, y1, x2, y2, colour): return ["-fill", colour, "-stroke", "none", "-draw", f"rectangle {x1},{y1} {x2},{y2}"]
def px(x, y, colour): return ["-fill", colour, "-stroke", "none", "-draw", f"point {x},{y}"]

# Spear: a long shaft with a bronze head. Held upright to the side; on side facings it points forward.
draw("spear-down",  line(21, 6, 21, 27, wood[1]) + rect(20, 3, 22, 6, metal[2]) + px(21, 2, metal[2]))
draw("spear-up",    line(10, 6, 10, 27, wood[1]) + rect(9, 3, 11, 6, metal[2]) + px(10, 2, metal[2]))
draw("spear-right", line(14, 17, 29, 17, wood[1]) + rect(29, 16, 31, 18, metal[2]) + px(31, 17, metal[2]))
draw("spear-left",  line(2, 17, 17, 17, wood[1]) + rect(0, 16, 2, 18, metal[2]) + px(0, 17, metal[2]))
# Sling: a short cord with a pouch at the hip.
draw("sling-down",  line(22, 18, 25, 24, leather[0]) + rect(24, 24, 26, 26, leather[1]))
draw("sling-up",    line(9, 18, 6, 24, leather[0]) + rect(5, 24, 7, 26, leather[1]))
draw("sling-right", line(20, 18, 24, 22, leather[0]) + rect(24, 22, 26, 24, leather[1]))
draw("sling-left",  line(11, 18, 7, 22, leather[0]) + rect(5, 22, 7, 24, leather[1]))
# Shield: a tall hide rectangle with a bronze boss and dark rim.
def shield(x1, y1, x2, y2):
	cx, cy = (x1 + x2) // 2, (y1 + y2) // 2
	return rect(x1, y1, x2, y2, outline) + rect(x1 + 1, y1 + 1, x2 - 1, y2 - 1, leather[1]) + rect(cx - 1, cy - 1, cx + 1, cy + 1, metal[2])
draw("shield-down",  shield(6, 12, 13, 27))
draw("shield-up",    shield(18, 12, 25, 27))
draw("shield-right", shield(20, 11, 25, 27))
draw("shield-left",  shield(6, 11, 11, 27))
print("overlays:", sorted(p.name for p in out.glob("*.png")))
