#!/usr/bin/env python3
"""Scar marks per facing, drawn by rule: small, readable, from the family ramps.
Output: art/overlays/scar-<scar>-<facing>.png"""
import json, subprocess
from pathlib import Path
b = json.load(open("art/palettes/bronze.ramps.json"))
blood, outline, hi, leather = b["blood"], b["outline"], b["highlight"], b["leather"]
out = Path("art/overlays")
def draw(name, cmds): subprocess.run(["magick", "-size", "32x32", "xc:none"] + cmds + [str(out / f"{name}.png")], check=True)
def px(x, y, c): return ["-fill", c, "-stroke", "none", "-draw", f"point {x},{y}"]
def line(x1, y1, x2, y2, c): return ["-fill", c, "-stroke", c, "-draw", f"line {x1},{y1} {x2},{y2}"]
def rect(x1, y1, x2, y2, c): return ["-fill", c, "-stroke", "none", "-draw", f"rectangle {x1},{y1} {x2},{y2}"]
facings = ["down", "left", "right", "up"]
# crushed hand: a leather wrap on the off hand
for f, (x, y) in zip(facings, [(11, 22), (13, 22), (17, 22), (19, 22)]):
	draw(f"scar-crushed_hand-{f}", rect(x, y, x + 2, y + 2, leather[0]) + px(x + 1, y + 1, leather[2]))
# torn ear: a notch and a red mark by the head
for f, (x, y) in zip(facings, [(19, 9), (12, 9), (19, 9), (19, 9)]):
	draw(f"scar-torn_ear-{f}", px(x, y, blood) + px(x + 1, y + 1, outline))
# broken nose: a dark bar across the face
for f, (x, y, w) in zip(facings, [(14, 11, 3), (13, 11, 2), (17, 11, 2), (14, 11, 0)]):
	draw(f"scar-broken_nose-{f}", (line(x, y, x + w, y, outline) if w else []))
# salt lungs: a pale line at the collar
for f in facings:
	draw(f"scar-salt_lungs-{f}", line(13, 14, 18, 14, hi))
# lamed: a leather strap round the leg
for f, (x, y) in zip(facings, [(12, 25), (14, 25), (16, 25), (18, 25)]):
	draw(f"scar-lamed-{f}", line(x, y, x + 3, y, leather[0]) + px(x + 1, y + 1, leather[0]))
# shield shoulder: a bronze-coloured pad on the shoulder
for f, (x, y) in zip(facings, [(10, 14), (12, 14), (18, 14), (20, 14)]):
	draw(f"scar-shield_shoulder-{f}", rect(x, y, x + 2, y + 1, leather[1]))
# bitten: three red points on the forearm
for f, (x, y) in zip(facings, [(20, 19), (11, 19), (20, 19), (10, 19)]):
	draw(f"scar-bitten-{f}", px(x, y, blood) + px(x + 1, y + 1, blood) + px(x, y + 2, blood))
# burned ink, substituted: marks on the throat
for f in facings:
	draw(f"scar-burned_ink-{f}", line(14, 13, 17, 13, blood))
	draw(f"scar-substituted-{f}", px(15, 13, outline) + px(16, 13, outline))
print("scar overlays:", len(list(out.glob("scar-*.png"))))
