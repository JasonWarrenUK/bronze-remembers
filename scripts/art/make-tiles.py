#!/usr/bin/env python3
"""Placeholder 16x16 tiles from theme ramps (no inline hex). Deterministic noise.
usage: make-tiles.py  -> art/tiles/<family>-<tile>.png"""
import json, random, subprocess
from pathlib import Path

def ramps(fam): return json.load(open(f"art/palettes/{fam}.ramps.json"))

def tile(path, base, speckle, seed, density=0.12, edge=None):
	rnd = random.Random(seed)
	# Build a 16x16 PPM-like via ImageMagick draw commands.
	cmds = ["magick", "-size", "16x16", f"xc:{base}"]
	for y in range(16):
		for x in range(16):
			if rnd.random() < density:
				cmds += ["-fill", speckle, "-draw", f"point {x},{y}"]
	if edge:
		cmds += ["-fill", edge, "-draw", "line 0,15 15,15", "-draw", "line 15,0 15,15"]
	cmds += [str(path)]
	subprocess.run(cmds, check=True)

b = ramps("bronze"); t = ramps("tide"); a = ramps("ash")
out = Path("art/tiles")
tile(out/"floor.png",  b["cloth"][1], b["cloth"][0], 1, 0.10)
tile(out/"rubble.png", b["leather"][1], b["outline"], 2, 0.30)
tile(out/"wall.png",   b["leather"][0], b["outline"], 3, 0.15, edge=b["outline"])
tile(out/"water.png",  t["metal"][0], t["metal"][1], 4, 0.14)
tile(out/"tide.png",   t["metal"][1], t["cloth"][1], 5, 0.25)
tile(out/"deploy.png", b["metal"][2], b["metal"][1], 6, 0.20)
# Stage variants
tile(out/"floor-cold.png",  b["cloth"][0], b["outline"], 7, 0.18)                     # Custom Broken: hearths dark
tile(out/"floor-weed.png",  b["cloth"][1], t["metal"][1], 8, 0.16)                    # Sea Broken: weed on the stones
tile(out/"wall-broken.png", b["leather"][0], b["cloth"][0], 9, 0.28, edge=b["outline"]) # Law Lost: unmanned, crumbling
tile(out/"rubble-bones.png", b["leather"][1], b["highlight"], 10, 0.22)               # Custom Lost: unburied
print("tiles:", sorted(p.name for p in out.glob("*.png")))
